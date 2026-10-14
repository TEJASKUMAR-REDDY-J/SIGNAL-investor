import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/engine/scoring.dart';
import 'package:signal_investor/engine/valuation.dart';

/// ~3 years of daily closes growing from [start] by [drift] per day.
List<Bar> series(double start, double drift, {int days = 800}) => [
      for (var i = 0; i < days; i++)
        Bar(DateTime.utc(2023, 8, 1).add(Duration(days: i)), (start * 10000 * (1 + drift * i)).round()),
    ];

ScanInput s(String sym, {double roe = 0.2, double de = 30, num fcf = 1e9, double mcap = 5e11, double pe = 20, List<Bar>? closes}) =>
    ScanInput(sym, sym, 'X', {'roe': roe, 'debtToEquity': de, 'freeCashflow': fcf, 'operatingCashflow': fcf, 'marketCap': mcap, 'pe': pe},
        closes ?? series(100, 0.0005), DateTime.utc(2026, 10, 9));

void main() {
  test('filters: ROE, debt, cash flow, size, history', () {
    expect(filterOut(s('A')), isNull);
    expect(filterOut(s('B', roe: 0.08)), contains('ROE'));
    expect(filterOut(s('C', de: 250)), contains('debt'));
    expect(filterOut(s('D', fcf: -5)), contains('cash flow'));
    expect(filterOut(s('E', mcap: 1e9)), contains('small'));
    expect(filterOut(s('F', closes: series(100, 0.001, days: 100))), contains('history'));
  });

  test('12-1 momentum skips the last month', () {
    final c = series(100, 0.001);
    final m = momentumOf(c)!;
    // close 30 days ago vs close 365 days ago
    final a = c.lastWhere((b) => !b.day.isAfter(c.last.day.subtract(const Duration(days: 365))));
    final b = c.lastWhere((b) => !b.day.isAfter(c.last.day.subtract(const Duration(days: 30))));
    expect(m, closeTo(b.closeE4 / a.closeE4 - 1, 1e-9));
  });

  test('ranking prefers quality + cheap vs own history + momentum; top N with reasons and breaks', () {
    final r = rankUniverse([
      s('BEST', roe: 0.35, de: 5, pe: 15, closes: series(100, 0.0012)),
      s('MID', roe: 0.18, de: 40, pe: 25),
      s('WEAK', roe: 0.13, de: 90, pe: 60, closes: series(100, -0.0002)),
      s('JUNK', roe: 0.05),
    ], n: 2);
    expect(r.map((c) => c.input.symbol), ['BEST', 'MID']);
    expect(r.first.reasons.first, startsWith('ROE 35%'));
    expect(r.first.breaks.any((b) => b.contains('200-day')), isTrue);
    expect(r.first.inputs['dataAsOf'], '2026-10-09T00:00:00.000Z');
    expect(rankUniverse([s('X')], exclude: {'X'}), isEmpty);
  });
}
