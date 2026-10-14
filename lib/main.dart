import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import 'db/db.dart';
import 'db/open_db.dart';
import 'engine/portfolio.dart';
import 'ui/settings.dart';
import 'ui/shell.dart';
import 'ui/logo.dart';
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
  final _prompt = ValueNotifier(0); // bumped to ask the lock screen for the fingerprint again
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
      if (_profile != null && away >= const Duration(seconds: 60)) {
        lock().then((_) => _prompt.value++);
      }
    }
  }

  /// Closes the profile db and returns to the lock screen.
  Future<void> lock() async {
    final p = _profile;
    _profile = null;
    _nav.currentState?.popUntil((r) => r.isFirst);
    await p?.close();
  }

  /// One encrypted profile per phone, opened with the phone's own fingerprint, face or screen lock.
  Future<String?> unlock() async {
    if (_profile != null) return null;
    final auth = LocalAuthentication();
    try {
      if (!await auth.isDeviceSupported()) {
        return 'Set a screen lock (PIN, pattern or fingerprint) on this phone first.';
      }
      final ok = await auth.authenticate(localizedReason: 'Unlock SIGNAL Investor');
      if (!ok) return 'Not unlocked.';
      final p = await deviceProfile();
      _market ??= await openMarket();
      _profile = await openProfile(p);
      final session = Session(p, _profile!, _market!, ValueNotifier<Portfolio?>(null), lock);
      await _nav.currentState!.push(MaterialPageRoute(builder: (_) => Shell(session: session)));
      return null;
    } on LocalAuthException catch (e) {
      return 'Unlock failed: ${e.code.name}';
    } catch (e) {
      // Never surface key material; StateError messages are our own.
      return e is StateError ? e.message : 'Could not open your data.';
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
          home: LockScreen(onUnlock: unlock, prompt: _prompt),
        ),
      );
}

class LockScreen extends StatefulWidget {
  final Future<String?> Function() onUnlock;
  final ValueListenable<int>? prompt;
  const LockScreen({super.key, required this.onUnlock, this.prompt});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool? _accepted;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.prompt?.addListener(_open);
    _load();
  }

  @override
  void dispose() {
    widget.prompt?.removeListener(_open);
    super.dispose();
  }

  Future<void> _load() async {
    final ok = await storage.read(key: 'disclaimer_ok') == '1';
    if (!mounted) return;
    setState(() => _accepted = ok);
    if (ok) _open(); // ask for the fingerprint straight away on launch
  }

  Future<void> _open() async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    final err = await widget.onUnlock();
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) snack(context, err);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    if (_accepted == null) return const Scaffold(body: SizedBox());
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
                _open();
              },
              child: const Text('I understand'),
            ),
          ]),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(children: [
            const Spacer(flex: 3),
            const SizedBox(width: 88, height: 88, child: SignalLogo()),
            const SizedBox(height: 20),
            Text('SIGNAL Investor', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text("Track. Rule. Alert. Don't predict.", style: t.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
            const Spacer(flex: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _open,
                icon: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
            ),
            const SizedBox(height: 12),
            Text("Uses this phone's fingerprint, face or screen lock. Your data is encrypted and stays on this phone.",
                textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
