// Renders real screens with DEMO data to PNGs (FLAG_SECURE blocks device
// screenshots). Run: flutter test test/screenshots_test.dart --dart-define=SHOTS=<out dir>
import 'dart:io';
import 'dart:math' as math;
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
import 'package:signal_investor/ui/holding.dart';
import 'package:signal_investor/ui/lab.dart';
import 'package:signal_investor/ui/logo.dart';
import 'package:signal_investor/ui/sandbox.dart';
import 'package:signal_investor/ui/sell_flow.dart';
import 'package:signal_investor/ui/settings.dart';
import 'package:signal_investor/ui/shell.dart';
import 'package:signal_investor/ui/theme.dart';
import 'package:signal_investor/ui/widgets.dart';
import 'package:signal_investor/ui/wrapped.dart';

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

/// Demo random walk of daily closes ending today (weekdays only).
List<(String, int)> walk(double end, int days, double vol, int seed, {double? lastDayMove}) {
  final r = math.Random(seed);
  final today = istToday();
  final out = <(String, int)>[];
  var v = end;
  for (var i = 0; i < days; i++) {
    final d = today.subtract(Duration(days: i));
    if (d.weekday >= 6) continue;
    out.add((fmtDay(d), (v * 10000).round()));
    final move = i == 0 && lastDayMove != null ? lastDayMove : (r.nextDouble() - 0.47) * vol;
    v = v / (1 + move);
  }
  return out.reversed.toList();
}

Future<void> seed(ProfileDb db, MarketDb m) async {
  Future<int> inst(String kind, String name, {String? sym, String? code, String? ticker, String aliases = ''}) =>
      m.into(m.instruments).insert(InstrumentsCompanion.insert(
          kind: kind, name: name, nseSymbol: Value(sym), schemeCode: Value(code),
          yahooTicker: Value(ticker ?? (sym == null ? null : '$sym.NS')), aliases: Value(aliases)));
  final bench = await inst('mf', 'Nifty 50 index fund (benchmark)', code: '120716', aliases: 'benchmark');
  final idx = await inst('index', 'NIFTY 50', ticker: '^NSEI', aliases: 'index');
  final nifty = await inst('mf', 'UTI Nifty 50 Index Fund - Direct Growth', code: '120716b');
  final next50 = await inst('mf', 'ICICI Pru Nifty Next 50 Index - Direct', code: '120684');
  final tcs = await inst('stock', 'Tata Consultancy Services', sym: 'TCS');
  final hdfc = await inst('stock', 'HDFC Bank', sym: 'HDFCBANK');
  final titan = await inst('stock', 'Titan Company', sym: 'TITAN');
  await m.putPrices(bench, 'mfapi', walk(160, 1200, 0.018, 1));
  await m.putPrices(nifty, 'mfapi', walk(160, 1200, 0.018, 1));
  await m.putPrices(next50, 'mfapi', walk(72, 1200, 0.022, 2));
  await m.putPrices(idx, 'yahoo', walk(25100, 2600, 0.018, 3, lastDayMove: -0.021));
  await m.putPrices(tcs, 'yahoo', walk(3350, 1000, 0.024, 4));
  await m.putPrices(hdfc, 'yahoo', walk(1925, 1000, 0.02, 5));
  await m.putPrices(titan, 'yahoo', walk(3720, 1000, 0.026, 6));
  final t0 = walk(3350, 1, 0, 4).last;
  await m.putPrices(tcs, 'nse', [(t0.$1, t0.$2 + 2000)]); // cross-check within 0.5%

  final goal = await db.saveGoal(GoalsCompanion.insert(
      name: "Master's abroad", targetDate: '2028-08-01', targetPaise: 150000000,
      unitName: const Value('months abroad'), unitPaise: const Value(12000000)));
  await db.saveGoal(GoalsCompanion.insert(name: 'House down payment', targetDate: '2034-03-31', targetPaise: 500000000));
  final today = istToday();
  for (var i = 18; i >= 1; i--) {
    final d = addMonths(DateTime.utc(today.year, today.month, 6), -i);
    if (i == 2) continue; // one missed instalment
    final nav = (walk(160, 1200, 0.018, 1).lastWhere((x) => x.$1.compareTo(fmtDay(d)) <= 0, orElse: () => ('', 1450000))).$2;
    await db.addTx(TransactionsCompanion.insert(
        instrumentId: nifty, date: fmtDay(d), type: 'sip', unitsE4: 5000 * 100000000 ~/ nav, priceE4: nav, goalId: Value(goal)));
    if (i <= 12) {
      await db.addTx(TransactionsCompanion.insert(
          instrumentId: next50, date: fmtDay(d), type: 'sip', unitsE4: 3000 * 100000000 ~/ 680000, priceE4: 680000));
    }
  }
  await db.addTx(TransactionsCompanion.insert(instrumentId: tcs, date: fmtDay(today.subtract(const Duration(days: 371))), type: 'buy', unitsE4: 80000, priceE4: 30100000, feesPaise: const Value(3100)));
  await db.addTx(TransactionsCompanion.insert(instrumentId: tcs, date: fmtDay(today.subtract(const Duration(days: 120))), type: 'buy', unitsE4: 40000, priceE4: 32500000));
  await db.addTx(TransactionsCompanion.insert(instrumentId: tcs, date: '2026-06-15', type: 'dividend', unitsE4: 0, priceE4: 3960000));
  await db.addTx(TransactionsCompanion.insert(instrumentId: hdfc, date: '2025-12-01', type: 'buy', unitsE4: 250000, priceE4: 17200000, feesPaise: const Value(4300)));
  await db.addTx(TransactionsCompanion.insert(instrumentId: titan, date: '2025-08-20', type: 'buy', unitsE4: 100000, priceE4: 33500000));
  await db.addTx(TransactionsCompanion.insert(instrumentId: titan, date: '2026-07-20', type: 'sell', unitsE4: 40000, priceE4: 36800000, feesPaise: const Value(2000)));
  await db.setBucket(tcs, 'satellite');
  await db.setBucket(titan, 'satellite');
  await db.saveThesis(ThesesCompanion.insert(
      instrumentId: Value(tcs),
      whyBought: 'Cash-rich IT leader, steady dividends, fair valuation versus its 5-year history.',
      breaksIf: 'two weak quarters, auditor change, large deal losses',
      reviewDate: const Value('2027-02-10')));
  await db.saveSip(SipPlansCompanion.insert(instrumentId: nifty, amountPaise: 500000, dayOfMonth: 6, start: fmtDay(addMonths(DateTime.utc(today.year, today.month, 6), -18))));
  await db.saveSip(SipPlansCompanion.insert(instrumentId: next50, amountPaise: 300000, dayOfMonth: 6, start: fmtDay(addMonths(DateTime.utc(today.year, today.month, 6), -12))));
  await db.setSetting('last_open_day', fmtDay(today.subtract(const Duration(days: 10))));
  for (final (i, d) in [40, 25, 5].indexed) {
    await db.addPaperTrade(PaperTradesCompanion.insert(
        instrumentId: [hdfc, next50, tcs][i], date: fmtDay(today.subtract(Duration(days: d * 7))), type: 'buy',
        unitsE4: [500000, 2000000, 300000][i], priceE4: [16800000, 650000, 31000000][i], reason: const Value('Practice')));
  }
}

