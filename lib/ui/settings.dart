import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../engine/calendar.dart';
import '../engine/money.dart';
import '../engine/tax.dart';
import '../db/open_db.dart';
import '../sources/groq.dart';
import 'ask.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wrapped.dart';

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
          const SectionHeader('AI (Groq)'),
          _GroqCard(session: widget.session),
          const SectionHeader('Look back'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Financial-year Wrapped'),
              subtitle: const Text('Once a year: discipline, tax saved by waiting, you vs the index'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final p = widget.session.portfolio.value;
                if (p == null) return;
                Navigator.push(context, MaterialPageRoute(builder: (_) => WrappedScreen(p: p, fy: p.fy - 1)));
              },
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


class _GroqCard extends StatefulWidget {
  final Session session;
  const _GroqCard({required this.session});
  @override
  State<_GroqCard> createState() => _GroqCardState();
}

class _GroqCardState extends State<_GroqCard> {
  final _key = TextEditingController();
  List<String>? _models;
  String? _status, _tag, _ask;
  bool _hasOwn = false, _busy = false;

  String get _store => 'groq_${widget.session.profile.id}';

  @override
  void initState() {
    super.initState();
    () async {
      final own = await storage.read(key: _store);
      final tag = await widget.session.db.setting('groq_tag_model');
      final askM = await widget.session.db.setting('groq_ask_model');
      if (!mounted) return;
      setState(() {
        _hasOwn = cleanKey(own) != null;
        _tag = tag ?? defaultTagModel;
        _ask = askM ?? defaultAskModel;
        _status = _hasOwn ? 'Using this profile\'s key' : (envKey() != null ? 'Using the key built in from .env' : 'No key yet');
      });
    }();
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _check([String? fresh]) async {
    final k = cleanKey(fresh) ?? await groqKeyFor(widget.session.profile.id);
    if (k == null) return setState(() => _status = 'No key yet');
    setState(() => _busy = true);
    try {
      final m = await listModels(http.Client(), k);
      if (fresh != null) {
        await storage.write(key: _store, value: k);
        _key.clear();
        _hasOwn = true;
      }
      setState(() {
        _models = m;
        _status = 'Key works · ${m.length} models';
      });
    } catch (e) {
      setState(() => _status = e.toString().replaceFirst('groq: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget picker(String label, String? value, String setting, void Function(String) set) => DropdownButtonFormField<String>(
          initialValue: _models!.contains(value) ? value : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [for (final m in _models!) DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))],
          onChanged: (v) {
            if (v == null) return;
            set(v);
            widget.session.db.setSetting(setting, v);
          },
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.key, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(_status ?? '…')),
            if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _key,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: _hasOwn ? 'Replace this profile\'s key' : 'Paste a Groq API key for this profile',
              suffixIcon: IconButton(icon: const Icon(Icons.check), onPressed: () => _check(_key.text)),
            ),
            onSubmitted: _check,
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            OutlinedButton(onPressed: _busy ? null : () => _check(), child: const Text('Test key and load models')),
            if (_hasOwn)
              TextButton(
                onPressed: () async {
                  await storage.delete(key: _store);
                  setState(() {
                    _hasOwn = false;
                    _status = envKey() != null ? 'Using the key built in from .env' : 'No key yet';
                  });
                },
                child: const Text('Remove key'),
              ),
          ]),
          if (_models != null) ...[
            const SizedBox(height: 12),
            picker('Model for news tagging (small, fast)', _tag, 'groq_tag_model', (v) => _tag = v),
            const SizedBox(height: 12),
            picker('Model for Ask', _ask, 'groq_ask_model', (v) => _ask = v),
          ],
          const SizedBox(height: 8),
          Text(
            'The key is stored encrypted on this phone. Only headlines, publishers, times, company names and your '
            'questions (with amounts removed) are sent. Never holdings, units or prices you paid.',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }
}
