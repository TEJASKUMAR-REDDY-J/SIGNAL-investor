import 'dart:math';

import 'lots.dart';
import 'money.dart';

// Three autonomous paper portfolios. Rules shortlist and size; an AI may choose
// among the shortlist; [enforce] applies the hard limits no plan can exceed.

enum AgentKind { daily, weekly, monthly }

const agentStartCashPaise = 250000000; // Rs 25,00,000 each
const agentMonthlyLimitPaise = 40000000; // Rs 4,00,000 net new money per agent per calendar month
const agentPerStockDayPaise = 5000000; // Rs 50,000 per stock per day per agent
const agentCostBps = 10; // 0.1% per trade: brokerage, STT and charges, roughly
const agentRuleVersion = 'agents/1 2026-10-14';

class AgentConfig {
  final String name;
  final String style;
  final int maxHoldings;
  final int stopBps; // exit at this loss
  final int? targetBps; // exit at this gain
  final int? maxHoldDays; // exit after this many calendar days
  const AgentConfig(this.name, this.style, this.maxHoldings, this.stopBps, this.targetBps, this.maxHoldDays);
}

const agentConfigs = {
  AgentKind.daily: AgentConfig(
      'Daily',
      'Short-term trader. Buys fresh good news and strong recent moves; sells at +5%, at -3%, on bad news, or after a week.',
      10,
      300,
      500,
      7),
  AgentKind.weekly: AgentConfig(
      'Weekly',
      'Swing trader. Picks 1-month leaders with good news on the first trading day of each week; sells at +12%, at -7%, '
          'or when the trend or news turns.',
      12,
      700,
      1200,
      45),
  AgentKind.monthly: AgentConfig(
      'Monthly',
      'Long-term compounder. Buys quality and growth leaders a little every trading day, spreading the month\'s money '
          'across the month. Sells only when the case breaks.',
      20,
      2500,
      null,
      null),
};

/// One NIFTY 500 stock as the agents see it today.
class AgentCand {
  final int instrumentId;
  final String symbol;
  final String name;
  final int priceE4; // latest (delayed) price
  final List<int> closesE4; // recent daily closes, oldest first, ending today
  final double? advisorScore; // 0..1, null when the quality filters fail
  final double? quality, growth, momentum;
  final double news1, news7; // AI headline points, last 24 h and 7 days
  final String? headline; // latest labelled headline
  const AgentCand(this.instrumentId, this.symbol, this.name, this.priceE4, this.closesE4,
      {this.advisorScore, this.quality, this.growth, this.momentum, this.news1 = 0, this.news7 = 0, this.headline});

  double _ret(int days) {
    if (closesE4.length <= days) return 0;
    final then = closesE4[closesE4.length - 1 - days];
    return then == 0 ? 0 : priceE4 / then - 1;
  }

  double get ret1 => _ret(1);
  double get ret5 => _ret(5);
  double get ret20 => _ret(min(20, closesE4.length - 1));
}

class AgentPosition {
  final int instrumentId;
  int units4 = 0;
  int costPaise = 0;
  DateTime firstBuy;
  AgentPosition(this.instrumentId, this.firstBuy);
}

/// Cash and positions rebuilt from the trade log (average cost).
class AgentBook {
  int cashPaise = agentStartCashPaise;
  int realizedPaise = 0;
  final positions = <int, AgentPosition>{};
  final _buys = <(String, int), int>{}; // (date, instrument) -> bought value that day
  final _monthNet = <String, int>{}; // YYYY-MM -> buys minus sells

  AgentBook(Iterable<(String date, String side, int instrumentId, int units4, int price4, int fees)> trades) {
    for (final (date, side, id, u, p, fees) in trades) {
      final v = valuePaise(u, p);
      final month = date.substring(0, 7);
      if (side == 'buy') {
        cashPaise -= v + fees;
        final pos = positions.putIfAbsent(id, () => AgentPosition(id, parseDay(date)));
        pos.units4 += u;
        pos.costPaise += v + fees;
        _buys[(date, id)] = (_buys[(date, id)] ?? 0) + v;
        _monthNet[month] = (_monthNet[month] ?? 0) + v;
      } else {
        cashPaise += v - fees;
        final pos = positions[id];
        if (pos == null || pos.units4 == 0) continue;
        final cost = mulDiv(pos.costPaise, min(u, pos.units4), pos.units4);
        realizedPaise += v - fees - cost;
        pos.costPaise -= cost;
        pos.units4 -= min(u, pos.units4);
        if (pos.units4 == 0) positions.remove(id);
        _monthNet[month] = (_monthNet[month] ?? 0) - v;
      }
    }
  }

  int boughtOn(String date, int id) => _buys[(date, id)] ?? 0;
  int monthNet(String month) => max(0, _monthNet[month] ?? 0);
  int monthRoom(String month) => max(0, agentMonthlyLimitPaise - monthNet(month));

