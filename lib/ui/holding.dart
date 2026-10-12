import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import 'add_transaction.dart';

class HoldingScreen extends StatelessWidget {
  final ProfileDb db;
  final MarketDb market;
  final int instrumentId;
  const HoldingScreen({super.key, required this.db, required this.market, required this.instrumentId});

  Future<void> _delete(BuildContext context, Transaction t, List<Transaction> all) async {
    if (fifo([for (final x in all) if (x.id != t.id) x.tx]).oversold.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cannot delete: a later sell would exceed units held. Delete or edit that sell first.')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('${t.type.toUpperCase()} on ${t.date}. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await db.deleteTx(t.id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return StreamBuilder(
      stream: (market.select(market.instruments)..where((i) => i.id.equals(instrumentId))).watchSingleOrNull(),
      builder: (context, inst) => Scaffold(
        appBar: AppBar(title: Text(inst.data?.name ?? 'Holding')),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add transaction',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AddTransaction(db: db, market: market, instrumentId: instrumentId))),
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder(
          stream: db.watchTxs(instrumentId),
          builder: (context, s) {
            if (!s.hasData) return const Center(child: CircularProgressIndicator());
            final rows = s.data!;
            final l = fifo(rows.map((r) => r.tx));
            final today = istToday();
            final avg = l.units4 == 0 ? 0 : mulDiv(l.costPaise, unitScale, l.units4);
            return ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 88), children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${formatScaled(l.units4, 4)} units', style: t.titleLarge),
                    Text('Cost ${rupees(l.costPaise)} · avg ${rupees(avg)}'),
                    if (l.dividendsPaise > 0) Text('Dividends ${rupees(l.dividendsPaise)}'),
                    if (inst.data != null)
                      Text(
                          inst.data!.kind == 'mf'
                              ? 'Scheme code ${inst.data!.schemeCode ?? '-'}'
                              : 'NSE ${inst.data!.nseSymbol ?? '-'}',
                          style: t.bodySmall),
                  ]),
                ),
              ),
              if (l.oversold.isNotEmpty)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const ListTile(
                      leading: Icon(Icons.warning),
                      title: Text('A sell exceeds units held. Fix the dates or units below.')),
                ),
              _header(context, 'Open lots (FIFO)'),
              if (l.open.isEmpty) const ListTile(title: Text('No open lots')),
              for (final lot in l.open)
                ListTile(
                  dense: true,
                  leading: Icon(isLongTerm(lot.buyDate, today) ? Icons.check_circle : Icons.hourglass_bottom,
                      color: isLongTerm(lot.buyDate, today) ? Colors.green : null),
                  title: Text('${formatScaled(lot.units4, 4)} units · ${rupees(lot.costPaise)}'),
                  subtitle: Text('Bought ${fmtDay(lot.buyDate)} · '
                      '${isLongTerm(lot.buyDate, today) ? 'long-term since' : 'turns long-term on'} '
                      '${fmtDay(lot.longTermDate)}'),
                ),
              if (l.realized.isNotEmpty) ...[
                _header(context, 'Realised (FIFO matched)'),
                for (final r in l.realized.reversed)
                  ListTile(
                    dense: true,
                    title: Text('${formatScaled(r.units4, 4)} units · gain ${rupees(r.gainPaise)}'),
                    subtitle: Text('${fmtDay(r.buyDate)} → ${fmtDay(r.sellDate)} · ${r.longTerm ? 'LTCG' : 'STCG'}'),
                  ),
              ],
              _header(context, 'Transactions'),
              for (final r in rows.reversed)
                ListTile(
                  title: Text(r.type == 'dividend'
                      ? 'DIVIDEND ${rupees(valuePaise(unitScale, r.priceE4))}'
                      : '${r.type.toUpperCase()} ${formatScaled(r.unitsE4, 4)} @ ₹${formatScaled(r.priceE4, 4, minDecimals: 2)}'),
                  subtitle: Text([r.date, if (r.feesPaise > 0) 'charges ${rupees(r.feesPaise)}', if (r.note.isNotEmpty) r.note]
                      .join(' · ')),
                  trailing: PopupMenuButton<String>(
                    onSelected: (a) => a == 'edit'
                        ? Navigator.push(context,
                            MaterialPageRoute(builder: (_) => AddTransaction(db: db, market: market, existing: r)))
                        : _delete(context, r, rows),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Long-term = held more than 12 months (listed equity / equity MF). '
                    'Lots are recomputed from your transactions each time. Not tax advice.',
                    style: TextStyle(fontSize: 12)),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String s) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
        child: Text(s, style: Theme.of(context).textTheme.titleMedium),
      );
}