void main() {
  final key = GlobalKey();
  late ProfileDb db;
  late MarketDb market;
  late Session session;

  setUpAll(loadFonts);
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'disclaimer_ok': '1', 'tour_done': '1', 'notif_asked': '1'});
    db = ProfileDb(NativeDatabase.memory());
    market = MarketDb(NativeDatabase.memory());
    session = Session(const Profile('a1b2c3', 'Profile 1'), db, market, ValueNotifier<Portfolio?>(null), () {});
  });

  Future<void> settle(WidgetTester t, [int n = 30]) async {
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> shot(WidgetTester t, String name, {int n = 30}) async {
    await settle(t, n);
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
    await settle(t, 60);
    await seeded;

    await t.pumpWidget(app(LockScreen(onUnlock: () async => null), b));
    await shot(t, '01_lock_$tag');

    await t.pumpWidget(app(Shell(session: session, initialTab: 1), b));
    await shot(t, '02_home_$tag', n: 60);
    await t.drag(find.byType(CustomScrollView).first, const Offset(0, -1100));
    await shot(t, '03_home_scrolled_$tag');
    await t.drag(find.byType(CustomScrollView).first, const Offset(0, -1100));
    await shot(t, '04_home_more_$tag');

    await t.tap(find.text('Holdings').last);
    await shot(t, '05_holdings_$tag');
    await t.tap(find.text('Plan').last);
    await shot(t, '06_plan_$tag');
    await t.tap(find.text('Lab').last);
    await shot(t, '07_lab_$tag');

    final p = session.portfolio.value!;
    final tcs = p.instruments.values.firstWhere((i) => i.nseSymbol == 'TCS').id;
    await t.pumpWidget(app(HoldingScreen(session: session, instrumentId: tcs), b));
    await shot(t, '08_holding_$tag');
    await t.drag(find.byType(ListView).first, const Offset(0, -900));
    await shot(t, '09_holding_orchard_$tag');

    await t.pumpWidget(app(SellFlow(session: session, instrumentId: tcs), b));
    await settle(t);
    await t.enterText(find.byType(TextField), 'Want to fund a trip');
    await shot(t, '10_sell_letter_$tag');
    await t.tap(find.text('Continue'));
    await settle(t);
    await t.drag(find.byType(Slider), const Offset(160, 0));
    await shot(t, '11_sell_slider_$tag');
    await t.tap(find.text('Continue'));
    await shot(t, '12_sell_hold_$tag');

    await t.pumpWidget(app(SandboxScreen(session: session), b));
    await shot(t, '13_sandbox_$tag');
    await t.pumpWidget(app(TimeMachineScreen(session: session), b));
    await shot(t, '14_time_machine_$tag');
    await t.pumpWidget(app(WrappedScreen(p: p, fy: p.fy - 1), b));
    await shot(t, '15_wrapped_$tag');
    await t.pumpWidget(app(SettingsScreen(session: session), b));
    await shot(t, '16_settings_$tag');

    await t.pumpWidget(const SizedBox());
    await t.runAsync(() async {
      await db.close();
      await market.close();
    });
  }

  Future<void> withShadows(WidgetTester t, Future<void> Function() f) async {
    debugDisableShadows = false;
    try {
      await f();
    } finally {
      debugDisableShadows = true;
    }
  }

  testWidgets('screens dark', (t) => withShadows(t, () => run(t, Brightness.dark)), skip: out.isEmpty);
  testWidgets('screens light', (t) => withShadows(t, () => run(t, Brightness.light)), skip: out.isEmpty);

  // Launcher icons from the same painter as the in-app logo.
  testWidgets('launcher icons', (t) async {
    for (final (dir, px) in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]) {
      t.view.physicalSize = Size(px.toDouble(), px.toDouble());
      t.view.devicePixelRatio = 1;
      await t.pumpWidget(RepaintBoundary(key: key, child: const Directionality(textDirection: TextDirection.ltr, child: SignalLogo())));
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('android/app/src/main/res/mipmap-$dir/ic_launcher.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
    t.view.reset();
  }, skip: const String.fromEnvironment('ICONS').isEmpty);
}
