import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../engine/tax.dart';
import '../engine/valuation.dart';
import '../sources/mfapi.dart';
import '../sources/net.dart';
import '../sources/yahoo.dart';
import 'patience.dart';
import 'theme.dart';
import 'widgets.dart';

/// Virtual starting cash for the sandbox.
const paperCashPaise = 100000000; // Rs 10,00,000

/// Paper trades as ledger rows, so the same engine values them.
List<Transaction> paperTxs(List<PaperTrade> t) => [
      for (final x in t)
        Transaction(
            id: x.id, instrumentId: x.instrumentId, date: x.date, type: x.type, unitsE4: x.unitsE4, priceE4: x.priceE4,
            feesPaise: 0, note: x.reason, sttPaise: 0),
    ];

int paperCash(List<PaperTrade> t) {
  var c = paperCashPaise;
  for (final x in t) {
    final v = valuePaise(x.unitsE4, x.priceE4);
    c += x.type == 'sell' ? v : -v;
  }
  return c;
}

/// The sandbox: practise with virtual money at real prices. Patience is the game:
/// lots ripen, short-term exits show their tax, and the ghost index runs alongside.
class SandboxScreen extends StatelessWidget {
  final Session session;
  final int? buyInstrumentId;
  const SandboxScreen({super.key, required this.session, this.buyInstrumentId});

