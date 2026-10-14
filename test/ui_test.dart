import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/db/open_db.dart';
import 'package:signal_investor/engine/calendar.dart';
import 'package:signal_investor/engine/lots.dart';
import 'package:signal_investor/engine/portfolio.dart';
import 'package:signal_investor/main.dart';
import 'package:signal_investor/ui/holding.dart';
import 'package:signal_investor/ui/sandbox.dart';
import 'package:signal_investor/ui/settings.dart';
import 'package:signal_investor/ui/shell.dart';
import 'package:signal_investor/ui/theme.dart';
import 'package:signal_investor/ui/widgets.dart';

/// Awaits a DB/storage future inside fake-async by pumping until it settles.
Future<T> q<T>(WidgetTester t, Future<T> Function() f) async {
  final fut = f();
  var done = false;
  late T value;
  Object? err;
  fut.then((v) {
    value = v;
    done = true;
  }, onError: (Object e) {
    err = e;
    done = true;
  });
  for (var i = 0; !done && i < 500; i++) {
    await t.pump(const Duration(milliseconds: 10));
  }
  if (err != null) throw err!;
  if (!done) throw StateError('future did not complete');
  return value;
}

Future<void> settle(WidgetTester t, [int n = 20]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

// UI tests use in-memory plain DBs; encryption is covered in db_test.dart.
void main() {
  late ProfileDb db;
  late MarketDb market;
  late Session session;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'tour_done': '1', 'notif_asked': '1'});
    db = ProfileDb(NativeDatabase.memory());
    market = MarketDb(NativeDatabase.memory());
    session = Session(const Profile('p1', 'Profile 1'), db, market, ValueNotifier<Portfolio?>(null), () {});
  });

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(1080, 4000);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
  }

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await q(t, () async {
      await db.close();
      await market.close();
    });
    await t.pump(const Duration(seconds: 1));
  }

  Widget app([Widget? home]) =>
      MaterialApp(theme: buildTheme(Brightness.light), home: home ?? Shell(session: session));

  Future<int> stock(WidgetTester t, String name, String sym) => q(t, () =>
      market.into(market.instruments).insert(InstrumentsCompanion.insert(kind: 'stock', name: name, nseSymbol: Value(sym))));

  testWidgets('add instrument + buy, lots, oversell rejected, edit, delete', (t) async {
    tall(t);
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('Start here'), findsOneWidget);

    await t.tap(find.text('Add'));
    await settle(t);
    await t.tap(find.text('Choose fund or stock'));
    await settle(t);
    await t.tap(find.text('Add by symbol or scheme code'));
    await settle(t);
    await t.tap(find.text('NSE stock'));
    await settle(t, 5);
    await t.enterText(find.widgetWithText(TextFormField, 'Name'), 'Reliance Industries');
    await t.enterText(find.widgetWithText(TextFormField, 'NSE symbol'), 'reliance');
    await t.tap(find.widgetWithText(FilledButton, 'Add'));
    await settle(t);
    final inst = await q(t, () => (market.select(market.instruments)..where((i) => i.nseSymbol.equals('RELIANCE'))).getSingle());
    expect(inst.yahooTicker, 'RELIANCE.NS');
    expect(find.text('Reliance Industries'), findsOneWidget);

    await t.enterText(find.widgetWithText(TextFormField, 'Quantity (shares)'), '10');
    await t.enterText(find.widgetWithText(TextFormField, 'Price per share'), '2500.5');
    await t.enterText(find.widgetWithText(TextFormField, 'Charges (optional)'), '20');
    await settle(t, 3);
    expect(find.text('₹25,005.00'), findsOneWidget);
    await t.tap(find.text('Save'));
    await settle(t);

    // Holdings tab -> detail.
    await t.tap(find.text('Holdings'));
    await settle(t);
    expect(find.text('₹25,025'), findsWidgets); // row + totals strip
    await t.tap(find.text('Reliance Industries'));
    await settle(t);
    final lt = longTermFrom(istToday());
    expect(find.textContaining(prettyDay(lt)), findsOneWidget);

    // Oversell rejected.
    await t.tap(find.text('I bought this'));
    await settle(t);
    await t.tap(find.widgetWithText(ChoiceChip, 'Sell'));
    await settle(t, 3);
    await t.enterText(find.widgetWithText(TextFormField, 'Quantity (shares)'), '15');
    await t.enterText(find.widgetWithText(TextFormField, 'Price per share'), '2600');
    await t.tap(find.text('Save'));
    await settle(t);
    expect(find.textContaining('exceed the units held'), findsOneWidget);
    expect(await q(t, () => db.select(db.transactions).get()), hasLength(1));
    await t.pageBack();
    await settle(t);

    // Edit (tap history row) to 12 units.
    await t.ensureVisible(find.textContaining('Buy  10'));
    await t.tap(find.textContaining('Buy  10'));
    await settle(t);
    await t.enterText(find.widgetWithText(TextFormField, 'Quantity (shares)'), '12');
    await t.tap(find.text('Save changes'));
    await settle(t);
    expect(find.textContaining('12 units'), findsWidgets);

    // Delete shows Undo (no "are you sure?"); Undo restores the same row.
    await t.drag(find.byType(ListView).first, const Offset(0, -3000));
    await settle(t);
    await t.tap(find.byTooltip('Delete'));
    await settle(t);
    expect(find.text('History'), findsNothing); // nothing owned: back to the plain stock page
    expect(find.text('I bought this'), findsOneWidget);
    await t.tap(find.text('Undo'));
    await settle(t);
    expect(find.text('History'), findsOneWidget);
    expect(await q(t, () => db.select(db.transactions).get()), hasLength(1));
    await t.drag(find.byType(ListView).first, const Offset(0, -3000));
    await settle(t);
    await t.tap(find.byTooltip('Delete'));
    await settle(t, 120); // let the snackbar expire
    expect(find.text('History'), findsNothing);
    final audit = await q(t, () => db.select(db.auditLog).get());
    expect(audit.where((a) => a.detail.startsWith('transaction')).map((a) => a.action),
        ['insert', 'edit', 'delete', 'restore', 'delete']);
    await close(t);
  });

  testWidgets('cannot delete a buy a later sell needs; split and dividend shown', (t) async {
    tall(t);
    final id = await stock(t, 'Infosys', 'INFY');
    await q(t, () async {
      await db.addTx(TransactionsCompanion.insert(instrumentId: id, date: '2024-01-10', type: 'buy', unitsE4: 100000, priceE4: 15000000));
      await db.addTx(TransactionsCompanion.insert(instrumentId: id, date: '2025-03-03', type: 'split', unitsE4: 20000, priceE4: 0));
      await db.addTx(TransactionsCompanion.insert(instrumentId: id, date: '2025-06-02', type: 'sell', unitsE4: 150000, priceE4: 9000000));
      await db.addTx(TransactionsCompanion.insert(instrumentId: id, date: '2025-07-01', type: 'dividend', unitsE4: 0, priceE4: 1500000));
    });
    await t.pumpWidget(app());
    await settle(t);
    await t.tap(find.text('Holdings'));
    await settle(t);
    await t.tap(find.text('Infosys'));
    await settle(t);
    expect(find.textContaining('5 units · avg'), findsOneWidget); // 10 -> 20 after split, sold 15
    expect(find.textContaining('Split  1 → 2'), findsOneWidget);
    expect(find.text('LTCG'), findsOneWidget);
    expect(find.textContaining('₹150'), findsWidgets);
    // Delete the buy (last history row).
    await t.drag(find.byType(ListView).first, const Offset(0, -3000));
    await settle(t);
    await t.tap(find.byTooltip('Delete').last);
    await settle(t);
    expect(find.textContaining('Cannot delete'), findsOneWidget);
    expect(await q(t, () => db.select(db.transactions).get()), hasLength(4));
    await close(t);
  });

  testWidgets('home tiles resize on long-press, hide via customize, persist', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    final id = await stock(t, 'TCS', 'TCS');
    await q(t, () => db.addTx(
        TransactionsCompanion.insert(instrumentId: id, date: '2025-01-10', type: 'buy', unitsE4: 10000, priceE4: 40000000)));
    await t.pumpWidget(app());
    await settle(t);
    final tile = find.byKey(const ValueKey('tile-alloc'));
    await t.ensureVisible(tile);
    await settle(t, 4);
    final w1 = t.getSize(tile).width;
    await t.longPress(find.text('Allocation'));
    await settle(t);
    expect(t.getSize(tile).width, greaterThan(w1 * 1.8));
    expect(await q(t, () => storage.read(key: 'layout4_p1')), contains('"alloc":2'));

    await t.ensureVisible(find.text('Customize home'));
    await settle(t);
    await t.tap(find.text('Customize home'));
    await settle(t);
    final row = find.ancestor(of: find.text('Allocation'), matching: find.byType(ListTile));
    await t.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await settle(t);
    await t.tapAt(const Offset(200, 40)); // dismiss sheet
    await settle(t);
    expect(find.byKey(const ValueKey('tile-alloc')), findsNothing);
    final saved = jsonDecode((await q(t, () => storage.read(key: 'layout4_p1')))!) as Map;
    expect(saved['hidden'], contains('alloc'));
    await close(t);
  });

  testWidgets('plan: SIP plan with missed instalment, record prefilled, add goal', (t) async {
    tall(t);
    final id = await q(t, () => market.into(market.instruments).insert(
        InstrumentsCompanion.insert(kind: 'mf', name: 'Nifty Index', schemeCode: const Value('120716'))));
    final today = istToday();
    final start = DateTime.utc(today.year, today.month - 2, 3);
    await q(t, () async {
      await db.saveSip(SipPlansCompanion.insert(instrumentId: id, amountPaise: 500000, dayOfMonth: 3, start: fmtDay(start)));
      // Only the first instalment recorded.
      await db.addTx(TransactionsCompanion.insert(
          instrumentId: id, date: fmtDay(nse.onOrAfter(start)), type: 'sip', unitsE4: 100000, priceE4: 500000));
    });
    await t.pumpWidget(app());
    await settle(t);
    await t.tap(find.text('Plan'));
    await settle(t);
    expect(find.text('1 recorded'), findsOneWidget);
    expect(find.textContaining('missed'), findsWidgets);
    await t.tap(find.text('Record').first);
    await settle(t);
    expect(find.text('Record SIP'), findsOneWidget);
    expect(find.text('Nifty Index'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Amount invested'), findsOneWidget);
    await t.pageBack();
    await settle(t);

    await t.tap(find.text('Goal'));
    await settle(t);
    await t.enterText(find.widgetWithText(TextFormField, 'Name'), 'Masters');
    await t.enterText(find.widgetWithText(TextFormField, 'Target amount'), '1500000');
    await t.tap(find.text('Save'));
    await settle(t);
    expect(find.text('Masters'), findsOneWidget);
    final g = await q(t, () => db.select(db.goals).getSingle());
    expect(g.targetPaise, 150000000);
    await close(t);
  });

  testWidgets('picker searches the whole NSE list and adds a stock in one tap', (t) async {
    tall(t);
    await q(t, () => market.batch((b) => b.insertAll(market.universe, [
          UniverseCompanion.insert(symbol: 'INFY', name: 'Infosys Limited', nifty500: const Value(true)),
          UniverseCompanion.insert(symbol: 'INFIBEAM', name: 'Infibeam Avenues Limited'),
        ])));
    await t.pumpWidget(app());
    await settle(t);
    await t.tap(find.text('Add'));
    await settle(t);
    await t.tap(find.text('Choose fund or stock'));
    await settle(t);
    await t.enterText(find.widgetWithText(TextField, 'Search any NSE stock or mutual fund'), 'infy');
    await settle(t, 30);
    expect(find.text('Infosys Limited'), findsOneWidget);
    expect(find.textContaining('NIFTY 500'), findsOneWidget);
    await t.tap(find.text('Infosys Limited'));
    await settle(t);
    final inst = await q(t, () => (market.select(market.instruments)..where((i) => i.nseSymbol.equals('INFY'))).getSingle());
    expect(inst.yahooTicker, 'INFY.NS');
    expect(find.text('Infosys Limited'), findsOneWidget); // selected in the form
    await close(t);
  });

  testWidgets('scan "Try in sandbox" offers one buy sheet; cancel does not reopen it; buy lands once', (t) async {
    tall(t);
    final id = await stock(t, 'Oracle Financial', 'OFSS');
    await q(t, () => market.putPrices(id, 'yahoo', [('2026-10-13', 90000000)]));
    await t.pumpWidget(app());
    await settle(t, 40);
    t.state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => SandboxScreen(session: session, buyInstrumentId: id)));
    await settle(t);
    expect(find.text('Buy at latest price'), findsOneWidget);
    await t.tapAt(const Offset(20, 20)); // dismiss
    await settle(t);
    expect(find.text('Buy at latest price'), findsNothing);
    await t.tap(find.text('Paper buy'));
    await settle(t);
    await t.tap(find.byType(DropdownButtonFormField<int>));
    await settle(t);
    await t.tap(find.text('Oracle Financial').last);
    await settle(t);
    await t.tap(find.text('Buy at latest price'));
    await settle(t, 40);
    expect(find.text('Buy at latest price'), findsNothing);
    expect(await q(t, () => db.select(db.paperTrades).get()), hasLength(1));
    await close(t);
  });

  testWidgets('empty home guides: start steps, search, ask, pulse, ideas, watchlist', (t) async {
    tall(t);
    await t.pumpWidget(app());
    await settle(t, 40);
    for (final s in ['Start here', 'Search any stock or mutual fund', 'News pulse', 'Top ideas', 'Watchlist', '1-minute tour']) {
      expect(find.textContaining(s), findsWidgets, reason: s);
    }
    expect(find.textContaining('Ask SIGNAL'), findsWidgets);
    await t.tap(find.byTooltip('How to use SIGNAL'));
    await settle(t);
    expect(find.text('How do I add a stock or fund I bought?'), findsOneWidget);
    await close(t);
  });

  testWidgets('unowned stock page: price, watch, "I bought this" fills the price', (t) async {
    tall(t);
    final id = await stock(t, 'Tata Consultancy', 'TCS');
    final today = istToday(), prev = nse.onOrBefore(today.subtract(const Duration(days: 1)));
    await q(t, () => market.putPrices(id, 'yahoo', [(fmtDay(prev), 24000000), (fmtDay(today), 25000000)]));
    await t.pumpWidget(app());
    await settle(t, 40);
    t.state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute(builder: (_) => HoldingScreen(session: session, instrumentId: id)));
    await settle(t, 40);
    expect(find.text('₹2,500.00'), findsWidgets);
    expect(find.textContaining('+4.17%'), findsOneWidget);
    expect(find.text('History'), findsNothing);
    await t.tap(find.text('Watch'));
    await settle(t);
    expect(find.text('Watching'), findsOneWidget);
    expect((await q(t, () => db.select(db.watchlist).get())).single.instrumentId, id);
    await t.tap(find.text('I bought this'));
    await settle(t, 60);
    expect(find.widgetWithText(TextFormField, 'Price per share'), findsOneWidget);
    expect(find.text('2500'), findsOneWidget); // filled in
    expect(find.textContaining('filled in'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextFormField, 'Quantity (shares)'), '4');
    await settle(t, 3);
    expect(find.text('₹10,000.00'), findsOneWidget);
    await close(t);
  });

  testWidgets('first-run tour: demo choice runs after the tour closes and its progress dialog always closes', (t) async {
    tall(t);
    FlutterSecureStorage.setMockInitialValues({'notif_asked': '1'}); // tour not done yet
    await t.pumpWidget(app());
    await settle(t, 40);
    expect(find.text('Track what you own'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.text('Next'));
      await settle(t, 10);
    }
    await t.tap(find.text('Explore with a demo portfolio'));
    for (var i = 0; i < 400 && find.textContaining('Could not reach').evaluate().isEmpty; i++) {
      await t.pump(const Duration(milliseconds: 50)); // offline in tests: the demo gives up
    }
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.textContaining('Could not reach the price sources'), findsWidgets);
    expect(await q(t, () => storage.read(key: 'tour_done')), '1');
    expect(find.text('Start here'), findsOneWidget);
    await close(t);
  });

  testWidgets('settings theme toggle persists', (t) async {
    tall(t);
    await t.pumpWidget(app(SettingsScreen(session: session)));
    await settle(t);
    await t.tap(find.text('Dark'));
    await settle(t);
    expect(themeMode.value, ThemeMode.dark);
    expect(await q(t, () => storage.read(key: 'theme_mode')), 'dark');
    await q(t, () => setThemeMode(ThemeMode.system));
    await close(t);
  });

  testWidgets('first run: disclaimer, then fingerprint lock; one profile per phone', (t) async {
    tall(t);
    await t.pumpWidget(const App());
    await settle(t);
    expect(find.textContaining('Not investment, tax or legal advice'), findsOneWidget);
    await t.tap(find.text('I understand'));
    await settle(t);
    expect(find.text('Unlock'), findsOneWidget);
    expect(find.byType(TextField), findsNothing); // never asks for a name or a profile
    final a = await q(t, deviceProfile);
    final b = await q(t, deviceProfile);
    expect(b.id, a.id);
    expect(await q(t, loadProfiles), hasLength(1));
    expect(await q(t, () => storage.read(key: 'key_${a.id}')), matches(RegExp(r'^[0-9a-f]{64}$')));
    await close(t);
  });
}
