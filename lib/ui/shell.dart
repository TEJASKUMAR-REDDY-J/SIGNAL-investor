import 'dart:async';

import 'package:flutter/material.dart';

import '../db/db.dart';
import '../db/open_db.dart';
import '../engine/calendar.dart';

import 'package:flutter/services.dart';

import '../engine/lots.dart';
import '../engine/news_score.dart';
import '../engine/portfolio.dart';
import '../engine/sell_rules.dart';
import '../engine/valuation.dart';
import '../pipeline/background.dart';
import '../pipeline/feeds.dart';
import '../pipeline/instruments.dart';
import '../pipeline/live.dart';
import '../pipeline/refresh.dart';
import '../pipeline/scan.dart';
import '../sources/groq.dart';
import 'ask.dart';
import 'lab.dart';
import 'sandbox.dart';
import '../sources/net.dart';
import 'activity.dart';
import 'add_transaction.dart';
import 'dashboard.dart';
import 'guide.dart';
import 'holdings.dart';
import 'plan.dart';
import 'widgets.dart';

/// Signed-in home: subscribes once to every table and recomputes one
/// [Portfolio] per change, shared by all tabs (no per-screen FIFO work).
class Shell extends StatefulWidget {
  final Session session;
  const Shell({super.key, required this.session});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _tab = 0;
  List<Price> _prices = const [];
  Timer? _debounce;
  bool _refreshedOnce = false;
  int _satTarget = 25;
  late final _net = Net();
  Set<int> _paper = const {};
  Set<int> _ideaIds = const {};
  List<NewsItem> _newsItems = const [];
  Timer? _liveTimer;
  String _savedTracked = '';
  late final _refresher = Refresher(
    s.market,
    _net,
    extra: [filingsStep(s.market, _net, _tracked), newsStep(s.market, _net, _tracked, _groq)],
  );

  Set<int> _heldReal() => {for (final h in s.portfolio.value?.holdings ?? const <Holding>[]) h.instrumentId};

  /// Holdings, sandbox positions and the watchlist: prices kept fresh.
  Set<int> _held() => {..._heldReal(), ..._paper, ...s.watch.value};

  /// Plus the advisor's top stock ideas: news and filings tracked for all of these.
  Set<int> _tracked() => {..._held(), ..._ideaIds};

  Future<(String, String)?> _groq() async {
    final key = await groqKeyFor(s.profile.id);
    if (key == null) return null;
    return (key, await s.db.setting('groq_tag_model') ?? defaultTagModel);
  }

  final _subs = <StreamSubscription>[];
  List<Transaction>? _txs;
  List<Instrument>? _inst;
  List<HoldingPref> _prefs = const [];
  List<Goal> _goals = const [];
  List<SipPlan> _sips = const [];

  Session get s => widget.session;

