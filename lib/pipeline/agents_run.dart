import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../db/db.dart';
import '../engine/agent_stats.dart';
import '../engine/agents.dart';
import '../engine/calendar.dart';
import '../engine/indicators.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/news_score.dart';
import '../engine/regime.dart';
import '../sources/groq.dart';
import '../sources/net.dart';
import '../sources/yahoo.dart';
import 'instruments.dart';
import 'scan.dart';

const agentModel = 'openai/gpt-oss-120b';

/// IST calendar day of [nowUtc].
DateTime istDay(DateTime nowUtc) {
  final ist = nowUtc.toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime.utc(ist.year, ist.month, ist.day);
}

/// Agents trade once per trading day, from 09:45 IST (after the opening rush).
bool agentsCanTrade(DateTime nowUtc) {
  final ist = nowUtc.toUtc().add(const Duration(hours: 5, minutes: 30));
  return nse.isTradingDay(istDay(nowUtc)) && (ist.hour > 9 || (ist.hour == 9 && ist.minute >= 45));
}

Future<Set<AgentKind>> agentsDue(MarketDb m, DateTime nowUtc) async {
  if (!agentsCanTrade(nowUtc)) return {};
  final ran = {for (final r in await (m.select(m.agentRuns)..where((r) => r.date.equals(fmtDay(istDay(nowUtc))))).get()) r.agent};
  return {for (final k in AgentKind.values) if (!ran.contains(k.name)) k};
}

AgentBook bookFor(List<AgentTrade> all, AgentKind k) => AgentBook([
      for (final t in all)
        if (t.agent == k.name) (t.date, t.side, t.instrumentId, t.unitsE4, t.priceE4, t.feesPaise),
    ]);

/// Scorecard for one agent from its runs and trades (NIFTY from [nifty] closes by date).
AgentStats statsFor(AgentKind k, List<AgentRun> runs, List<AgentTrade> trades, Map<String, double> nifty) {
  final days = nifty.keys.toList()..sort();
  double? niftyAt(DateTime d) {
    final key = fmtDay(d);
    String? best;
    for (final x in days) {
      if (x.compareTo(key) <= 0) best = x;
    }
    return best == null ? null : nifty[best];
  }

  return agentStats(
    startCashPaise: agentStartCashPaise,
    runValues: [for (final r in runs) if (r.agent == k.name) (r.date, r.valuePaise)],
    trades: [
      for (final t in trades)
        if (t.agent == k.name) (t.date, t.side, t.instrumentId, t.unitsE4, t.priceE4, t.feesPaise, t.reason),
    ],
    niftyAt: niftyAt,
  );
}

/// NIFTY 50 closes by date from the stored index history (the refresher keeps years of it).
Future<Map<String, double>> niftyByDate(MarketDb m) async {
  final idx = await (m.select(m.instruments)..where((i) => i.yahooTicker.equals('^NSEI'))).getSingleOrNull();
  if (idx == null) return const {};
  return {
    for (final p in await (m.select(m.prices)..where((p) => p.instrumentId.equals(idx.id) & p.source.equals('yahoo'))).get())
      p.date: p.closeE4 / 10000,
  };
}

String _rs(int paise) => rupees(paise, decimals: false);
String _pc(double x) => '${x >= 0 ? '+' : ''}${(x * 100).toStringAsFixed(1)}%';
List<double> _d(List<int> e4) => [for (final x in e4) x / 10000];

