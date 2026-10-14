import 'lots.dart';
import 'money.dart';
import 'valuation.dart';
import 'xirr.dart';

/// "What if I had..." on real stored history. Educational, not a forecast.
class SimResult {
  final int investedPaise;
  final int valuePaise;
  final double? xirr;
  final List<(DateTime, int, int)> path; // month, value, invested
  final int worstDropBps; // deepest fall from a prior peak along the way
  const SimResult(this.investedPaise, this.valuePaise, this.xirr, this.path, this.worstDropBps);
}

SimResult _run(List<Bar> nav, List<(DateTime, int)> buys) {
  var units = 0, invested = 0, peak = 0, worst = 0;
  final flows = <Flow>[];
  final path = <(DateTime, int, int)>[];
  var bi = 0;
  for (var i = 0; i < nav.length; i++) {
    final b = nav[i];
    while (bi < buys.length && !buys[bi].$1.isAfter(b.day)) {
      units += unitsFor(buys[bi].$2, b.closeE4);
      invested += buys[bi].$2;
      flows.add((date: b.day, paise: -buys[bi].$2));
      bi++;
    }
    final v = valuePaise(units, b.closeE4);
    if (v > peak) peak = v;
    if (peak > 0) {
      final dd = ((peak - v) * 10000 / peak).round();
      if (dd > worst) worst = dd;
    }
    final last = i == nav.length - 1;
    if (last || nav[i + 1].day.month != b.day.month) path.add((DateTime.utc(b.day.year, b.day.month), v, invested));
  }
  final value = nav.isEmpty ? 0 : valuePaise(units, nav.last.closeE4);
  if (value > 0) flows.add((date: nav.last.day, paise: value));
  return SimResult(invested, value, flows.length >= 2 ? xirr(flows) : null, path, worst);
}

/// Monthly SIP on the first available day of each month from [start].
SimResult simulateSip(List<Bar> nav, DateTime start, int monthlyPaise) {
  final from = nav.where((b) => !b.day.isBefore(start)).toList();
  if (from.isEmpty) return const SimResult(0, 0, null, [], 0);
  final buys = <(DateTime, int)>[];
  for (var m = DateTime.utc(from.first.day.year, from.first.day.month); !m.isAfter(from.last.day); m = addMonths(m, 1)) {
    buys.add((m.isBefore(from.first.day) ? from.first.day : m, monthlyPaise));
  }
  return _run(from, buys);
}

/// The same total money invested on day one.
SimResult simulateLump(List<Bar> nav, DateTime start, int amountPaise) {
  final from = nav.where((b) => !b.day.isBefore(start)).toList();
  if (from.isEmpty) return const SimResult(0, 0, null, [], 0);
  return _run(from, [(from.first.day, amountPaise)]);
}
