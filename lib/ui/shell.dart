import 'dart:async';

import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/calendar.dart';
import '../engine/portfolio.dart';
import '../engine/valuation.dart';
import '../pipeline/refresh.dart';
import '../sources/net.dart';
import 'activity.dart';
import 'add_transaction.dart';
import 'dashboard.dart';
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
  late final _net = Net();
  late final _refresher = Refresher(s.market, _net);
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
      (m.select(m.fetchLog)..where((f) => f.source.equals('full'))).watchSingleOrNull()
          .listen((f) => s.lastRefresh.value = f?.lastOkAt),
      db.watchTxs().listen((v) => _set(() => _txs = v)),
      m.select(m.instruments).watch().listen((v) => _set(() => _inst = v)),
      db.select(db.holdingPrefs).watch().listen((v) => _set(() => _prefs = v)),
      db.select(db.goals).watch().listen((v) => _set(() => _goals = v)),
      db.select(db.sipPlans).watch().listen((v) => _set(() => _sips = v)),
    ]);
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
    s.portfolio.value =
        Portfolio.compute(txs: _txs!, instruments: _inst!, prefs: _prefs, goals: _goals, sips: _sips, book: book);
    if (!_refreshedOnce) {
      _refreshedOnce = true;
      _refresh();
    }
  }

  Future<void> _refresh({bool force = false}) async {
    if (s.refreshing.value) return;
    s.refreshing.value = true;
    try {
      final held = {for (final h in s.portfolio.value?.holdings ?? const <Holding>[]) h.instrumentId};
      final lines = await _refresher.run(held, force: force);
      if (force || lines.isNotEmpty) s.receipt.value = lines;
    } finally {
      if (mounted) s.refreshing.value = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
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
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      floatingActionButton: _tab == 3
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
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Holdings'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Plan'),
        ],
      ),
    );
  }
}
