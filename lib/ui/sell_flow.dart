import 'dart:convert';

import 'package:drift/drift.dart' show BooleanExpressionOperators;

import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../engine/sell_rules.dart';
import '../engine/tax.dart';
import 'add_transaction.dart';
import 'patience.dart';
import 'theme.dart';
import 'widgets.dart';

/// Manual sell plans are stored as signals with rule 0.
const manualSellRule = 0;
const coolOff = Duration(hours: 24);

/// "Thinking of selling?": thesis first, then the cost of impatience, then a
/// deliberate press-and-hold. Never places an order.
class SellFlow extends StatefulWidget {
  final Session session;
  final int instrumentId;
  final SellSuggestion? suggestion;
  const SellFlow({super.key, required this.session, required this.instrumentId, this.suggestion});
  @override
  State<SellFlow> createState() => _SellFlowState();
}

class _SellFlowState extends State<SellFlow> {
  int _step = 0;
  late final Holding h = widget.session.portfolio.value!.holdings.firstWhere((x) => x.instrumentId == widget.instrumentId);
  late final _units = TextEditingController(text: formatScaled(widget.suggestion?.unitsE4 ?? h.ledger.units4, 4));
  late final _price = TextEditingController(
      text: h.price == null ? '' : formatScaled(widget.suggestion?.priceE4 ?? h.price!.closeE4, 4));
  final _reason = TextEditingController();
  double _days = 0;

  Portfolio get p => widget.session.portfolio.value!;
  int get _rule => widget.suggestion?.rule ?? manualSellRule;

