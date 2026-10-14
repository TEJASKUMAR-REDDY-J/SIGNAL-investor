import 'package:flutter/material.dart';

import '../engine/fund_rank.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../engine/scoring.dart';
import 'theme.dart';
import 'widgets.dart';

String _pct(num x, {bool signed = false}) => '${signed && x >= 0 ? '+' : ''}${(x * 100).toStringAsFixed(1)}%';

/// Growth and worst fall from the stored price history (any instrument).
FundMetrics? historyMetrics(Portfolio p, int id) =>
    fundMetrics('', '', '', [for (final b in p.book.series(id)) (fmtDay(b.day), b.closeE4)]);

/// Plain sentences for the AI: price history and, if owned, the position itself.
List<String> returnFacts(Portfolio p, int id) {
  final m = historyMetrics(p, id);
  final h = p.holdings.where((h) => h.instrumentId == id).firstOrNull;
  return [
    if (m != null)
      'Price history: ${[
        if (m.cagr1 != null) '1 year ${_pct(m.cagr1!, signed: true)}',
        if (m.cagr3 != null) '3 years ${_pct(m.cagr3!)} a year',
        if (m.cagr5 != null) '5 years ${_pct(m.cagr5!)} a year',
        'worst fall ${_pct(m.maxDrawdown)}',
      ].join(', ')}',
    if (h != null)
      'I own ${formatScaled(h.ledger.units4, 4)} units, cost ${rupees(h.ledger.costPaise)}, now ${rupees(h.valuePaise)} '
          '(${h.gainPaise >= 0 ? 'gain' : 'loss'} ${rupees(h.gainPaise.abs())})${h.xirr == null ? '' : ', XIRR ${_pct(h.xirr!)} a year'}, '
          '${(h.valuePaise * 100 / (p.valuePaise == 0 ? 1 : p.valuePaise)).toStringAsFixed(1)}% of my portfolio',
  ];
}

List<String> fundamentalFacts(Map<String, num?> f) => [
      for (final (k, label, pct) in const [
        ('pe', 'P/E (trailing)', false),
        ('forwardPe', 'P/E (forward)', false),
        ('roe', 'Return on equity', true),
        ('revenueGrowth', 'Sales growth, year on year', true),
        ('earningsGrowth', 'Profit growth, year on year', true),
        ('operatingMargins', 'Operating margin', true),
        ('dividendYield', 'Dividend yield', true),
        ('beta', 'Beta', false),
      ])
        if (f[k] != null) '$label: ${pct ? _pct(f[k]!) : f[k]!.toStringAsFixed(2)}',
      if (f['debtToEquity'] != null) 'Debt to equity: ${(f['debtToEquity']! / 100).toStringAsFixed(2)}x',
      if (f['marketCap'] != null) 'Market cap: ₹${(f['marketCap']! / 1e7).round()} crore',
      if (f['high52'] != null && f['low52'] != null) '52-week range: ₹${f['low52']} to ₹${f['high52']}',
    ];

class ReturnsCard extends StatelessWidget {
  final Portfolio p;
  final int id;
  final bool isFund;
  const ReturnsCard({super.key, required this.p, required this.id, required this.isFund});

  @override
  Widget build(BuildContext context) {
    final m = historyMetrics(p, id);
    if (m == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    Widget cell(String k, String v, Color? c) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(v, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c, fontFeatures: tabular)),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SectionHeader(isFund ? 'How it has grown' : 'Price growth'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              cell('1 year', m.cagr1 == null ? '—' : _pct(m.cagr1!, signed: true), m.cagr1 == null ? null : cs.signed((m.cagr1! * 10000).round())),
              cell('3 years', m.cagr3 == null ? '—' : '${_pct(m.cagr3!)}/yr', null),
              cell('5 years', m.cagr5 == null ? '—' : '${_pct(m.cagr5!)}/yr', null),
              cell('Worst fall', '-${_pct(m.maxDrawdown)}', cs.loss),
            ]),
            const SizedBox(height: 10),
            Text(
                m.cagr3 != null && m.cagr3! > 0
                    ? 'At ${_pct(m.cagr3!)} a year, money doubles in about ${(72 / (m.cagr3! * 100)).toStringAsFixed(0)} years. '
                        'The worst fall shows what holding through a bad patch felt like.'
                    : 'Growth figures need at least 3 years of history.',
                style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
            if (!isFund) Text('Price only; dividends not included.', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
          ]),
        ),
      ),
    ]);
  }
}

