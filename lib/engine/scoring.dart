import 'scan_config.dart';
import 'valuation.dart';

/// One NIFTY 500 stock's inputs for the scan.
class ScanInput {
  final String symbol;
  final String name;
  final String industry;
  final Map<String, num?> f; // roe, debtToEquity, freeCashflow, operatingCashflow, pe, marketCap
  final List<Bar> closes; // daily, oldest first (about 3 years)
  final DateTime dataAsOf;
  const ScanInput(this.symbol, this.name, this.industry, this.f, this.closes, this.dataAsOf);
}

class Candidate {
  final ScanInput input;
  final double score; // 0..1
  final double quality, growth, value, momentum; // percentiles 0..1
  final double momentumReturn; // 12-1 month
  final double vs3yAvg; // price vs own 3-year average, -0.1 = 10% below
  final List<String> reasons;
  final List<String> breaks;
  const Candidate(this.input, this.score, this.quality, this.growth, this.value, this.momentum, this.momentumReturn,
      this.vs3yAvg, this.reasons, this.breaks);

  Map<String, Object?> get inputs => {
        'symbol': input.symbol,
        'roe': input.f['roe'],
        'debtToEquity': input.f['debtToEquity'],
        'pe': input.f['pe'],
        'revenueGrowth': input.f['revenueGrowth'],
        'earningsGrowth': input.f['earningsGrowth'],
        'momentum12_1': momentumReturn,
        'vs3yAvg': vs3yAvg,
        'score': score,
        'dataAsOf': input.dataAsOf.toIso8601String(),
      };
}

/// Why a stock failed the filters, or null when it passes.
String? filterOut(ScanInput s) {
  final roe = s.f['roe'], de = s.f['debtToEquity'], fcf = s.f['freeCashflow'], ocf = s.f['operatingCashflow'];
  final mcap = s.f['marketCap'];
  if (roe == null || roe < minRoe) return 'ROE below ${(minRoe * 100).round()}% or missing';
  if (de != null && de > maxDebtToEquityPct) return 'debt above ${maxDebtToEquityPct / 100}x equity';
  // Without cash-flow data (common on Yahoo now), positive earnings stand in.
  final cashOk = fcf == null && ocf == null ? (s.f['eps'] ?? 0) > 0 : ((fcf ?? 0) > 0 || (ocf ?? 0) > 0);
  if (requirePositiveCashFlow && !cashOk) return 'no positive cash flow';
  if (mcap == null || mcap < minMarketCapCr * 1e7) return 'too small or market cap missing';
  if (momentumOf(s.closes) == null) return 'not enough price history';
  return null;
}

/// 12-1 month return from daily closes, null without enough history.
double? momentumOf(List<Bar> c) {
  if (c.length < 200) return null;
  final end = c.last.day.subtract(const Duration(days: momentumSkipDays));
  final start = c.last.day.subtract(const Duration(days: momentumLookbackDays));
  Bar? at(DateTime d) => c.lastWhere((b) => !b.day.isAfter(d), orElse: () => c.first);
  final a = at(start)!, b = at(end)!;
  if (a.day.isAfter(start.add(const Duration(days: 10)))) return null; // history starts too late
  return b.closeE4 / a.closeE4 - 1;
}

double vs3y(List<Bar> c) {
  final avg = c.fold<double>(0, (a, b) => a + b.closeE4) / c.length;
  return c.last.closeE4 / avg - 1;
}

/// Percentile rank (0..1) of each value; higher value -> higher rank.
List<double> _pct(List<double> v) {
  final idx = List.generate(v.length, (i) => i)..sort((a, b) => v[a].compareTo(v[b]));
  final out = List<double>.filled(v.length, 0);
  if (v.length == 1) return [1];
  // Equal values share their average rank, so ties never depend on list order.
  for (var r = 0; r < idx.length;) {
    var e = r;
    while (e + 1 < idx.length && v[idx[e + 1]] == v[idx[r]]) {
      e++;
    }
    for (var k = r; k <= e; k++) {
      out[idx[k]] = (r + e) / 2 / (v.length - 1);
    }
    r = e + 1;
  }
  return out;
}

