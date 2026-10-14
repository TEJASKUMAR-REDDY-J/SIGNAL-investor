import 'package:flutter/material.dart';

import '../engine/calendar.dart';
import '../engine/money.dart';
import '../engine/tax.dart';
import 'theme.dart';
import 'widgets.dart';

const disclaimer =
    'Personal decision aid only. Not investment, tax or legal advice; the authors are not SEBI-registered '
    'advisers. Tax figures are estimates for listed equity and equity mutual funds only (no surcharge, debt '
    'funds or grandfathering). Market data comes from unofficial public sources and can be wrong or late. '
    'Verify everything with your broker, RTA statement or a chartered accountant before acting. This app never '
    'places orders.';

class SettingsScreen extends StatefulWidget {
  final Session session;
  const SettingsScreen({super.key, required this.session});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _target = 25;

  @override
  void initState() {
    super.initState();
    widget.session.db.setting('satellite_target_pct').then((v) {
      if (v != null && mounted) setState(() => _target = int.tryParse(v) ?? 25);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = widget.session.portfolio.value;
    final satPct = p == null || p.investedPaise == 0 ? 0 : (p.satellitePaise * 100 / p.investedPaise).round();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 32),
        children: [
          const SectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: ValueListenableBuilder(
                valueListenable: themeMode,
                builder: (context, mode, _) => FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                    ],
                    selected: {mode},
                    onSelectionChanged: (v) => setThemeMode(v.first),
                  ),
                ),
              ),
            ),
          ),
          const SectionHeader('Portfolio'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Satellite target', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Text(
                        '$_target%',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: tabular),
                      ),
                    ],
                  ),
                  Slider(
                    value: _target.toDouble(),
                    max: 50,
                    divisions: 10,
                    label: '$_target%',
                    onChanged: (v) => setState(() => _target = v.round()),
                    onChangeEnd: (v) => widget.session.db.setSetting('satellite_target_pct', '${v.round()}'),
                  ),
                  Text(
                    'Now $satPct% satellite. The plan suggests 70–80% in index SIPs (core) and 20–30% in picks.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('Security'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Lock now'),
                  subtitle: const Text('Also locks after 60 s in the background'),
                  onTap: widget.session.lock,
                ),
                ListTile(
                  leading: const Icon(Icons.switch_account_outlined),
                  title: const Text('Switch profile'),
                  onTap: widget.session.lock,
                ),
                const ListTile(
                  leading: Icon(Icons.enhanced_encryption_outlined),
                  title: Text('Encrypted on this phone'),
                  subtitle: Text(
                    'Each profile has its own key in the Android keystore. Screenshots are blocked. '
                    'No cloud backup.',
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('Tax rules used'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'FY 2026-27, listed equity and equity MFs\n'
                '• Held more than 12 months: long-term\n'
                '• STCG ${stcgBps / 100}% · LTCG ${ltcgBps / 100}% above ${rupees(ltcgExemptionPaise, decimals: false)} per person per FY\n'
                '• ${cessBps / 100}% cess on tax\n'
                '• Short-term losses offset STCG and LTCG; long-term losses only LTCG\n'
                'Last verified 12 Oct 2026.',
                style: const TextStyle(height: 1.5),
              ),
            ),
          ),
          const SectionHeader('Market calendar'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'NSE trading holidays for ${nse.years.join(', ')} are built in (last checked 13 Oct 2026). '
                'Weekends and holidays are closed days for SIP due dates and the date picker.',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
          ),
          const SectionHeader('About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(disclaimer, style: TextStyle(color: cs.onSurfaceVariant, height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }
}
