// Money is int paise. Units and prices are ints scaled by 1e4
// (MF units and NAVs carry up to 4 decimals). Never double for stored money.

const unitScale = 10000;
const priceScale = 10000;

final _million = BigInt.from(1000000);

/// Paise value of [units4] x [price4], rounded half away from zero.
/// BigInt because units4 * price4 can exceed int64.
int valuePaise(int units4, int price4) =>
    divRound(BigInt.from(units4) * BigInt.from(price4), _million);

/// Units (x1e4) that [paise] buys at [price4], rounded half away from zero.
int unitsFor(int paise, int price4) =>
    divRound(BigInt.from(paise) * _million, BigInt.from(price4));

/// a * b / c rounded, without int64 overflow.
int mulDiv(int a, int b, int c) =>
    divRound(BigInt.from(a) * BigInt.from(b), BigInt.from(c));

int divRound(BigInt n, BigInt d) {
  final q = n ~/ d;
  final r = n.remainder(d).abs() * BigInt.two;
  if (r < d.abs()) return q.toInt();
  return (q + ((n.isNegative != d.isNegative) ? -BigInt.one : BigInt.one))
      .toInt();
}

/// Parses "1,234.5678" into an int scaled by 10^[decimals]. Exact, no double.
/// Returns null on bad input or more decimals than allowed.
int? parseScaled(String s, int decimals) {
  final t = s.replaceAll(',', '').trim();
  final m = RegExp(r'^(-?)(\d*)(?:\.(\d*))?$').firstMatch(t);
  if (m == null || (m[2]!.isEmpty && (m[3] ?? '').isEmpty)) return null;
  final frac = m[3] ?? '';
  if (frac.length > decimals) return null;
  final whole = m[2]!.isEmpty ? '0' : m[2]!;
  if (whole.length > 13) return null;
  final v = int.parse(whole + frac.padRight(decimals, '0'));
  return m[1] == '-' ? -v : v;
}

/// Inverse of [parseScaled]; trims trailing zeros down to [minDecimals].
String formatScaled(int v, int decimals, {int minDecimals = 0}) {
  final neg = v < 0;
  final s = v.abs().toString().padLeft(decimals + 1, '0');
  final whole = s.substring(0, s.length - decimals);
  var frac = s.substring(s.length - decimals);
  while (frac.length > minDecimals && frac.endsWith('0')) {
    frac = frac.substring(0, frac.length - 1);
  }
  return '${neg ? '-' : ''}$whole${frac.isEmpty ? '' : '.$frac'}';
}

/// Indian grouping: 12345678 paise -> "₹1,23,456.78".
String rupees(int paise, {bool decimals = true}) {
  final neg = paise < 0;
  var p = paise.abs();
  if (!decimals) p = (p + 50) ~/ 100 * 100;
  final whole = (p ~/ 100).toString();
  final buf = StringBuffer();
  if (whole.length <= 3) {
    buf.write(whole);
  } else {
    final head = whole.substring(0, whole.length - 3);
    for (var i = 0; i < head.length; i++) {
      if (i > 0 && (head.length - i) % 2 == 0) buf.write(',');
      buf.write(head[i]);
    }
    buf.write(',${whole.substring(whole.length - 3)}');
  }
  final frac = decimals ? '.${(p % 100).toString().padLeft(2, '0')}' : '';
  return '${neg ? '-' : ''}₹$buf$frac';
}
