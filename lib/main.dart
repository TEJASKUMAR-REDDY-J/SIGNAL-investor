import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'db/db.dart';
import 'db/open_db.dart';
import 'ui/dashboard.dart';

void main() => runApp(const App());

const disclaimer =
    'Personal decision aid only. Not investment, tax or legal advice; the '
    'authors are not SEBI-registered advisers. Tax figures are estimates for '
    'listed equity and equity mutual funds only (no surcharge, debt funds or '
    'grandfathering). Market data comes from unofficial public sources and can '
    'be wrong or late. Verify everything with your broker, RTA statement or a '
    'chartered accountant before acting. This app never places orders.';

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final _nav = GlobalKey<NavigatorState>();
  MarketDb? _market;
  ProfileDb? _profile;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      _pausedAt ??= DateTime.now();
    } else if (s == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (_profile != null && away >= const Duration(seconds: 60)) lock();
    }
  }

  /// Closes the profile db and returns to the picker.
  Future<void> lock() async {
    final p = _profile;
    _profile = null;
    _nav.currentState?.popUntil((r) => r.isFirst);
    await p?.close();
  }

  Future<String?> unlock(Profile p) async {
    final auth = LocalAuthentication();
    try {
      if (!await auth.isDeviceSupported()) {
        return 'Set a screen lock (PIN, pattern or fingerprint) on this phone first.';
      }
      final ok = await auth.authenticate(localizedReason: 'Unlock ${p.name}');
      if (!ok) return 'Not unlocked.';
      _market ??= await openMarket();
      _profile = await openProfile(p);
      await _nav.currentState!.push(MaterialPageRoute(
          builder: (_) => Dashboard(profile: p, db: _profile!, market: _market!, onLock: lock)));
      return null;
    } on LocalAuthException catch (e) {
      return 'Unlock failed: ${e.code.name}';
    } catch (e) {
      // Never surface key material; StateError messages are our own.
      return e is StateError ? e.message : 'Could not open profile.';
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: _nav,
        title: 'SIGNAL Investor',
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        darkTheme: ThemeData(
            colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
        home: ProfilePicker(onUnlock: unlock),
      );
}

class ProfilePicker extends StatefulWidget {
  final Future<String?> Function(Profile) onUnlock;
  const ProfilePicker({super.key, required this.onUnlock});
  @override
  State<ProfilePicker> createState() => _ProfilePickerState();
}

class _ProfilePickerState extends State<ProfilePicker> {
  List<Profile>? _profiles;
  bool? _accepted;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ps = await loadProfiles();
    final ok = await storage.read(key: 'disclaimer_ok') == '1';
    if (mounted) setState(() => (_profiles = ps, _accepted = ok));
  }

  Future<void> _create() async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New profile'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'Display name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Create')),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await createProfile(name);
    await _load();
  }

  Future<void> _open(Profile p) async {
    setState(() => _busy = true);
    final err = await widget.onUnlock(p);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  @override
  Widget build(BuildContext context) {
    if (_profiles == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_accepted != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Before you start')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Icon(Icons.info_outline, size: 48),
          const SizedBox(height: 16),
          const Text(disclaimer, style: TextStyle(fontSize: 16, height: 1.4)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await storage.write(key: 'disclaimer_ok', value: '1');
              setState(() => _accepted = true);
            },
            child: const Text('I understand'),
          ),
        ]),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('SIGNAL Investor')),
      body: ListView(children: [
        for (final p in _profiles!)
          ListTile(
            leading: CircleAvatar(child: Text(p.name.characters.first.toUpperCase())),
            title: Text(p.name),
            trailing: const Icon(Icons.fingerprint),
            enabled: !_busy,
            onTap: () => _open(p),
          ),
        if (_profiles!.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No profiles yet. Each person gets their own encrypted profile.'),
          ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _create,
        icon: const Icon(Icons.person_add),
        label: const Text('Profile'),
      ),
    );
  }
}