/// Fundamentals in plain words. The verdicts are rough rules of thumb, not ratings.
class KeyNumbers extends StatelessWidget {
  final Map<String, num?>? f;
  final bool loading;
  final Session session;
  final String? symbol;
  const KeyNumbers({super.key, required this.f, required this.loading, required this.session, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (f == null) return const SizedBox.shrink();
    final f0 = f!;
    final rows = <(String, String, String, Color)>[];
    void add(String label, num? v, String Function(num) fmt, (String, Color) Function(num) verdict) {
      if (v != null) {
        final (w, c) = verdict(v);
        rows.add((label, fmt(v), w, c));
      }
    }

    (String, Color) growth(num g) => g >= 0.15
        ? ('Fast', cs.gain)
        : g >= 0.05
            ? ('Steady', cs.primary)
            : g >= 0
                ? ('Slow', cs.warn)
                : ('Shrinking', cs.loss);
    add('Sales growth (YoY)', f0['revenueGrowth'], (v) => _pct(v, signed: true), growth);
    add('Profit growth (YoY)', f0['earningsGrowth'], (v) => _pct(v, signed: true), growth);
    add('Return on equity', f0['roe'], _pct,
        (v) => v >= 0.2 ? ('Strong', cs.gain) : (v >= 0.12 ? ('OK', cs.primary) : ('Weak', cs.loss)));
    add('Debt to equity', f0['debtToEquity'], (v) => '${(v / 100).toStringAsFixed(2)}x',
        (v) => v <= 50 ? ('Low', cs.gain) : (v <= 100 ? ('Moderate', cs.warn) : ('High', cs.loss)));
    add('Operating margin', f0['operatingMargins'], _pct,
        (v) => v >= 0.2 ? ('High', cs.gain) : (v >= 0.1 ? ('OK', cs.primary) : ('Thin', cs.warn)));
    add('P/E', f0['pe'], (v) => v.toStringAsFixed(1),
        (v) => v <= 0 ? ('Loss-making', cs.loss) : (v < 15 ? ('Low', cs.gain) : (v <= 35 ? ('Moderate', cs.primary) : ('High', cs.warn))));
    add('Dividend yield', f0['dividendYield'], _pct, (v) => v >= 0.02 ? ('Pays well', cs.gain) : ('Small', cs.onSurfaceVariant));
    add('Market cap', f0['marketCap'], (v) => '₹${_crore(v / 1e7)} Cr',
        (v) => v >= 1e12 ? ('Large cap', cs.primary) : (v >= 2e11 ? ('Mid cap', cs.primary) : ('Small cap', cs.warn)));

    final hi = f0['high52'], lo = f0['low52'];
    final ideas = session.stockIdeas.value ?? const <Candidate>[];
    final rank = ideas.indexWhere((c) => c.input.symbol == symbol);
    final probe = ScanInput(symbol ?? '', '', '', f0, const [], DateTime.now());
    final why = filterOut(probe);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader('Key numbers'),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final (label, value, word, color) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Text(label)),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: tabular)),
                  const SizedBox(width: 10),
                  SizedBox(width: 92, child: Align(alignment: Alignment.centerRight, child: Pill(word, color: color))),
                ]),
              ),
            if (hi != null && lo != null && hi > lo) ...[
              const SizedBox(height: 8),
              Text('52-week range ₹${lo.toStringAsFixed(0)} – ₹${hi.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 8),
            Notice(
              icon: rank >= 0 ? Icons.emoji_events_outlined : (why == null || why.contains('history') ? Icons.check_circle_outline : Icons.info_outline),
              color: rank >= 0 ? cs.gain : cs.primary,
              text: rank >= 0
                  ? 'Advisor: #${rank + 1} of today\'s top ${ideas.length} ideas. ${ideas[rank].reasons.join('. ')}.'
                  : (why == null || why.contains('history')
                      ? 'Advisor: passes the quality checks (ROE, debt, cash flow, size).'
                      : 'Advisor: left out because ${why.replaceFirst(' or missing', '')}.'),
            ),
            const Fine('Labels are rough rules of thumb, not ratings. Data: Yahoo Finance (unofficial), latest reported figures.'),
          ]),
        ),
      ),
    ]);
  }
}

String _crore(num c) {
  final s = c.round().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}
