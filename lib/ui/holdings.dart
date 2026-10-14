import 'package:flutter/material.dart';

import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import 'holding.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Sort { value, name, longTerm }

class HoldingsTab extends StatefulWidget {
  final Session session;
  const HoldingsTab({super.key, required this.session});
  @override
  State<HoldingsTab> createState() => _HoldingsTabState();
}

class _HoldingsTabState extends State<HoldingsTab> {
  String _q = '';
  String _filter = 'all'; // all | mf | stock | core | satellite
  _Sort _sort = _Sort.value;

  bool _keep(Holding h) {
    if (_q.isNotEmpty) {
      final i = h.instrument;
      final hay = '${h.name} ${i?.nseSymbol ?? ''} ${i?.schemeCode ?? ''} ${i?.aliases ?? ''}'.toLowerCase();
      if (!hay.contains(_q)) return false;
    }
    return switch (_filter) {
      'mf' => h.isMf,
      'stock' => !h.isMf,
      'core' => h.bucket == 'core',
      'satellite' => h.bucket == 'satellite',
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: widget.session.portfolio,
      builder: (context, p, _) {
        if (p == null) return const Center(child: CircularProgressIndicator());
        final today = p.today;
        double ltShare(Holding h) => h.ledger.units4 == 0
            ? 0
            : h.ledger.open.where((l) => isLongTerm(l.buyDate, today)).fold(0, (a, l) => a + l.units4) /
                h.ledger.units4;
        final list = p.holdings.where(_keep).toList();
        switch (_sort) {
          case _Sort.value:
            break; // already largest first
          case _Sort.name:
            list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          case _Sort.longTerm:
            list.sort((a, b) => ltShare(b).compareTo(ltShare(a)));
        }
        return CustomScrollView(slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Holdings'),
            actions: [
              PopupMenuButton<_Sort>(
                tooltip: 'Sort',
                icon: const Icon(Icons.sort),
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _Sort.value, child: Text('Largest first')),
                  PopupMenuItem(value: _Sort.name, child: Text('Name A–Z')),
                  PopupMenuItem(value: _Sort.longTerm, child: Text('Most long-term')),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(children: [
                TextField(
                  decoration: const InputDecoration(
                      hintText: 'Search name, symbol, scheme code', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final (k, label) in const [
                      ('all', 'All'),
                      ('mf', 'Mutual funds'),
                      ('stock', 'Stocks'),
                      ('core', 'Core'),
                      ('satellite', 'Satellite'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _filter == k,
                          onSelected: (_) => setState(() => _filter = k),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
          if (list.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.search_off,
                title: p.holdings.isEmpty ? 'No holdings yet' : 'Nothing matches',
                message: p.holdings.isEmpty ? 'Tap Add to record a buy or SIP.' : 'Try another search or filter.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              sliver: SliverList.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final h = list[i];
                  final lt = ltShare(h);
                  final share = p.valuePaise == 0 ? 0.0 : h.valuePaise / p.valuePaise;
                  final pct = h.ledger.costPaise == 0 ? 0.0 : h.gainPaise / h.ledger.costPaise;
                  return Card(
                    child: InkWell(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => HoldingScreen(session: widget.session, instrumentId: h.instrumentId))),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: (h.isMf ? cs.series[0] : cs.series[1]).withValues(alpha: 0.15),
                              child: Icon(h.isMf ? Icons.pie_chart_outline : Icons.show_chart,
                                  size: 18, color: h.isMf ? cs.series[0] : cs.series[1]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${formatScaled(h.ledger.units4, 4)} units · ${(share * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontFeatures: tabular)),
                              ]),
                            ),
                            const SizedBox(width: 8),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Money(h.valuePaise, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              if (h.priced)
                                Text('${pct >= 0 ? 'up' : 'down'} ${(pct.abs() * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(fontSize: 12, color: cs.signed(h.gainPaise), fontWeight: FontWeight.w600))
                              else
                                Text('at cost', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                            ]),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: Meter(lt, height: 5, color: cs.gain)),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text('${(lt * 100).round()}% long-term',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                            ),
                            if (h.bucket == 'satellite') ...[const SizedBox(width: 8), Pill('Satellite', color: cs.series[2])],
                            if (h.mismatch || h.stale) ...[
                              const SizedBox(width: 8),
                              Tooltip(
                                message: h.mismatch ? 'Price sources disagree' : 'Price is stale',
                                child: Icon(h.mismatch ? Icons.compare_arrows : Icons.history, size: 16, color: cs.warn),
                              ),
                            ],
                            if (h.ledger.oversold.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.error_outline, size: 16, color: cs.loss),
                            ],
                          ]),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
        ]);
      },
    );
  }
}
