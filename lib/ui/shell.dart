import 'dart:async';

import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/portfolio.dart';
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

class _ShellState extends State<Shell> {
  int _tab = 0;
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
    _subs.addAll([
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
    s.portfolio.value = Portfolio.compute(
        txs: _txs!, instruments: _inst!, prefs: _prefs, goals: _goals, sips: _sips);
  }

  @override
  void dispose() {
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
