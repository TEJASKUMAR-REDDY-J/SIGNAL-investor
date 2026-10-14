import 'dart:math';

// Classic technical indicators on daily closes (oldest first, any unit).
// Wilder RSI, MACD 12/26/9, Bollinger 20/2, realised volatility, drawdown,
// 52-week position, relative strength. Pure functions, no I/O.

double? sma(List<double> x, int n) {
  if (x.length < n || n <= 0) return null;
  var s = 0.0;
  for (var i = x.length - n; i < x.length; i++) {
    s += x[i];
  }
  return s / n;
}

/// Exponential moving average series (seeded with the first value).
List<double> emaSeries(List<double> x, int n) {
  if (x.isEmpty) return const [];
  final k = 2 / (n + 1);
  final out = <double>[x.first];
  for (var i = 1; i < x.length; i++) {
    out.add(x[i] * k + out.last * (1 - k));
  }
  return out;
}

/// Wilder's RSI over [n] periods; null without n+1 closes.
double? rsi(List<double> x, [int n = 14]) {
  if (x.length <= n) return null;
  var gain = 0.0, loss = 0.0;
  for (var i = 1; i <= n; i++) {
    final d = x[i] - x[i - 1];
    if (d >= 0) {
      gain += d;
    } else {
      loss -= d;
    }
  }
  gain /= n;
  loss /= n;
  for (var i = n + 1; i < x.length; i++) {
    final d = x[i] - x[i - 1];
    gain = (gain * (n - 1) + max(d, 0)) / n;
    loss = (loss * (n - 1) + max(-d, 0)) / n;
  }
  if (loss == 0) return gain == 0 ? 50 : 100;
  return 100 - 100 / (1 + gain / loss);
}

/// MACD line, signal line and histogram (12, 26, 9); null without 35 closes.
(double, double, double)? macd(List<double> x, [int fast = 12, int slow = 26, int signal = 9]) {
  if (x.length < slow + signal) return null;
  final f = emaSeries(x, fast), s = emaSeries(x, slow);
  final line = [for (var i = 0; i < x.length; i++) f[i] - s[i]];
  final sig = emaSeries(line.sublist(slow - 1), signal);
  return (line.last, sig.last, line.last - sig.last);
}

/// Bollinger %B: 0 = lower band, 1 = upper band (20 days, 2 standard deviations).
double? bollingerB(List<double> x, [int n = 20, double k = 2]) {
  if (x.length < n) return null;
  final w = x.sublist(x.length - n);
  final m = w.reduce((a, b) => a + b) / n;
  final sd = sqrt(w.fold(0.0, (a, v) => a + (v - m) * (v - m)) / n);
  if (sd == 0) return 0.5;
  return (x.last - (m - k * sd)) / (2 * k * sd);
}

/// Annualised volatility of daily log returns over the last [n] days.
double? volatility(List<double> x, [int n = 20]) {
  if (x.length <= n) return null;
  final r = [for (var i = x.length - n; i < x.length; i++) log(x[i] / x[i - 1])];
  final m = r.reduce((a, b) => a + b) / r.length;
  final v = r.fold(0.0, (a, e) => a + (e - m) * (e - m)) / (r.length - 1);
  return sqrt(v) * sqrt(252);
}

/// Worst peak-to-trough fall within the series, 0.3 = 30%.
double maxDrawdown(List<double> x) {
  var peak = double.negativeInfinity, dd = 0.0;
  for (final v in x) {
    peak = max(peak, v);
    if (peak > 0) dd = max(dd, 1 - v / peak);
  }
  return dd;
}

/// Return over the last [days] closes; null when too short.
double? ret(List<double> x, int days) => x.length > days && x[x.length - 1 - days] != 0 ? x.last / x[x.length - 1 - days] - 1 : null;

/// Average true range over [n] days from highs, lows and closes (same length).
double? atr(List<double> high, List<double> low, List<double> close, [int n = 14]) {
  if (close.length <= n || high.length != close.length || low.length != close.length) return null;
  final tr = <double>[];
  for (var i = 1; i < close.length; i++) {
    tr.add([high[i] - low[i], (high[i] - close[i - 1]).abs(), (low[i] - close[i - 1]).abs()].reduce(max));
  }
  var a = tr.sublist(0, n).reduce((p, q) => p + q) / n;
  for (var i = n; i < tr.length; i++) {
    a = (a * (n - 1) + tr[i]) / n;
  }
  return a;
}

