import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/db/open_db.dart';
import 'package:signal_investor/engine/lots.dart';
import 'package:signal_investor/main.dart';
import 'package:signal_investor/ui/dashboard.dart';

// UI tests use in-memory plain DBs; encryption is covered in db_test.dart.
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

void main() {
  late ProfileDb db;
  late MarketDb market;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    db = ProfileDb(NativeDatabase.memory());
    market = MarketDb(NativeDatabase.memory());
  });

  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await q(t, () async {
      await db.close();
      await market.close();
    });
    await t.pump(const Duration(seconds: 1));
  }

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  Widget app() => MaterialApp(
      home: Dashboard(profile: const Profile('p1', 'Asha'), db: db, market: market, onLock: () {}));

  testWidgets('add instrument + buy, view lots, reject oversell, edit, delete', (t) async {
    tall(t);
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.textContaining('No holdings yet'), findsOneWidget);

    await t.tap(find.text('Transaction'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('New fund / stock'));
    await t.pumpAndSettle();
    await t.tap(find.text('NSE stock'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextFormField, 'Name'), 'Reliance Industries');
    await t.enterText(find.widgetWithText(TextFormField, 'NSE symbol'), 'reliance');
    await t.tap(find.text('Add'));
    await t.pumpAndSettle();
    final inst = await q(t, () => market.select(market.instruments).getSingle());
    expect(inst.nseSymbol, 'RELIANCE');
    expect(inst.yahooTicker, 'RELIANCE.NS');

    await t.enterText(find.widgetWithText(TextFormField, 'Units'), '10');
    await t.enterText(find.widgetWithText(TextFormField, 'Price / NAV per unit (₹)'), '2500.5');
    await t.enterText(find.widgetWithText(TextFormField, 'Charges (₹, optional)'), '20');
    await t.pump();
    expect(find.text('Total: ₹25,005.00'), findsOneWidget);
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();

    // Back on dashboard: cost incl. charges.
    expect(find.text('Reliance Industries'), findsOneWidget);
    expect(find.text('₹25,025'), findsWidgets);

    await t.tap(find.text('Reliance Industries'));
    await t.pumpAndSettle();
    final lt = fmtDay(longTermFrom(istToday()));
    expect(find.textContaining('turns long-term on $lt'), findsOneWidget);

    // Oversell is rejected.
    await t.tap(find.byTooltip('Add transaction'));
    await t.pumpAndSettle();
    await t.tap(find.text('Sell'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextFormField, 'Units'), '15');
    await t.enterText(find.widgetWithText(TextFormField, 'Price / NAV per unit (₹)'), '2600');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.textContaining('exceed the units held'), findsOneWidget);
    expect(await q(t, () => db.select(db.transactions).get()), hasLength(1));
    await t.pageBack();
    await t.pumpAndSettle();

    // Edit to 12 units.
    await t.tap(find.byType(PopupMenuButton<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextFormField, 'Units'), '12');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('12 units'), findsOneWidget);

    // Delete.
    await t.tap(find.byType(PopupMenuButton<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Delete'));
    await t.pumpAndSettle();
    expect(find.text('No open lots'), findsOneWidget);

    final audit = await q(t, () => db.select(db.auditLog).get());
    expect(audit.map((a) => a.action), ['insert', 'edit', 'delete']);
    await close(t);
  });

  testWidgets('cannot delete a buy that a later sell depends on; dividends and SIP', (t) async {
    tall(t);
    await q(t, () async {
      final id = await market.into(market.instruments).insert(
          InstrumentsCompanion.insert(kind: 'mf', name: 'Index Fund', schemeCode: const Value('120716')));
      await db.addTx(TransactionsCompanion.insert(
          instrumentId: id, date: '2024-01-10', type: 'sip', unitsE4: 1234567, priceE4: 405000));
      await db.addTx(TransactionsCompanion.insert(
          instrumentId: id, date: '2025-06-01', type: 'sell', unitsE4: 1000000, priceE4: 500000));
      await db.addTx(TransactionsCompanion.insert(
          instrumentId: id, date: '2025-07-01', type: 'dividend', unitsE4: 0, priceE4: 1500000));
    });
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.text('Index Fund'));
    await t.pumpAndSettle();
    expect(find.text('23.4567 units'), findsOneWidget);
    expect(find.textContaining('long-term since 2025-01-11'), findsOneWidget);
    expect(find.textContaining('LTCG'), findsOneWidget);
    expect(find.textContaining('Dividends ₹150.00'), findsOneWidget);

    // Transactions are listed newest first; the SIP is last.
    await t.ensureVisible(find.byType(PopupMenuButton<String>).last);
    await t.pumpAndSettle();
    await t.tap(find.byType(PopupMenuButton<String>).last);
    await t.pumpAndSettle();
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    expect(find.textContaining('Cannot delete'), findsOneWidget);
    expect(await q(t, () => db.select(db.transactions).get()), hasLength(3));
    await close(t);
  });

  testWidgets('tiles resize on long-press and the layout persists', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3; // 360 dp phone
    addTearDown(t.view.reset);
    final id = (await q(t, () async {
      final id = await market.into(market.instruments).insert(InstrumentsCompanion.insert(kind: 'stock', name: 'TCS'));
      await db.addTx(TransactionsCompanion.insert(
          instrumentId: id, date: '2025-01-10', type: 'buy', unitsE4: 10000, priceE4: 40000000));
      return id;
    }));
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    final tile = find.byKey(ValueKey('tile-i$id'));
    final w1 = t.getSize(tile).width;
    await t.longPress(find.text('TCS'));
    await t.pumpAndSettle();
    final w2 = t.getSize(tile).width;
    expect(w2, greaterThan(w1 * 1.8));
    expect(find.textContaining('Next lot turns long-term'), findsNothing); // already LT
    expect(find.textContaining('Long-term units: 1'), findsOneWidget);
    expect(await q(t, () => storage.read(key: 'layout_p1')), contains('"i$id":2'));
    // Summary shrinks to small on long-press (3 -> 1).
    final s1 = t.getSize(find.byKey(const ValueKey('tile-summary'))).width;
    await t.longPress(find.text('Invested (cost)'));
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const ValueKey('tile-summary'))).width, lessThan(s1 / 1.8));
    expect(find.textContaining('LTCG exemption left'), findsNothing);
    await close(t);
  });

  testWidgets('first run shows disclaimer, then profile creation', (t) async {
    await t.pumpWidget(const App());
    await t.pumpAndSettle();
    expect(find.textContaining('Not investment, tax or legal advice'), findsOneWidget);
    await t.tap(find.text('I understand'));
    await t.pumpAndSettle();
    expect(find.textContaining('No profiles yet'), findsOneWidget);
    await t.tap(find.text('Profile'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Ravi');
    await t.tap(find.text('Create'));
    await t.pumpAndSettle();
    expect(find.text('Ravi'), findsOneWidget);
    final ps = await q(t, loadProfiles);
    expect(ps.single.name, 'Ravi');
    expect(await q(t, () => storage.read(key: 'key_${ps.single.id}')), matches(RegExp(r'^[0-9a-f]{64}$')));
    await close(t);
  });
}
