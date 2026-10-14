// Renders real screens with demo data to PNGs (FLAG_SECURE blocks device
// screenshots). Run: flutter test test/screenshots_test.dart --dart-define=SHOTS=<out dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/db/open_db.dart';
import 'package:signal_investor/engine/lots.dart';
import 'package:signal_investor/engine/portfolio.dart';
import 'package:signal_investor/main.dart';
import 'package:signal_investor/ui/add_transaction.dart';
import 'package:signal_investor/ui/holding.dart';
import 'package:signal_investor/ui/settings.dart';
import 'package:signal_investor/ui/shell.dart';
import 'package:signal_investor/ui/theme.dart';
import 'package:signal_investor/ui/widgets.dart';

const out = String.fromEnvironment('SHOTS');

Future<void> loadFonts() async {
  final dir = '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter_stable'}/bin/cache/artifacts/material_fonts';
  Future<ByteData> f(String n) async => ByteData.sublistView(await File('$dir/$n').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'light', 'black']) {
    roboto.addFont(f('roboto-$w.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(f('materialicons-regular.otf'))).load();
}

Future<void> seed(ProfileDb db, MarketDb m) async {
  Future<int> inst(String kind, String name, {String? sym, String? code}) => m.into(m.instruments).insert(
      InstrumentsCompanion.insert(kind: kind, name: name, nseSymbol: Value(sym), schemeCode: Value(code)));
  final nifty = await inst('mf', 'UTI Nifty 50 Index Fund - Direct Growth', code: '120716');
  final next50 = await inst('mf', 'ICICI Pru Nifty Next 50 Index - Direct', code: '120684');
  final tcs = await inst('stock', 'Tata Consultancy Services', sym: 'TCS');
  final hdfc = await inst('stock', 'HDFC Bank', sym: 'HDFCBANK');
  final titan = await inst('stock', 'Titan Company', sym: 'TITAN');
  final goal = await db.saveGoal(GoalsCompanion.insert(name: "Master's abroad", targetDate: '2028-08-01', targetPaise: 150000000));
  await db.saveGoal(GoalsCompanion.insert(name: 'House down payment', targetDate: '2034-03-31', targetPaise: 500000000));
  final today = istToday();
  var nav = 1450000; // NAV x1e4
  for (var i = 18; i >= 1; i--) {
    final d = addMonths(DateTime.utc(today.year, today.month, 5), -i);
    if (i == 2) continue; // one missed instalment
    nav = nav * 101 ~/ 100;
    await db.addTx(TransactionsCompanion.insert(
        instrumentId: nifty, date: fmtDay(d), type: 'sip', unitsE4: 5000 * 100000000 ~/ nav, priceE4: nav, goalId: Value(goal)));
    if (i <= 12) {
      await db.addTx(TransactionsCompanion.insert(
          instrumentId: next50, date: fmtDay(d), type: 'sip', unitsE4: 3000 * 100000000 ~/ (nav * 4), priceE4: nav * 4));
    }
  }
  await db.addTx(TransactionsCompanion.insert(instrumentId: tcs, date: '2025-02-10', type: 'buy', unitsE4: 120000, priceE4: 41000000, feesPaise: Value(4100)));
  await db.addTx(TransactionsCompanion.insert(instrumentId: tcs, date: '2026-06-15', type: 'dividend', unitsE4: 0, priceE4: 3960000));
  await db.addTx(TransactionsCompanion.insert(instrumentId: hdfc, date: '2025-12-01', type: 'buy', unitsE4: 250000, priceE4: 17200000, feesPaise: Value(4300)));
  await db.addTx(TransactionsCompanion.insert(instrumentId: titan, date: '2025-08-20', type: 'buy', unitsE4: 100000, priceE4: 33500000));
  await db.addTx(TransactionsCompanion.insert(instrumentId: titan, date: '2026-07-20', type: 'sell', unitsE4: 40000, priceE4: 36800000, feesPaise: Value(2000)));
  await db.setBucket(tcs, 'satellite');
  await db.setBucket(titan, 'satellite');
  await db.saveThesis(ThesesCompanion.insert(
      instrumentId: Value(tcs),
      whyBought: 'Cash-rich IT leader, steady dividends, fair valuation versus its 5-year history.',
      breaksIf: 'two weak quarters, auditor change, large deal losses',
      reviewDate: const Value('2027-02-10')));
  await db.saveSip(SipPlansCompanion.insert(instrumentId: nifty, amountPaise: 500000, dayOfMonth: 5, start: fmtDay(addMonths(DateTime.utc(today.year, today.month, 5), -18))));
  await db.saveSip(SipPlansCompanion.insert(instrumentId: next50, amountPaise: 300000, dayOfMonth: 5, start: fmtDay(addMonths(DateTime.utc(today.year, today.month, 5), -12))));
}

void main() {
  final key = GlobalKey();
  late ProfileDb db;
  late MarketDb market;
  late Session session;

  setUpAll(loadFonts);
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'disclaimer_ok': '1'});
    db = ProfileDb(NativeDatabase.memory());
    market = MarketDb(NativeDatabase.memory());
    session = Session(const Profile('a1b2c3', 'Profile 1'), db, market, ValueNotifier<Portfolio?>(null), () {});
  });

  Future<void> settle(WidgetTester t, [int n = 30]) async {
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await settle(t);
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2.625);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$out/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Widget app(Widget home, Brightness b) => RepaintBoundary(
        key: key,
        child: MaterialApp(key: UniqueKey(), debugShowCheckedModeBanner: false, theme: buildTheme(b), home: home),
      );

  Future<void> run(WidgetTester t, Brightness b) async {
    final tag = b == Brightness.dark ? 'dark' : 'light';
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    final seeded = seed(db, market);
    await settle(t, 40);
    await seeded;

    await t.runAsync(() async {
      await createProfile();
      await createProfile();
      await createProfile();
    });
    await t.pumpWidget(app(ProfilePicker(onUnlock: (_) async => null), b));
    await shot(t, '01_profiles_$tag');

    await t.pumpWidget(app(Shell(session: session), b));
    await shot(t, '02_home_$tag');
    await t.drag(find.byType(CustomScrollView).first, const Offset(0, -900));
    await shot(t, '03_home_scrolled_$tag');

    await t.tap(find.text('Holdings').last);
    await shot(t, '04_holdings_$tag');
    await t.tap(find.text('Activity').last);
    await shot(t, '05_activity_$tag');
    await t.tap(find.text('Plan').last);
    await shot(t, '06_plan_$tag');

    final p = session.portfolio.value!;
    final tcs = p.instruments.values.firstWhere((i) => i.nseSymbol == 'TCS').id;
    await t.pumpWidget(app(HoldingScreen(session: session, instrumentId: tcs), b));
    await shot(t, '07_holding_$tag');
    await t.tap(find.text('What if I sell?'));
    await shot(t, '08_what_if_$tag');

    final hdfc = p.instruments.values.firstWhere((i) => i.nseSymbol == 'HDFCBANK').id;
    await t.pumpWidget(app(AddTransaction(session: session, instrumentId: hdfc), b));
    await settle(t);
    await t.tap(find.widgetWithText(ChoiceChip, 'Sell'));
    await settle(t, 5);
    await t.enterText(find.widgetWithText(TextFormField, 'Units'), '10');
    await t.enterText(find.widgetWithText(TextFormField, 'Price / NAV per unit'), '1925');
    await shot(t, '09_sell_form_$tag');

    await t.pumpWidget(app(SettingsScreen(session: session), b));
    await shot(t, '10_settings_$tag');

    await t.pumpWidget(const SizedBox());
    await t.runAsync(() async {
      await db.close();
      await market.close();
    });
  }

  // flutter_test draws shadows as solid outlines unless this is off; it must
  // be restored before the test ends.
  Future<void> withShadows(WidgetTester t, Brightness b) async {
    debugDisableShadows = false;
    try {
      await run(t, b);
    } finally {
      debugDisableShadows = true;
    }
  }

  testWidgets('screens light', (t) => withShadows(t, Brightness.light), skip: out.isEmpty);
  testWidgets('screens dark', (t) => withShadows(t, Brightness.dark), skip: out.isEmpty);
}
