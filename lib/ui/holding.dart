import 'package:drift/drift.dart' show Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../engine/valuation.dart';
import 'add_transaction.dart';
import 'news.dart';
import 'patience.dart';
import 'sell_flow.dart';
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
          final cs = Theme.of(context).colorScheme;
          final inst = p.instruments[instrumentId];
          final ledger = p.ledgers[instrumentId] ?? fifo(const []);
          final rows = p.txs.where((t) => t.instrumentId == instrumentId).toList().reversed.toList();
          final h = p.holdings.where((h) => h.instrumentId == instrumentId).firstOrNull;
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
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => AddTransaction(session: session, instrumentId: instrumentId))),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
            body: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 100), children: [
              _header(context, p, inst, ledger, h),
              if (ledger.oversold.isNotEmpty) ...[
                const SizedBox(height: 8),
                Notice(icon: Icons.error_outline, color: cs.loss, text: 'A sell exceeds units held. Fix the dates or units below.'),
              ],
              if (p.book.series(instrumentId).length > 5) ...[
                const SectionHeader('Price, 1 year'),
                Card(child: Padding(padding: const EdgeInsets.fromLTRB(8, 16, 16, 8), child: _PriceChart(p: p, id: instrumentId))),
              ],
              _ThesisCard(db: db, instrumentId: instrumentId),
              if (ledger.open.isNotEmpty) ...[
                const SectionHeader('Your lots, ripening'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Orchard(lots: ledger.open, today: p.today),
                      const SizedBox(height: 10),
                      Text('A lot ripens 12 months and a day after you buy it. Ripe lots are long-term and cheaper to sell.',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ]),
                  ),
                ),
              ],
              SectionHeader('Open lots', trailing: Text('FIFO', style: Theme.of(context).textTheme.labelMedium)),
              if (ledger.open.isEmpty)
                const Padding(padding: EdgeInsets.all(8), child: Text('No open lots.'))
              else
                Card(child: Column(children: [for (final l in ledger.open) _LotTile(lot: l, today: p.today)])),
              if (inst?.kind == 'stock') NewsSection(session: session, instrumentId: instrumentId),
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
                        trailing: Pill(r.longTerm ? 'LTCG' : 'STCG', color: r.longTerm ? cs.gain : cs.warn),
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
                        if (r.sttPaise > 0) 'STT ${rupees(r.sttPaise)}',
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
                  'your transactions every time. Prices are end-of-day from public sources. Not tax advice.'),
            ]),
          );
        },
      );

  Widget _header(BuildContext context, Portfolio p, Instrument? inst, Ledger l, Holding? h) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final avg = l.units4 == 0 ? 0 : mulDiv(l.costPaise, unitScale, l.units4);
    final realized = l.realized.fold(0, (a, r) => a + r.gainPaise);
    final cc = p.book.crossCheck(instrumentId);
    final bucket = h?.bucket ?? 'core';
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
          FittedBox(child: Money(h?.valuePaise ?? l.costPaise, style: t.headlineLarge?.copyWith(fontWeight: FontWeight.w700))),
          if (h != null && h.priced) ...[
            Wrap(children: [
              Money(h.gainPaise, signed: true, colored: true, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                  ' ${h.gainPaise >= 0 ? 'up' : 'down'} ${l.costPaise == 0 ? 0 : (h.gainPaise.abs() * 100 / l.costPaise).toStringAsFixed(1)}% on cost ${rupees(l.costPaise, decimals: false)}',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ]),
            if (h.xirr != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('XIRR ${(h.xirr! * 100).toStringAsFixed(1)}% a year. ${rateSentence(h.xirr!)}',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
              ),
          ] else
            Text('At cost. Market price appears after the next refresh.', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text('${formatScaled(l.units4, 4)} units · avg ${rupees(avg)}',
              style: TextStyle(color: cs.onSurfaceVariant, fontFeatures: tabular)),
          if (h?.price != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('${priceLabel(h!.price!.closeE4)} on ${prettyDay(h.price!.day)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontFeatures: tabular)),
                if (cc != null)
                  Pill(
                    cc.$3 > mismatchBps ? 'NSE check ${(cc.$3 / 100).toStringAsFixed(2)}% off' : 'NSE check',
                    color: cc.$3 > mismatchBps ? cs.loss : cs.gain,
                    icon: cc.$3 > mismatchBps ? Icons.compare_arrows : Icons.verified_outlined,
                  ),
                if (h.stale) Pill('stale', color: cs.warn, icon: Icons.history),
              ]),
            ),
          if (h != null && h.mismatch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Notice(
                  icon: Icons.compare_arrows,
                  color: cs.loss,
                  text: 'Yahoo and NSE closes differ by more than 0.5%. No signals for this holding until they agree.'),
            ),
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
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'core', label: Text('Core'), icon: Icon(Icons.shield_outlined)),
              ButtonSegment(value: 'satellite', label: Text('Satellite'), icon: Icon(Icons.rocket_launch_outlined)),
            ],
            selected: {bucket},
            onSelectionChanged: (v) => db.setBucket(instrumentId, v.first),
          ),
          if (l.units4 > 0 && h != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: h.priced
                      ? () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => SellFlow(session: session, instrumentId: instrumentId)))
                      : () => snack(context, 'Needs a market price first: pull to refresh on Home.'),
                  icon: const Icon(Icons.psychology_alt_outlined),
                  label: const Text('Thinking of selling?'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: 'Check against your statement',
                onPressed: () => _statementCheck(context, l),
                icon: const Icon(Icons.fact_check_outlined),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  /// Type the units from a CAS / broker statement; show any difference.
  Future<void> _statementCheck(BuildContext context, Ledger l) async {
    final c = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
        final v = parseScaled(c.text, 4);
        final diff = v == null ? null : v - l.units4;
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Check against statement'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('App: ${formatScaled(l.units4, 4)} units'),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Units on your CAMS / KFintech / broker statement'),
              onChanged: (_) => set(() {}),
            ),
            const SizedBox(height: 12),
            if (diff != null)
              diff == 0
                  ? Text('Matches exactly.', style: TextStyle(color: cs.gain, fontWeight: FontWeight.w600))
                  : Text(
                      '${diff > 0 ? 'Statement has' : 'App has'} ${formatScaled(diff.abs(), 4)} more units. '
                      '${diff.abs() <= 10 ? 'Tiny gap: likely unit rounding or stamp duty; edit the units of one entry.' : 'Look for a missing or mistyped entry.'}',
                      style: TextStyle(color: cs.warn)),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
        );
      }),
    );
    c.dispose();
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

