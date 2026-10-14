import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/db.dart';
import '../engine/calendar.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/tax.dart';
import '../sources/mfapi.dart';
import '../sources/net.dart';
import 'theme.dart';
import 'widgets.dart';

/// Add a transaction, edit [existing], or record a SIP instalment ([sipPlan]).
class AddTransaction extends StatefulWidget {
  final Session session;
  final Transaction? existing;
  final int? instrumentId;
  final SipPlan? sipPlan;
  final DateTime? date;
  // Prefill from a sell decision or the type-to-add bar.
  final TxType? type;
  final int? unitsE4;
  final int? priceE4;
  final int? amountPaise;
  const AddTransaction(
      {super.key,
      required this.session,
      this.existing,
      this.instrumentId,
      this.sipPlan,
      this.date,
      this.type,
      this.unitsE4,
      this.priceE4,
      this.amountPaise});
  @override
  State<AddTransaction> createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  final _form = GlobalKey<FormState>();
  late final _e = widget.existing;
  late int? _inst = _e?.instrumentId ?? widget.sipPlan?.instrumentId ?? widget.instrumentId;
  late TxType _type = _e != null
      ? TxType.values.byName(_e.type)
      : (widget.type ?? (widget.sipPlan != null ? TxType.sip : TxType.buy));
  late DateTime _date = _e != null ? parseDay(_e.date) : _initialDate();
  late int? _goal = _e?.goalId;
  bool _byAmount = false;
  late final _units = TextEditingController(
      text: _e != null
          ? (_e.unitsE4 == 0 ? '' : formatScaled(_e.unitsE4, 4))
          : (widget.unitsE4 == null ? '' : formatScaled(widget.unitsE4!, 4)));
  late final _price = TextEditingController(
      text: _e != null ? formatScaled(_e.priceE4, 4) : (widget.priceE4 == null ? '' : formatScaled(widget.priceE4!, 4)));
  late final _amount = TextEditingController(
      text: widget.sipPlan != null
          ? formatScaled(widget.sipPlan!.amountPaise, 2)
          : (widget.amountPaise == null ? '' : formatScaled(widget.amountPaise!, 2)));
  late final _fees = TextEditingController(text: _e == null || _e.feesPaise == 0 ? '' : formatScaled(_e.feesPaise, 2));
  late final _note = TextEditingController(text: _e?.note ?? '');
  late final _stt = TextEditingController(text: _e == null || _e.sttPaise == 0 ? '' : formatScaled(_e.sttPaise, 2));
  bool _saving = false;

  Session get s => widget.session;
  bool get _trade => _type == TxType.buy || _type == TxType.sip || _type == TxType.sell;
  bool get _ratio => _type == TxType.split || _type == TxType.bonus;

  DateTime _initialDate() {
    final d = widget.date ?? istToday();
    // Trades settle only on business days; land a preset on the next one.
    return nse.knows(d) || nse.isWeekend(d) ? nse.onOrAfter(d) : d;
  }

  @override
  void initState() {
    super.initState();
    _byAmount = widget.sipPlan != null || (widget.amountPaise != null && widget.type != TxType.dividend);
    // Dividend amount lives in the price field.
    if (widget.type == TxType.dividend && widget.amountPaise != null) {
      _price.text = formatScaled(widget.amountPaise!, 2);
    }
  }

