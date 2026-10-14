import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/open_db.dart';
import '../engine/calendar.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../db/db.dart';
import '../engine/agents.dart';
import '../engine/fund_rank.dart';
import '../engine/indicators.dart';
import '../pipeline/agents_run.dart';
import '../pipeline/instruments.dart';
import '../sources/groq.dart';
import '../sources/mfapi.dart';
import '../sources/yahoo.dart';
import '../sources/net.dart';
import 'widgets.dart';

const defaultAskModel = 'openai/gpt-oss-120b';

/// Groq key: the one saved in Settings first, else the build-time .env key.
Future<String?> groqKeyFor(String profileId) async => cleanKey(await storage.read(key: 'groq_$profileId')) ?? envKey();

String _pct(num x) => '${(x * 100).toStringAsFixed(1)}%';

/// Everything the assistant may use: the user's portfolio (they opted in), the
/// advisor's ideas, news points and index levels. Plain lines, compact.
List<String> portfolioFacts(Session s) {
  final p = s.portfolio.value;
  if (p == null) return const [];
  final out = <String>['Today is ${fmtDay(p.today)} (India). Market: ${nse.status(DateTime.now()).label}.'];
  for (final e in s.quotes.value.entries) {
    final i = p.instruments[e.key];
    if (i?.kind == 'index') {
      out.add('${i!.name}: ${(e.value.priceE4 / 10000).toStringAsFixed(2)} (${e.value.changeBps >= 0 ? '+' : ''}${(e.value.changeBps / 100).toStringAsFixed(2)}% today)');
    }
  }
  if (p.holdings.isEmpty) {
    out.add('I have not recorded any investments in the app yet.');
  } else {
    out.add('My portfolio: value ${rupees(p.valuePaise)}, invested ${rupees(p.investedPaise)}, '
        '${p.gainPaise >= 0 ? 'gain' : 'loss'} ${rupees(p.gainPaise.abs())}'
        '${p.xirr == null ? '' : ', XIRR ${_pct(p.xirr!)} a year'}'
        '${p.ghostXirr == null ? '' : ' (same money in a Nifty 50 index fund: ${_pct(p.ghostXirr!)})'}.');
    for (final h in p.holdings) {
      final i = h.instrument;
      final lt = h.ledger.open.where((l) => isLongTerm(l.buyDate, p.today)).fold(0, (a, l) => a + l.units4);
      out.add('- ${h.name} (${h.isMf ? 'fund ${i?.schemeCode ?? ''}' : 'NSE ${i?.nseSymbol ?? ''}'}): '
          '${formatScaled(h.ledger.units4, 4)} units, cost ${rupees(h.ledger.costPaise)}, value ${rupees(h.valuePaise)}, '
          '${h.gainPaise >= 0 ? 'gain' : 'loss'} ${rupees(h.gainPaise.abs())}, '
          '${(h.valuePaise * 100 / (p.valuePaise == 0 ? 1 : p.valuePaise)).toStringAsFixed(1)}% of portfolio, '
          '${h.bucket}${h.xirr == null ? '' : ', XIRR ${_pct(h.xirr!)}'}, '
          '${h.ledger.units4 == 0 ? 0 : (lt * 100 / h.ledger.units4).round()}% of units long-term');
    }
    out.add('This financial year: short-term gains ${rupees(p.fyGains.st)}, long-term gains ${rupees(p.fyGains.lt)}, '
        'estimated tax ${rupees(p.fyTax.taxPaise)}, tax-free LTCG room left ${rupees(p.fyTax.exemptionLeftPaise)}.');
  }
  for (final g in p.goals) {
    out.add('Goal "${g.goal.name}": ${rupees(g.goal.targetPaise)} by ${g.goal.targetDate}, ${(g.progress * 100).round()}% there.');
  }
  final sips = p.sips.where((x) => x.plan.active).toList();
  if (sips.isNotEmpty) {
    out.add('Active SIPs: ${sips.map((x) => '${p.instruments[x.plan.instrumentId]?.name ?? 'fund'} ${rupees(x.plan.amountPaise)}/month').join('; ')}.');
  }
  for (final x in s.suggestions.value) {
    out.add('App sell rule firing: rule ${x.rule} on ${p.instruments[x.instrumentId]?.name ?? ''}.');
  }
  final ideas = s.stockIdeas.value ?? const [];
  if (ideas.isNotEmpty) {
    out.add('Advisor stock ideas (rule-ranked on quality, growth, value and momentum; NIFTY 500):');
    for (final (k, c) in ideas.take(10).indexed) {
      out.add('${k + 1}. ${c.input.name} (${c.input.symbol}, ${c.input.industry}): ${c.reasons.join('; ')}');
    }
  }
  final funds = s.fundIdeas.value ?? const {};
  for (final e in funds.entries) {
    if (e.value.isNotEmpty) out.add('Advisor top ${e.key}: ${e.value.first.m.name} (${e.value.first.reasons.join('; ')})');
  }
  for (final n in s.news.value.take(6)) {
    out.add('News points (7 days) ${p.instruments[n.instrumentId]?.name ?? ''}: ${n.points} '
        '(${n.positive} positive, ${n.negative} negative). Latest: ${n.latest?.title ?? ''}');
  }
  final watch = [for (final id in s.watch.value) p.instruments[id]?.name ?? ''];
  if (watch.isNotEmpty) out.add('Watchlist: ${watch.join(', ')}.');
  return out;
}