  @override
  void initState() {
    super.initState();
    final db = s.db, m = s.market;
    WidgetsBinding.instance.addObserver(this);
    s.refresh = _refresh;
    m.select(m.holidays).get().then((h) => loadHolidays({for (final x in h) x.date: x.name}));
    _subs.addAll([
      m.select(m.prices).watch().listen((v) => _set(() => _prices = v)),
      (m.select(
        m.fetchLog,
      )..where((f) => f.source.equals('full'))).watchSingleOrNull().listen((f) => s.lastRefresh.value = f?.lastOkAt),
      db.watchTxs().listen((v) => _set(() => _txs = v)),
      db.select(db.paperTrades).watch().listen((v) => _paper = paperHeld(v)),
      db.select(db.theses).watch().listen((v) => _set(() => s.theses.value = {for (final t in v) t.instrumentId: t})),
      (db.select(db.signals)..where((x) => x.status.equals('open'))).watch().listen((v) => s.openSignals.value = v),
      m.select(m.filings).watch().listen((v) {
        final by = <int, List<Filing>>{};
        for (final f in v) {
          (by[f.instrumentId] ??= []).add(f);
        }
        _set(() => s.filings.value = by);
      }),
      (db.select(db.profileSettings)..where((x) => x.key.equals('satellite_target_pct'))).watchSingleOrNull().listen(
        (v) => _set(() => _satTarget = int.tryParse(v?.value ?? '') ?? 25),
      ),
      m.select(m.instruments).watch().listen((v) => _set(() => _inst = v)),
      db.select(db.holdingPrefs).watch().listen((v) => _set(() => _prefs = v)),
      db.select(db.goals).watch().listen((v) => _set(() => _goals = v)),
      db.select(db.sipPlans).watch().listen((v) => _set(() => _sips = v)),
      db.select(db.watchlist).watch().listen((v) {
        s.watch.value = {for (final w in v) w.instrumentId};
        _scoreNews();
        _saveTracked();
      }),
      m.select(m.newsItems).watch().listen((v) {
        _newsItems = v;
        _scoreNews();
      }),
    ]);
    s.reloadIdeas = _loadIdeas;
    _loadIdeas();
    _liveTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_resumed && nse.status(DateTime.now()).phase == MarketPhase.open) _live();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startBackground());
  }

  bool _resumed = true;

  void _scoreNews() {
    final t = _tracked();
    s.news.value = newsScores([for (final n in _newsItems) if (t.contains(n.instrumentId)) n], DateTime.now().toUtc());
  }

  /// Advisor ideas straight from the cache; instrument rows for the top stocks so their news is tracked.
  Future<void> _loadIdeas() async {
    final held = {for (final h in s.portfolio.value?.holdings ?? const <Holding>[]) ?h.instrument?.nseSymbol};
    final ideas = await stockIdeas(s.market, exclude: held);
    final ids = <int>{};
    for (final c in ideas) {
      ids.add(await ensureStock(s.market, c.input.symbol, c.input.name));
    }
    if (!mounted) return;
    _ideaIds = ids;
    s.stockIdeas.value = ideas;
    s.fundIdeas.value = await fundIdeas(s.market);
    _scoreNews();
    _saveTracked();
  }

  /// The background job reads this list; it never opens the profile database.
  void _saveTracked() {
    final t = (_tracked().toList()..sort()).join(',');
    if (t == _savedTracked) return;
    _savedTracked = t;
    saveTracked(_tracked()).catchError((_) {});
  }

  /// Live (delayed) quotes for the index strip, holdings and watchlist: one request per 20.
  Future<void> _live() async {
    try {
      final idx = await ensureIndices(s.market);
      final ids = _held();
      final inst = [...idx, ...(_inst ?? const <Instrument>[]).where((i) => ids.contains(i.id) && i.kind == 'stock')];
      final q = await liveQuotes(s.market, _net, inst);
      if (mounted && q.isNotEmpty) s.quotes.value = {...s.quotes.value, ...q};
    } catch (_) {
      // Live prices are a nicety; the refresher still runs.
    }
  }

  Future<void> _startBackground() async {
    _live();
    // First launch only: the tour (with the demo option) before anything else.
    if (await storage.read(key: tourDoneKey) == null && mounted) {
      await openTour(context, s);
      await storage.write(key: tourDoneKey, value: '1');
    }
    try {
      await initBackground();
      if (await storage.read(key: 'notif_asked') == null) {
        await storage.write(key: 'notif_asked', value: '1');
        await requestNotificationPermission();
      }
    } catch (_) {
      // No platform (tests) or WorkManager unavailable: the app still refreshes on open.
    }
  }

  void _set(VoidCallback f) {
    f();
    if (_txs == null || _inst == null) return;
    // First paint immediately from cache; later bursts (price batches) coalesce.
    if (s.portfolio.value == null) return _compute();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _compute);
  }

  void _compute() {
    final book = PriceBook();
    for (final p in _prices) {
      book.add(p.instrumentId, p.source, p.date, p.closeE4);
    }
    book.seal();
    final p = Portfolio.compute(txs: _txs!, instruments: _inst!, prefs: _prefs, goals: _goals, sips: _sips, book: book);
    s.portfolio.value = p;
    _saveTracked();
    final sug = sellRules(p: p, theses: s.theses.value, filings: s.filings.value, satelliteTargetPct: _satTarget);
    s.suggestions.value = sug;
    _storeSignals(sug);
    if (!_refreshedOnce) {
      _refreshedOnce = true;
      _ripeCheck(p);
      _refresh();
      _loadIdeas(); // again, now that holdings are known (ideas exclude what you own)
    }
  }

  /// Every suggestion is stored with its inputs and rule version (signal log).
  Future<void> _storeSignals(List<SellSuggestion> sug) async {
    for (final x in sug) {
      await s.db.upsertSignal(x.instrumentId, x.rule, x.inputsJson, sellRuleVersion);
    }
    await s.db.closeSignalsExcept({for (final x in sug) (x.instrumentId, x.rule)}, {1, 2, 3, 4, 5});
  }

  /// Soft tap + card the first time the app opens after a lot turns long-term.
  Future<void> _ripeCheck(Portfolio p) async {
    final last = await s.db.setting('last_open_day');
    final today = fmtDay(p.today);
    if (last != null && last != today) {
      final from = parseDay(last);
      final ripe = [
        for (final h in p.holdings)
          for (final l in h.ledger.open)
            if (l.longTermDate.isAfter(from) && !l.longTermDate.isAfter(p.today)) (h.name, l),
      ];
      if (ripe.isNotEmpty) {
        s.ripened.value = ripe;
        HapticFeedback.lightImpact();
      }
    }
    if (last != today) await s.db.setSetting('last_open_day', today);
  }

  Future<void> _refresh({bool force = false}) async {
    if (s.refreshing.value) return;
    s.refreshing.value = true;
    try {
      final lines = await _refresher.run(_held(), force: force);
      if (force || lines.isNotEmpty) s.receipt.value = lines;
    } finally {
      if (mounted) s.refreshing.value = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed) {
      _refresh();
      _live();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _liveTimer?.cancel();
    for (final x in _subs) {
      x.cancel();
    }
    super.dispose();
  }

  void _add() => Navigator.push(context, MaterialPageRoute(builder: (_) => AddTransaction(session: s)));

  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(session: s, onOpenTab: (i) => setState(() => _tab = i)),
      HoldingsTab(session: s),
      ActivityTab(session: s),
      PlanTab(session: s),
      LabTab(session: s),
    ];
    // Back: other tab -> Home; Home -> lock (closes the profile database).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_tab != 0) {
          setState(() => _tab = 0);
        } else {
          s.lock();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _tab, children: pages),
        floatingActionButton: _tab >= 3
            ? null
            : FloatingActionButton.extended(
                heroTag: 'add',
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: 'Holdings',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Activity',
            ),
            NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Plan'),
            NavigationDestination(icon: Icon(Icons.science_outlined), selectedIcon: Icon(Icons.science), label: 'Lab'),
          ],
        ),
      ),
    );
  }
}
