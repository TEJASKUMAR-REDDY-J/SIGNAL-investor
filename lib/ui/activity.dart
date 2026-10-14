import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/quick_add.dart';
import '../sources/rss.dart' show normTitle;
import 'add_transaction.dart';
import 'holding.dart';
import 'theme.dart';
import 'widgets.dart';

class ActivityTab extends StatefulWidget {
  final Session session;
  const ActivityTab({super.key, required this.session});
  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  String _type = 'all';
  String _q = '';

  /// Parsed locally with plain rules; only prefills the form for you to confirm.
  void _quickAdd(BuildContext context, String text) {
    final qa = parseQuickAdd(text, istToday());
    if (qa == null) {
      snack(context, 'Start with buy, sell, sip or div');
      return;
    }
    final p = widget.session.portfolio.value!;
    final words = normTitle(qa.query);
    final hit = words.isEmpty
        ? null
        : p.instruments.values.where((i) {
            final hay = ' ${normTitle('${i.name} ${i.nseSymbol ?? ''} ${i.aliases}')} ';
            return words.split(' ').every((w) => hay.contains(' $w') || hay.contains(w));
          }).firstOrNull;
    if (hit == null && words.isNotEmpty) snack(context, 'No match for "${qa.query}". Pick it in the form.');
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddTransaction(
                  session: widget.session,
                  instrumentId: hit?.id,
                  type: qa.type,
                  unitsE4: qa.unitsE4,
                  priceE4: qa.priceE4,
                  amountPaise: qa.amountPaise,
                  date: qa.date,
                )));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: widget.session.portfolio,
      builder: (context, p, _) {
        if (p == null) return const Center(child: CircularProgressIndicator());
        final rows = [
          for (final t in p.txs.reversed)
            if ((_type == 'all' || t.type == _type) &&
                (_q.isEmpty || (p.instruments[t.instrumentId]?.name.toLowerCase().contains(_q) ?? false) ||
                    t.note.toLowerCase().contains(_q)))
              t,
        ];
        // Flatten into month headers + rows for one lazy list.
        final items = <Object>[];
        String? month;
        for (final t in rows) {
          final m = monthYear(parseDay(t.date));
          if (m != month) items.add(month = m);
          items.add(t);
        }
        return CustomScrollView(slivers: [
          const SliverAppBar(floating: true, title: Text('Activity')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Column(children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Type to add: sip 5000 nifty today',
                    prefixIcon: Icon(Icons.bolt),
                    helperText: 'buy 10 infy 1520 · sell 5 tcs 3100 yesterday · div 250 itc',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) => _quickAdd(context, v),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(hintText: 'Search fund, stock or note', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final k in const ['all', 'buy', 'sip', 'sell', 'dividend', 'split', 'bonus'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(k == 'all' ? 'All' : txLabel(k)),
                          selected: _type == k,
                          onSelected: (_) => setState(() => _type = k),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
          ),
          if (items.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions', message: 'Entries you add show up here, newest first.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final it = items[i];
                  if (it is String) return SectionHeader(it);
                  final t = it as Transaction;
                  final name = p.instruments[t.instrumentId]?.name ?? 'Unknown';
                  final color = switch (t.type) {
                    'sell' => cs.warn,
                    'dividend' || 'bonus' => cs.gain,
                    _ => cs.primary,
                  };
                  return Dismissible(
                    key: ValueKey('tx-${t.id}'),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async {
                      await deleteTx(context, widget.session, t);
                      return false; // the stream rebuilds the list if it was deleted
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(16)),
                      child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.14),
                            child: Icon(txIcon(t.type), color: color, size: 20),
                          ),
                          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${txLabel(t.type)} · ${txSummary(t)}', style: const TextStyle(fontFeatures: tabular)),
                          trailing: Text('${parseDay(t.date).day} ${months[parseDay(t.date).month - 1]}',
                              style: TextStyle(color: cs.onSurfaceVariant)),
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => AddTransaction(session: widget.session, existing: t))),
                        ),
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
