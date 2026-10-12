import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/money.dart';

/// Add a transaction, or edit [existing].
class AddTransaction extends StatefulWidget {
  final ProfileDb db;
  final MarketDb market;
  final Transaction? existing;
  final int? instrumentId;
  const AddTransaction(
      {super.key, required this.db, required this.market, this.existing, this.instrumentId});
  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final _form = GlobalKey<FormState>();
  late final _e = widget.existing;
  late int? _inst = _e?.instrumentId ?? widget.instrumentId;
  late TxType _type = _e == null ? TxType.buy : TxType.values.byName(_e.type);
  late DateTime _date = _e == null ? istToday() : parseDay(_e.date);
  late final _units = TextEditingController(
      text: _e == null || _e.unitsE4 == 0 ? '' : formatScaled(_e.unitsE4, 4));
  late final _price = TextEditingController(text: _e == null ? '' : formatScaled(_e.priceE4, 4));
  late final _fees =
      TextEditingController(text: _e == null || _e.feesPaise == 0 ? '' : formatScaled(_e.feesPaise, 2));
  late final _note = TextEditingController(text: _e?.note ?? '');
  bool _saving = false;

  bool get _div => _type == TxType.dividend;

  @override
  void dispose() {
    for (final c in [_units, _price, _fees, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _num(String? v, int dp, {bool required = true, bool positive = true}) {
    if ((v ?? '').trim().isEmpty) return required ? 'Required' : null;
    final n = parseScaled(v!, dp);
    if (n == null) return 'Number with up to $dp decimals';
    if (positive && n <= 0) return 'Must be more than 0';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _inst == null) {
      if (_inst == null) _snack('Pick an instrument');
      return;
    }
    setState(() => _saving = true);
    try {
      final units = _div ? 0 : parseScaled(_units.text, 4)!;
      final price = parseScaled(_price.text, 4)!;
      final fees = _div || _fees.text.trim().isEmpty ? 0 : parseScaled(_fees.text, 2)!;
      // Reject anything that would make a sell exceed units held, for this
      // instrument and (if moved) the one it came from.
      final all = await widget.db.select(widget.db.transactions).get();
      final others = all.where((t) => t.id != _e?.id).toList();
      final newTx = Tx(_e?.id ?? 1 << 52, _date, _type, units, price, fees);
      for (final id in {_inst!, ?_e?.instrumentId}) {
        final txs = [
          for (final t in others)
            if (t.instrumentId == id) t.tx,
          if (id == _inst) newTx,
        ];
        if (fifo(txs).oversold.isNotEmpty) {
          _snack('A sell would exceed the units held on that date. Check dates and units.');
          return;
        }
      }
      final row = TransactionsCompanion.insert(
        instrumentId: _inst!,
        date: fmtDay(_date),
        type: _type.name,
        unitsE4: units,
        priceE4: price,
        feesPaise: Value(fees),
        note: Value(_note.text.trim()),
      );
      if (_e == null) {
        await widget.db.addTx(row);
      } else {
        await widget.db.editTx(_e.copyWith(
            instrumentId: _inst!,
            date: fmtDay(_date),
            type: _type.name,
            unitsE4: units,
            priceE4: price,
            feesPaise: fees,
            note: _note.text.trim()));
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _addInstrument() async {
    final id = await showDialog<int>(context: context, builder: (_) => _NewInstrument(widget.market));
    if (id != null) setState(() => _inst = id);
  }

  @override
  Widget build(BuildContext context) {
    final units = parseScaled(_units.text, 4), price = parseScaled(_price.text, 4);
    final total = _div
        ? (price == null ? null : valuePaise(unitScale, price))
        : (units == null || price == null ? null : valuePaise(units, price));
    return Scaffold(
      appBar: AppBar(title: Text(_e == null ? 'Add transaction' : 'Edit transaction')),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          StreamBuilder(
            stream: (widget.market.select(widget.market.instruments)
                  ..orderBy([(i) => OrderingTerm(expression: i.name)]))
                .watch(),
            builder: (context, s) => Row(children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _inst,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Fund / stock'),
                  items: [
                    for (final i in s.data ?? <Instrument>[])
                      DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _inst = v),
                ),
              ),
              IconButton(tooltip: 'New fund / stock', icon: const Icon(Icons.add_circle_outline), onPressed: _addInstrument),
            ]),
          ),
          const SizedBox(height: 16),
          SegmentedButton<TxType>(
            segments: const [
              ButtonSegment(value: TxType.buy, label: Text('Buy')),
              ButtonSegment(value: TxType.sip, label: Text('SIP')),
              ButtonSegment(value: TxType.sell, label: Text('Sell')),
              ButtonSegment(value: TxType.dividend, label: Text('Dividend')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(fmtDay(_date)),
            subtitle: const Text('Trade / allotment date'),
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.utc(1990),
                  lastDate: istToday());
              if (d != null) setState(() => _date = DateTime.utc(d.year, d.month, d.day));
            },
          ),
          if (!_div)
            TextFormField(
              controller: _units,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Units', helperText: 'Up to 4 decimals (from your statement)'),
              validator: (v) => _num(v, 4),
            ),
          TextFormField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
                labelText: _div ? 'Dividend amount (₹)' : 'Price / NAV per unit (₹)', prefixText: '₹ '),
            validator: (v) => _num(v, 4),
          ),
          if (!_div)
            TextFormField(
              controller: _fees,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Charges (₹, optional)', prefixText: '₹ ', helperText: 'Brokerage, stamp duty, STT'),
              validator: (v) => _num(v, 2, required: false, positive: false),
            ),
          TextFormField(
            controller: _note,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          if (total != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Total: ${rupees(total)}', style: Theme.of(context).textTheme.titleMedium),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
          const SizedBox(height: 8),
          const Text('Do not enter PAN, bank, demat or broker account details anywhere in this app.',
              style: TextStyle(fontSize: 12)),
        ]),
      ),
    );
  }
}

