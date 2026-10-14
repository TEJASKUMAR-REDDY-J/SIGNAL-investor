import '../db/db.dart';
import 'calendar.dart';
import 'lots.dart';
import 'money.dart';
import 'tax.dart';
import 'tax.dart' as tax;
import 'valuation.dart';

int valuePaise4(int units4, int price4) => valuePaise(units4, price4);

class Holding {
  final int instrumentId;
  final Instrument? instrument;
  final Ledger ledger;
  final String bucket; // core | satellite
  final Bar? price; // latest close, null when not fetched yet
  final bool mismatch; // two sources disagree > 0.5% -> no signals
  final bool stale;
  final double? xirr;
  const Holding(this.instrumentId, this.instrument, this.ledger, this.bucket,
      {this.price, this.mismatch = false, this.stale = false, this.xirr});
  String get name => instrument?.name ?? 'Unknown #$instrumentId';
  bool get isMf => instrument?.kind == 'mf';

  /// Market value, or cost when no price is known yet.
  int get valuePaise => price == null ? ledger.costPaise : valuePaise4(ledger.units4, price!.closeE4);
  int get gainPaise => valuePaise - ledger.costPaise;
  bool get priced => price != null;
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
    [MarketCalendar? cal]) {
  cal ??= nse;
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

class MonthPoint {
  final DateTime month;
  final int investedPaise; // net cash in
  final int? valuePaise; // market value at month end (null without prices)
  final int? ghostPaise; // same flows in the Nifty 50 index fund
  const MonthPoint(this.month, this.investedPaise, this.valuePaise, this.ghostPaise);
}

/// Everything the screens need, computed once per data change.
class Portfolio {
  final DateTime today;
  final Map<int, Instrument> instruments;
  final Map<int, Ledger> ledgers;
  final List<Holding> holdings; // units > 0, largest value first
  final List<Realized> realized;
  final int investedPaise; // open cost
  final int dividendsPaise;
  final int fy;
  final Tax fyTax;
  final ({int st, int lt}) fyGains;
  final List<MonthPoint> months;
  final List<(Holding, Lot)> upcomingLongTerm; // next 90 days
  final List<SipStatus> sips;
  final List<GoalStatus> goals;
  final List<Transaction> txs;
  final PriceBook book;
  final int? benchId;
  final int? indexId;
  final double? xirr; // whole portfolio, at market
  final double? ghostXirr; // same flows in the benchmark
  final int? ghostValuePaise;
  final FallContext? fall;

  Portfolio._(this.today, this.instruments, this.ledgers, this.holdings, this.realized, this.investedPaise,
      this.dividendsPaise, this.fy, this.fyTax, this.fyGains, this.months, this.upcomingLongTerm, this.sips,
      this.goals, this.txs, this.book, this.benchId, this.indexId, this.xirr, this.ghostXirr, this.ghostValuePaise,
      this.fall);

  int get valuePaise => holdings.fold(0, (a, h) => a + h.valuePaise);
  int get gainPaise => valuePaise - investedPaise;
  bool get anyPriced => holdings.any((h) => h.priced);
  bool get allPriced => holdings.every((h) => h.priced);
  List<Holding> get staleHoldings => [for (final h in holdings) if (h.stale) h];
  int get satellitePaise => holdings.where((h) => h.bucket == 'satellite').fold(0, (a, h) => a + h.valuePaise);
  int get mfPaise => holdings.where((h) => h.isMf).fold(0, (a, h) => a + h.valuePaise);
  int get missedSipCount => sips.fold(0, (a, s) => a + s.missed.length);

  /// Today's move across priced holdings (shown only on press-and-hold).
  int get dayChangePaise {
    var sum = 0;
    for (final h in holdings) {
      final s = book.series(h.instrumentId);
      if (s.length < 2 || h.price == null) continue;
      sum += valuePaise4(h.ledger.units4, s.last.closeE4) - valuePaise4(h.ledger.units4, s[s.length - 2].closeE4);
    }
    return sum;
  }

  List<(DateTime, int)> get netInvested => [for (final m in months) (m.month, m.investedPaise)];

  factory Portfolio.compute({
    required List<Transaction> txs,
    required List<Instrument> instruments,
    List<HoldingPref> prefs = const [],
    List<Goal> goals = const [],
    List<SipPlan> sips = const [],
    PriceBook? book,
    DateTime? today,
  }) {
    final now = today ?? istToday();
    final pb = book ?? (PriceBook()..seal());
    final inst = {for (final i in instruments) i.id: i};
    final benchId = (instruments.where((i) => i.schemeCode == benchmarkScheme).firstOrNull ??
            instruments.where((i) => i.aliases == 'benchmark').firstOrNull)
        ?.id;
    final indexId = instruments.where((i) => i.kind == 'index').firstOrNull?.id;
    final bucket = {for (final p in prefs) p.instrumentId: p.bucket};
    final byInst = <int, List<Tx>>{};
    for (final t in txs) {
      (byInst[t.instrumentId] ??= []).add(t.tx);
    }
    final ledgers = {for (final e in byInst.entries) e.key: fifo(e.value)};
    // Staleness is judged at the end of [today] when a date is given (tests,
    // time machine); otherwise at the real current instant.
    final nowUtc = today == null ? DateTime.now() : DateTime.utc(today.year, today.month, today.day, 18, 29);
    final lastDay = nse.lastTradingDay(nowUtc);
    // NAVs land late at night: one trading day of lag is normal for funds.
    final navOk = nse.onOrBefore(lastDay.subtract(const Duration(days: 1)));
    final holdings = <Holding>[];
    for (final e in ledgers.entries) {
      if (e.value.units4 <= 0) continue;
      final i = inst[e.key];
      final px = pb.latest(e.key);
      final value = px == null ? null : valuePaise4(e.value.units4, px.closeE4);
      holdings.add(Holding(e.key, i, e.value, bucket[e.key] ?? 'core',
          price: px,
          mismatch: pb.mismatched(e.key),
          stale: px != null && px.day.isBefore(i?.kind == 'mf' ? navOk : lastDay),
          xirr: value == null ? null : xirrOf(byInst[e.key]!, value, now)));
    }
    holdings.sort((a, b) => b.valuePaise.compareTo(a.valuePaise));
    final realized = [for (final l in ledgers.values) ...l.realized];
    final fy = fyOf(now);

    // Monthly series: net cash in, market value and ghost value at month end.
    final instOf = {for (final t in txs) t.id: t.instrumentId};
    final sorted = [for (final t in txs) t.tx]..sort(compareTx);
    final months = <MonthPoint>[];
    if (sorted.isNotEmpty) {
      var i = 0, cum = 0, ghost = 0;
      final ghostOk = benchId != null && pb.series(benchId).isNotEmpty;
      final units = <int, int>{};
      final first = sorted.first.date;
      for (var m = DateTime.utc(first.year, first.month, 1); !m.isAfter(now); m = addMonths(m, 1)) {
        final next = addMonths(m, 1);
        while (i < sorted.length && sorted[i].date.isBefore(next)) {
          final t = sorted[i++];
          final id = instOf[t.id]!;
          final f = txFlowPaise(t);
          cum -= f;
          final u = units[id] ?? 0;
          units[id] = switch (t.type) {
            TxType.buy || TxType.sip => u + t.units4,
            TxType.sell => u - t.units4,
            TxType.split => mulDiv(u, t.units4, unitScale),
            TxType.bonus => u + mulDiv(u, t.units4, unitScale),
            TxType.dividend => u,
          };
          if (ghostOk && f != 0) {
            final nav = pb.on(benchId, t.date) ?? pb.series(benchId).first;
            ghost += f < 0 ? unitsFor(-f, nav.closeE4) : -unitsFor(f, nav.closeE4);
          }
        }
        final end = next.subtract(const Duration(days: 1));
        final at = end.isAfter(now) ? now : end;
        int? value = 0;
        for (final e in units.entries) {
          if (e.value <= 0) continue;
          final b = pb.on(e.key, at);
          if (b == null) {
            value = null;
            break;
          }
          value = value! + valuePaise4(e.value, b.closeE4);
        }
        final gb = ghostOk ? pb.on(benchId, at) : null;
        months.add(MonthPoint(m, cum, value, gb == null ? null : valuePaise4(ghost, gb.closeE4)));
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

    final allTx = [for (final t in txs) t.tx];
    final priced = holdings.isNotEmpty && holdings.every((h) => h.priced);
    final total = holdings.fold(0, (a, h) => a + h.valuePaise);
    final gUnits = benchId == null ? null : ghostUnits(allTx, pb, benchId);
    final gLatest = benchId == null ? null : pb.latest(benchId);
    final gValue = gUnits == null || gLatest == null ? null : valuePaise4(gUnits, gLatest.closeE4);

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
      months,
      upcoming,
      [for (final p in sips) sipStatus(p, sipDates[p.instrumentId] ?? const [], now)],
      [
        for (final g in goals) GoalStatus(g, tagged[g.id] ?? 0, parseDay(g.targetDate).difference(now).inDays),
      ]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft)),
      txs,
      pb,
      benchId,
      indexId,
      priced ? xirrOf(allTx, total, now) : null,
      priced && gValue != null ? xirrOf(allTx, gValue, now) : null,
      gValue,
      indexId == null ? null : badDay(pb.series(indexId)),
    );
  }
}
