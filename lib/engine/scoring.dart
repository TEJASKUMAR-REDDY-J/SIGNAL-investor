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
  final double quality, value, momentum; // percentiles 0..1
  final double momentumReturn; // 12-1 month
  final double vs3yAvg; // price vs own 3-year average, -0.1 = 10% below
  final List<String> reasons;
  final List<String> breaks;
  const Candidate(this.input, this.score, this.quality, this.value, this.momentum, this.momentumReturn, this.vs3yAvg,
      this.reasons, this.breaks);

  Map<String, Object?> get inputs => {
        'symbol': input.symbol,
        'roe': input.f['roe'],
        'debtToEquity': input.f['debtToEquity'],
        'pe': input.f['pe'],
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
  if (requirePositiveCashFlow && !((fcf ?? 0) > 0 || (ocf ?? 0) > 0)) return 'no positive cash flow';
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
  for (var r = 0; r < idx.length; r++) {
    out[idx[r]] = v.length == 1 ? 1 : r / (v.length - 1);
  }
  return out;
}

String _p(double x) => '${(x * 100).toStringAsFixed(0)}%';

/// Filter, rank by quality + value-vs-own-history + 12-1 momentum, top [n].
List<Candidate> rankUniverse(List<ScanInput> all, {int n = topN, Set<String> exclude = const {}}) {
  final ok = [for (final s in all) if (!exclude.contains(s.symbol) && filterOut(s) == null) s];
  if (ok.isEmpty) return const [];
  final roe = [for (final s in ok) s.f['roe']!.toDouble()];
  final de = [for (final s in ok) -(s.f['debtToEquity']?.toDouble() ?? 0)];
  final cheap = [for (final s in ok) -vs3y(s.closes)];
  final ey = [for (final s in ok) (s.f['pe'] ?? 0) > 0 ? 1 / s.f['pe']!.toDouble() : 0.0];
  final mom = [for (final s in ok) momentumOf(s.closes)!];
  final pr = _pct(roe), pd = _pct(de), pc = _pct(cheap), pe = _pct(ey), pm = _pct(mom);
  final out = <Candidate>[];
  for (var i = 0; i < ok.length; i++) {
    final s = ok[i];
    final q = (pr[i] * 0.7 + pd[i] * 0.3), v = (pc[i] * 0.5 + pe[i] * 0.5), m = pm[i];
    final score = wQuality * q + wValue * v + wMomentum * m;
    final r3 = vs3y(s.closes);
    final sma = s.closes.length >= 200
        ? s.closes.sublist(s.closes.length - 200).fold<int>(0, (a, b) => a + b.closeE4) / 200
        : null;
    out.add(Candidate(s, score, q, v, m, mom[i], r3, [
      'ROE ${_p(s.f['roe']!.toDouble())}${s.f['debtToEquity'] == null ? '' : ', debt ${(s.f['debtToEquity']! / 100).toStringAsFixed(2)}x equity'}',
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
