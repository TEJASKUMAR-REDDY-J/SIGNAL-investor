import 'dart:math';

/// Cash flow: negative = money in (investment), positive = money out.
typedef Flow = ({DateTime date, int paise});

/// Spreadsheet-style XIRR (actual/365) via bisection on [-0.99, 10.0].
/// Returns null if NPV does not change sign over the bracket.
double? xirr(List<Flow> flows) {
  if (flows.length < 2) return null;
  final t0 = flows.map((f) => f.date).reduce((a, b) => a.isBefore(b) ? a : b);
  final ts = [for (final f in flows) f.date.difference(t0).inDays / 365.0];
  final cs = [for (final f in flows) f.paise / 100.0];
  double npv(double r) {
    var s = 0.0;
    for (var i = 0; i < cs.length; i++) {
      s += cs[i] / pow(1 + r, ts[i]);
    }
    return s;
  }

  var lo = -0.99, hi = 10.0;
  var fLo = npv(lo);
  final fHi = npv(hi);
  if (fLo.isNaN || fHi.isNaN || fLo.sign == fHi.sign) return null;
  for (var i = 0; i < 200 && hi - lo > 1e-12; i++) {
    final mid = (lo + hi) / 2;
    final f = npv(mid);
    if (f == 0) return mid;
    if (f.sign == fLo.sign) {
      lo = mid;
      fLo = f;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}
