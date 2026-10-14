import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/open_db.dart';
import '../engine/calendar.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../sources/groq.dart';
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
      final a = await ask(_net, key, model, text,
          webSearch: _web,
          history: history,
          context: [if (_mine) ...portfolioFacts(widget.session), ...widget.extraContext]);
      if (mounted) {
        setState(() => _chat.add((false, '${a.text}${a.searches > 0 ? '\n\n(${a.searches} web search${a.searches == 1 ? '' : 'es'})' : ''}')));
      }
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
