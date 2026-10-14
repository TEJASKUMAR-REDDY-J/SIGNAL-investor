import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'db/db.dart';
import 'db/open_db.dart';
import 'engine/portfolio.dart';
import 'ui/settings.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadThemeMode();
  runApp(const App());
}

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
      final session = Session(p, _profile!, _market!, ValueNotifier<Portfolio?>(null), lock);
      await _nav.currentState!.push(MaterialPageRoute(builder: (_) => Shell(session: session)));
      return null;
    } on LocalAuthException catch (e) {
      return 'Unlock failed: ${e.code.name}';
    } catch (e) {
      // Never surface key material; StateError messages are our own.
      return e is StateError ? e.message : 'Could not open profile.';
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: themeMode,
        builder: (context, mode, _) => MaterialApp(
          navigatorKey: _nav,
          title: 'SIGNAL Investor',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: mode,
          home: ProfilePicker(onUnlock: unlock),
        ),
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
  String? _busy;

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
    await createProfile();
    await _load();
  }

  Future<void> _open(Profile p) async {
    setState(() => _busy = p.id);
    final err = await widget.onUnlock(p);
    if (!mounted) return;
    setState(() => _busy = null);
    if (err != null) snack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    if (_profiles == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_accepted != true) {
      return Scaffold(
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 48, 24, 24), children: [
            Icon(Icons.shield_moon_outlined, size: 56, color: cs.primary),
            const SizedBox(height: 20),
            Text('Before you start', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Text(disclaimer, style: t.bodyLarge?.copyWith(height: 1.5, color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () async {
                await storage.write(key: 'disclaimer_ok', value: '1');
                setState(() => _accepted = true);
              },
              child: const Text('I understand'),
            ),
          ]),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 40, 20, 100), children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.insights, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Text('SIGNAL', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ]),
          const SizedBox(height: 28),
          Text('Track. Rule. Alert.', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text("Don't predict.", style: t.headlineMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 32),
          Text('Who is investing?', style: t.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          for (final p in _profiles!)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarColor(p.id),
                    child: Text(p.badge,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                  subtitle: const Text('Encrypted profile'),
                  trailing: _busy == p.id
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : Icon(Icons.fingerprint, color: cs.primary, size: 28),
                  onTap: _busy == null ? () => _open(p) : null,
                ),
              ),
            ),
          if (_profiles!.isEmpty)
            const EmptyState(
              icon: Icons.group_outlined,
              title: 'No profiles yet',
              message: 'Each person gets their own encrypted profile, unlocked with this phone\'s fingerprint or PIN.',
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy == null ? _create : null,
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add profile'),
          ),
        ]),
      ),
    );
  }
}