  int valueAt(Map<int, int> pricesE4) =>
      cashPaise + positions.values.fold(0, (a, p) => a + valuePaise(p.units4, pricesE4[p.instrumentId] ?? 0));
}

class PlannedBuy {
  final int instrumentId;
  final int amountPaise;
  final String reason;
  const PlannedBuy(this.instrumentId, this.amountPaise, this.reason);
}

class PlannedSell {
  final int instrumentId;
  final String reason;
  const PlannedSell(this.instrumentId, this.reason); // whole position
}

class AgentPlan {
  final List<PlannedBuy> buys;
  final List<PlannedSell> sells;
  final List<AgentCand> shortlist; // what the AI may choose from
  const AgentPlan(this.buys, this.sells, this.shortlist);
}

class AgentOrder {
  final int instrumentId;
  final String side;
  final int units4;
  final int priceE4;
  final int feesPaise;
  final String reason;
  const AgentOrder(this.instrumentId, this.side, this.units4, this.priceE4, this.feesPaise, this.reason);
}

String _pc(double x) => '${x >= 0 ? '+' : ''}${(x * 100).toStringAsFixed(1)}%';

/// Weekly agent rebalances on the first trading day of the week.
bool isFirstTradingDayOfWeek(DateTime day, bool Function(DateTime) isTradingDay) {
  for (var d = day.subtract(const Duration(days: 1)); d.weekday < day.weekday && d.weekday >= DateTime.monday;
      d = d.subtract(const Duration(days: 1))) {
    if (isTradingDay(d)) return false;
  }
  return true;
}

/// Trading days left in [day]'s month, including [day].
int tradingDaysLeft(DateTime day, bool Function(DateTime) isTradingDay) {
  var n = 0;
  for (var d = day; d.month == day.month; d = d.add(const Duration(days: 1))) {
    if (isTradingDay(d)) n++;
  }
  return max(1, n);
}

double _score(AgentKind k, AgentCand c) => switch (k) {
      AgentKind.daily => 1.0 * c.news1 + 0.4 * c.news7 + 8 * c.ret5 + 15 * c.ret1,
      AgentKind.weekly => 6 * c.ret20 + 0.5 * c.news7 + (c.momentum ?? 0.5) + 0.5 * (c.growth ?? 0.5),
      AgentKind.monthly => (c.advisorScore ?? 0) + 0.15 * c.news7.clamp(-2, 2),
    };

bool _eligible(AgentKind k, AgentCand c) => switch (k) {
      // Fresh positive catalyst or a strong day, inside an uptrend, no bad news this week.
      AgentKind.daily => (c.news1 > 0 || c.ret1 > 0.01) && c.ret20 > 0 && c.news7 >= 0,
      AgentKind.weekly => c.ret20 > 0.02 && c.news7 >= 0 && (c.advisorScore != null || c.news7 > 0.5),
      AgentKind.monthly => c.advisorScore != null && c.news7 > -1,
    };

String _why(AgentKind k, AgentCand c) => switch (k) {
      AgentKind.daily => [
          if (c.news1 > 0) 'good news today${c.headline == null ? '' : ': ${c.headline}'}',
          'up ${_pc(c.ret1)} today, ${_pc(c.ret5)} in 5 days',
        ].join('; '),
      AgentKind.weekly => [
          '1-month trend ${_pc(c.ret20)}',
          if (c.news7 > 0) 'news this week +${c.news7.toStringAsFixed(1)}',
          if (c.growth != null) 'growth rank ${(c.growth! * 100).round()}',
        ].join('; '),
      AgentKind.monthly => [
          'Advisor score ${((c.advisorScore ?? 0) * 100).round()}',
          if (c.quality != null) 'quality ${(c.quality! * 100).round()}',
          if (c.growth != null) 'growth ${(c.growth! * 100).round()}',
          if (c.news7 != 0) 'news ${c.news7 > 0 ? '+' : ''}${c.news7.toStringAsFixed(1)}',
        ].join(', '),
    };

