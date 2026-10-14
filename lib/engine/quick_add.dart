import 'lots.dart';
import 'money.dart';

/// "sip 5000 ppfas today" / "buy 10 infy 1520" / "sell 5 tcs @3100 yesterday".
/// Plain text rules, parsed locally; the result only prefills the form.
class QuickAdd {
  final TxType type;
  final int? unitsE4; // buy / sell
  final int? priceE4; // buy / sell
  final int? amountPaise; // sip / dividend
  final String query; // instrument words
  final DateTime? date;
  const QuickAdd(this.type, {this.unitsE4, this.priceE4, this.amountPaise, this.query = '', this.date});
}

const _types = {
  'buy': TxType.buy,
  'b': TxType.buy,
  'sell': TxType.sell,
  's': TxType.sell,
  'sip': TxType.sip,
  'div': TxType.dividend,
  'dividend': TxType.dividend,
};
const _mon = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

QuickAdd? parseQuickAdd(String input, DateTime today) {
  final words = input.toLowerCase().replaceAll('₹', ' ').replaceAll(',', '').split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty || w == 'rs' || w == 'units' || w == 'of' || w == 'at');
  if (words.isEmpty || !_types.containsKey(words.first)) return null;
  final type = _types[words.first]!;
  final nums = <String>[];
  final rest = <String>[];
  DateTime? date;
  for (var i = 1; i < words.length; i++) {
    final w = words[i];
    if (w == 'today') {
      date = today;
    } else if (w == 'yesterday') {
      date = today.subtract(const Duration(days: 1));
    } else if (RegExp(r'^\d{1,2}/\d{1,2}(/\d{2,4})?$').hasMatch(w)) {
      final p = w.split('/').map(int.parse).toList();
      final y = p.length == 3 ? (p[2] < 100 ? 2000 + p[2] : p[2]) : today.year;
      date = DateTime.utc(y, p[1], p[0]);
    } else if (RegExp(r'^\d{1,2}$').hasMatch(w) && i + 1 < words.length && _mon.contains(words[i + 1].substring(0, words[i + 1].length.clamp(0, 3)))) {
      date = DateTime.utc(today.year, _mon.indexOf(words[i + 1].substring(0, 3)) + 1, int.parse(w));
      i++;
    } else if (RegExp(r'^@?\d+(\.\d+)?$').hasMatch(w)) {
      nums.add(w.replaceAll('@', ''));
    } else {
      rest.add(w);
    }
  }
  if (date != null && date.isAfter(today)) date = DateTime.utc(date.year - 1, date.month, date.day);
  final q = rest.join(' ');
  if (type == TxType.sip || type == TxType.dividend) {
    final amt = nums.isEmpty ? null : parseScaled(nums.first, 2);
    return QuickAdd(type, amountPaise: amt, query: q, date: date);
  }
  return QuickAdd(type,
      unitsE4: nums.isEmpty ? null : parseScaled(nums.first, 4),
      priceE4: nums.length < 2 ? null : parseScaled(nums[1], 4),
      query: q,
      date: date);
}