/// Local data tools for Ask: chart indicators, fundamentals, news, fund returns, the agents.
ToolRunner askToolRunner(Session s, Net net) {
  final m = s.market;
  String j(Object? o) => jsonEncode(o);
  Future<Listing?> listing(Object? sym) async => sym is String
      ? (m.select(m.universe)..where((u) => u.symbol.equals(sym.toUpperCase().trim()))).getSingleOrNull()
      : null;
  return (name, args) async {
    switch (name) {
      case 'get_technicals':
        final l = await listing(args['symbol']);
        if (l == null) return 'unknown NSE symbol';
        final h = await yahooSparkHistory(net, ['${l.symbol}.NS', '^NSEI'], range: '1y');
        final c = h['${l.symbol}.NS'];
        if (c == null) return 'no price data';
        final idx = h['^NSEI']?.$2;
        return j({'name': l.name, ...Technicals.of([for (final x in c.$2) x / 10000], index: idx == null ? null : [for (final x in idx) x / 10000]).toJson()});
      case 'get_fundamentals':
        final l = await listing(args['symbol']);
        if (l == null) return 'unknown NSE symbol';
        final f = await stockFundamentals(m, net, l.symbol);
        final ideas = s.stockIdeas.value ?? const [];
        final rank = ideas.indexWhere((c) => c.input.symbol == l.symbol);
        return j({'name': l.name, 'industry': l.industry, ...?f, 'advisor_rank': rank < 0 ? 'not in the top ideas' : rank + 1});
      case 'get_news':
        final l = await listing(args['symbol']);
        if (l == null) return 'unknown NSE symbol';
        final inst = await (m.select(m.instruments)..where((i) => i.nseSymbol.equals(l.symbol))).getSingleOrNull();
        if (inst == null) return 'no news tracked for it yet';
        final news = await (m.select(m.newsItems)
              ..where((x) => x.instrumentId.equals(inst.id))
              ..orderBy([(x) => OrderingTerm.desc(x.publishedAt)])
              ..limit(8))
            .get();
        return j([for (final x in news) {'title': x.title, 'publisher': x.publisher, 'date': fmtDay(x.publishedAt.toUtc()), 'label': x.label, 'why': x.reason}]);
      case 'get_fund':
        final hits = await mfSearch(net, '${args['name'] ?? ''}');
        if (hits.isEmpty) return 'no fund found';
        final (code, fname) = hits.firstWhere((h) => !isRegularPlan(h.$2), orElse: () => hits.first);
        final now = DateTime.now().toUtc();
        final navs = await mfNavsBetween(net, code, DateTime.utc(now.year - 5, now.month, now.day), now);
        final mt = fundMetrics(code, fname, '', navs.navs);
        return mt == null ? 'not enough history' : j({'fund': fname, 'scheme_code': code, ...mt.toJson()});
      case 'get_agents':
        final trades = await m.select(m.agentTrades).get();
        final runs = await (m.select(m.agentRuns)..orderBy([(r) => OrderingTerm.desc(r.id)])..limit(9)).get();
        final sym = {for (final i in await m.select(m.instruments).get()) i.id: i.nseSymbol ?? i.name};
        return j({
          for (final k in AgentKind.values)
            k.name: {
              'holdings': [for (final p in bookFor(trades, k).positions.values) sym[p.instrumentId]],
              'cash_rupees': bookFor(trades, k).cashPaise ~/ 100,
              'latest_decisions': [for (final r in runs) if (r.agent == k.name) '${r.date}: ${r.summary}'],
            },
        });
    }
    return 'unknown tool';
  };
}

