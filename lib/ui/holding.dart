import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../engine/tax.dart';
import 'add_transaction.dart';
import 'theme.dart';
import 'widgets.dart';

class HoldingScreen extends StatelessWidget {
  final Session session;
  final int instrumentId;
  const HoldingScreen({super.key, required this.session, required this.instrumentId});

  ProfileDb get db => session.db;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: session.portfolio,
        builder: (context, p, _) {
          if (p == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          final inst = p.instruments[instrumentId];
          final ledger = p.ledgers[instrumentId] ?? fifo(const []);
          final rows = p.txs.where((t) => t.instrumentId == instrumentId).toList().reversed.toList();
          final bucket = p.holdings.where((h) => h.instrumentId == instrumentId).firstOrNull?.bucket ?? 'core';
          return Scaffold(
            appBar: AppBar(
              title: Text(inst?.name ?? 'Holding', overflow: TextOverflow.ellipsis),
              actions: [
                if (inst != null)
                  IconButton(
                    tooltip: 'Edit name and aliases',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editInstrument(context, inst),
                  ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'add-h',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AddTransaction(session: session, instrumentId: instrumentId))),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
            body: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 100), children: [
              _header(context, p, inst, ledger, bucket),
              if (ledger.oversold.isNotEmpty) ...[
                const SizedBox(height: 8),
                Notice(
                    icon: Icons.error_outline,
                    color: Theme.of(context).colorScheme.loss,
                    text: 'A sell exceeds units held. Fix the dates or units below.'),
              ],
              _ThesisCard(db: db, instrumentId: instrumentId),
              SectionHeader('Open lots', trailing: Text('FIFO', style: Theme.of(context).textTheme.labelMedium)),
              if (ledger.open.isEmpty)
                const Padding(padding: EdgeInsets.all(8), child: Text('No open lots.'))
              else
                Card(child: Column(children: [for (final l in ledger.open) _LotTile(lot: l, today: p.today)])),
              if (ledger.realized.isNotEmpty) ...[
                const SectionHeader('Realised'),
                Card(
                  child: Column(children: [
                    for (final r in ledger.realized.reversed)
                      ListTile(
                        dense: true,
                        title: Wrap(children: [
                          Text('${formatScaled(r.units4, 4)} units  ', style: const TextStyle(fontFeatures: tabular)),
                          Money(r.gainPaise, decimals: true, signed: true, colored: true),
                        ]),
                        subtitle: Text('${prettyDay(r.buyDate)} → ${prettyDay(r.sellDate)}'),
                        trailing: Pill(r.longTerm ? 'LTCG' : 'STCG',
                            color: r.longTerm ? Theme.of(context).colorScheme.gain : Theme.of(context).colorScheme.warn),
                      ),
                  ]),
                ),
              ],
              SectionHeader('History', trailing: Text('${rows.length}')),
              Card(
                child: Column(children: [
                  for (final r in rows)
                    ListTile(
                      leading: Icon(txIcon(r.type)),
                      title: Text('${txLabel(r.type)}  ${txSummary(r)}', style: const TextStyle(fontFeatures: tabular)),
                      subtitle: Text([
                        prettyDay(parseDay(r.date)),
                        if (r.feesPaise > 0) 'charges ${rupees(r.feesPaise)}',
                        if (r.note.isNotEmpty) r.note,
                      ].join(' · ')),
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => AddTransaction(session: session, existing: r))),
                      trailing: IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => deleteTx(context, session, r),
                      ),
                    ),
                ]),
              ),
              const Fine('Long-term = held more than 12 months (listed equity and equity MFs). Lots are rebuilt from '
                  'your transactions every time. Not tax advice.'),
            ]),
          );
        },
      );

  Widget _header(BuildContext context, Portfolio p, Instrument? inst, Ledger l, String bucket) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final avg = l.units4 == 0 ? 0 : mulDiv(l.costPaise, unitScale, l.units4);
    final realized = l.realized.fold(0, (a, r) => a + r.gainPaise);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Pill(inst?.kind == 'mf' ? 'Mutual fund' : 'NSE stock', color: cs.primary),
            Text(inst?.kind == 'mf' ? 'Scheme ${inst?.schemeCode ?? '-'}' : (inst?.nseSymbol ?? ''),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          FittedBox(child: Money(l.costPaise, style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700))),
          Text('${formatScaled(l.units4, 4)} units · avg ${rupees(avg)}',
              style: TextStyle(color: cs.onSurfaceVariant, fontFeatures: tabular)),
          if (realized != 0 || l.dividendsPaise > 0) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 16, runSpacing: 6, children: [
              if (realized != 0)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Realised '),
                  Money(realized, signed: true, colored: true, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              if (l.dividendsPaise > 0)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Dividends '),
                  Money(l.dividendsPaise, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
            ]),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'core', label: Text('Core'), icon: Icon(Icons.shield_outlined)),
                  ButtonSegment(value: 'satellite', label: Text('Satellite'), icon: Icon(Icons.rocket_launch_outlined)),
                ],
                selected: {bucket},
                onSelectionChanged: (v) => db.setBucket(instrumentId, v.first),
              ),
            ),
          ]),
          if (l.units4 > 0) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SellEstimator(ledger: l, realizedAll: p.realized, today: p.today, lastPriceE4: _lastPrice()),
                ),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('What if I sell?'),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  int? _lastPrice() {
    final p = session.portfolio.value!;
    final rows = p.txs.where((t) => t.instrumentId == instrumentId && (t.type == 'buy' || t.type == 'sip' || t.type == 'sell'));
    return rows.isEmpty ? null : rows.last.priceE4;
  }

  Future<void> _editInstrument(BuildContext context, Instrument inst) async {
    final name = TextEditingController(text: inst.name);
    final aliases = TextEditingController(text: inst.aliases);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit fund / stock'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(
            controller: aliases,
            decoration: const InputDecoration(labelText: 'Aliases', helperText: 'Comma separated; used for news matching'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      final m = session.market;
      await (m.update(m.instruments)..where((i) => i.id.equals(inst.id)))
          .write(InstrumentsCompanion(name: Value(name.text.trim()), aliases: Value(aliases.text.trim())));
    }
  }
}