String _p(double x) => '${(x * 100).toStringAsFixed(0)}%';

/// Percentile ranks where missing values sit in the middle (0.5) instead of the bottom.
List<double> _pctOrMid(List<double?> v) {
  final have = [for (final x in v) ?x];
  final ranks = _pct(have);
  var k = 0;
  return [for (final x in v) x == null ? 0.5 : ranks[k++]];
}

/// Filter, rank by quality + growth + value-vs-own-history + 12-1 momentum, top [n].
List<Candidate> rankUniverse(List<ScanInput> all, {int n = topN, Set<String> exclude = const {}}) {
  final ok = [for (final s in all) if (!exclude.contains(s.symbol) && filterOut(s) == null) s];
  if (ok.isEmpty) return const [];
  final roe = [for (final s in ok) s.f['roe']!.toDouble()];
  final de = [for (final s in ok) -(s.f['debtToEquity']?.toDouble() ?? 0)];
  final cheap = [for (final s in ok) -vs3y(s.closes)];
  final ey = [for (final s in ok) (s.f['pe'] ?? 0) > 0 ? 1 / s.f['pe']!.toDouble() : 0.0];
  final mom = [for (final s in ok) momentumOf(s.closes)!];
  final rev = [for (final s in ok) s.f['revenueGrowth']?.toDouble()];
  final earn = [for (final s in ok) s.f['earningsGrowth']?.toDouble()];
  final pr = _pct(roe), pd = _pct(de), pc = _pct(cheap), pe = _pct(ey), pm = _pct(mom);
  final pg1 = _pctOrMid(rev), pg2 = _pctOrMid(earn);
  final out = <Candidate>[];
  for (var i = 0; i < ok.length; i++) {
    final s = ok[i];
    final q = (pr[i] * 0.7 + pd[i] * 0.3), g = (pg1[i] + pg2[i]) / 2, v = (pc[i] * 0.5 + pe[i] * 0.5), m = pm[i];
    final score = wQuality * q + wGrowth * g + wValue * v + wMomentum * m;
    final r3 = vs3y(s.closes);
    final sma = s.closes.length >= 200
        ? s.closes.sublist(s.closes.length - 200).fold<int>(0, (a, b) => a + b.closeE4) / 200
        : null;
    String signed(num x) => '${x >= 0 ? '+' : ''}${_p(x.toDouble())}';
    out.add(Candidate(s, score, q, g, v, m, mom[i], r3, [
      'ROE ${_p(s.f['roe']!.toDouble())}${s.f['debtToEquity'] == null ? '' : ', debt ${(s.f['debtToEquity']! / 100).toStringAsFixed(2)}x equity'}',
      if (rev[i] != null || earn[i] != null)
        'Growth: sales ${rev[i] == null ? 'n/a' : signed(rev[i]!)}, profit ${earn[i] == null ? 'n/a' : signed(earn[i]!)} year on year',
      '12-1 month momentum ${mom[i] >= 0 ? '+' : ''}${_p(mom[i])}',
      'Price ${r3 <= 0 ? '${_p(-r3)} below' : '${_p(r3)} above'} its own 3-year average'
          '${(s.f['pe'] ?? 0) > 0 ? ', P/E ${s.f['pe']!.toStringAsFixed(1)}' : ''}',
    ], [
      'ROE falls below ${_p(minRoe)}',
      'Debt rises above ${(maxDebtToEquityPct / 100).toStringAsFixed(1)}x equity',
      if (sma != null) 'Price closes below its 200-day average (now ₹${(sma / 10000).toStringAsFixed(0)})',
      'Two weak quarters in a row, an auditor exit or a promoter pledge',
    ]));
  }
  out.sort((a, b) => b.score.compareTo(a.score));
  return out.take(n).toList();
}