  @override
  void dispose() {
    for (final c in [_units, _price, _amount, _fees, _note, _stt]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _num(String? v, int dp, {bool required = true, bool positive = true}) {
    if ((v ?? '').trim().isEmpty) return required ? 'Required' : null;
    final n = parseScaled(v!, dp);
    if (n == null) return 'Number, up to $dp decimals';
    if (positive && n <= 0) return 'Must be more than 0';
    if (n < 0) return 'Cannot be negative';
    return null;
  }

  bool get _isMf => _inst != null && s.portfolio.value!.instruments[_inst]?.kind == 'mf';

  /// MF purchases: stamp duty is automatic, no other charges field.
  bool get _mfBuy => _isMf && (_type == TxType.buy || _type == TxType.sip);

  /// Units entered directly, or derived from amount / NAV (MF: after stamp duty).
  int? get _unitsE4 {
    if (_type == TxType.dividend) return 0;
    if (_byAmount && !_ratio && _type != TxType.sell) {
      final a = parseScaled(_amount.text, 2), p = parseScaled(_price.text, 4);
      if (a == null || p == null || p <= 0) return null;
      return unitsFor(_isMf ? a - mfStampOnAmount(a) : a, p);
    }
    return parseScaled(_units.text, 4);
  }

  /// Charges added to cost (stocks: brokerage etc.; MF buys: stamp duty).
  int _feesFor(int units, int price) {
    if (!_trade) return 0;
    if (_mfBuy) return mfStampOnValue(valuePaise(units, price));
    return _fees.text.trim().isEmpty ? 0 : parseScaled(_fees.text, 2)!;
  }

  List<Tx> _otherTxs(int instrumentId) => [
        for (final t in s.portfolio.value!.txs)
          if (t.instrumentId == instrumentId && t.id != _e?.id) t.tx,
      ];

  Future<void> _save() async {
    if (_inst == null) return snack(context, 'Pick a fund or stock first');
    if (!_form.currentState!.validate()) return;
    final units = _unitsE4;
    if (units == null) return snack(context, 'Check units / amount');
    setState(() => _saving = true);
    try {
      final price = _ratio ? 0 : parseScaled(_price.text, 4)!;
      final fees = _feesFor(units, price);
      final stt = !_isMf && _trade && _stt.text.trim().isNotEmpty ? parseScaled(_stt.text, 2)! : 0;
      final newTx = Tx(_e?.id ?? 1 << 52, _date, _type, units, price, fees);
      // Reject anything that makes a sell exceed units held, here or in the
      // instrument the entry was moved away from.
      for (final id in {_inst!, ?_e?.instrumentId}) {
        final txs = [..._otherTxs(id), if (id == _inst) newTx];
        if (fifo(txs).oversold.isNotEmpty) {
          return snack(context, 'A sell would exceed the units held on that date. Check dates and units.');
        }
      }
      final goal = _type == TxType.buy || _type == TxType.sip ? _goal : null;
      if (_e == null) {
        await s.db.addTx(TransactionsCompanion.insert(
          instrumentId: _inst!,
          date: fmtDay(_date),
          type: _type.name,
          unitsE4: units,
          priceE4: price,
          feesPaise: Value(fees),
          sttPaise: Value(stt),
          goalId: Value(goal),
          note: Value(_note.text.trim()),
        ));
      } else {
        await s.db.editTx(_e.copyWith(
            instrumentId: _inst!,
            date: fmtDay(_date),
            type: _type.name,
            unitsE4: units,
            priceE4: price,
            feesPaise: fees,
            sttPaise: stt,
            goalId: Value(goal),
            note: _note.text.trim()));
      }
      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickInstrument() async {
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _InstrumentPicker(market: s.market),
    );
    if (id != null) setState(() => _inst = id);
  }

  Future<void> _pickDate() async {
    final trade = _trade;
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.utc(1990),
      lastDate: istToday(),
      helpText: trade ? 'Trade / allotment date (market days only)' : 'Date',
      selectableDayPredicate: trade
          ? (d) {
              final u = DateTime.utc(d.year, d.month, d.day);
              return u == _date || nse.isTradingDay(u);
            }
          : null,
    );
    if (d != null) setState(() => _date = DateTime.utc(d.year, d.month, d.day));
  }

  // Rebuild when the shared portfolio recomputes (e.g. a newly added fund).
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder(valueListenable: s.portfolio, builder: (context, _, _) => _build(context));

  Widget _build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = s.portfolio.value!;
    final inst = _inst == null ? null : p.instruments[_inst];
    final units = _unitsE4;
    final price = parseScaled(_price.text, 4);
    final total = switch (_type) {
      TxType.dividend => price == null ? null : valuePaise(unitScale, price),
      TxType.split || TxType.bonus => null,
      _ => units == null || price == null ? null : valuePaise(units, price),
    };
    final closed = nse.closedReason(_date);
    final today = istToday(), yesterday = nse.onOrBefore(today.subtract(const Duration(days: 1)));
    final unitHelp = switch (_type) {
      TxType.split => 'New units for each 1 old unit (1 → 5 split: enter 5)',
      TxType.bonus => 'Bonus units per 1 held (1:1 bonus: enter 1)',
      _ => 'Up to 4 decimals, from your statement',
    };

    return Scaffold(
      appBar: AppBar(title: Text(_e == null ? (widget.sipPlan != null ? 'Record SIP' : 'Add transaction') : 'Edit transaction')),
      body: Form(
        key: _form,
        onChanged: () => setState(() {}),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
          // Instrument
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(inst == null ? Icons.search : (inst.kind == 'mf' ? Icons.pie_chart_outline : Icons.show_chart),
                    color: cs.onPrimaryContainer),
              ),
              title: Text(inst?.name ?? 'Choose fund or stock', maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(inst == null ? 'Search or add new' : (inst.kind == 'mf' ? 'Scheme ${inst.schemeCode}' : 'NSE ${inst.nseSymbol}')),
              trailing: const Icon(Icons.expand_more),
              onTap: _pickInstrument,
            ),
          ),
          const SizedBox(height: 16),
          // Type
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in TxType.values)
              ChoiceChip(
                avatar: Icon(txIcon(t.name), size: 18),
                label: Text(txLabel(t.name)),
                selected: _type == t,
                onSelected: (_) => setState(() => _type = t),
              ),
          ]),
          const SizedBox(height: 16),
          // Date
          Row(children: [
            Expanded(
              child: Wrap(spacing: 8, children: [
                ChoiceChip(label: const Text('Today'), selected: _date == today, onSelected: (_) => setState(() => _date = today)),
                if (yesterday != today)
                  ChoiceChip(
                    label: Text(yesterday == today.subtract(const Duration(days: 1)) ? 'Yesterday' : 'Last market day'),
                    selected: _date == yesterday,
                    onSelected: (_) => setState(() => _date = yesterday),
                  ),
              ]),
            ),
            TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month), label: Text(prettyDay(_date))),
          ]),
          if (closed != null && _trade)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Notice(
                icon: Icons.event_busy,
                color: cs.warn,
                text: 'Market closed on ${prettyDay(_date)} ($closed). Use the trade or allotment date from your statement.',
              ),
            ),
          const SizedBox(height: 12),
          if ((_type == TxType.buy || _type == TxType.sip))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Enter units')),
                  ButtonSegment(value: true, label: Text('Enter amount')),
                ],
                selected: {_byAmount},
                onSelectionChanged: (v) => setState(() => _byAmount = v.first),
              ),
            ),
          if (_byAmount && (_type == TxType.buy || _type == TxType.sip))
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount invested', prefixText: '₹ '),
              validator: (v) => _num(v, 2),
            )
          else if (_type != TxType.dividend)
            TextFormField(
              controller: _units,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: _ratio ? 'Ratio' : 'Units', helperText: unitHelp),
              validator: (v) => _num(v, 4),
            ),
          if (!_ratio) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: _type == TxType.dividend ? 'Dividend received' : 'Price / NAV per unit', prefixText: '₹ '),
              validator: (v) => _num(v, 4),
            ),
          ],
          if (_trade && !_mfBuy) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _fees,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: _isMf ? 'Exit load (optional)' : 'Charges (optional)',
                  prefixText: '₹ ',
                  helperText: _isMf
                      ? 'Reduces sale proceeds'
                      : 'Brokerage, exchange fees, GST, stamp duty. Not STT.'),
              validator: (v) => _num(v, 2, required: false, positive: false),
            ),
          ],
          if (_trade && !_isMf) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _stt,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'STT (optional)',
                  prefixText: '₹ ',
                  helperText: 'Kept for records only: STT is not deductible from capital gains'),
              validator: (v) => _num(v, 2, required: false, positive: false),
            ),
          ],
          if (_mfBuy && units != null && price != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                  'Stamp duty 0.005%: ${rupees(mfStampOnValue(valuePaise(units, price)))} (added to cost automatically)',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ),
          if ((_type == TxType.buy || _type == TxType.sip) && p.goals.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _goal,
              decoration: const InputDecoration(labelText: 'Goal (optional)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('No goal')),
                for (final g in p.goals) DropdownMenuItem(value: g.goal.id, child: Text(g.goal.name)),
              ],
              onChanged: (v) => setState(() => _goal = v),
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(controller: _note, maxLength: 200, decoration: const InputDecoration(labelText: 'Note (optional)')),
          if (total != null || (_byAmount && units != null))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (total != null)
                    Row(children: [
                      const Expanded(child: Text('Total')),
                      Money(total, decimals: true, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ]),
                  if (_byAmount && units != null && _type != TxType.sell)
                    Text('≈ ${formatScaled(units, 4)} units (rounded to 4 decimals; edit with "Enter units" if your statement differs)',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ]),
              ),
            ),
          if (_type == TxType.sell && _inst != null && units != null && price != null && units > 0 && price > 0)
            _sellPreview(context, units, price),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: Text(_e == null ? 'Save' : 'Save changes'),
          ),
          const Fine('Never enter PAN, bank, demat or broker account details anywhere in this app.'),
        ]),
      ),
    );
  }

  Widget _sellPreview(BuildContext context, int units, int price) {
    final cs = Theme.of(context).colorScheme;
    final p = s.portfolio.value!;
    final before = [for (final t in _otherTxs(_inst!)) if (compareTx(t, Tx(1 << 52, _date, TxType.sell, 0, 0)) < 0) t];
    final l = fifo(before);
    if (units > l.units4) return const SizedBox.shrink();
    final otherRealized = [
      for (final e in p.ledgers.entries)
        if (e.key != _inst) ...e.value.realized,
      ...l.realized,
    ];
    final w = compareWait(lots: l.open, units4: units, price4: price, date: _date, realizedAll: otherRealized,
        feesPaise: parseScaled(_fees.text, 2) ?? 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Gain')),
            Money(w.now.gainPaise, decimals: true, signed: true, colored: true),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Expanded(child: Text('Est. tax on this sale')),
            Money(w.now.extraTaxPaise, decimals: true, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          if (w.extraTaxPaise > 0) ...[
            const SizedBox(height: 10),
            Notice(
              icon: Icons.warning_amber,
              color: cs.warn,
              text: 'Short-term sale: ${rupees(w.extraTaxPaise)} more tax than selling on '
                  '${prettyDay(w.waitUntil!)} at the same price.',
            ),
          ],
          const Fine('Estimate using FIFO lots and this FY\'s realised gains. Not tax advice.'),
        ]),
      ),
    );
  }
}

