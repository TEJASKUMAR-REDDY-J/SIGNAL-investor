import 'lots.dart';
import 'portfolio.dart';
import 'tax.dart';

/// Discipline, not activity: nothing here rewards opening the app or trading.
class Habits {
  final int sipStreakMonths; // consecutive months with every SIP instalment recorded
  final bool freePassUsed; // one missed month per FY does not break the streak
  final int monthsWithoutShortTermSell;
  final (Holding, Lot)? longestHeld;
  const Habits(this.sipStreakMonths, this.freePassUsed, this.monthsWithoutShortTermSell, this.longestHeld);
}

int _ym(DateTime d) => d.year * 12 + d.month - 1;

Habits habits(Portfolio p) {
  final today = p.today;
  // Months that had a due instalment, and months with a miss.
  final due = <int>{}, missed = <int>{};
  for (final s in p.sips) {
    if (!s.plan.active) continue;
    for (var m = DateTime.utc(parseDay(s.plan.start).year, parseDay(s.plan.start).month, 1);
        !m.isAfter(today);
        m = addMonths(m, 1)) {
      due.add(_ym(m));
    }
    for (final d in s.missed) {
      missed.add(_ym(d));
    }
  }
  // Current month counts only once its instalments are no longer pending.
  final months = due.toList()..sort((a, b) => b.compareTo(a));
  var streak = 0;
  var passUsed = false;
  int? passFy;
  for (final m in months) {
    if (m == _ym(today) && !missed.contains(m)) continue; // still in progress
    if (!missed.contains(m)) {
      streak++;
      continue;
    }
    final fy = fyOf(DateTime.utc(m ~/ 12, m % 12 + 1));
    if (passFy == null || passFy != fy) {
      passFy = fy;
      passUsed = true;
      continue; // forgiven, streak continues
    }
    break;
  }

  final lastShort = p.realized.where((r) => !r.longTerm).map((r) => r.sellDate).fold<DateTime?>(
      null, (a, b) => a == null || b.isAfter(a) ? b : a);
  final firstTx = p.txs.isEmpty ? today : parseDay(p.txs.map((t) => t.date).reduce((a, b) => a.compareTo(b) <= 0 ? a : b));
  final since = lastShort ?? firstTx;
  final quiet = (_ym(today) - _ym(since)).clamp(0, 1200);

  (Holding, Lot)? longest;
  for (final h in p.holdings) {
    for (final l in h.ledger.open) {
      if (longest == null || l.buyDate.isBefore(longest.$2.buyDate)) longest = (h, l);
    }
  }
  return Habits(streak, passUsed, quiet, longest);
}

/// Once-a-year look back, for the financial year starting in [fy].
class Wrapped {
  final int fy;
  final int exemptionUsedPaise;
  final int ltGainPaise;
  final int taxPaidPaise;
  final int taxSavedByWaitingPaise; // vs the same gains taxed as short-term
  final int sipMonthsKept;
  final int sipMonthsDue;
  const Wrapped(this.fy, this.exemptionUsedPaise, this.ltGainPaise, this.taxPaidPaise, this.taxSavedByWaitingPaise,
      this.sipMonthsKept, this.sipMonthsDue);
}

Wrapped wrapped(Portfolio p, int fy) {
  final g = fyGains(p.realized, fy);
  final actual = taxFor(stGainPaise: g.st, ltGainPaise: g.lt);
  final ifShort = taxFor(stGainPaise: g.st + (g.lt > 0 ? g.lt : 0), ltGainPaise: g.lt > 0 ? 0 : g.lt);
  var dueM = 0, keptM = 0;
  final start = DateTime.utc(fy, 4), end = DateTime.utc(fy + 1, 3, 31);
  final missed = {for (final s in p.sips) for (final d in s.missed) _ym(d)};
  final due = <int>{};
  for (final s in p.sips) {
    for (var m = DateTime.utc(parseDay(s.plan.start).year, parseDay(s.plan.start).month, 1);
        !m.isAfter(end) && !m.isAfter(p.today);
        m = addMonths(m, 1)) {
      if (!m.isBefore(start)) due.add(_ym(m));
    }
  }
  dueM = due.length;
  keptM = due.where((m) => !missed.contains(m)).length;
  return Wrapped(fy, actual.exemptionUsedPaise, g.lt, actual.taxPaise, ifShort.taxPaise - actual.taxPaise, keptM, dueM);
}
