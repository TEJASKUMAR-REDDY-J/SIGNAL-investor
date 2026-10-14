import 'package:flutter/material.dart';

import '../engine/habits.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../engine/tax.dart';
import '../engine/valuation.dart';
import 'patience.dart';
import 'widgets.dart';

/// Financial-year Wrapped: the once-a-year celebration of discipline.
class WrappedScreen extends StatefulWidget {
  final Portfolio p;
  final int fy;
  const WrappedScreen({super.key, required this.p, required this.fy});
  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  final _page = PageController();
  int _i = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final w = wrapped(p, widget.fy);
    final h = habits(p);
    final cs = Theme.of(context).colorScheme;
    final cards = <(IconData, String, Widget, String)>[
      (
        Icons.timeline,
        'You vs the index',
        p.xirr == null
            ? const Text('Prices needed', style: TextStyle(fontSize: 28))
            : Text('${(p.xirr! * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800)),
        p.xirr == null || p.ghostXirr == null
            ? 'Your yearly return since you started.'
            : 'Same money in a Nifty 50 index fund: ${(p.ghostXirr! * 100).toStringAsFixed(1)}%. ${rateSentence(p.xirr!)}',
      ),
      (
        Icons.savings_outlined,
        'Tax saved by waiting',
        Money(w.taxSavedByWaitingPaise, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
        'Versus booking the same ${rupees0(w.ltGainPaise)} of long-term gains as short-term.',
      ),
      (
        Icons.water_drop_outlined,
        'Tax-free room used',
        SizedBox(height: 130, child: ExemptionJar(usedPaise: w.exemptionUsedPaise, today: DateTime.utc(widget.fy + 1, 4, 1), size: 130)),
        '${rupees0(w.exemptionUsedPaise)} of ${rupees0(ltcgExemptionPaise)} used.',
      ),
      (
        Icons.autorenew,
        'SIP months kept',
        Text('${w.sipMonthsKept} / ${w.sipMonthsDue}', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w800)),
        w.sipMonthsDue == 0 ? 'No SIP plans this year.' : 'Showing up every month is the whole game.',
      ),
      (
        Icons.park_outlined,
        'Longest held',
        Text(h.longestHeld?.$1.name ?? '—',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        h.longestHeld == null ? '' : 'Held since ${prettyDay(h.longestHeld!.$2.buyDate)}.',
      ),
    ];
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: Text('FY ${widget.fy}-${(widget.fy + 1) % 100} Wrapped')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (var k = 0; k < cards.length; k++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                      color: k <= _i ? cs.primary : cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(2)),
                ),
              ),
          ]),
        ),
        Expanded(
          child: PageView(
            controller: _page,
            onPageChanged: (i) => setState(() => _i = i),
            children: [
              for (final (icon, title, big, sub) in cards)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(icon, size: 40, color: cs.primary),
                        const SizedBox(height: 16),
                        Text(title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 24),
                        FittedBox(child: big),
                        const SizedBox(height: 20),
                        Text(sub, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, height: 1.4)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Fine('Once a year, on 1 April. Discipline over activity. Estimates, not advice.'),
        ),
      ]),
    );
  }
}

String rupees0(int p) => rupees(p, decimals: false);
