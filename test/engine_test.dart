import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/engine/lots.dart';
import 'package:signal_investor/engine/money.dart';
import 'package:signal_investor/engine/tax.dart';
import 'package:signal_investor/engine/xirr.dart';

DateTime d(String s) => parseDay(s);
int u(num n) => (n * unitScale).round();
int px(num n) => (n * priceScale).round();

void main() {
  group('FIFO', () {
    test('buy 10, buy 10, sell 15 leaves 5 units from second lot', () {
      final l = fifo([
        Tx(1, d('2025-01-01'), TxType.buy, u(10), px(100)),
        Tx(2, d('2025-02-01'), TxType.buy, u(10), px(120)),
        Tx(3, d('2025-03-01'), TxType.sell, u(15), px(130)),
      ]);
      expect(l.open.length, 1);
      expect(l.open.single.units4, u(5));
      expect(l.open.single.buyDate, d('2025-02-01'));
      expect(l.open.single.costPaise, 60000); // 5 x Rs 120
      expect(l.realized.map((r) => r.units4), [u(10), u(5)]);
      expect(l.realized.fold(0, (a, r) => a + r.costPaise), 160000);
      expect(l.realized.fold(0, (a, r) => a + r.proceedsPaise), 195000);
      expect(l.oversold, isEmpty);
    });

    test('fees add to cost and reduce proceeds; oversell flagged', () {
      final l = fifo([
        Tx(1, d('2025-01-01'), TxType.buy, u(3), px(100), 1500),
        Tx(2, d('2025-02-01'), TxType.sell, u(5), px(110), 500),
      ]);
      expect(l.open, isEmpty);
      expect(l.realized.single.costPaise, 31500);
      expect(l.realized.single.proceedsPaise, 32500);
      expect(l.oversold, [2]);
    });

    test('same-day buy is matched before sell regardless of entry order', () {
      final l = fifo([
        Tx(1, d('2025-01-01'), TxType.sell, u(1), px(10)),
        Tx(2, d('2025-01-01'), TxType.buy, u(1), px(10)),
      ]);
      expect(l.oversold, isEmpty);
      expect(l.open, isEmpty);
    });

    test('dividends tracked, not lots', () {
      final l = fifo([
        Tx(1, d('2025-01-01'), TxType.buy, u(1), px(10)),
        Tx(2, d('2025-06-01'), TxType.dividend, 0, px(250.5)),
      ]);
      expect(l.dividendsPaise, 25050);
      expect(l.units4, u(1));
    });
  });

  group('holding period', () {
    test('day 365 is short-term, day 366 is long-term', () {
      final buy = d('2025-01-10');
      expect(isLongTerm(buy, buy.add(const Duration(days: 365))), isFalse);
      expect(isLongTerm(buy, buy.add(const Duration(days: 366))), isTrue);
      expect(longTermFrom(buy), d('2026-01-11'));
    });

    test('addMonths forwards and backwards across years', () {
      expect(addMonths(d('2026-10-05'), -18), d('2025-04-05'));
      expect(addMonths(d('2026-01-31'), -1), d('2025-12-31'));
      expect(addMonths(d('2026-03-31'), -1), d('2026-02-28'));
      expect(addMonths(d('2026-11-30'), 3), d('2027-02-28'));
      expect(addMonths(d('2024-02-29'), 12), d('2025-02-28'));
      expect(addMonths(d('2026-10-05'), -120), d('2016-10-05'));
    });

    test('leap years use calendar months, not 365 days', () {
      // 2023-03-01 + 366 days = 2024-03-01 = exactly 12 months: short-term.
      expect(isLongTerm(d('2023-03-01'), d('2024-03-01')), isFalse);
      expect(isLongTerm(d('2023-03-01'), d('2024-03-02')), isTrue);
      expect(longTermFrom(d('2024-02-29')), d('2025-03-01'));
    });
  });

  group('tax', () {
    test('Rs 1,00,000 at 12% for 10 years, sold once as LTCG', () {
      final buy = d('2016-01-10');
      final sell = d('2026-01-10');
      final l = fifo([Tx(1, buy, TxType.buy, u(1000), px(100))]);
      final price = px(100 * math.pow(1.12, 10));
      final est = estimateSale(
          lots: l.open,
          units4: u(1000),
          price4: price,
          date: sell,
          realizedAll: const []);
      expect(est.slices.single.longTerm, isTrue);
      final net = est.proceedsPaise - est.extraTaxPaise;
      expect((net - 29945900).abs(), lessThanOrEqualTo(100));
    });

    test('same, but realised and taxed as STCG every year', () {
      var cash = 10000000; // paise
      final realized = <Realized>[];
      for (var y = 0; y < 10; y++) {
        final buy = DateTime.utc(2016 + y, 1, 10);
        final sell = DateTime.utc(2017 + y, 1, 10); // anniversary: short-term
        final p0 = px(100 * math.pow(1.12, y));
        final p1 = px(100 * math.pow(1.12, y + 1));
        final lots = [Lot(buy, unitsFor(cash, p0), cash)];
        final est = estimateSale(
            lots: lots,
            units4: lots.single.units4,
            price4: p1,
            date: sell,
            realizedAll: realized);
        expect(est.slices.single.longTerm, isFalse);
        realized.addAll(est.slices);
        cash = est.proceedsPaise - est.extraTaxPaise;
      }
      expect((cash - 24791300).abs(), lessThanOrEqualTo(100));
    });

    test('LTCG exemption resets on 1 April', () {
      Realized lt(String sell, int gain) =>
          Realized(d('2020-01-01'), d(sell), u(1), 0, gain);
      final r = [lt('2026-03-31', 10000000)]; // Rs 1L in FY 2025-26
      expect(fyOf(d('2026-03-31')), 2025);
      expect(fyOf(d('2026-04-01')), 2026);
      expect(fyTax(r, 2025).exemptionUsedPaise, 10000000);
      expect(fyTax(r, 2025).exemptionLeftPaise, 2500000);
      expect(fyTax(r, 2026).exemptionLeftPaise, ltcgExemptionPaise);
      // Rs 1L more on 1 April is fully exempt again.
      final r2 = [...r, lt('2026-04-01', 10000000)];
      expect(fyTax(r2, 2026).taxPaise, 0);
      expect(fyTax(r2, 2026).exemptionUsedPaise, 10000000);
    });

    test('set-off: ST loss offsets LTCG, LT loss never offsets STCG', () {
      // ST loss 50k, LT gain 2L -> LT 1.5L, exempt 1.25L, tax 12.5% of 25k +4%.
      expect(taxFor(stGainPaise: -5000000, ltGainPaise: 20000000).taxPaise,
          325000);
      // LT loss 50k, ST gain 1L -> STCG 1L taxed fully: 20k + 4% = 20,800.
      expect(taxFor(stGainPaise: 10000000, ltGainPaise: -5000000).taxPaise,
          2080000);
    });
  });

  group('wait vs sell now', () {
    test('short-term sale shows extra tax versus waiting for long-term', () {
      final l = fifo([Tx(1, d('2026-03-01'), TxType.buy, u(100), px(1000))]);
      final w = compareWait(
          lots: l.open, units4: u(100), price4: px(1500), date: d('2026-10-12'), realizedAll: const []);
      expect(w.waitUntil, d('2027-03-02'));
      expect(w.now.extraTaxPaise, 1040000); // 50k STCG x 20.8%
      expect(w.later!.extraTaxPaise, 0); // 50k LTCG inside 1.25L exemption
      expect(w.extraTaxPaise, 1040000);
    });
    test('already long-term: nothing to wait for', () {
      final l = fifo([Tx(1, d('2024-03-01'), TxType.buy, u(1), px(10))]);
      final w = compareWait(lots: l.open, units4: u(1), price4: px(20), date: d('2026-10-12'), realizedAll: const []);
      expect(w.waitUntil, isNull);
      expect(w.extraTaxPaise, 0);
    });
  });

  group('xirr vs Excel XIRR', () {
    List<Flow> monthly(DateTime start, int n, int paise) => [
          for (var m = 0; m < n; m++)
            (date: addMonths(start, m), paise: -paise),
        ];
    void near(double? got, double excel) =>
        expect((got! - excel).abs(), lessThan(0.0001));

    test('24 x Rs 5,000 SIP -> Rs 1,40,000', () {
      near(
          xirr([
            ...monthly(d('2023-01-05'), 24, 500000),
            (date: d('2025-01-05'), paise: 14000000),
          ]),
          0.15503920912742616);
    });
    test('36 x Rs 10,000 SIP -> Rs 3,00,000 (loss)', () {
      near(
          xirr([
            ...monthly(d('2021-04-10'), 36, 1000000),
            (date: d('2024-04-10'), paise: 30000000),
          ]),
          -0.11463401336222888);
    });
    test('12 x Rs 2,500 SIP with partial withdrawal', () {
      near(
          xirr([
            ...monthly(d('2024-06-15'), 12, 250000),
            (date: d('2025-01-20'), paise: 500000),
            (date: d('2025-07-01'), paise: 2800000),
          ]),
          0.20004937052726746);
    });
    test('no sign change -> null', () {
      expect(
          xirr([
            (date: d('2024-01-01'), paise: -100),
            (date: d('2025-01-01'), paise: -100),
          ]),
          isNull);
    });
  });

  group('money', () {
    test('1,000 SIP instalments: no floating-point drift', () {
      final txs = [
        for (var i = 0; i < 1000; i++)
          // Rs 1,234.56 at NAV 45.6789 (units rounded to 4 dp like an RTA).
          Tx(i, addMonths(d('1940-01-01'), i), TxType.sip,
              unitsFor(123456, px(45.6789)), px(45.6789)),
      ];
      final l = fifo(txs);
      final perLot = valuePaise(unitsFor(123456, px(45.6789)), px(45.6789));
      expect(l.costPaise, perLot * 1000); // exact integer sum
      expect(l.units4, unitsFor(123456, px(45.6789)) * 1000);
      // Sell everything in 1,000 partial sells: cost fully released, no residue.
      final open = [...l.open];
      var released = 0;
      for (var i = 0; i < 1000; i++) {
        released += sellFifo(open, unitsFor(123456, px(45.6789)), px(50), 0,
                d('2030-01-01'))
            .fold(0, (a, r) => a + r.costPaise);
      }
      expect(open, isEmpty);
      expect(released, l.costPaise);
      var sum = 0;
      for (var i = 0; i < 1000; i++) {
        sum += parseScaled('1234.56', 2)!;
      }
      expect(sum, 123456000);
      expect(rupees(sum), '₹12,34,560.00');
    });

    test('parse/format round trip and rejects junk', () {
      expect(parseScaled('1,234.5678', 4), 12345678);
      expect(parseScaled('0.1', 4), 1000);
      expect(parseScaled('.5', 2), 50);
      expect(parseScaled('1.23456', 4), isNull);
      expect(parseScaled('abc', 2), isNull);
      expect(parseScaled('', 2), isNull);
      expect(formatScaled(12345678, 4), '1234.5678');
      expect(formatScaled(10000, 4, minDecimals: 2), '1.00');
      expect(rupees(-5), '-₹0.05');
      expect(rupees(99999999), '₹9,99,999.99');
    });
  });
}
