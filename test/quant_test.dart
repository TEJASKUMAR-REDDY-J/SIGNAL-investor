import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/engine/agent_stats.dart';
import 'package:signal_investor/engine/indicators.dart';
import 'package:signal_investor/engine/regime.dart';

void main() {
  group('indicators', () {
    test('RSI matches the StockCharts worked example (70.53)', () {
      const x = [44.34, 44.09, 44.15, 43.61, 44.33, 44.83, 45.10, 45.42, 45.84, 46.08, 45.89, 46.03, 45.61, 46.28, 46.28];
      expect(rsi(x), closeTo(70.5, 0.1)); // published inputs are rounded
      expect(rsi([for (var i = 0; i < 20; i++) 100.0 + i]), 100);
      expect(rsi([for (var i = 0; i < 20; i++) i.isEven ? 100.0 : 101.0]), closeTo(50, 4));
      expect(rsi([1, 2, 3]), isNull);
    });

    test('averages, MACD, Bollinger, volatility, drawdown, ATR', () {
      expect(sma([1, 2, 3, 4], 2), 3.5);
      expect(sma([1, 2], 3), isNull);
      expect(emaSeries([10, 10, 10], 5), [10, 10, 10]);
      final up = [for (var i = 0; i < 60; i++) 100.0 + i];
      final down = up.reversed.toList();
      expect(macd(up)!.$1, greaterThan(0));
      expect(macd(down)!.$1, lessThan(0));
      expect(macd(up.take(20).toList()), isNull);
      expect(bollingerB([for (var i = 0; i < 20; i++) i.isEven ? 99.0 : 101.0]), closeTo(0.75, 0.01));
      expect(volatility([for (var i = 0; i < 30; i++) 100.0]), 0);
      expect(maxDrawdown([100, 120, 60, 90]), 0.5);
      expect(ret([100, 110], 1), closeTo(0.1, 1e-9));
      // Constant range of 2 around flat closes -> ATR 2.
      final c = List<double>.filled(20, 100);
      expect(atr(List.filled(20, 101), List.filled(20, 99), c), closeTo(2, 1e-9));
    });

    test('technicals snapshot: trend label, 52-week position, relative strength, volume', () {
      final closes = [for (var i = 0; i < 260; i++) 100.0 + i * 0.5 + (i.isEven ? 1 : -1)];
      final index = [for (var i = 0; i < 260; i++) 100.0 + i * 0.1];
      final t = Technicals.of(closes, index: index, volumes: [...List.filled(259, 1000.0), 3000.0]);
      expect(t.uptrend, isTrue);
      expect(t.trendLabel, startsWith('uptrend'));
      expect(t.from52wHigh!, lessThanOrEqualTo(0));
      expect(t.relStrength3m!, greaterThan(0));
      expect(t.volumeRatio, closeTo(3, 1e-9));
      expect(t.toJson()['rsi14'], isA<double>());
      expect(Technicals.of([100, 101]).trendLabel, 'not enough history');
    });
  });

  group('regime and risk', () {
    test('risk-on vs risk-off', () {
      final rising = [for (var i = 0; i < 250; i++) 100.0 + i];
      final falling = rising.reversed.toList();
      final on = regimeOf(nifty: rising, vix: 13, breadth: 0.7);
      expect((on.label, on.budgetScale), ('Risk-on', 1.0));
      expect(on.reasons, contains('NIFTY above its 200-day average'));
      final off = regimeOf(nifty: falling, vix: 25, breadth: 0.2);
      expect((off.label, off.budgetScale), ('Risk-off', 0.35));
      expect(regimeOf(nifty: [1, 2, 3], breadth: 0.5).label, 'Neutral');
      expect(on.line, contains('VIX 13.0'));
    });

    test('volatility sizing and the drawdown brake', () {
      expect(volScaled(5000000, 0.5), 2500000); // twice the target vol -> half size
      expect(volScaled(5000000, 0.1), 5000000); // calm -> full size, never more
      expect(volScaled(5000000, 2.0), 2000000); // floor at 40%
      expect(volScaled(5000000, null), 5000000);
      expect(drawdownBrake([100, 95]).$1, 1);
      expect(drawdownBrake([100, 90]).$1, 0.5);
      expect(drawdownBrake([100, 80]).$1, 0);
      expect(drawdownBrake([]).$1, 1);
    });
  });

  test('scorecard: return, Sharpe, drawdown, round trips, wins by signal, alpha', () {
    final s = agentStats(
      startCashPaise: 100000,
      runValues: [('2026-10-01', 101000), ('2026-10-02', 102000), ('2026-10-05', 99000), ('2026-10-06', 103000), ('2026-10-07', 104000), ('2026-10-08', 105000)],
      trades: [
        ('2026-10-01', 'buy', 1, 100000, 1000000, 0, 'good news today: big order'),
        ('2026-10-01', 'buy', 2, 100000, 1000000, 0, '1-month trend +8%'),
        ('2026-10-06', 'sell', 1, 100000, 1100000, 0, 'took profit'),
        ('2026-10-07', 'sell', 2, 100000, 950000, 0, 'stop-loss'),
      ],
      niftyAt: (d) => d.month == 9 ? 100 : 102,
    );
    expect(s.totalReturn, closeTo(0.05, 1e-9));
    expect(s.sharpe, isNotNull);
    expect(s.maxDrawdown, closeTo(1 - 99000 / 102000, 1e-9));
    expect(s.closed, hasLength(2));
    expect(s.winRate, 0.5);
    expect(s.bySignal, {'news': (1, 1), 'momentum': (0, 1)});
    expect(s.closed.first.days, 5);
    expect(s.alpha, closeTo(0.03, 1e-9));
    expect(s.summary, contains('news signals 1/1 wins'));
    expect(signalOf('Advisor score 74, quality 80'), 'quality');
  });
}
