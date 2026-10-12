import 'money.dart';

// Dates are UTC-midnight DateTimes, stored as 'YYYY-MM-DD'.
DateTime parseDay(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime.utc(p[0], p[1], p[2]);
}

/// Today's date in IST (UTC+05:30), computed explicitly, never from device TZ.
DateTime istToday([DateTime? nowUtc]) {
  final ist = (nowUtc ?? DateTime.now()).toUtc().add(const Duration(hours: 5, minutes: 30));
  return DateTime.utc(ist.year, ist.month, ist.day);
}

String fmtDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Same calendar day [months] later, clamped to month end (31 Jan + 1m = 28/29 Feb).
DateTime addMonths(DateTime d, int months) {
  final m0 = d.month - 1 + months;
  final y = d.year + (m0 ~/ 12);
  final m = m0 % 12 + 1;
  final last = DateTime.utc(y, m + 1, 0).day;
  return DateTime.utc(y, m, d.day > last ? last : d.day);
}

/// Listed equity / equity MF: long-term if held MORE than 12 months.
/// The 12-month anniversary itself is still short-term.
DateTime longTermFrom(DateTime buy) =>
    addMonths(buy, 12).add(const Duration(days: 1));

bool isLongTerm(DateTime buy, DateTime sell) => !sell.isBefore(longTermFrom(buy));

enum TxType { buy, sell, sip, dividend }

/// One ledger row. Dividend: units4 = 0, price4 = total amount x1e4.
class Tx {
  final int id;
  final DateTime date;
  final TxType type;
  final int units4;
  final int price4;
  final int feesPaise;
  const Tx(this.id, this.date, this.type, this.units4, this.price4,
      [this.feesPaise = 0]);

  bool get adds => type == TxType.buy || type == TxType.sip;
}

class Lot {
  final DateTime buyDate;
  final int units4;
  final int costPaise;
  const Lot(this.buyDate, this.units4, this.costPaise);
  DateTime get longTermDate => longTermFrom(buyDate);
}

class Realized {
  final DateTime buyDate;
  final DateTime sellDate;
  final int units4;
  final int costPaise;
  final int proceedsPaise;
  const Realized(this.buyDate, this.sellDate, this.units4, this.costPaise,
      this.proceedsPaise);
  bool get longTerm => isLongTerm(buyDate, sellDate);
  int get gainPaise => proceedsPaise - costPaise;
}

class Ledger {
  final List<Lot> open;
  final List<Realized> realized;
  final int dividendsPaise;

  /// Ids of sells that exceeded units held at the time (excess ignored).
  final List<int> oversold;
  const Ledger(this.open, this.realized, this.dividendsPaise, this.oversold);

  int get units4 => open.fold(0, (a, l) => a + l.units4);
  int get costPaise => open.fold(0, (a, l) => a + l.costPaise);
}

/// Ledger order: date, then adds before sells on the same day, then id.
int compareTx(Tx a, Tx b) {
  final c = a.date.compareTo(b.date);
  if (c != 0) return c;
  final s = (a.type == TxType.sell ? 1 : 0) - (b.type == TxType.sell ? 1 : 0);
  return s != 0 ? s : a.id.compareTo(b.id);
}

/// FIFO lots for ONE instrument, recomputed from transactions every time.
Ledger fifo(Iterable<Tx> txs) {
  final sorted = txs.toList()..sort(compareTx);
  final open = <Lot>[];
  final realized = <Realized>[];
  final oversold = <int>[];
  var dividends = 0;
  for (final t in sorted) {
    switch (t.type) {
      case TxType.dividend:
        dividends += valuePaise(unitScale, t.price4);
      case TxType.buy || TxType.sip:
        if (t.units4 <= 0) continue;
        open.add(Lot(t.date, t.units4,
            valuePaise(t.units4, t.price4) + t.feesPaise));
      case TxType.sell:
        final held = open.fold(0, (a, l) => a + l.units4);
        if (t.units4 > held) oversold.add(t.id);
        realized.addAll(
            sellFifo(open, t.units4, t.price4, t.feesPaise, t.date));
    }
  }
  return Ledger(open, realized, dividends, oversold);
}

/// Sells up to [units4] from the front of [open] (mutated). Excess over
/// holdings is ignored. Fees reduce proceeds.
List<Realized> sellFifo(
    List<Lot> open, int units4, int price4, int feesPaise, DateTime date) {
  final held = open.fold(0, (a, l) => a + l.units4);
  final n = units4 > held ? held : units4;
  final out = <Realized>[];
  if (n <= 0) return out;
  final proceeds = valuePaise(n, price4) - feesPaise;
  var left = n, proceedsLeft = proceeds;
  while (left > 0) {
    final lot = open.first;
    final take = lot.units4 < left ? lot.units4 : left;
    final cost = take == lot.units4
        ? lot.costPaise
        : mulDiv(lot.costPaise, take, lot.units4);
    left -= take;
    // Remainder goes to the last slice so proceeds sum exactly.
    final p = left == 0 ? proceedsLeft : mulDiv(proceeds, take, n);
    proceedsLeft -= p;
    out.add(Realized(lot.buyDate, date, take, cost, p));
    if (take == lot.units4) {
      open.removeAt(0);
    } else {
      open[0] = Lot(lot.buyDate, lot.units4 - take, lot.costPaise - cost);
    }
  }
  return out;
}
