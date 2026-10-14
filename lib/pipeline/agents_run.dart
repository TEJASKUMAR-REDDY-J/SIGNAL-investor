import 'package:drift/drift.dart';

import '../db/db.dart';
import '../engine/agents.dart';
import '../engine/calendar.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/news_score.dart';
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

String _rs(int paise) => rupees(paise, decimals: false);
String _pc(double x) => '${x >= 0 ? '+' : ''}${(x * 100).toStringAsFixed(1)}%';

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

  // 3. The pool: top-ranked names, anything with news, and every agent holding.
  final trades = await (m.select(m.agentTrades)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
  final books = {for (final k in AgentKind.values) k: bookFor(trades, k)};
  final heldIds = {for (final b in books.values) ...b.positions.keys};
  final symOf = {for (final i in instruments) i.id: i.nseSymbol!};
  final pool = <String>{
    for (final c in ideas.take(120)) c.input.symbol,
    for (final id in {...n7.keys, ...heldIds}) ?symOf[id],
  }..removeWhere((s) => !listings.containsKey(s));
  onStatus?.call('Fetching live prices for ${pool.length} stocks…');
  final hist = await yahooSparkHistory(net, [for (final s in pool) '$s.NS']);

  final cands = <int, AgentCand>{};
  final priceRows = <(int, String, int)>[];
  for (final s in pool) {
    final h = hist['$s.NS'];
    if (h == null) continue;
    final (q, closes) = h;
    final id = idOf[s] ?? await ensureStock(m, s, listings[s]!.name);
    final idea = bySymbol[s];
    cands[id] = AgentCand(id, s, listings[s]!.name, q.priceE4, closes,
        advisorScore: idea?.score,
        quality: idea?.quality,
        growth: idea?.growth,
        momentum: idea?.momentum,
        news1: n1[id]?.points ?? 0,
        news7: n7[id]?.points ?? 0,
        headline: (n1[id] ?? n7[id])?.latest?.title,
        industry: listings[s]!.industry);
    priceRows.add((id, q.day, q.priceE4));
  }
  await m.batch((b) => b.insertAllOnConflictUpdate(m.prices, [
        for (final (id, d, p) in priceRows)
          PricesCompanion.insert(instrumentId: id, date: d, closeE4: p, source: 'yahoo', fetchedAt: DateTime.now()),
      ]));
  final notes = await (m.select(m.agentNotes)..orderBy([(x) => OrderingTerm.desc(x.at)])..limit(20)).get();

  // 4. Each due agent: rules -> AI -> hard limits -> log.
  final lines = <String>[];
  for (final k in due) {
    final cfg = agentConfigs[k]!;
    onStatus?.call('${cfg.name} agent deciding…');
    try {
      final book = books[k]!;
      final weeklyFirst = k == AgentKind.weekly && !trades.any((t) => t.agent == k.name);
      final daysLeft = tradingDaysLeft(today, nse.isTradingDay);
      final rebLeft = rebalanceDaysLeft(today, nse.isTradingDay) + (weeklyFirst && !isFirstTradingDayOfWeek(today, nse.isTradingDay) ? 1 : 0);
      var plan = propose(k, book, cands, today,
          rebalanceDay: weeklyFirst || isFirstTradingDayOfWeek(today, nse.isTradingDay),
          tradingDaysLeftInMonth: daysLeft,
          rebalanceDaysLeftInMonth: rebLeft);
      final cap = dayBudget(k, book.monthRoom(date.substring(0, 7)), tradingDaysLeft: daysLeft, rebalanceDaysLeft: rebLeft);
      var summary = '';
      var ai = false;
      if (groqKey != null && (plan.shortlist.isNotEmpty || book.positions.isNotEmpty)) {
        final myNotes = [for (final x in notes) if (x.agent == null || x.agent == k.name) x.body];
        final dec = await agentDecide(net, groqKey, model, _brief(k, book, plan, cands, today, myNotes),
                buyable: {
                  for (final c in plan.shortlist) c.symbol,
                  if (k == AgentKind.monthly) for (final id in book.positions.keys) ?cands[id]?.symbol,
                },
                held: {for (final id in book.positions.keys) ?cands[id]?.symbol},
                maxRupees: agentPerStockDayPaise ~/ 100)
            .catchError((_) => null);
        if (dec != null && (plan.buys.isEmpty || plan.shortlist.isNotEmpty)) {
          final idBySym = {for (final c in cands.values) c.symbol: c.instrumentId};
          final ruleReason = {for (final b in plan.buys) b.instrumentId: b.reason};
          // Stop-losses and profit targets always run; the AI adds or skips the rest.
          final hard = [for (final s in plan.sells) if (s.reason.startsWith('stop-loss') || s.reason.startsWith('took profit')) s];
          plan = AgentPlan([
            for (final (sym, rs, why) in dec.buys)
              PlannedBuy(idBySym[sym]!, rs * 100, why.isEmpty ? (ruleReason[idBySym[sym]] ?? 'AI pick') : why),
          ], [
            ...hard,
            for (final (sym, why) in dec.sells)
              if (!hard.any((h) => h.instrumentId == idBySym[sym])) PlannedSell(idBySym[sym]!, why.isEmpty ? 'AI exit' : why),
          ], plan.shortlist);
          summary = dec.summary;
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
            ? 'Held steady: nothing met the rules today.'
            : '${line[0].toUpperCase()}${line.substring(1)} under the rules.';
      }
      await m.into(m.agentRuns).insert(AgentRunsCompanion.insert(
          agent: k.name, date: date, at: at, summary: summary, valuePaise: value, cashPaise: after.cashPaise, ai: Value(ai)));
      lines.add('${cfg.name}: $line · ${_rs(value)} (${_pc(value / agentStartCashPaise - 1)})');
    } catch (e) {
      lines.add('${cfg.name}: skipped ($e)');
    }
  }
  return lines;
}

String _brief(AgentKind k, AgentBook book, AgentPlan plan, Map<int, AgentCand> cands, DateTime today, List<String> notes) {
  final cfg = agentConfigs[k]!;
  final month = fmtDay(today).substring(0, 7);
  String row(AgentCand c) => '${c.symbol} | ${c.name} | ${c.industry} | ₹${(c.priceE4 / 10000).toStringAsFixed(2)} | 1d ${_pc(c.ret1)} | '
      '5d ${_pc(c.ret5)} | 1m ${_pc(c.ret20)} | advisor ${c.advisorScore == null ? 'fails filters' : (c.advisorScore! * 100).round()} | '
      'news24h ${c.news1} | news7d ${c.news7}${c.headline == null ? '' : ' | "${c.headline}"'}';
  return [
    'Agent: ${cfg.name}. Style: ${cfg.style}',
    'Today ${fmtDay(today)}. Cash ${_rs(book.cashPaise)}. New-money room this month ${_rs(book.monthRoom(month))} '
        '(limit ₹4,00,000 net per month, spread across the month: buy no more than the plan total for today). '
        'At most $agentMaxPerSector holdings per industry. '
        'At most ₹50,000 per stock today. Max ${cfg.maxHoldings} holdings.',
    'Holdings:',
    if (book.positions.isEmpty) '(none)',
    for (final p in book.positions.values)
      if (cands[p.instrumentId] case final c?)
        '${c.symbol} | ${formatScaled(p.units4, 4)} shares | cost ${_rs(p.costPaise)} | now ${_rs(valuePaise(p.units4, c.priceE4))} '
            '| ${_pc(valuePaise(p.units4, c.priceE4) / p.costPaise - 1)} | held ${today.difference(p.firstBuy).inDays} days | news7d ${c.news7}',
    'Rule plan:',
    for (final s in plan.sells) 'SELL ${cands[s.instrumentId]?.symbol}: ${s.reason}',
    for (final b in plan.buys) 'BUY ${cands[b.instrumentId]?.symbol} ${_rs(b.amountPaise)}: ${b.reason}',
    if (plan.sells.isEmpty && plan.buys.isEmpty) '(nothing)',
    'Shortlist (symbol | name | industry | price | 1 day | 5 days | 1 month | advisor 0-100 | news points 24h | 7d | latest headline):',
    for (final c in plan.shortlist) row(c),
    if (notes.isNotEmpty) 'Owner notes (newest first):',
    for (final x in notes) '- $x',
  ].join('\n');
}