class _NewInstrument extends StatefulWidget {
  final MarketDb market;
  const _NewInstrument(this.market);
  @override
  State<_NewInstrument> createState() => _NewInstrumentState();
}

class _NewInstrumentState extends State<_NewInstrument> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  String _kind = 'mf';

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final m = widget.market;
    final code = _code.text.trim().toUpperCase();
    final existing = await (m.select(m.instruments)
          ..where((i) => _kind == 'mf' ? i.schemeCode.equals(code) : i.nseSymbol.equals(code)))
        .getSingleOrNull();
    final id = existing?.id ??
        await m.into(m.instruments).insert(InstrumentsCompanion.insert(
              kind: _kind,
              name: _name.text.trim(),
              schemeCode: Value(_kind == 'mf' ? code : null),
              nseSymbol: Value(_kind == 'stock' ? code : null),
              yahooTicker: Value(_kind == 'stock' ? '$code.NS' : null),
            ));
    if (mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('New fund / stock'),
        content: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'mf', label: Text('Mutual fund')),
                  ButtonSegment(value: 'stock', label: Text('NSE stock')),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              TextFormField(
                controller: _name,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _code,
                decoration: InputDecoration(
                  labelText: _kind == 'mf' ? 'AMFI scheme code' : 'NSE symbol',
                  helperText: _kind == 'mf' ? 'e.g. 120503 (from mfapi.in / AMFI)' : 'e.g. RELIANCE',
                ),
                validator: (v) {
                  final t = (v ?? '').trim().toUpperCase();
                  final ok = _kind == 'mf'
                      ? RegExp(r'^\d{3,7}$').hasMatch(t)
                      : RegExp(r'^[A-Z0-9&-]{1,20}$').hasMatch(t);
                  return ok ? null : (_kind == 'mf' ? 'Digits only' : 'Letters, digits, & or -');
                },
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _save, child: const Text('Add')),
        ],
      );
}
