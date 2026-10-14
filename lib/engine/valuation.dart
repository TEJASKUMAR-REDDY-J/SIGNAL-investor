import 'dart:math' as math;

import 'lots.dart';
import 'money.dart';
import 'xirr.dart';

/// Max allowed gap between two price sources for the same day.
const mismatchBps = 50; // 0.5%

class Bar {
  final DateTime day;
  final int closeE4;
  const Bar(this.day, this.closeE4);
}

/// Closes per instrument per source, oldest first.
class PriceBook {
  final Map<int, Map<String, List<Bar>>> _bars = {};

  void add(int instrumentId, String source, String date, int closeE4) =>
      ((_bars[instrumentId] ??= {})[source] ??= []).add(Bar(parseDay(date), closeE4));

  /// Call once after adding rows.
  void seal() {
    for (final m in _bars.values) {
      for (final l in m.values) {
        l.sort((a, b) => a.day.compareTo(b.day));
      }
    }
  }

  /// Primary series: Yahoo for stocks/indices, mfapi for funds, else NSE.
  List<Bar> series(int id) {
    final m = _bars[id];
    if (m == null) return const [];
    return m['yahoo'] ?? m['mfapi'] ?? m['nse'] ?? const [];
  }

  Bar? latest(int id) => series(id).lastOrNull;

  /// Last close on or before [day] (binary search).
  Bar? on(int id, DateTime day) {
    final s = series(id);
    var lo = 0, hi = s.length - 1, best = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (!s[mid].day.isAfter(day)) {
        best = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return best < 0 ? null : s[best];
  }

  /// Latest day both Yahoo and NSE have a close for; (yahoo, nse, gapBps).
  (Bar, Bar, int)? crossCheck(int id) {
    final y = _bars[id]?['yahoo'], n = _bars[id]?['nse'];
    if (y == null || n == null) return null;
    final nm = {for (final b in n) b.day: b};
    for (final b in y.reversed) {
      final o = nm[b.day];
      if (o != null) return (b, o, ((b.closeE4 - o.closeE4).abs() * 10000 / o.closeE4).round());
    }
    return null;
  }

  bool mismatched(int id) => (crossCheck(id)?.$3 ?? 0) > mismatchBps;

  /// Simple moving average of the last [n] closes, null if history is short.
  int? sma(int id, int n) {
    final s = series(id);
    if (s.length < n) return null;
    var sum = 0;
    for (var i = s.length - n; i < s.length; i++) {
      sum += s[i].closeE4;
    }
    return sum ~/ n;
  }

  /// Highest close in the last [days] calendar days.
  int? peak(int id, int days) {
    final s = series(id);
    if (s.isEmpty) return null;
    final from = s.last.day.subtract(Duration(days: days));
    return s.where((b) => !b.day.isBefore(from)).map((b) => b.closeE4).reduce(math.max);
  }

  /// Change of the latest close versus the previous one, in bps.
  int? dayChangeBps(int id) {
    final s = series(id);
    if (s.length < 2) return null;
    return ((s.last.closeE4 - s[s.length - 2].closeE4) * 10000 / s[s.length - 2].closeE4).round();
  }
}

/// Cash flow of one transaction from the investor's side (paise, + = money back).
int txFlowPaise(Tx t) => switch (t.type) {
      TxType.buy || TxType.sip => -(valuePaise(t.units4, t.price4) + t.feesPaise),
      TxType.sell => valuePaise(t.units4, t.price4) - t.feesPaise,
      TxType.dividend => valuePaise(unitScale, t.price4),
      _ => 0,
    };

double? xirrOf(Iterable<Tx> txs, int terminalValuePaise, DateTime today) {
  final flows = <Flow>[
    for (final t in txs)
      if (txFlowPaise(t) != 0) (date: t.date, paise: txFlowPaise(t)),
    if (terminalValuePaise > 0) (date: today, paise: terminalValuePaise),
  ];
  return xirr(flows);
}

/// Same cash flows into a benchmark: buys buy benchmark units at its close on
/// that day; sells and dividends redeem benchmark units of the same rupee value.
/// Returns benchmark units held after all flows (x1e4), or null without prices.
int? ghostUnits(Iterable<Tx> txs, PriceBook book, int benchId) {
  var units = 0;
  for (final t in [...txs]..sort(compareTx)) {
    final f = txFlowPaise(t);
    if (f == 0) continue;
    final nav = book.on(benchId, t.date) ?? book.series(benchId).firstOrNull;
    if (nav == null) return null;
    units += f < 0 ? unitsFor(-f, nav.closeE4) : -unitsFor(f, nav.closeE4);
  }
  return units;
}

/// Plain-language reading of an annual rate.
String rateSentence(double r) {
  if (r.isNaN) return '';
  if (r <= -0.99) return 'Nearly all of the money invested has been lost.';
  if (r < 0) return 'At this rate money shrinks by about ${(-r * 100).toStringAsFixed(1)}% a year.';
  if (r < 0.005) return 'Roughly flat so far.';
  final years = math.log(2) / math.log(1 + r);
  return 'At this rate money doubles roughly every ${years.toStringAsFixed(1)} years.';
}

class FallContext {
  final int todayBps; // negative
  final int similarFalls;
  final int? medianRecoveryDays; // trading days back to the prior close
  final int unrecovered;
  const FallContext(this.todayBps, this.similarFalls, this.medianRecoveryDays, this.unrecovered);
}

/// Past one-day falls at least as deep as today's, and how long the index
/// took to get back above the close before each fall. From real history only.
FallContext? badDay(List<Bar> index, {int thresholdBps = -150}) {
  if (index.length < 30) return null;
  final last = index.length - 1;
  final today = ((index[last].closeE4 - index[last - 1].closeE4) * 10000 / index[last - 1].closeE4).round();
  if (today > thresholdBps) return null;
  final rec = <int>[];
  var unrecovered = 0, count = 0;
  for (var i = 1; i < last; i++) {
    final c = ((index[i].closeE4 - index[i - 1].closeE4) * 10000 / index[i - 1].closeE4).round();
    if (c > today) continue;
    count++;
    final before = index[i - 1].closeE4;
    final j = index.indexWhere((b) => b.closeE4 >= before, i + 1);
    if (j < 0 || j > last - 1) {
      unrecovered++;
    } else {
      rec.add(j - i);
    }
  }
  rec.sort();
  return FallContext(today, count, rec.isEmpty ? null : rec[rec.length ~/ 2], unrecovered);
}
