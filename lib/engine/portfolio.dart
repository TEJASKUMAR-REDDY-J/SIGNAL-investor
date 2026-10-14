import '../db/db.dart';
import 'calendar.dart';
import 'lots.dart';
import 'money.dart';
import 'tax.dart';
import 'tax.dart' as tax;

class Holding {
  final int instrumentId;
  final Instrument? instrument;
  final Ledger ledger;
  final String bucket; // core | satellite
  const Holding(this.instrumentId, this.instrument, this.ledger, this.bucket);
  String get name => instrument?.name ?? 'Unknown #$instrumentId';
  bool get isMf => instrument?.kind == 'mf';
}

class SipStatus {
  final SipPlan plan;
  final List<DateTime> missed;
  final int recorded;
  final DateTime? nextDue;
  const SipStatus(this.plan, this.missed, this.recorded, this.nextDue);
}

class GoalStatus {
  final Goal goal;
  final int taggedPaise;
  final int daysLeft;
  const GoalStatus(this.goal, this.taggedPaise, this.daysLeft);
  double get yearsLeft => daysLeft / 365.25;

  /// Every instrument here is equity, so tagged money under 3 years out is flagged.
  bool get equityTooClose => taggedPaise > 0 && daysLeft < 3 * 365;
  double get progress =>
      goal.targetPaise <= 0 ? 0 : (taggedPaise / goal.targetPaise).clamp(0, 1).toDouble();
}

/// SIP instalments due between plan start and [today] that have no matching
/// SIP transaction within -5/+7 days of the due date. Each txn matches once.
/// A due date on a weekend or market holiday moves to the next business day.
SipStatus sipStatus(SipPlan p, Iterable<DateTime> sipDates, DateTime today,
    [MarketCalendar cal = nse]) {
  final start = parseDay(p.start);
  final end = p.end == null ? null : parseDay(p.end!);
  final dates = sipDates.toList()..sort();
  final used = List.filled(dates.length, false);
  final missed = <DateTime>[];
  var recorded = 0;
  DateTime? next;
  for (var m = DateTime.utc(start.year, start.month, 1);; m = addMonths(m, 1)) {
    final last = DateTime.utc(m.year, m.month + 1, 0).day;
    final due = cal.onOrAfter(DateTime.utc(m.year, m.month, p.dayOfMonth > last ? last : p.dayOfMonth));
    if (end != null && due.isAfter(end)) break;
    if (due.isBefore(start)) continue;
    if (due.isAfter(today)) {
      if (p.active) next = due;
      break;
    }
    final i = _match(dates, used, due);
    if (i >= 0) {
      used[i] = true;
      recorded++;
    } else if (p.active && today.difference(due).inDays > 7) {
      missed.add(due);
    }
  }
  return SipStatus(p, missed, recorded, next);
}

int _match(List<DateTime> dates, List<bool> used, DateTime due) {
  for (var i = 0; i < dates.length; i++) {
    if (used[i]) continue;
    final d = dates[i].difference(due).inDays;
    if (d >= -5 && d <= 7) return i;
  }
  return -1;
}

/// Everything the screens need, computed once per data change.
class Portfolio {
  final DateTime today;
  final Map<int, Instrument> instruments;
  final Map<int, Ledger> ledgers;
  final List<Holding> holdings; // units > 0, largest cost first
  final List<Realized> realized;
  final int investedPaise;
  final int dividendsPaise;
  final int fy;
  final Tax fyTax;
  final ({int st, int lt}) fyGains;
  final List<(DateTime, int)> netInvested; // month start -> cumulative paise
  final List<(Holding, Lot)> upcomingLongTerm; // next 90 days
  final List<SipStatus> sips;
  final List<GoalStatus> goals;
  final List<Transaction> txs;

  Portfolio._(this.today, this.instruments, this.ledgers, this.holdings, this.realized,
      this.investedPaise, this.dividendsPaise, this.fy, this.fyTax, this.fyGains,
      this.netInvested, this.upcomingLongTerm, this.sips, this.goals, this.txs);