/// Shared delete with the oversell guard.
Future<void> deleteTx(BuildContext context, Session s, Transaction t) async {
  final p = s.portfolio.value!;
  final rest = [for (final x in p.txs) if (x.instrumentId == t.instrumentId && x.id != t.id) x.tx];
  if (fifo(rest).oversold.isNotEmpty) {
    snack(context, 'Cannot delete: a later sell would exceed units held. Edit or delete that sell first.');
    return;
  }
  if (await confirm(context, 'Delete transaction?',
      '${txLabel(t.type)} on ${prettyDay(parseDay(t.date))}. This cannot be undone.')) {
    await s.db.deleteTx(t.id);
    if (context.mounted) snack(context, 'Deleted');
  }
}

class _LotTile extends StatelessWidget {
  final Lot lot;
  final DateTime today;
  const _LotTile({required this.lot, required this.today});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lt = isLongTerm(lot.buyDate, today);
    final total = lot.longTermDate.difference(lot.buyDate).inDays;
    final held = today.difference(lot.buyDate).inDays;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${formatScaled(lot.units4, 4)} units', style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: tabular)),
          ),
          Money(lot.costPaise, decimals: true),
        ]),
        const SizedBox(height: 6),
        Meter(held / total, height: 6, color: lt ? cs.gain : cs.warn),
        const SizedBox(height: 6),
        Wrap(alignment: WrapAlignment.spaceBetween, spacing: 12, runSpacing: 2, children: [
          Text('Bought ${prettyDay(lot.buyDate)}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          Text(
            lt ? 'Long-term since ${prettyDay(lot.longTermDate)}' : 'Long-term ${inDays(lot.longTermDate.difference(today).inDays)} · ${prettyDay(lot.longTermDate)}',
            style: TextStyle(fontSize: 12, color: lt ? cs.gain : cs.warn, fontWeight: FontWeight.w500),
          ),
        ]),
      ]),
    );
  }
}