  @override
  Widget build(BuildContext context) {
    final db = session.db;
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: (db.select(db.paperTrades)..orderBy([(t) => OrderingTerm.asc(t.date), (t) => OrderingTerm.asc(t.id)])).watch(),
      builder: (context, snap) {
        final trades = snap.data ?? const <PaperTrade>[];
        final real = session.portfolio.value!;
        final p = Portfolio.compute(txs: paperTxs(trades), instruments: real.instruments.values.toList(), book: real.book);
        final cash = paperCash(trades);
        final total = cash + p.valuePaise;
        if (buyInstrumentId != null && snap.hasData && trades.every((t) => t.instrumentId != buyInstrumentId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && ModalRoute.of(context)?.isCurrent == true) _buy(context, cash, buyInstrumentId);
          });
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Sandbox')),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'paper-buy',
            onPressed: () => _buy(context, cash, null),
            icon: const Icon(Icons.add),
            label: const Text('Paper buy'),
          ),
          body: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 100), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.science_outlined, color: cs.primary),
                    const SizedBox(width: 8),
                    const Text('Paper money only. Real prices.', style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 10),
                  FittedBox(child: Money(total, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700))),
                  Wrap(children: [
                    Text('from ${rupees(paperCashPaise, decimals: false)} · ', style: TextStyle(color: cs.onSurfaceVariant)),
                    Money(total - paperCashPaise, signed: true, colored: true),
                  ]),
                  const SizedBox(height: 6),
                  Text('Cash ${rupees(cash, decimals: false)} · invested ${rupees(p.valuePaise, decimals: false)}',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  if (p.xirr != null && p.ghostXirr != null) ...[
                    const SizedBox(height: 6),
                    Text('You ${(p.xirr! * 100).toStringAsFixed(1)}% a year vs Nifty 50 ghost ${(p.ghostXirr! * 100).toStringAsFixed(1)}%'),
                  ],
                ]),
              ),
            ),
            if (p.holdings.isEmpty)
              const EmptyState(
                icon: Icons.spa_outlined,
                title: 'An empty sandbox',
                message: 'Make a paper buy, then do the hard part: wait. Lots ripen after 12 months.',
              ),
            for (final h in p.holdings)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(h.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Money(h.valuePaise, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                      Text(
                          h.priced
                              ? '${formatScaled(h.ledger.units4, 4)} units · ${h.gainPaise >= 0 ? 'up' : 'down'} ${rupees(h.gainPaise.abs(), decimals: false)}'
                              : '${formatScaled(h.ledger.units4, 4)} units · price pending',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 10),
                      Orchard(lots: h.ledger.open, today: p.today),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(onPressed: h.priced ? () => _sell(context, p, h) : null, child: const Text('Paper sell')),
                      ),
                    ]),
                  ),
                ),
              ),
            const Fine('Nothing here is a real order. Prices are the latest real closes; buys use them as of today.'),
          ]),
        );
      },
    );
  }

  Future<void> _buy(BuildContext context, int cash, int? instrumentId) async {
    final real = session.portfolio.value!;
    final list = real.instruments.values.where((i) => i.kind != 'index').toList()..sort((a, b) => a.name.compareTo(b.name));
    int? id = instrumentId ?? list.firstOrNull?.id;
    final amount = TextEditingController(text: '50000');
    final reason = TextEditingController();
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Paper buy', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: id,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Fund or stock', helperText: 'Add new ones with Add on Home or from the scan'),
              items: [for (final i in list) DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => set(() => id = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount', prefixText: '₹ ', helperText: 'Cash left ${rupees(cash, decimals: false)}'),
            ),
            TextField(controller: reason, maxLength: 140, decoration: const InputDecoration(labelText: 'Why? (your thesis)')),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buy at latest price')),
          ]),
        ),
      ),
    );
    if (go != true || id == null || !context.mounted) return;
    final amt = parseScaled(amount.text, 2) ?? 0;
    if (amt <= 0 || amt > cash) return snack(context, 'Amount must be within your paper cash.');
    final price = await _latestPrice(id!);
    if (!context.mounted) return;
    if (price == null) return snack(context, 'No price yet for this one. Try again after a refresh.');
    await session.db.addPaperTrade(PaperTradesCompanion.insert(
        instrumentId: id!, date: fmtDay(istToday()), type: 'buy', unitsE4: unitsFor(amt, price.closeE4), priceE4: price.closeE4,
        reason: Value(reason.text.trim())));
    if (context.mounted) snack(context, 'Bought on paper at ₹${formatScaled(price.closeE4, 4, minDecimals: 2)} (${prettyDay(price.day)})');
  }

  /// Latest known close; fetch one if this instrument has none yet.
  Future<Bar?> _latestPrice(int id) async {
    final real = session.portfolio.value!;
    final b = real.book.latest(id);
    if (b != null) return b;
    final i = real.instruments[id];
    if (i == null) return null;
    final net = Net();
    try {
      final rows = i.kind == 'mf' && i.schemeCode != null
          ? (await mfNavs(net, i.schemeCode!, latestOnly: true)).navs
          : (i.yahooTicker != null ? await yahooDaily(net, i.yahooTicker!) : const <(String, int)>[]);
      if (rows.isEmpty) return null;
      await session.market.putPrices(id, i.kind == 'mf' ? 'mfapi' : 'yahoo', rows);
      return Bar(parseDay(rows.last.$1), rows.last.$2);
    } catch (_) {
      return null;
    }
  }

  Future<void> _sell(BuildContext context, Portfolio p, Holding h) async {
    final reason = TextEditingController();
    final w = compareWait(lots: h.ledger.open, units4: h.ledger.units4, price4: h.price!.closeE4, date: p.today, realizedAll: p.realized);
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Paper sell: ${h.name}', style: Theme.of(ctx).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (w.extraTaxPaise > 0)
              Text('In real life this would cost ${rupees(w.extraTaxPaise)} more tax than waiting until ${prettyDay(w.waitUntil!)}.',
                  textAlign: TextAlign.center, style: TextStyle(color: cs.warn)),
            TextField(controller: reason, maxLength: 140, decoration: const InputDecoration(labelText: 'Why sell? (required)'), onChanged: (_) => set(() {})),
            const SizedBox(height: 12),
            if (reason.text.trim().length >= 5)
              HoldToConfirm(
                label: 'Hold to paper sell',
                sublabel: w.extraTaxPaise > 0 ? '+${rupees(w.extraTaxPaise, decimals: false)}\ntax' : null,
                color: w.extraTaxPaise > 0 ? cs.warn : cs.primary,
                onConfirmed: () async {
                  await session.db.addPaperTrade(PaperTradesCompanion.insert(
                      instrumentId: h.instrumentId, date: fmtDay(istToday()), type: 'sell', unitsE4: h.ledger.units4,
                      priceE4: h.price!.closeE4, reason: Value(reason.text.trim())));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              )
            else
              Text('Write a reason first.', style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

/// Instruments held in the sandbox, so the refresher keeps their prices current.
Set<int> paperHeld(List<PaperTrade> t) {
  final u = <int, int>{};
  for (final x in t) {
    u[x.instrumentId] = (u[x.instrumentId] ?? 0) + (x.type == 'sell' ? -x.unitsE4 : x.unitsE4);
  }
  return {for (final e in u.entries) if (e.value > 0) e.key};
}

