import 'dart:math';

import 'indicators.dart';

/// The market's mood, from NIFTY's trend, India VIX and breadth. It scales how
/// much new money the agents put in: trend-following and volatility filters cut
/// drawdowns in crashes (Faber 2007; Barroso and Santa-Clara 2015).
class MarketRegime {
  final String label; // Risk-on | Neutral | Risk-off
  final double budgetScale; // multiplies the day's buying budget
  final double? niftyVs200; // NIFTY vs its 200-day average, 0.05 = 5% above
  final double? vix;
  final double breadth; // share of tracked stocks above their 50-day average
  final List<String> reasons;
  const MarketRegime(this.label, this.budgetScale, this.niftyVs200, this.vix, this.breadth, this.reasons);

  static const unknown = MarketRegime('Neutral', 0.7, null, null, 0.5, ['market data unavailable']);

  String get line =>
      '$label${niftyVs200 == null ? '' : ' · NIFTY ${niftyVs200! >= 0 ? '+' : ''}${(niftyVs200! * 100).toStringAsFixed(1)}% vs 200-day'}'
      '${vix == null ? '' : ' · VIX ${vix!.toStringAsFixed(1)}'} · ${(breadth * 100).round()}% of stocks above 50-day';

  Map<String, Object?> toJson() => {
        'regime': label,
        'budget_scale': budgetScale,
        'nifty_vs_200dma': niftyVs200 == null ? null : double.parse(niftyVs200!.toStringAsFixed(3)),
        'india_vix': vix,
        'breadth_above_50dma': double.parse(breadth.toStringAsFixed(2)),
        'reasons': reasons,
      };
}

MarketRegime regimeOf({required List<double> nifty, double? vix, required double breadth}) {
  if (nifty.length < 60) return MarketRegime.unknown;
  final t = Technicals.of(nifty);
  var score = 0;
  final why = <String>[];
  if (t.sma200 != null) {
    if (t.price > t.sma200!) {
      score++;
      why.add('NIFTY above its 200-day average');
    } else {
      score--;
      why.add('NIFTY below its 200-day average');
    }
  }
  if (t.sma50 != null && t.price > t.sma50!) {
    score++;
    why.add('NIFTY above its 50-day average');
  }
  if (vix != null) {
    if (vix < 16) {
      score++;
      why.add('calm volatility (VIX ${vix.toStringAsFixed(1)})');
    } else if (vix > 22) {
      score--;
      why.add('fearful volatility (VIX ${vix.toStringAsFixed(1)})');
    }
  }
  if (breadth > 0.55) {
    score++;
    why.add('most stocks rising (breadth ${(breadth * 100).round()}%)');
  } else if (breadth < 0.35) {
    score--;
    why.add('few stocks rising (breadth ${(breadth * 100).round()}%)');
  }
  final (label, scale) = score >= 2 ? ('Risk-on', 1.0) : (score <= 0 ? ('Risk-off', 0.35) : ('Neutral', 0.7));
  return MarketRegime(label, scale, t.sma200 == null ? null : t.price / t.sma200! - 1, vix, breadth, why);
}

/// Volatility-scaled position size: calmer stocks get the full amount, jumpier
/// ones less, aiming each position at about [targetVol] annual volatility.
int volScaled(int amountPaise, double? vol, {double targetVol = 0.25}) {
  if (vol == null || vol <= 0) return amountPaise;
  return (amountPaise * (targetVol / vol).clamp(0.4, 1.0)).round();
}

/// Drawdown brake: after a fall from the agent's peak value, buy less.
/// Returns the multiplier for new buys and a reason.
(double, String?) drawdownBrake(List<int> values) {
  if (values.isEmpty) return (1, null);
  final peak = values.reduce(max);
  final dd = 1 - values.last / peak;
  if (dd > 0.15) return (0, 'down ${(dd * 100).toStringAsFixed(1)}% from its peak: no new buys until it recovers');
  if (dd > 0.08) return (0.5, 'down ${(dd * 100).toStringAsFixed(1)}% from its peak: buying at half size');
  return (1, null);
}
