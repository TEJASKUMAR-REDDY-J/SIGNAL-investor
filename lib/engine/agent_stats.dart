import 'dart:math';

import 'lots.dart';
import 'money.dart';

/// One closed round trip (a sale matched against average cost).
class ClosedTrade {
  final int instrumentId;
  final String buyReason;
  final String sellReason;
  final DateTime bought, sold;
  final int pnlPaise;
  final double pnlPct;
  const ClosedTrade(this.instrumentId, this.buyReason, this.sellReason, this.bought, this.sold, this.pnlPaise, this.pnlPct);
  int get days => sold.difference(bought).inDays;
}

/// Which kind of signal a buy came from, read off its reason.
String signalOf(String reason) {
  final r = reason.toLowerCase();
  if (r.contains('news') || r.contains('launch') || r.contains('order') || r.contains('result')) return 'news';
  if (r.contains('trend') || r.contains('momentum') || r.contains('up ') || r.contains('rsi') || r.contains('macd') || r.contains('breakout')) {
    return 'momentum';
  }
  if (r.contains('advisor') || r.contains('quality') || r.contains('growth') || r.contains('roe') || r.contains('value')) return 'quality';
  return 'other';
}

/// The agent's scorecard: return, risk and what has worked.
class AgentStats {
  final double totalReturn;
  final double? niftyReturn;
  final double? sharpe; // annualised, from one value per run day
  final double maxDrawdown;
  final int buys, sells;
  final List<ClosedTrade> closed;
  const AgentStats(this.totalReturn, this.niftyReturn, this.sharpe, this.maxDrawdown, this.buys, this.sells, this.closed);

  double? get alpha => niftyReturn == null ? null : totalReturn - niftyReturn!;
  double? get winRate => closed.isEmpty ? null : closed.where((c) => c.pnlPaise > 0).length / closed.length;
  double? get avgWinPct {
    final w = closed.where((c) => c.pnlPaise > 0);
    return w.isEmpty ? null : w.fold(0.0, (a, c) => a + c.pnlPct) / w.length;
  }

  double? get avgLossPct {
    final l = closed.where((c) => c.pnlPaise <= 0);
    return l.isEmpty ? null : l.fold(0.0, (a, c) => a + c.pnlPct) / l.length;
  }

  double? get avgHoldDays => closed.isEmpty ? null : closed.fold(0, (a, c) => a + c.days) / closed.length;

  /// Wins and total closed trades per signal type.
  Map<String, (int, int)> get bySignal {
    final out = <String, (int, int)>{};
    for (final c in closed) {
      final s = signalOf(c.buyReason);
      final (w, n) = out[s] ?? (0, 0);
      out[s] = (w + (c.pnlPaise > 0 ? 1 : 0), n + 1);
    }
    return out;
  }

  /// Compact track record for the agent's own prompt (memory of outcomes).
  String get summary {
    String p(double x) => '${x >= 0 ? '+' : ''}${(x * 100).toStringAsFixed(1)}%';
    final parts = <String>[
      'return ${p(totalReturn)}${niftyReturn == null ? '' : ' vs NIFTY ${p(niftyReturn!)}'}',
      if (sharpe != null) 'Sharpe ${sharpe!.toStringAsFixed(2)}',
      'max drawdown ${(maxDrawdown * 100).toStringAsFixed(1)}%',
      '$buys buys, ${closed.length} closed',
      if (winRate != null) 'win rate ${(winRate! * 100).round()}%',
      if (avgWinPct != null) 'avg win ${p(avgWinPct!)}',
      if (avgLossPct != null) 'avg loss ${p(avgLossPct!)}',
      for (final e in bySignal.entries) '${e.key} signals ${e.value.$1}/${e.value.$2} wins',
    ];
    return parts.join('; ');
  }
}

/// [runValues]: (date, value after the run), oldest first. [trades]: the agent's
/// log, oldest first. [niftyAt]: index close on or before a date.
AgentStats agentStats({
  required int startCashPaise,
  required List<(String, int)> runValues,
  required List<(String date, String side, int id, int units4, int price4, int fees, String reason)> trades,
  double? Function(DateTime)? niftyAt,
}) {
  final values = [startCashPaise, for (final r in runValues) r.$2];
  final total = values.last / startCashPaise - 1;
  double? sharpe;
  if (values.length >= 6) {
    final r = [for (var i = 1; i < values.length; i++) values[i] / values[i - 1] - 1];
    final m = r.reduce((a, b) => a + b) / r.length;
    final sd = sqrt(r.fold(0.0, (a, e) => a + (e - m) * (e - m)) / (r.length - 1));
    if (sd > 0) sharpe = m / sd * sqrt(252);
  }
  var peak = values.first, dd = 0.0;
  for (final v in values) {
    peak = max(peak, v);
    dd = max(dd, 1 - v / peak);
  }
  double? nifty;
  if (niftyAt != null && runValues.isNotEmpty) {
    final a = niftyAt(parseDay(runValues.first.$1).subtract(const Duration(days: 1)));
    final b = niftyAt(parseDay(runValues.last.$1));
    if (a != null && b != null && a > 0) nifty = b / a - 1;
  }
  // Average-cost round trips.
  final units = <int, int>{}, cost = <int, int>{};
  final firstBuy = <int, DateTime>{}, reason = <int, String>{};
  final closed = <ClosedTrade>[];
  var buys = 0, sells = 0;
  for (final (date, side, id, u, p, fees, why) in trades) {
    final v = valuePaise(u, p);
    if (side == 'buy') {
      buys++;
      if ((units[id] ?? 0) == 0) {
        firstBuy[id] = parseDay(date);
        reason[id] = why;
      }
      units[id] = (units[id] ?? 0) + u;
      cost[id] = (cost[id] ?? 0) + v + fees;
    } else {
      sells++;
      final have = units[id] ?? 0;
      if (have == 0) continue;
      final q = min(u, have);
      final c = mulDiv(cost[id]!, q, have);
      final pnl = v - fees - c;
      closed.add(ClosedTrade(id, reason[id] ?? '', why, firstBuy[id] ?? parseDay(date), parseDay(date), pnl, c == 0 ? 0 : pnl / c));
      units[id] = have - q;
      cost[id] = cost[id]! - c;
    }
  }
  return AgentStats(total, nifty, sharpe, dd, buys, sells, closed);
}