  @override
  void dispose() {
    _units.dispose();
    _price.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.suggestion == null ? 'Thinking of selling?' : ruleNames[_rule]!)),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (_step) {
          0 => _letter(context),
          1 => _cost(context),
          _ => _decide(context),
        },
      ),
    );
  }

  Widget _letter(BuildContext context) {
    final db = widget.session.db;
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder(
      key: const ValueKey(0),
      stream: (db.select(db.theses)..where((t) => t.instrumentId.equals(widget.instrumentId))).watchSingleOrNull(),
      builder: (context, snap) {
        final th = snap.data;
        return ListView(padding: const EdgeInsets.all(20), children: [
          Text('A letter from your past self', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(h.name, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: th == null
                  ? Text('You did not write down why you bought this. That is worth a minute before selling it.',
                      style: TextStyle(color: cs.onSurfaceVariant, height: 1.5))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Why I bought it', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text('"${th.whyBought}"', style: const TextStyle(fontSize: 17, height: 1.45, fontStyle: FontStyle.italic)),
                      if (th.breaksIf.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text('This would make me sell', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text('"${th.breaksIf}"', style: const TextStyle(fontSize: 16, height: 1.4, fontStyle: FontStyle.italic)),
                      ],
                    ]),
            ),
          ),
          if (widget.suggestion != null) ...[
            const SizedBox(height: 12),
            Notice(icon: Icons.rule, color: cs.primary, text: 'Rule $_rule: ${widget.suggestion!.reason}'),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _reason,
            maxLength: 200,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Why sell now? (required)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _reason.text.trim().length < 5 ? null : () => setState(() => _step = 1),
            child: const Text('Continue'),
          ),
        ]);
      },
    );
  }

  Widget _cost(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final u = parseScaled(_units.text, 4), pr = parseScaled(_price.text, 4);
    final ok = u != null && pr != null && u > 0 && pr > 0 && u <= h.ledger.units4;
    final lastLt = h.ledger.open.isEmpty
        ? p.today
        : h.ledger.open.map((l) => l.longTermDate).reduce((a, b) => a.isAfter(b) ? a : b);
    final span = (lastLt.difference(p.today).inDays + 30).clamp(30, 400);
    final day = p.today.add(Duration(days: _days.round()));
    SaleEstimate? at(DateTime d) =>
        ok ? estimateSale(lots: h.ledger.open, units4: u, price4: pr, date: d, realizedAll: p.realized) : null;
    final now = at(p.today), then = at(day);
    final ripeDays = {for (final l in h.ledger.open) l.longTermDate.difference(p.today).inDays}..removeWhere((d) => d <= 0);
    return ListView(key: const ValueKey(1), padding: const EdgeInsets.all(20), children: [
      Text('The cost of impatience', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _units,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Units', helperText: 'of ${formatScaled(h.ledger.units4, 4)}'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: 'Price', prefixText: '₹ ', helperText: h.price == null ? '' : 'Last ${prettyDay(h.price!.day)}'),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ]),
      const SizedBox(height: 20),
      if (now == null)
        Text('Enter units (up to what you hold) and a price.', style: TextStyle(color: cs.onSurfaceVariant))
      else ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_days == 0 ? 'Tax if sold today' : 'Tax if sold on ${prettyDay(day)}',
                  style: TextStyle(color: cs.onSurfaceVariant)),
              RollingMoney(then!.extraTaxPaise,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (_days > 0 && now.extraTaxPaise > then.extraTaxPaise)
                Text('Waiting saves ${rupees(now.extraTaxPaise - then.extraTaxPaise)} (same price assumed)',
                    style: TextStyle(color: cs.gain, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Slider(
                value: _days,
                max: span.toDouble(),
                divisions: span,
                label: prettyDay(day),
                onChanged: (v) => setState(() => _days = v),
              ),
              Row(children: [
                Text('Today', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                const Spacer(),
                Text('Drag to see tax fall as lots ripen', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
              if (ripeDays.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, children: [
                  for (final d in ripeDays.toList()..sort())
                    ActionChip(
                      avatar: const Icon(Icons.eco, size: 16),
                      label: Text(prettyDay(p.today.add(Duration(days: d)))),
                      onPressed: () => setState(() => _days = d.toDouble().clamp(0, span.toDouble())),
                    ),
                ]),
              ],
            ]),
          ),
        ),
      ],
      const SizedBox(height: 16),
      FilledButton(onPressed: ok ? () => setState(() => _step = 2) : null, child: const Text('Continue')),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep holding')),
      const Fine('Estimate from your FIFO lots and this FY\'s gains. Not tax advice.'),
    ]);
  }

  Widget _decide(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final u = parseScaled(_units.text, 4)!, pr = parseScaled(_price.text, 4)!;
    final w = compareWait(lots: h.ledger.open, units4: u, price4: pr, date: p.today, realizedAll: p.realized);
    final impatient = w.extraTaxPaise > 0 && _rule != 1 && _rule != 2;
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(impatient ? 'Short-term sale' : 'Ready to decide', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          impatient
              ? 'Selling now costs ${rupees(w.extraTaxPaise)} more than waiting until ${prettyDay(w.waitUntil!)}. '
                  'If you still decide to, sleep on it: this comes back to you in 24 hours.'
              : 'Place the order in your broker app yourself. Then record the sale here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 28),
        HoldToConfirm(
          label: impatient ? 'Hold to plan this sale' : 'Hold to decide',
          sublabel: impatient ? '+${rupees(w.extraTaxPaise, decimals: false)}\ntax' : null,
          color: impatient ? cs.warn : cs.primary,
          onConfirmed: () async {
            final db = widget.session.db;
            final inputs = jsonEncode({'unitsE4': u, 'priceE4': pr, 'extraTaxPaise': w.extraTaxPaise, 'reason': _reason.text.trim()});
            if (widget.suggestion != null) {
              await db.upsertSignal(widget.instrumentId, _rule, widget.suggestion!.inputsJson, sellRuleVersion);
            } else {
              await db.upsertSignal(widget.instrumentId, manualSellRule, inputs, sellRuleVersion);
            }
            final sig = await (db.select(db.signals)
                  ..where((s) => s.instrumentId.equals(widget.instrumentId) & s.rule.equals(_rule) & s.status.equals('open')))
                .getSingleOrNull();
            if (sig != null) await db.actOnSignal(sig.id, impatient ? 'planned' : 'done', note: _reason.text.trim());
            if (!context.mounted) return;
            if (impatient) {
              Navigator.pop(context);
              snack(context, 'Planned. It will be in Do next tomorrow.');
            } else {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddTransaction(
                          session: widget.session,
                          instrumentId: widget.instrumentId,
                          type: TxType.sell,
                          unitsE4: u,
                          priceE4: pr)));
            }
          },
        ),
        const SizedBox(height: 24),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep holding')),
      ]),
    );
  }
}

/// Planned manual sells whose 24-hour cool-off has passed (or not yet).
bool coolOffDone(Signal s, DateTime nowLocal) =>
    s.actedAt != null && nowLocal.difference(s.actedAt!) >= coolOff;