  int get satellitePaise =>
      holdings.where((h) => h.bucket == 'satellite').fold(0, (a, h) => a + h.ledger.costPaise);
  int get mfPaise => holdings.where((h) => h.isMf).fold(0, (a, h) => a + h.ledger.costPaise);
  int get missedSipCount => sips.fold(0, (a, s) => a + s.missed.length);

  factory Portfolio.compute({
    required List<Transaction> txs,
    required List<Instrument> instruments,
    List<HoldingPref> prefs = const [],
    List<Goal> goals = const [],
    List<SipPlan> sips = const [],
    DateTime? today,
  }) {
    final now = today ?? istToday();
    final inst = {for (final i in instruments) i.id: i};
    final bucket = {for (final p in prefs) p.instrumentId: p.bucket};
    final byInst = <int, List<Tx>>{};
    for (final t in txs) {
      (byInst[t.instrumentId] ??= []).add(t.tx);
    }
    final ledgers = {for (final e in byInst.entries) e.key: fifo(e.value)};
    final holdings = [
      for (final e in ledgers.entries)
        if (e.value.units4 > 0) Holding(e.key, inst[e.key], e.value, bucket[e.key] ?? 'core'),
    ]..sort((a, b) => b.ledger.costPaise.compareTo(a.ledger.costPaise));
    final realized = [for (final l in ledgers.values) ...l.realized];
    final fy = fyOf(now);

    // Net invested: cash in (buys incl. charges) minus cash out (sell proceeds).
    final sorted = [...txs]..sort((a, b) => a.date.compareTo(b.date));
    final series = <(DateTime, int)>[];
    if (sorted.isNotEmpty) {
      var i = 0, cum = 0;
      final first = parseDay(sorted.first.date);
      for (var m = DateTime.utc(first.year, first.month, 1);
          !m.isAfter(now);
          m = addMonths(m, 1)) {
        final next = addMonths(m, 1);
        while (i < sorted.length && parseDay(sorted[i].date).isBefore(next)) {
          final t = sorted[i++];
          if (t.type == 'buy' || t.type == 'sip') cum += valuePaise(t.unitsE4, t.priceE4) + t.feesPaise;
          if (t.type == 'sell') cum -= valuePaise(t.unitsE4, t.priceE4) - t.feesPaise;
        }
        series.add((m, cum));
      }
    }

    final horizon = now.add(const Duration(days: 90));
    final upcoming = [
      for (final h in holdings)
        for (final l in h.ledger.open)
          if (l.longTermDate.isAfter(now) && !l.longTermDate.isAfter(horizon)) (h, l),
    ]..sort((a, b) => a.$2.longTermDate.compareTo(b.$2.longTermDate));

    final sipDates = <int, List<DateTime>>{};
    for (final t in txs) {
      if (t.type == 'sip') (sipDates[t.instrumentId] ??= []).add(parseDay(t.date));
    }

    final tagged = <int, int>{};
    for (final l in ledgers.values) {
      for (final lot in l.open) {
        if (lot.goalId != null) tagged[lot.goalId!] = (tagged[lot.goalId!] ?? 0) + lot.costPaise;
      }
    }

    return Portfolio._(
      now,
      inst,
      ledgers,
      holdings,
      realized,
      holdings.fold(0, (a, h) => a + h.ledger.costPaise),
      ledgers.values.fold(0, (a, l) => a + l.dividendsPaise),
      fy,
      tax.fyTax(realized, fy),
      tax.fyGains(realized, fy),
      series,
      upcoming,
      [for (final p in sips) sipStatus(p, sipDates[p.instrumentId] ?? const [], now)],
      [
        for (final g in goals)
          GoalStatus(g, tagged[g.id] ?? 0, parseDay(g.targetDate).difference(now).inDays),
      ]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft)),
      txs,
    );
  }
}
