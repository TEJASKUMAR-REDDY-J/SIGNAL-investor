
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/time_machine.dart';
import '../engine/valuation.dart';
import 'advisor.dart';
import 'ask.dart';
import 'sandbox.dart';
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
          card(Icons.emoji_events_outlined, 'Advisor', 'Best-ranked NIFTY 500 stocks and mutual funds by category, with reasons.',
              () => AdvisorScreen(session: session)),
          card(Icons.auto_awesome, 'Ask SIGNAL', 'Your AI guide: the app, your portfolio, any company, tax. Explains; you decide.',
              () => AskScreen(session: session)),
          const Fine('Everything here is for learning. Ideas from the scan are starting points to research, not picks. '
              'Most active fund managers trail the index over 10 years.'),
        ]),
      ),
    ]);
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
                    text: 'Along the way this fell as much as ${(sip.worstDropBps / 100).toStringAsFixed(0)}% from a peak. '
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
