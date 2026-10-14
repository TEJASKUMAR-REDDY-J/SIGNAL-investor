import 'dart:convert';

import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../engine/scan_config.dart';
import '../engine/scoring.dart';
import '../engine/time_machine.dart';
import '../engine/valuation.dart';
import '../pipeline/scan.dart';
import '../sources/net.dart';
import 'ask.dart';
import 'sandbox.dart';
import 'theme.dart';
import 'widgets.dart';

const _netChannel = MethodChannel('signal/net');

Future<bool> onWifi() async {
  try {
    return await _netChannel.invokeMethod<bool>('isWifi') ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

/// Buy candidates are logged as signals with this rule number.
const buyCandidateRule = 10;

class LabTab extends StatelessWidget {
  final Session session;
  const LabTab({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    Widget card(IconData icon, String title, String body, Widget Function() page) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(body),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page())),
            ),
          ),
        );
    return CustomScrollView(slivers: [
      const SliverAppBar(floating: true, title: Text('Lab')),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 40),
        sliver: SliverList.list(children: [
          card(Icons.science_outlined, 'Sandbox', 'Paper money at real prices. Practise patience without real risk.',
              () => SandboxScreen(session: session)),
          card(Icons.history_toggle_off, 'Time machine', 'What a SIP or lump sum would have done, on real history.',
              () => TimeMachineScreen(session: session)),
          card(Icons.radar, 'Weekly scan', 'NIFTY 500 (includes mid and small caps), ranked by quality, value and momentum.',
              () => ScanScreen(session: session)),
          card(Icons.auto_awesome, 'Ask', 'An AI explainer for rules, tax and public news. Never decides for you.',
              () => AskScreen(session: session)),
          const Fine('Everything here is for learning. Ideas from the scan are starting points to research, not picks. '
              'Most active fund managers trail the index over 10 years.'),
        ]),
      ),
    ]);
  }
}

// ---------------- Weekly scan ----------------

class ScanScreen extends StatefulWidget {
  final Session session;
  const ScanScreen({super.key, required this.session});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CancelToken? _cancel;
  int _done = 0, _total = 0;
  String _what = '';
  List<Candidate>? _result;
  String? _error;
  final _net = Net();

  Future<void> _start() async {
    if (!await onWifi()) {
      if (mounted) snack(context, 'The scan runs on Wi-Fi only (about 600 small requests).');
      return;
    }
    final c = CancelToken();
    setState(() {
      _cancel = c;
      _error = null;
      _result = null;
    });
    final held = <String>{
      for (final h in widget.session.portfolio.value?.holdings ?? const <Holding>[]) h.instrument?.nseSymbol ?? '',
    };
    try {
      final r = await runScan(widget.session.market, _net,
          cancel: c,
          exclude: held,
          onProgress: (d, t, w) {
            if (mounted) setState(() => (_done = d, _total = t, _what = w));
          });
      await _log(r);
      if (mounted) setState(() => _result = r);
    } on FetchError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Scan stopped: $e');
    } finally {
      if (mounted) setState(() => _cancel = null);
    }
  }

  Future<int> _instrumentFor(Candidate c) async {
    final m = widget.session.market;
    final hit = await (m.select(m.instruments)..where((i) => i.nseSymbol.equals(c.input.symbol))).getSingleOrNull();
    return hit?.id ??
        await m.into(m.instruments).insert(InstrumentsCompanion.insert(
            kind: 'stock', name: c.input.name, nseSymbol: Value(c.input.symbol), yahooTicker: Value('${c.input.symbol}.NS')));
  }

  /// Every candidate is a signal with inputs and rule version.
  Future<void> _log(List<Candidate> r) async {
    for (final c in r) {
      await widget.session.db.upsertSignal(await _instrumentFor(c), buyCandidateRule, jsonEncode(c.inputs), scanRuleVersion);
    }
  }

  Future<void> _act(Candidate c, String action) async {
    final db = widget.session.db;
    final id = await _instrumentFor(c);
    final sig = await (db.select(db.signals)
          ..where((s) => s.instrumentId.equals(id) & s.rule.equals(buyCandidateRule) & s.status.equals('open')))
        .getSingleOrNull();
    if (sig != null) await db.actOnSignal(sig.id, action);
    if (!mounted) return;
    if (action == 'sandbox') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SandboxScreen(session: widget.session, buyInstrumentId: id)));
    } else {
      setState(() => _result = [..._result!]..remove(c));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final running = _cancel != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly scan')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('How it works', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Filters NIFTY 500 on ROE ≥ ${(minRoe * 100).round()}%, debt ≤ ${(maxDebtToEquityPct / 100).toStringAsFixed(1)}x '
                'equity, positive cash flow and size. Ranks by quality, price against its own 3-year average, and 12-1 month '
                'momentum. Shows the top $topN you do not already own. Wi-Fi only; 1 second between requests.',
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (running) ...[
                LinearProgressIndicator(value: _total == 0 ? null : _done / _total),
                const SizedBox(height: 6),
                Text('$_done / $_total · $_what', style: const TextStyle(fontFeatures: tabular)),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () => _cancel!.cancelled = true, child: const Text('Cancel')),
              ] else
                FilledButton.icon(onPressed: _start, icon: const Icon(Icons.radar), label: const Text('Run scan')),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Notice(icon: Icons.error_outline, color: cs.loss, text: _error!)),
            ]),
          ),
        ),
        if (_result != null && _result!.isEmpty)
          const EmptyState(icon: Icons.filter_alt_off, title: 'Nothing passed', message: 'No stock cleared every filter this time.'),
        for (final (i, c) in (_result ?? const <Candidate>[]).indexed)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(radius: 14, child: Text('${i + 1}')),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.input.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${c.input.symbol} · ${c.input.industry}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      ]),
                    ),
                    Text('${(c.score * 100).round()}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.primary)),
                  ]),
                  const SizedBox(height: 10),
                  for (final r in c.reasons) Text('• $r'),
                  const SizedBox(height: 8),
                  Text('What would break the case', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  for (final b in c.breaks) Text('• $b', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text('Data as of ${prettyDay(c.input.dataAsOf)}', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(children: [
                    FilledButton.tonalIcon(onPressed: () => _act(c, 'sandbox'), icon: const Icon(Icons.science_outlined), label: const Text('Try in sandbox')),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => _act(c, 'dismissed'), child: const Text('Dismiss')),
                  ]),
                ]),
              ),
            ),
          ),
        const Fine('Fundamentals and prices from Yahoo (unofficial). Promoter pledge data is not available from a free source, '
            'so check it yourself. A ranking is not a recommendation.'),
      ]),
    );
  }
}