/// Everything the agents read about one stock's price action.
class Technicals {
  final double price;
  final double? rsi14, macdHist, bollB, vol20, sma50, sma200, ret1, ret5, ret20, ret60, ret250;
  final double? from52wHigh; // -0.1 = 10% below the 52-week high
  final double? relStrength3m; // 3-month return minus the index's
  final double? atrPct; // ATR as a share of price
  final double? volumeRatio; // today's volume / 20-day average
  const Technicals(this.price,
      {this.rsi14,
      this.macdHist,
      this.bollB,
      this.vol20,
      this.sma50,
      this.sma200,
      this.ret1,
      this.ret5,
      this.ret20,
      this.ret60,
      this.ret250,
      this.from52wHigh,
      this.relStrength3m,
      this.atrPct,
      this.volumeRatio});

  bool? get aboveSma50 => sma50 == null ? null : price > sma50!;
  bool? get aboveSma200 => sma200 == null ? null : price > sma200!;
  bool get uptrend => (aboveSma50 ?? false) && (sma200 == null || (sma50 ?? 0) > sma200!);

  /// Plain-words reading for people and the AI.
  String get trendLabel => sma50 == null
      ? 'not enough history'
      : uptrend
          ? 'uptrend (above 50-day and 50 > 200-day)'
          : (aboveSma50! ? 'recovering (above 50-day)' : 'downtrend (below 50-day)');

  static Technicals of(List<double> closes, {List<double>? index, List<double>? highs, List<double>? lows, List<double>? volumes}) {
    final p = closes.isEmpty ? 0.0 : closes.last;
    final last250 = closes.length > 250 ? closes.sublist(closes.length - 250) : closes;
    final hi = last250.isEmpty ? null : last250.reduce(max);
    final r60 = ret(closes, 60);
    final i60 = index == null ? null : ret(index, 60);
    double? volRatio;
    if (volumes != null && volumes.length > 21) {
      final avg = volumes.sublist(volumes.length - 21, volumes.length - 1).reduce((a, b) => a + b) / 20;
      if (avg > 0) volRatio = volumes.last / avg;
    }
    final a = highs == null || lows == null ? null : atr(highs, lows, closes);
    return Technicals(p,
        rsi14: rsi(closes),
        macdHist: macd(closes)?.$3,
        bollB: bollingerB(closes),
        vol20: volatility(closes),
        sma50: sma(closes, 50),
        sma200: sma(closes, 200),
        ret1: ret(closes, 1),
        ret5: ret(closes, 5),
        ret20: ret(closes, 20),
        ret60: r60,
        ret250: ret(closes, min(250, closes.length - 1)),
        from52wHigh: hi == null || hi == 0 ? null : p / hi - 1,
        relStrength3m: r60 == null || i60 == null ? null : r60 - i60,
        atrPct: a == null || p == 0 ? null : a / p,
        volumeRatio: volRatio);
  }

  Map<String, Object?> toJson() {
    double? r(double? x, [int d = 3]) => x == null ? null : double.parse(x.toStringAsFixed(d));
    return {
      'price': r(price, 2),
      'trend': trendLabel,
      'rsi14': r(rsi14, 1),
      'macd_histogram': r(macdHist, 2),
      'bollinger_pctB': r(bollB, 2),
      'volatility_annual': r(vol20),
      'sma50': r(sma50, 2),
      'sma200': r(sma200, 2),
      'return_1d': r(ret1),
      'return_5d': r(ret5),
      'return_1m': r(ret20),
      'return_3m': r(ret60),
      'return_1y': r(ret250),
      'from_52w_high': r(from52wHigh),
      'rel_strength_3m_vs_nifty': r(relStrength3m),
      'atr_pct': r(atrPct),
      'volume_vs_20d': r(volumeRatio, 2),
    };
  }
}