/// Ask anything: how to use the app, your portfolio, a company, tax. Explains; never decides.
class AskScreen extends StatefulWidget {
  final Session session;
  final String? initialQuestion;
  final List<String> extraContext;
  const AskScreen({super.key, required this.session, this.initialQuestion, this.extraContext = const []});
  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _q = TextEditingController();
  final _scroll = ScrollController();
  final _chat = <(bool, String)>[]; // (fromUser, text)
  bool _web = false, _busy = false, _mine = true;
  final _net = Net();

  static const _starters = [
    'Study Tata Motors: chart, business and news. Is it in good shape?',
    'How are the three agents doing, and why did they make their last trades?',
    'How is my portfolio doing, and what should I keep an eye on?',
    'Which of the Advisor\'s top ideas is growing fastest, and why?',
    'I am new. How do I record a stock I bought?',
    'What does the news say about the companies I follow?',
    'Explain my tax position this year in simple words',
    'Index fund or flexi cap fund: which suits a beginner?',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuestion != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.initialQuestion));
    }
  }

  @override
  void dispose() {
    _q.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _q.text).trim();
    if (text.isEmpty || _busy) return;
    final key = await groqKeyFor(widget.session.profile.id);
    if (!mounted) return;
    if (key == null) {
      snack(context, 'Add a Groq API key in Settings first.');
      return;
    }
    final model = await widget.session.db.setting('groq_ask_model') ?? defaultAskModel;
    final history = [..._chat];
    setState(() {
      _chat.add((true, text));
      _busy = true;
      _q.clear();
    });
    _toBottom();
    try {
      final ctx = [if (_mine) ...portfolioFacts(widget.session), ...widget.extraContext];
      // Web search and function tools don't mix on Groq: web questions use browser search,
      // everything else can look up any stock, fund or the agents.
      final a = _web
          ? await ask(_net, key, model, text, webSearch: true, history: history, context: ctx)
          : await askWithTools(_net, key, model, text, askToolRunner(widget.session, _net), history: history, context: ctx);
      final note = a.searches == 0 ? '' : (_web ? '${a.searches} web search${a.searches == 1 ? '' : 'es'}' : '${a.searches} data look-up${a.searches == 1 ? '' : 's'}');
      if (mounted) setState(() => _chat.add((false, '${a.text}${note.isEmpty ? '' : '\n\n($note)'}')));
    } catch (e) {
      if (mounted) setState(() => _chat.add((false, 'Could not get an answer: ${e.toString().replaceFirst('groq: ', '')}')));
    } finally {
      if (mounted) setState(() => _busy = false);
      _toBottom();
    }
  }

  Future<void> _toBottom() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ask SIGNAL')),
      body: Column(children: [
        Expanded(
          child: ListView(controller: _scroll, padding: const EdgeInsets.all(12), children: [
            if (_chat.isEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.auto_awesome, color: cs.primary),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Your guide and explainer', style: TextStyle(fontWeight: FontWeight.w700))),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'Ask how to use the app, about your portfolio, a company, a fund or tax. It uses your portfolio, the '
                      'Advisor\'s ideas and the news on this phone, and can search the web. It explains; you decide. '
                      'Answers can be wrong, so check before acting.',
                      style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              for (final s in _starters)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ActionChip(label: Text(s), onPressed: () => _send(s)),
                ),
            ],
            for (final (me, text) in _chat)
              Align(
                alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.86),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: me ? cs.primaryContainer : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: text));
                      snack(context, 'Copied');
                    },
                    child: SelectableText(text, style: const TextStyle(height: 1.4)),
                  ),
                ),
              ),
            if (_busy)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4)),
                  const SizedBox(width: 10),
                  Text(_web ? 'Thinking and searching the web…' : 'Thinking…', style: TextStyle(color: cs.onSurfaceVariant)),
                ]),
              ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Column(children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  FilterChip(
                    avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                    label: const Text('Use my portfolio'),
                    selected: _mine,
                    onSelected: (v) => setState(() => _mine = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: const Icon(Icons.travel_explore, size: 18),
                    label: const Text('Search the web'),
                    selected: _web,
                    onSelected: (v) => setState(() => _web = v),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'Ask anything…'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(tooltip: 'Send', onPressed: _busy ? null : _send, icon: const Icon(Icons.arrow_upward)),
              ]),
              const SizedBox(height: 4),
              Text(
                  _mine
                      ? 'Your holdings and amounts are sent to Groq with each question. Not investment advice.'
                      : 'Only your question is sent. Not investment advice.',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),
      ]),
    );
  }
}