// ---------------- Time machine ----------------

class TimeMachineScreen extends StatefulWidget {
  final Session session;
  const TimeMachineScreen({super.key, required this.session});
  @override
  State<TimeMachineScreen> createState() => _TimeMachineScreenState();
}

class _TimeMachineScreenState extends State<TimeMachineScreen> {
  int? _id;
  double _years = 5;
  final _amount = TextEditingController(text: '5000');

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.session.portfolio.value!;
    final options = [
      for (final i in p.instruments.values)
        if (p.book.series(i.id).length > 250) i,
    ]..sort((a, b) => a.name.compareTo(b.name));
    _id ??= p.benchId != null && options.any((i) => i.id == p.benchId) ? p.benchId : options.firstOrNull?.id;
    final nav = _id == null ? const <Bar>[] : p.book.series(_id!);
    final maxYears = nav.isEmpty ? 1.0 : (nav.last.day.difference(nav.first.day).inDays / 365).floorToDouble().clamp(1.0, 20.0);
    if (_years > maxYears) _years = maxYears;
    final monthly = (parseScaled(_amount.text, 2) ?? 0);
    final start = nav.isEmpty ? DateTime.utc(2000) : addMonths(DateTime.utc(nav.last.day.year, nav.last.day.month), -(_years * 12).round());
    final sip = nav.isEmpty || monthly <= 0 ? null : simulateSip(nav, start, monthly);
    final lump = sip == null ? null : simulateLump(nav, start, sip.investedPaise);
    return Scaffold(
      appBar: AppBar(title: const Text('Time machine')),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        if (options.isEmpty)
          const EmptyState(
              icon: Icons.history_toggle_off,
              title: 'No history yet',
              message: 'Pull to refresh on Home once. The Nifty 50 index fund history is fetched for the ghost line and appears here.')
        else ...[
          DropdownButtonFormField<int>(
            initialValue: _id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Fund or stock'),
            items: [for (final i in options) DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => setState(() => _id = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monthly SIP', prefixText: '₹ '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text('Starting ${_years.round()} year${_years.round() == 1 ? '' : 's'} ago (${monthYear(start)})'),
          Slider(value: _years, min: 1, max: maxYears, divisions: (maxYears - 1).round().clamp(1, 20), onChanged: (v) => setState(() => _years = v)),
          if (sip != null && lump != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Monthly SIP', style: TextStyle(color: cs.onSurfaceVariant)),
                  Money(sip.valuePaise, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text('from ${rupees(sip.investedPaise, decimals: false)} put in'
                      '${sip.xirr == null ? '' : ' · ${(sip.xirr! * 100).toStringAsFixed(1)}% a year'}'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: LineChart(LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                            spots: [for (final (i, x) in sip.path.indexed) FlSpot(i.toDouble(), x.$2 / 100)],
                            color: cs.primary,
                            barWidth: 2.4,
                            dotData: const FlDotData(show: false)),
                        LineChartBarData(
                            spots: [for (final (i, x) in sip.path.indexed) FlSpot(i.toDouble(), x.$3 / 100)],
                            color: cs.outline,
                            barWidth: 1.2,
                            isStepLineChart: true,
                            dashArray: [4, 4],
                            dotData: const FlDotData(show: false)),
                      ],
                    )),
                  ),
                  const SizedBox(height: 10),
                  Notice(
                    icon: Icons.self_improvement,
                    color: cs.primary,
                    text: 'Along the way the SIP fell as much as ${(sip.worstDropBps / 100).toStringAsFixed(0)}% from a peak. '
                        'Staying in through that is the hard part, and where most of the return came from.',
                  ),
                  const SizedBox(height: 10),
                  Text('Same total as one lump sum on day one: ${rupees(lump.valuePaise, decimals: false)}'
                      '${lump.xirr == null ? '' : ' (${(lump.xirr! * 100).toStringAsFixed(1)}% a year)'}',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                ]),
              ),
            ),
          ],
          const Fine('Uses real past prices stored on this phone. The past does not repeat on schedule. '
              'Stamp duty, expense changes and taxes are not included.'),
        ],
      ]),
    );
  }
}