class _InstrumentPicker extends StatefulWidget {
  final MarketDb market;
  const _InstrumentPicker({required this.market});
  @override
  State<_InstrumentPicker> createState() => _InstrumentPickerState();
}

class _InstrumentPickerState extends State<_InstrumentPicker> {
  String _q = '';
  List<Listing> _stocks = const [];
  List<(String, String)> _funds = const [];
  bool _searchingFunds = false;
  Timer? _debounce;
  final _net = Net();

  MarketDb get m => widget.market;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQuery(String v) {
    setState(() => _q = v.trim().toLowerCase());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  /// Every NSE-listed stock (local list) and every mutual fund (mfapi search).
  Future<void> _search() async {
    final q = _q;
    if (q.length < 2) {
      setState(() => (_stocks = const [], _funds = const []));
      return;
    }
    final stocks = await (m.select(m.universe)
          ..where((u) => u.symbol.lower().like('$q%') | u.name.lower().like('%$q%'))
          ..orderBy([(u) => OrderingTerm.desc(u.nifty500), (u) => OrderingTerm.asc(u.symbol)])
          ..limit(15))
        .get();
    if (!mounted || q != _q) return;
    setState(() {
      _stocks = stocks;
      _searchingFunds = q.length >= 3;
    });
    if (q.length < 3) return;
    try {
      final f = await mfSearch(_net, q);
      if (mounted && q == _q) setState(() => _funds = f.take(25).toList());
    } catch (_) {
      if (mounted && q == _q) setState(() => _funds = const []);
    } finally {
      if (mounted && q == _q) setState(() => _searchingFunds = false);
    }
  }

  Future<int> _ensureStock(Listing l) async {
    final hit = await (m.select(m.instruments)..where((i) => i.nseSymbol.equals(l.symbol))).getSingleOrNull();
    return hit?.id ??
        await m.into(m.instruments).insert(InstrumentsCompanion.insert(
            kind: 'stock', name: l.name, nseSymbol: Value(l.symbol), yahooTicker: Value('${l.symbol}.NS')));
  }

  Future<int> _ensureFund(String code, String name) async {
    final hit = await (m.select(m.instruments)..where((i) => i.schemeCode.equals(code))).getSingleOrNull();
    return hit?.id ??
        await m.into(m.instruments).insert(InstrumentsCompanion.insert(kind: 'mf', name: name, schemeCode: Value(code)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget header(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(t, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        );
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
                hintText: 'Search any NSE stock or mutual fund', prefixIcon: Icon(Icons.search)),
            onChanged: _onQuery,
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: m.select(m.instruments).watch(),
            builder: (context, snap) {
              final mine = [
                for (final i in snap.data ?? const <Instrument>[])
                  if (i.kind != 'index' &&
                      (_q.isEmpty || '${i.name} ${i.nseSymbol ?? ''} ${i.schemeCode ?? ''} ${i.aliases}'.toLowerCase().contains(_q)))
                    i,
              ]..sort((a, b) => a.name.compareTo(b.name));
              final mineSymbols = {for (final i in mine) i.nseSymbol};
              final mineCodes = {for (final i in mine) i.schemeCode};
              return ListView(children: [
                if (mine.isNotEmpty) header('YOURS'),
                for (final it in mine)
                  ListTile(
                    leading: Icon(it.kind == 'mf' ? Icons.pie_chart_outline : Icons.show_chart),
                    title: Text(it.name),
                    subtitle: Text(it.kind == 'mf' ? 'Scheme ${it.schemeCode}' : 'NSE ${it.nseSymbol}'),
                    onTap: () => Navigator.pop(context, it.id),
                  ),
                if (_stocks.any((l) => !mineSymbols.contains(l.symbol))) header('NSE STOCKS'),
                for (final l in _stocks)
                  if (!mineSymbols.contains(l.symbol))
                    ListTile(
                      leading: const Icon(Icons.show_chart),
                      title: Text(l.name),
                      subtitle: Text('${l.symbol}${l.nifty500 ? ' · NIFTY 500' : ''}${l.industry.isEmpty ? '' : ' · ${l.industry}'}'),
                      onTap: () async {
                        final id = await _ensureStock(l);
                        if (context.mounted) Navigator.pop(context, id);
                      },
                    ),
                if (_searchingFunds) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
                if (_funds.any((f) => !mineCodes.contains(f.$1))) header('MUTUAL FUNDS'),
                for (final (code, name) in _funds)
                  if (!mineCodes.contains(code))
                    ListTile(
                      leading: const Icon(Icons.pie_chart_outline),
                      title: Text(name),
                      subtitle: Text('Scheme $code${isRegularPlan(name) ? ' · Regular plan (higher cost)' : ''}'),
                      onTap: () async {
                        final id = await _ensureFund(code, name);
                        if (context.mounted) Navigator.pop(context, id);
                      },
                    ),
                if (_q.length >= 2 && _stocks.isEmpty && _funds.isEmpty && !_searchingFunds)
                  const Padding(padding: EdgeInsets.all(16), child: Text('No match. You can add it by code below.')),
                if (_q.isEmpty && mine.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Type a company, NSE symbol or fund name. All NSE stocks and all mutual funds are searchable.'),
                  ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Add by symbol or scheme code'),
                  onTap: () async {
                    final id = await showDialog<int>(context: context, builder: (_) => _NewInstrument(m, initialName: _q));
                    if (id != null && context.mounted) Navigator.pop(context, id);
                  },
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}

class _NewInstrument extends StatefulWidget {
  final MarketDb market;
  final String initialName;
  const _NewInstrument(this.market, {this.initialName = ''});
  @override
  State<_NewInstrument> createState() => _NewInstrumentState();
}

class _NewInstrumentState extends State<_NewInstrument> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
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
                onSelectionChanged: (v) => setState(() => _kind = v.first),
              ),
              const SizedBox(height: 12),
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
                  helperText: _kind == 'mf' ? 'e.g. 120716 (on mfapi.in / AMFI)' : 'e.g. RELIANCE',
                ),
                validator: (v) {
                  final t = (v ?? '').trim().toUpperCase();
                  final ok = _kind == 'mf' ? RegExp(r'^\d{3,7}$').hasMatch(t) : RegExp(r'^[A-Z0-9&-]{1,20}$').hasMatch(t);
                  return ok ? null : (_kind == 'mf' ? 'Digits only' : 'Letters, digits, & or -');
                },
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _save, style: FilledButton.styleFrom(minimumSize: const Size(64, 40)), child: const Text('Add')),
        ],
      );
}
