import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/db/open_db.dart';
import 'package:signal_investor/engine/lots.dart';
import 'package:signal_investor/engine/money.dart';
import 'package:signal_investor/engine/portfolio.dart';
import 'package:signal_investor/engine/tax.dart';
import 'package:sqlite3/sqlite3.dart' as s3;

DateTime d(String s) => parseDay(s);

Transaction tx(int id, int inst, String date, String type, int units4, int price4,
        {int fees = 0, int? goal}) =>
    Transaction(
        id: id,
        instrumentId: inst,
        date: date,
        type: type,
        unitsE4: units4,
        priceE4: price4,
        feesPaise: fees,
        goalId: goal,
        note: '',
        sttPaise: 0);

SipPlan plan(String start, int day, {String? end, bool active = true}) =>
    SipPlan(id: 1, instrumentId: 1, amountPaise: 500000, dayOfMonth: day, start: start, end: end, active: active);

void main() {
  group('corporate actions', () {
    test('1:5 split multiplies units, keeps cost and buy date', () {
      final l = fifo([
        Tx(1, d('2024-01-10'), TxType.buy, 100000, 10000000), // 10 @ 1000
        Tx(2, d('2025-03-01'), TxType.split, 50000, 0),
        Tx(3, d('2025-03-01'), TxType.sell, 200000, 2500000), // 20 @ 250 same day
      ]);
      expect(l.oversold, isEmpty);
      expect(l.open.single.units4, 300000);
      expect(l.open.single.buyDate, d('2024-01-10'));
      expect(l.open.single.costPaise, 600000);
      expect(l.realized.single.longTerm, isTrue);
      expect(l.realized.single.costPaise, 400000);
    });

    test('1:1 bonus adds a zero-cost lot dated on allotment', () {
      final l = fifo([
        Tx(1, d('2024-01-10'), TxType.buy, 100000, 10000000),
        Tx(2, d('2025-06-01'), TxType.bonus, 10000, 0),
      ]);
      expect(l.units4, 200000);
      expect(l.costPaise, 1000000);
      expect(l.open.last.costPaise, 0);
      expect(l.open.last.buyDate, d('2025-06-01'));
      expect(l.open.last.longTermDate, d('2026-06-02'));
    });

    test('bonus sold short-term is fully taxable gain', () {
      final l = fifo([
        Tx(1, d('2024-01-10'), TxType.buy, 100000, 10000000),
        Tx(2, d('2025-06-01'), TxType.bonus, 10000, 0),
        Tx(3, d('2025-07-01'), TxType.sell, 200000, 6000000),
      ]);
      expect(l.realized.map((r) => r.longTerm), [true, false]);
      expect(l.realized.last.gainPaise, 600000);
    });
  });

  group('SIP status', () {
    test('missed instalments, matching window, next due', () {
      final s = sipStatus(
          plan('2026-06-01', 5),
          [d('2026-06-05'), d('2026-07-09'), d('2026-09-02')], // Aug missing, Sep early
          d('2026-10-20'));
      expect(s.recorded, 4 - 1);
      expect(s.missed, [d('2026-08-05'), d('2026-10-05')]);
      expect(s.nextDue, d('2026-11-05'));
    });

    test('grace of 7 days before flagging; day 31 clamps to month end', () {
      // Day 31 in April -> Thu 30 Apr.
      expect(sipStatus(plan('2026-04-01', 31), [], d('2026-05-06')).missed, isEmpty);
      expect(sipStatus(plan('2026-04-01', 31), [], d('2026-05-08')).missed, [d('2026-04-30')]);
      // Feb -> Sat 28 Feb -> next business day Mon 2 Mar.
      expect(sipStatus(plan('2026-02-01', 31), [], d('2026-03-08')).missed, isEmpty);
      expect(sipStatus(plan('2026-02-01', 31), [], d('2026-03-10')).missed, [d('2026-03-02')]);
    });

    test('paused plans never report missed; end date respected', () {
      expect(sipStatus(plan('2026-01-01', 5, active: false), [], d('2026-10-01')).missed, isEmpty);
      final s = sipStatus(plan('2026-01-01', 5, end: '2026-02-28'), [], d('2026-10-01'));
      expect(s.missed, [d('2026-01-05'), d('2026-02-05')]);
      expect(s.nextDue, isNull);
    });
  });

  group('portfolio', () {
    final inst = [
      const Instrument(id: 1, kind: 'mf', name: 'Index', aliases: ''),
      const Instrument(id: 2, kind: 'stock', name: 'Pick', aliases: ''),
    ];

    test('totals, buckets, goal tagging, upcoming long-term, net invested', () {
      final p = Portfolio.compute(
        today: d('2026-10-12'),
        instruments: inst,
        prefs: [const HoldingPref(instrumentId: 2, bucket: 'satellite')],
        goals: [
          const Goal(id: 7, name: 'Masters', targetDate: '2028-08-01', targetPaise: 50000000),
          const Goal(id: 8, name: 'Retire', targetDate: '2050-01-01', targetPaise: 100000000),
        ],
        txs: [
          tx(1, 1, '2025-11-01', 'sip', 100000, 1000000, goal: 7), // 10 @ 100
          tx(2, 2, '2026-01-15', 'buy', 50000, 20000000, fees: 2000), // 5 @ 2000 + 20
          tx(3, 2, '2026-02-01', 'sell', 10000, 21000000), // 1 @ 2100
        ],
      );
      expect(p.holdings.map((h) => h.name), ['Pick', 'Index']);
      expect(p.investedPaise, 801600 + 100000);
      expect(p.satellitePaise, 801600); // 4 x Rs 2,004 (charges spread)
      expect(p.mfPaise, 100000);
      expect(p.goals.first.goal.name, 'Masters');
      expect(p.goals.first.taggedPaise, 100000);
      expect(p.goals.first.equityTooClose, isTrue);
      expect(p.goals.last.equityTooClose, isFalse);
      expect(p.upcomingLongTerm.map((u) => u.$2.longTermDate), [d('2026-11-02')]);
      expect(p.netInvested.first, (d('2025-11-01'), 100000));
      expect(p.netInvested.last.$2, 100000 + 1002000 - 210000);
      expect(p.netInvested.length, 12);
      expect(p.fyGains.st, 0); // sale was in FY 2025-26
      expect(p.realized.single.gainPaise, 210000 - 200400);
    });

    test('empty profile', () {
      final p = Portfolio.compute(txs: const [], instruments: const [], today: d('2026-10-12'));
      expect(p.holdings, isEmpty);
      expect(p.netInvested, isEmpty);
      expect(p.fyTax.exemptionLeftPaise, ltcgExemptionPaise);
      expect(rupees(p.investedPaise), '₹0.00');
    });
  });

  test('profile db migrates v1 -> v3 keeping data', () async {
    final dir = Directory.systemTemp.createTempSync('sigmig');
    addTearDown(() => dir.deleteSync(recursive: true));
    final f = File('${dir.path}/p.db');
    final key = newHexKey();
    var db = ProfileDb(openEncrypted(f, key));
    await db.addTx(TransactionsCompanion.insert(
        instrumentId: 1, date: '2025-01-01', type: 'buy', unitsE4: 1, priceE4: 1));
    await db.close();
    // Turn it into a v1 file: drop v2 tables, reset user_version.
    final raw = s3.sqlite3.open(f.path)
      ..execute("PRAGMA key = '$key';")
      // Rebuild the v1 shape: drop every table/column added after v1.
      ..execute('DROP TABLE holding_prefs; DROP TABLE profile_settings; DROP TABLE paper_trades; '
          'ALTER TABLE transactions DROP COLUMN stt_paise; ALTER TABLE theses DROP COLUMN broken; '
          'ALTER TABLE signals DROP COLUMN acted_at; ALTER TABLE signals DROP COLUMN note; '
          'ALTER TABLE goals DROP COLUMN unit_name; ALTER TABLE goals DROP COLUMN unit_paise; '
          'PRAGMA user_version = 1;');
    raw.close();
    db = ProfileDb(openEncrypted(f, key));
    expect(await db.select(db.transactions).get(), hasLength(1));
    await db.setBucket(1, 'satellite');
    await db.setSetting('satellite_target_pct', '25');
    expect(await db.setting('satellite_target_pct'), '25');
    expect((await db.select(db.holdingPrefs).getSingle()).bucket, 'satellite');
    await db.saveGoal(GoalsCompanion.insert(name: 'G', targetDate: '2030-01-01', targetPaise: 1));
    final g = await db.select(db.goals).getSingle();
    await db.addTx(TransactionsCompanion.insert(
        instrumentId: 1, date: '2025-01-02', type: 'buy', unitsE4: 1, priceE4: 1, goalId: Value(g.id)));
    await db.deleteGoal(g.id);
    // v3 columns and tables usable after migration.
    expect((await db.select(db.transactions).get()).first.sttPaise, 0);
    await db.addPaperTrade(PaperTradesCompanion.insert(instrumentId: 1, date: '2026-01-01', type: 'buy', unitsE4: 1, priceE4: 1));
    await db.saveThesis(ThesesCompanion.insert(instrumentId: const Value(1), whyBought: 'x', breaksIf: ''));
    await db.setThesisBroken(1, true);
    expect((await db.select(db.theses).getSingle()).broken, isTrue);
    expect((await db.select(db.transactions).get()).every((t) => t.goalId == null), isTrue);
    await db.close();
  });
}