class _ThesisCard extends StatelessWidget {
  final ProfileDb db;
  final int instrumentId;
  const _ThesisCard({required this.db, required this.instrumentId});

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: (db.select(db.theses)..where((t) => t.instrumentId.equals(instrumentId))).watchSingleOrNull(),
        builder: (context, s) {
          final th = s.data;
          final cs = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Card(
              child: InkWell(
                onTap: () => _edit(context, th),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.lightbulb_outline, size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Why I own this', style: TextStyle(fontWeight: FontWeight.w600))),
                      Icon(th == null ? Icons.add : Icons.edit_outlined, size: 18),
                    ]),
                    const SizedBox(height: 6),
                    if (th == null)
                      Text('Write your reason and what would make you sell. It keeps decisions honest.',
                          style: TextStyle(color: cs.onSurfaceVariant))
                    else ...[
                      Text(th.whyBought),
                      if (th.breaksIf.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Breaks if', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        Text(th.breaksIf),
                      ],
                      if (th.reviewDate != null) ...[
                        const SizedBox(height: 8),
                        Pill('Review ${prettyDay(parseDay(th.reviewDate!))}',
                            color: parseDay(th.reviewDate!).isAfter(istToday()) ? cs.primary : cs.warn,
                            icon: Icons.event),
                      ],
                    ],
                  ]),
                ),
              ),
            ),
          );
        },
      );

  Future<void> _edit(BuildContext context, Thesis? th) async {
    final why = TextEditingController(text: th?.whyBought ?? '');
    final breaks = TextEditingController(text: th?.breaksIf ?? '');
    DateTime? review = th?.reviewDate == null ? null : parseDay(th!.reviewDate!);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Thesis', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: why,
              minLines: 2,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Why I bought it'),
            ),
            TextField(
              controller: breaks,
              minLines: 1,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                  labelText: 'Breaks if', helperText: 'Comma-separated keywords, e.g. auditor, pledge, two weak quarters'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(review == null ? 'Set a review date' : 'Review on ${prettyDay(review!)}'),
              trailing: review == null ? null : IconButton(icon: const Icon(Icons.clear), onPressed: () => set(() => review = null)),
              onTap: () async {
                final d = await showDatePicker(
                    context: ctx,
                    initialDate: review ?? istToday().add(const Duration(days: 180)),
                    firstDate: DateTime.utc(2000),
                    lastDate: DateTime.utc(2100));
                if (d != null) set(() => review = DateTime.utc(d.year, d.month, d.day));
              },
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ]),
        ),
      ),
    );
    if (ok == true && why.text.trim().isNotEmpty) {
      await db.saveThesis(ThesesCompanion.insert(
        instrumentId: Value(instrumentId),
        whyBought: why.text.trim(),
        breaksIf: breaks.text.trim(),
        reviewDate: Value(review == null ? null : fmtDay(review!)),
      ));
    }
  }
}

/// "What if I sell N units at price P today?" with tax versus waiting.
class SellEstimator extends StatefulWidget {
  final Ledger ledger;
  final List<Realized> realizedAll;
  final DateTime today;
  final int? lastPriceE4;
  const SellEstimator({super.key, required this.ledger, required this.realizedAll, required this.today, this.lastPriceE4});
  @override
  State<SellEstimator> createState() => _SellEstimatorState();
}

class _SellEstimatorState extends State<SellEstimator> {
  late final _units = TextEditingController(text: formatScaled(widget.ledger.units4, 4));
  late final _price = TextEditingController(text: widget.lastPriceE4 == null ? '' : formatScaled(widget.lastPriceE4!, 4));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final u = parseScaled(_units.text, 4), pr = parseScaled(_price.text, 4);
    final ok = u != null && pr != null && u > 0 && pr > 0 && u <= widget.ledger.units4;
    final w = ok
        ? compareWait(lots: widget.ledger.open, units4: u, price4: pr, date: widget.today, realizedAll: widget.realizedAll)
        : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('What if I sell?', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _units,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Units', helperText: 'of ${formatScaled(widget.ledger.units4, 4)}'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price / NAV', prefixText: '₹ ', helperText: 'Default: last trade'),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        if (w == null)
          Text('Enter units (up to what you hold) and a price.', style: TextStyle(color: cs.onSurfaceVariant))
        else ...[
          _row('Proceeds', Money(w.now.proceedsPaise, decimals: true)),
          _row('Gain', Money(w.now.gainPaise, decimals: true, signed: true, colored: true)),
          _row('Est. tax if sold today', Money(w.now.extraTaxPaise, decimals: true)),
          if (w.waitUntil != null) ...[
            const Divider(height: 24),
            _row('Est. tax if sold on ${prettyDay(w.waitUntil!)}', Money(w.later!.extraTaxPaise, decimals: true)),
            const SizedBox(height: 8),
            if (w.extraTaxPaise > 0)
              Notice(
                icon: Icons.savings_outlined,
                color: cs.warn,
                text: 'Selling now costs ${rupees(w.extraTaxPaise)} more tax than waiting '
                    '${inDays(w.waitUntil!.difference(widget.today).inDays)} (same price assumed).',
              ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Notice(icon: Icons.check_circle_outline, color: cs.gain, text: 'All units sold here are long-term.'),
            ),
        ],
        const Fine('Uses FIFO lots and this FY\'s realised gains for this profile. Charges, surcharge and other '
            'income not included. An estimate, not advice.'),
      ]),
    );
  }

  Widget _row(String k, Widget v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Expanded(child: Text(k)), DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w600), child: v)]),
      );
}