/// The rule plan: exits first, then new buys sized to the day's limits.
AgentPlan propose(AgentKind k, AgentBook book, Map<int, AgentCand> cands, DateTime today,
    {required bool rebalanceDay, required int tradingDaysLeftInMonth}) {
  final cfg = agentConfigs[k]!;
  final sells = <PlannedSell>[];
  for (final p in book.positions.values) {
    final c = cands[p.instrumentId];
    if (c == null || p.costPaise == 0) continue;
    final pnl = valuePaise(p.units4, c.priceE4) / p.costPaise - 1;
    final days = today.difference(p.firstBuy).inDays;
    String? why;
    if (pnl <= -cfg.stopBps / 10000) {
      why = 'stop-loss: ${_pc(pnl)} since buying';
    } else if (cfg.targetBps != null && pnl >= cfg.targetBps! / 10000) {
      why = 'took profit: ${_pc(pnl)}';
    } else if (k == AgentKind.daily && c.news1 <= -0.5) {
      why = 'bad news today${c.headline == null ? '' : ': ${c.headline}'}';
    } else if (k != AgentKind.daily && c.news7 <= (k == AgentKind.monthly ? -2 : -1)) {
      why = 'repeated bad news this week (${c.news7.toStringAsFixed(1)})${c.headline == null ? '' : ': ${c.headline}'}';
    } else if (cfg.maxHoldDays != null && days >= cfg.maxHoldDays!) {
      why = 'held $days days, time to recycle (${_pc(pnl)})';
    } else if (k == AgentKind.weekly && rebalanceDay && c.ret20 < 0) {
      why = 'weekly review: 1-month trend turned ${_pc(c.ret20)}';
    } else if (k == AgentKind.monthly && c.advisorScore == null && pnl < -0.1) {
      why = 'no longer passes the quality checks (${_pc(pnl)})';
    }
    if (why != null) sells.add(PlannedSell(p.instrumentId, why));
  }

  final sold = {for (final s in sells) s.instrumentId};
  final ranked = [
    for (final c in cands.values)
      if (_eligible(k, c) && !sold.contains(c.instrumentId)) c,
  ]..sort((a, b) => _score(k, b).compareTo(_score(k, a)));
  final shortlist = ranked.take(15).toList();

  final buys = <PlannedBuy>[];
  final buyDay = k != AgentKind.weekly || rebalanceDay;
  if (buyDay) {
    final month = fmtDay(today).substring(0, 7);
    var budget = min(book.monthRoom(month), book.cashPaise);
    // Monthly spreads the month's room across the trading days left.
    if (k == AgentKind.monthly) budget = min(budget, (book.monthRoom(month) / tradingDaysLeftInMonth).ceil());
    final held = book.positions.length - sold.length;
    var slots = max(0, cfg.maxHoldings - held);
    for (final c in shortlist) {
      if (budget < 500000) break; // under Rs 5,000: not worth a trade
      final owned = book.positions.containsKey(c.instrumentId);
      if (!owned && slots == 0) continue;
      if (owned && k != AgentKind.monthly) continue; // traders do not average up/down
      final amount = min(budget, agentPerStockDayPaise);
      buys.add(PlannedBuy(c.instrumentId, amount, _why(k, c)));
      budget -= amount;
      if (!owned) slots--;
    }
  }
  return AgentPlan(buys, sells, shortlist);
}

/// Hard limits, whatever the plan says: whole shares, Rs 50,000 per stock per day,
/// Rs 4 lakh net new money per calendar month, never more than the cash, sells only
/// what is held. Sells run first so their cash and month room can fund the buys.
List<AgentOrder> enforce(AgentBook book, AgentPlan plan, Map<int, AgentCand> cands, DateTime today) {
  final date = fmtDay(today);
  final month = date.substring(0, 7);
  final out = <AgentOrder>[];
  var cash = book.cashPaise;
  var room = book.monthRoom(month);
  for (final s in plan.sells) {
    final p = book.positions[s.instrumentId];
    final c = cands[s.instrumentId];
    if (p == null || c == null || p.units4 == 0) continue;
    final v = valuePaise(p.units4, c.priceE4);
    final fees = mulDiv(v, agentCostBps, 10000);
    out.add(AgentOrder(s.instrumentId, 'sell', p.units4, c.priceE4, fees, s.reason));
    cash += v - fees;
    room = min(agentMonthlyLimitPaise, room + v);
  }
  final todayBuys = <int, int>{};
  for (final b in plan.buys) {
    final c = cands[b.instrumentId];
    if (c == null || c.priceE4 <= 0) continue;
    final dayLeft = agentPerStockDayPaise - book.boughtOn(date, b.instrumentId) - (todayBuys[b.instrumentId] ?? 0);
    var amount = [b.amountPaise, dayLeft, room, cash - mulDiv(cash, agentCostBps, 10000)].reduce(min);
    final shares = amount <= 0 ? 0 : amount * 100 ~/ c.priceE4; // whole shares: paise*1e4 / priceE4*100
    if (shares <= 0) continue;
    final units4 = shares * unitScale;
    final v = valuePaise(units4, c.priceE4);
    final fees = mulDiv(v, agentCostBps, 10000);
    if (v + fees > cash || v > room || v > dayLeft) continue;
    out.add(AgentOrder(b.instrumentId, 'buy', units4, c.priceE4, fees, b.reason));
    cash -= v + fees;
    room -= v;
    todayBuys[b.instrumentId] = (todayBuys[b.instrumentId] ?? 0) + v;
  }
  return out;
}
