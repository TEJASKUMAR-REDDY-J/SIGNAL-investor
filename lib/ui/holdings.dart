import 'package:flutter/material.dart';

import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import 'activity.dart';
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
              IconButton(
                tooltip: 'All activity',
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => Scaffold(body: ActivityTab(session: widget.session)))),
              ),
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
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _Totals(p: p),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(children: [
                      for (final (i, h) in list.indexed) ...[
                        if (i > 0) const Divider(indent: 68),
                        _Row(session: widget.session, h: h, lt: ltShare(h), share: p.valuePaise == 0 ? 0.0 : h.valuePaise / p.valuePaise),
                      ],
                    ]),
                  ),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}


/// Groww-style strip: current, invested, returns.
class _Totals extends StatelessWidget {
  final Portfolio p;
  const _Totals({required this.p});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget cell(String k, Widget v, [CrossAxisAlignment a = CrossAxisAlignment.start]) => Expanded(
          child: Column(crossAxisAlignment: a, children: [
            Text(k, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 2),
            DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), child: v),
          ]),
        );
    final pct = p.investedPaise == 0 ? 0.0 : p.gainPaise / p.investedPaise;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          cell('Current', Money(p.valuePaise)),
          cell('Invested', Money(p.investedPaise), CrossAxisAlignment.center),
          cell(
              'Returns',
              p.anyPriced
                  ? Text('${pct >= 0 ? '+' : '-'}${(pct.abs() * 100).toStringAsFixed(1)}%', style: TextStyle(color: cs.signed(p.gainPaise)))
                  : const Text('—'),
              CrossAxisAlignment.end),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Session session;
  final Holding h;
  final double lt;
  final double share;
  const _Row({required this.session, required this.h, required this.lt, required this.share});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = h.ledger.costPaise == 0 ? 0.0 : h.gainPaise / h.ledger.costPaise;
    final c = h.isMf ? cs.series[0] : cs.series[1];
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => HoldingScreen(session: session, instrumentId: h.instrumentId))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Text(
              h.name.trim().isEmpty ? '?' : h.name.trim()[0].toUpperCase(),
              style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Row(children: [
                Flexible(
                  child: Text('${formatScaled(h.ledger.units4, 4)} units · ${(lt * 100).round()}% ripe',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ),
                if (h.bucket == 'satellite') ...[const SizedBox(width: 6), Pill('Satellite', color: cs.series[2])],
                if (h.mismatch || h.stale) ...[
                  const SizedBox(width: 6),
                  Icon(h.mismatch ? Icons.compare_arrows : Icons.history, size: 14, color: cs.warn),
                ],
              ]),
            ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Money(h.valuePaise, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            h.priced
                ? Text('${pct >= 0 ? '+' : '-'}${(pct.abs() * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12.5, color: cs.signed(h.gainPaise), fontWeight: FontWeight.w600))
                : Text('at cost', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ]),
        ]),
      ),
    );
  }
}