/// Runs every agent that has not traded today. Returns one line per agent for the
/// notification. Never throws for a single agent's failure.
Future<List<String>> runAgents(
  MarketDb m,
  Net net, {
  String? groqKey,
  String model = agentModel,
  DateTime? nowUtc,
  void Function(String)? onStatus,
}) async {
  final now = (nowUtc ?? DateTime.now()).toUtc();
  final due = await agentsDue(m, now);
  if (due.isEmpty) return const [];
  final today = istDay(now);
  final date = fmtDay(today);

  // 1. Advisor data for all of NIFTY 500 (first time: a full scan, about 3 minutes).
  onStatus?.call('Reading NIFTY 500 data…');
  var ideas = await stockIdeas(m, n: 600, nowUtc: now);
  if (ideas.isEmpty) {
    onStatus?.call('First run: scanning NIFTY 500 (about 3 minutes)…');
    try {
      await runScan(m, net, onProgress: (d, t, w) => onStatus?.call('Scanning NIFTY 500: $d / $t'), cancel: CancelToken(), nowUtc: now);
    } catch (_) {}
    ideas = await stockIdeas(m, n: 600, nowUtc: now);
  }
  final bySymbol = {for (final c in ideas) c.input.symbol: c};
  final listings = {
    for (final u in await (m.select(m.universe)..where((u) => u.nifty500.equals(true))).get()) u.symbol: u,
  };

  // 2. News points per company (AI-labelled headlines).
  final items = await (m.select(m.newsItems)
        ..where((x) => x.instrumentId.isNotNull() & x.publishedAt.isBiggerOrEqualValue(now.subtract(const Duration(days: 7)))))
      .get();
  final n7 = {for (final s in newsScores(items, now)) s.instrumentId: s};
  final n1 = {for (final s in newsScores(items, now, window: const Duration(hours: 24))) s.instrumentId: s};
  final instruments = await (m.select(m.instruments)..where((i) => i.nseSymbol.isNotNull())).get();
  final idOf = {for (final i in instruments) i.nseSymbol!: i.id};

  // 3. The pool: top-ranked names, anything with news, every agent holding; a year of closes each.
  final trades = await (m.select(m.agentTrades)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
  final runs = await (m.select(m.agentRuns)..orderBy([(r) => OrderingTerm.asc(r.id)])).get();
  final books = {for (final k in AgentKind.values) k: bookFor(trades, k)};
  final heldIds = {for (final b in books.values) ...b.positions.keys};
  final symOf = {for (final i in instruments) i.id: i.nseSymbol!};
  final pool = <String>{
    for (final c in ideas.take(120)) c.input.symbol,
    for (final id in {...n7.keys, ...heldIds}) ?symOf[id],
  }..removeWhere((s) => !listings.containsKey(s));
  onStatus?.call('Fetching a year of prices for ${pool.length} stocks…');
  final hist = await yahooSparkHistory(net, ['^NSEI', '^INDIAVIX', for (final s in pool) '$s.NS'], range: '1y');
  final niftyCloses = hist['^NSEI'] == null ? const <double>[] : _d(hist['^NSEI']!.$2);
  final vix = hist['^INDIAVIX'] == null ? null : hist['^INDIAVIX']!.$1.priceE4 / 10000;

  final cands = <int, AgentCand>{};
  final priceRows = <(int, String, int)>[];
  AgentCand build(int id, String s, Quote q, List<int> closes, Technicals tech) {
    final idea = bySymbol[s];
    return AgentCand(id, s, listings[s]!.name, q.priceE4, closes,
        advisorScore: idea?.score,
        quality: idea?.quality,
        growth: idea?.growth,
        momentum: idea?.momentum,
        news1: n1[id]?.points ?? 0,
        news7: n7[id]?.points ?? 0,
        headline: (n1[id] ?? n7[id])?.latest?.title,
        industry: listings[s]!.industry,
        tech: tech);
  }

  for (final s in pool) {
    final h = hist['$s.NS'];
    if (h == null) continue;
    final (q, closes) = h;
    final id = idOf[s] ?? await ensureStock(m, s, listings[s]!.name);
    idOf[s] = id;
    symOf[id] = s;
    cands[id] = build(id, s, q, closes, Technicals.of(_d(closes), index: niftyCloses));
    priceRows.add((id, q.day, q.priceE4));
  }
  await m.batch((b) => b.insertAllOnConflictUpdate(m.prices, [
        for (final (id, d, p) in priceRows)
          PricesCompanion.insert(instrumentId: id, date: d, closeE4: p, source: 'yahoo', fetchedAt: DateTime.now()),
      ]));

  // 4. Market regime: trend, fear gauge and breadth.
  final above50 = cands.values.where((c) => c.tech?.aboveSma50 == true).length;
  final regime = regimeOf(nifty: niftyCloses, vix: vix, breadth: cands.isEmpty ? 0.5 : above50 / cands.length);

  // 5. First pass of rules, then full price bars (ATR, volume) for every shortlisted or held stock.
  final daysLeft = tradingDaysLeft(today, nse.isTradingDay);
  final firstOfWeek = isFirstTradingDayOfWeek(today, nse.isTradingDay);
  final scales = <AgentKind, (double, String?)>{};
  AgentPlan planFor(AgentKind k) {
    final weeklyFirst = k == AgentKind.weekly && !trades.any((t) => t.agent == k.name);
    final values = [for (final r in runs) if (r.agent == k.name) r.valuePaise];
    final (brake, why) = drawdownBrake(values);
    // The monthly compounder keeps buying through dips, only slower.
    final scale = (k == AgentKind.monthly ? max(0.7, regime.budgetScale) : regime.budgetScale) * brake;
    scales[k] = (scale, why);
    return propose(k, books[k]!, cands, today,
        rebalanceDay: weeklyFirst || firstOfWeek,
        tradingDaysLeftInMonth: daysLeft,
        rebalanceDaysLeftInMonth: rebalanceDaysLeft(today, nse.isTradingDay) + (weeklyFirst && !firstOfWeek ? 1 : 0),
        budgetScale: scale);
  }

  final enrich = <int>{
    for (final k in due) ...planFor(k).shortlist.map((c) => c.instrumentId),
    for (final k in due) ...books[k]!.positions.keys,
  };
  onStatus?.call('Reading full price bars for ${enrich.length} shortlisted stocks…');
  final bars = <int, Ohlc>{};
  await Future.wait([
    for (final id in enrich)
      if (symOf[id] != null)
        yahooOhlc(net, '${symOf[id]}.NS').then((o) => bars[id] = o).catchError((_) => const Ohlc([], [], [], [])),
  ]);
  for (final e in bars.entries) {
    final c = cands[e.key];
    if (c == null || e.value.close.length < 30) continue;
    final o = e.value;
    cands[e.key] = build(c.instrumentId, c.symbol, Quote(c.symbol, c.priceE4, c.priceE4, now), c.closesE4,
        Technicals.of(_d(c.closesE4), index: niftyCloses, highs: o.high, lows: o.low, volumes: o.volume));
  }

  final notes = await (m.select(m.agentNotes)..orderBy([(x) => OrderingTerm.desc(x.at)])..limit(20)).get();
  final memories = await (m.select(m.agentMemories)..orderBy([(x) => OrderingTerm.desc(x.at)])).get();
  final nifty = await niftyByDate(m);

  // 6. Each due agent: reflect (weekly) -> rules -> AI with tools -> hard limits -> log.
  final lines = <String>[];
  for (final k in due) {
    final cfg = agentConfigs[k]!;
    try {
      final book = books[k]!;
      final stats = statsFor(k, runs, trades, nifty);
      var lessons = [for (final x in memories) if (x.agent == k.name) x.body];
      if (groqKey != null && firstOfWeek && stats.closed.length >= 2 &&
          !memories.any((x) => x.agent == k.name && now.difference(x.at.toUtc()).inDays < 6)) {
        onStatus?.call('${cfg.name} agent reviewing last week…');
        final closedText = [
          for (final c in stats.closed.reversed.take(20))
            '${symOf[c.instrumentId] ?? c.instrumentId}: ${_pc(c.pnlPct)} in ${c.days} days. Bought because: ${c.buyReason}. Sold because: ${c.sellReason}',
        ].join('\n');
        final fresh = await agentReflect(net, groqKey, model, cfg.name, 'Scorecard: ${stats.summary}\nClosed trades:\n$closedText')
            .catchError((_) => <String>[]);
        for (final l in fresh) {
          await m.into(m.agentMemories).insert(AgentMemoriesCompanion.insert(agent: k.name, at: DateTime.now(), body: l));
        }
        lessons = [...fresh, ...lessons];
      }

      onStatus?.call('${cfg.name} agent deciding…');
      var plan = planFor(k);
      final (scale, brakeWhy) = scales[k]!;
      final cap = (dayBudget(k, book.monthRoom(date.substring(0, 7)),
                  tradingDaysLeft: daysLeft, rebalanceDaysLeft: rebalanceDaysLeft(today, nse.isTradingDay)) *
              scale)
          .round();
      var summary = '';
      var ai = false;
      String? bull, bear;
      var toolCalls = 0;
      if (groqKey != null && (plan.shortlist.isNotEmpty || book.positions.isNotEmpty)) {
        final myNotes = [for (final x in notes) if (x.agent == null || x.agent == k.name) x.body];
        final runner = _tools(m, k, book, cands, regime, stats, lessons.take(6).toList(), today, cap, symOf, items);
        final res = await agentTrade(net, groqKey, model, _brief(k, book, plan, cands, today, myNotes, regime, cap, brakeWhy), runner,
                buyable: {
                  for (final c in plan.shortlist) c.symbol,
                  if (k == AgentKind.monthly) for (final id in book.positions.keys) ?cands[id]?.symbol,
                },
                held: {for (final id in book.positions.keys) ?cands[id]?.symbol},
                maxRupees: agentPerStockDayPaise ~/ 100)
            .catchError((_) => null);
        if (res != null) {
          final idBySym = {for (final c in cands.values) c.symbol: c.instrumentId};
          final ruleReason = {for (final b in plan.buys) b.instrumentId: b.reason};
          // Stop-losses and profit targets always run; the AI adds or skips the rest.
          final hard = [for (final s in plan.sells) if (s.reason.startsWith('stop-loss') || s.reason.startsWith('took profit')) s];
          plan = AgentPlan([
            for (final (sym, rs, why) in res.decision.buys)
              PlannedBuy(idBySym[sym]!, volScaled(rs * 100, cands[idBySym[sym]]?.tech?.vol20),
                  why.isEmpty ? (ruleReason[idBySym[sym]] ?? 'AI pick') : why),
          ], [
            ...hard,
            for (final (sym, why) in res.decision.sells)
              if (!hard.any((h) => h.instrumentId == idBySym[sym])) PlannedSell(idBySym[sym]!, why.isEmpty ? 'AI exit' : why),
          ], plan.shortlist);
          summary = res.decision.summary;
          bull = res.bull;
          bear = res.bear;
          toolCalls = res.toolCalls;
          ai = true;
        }
      }
      final orders = enforce(book, plan, cands, today, dayCapPaise: cap);
      final at = DateTime.now();
      await m.transaction(() async {
        for (final o in orders) {
          await m.into(m.agentTrades).insert(AgentTradesCompanion.insert(
              agent: k.name, instrumentId: o.instrumentId, date: date, at: at, side: o.side, unitsE4: o.units4,
              priceE4: o.priceE4, feesPaise: Value(o.feesPaise), reason: Value(o.reason)));
        }
      });
      final after = bookFor(await m.select(m.agentTrades).get(), k);
      final value = after.valueAt({for (final c in cands.values) c.instrumentId: c.priceE4});
      final buys = orders.where((o) => o.side == 'buy'), sells = orders.where((o) => o.side == 'sell');
      final spent = buys.fold(0, (a, o) => a + valuePaise(o.units4, o.priceE4));
      final got = sells.fold(0, (a, o) => a + valuePaise(o.units4, o.priceE4));
      final line = orders.isEmpty
          ? 'no trades'
          : [
              if (buys.isNotEmpty) 'bought ${buys.length} (${_rs(spent)})',
              if (sells.isNotEmpty) 'sold ${sells.length} (${_rs(got)})',
            ].join(', ');
      if (summary.isEmpty) {
        summary = orders.isEmpty
            ? 'Held steady: nothing met the rules today${brakeWhy == null ? '' : ' ($brakeWhy)'}.'
            : '${line[0].toUpperCase()}${line.substring(1)} under the rules.';
      }
      await m.into(m.agentRuns).insert(AgentRunsCompanion.insert(
          agent: k.name,
          date: date,
          at: at,
          summary: summary,
          valuePaise: value,
          cashPaise: after.cashPaise,
          ai: Value(ai),
          bull: Value(bull),
          bear: Value(bear),
          regime: Value(regime.line),
          toolCalls: Value(toolCalls)));
      lines.add('${cfg.name}: $line · ${_rs(value)} (${_pc(value / agentStartCashPaise - 1)})');
    } catch (e) {
      lines.add('${cfg.name}: skipped ($e)');
    }
  }
  return lines;
}

/// The data tools the AI may call. All local: no network inside the loop.
ToolRunner _tools(MarketDb m, AgentKind k, AgentBook book, Map<int, AgentCand> cands, MarketRegime regime, AgentStats stats,
    List<String> lessons, DateTime today, int capPaise, Map<int, String> symOf, List<NewsItem> news) {
  final bySym = {for (final c in cands.values) c.symbol: c};
  AgentCand? find(Object? s) => s is String ? bySym[s.toUpperCase().trim()] : null;
  String j(Object? o) => jsonEncode(o);
  double r2(num x) => double.parse(x.toStringAsFixed(2));
  return (name, args) async {
    switch (name) {
      case 'get_portfolio':
        final sectors = <String, int>{};
        for (final id in book.positions.keys) {
          final ind = cands[id]?.industry ?? 'unknown';
          sectors[ind] = (sectors[ind] ?? 0) + 1;
        }
        return j({
          'cash_rupees': book.cashPaise ~/ 100,
          'month_room_rupees': book.monthRoom(fmtDay(today).substring(0, 7)) ~/ 100,
          'today_max_total_rupees': capPaise ~/ 100,
          'max_per_stock_today_rupees': agentPerStockDayPaise ~/ 100,
          'holdings': [
            for (final p in book.positions.values)
              {
                'symbol': symOf[p.instrumentId],
                'shares': p.units4 ~/ 10000,
                'cost_rupees': p.costPaise ~/ 100,
                'pnl_pct': cands[p.instrumentId] == null ? null : r2((valuePaise(p.units4, cands[p.instrumentId]!.priceE4) / p.costPaise - 1) * 100),
                'days_held': today.difference(p.firstBuy).inDays,
                'industry': cands[p.instrumentId]?.industry,
              },
          ],
          'holdings_per_industry': sectors,
        });
      case 'get_market_regime':
        return j(regime.toJson());
      case 'get_technicals':
        final c = find(args['symbol']);
        return c == null ? 'not in today\'s data' : j(c.tech?.toJson() ?? {'price': c.priceE4 / 10000});
      case 'get_fundamentals':
        final c = find(args['symbol']);
        if (c == null) return 'not in today\'s data';
        final row = await (m.select(m.fundamentals)..where((f) => f.symbol.equals(c.symbol))).getSingleOrNull();
        final f = row == null ? const {} : ((jsonDecode(row.json) as Map)['f'] as Map? ?? const {});
        return j({
          'name': c.name,
          'industry': c.industry,
          'advisor_score_0_100': c.advisorScore == null ? 'fails quality filters' : (c.advisorScore! * 100).round(),
          'quality_rank': c.quality == null ? null : (c.quality! * 100).round(),
          'growth_rank': c.growth == null ? null : (c.growth! * 100).round(),
          'momentum_rank': c.momentum == null ? null : (c.momentum! * 100).round(),
          for (final key in ['roe', 'debtToEquity', 'revenueGrowth', 'earningsGrowth', 'operatingMargins', 'pe', 'forwardPe', 'dividendYield', 'marketCap', 'beta'])
            if (f[key] != null) key: f[key],
        });
      case 'get_news':
        final c = find(args['symbol']);
        if (c == null) return 'not in today\'s data';
        final mine = [for (final x in news) if (x.instrumentId == c.instrumentId) x]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        final filings = await (m.select(m.filings)
              ..where((f) => f.instrumentId.equals(c.instrumentId))
              ..orderBy([(f) => OrderingTerm.desc(f.date)])
              ..limit(4))
            .get();
        return j({
          'points_24h': c.news1,
          'points_7d': c.news7,
          'headlines': [
            for (final x in mine.take(6)) {'title': x.title, 'publisher': x.publisher, 'label': x.label, 'why': x.reason},
          ],
          'nse_filings': [for (final f in filings) '${f.date}: ${f.category}'],
        });
      case 'compare':
        final syms = (args['symbols'] is List ? args['symbols'] as List : const []).take(8);
        return [
          for (final s in syms)
            if (find(s) case final c?)
              '${c.symbol}: ₹${(c.priceE4 / 10000).toStringAsFixed(1)}, 1m ${_pc(c.ret20)}, RSI ${c.tech?.rsi14?.round() ?? '-'}, '
                  '${c.tech?.trendLabel ?? ''}, vol ${c.tech?.vol20 == null ? '-' : '${(c.tech!.vol20! * 100).round()}%'}, '
                  'advisor ${c.advisorScore == null ? 'fails' : (c.advisorScore! * 100).round()}, news7d ${c.news7}, ${c.industry}'
            else
              '$s: not in today\'s data',
        ].join('\n');
      case 'get_track_record':
        return j({'scorecard': stats.summary, 'lessons_you_wrote': lessons});
    }
    return 'unknown tool';
  };
}

String _brief(AgentKind k, AgentBook book, AgentPlan plan, Map<int, AgentCand> cands, DateTime today, List<String> notes,
    MarketRegime regime, int capPaise, String? brakeWhy) {
  final cfg = agentConfigs[k]!;
  final month = fmtDay(today).substring(0, 7);
  String row(AgentCand c) => '${c.symbol} | ${c.name} | ${c.industry} | ₹${(c.priceE4 / 10000).toStringAsFixed(2)} | 1d ${_pc(c.ret1)} | '
      '1m ${_pc(c.ret20)} | RSI ${c.tech?.rsi14?.round() ?? '-'} | advisor ${c.advisorScore == null ? 'fails filters' : (c.advisorScore! * 100).round()} | '
      'news7d ${c.news7}';
  return [
    'Agent: ${cfg.name}. Style: ${cfg.style}',
    'Today ${fmtDay(today)}. Market: ${regime.line}.${brakeWhy == null ? '' : ' Drawdown brake: $brakeWhy.'}',
    'Cash ${_rs(book.cashPaise)}. New-money room this month ${_rs(book.monthRoom(month))}. Spend at most ${_rs(capPaise)} in total '
        'today, ₹50,000 per stock, max ${cfg.maxHoldings} holdings, max $agentMaxPerSector per industry.',
    'Holdings: ${book.positions.isEmpty ? '(none)' : [for (final p in book.positions.values) cands[p.instrumentId]?.symbol].join(', ')}',
    'Rule plan:',
    for (final s in plan.sells) 'SELL ${cands[s.instrumentId]?.symbol}: ${s.reason}',
    for (final b in plan.buys) 'BUY ${cands[b.instrumentId]?.symbol} ${_rs(b.amountPaise)}: ${b.reason}',
    if (plan.sells.isEmpty && plan.buys.isEmpty) '(nothing)',
    'Shortlist (symbol | name | industry | price | 1 day | 1 month | RSI | advisor 0-100 | news points 7d):',
    for (final c in plan.shortlist) row(c),
    if (notes.isNotEmpty) 'Owner notes (newest first):',
    for (final x in notes) '- $x',
    'Use the tools before deciding, then call submit_decision.',
  ].join('\n');
}