class _PriceChart extends StatelessWidget {
  final Portfolio p;
  final int id;
  const _PriceChart({required this.p, required this.id});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = p.book.series(id);
    final from = all.last.day.subtract(const Duration(days: 365));
    final start = all.indexWhere((b) => !b.day.isBefore(from));
    final bars = all.sublist(start < 0 ? 0 : start);
    final sma = <FlSpot>[];
    var sum = 0;
    for (var i = 0; i < all.length; i++) {
      sum += all[i].closeE4;
      if (i >= 200) sum -= all[i - 200].closeE4;
      final j = i - (all.length - bars.length);
      if (i >= 199 && j >= 0) sma.add(FlSpot(j.toDouble(), sum / 200 / 10000));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 170,
        child: RepaintBoundary(
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => cs.inverseSurface,
                getTooltipItems: (ts) => [
                  for (final t in ts)
                    LineTooltipItem(
                        t.barIndex == 0
                            ? '${prettyDay(bars[t.x.toInt()].day)}\n₹${t.y.toStringAsFixed(2)}'
                            : '200-day ₹${t.y.toStringAsFixed(2)}',
                        TextStyle(color: cs.onInverseSurface, fontSize: 12)),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (final (i, b) in bars.indexed) FlSpot(i.toDouble(), b.closeE4 / 10000)],
                color: cs.primary,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [cs.primary.withValues(alpha: 0.2), cs.primary.withValues(alpha: 0)])),
              ),
              if (sma.isNotEmpty)
                LineChartBarData(spots: sma, color: cs.warn, barWidth: 1.5, dashArray: [5, 4], dotData: const FlDotData(show: false)),
            ],
          )),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 8, top: 6),
        child: Wrap(spacing: 14, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 12, height: 3, color: cs.primary), const Text('  Close')]),
          if (sma.isNotEmpty)
            Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 12, height: 3, color: cs.warn), const Text('  200-day average')]),
        ]),
      ),
    ]);
  }
}

/// Delete with the oversell guard; Undo instead of an "are you sure?" dialog.
Future<void> deleteTx(BuildContext context, Session s, Transaction t) async {
  final p = s.portfolio.value!;
  final rest = [for (final x in p.txs) if (x.instrumentId == t.instrumentId && x.id != t.id) x.tx];
  if (fifo(rest).oversold.isNotEmpty) {
    snack(context, 'Cannot delete: a later sell would exceed units held. Edit or delete that sell first.');
    return;
  }
  await s.db.deleteTx(t.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('Deleted ${txLabel(t.type).toLowerCase()} of ${prettyDay(parseDay(t.date))}'),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(label: 'Undo', onPressed: () => s.db.restoreTx(t)),
    ));
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
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Thesis broken'),
                        subtitle: const Text('Rule 1: lets a sell suggestion override the 12-month wait'),
                        value: th.broken,
                        onChanged: (v) => db.setThesisBroken(instrumentId, v),
                      ),
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
