import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/engine/habits.dart';
import 'package:signal_investor/engine/lots.dart';
import 'package:signal_investor/engine/portfolio.dart';
import 'package:signal_investor/engine/quick_add.dart';

DateTime d(String s) => parseDay(s);
Transaction tx(int id, int inst, String date, String type, int units4, int price4) => Transaction(
    id: id, instrumentId: inst, date: date, type: type, unitsE4: units4, priceE4: price4,
    feesPaise: 0, note: '', sttPaise: 0);

void main() {
  group('type-to-add', () {
    final today = d('2026-10-14');
    test('sip amount + fund words + today', () {
      final q = parseQuickAdd('sip 5000 ppfas today', today)!;
      expect(q.type, TxType.sip);
      expect(q.amountPaise, 500000);
      expect(q.query, 'ppfas');
      expect(q.date, today);
    });
    test('buy units then price; @ price; yesterday; commas and rupee sign', () {
      final a = parseQuickAdd('buy 10 infy 1520', today)!;
      expect((a.type, a.unitsE4, a.priceE4, a.query), (TxType.buy, 100000, 15200000, 'infy'));
      final b = parseQuickAdd('sell 5 tcs @3,100.50 yesterday', today)!;
      expect((b.type, b.unitsE4, b.priceE4, b.date), (TxType.sell, 50000, 31005000, d('2026-10-13')));
      final c = parseQuickAdd('div ₹250 itc', today)!;
      expect((c.type, c.amountPaise, c.query), (TxType.dividend, 25000, 'itc'));
    });
    test('dates: "12 oct", "5/9", future date rolls back a year', () {
      expect(parseQuickAdd('sip 2000 nifty index 12 oct', today)!.date, d('2026-10-12'));
      expect(parseQuickAdd('sip 2000 nifty 12 oct', today)!.query, 'nifty');
      expect(parseQuickAdd('buy 1 x 10 5/9', today)!.date, d('2026-09-05'));
      expect(parseQuickAdd('sip 100 x 20 dec', today)!.date, d('2025-12-20'));
    });
    test('rejects unknown verbs', () {
      expect(parseQuickAdd('hello 10 infy', today), isNull);
      expect(parseQuickAdd('', today), isNull);
    });
  });

  group('habits', () {
    const fund = Instrument(id: 1, kind: 'mf', name: 'F', aliases: '');
    SipPlan plan(String start) => SipPlan(id: 1, instrumentId: 1, amountPaise: 100000, dayOfMonth: 5, start: start, active: true);

    test('SIP streak counts kept months, forgives one miss per FY', () {
      // Due Apr-Sep 2026 (Oct pending). Jun missed -> forgiven.
      final txs = [
        for (final m in ['2026-04-06', '2026-05-05', '2026-07-06', '2026-08-05', '2026-09-07'])
          tx(m.hashCode & 0xffff, 1, m, 'sip', 10000, 1000000),
      ];
      final p = Portfolio.compute(today: d('2026-10-03'), instruments: [fund], txs: txs, sips: [plan('2026-04-01')]);
      final h = habits(p);
      expect(p.sips.single.missed, [d('2026-06-05')]);
      expect(h.freePassUsed, isTrue);
      expect(h.sipStreakMonths, 5);
    });

    test('months without a short-term sell; longest-held lot', () {
      final txs = [
        tx(1, 1, '2025-01-10', 'buy', 100000, 1000000),
        tx(2, 1, '2025-03-10', 'sell', 10000, 1100000), // short-term
        tx(3, 1, '2025-06-10', 'buy', 10000, 1000000),
      ];
      final p = Portfolio.compute(today: d('2026-10-14'), instruments: [fund], txs: txs);
      final h = habits(p);
      expect(h.monthsWithoutShortTermSell, 19); // Mar 2025 -> Oct 2026
      expect(h.longestHeld!.$2.buyDate, d('2025-01-10'));
    });

    test('FY Wrapped: tax saved by waiting = same gains taxed as short-term minus actual', () {
      final txs = [
        tx(1, 1, '2023-01-10', 'buy', 1000000, 1000000), // 100 @ 100
        tx(2, 1, '2025-06-10', 'sell', 1000000, 3000000), // LT gain Rs 20,000 in FY 2025
      ];
      final w = wrapped(Portfolio.compute(today: d('2026-04-02'), instruments: [fund], txs: txs), 2025);
      expect(w.ltGainPaise, 2000000);
      expect(w.taxPaidPaise, 0); // inside the exemption
      expect(w.exemptionUsedPaise, 2000000);
      expect(w.taxSavedByWaitingPaise, 416000); // 20,000 x 20.8%
    });
  });
}
