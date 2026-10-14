import 'dart:math';

import 'lots.dart';

/// Growth and pain of one fund from its own NAV history (direct growth plan).
class FundMetrics {
  final String code;
  final String name;
  final String category;
  final double? cagr1, cagr3, cagr5; // a year, e.g. 0.152 = 15.2%
  final double maxDrawdown; // worst peak-to-trough fall in the window, 0.31 = 31%
  final String asOf; // YYYY-MM-DD of the latest NAV
  const FundMetrics(this.code, this.name, this.category, this.cagr1, this.cagr3, this.cagr5, this.maxDrawdown, this.asOf);

  Map<String, Object?> toJson() =>
      {'name': name, 'category': category, 'cagr1': cagr1, 'cagr3': cagr3, 'cagr5': cagr5, 'dd': maxDrawdown, 'asOf': asOf};

  static FundMetrics fromJson(String code, Map j) => FundMetrics(code, j['name'] as String, j['category'] as String,
      (j['cagr1'] as num?)?.toDouble(), (j['cagr3'] as num?)?.toDouble(), (j['cagr5'] as num?)?.toDouble(),
      (j['dd'] as num).toDouble(), j['asOf'] as String);
}

/// [navs] oldest first as (YYYY-MM-DD, navE4). Null when there is too little history.
FundMetrics? fundMetrics(String code, String name, String category, List<(String, int)> navs) {
  if (navs.length < 30) return null;
  final last = navs.last;
  final lastDay = parseDay(last.$1);
  double? cagr(int years) {
    final target = DateTime.utc(lastDay.year - years, lastDay.month, lastDay.day);
    // History must reach back to (about) the target date.
    if (parseDay(navs.first.$1).isAfter(target.add(const Duration(days: 10)))) return null;
    final then = navs.lastWhere((n) => !parseDay(n.$1).isAfter(target), orElse: () => navs.first);
    return pow(last.$2 / then.$2, 1 / years) - 1.0;
  }

  var peak = 0, dd = 0.0;
  for (final (_, v) in navs) {
    peak = max(peak, v);
    dd = max(dd, 1 - v / peak);
  }
  return FundMetrics(code, name, category, cagr(1), cagr(3), cagr(5), dd, last.$1);
}

class FundIdea {
  final FundMetrics m;
  final double score; // 0..1 within its category
  final List<String> reasons;
  const FundIdea(this.m, this.score, this.reasons);
}

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

String _p(double x) => '${(x * 100).toStringAsFixed(1)}%';

/// Ranks funds within each category: 3-year growth 40%, 5-year growth 30%,
/// smaller worst fall 30%. Funds younger than 3 years are left out.
Map<String, List<FundIdea>> rankFunds(List<FundMetrics> all, {int perCategory = 3}) {
  final by = <String, List<FundMetrics>>{};
  for (final f in all) {
    if (f.cagr3 != null) (by[f.category] ??= []).add(f);
  }
  final out = <String, List<FundIdea>>{};
  for (final e in by.entries) {
    final fs = e.value;
    final p3 = _pct([for (final f in fs) f.cagr3!]);
    final p5 = _pct([for (final f in fs) f.cagr5 ?? f.cagr3!]);
    final pd = _pct([for (final f in fs) -f.maxDrawdown]);
    final dds = [for (final f in fs) f.maxDrawdown]..sort();
    final medianDd = dds[dds.length ~/ 2];
    final ideas = [
      for (var i = 0; i < fs.length; i++)
        FundIdea(fs[i], 0.4 * p3[i] + 0.3 * p5[i] + 0.3 * pd[i], [
          '3 yr ${_p(fs[i].cagr3!)} a year${fs[i].cagr5 == null ? '' : ' · 5 yr ${_p(fs[i].cagr5!)} a year'}',
          'Worst fall ${_p(fs[i].maxDrawdown)} (category typical ${_p(medianDd)})',
          if (fs[i].cagr1 != null) 'Last 12 months ${fs[i].cagr1! >= 0 ? '+' : ''}${_p(fs[i].cagr1!)}',
        ]),
    ]..sort((a, b) => b.score.compareTo(a.score));
    out[e.key] = ideas.take(perCategory).toList();
  }
  return out;
}
