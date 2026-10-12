import 'dart:convert';

import 'package:flutter/material.dart';

import '../db/db.dart';
import '../db/open_db.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/tax.dart';
import 'add_transaction.dart';
import 'holding.dart';

class Dashboard extends StatefulWidget {
  final Profile profile;
  final ProfileDb db;
  final MarketDb market;
  final VoidCallback onLock;
  const Dashboard(
      {super.key, required this.profile, required this.db, required this.market, required this.onLock});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // Tile key -> size 1 (small), 2 (wide), 3 (large). Layout only, no money.
  Map<String, int> _sizes = {};
  late final _txs = widget.db.watchTxs();
  late final _instruments = widget.market.select(widget.market.instruments).watch();

  String get _layoutKey => 'layout_${widget.profile.id}';

  @override
  void initState() {
    super.initState();
    storage.read(key: _layoutKey).then((s) {
      if (s != null && mounted) setState(() => _sizes = Map<String, int>.from(jsonDecode(s)));
    });
  }

  int _size(String key) => _sizes[key] ?? (key == 'summary' ? 3 : 1);

  void _resize(String key) {
    setState(() => _sizes[key] = _size(key) % 3 + 1);
    storage.write(key: _layoutKey, value: jsonEncode(_sizes));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.profile.name),
          actions: [
            IconButton(tooltip: 'Lock', icon: const Icon(Icons.lock), onPressed: widget.onLock),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AddTransaction(db: widget.db, market: widget.market))),
          icon: const Icon(Icons.add),
          label: const Text('Transaction'),
        ),
        body: StreamBuilder(
          stream: _instruments,
          builder: (context, inst) => StreamBuilder(
            stream: _txs,
            builder: (context, txs) {
              if (!inst.hasData || !txs.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return _grid(context, {for (final i in inst.data!) i.id: i}, txs.data!);
            },
          ),
        ),
      );

  Widget _grid(BuildContext context, Map<int, Instrument> inst, List<Transaction> txs) {
    final byInst = <int, List<Tx>>{};
    for (final t in txs) {
      (byInst[t.instrumentId] ??= []).add(t.tx);
    }
    final ledgers = {for (final e in byInst.entries) e.key: fifo(e.value)};
    final realized = [for (final l in ledgers.values) ...l.realized];
    final held = ledgers.entries.where((e) => e.value.units4 > 0).toList()
      ..sort((a, b) => b.value.costPaise.compareTo(a.value.costPaise));

    final tiles = <(String, Widget Function(int))>[
      ('summary', (s) => _Summary(ledgers: ledgers.values, realized: realized, size: s)),
      for (final e in held)
        ('i${e.key}', (s) => _HoldingTile(
              instrument: inst[e.key],
              ledger: e.value,
              size: s,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => HoldingScreen(
                          db: widget.db, market: widget.market, instrumentId: e.key))),
            )),
    ];

    return LayoutBuilder(builder: (context, c) {
      const gap = 8.0;
      final cols = c.maxWidth < 600 ? 2 : (c.maxWidth < 900 ? 3 : 4);
      final unit = (c.maxWidth - gap * (cols + 1)) / cols;
      double width(int size) => size == 1 ? unit : (size == 2 && cols > 2 ? unit * 2 + gap : c.maxWidth - gap * 2);
      return ListView(padding: const EdgeInsets.all(gap), children: [
        Wrap(spacing: gap, runSpacing: gap, children: [
          for (final (key, build) in tiles)
            SizedBox(
              key: ValueKey('tile-$key'),
              width: width(_size(key)),
              child: GestureDetector(
                onLongPress: () => _resize(key),
                child: build(_size(key)),
              ),
            ),
        ]),
        if (held.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No holdings yet. Tap + Transaction to add your first buy or SIP.'),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(8, 16, 8, 80),
          child: Text('Long-press a tile to resize. Values are at cost (live prices arrive in a later phase). '
              'Estimates only, not advice.',
              style: TextStyle(fontSize: 12)),
        ),
      ]);
    });
  }
}

class _Summary extends StatelessWidget {
  final Iterable<Ledger> ledgers;
  final List<Realized> realized;
  final int size;
  const _Summary({required this.ledgers, required this.realized, required this.size});

  @override
  Widget build(BuildContext context) {
    final fy = fyOf(istToday());
    final tax = fyTax(realized, fy);
    final g = fyGains(realized, fy);
    final invested = ledgers.fold(0, (a, l) => a + l.costPaise);
    final divs = ledgers.fold(0, (a, l) => a + l.dividendsPaise);
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Invested (cost)', style: t.labelMedium),
          FittedBox(child: Text(rupees(invested, decimals: false), style: t.headlineMedium)),
          if (size >= 2) ...[
            const SizedBox(height: 8),
            Text('FY $fy-${(fy + 1) % 100} realised: ST ${rupees(g.st, decimals: false)} · '
                'LT ${rupees(g.lt, decimals: false)}'),
            Text('LTCG exemption left: ${rupees(tax.exemptionLeftPaise, decimals: false)}'),
          ],
          if (size >= 3) ...[
            Text('Est. tax on this FY\'s sales: ${rupees(tax.taxPaise)}'),
            Text('Dividends received (all time): ${rupees(divs, decimals: false)}'),
            const SizedBox(height: 4),
            Text('Estimate: equity rules only, excludes surcharge and other income. Not tax advice.',
                style: t.bodySmall),
          ],
        ]),
      ),
    );
  }
}

class _HoldingTile extends StatelessWidget {
  final Instrument? instrument;
  final Ledger ledger;
  final int size;
  final VoidCallback onTap;
  const _HoldingTile(
      {required this.instrument, required this.ledger, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final today = istToday();
    final lt = ledger.open.where((l) => isLongTerm(l.buyDate, today)).fold(0, (a, l) => a + l.units4);
    final nextLt = ledger.open.map((l) => l.longTermDate).where((d) => d.isAfter(today)).firstOrNull;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(instrument?.kind == 'mf' ? Icons.pie_chart_outline : Icons.show_chart, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(instrument?.name ?? 'Unknown #${instrument?.id}',
                    maxLines: size == 1 ? 2 : 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
              ),
            ]),
            const SizedBox(height: 6),
            Text(rupees(ledger.costPaise, decimals: false), style: t.titleLarge),
            Text('${formatScaled(ledger.units4, 4)} units', style: t.bodySmall),
            if (size >= 2) ...[
              const SizedBox(height: 4),
              Text('Long-term units: ${formatScaled(lt, 4)}', style: t.bodySmall),
              if (nextLt != null) Text('Next lot turns long-term: ${fmtDay(nextLt)}', style: t.bodySmall),
            ],
            if (ledger.oversold.isNotEmpty)
              Text('Check entries: a sell exceeds units held', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
      ),
    );
  }
}
