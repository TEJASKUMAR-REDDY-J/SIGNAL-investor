import 'dart:convert';

import '../db/db.dart';
import 'lots.dart';
import 'money.dart';
import 'portfolio.dart';
import 'tax.dart';

/// Bump when any rule's logic or constant changes; stored with every signal.
const sellRuleVersion = 'sell/1 2026-10-14';

// Placeholders from the plan ("backtest first"); edit here only.
const riskStopSmaDays = 200;
const riskStopDrawdownBps = 2500; // 25% below the 1-year peak
const rebalanceBandBps = 500; // satellite more than 5 points above target
const goalEquityDays = 3 * 365;
const filingLookbackDays = 30;

class SellSuggestion {
  final int rule; // 1 thesis, 2 goal, 3 rebalance, 4 harvest, 5 risk stop
  final int instrumentId;
  final String title;
  final String reason;
  final int unitsE4;
  final int priceE4;
  final int taxNowPaise;
  final int extraTaxVsWaitPaise;
  final DateTime? waitUntil;
  final Map<String, Object?> inputs;
  const SellSuggestion(this.rule, this.instrumentId, this.title, this.reason, this.unitsE4, this.priceE4,
      this.taxNowPaise, this.extraTaxVsWaitPaise, this.waitUntil, this.inputs);

  /// Rules 1 and 2 may override the 12-month wait; others warn about it.
  bool get overridesWait => rule == 1 || rule == 2;
  bool get shortTermWarning => !overridesWait && extraTaxVsWaitPaise > 0;
  String get inputsJson => jsonEncode(inputs);
}

const ruleNames = {
  1: 'Thesis break',
  2: 'Goal due',
  3: 'Rebalance',
  4: 'Tax harvest',
  5: 'Risk stop',
};

/// Keywords from a thesis "breaks if" field.
List<String> breakKeywords(String breaksIf) => [
      for (final k in breaksIf.toLowerCase().split(RegExp(r'[,;\n]')))
        if (k.trim().length >= 3) k.trim(),
    ];

List<SellSuggestion> sellRules({
  required Portfolio p,
  Map<int, Thesis> theses = const {},
  Map<int, List<Filing>> filings = const {},
  int satelliteTargetPct = 25,
}) {
  final out = <SellSuggestion>[];
  final today = p.today;

  SellSuggestion? make(int rule, Holding h, int units, String title, String reason, Map<String, Object?> inputs) {
    final price = h.price;
    if (price == null || units <= 0) return null;
    final w = compareWait(
        lots: h.ledger.open, units4: units, price4: price.closeE4, date: today, realizedAll: p.realized);
    return SellSuggestion(rule, h.instrumentId, title, reason, units, price.closeE4, w.now.extraTaxPaise,
        w.extraTaxPaise, w.waitUntil, {
      'instrument': h.name,
      'priceE4': price.closeE4,
      'priceDate': fmtDay(price.day),
      'unitsE4': units,
      ...inputs,
    });
  }

  final usable = [for (final h in p.holdings) if (h.priced && !h.mismatch && !h.stale) h];

  // 1. Thesis break: marked broken, or a recent filing hits a "breaks if" keyword.
  for (final h in usable) {
    final th = theses[h.instrumentId];
    if (th == null) continue;
    final kws = breakKeywords(th.breaksIf);
    final since = today.subtract(const Duration(days: filingLookbackDays));
    final hits = [
      for (final f in filings[h.instrumentId] ?? const <Filing>[])
        if (!parseDay(f.date).isBefore(since))
          for (final k in kws)
            if ('${f.subject} ${f.category}'.toLowerCase().contains(k)) (k, f),
    ];
    if (!th.broken && hits.isEmpty) continue;
    final why = th.broken
        ? 'You marked the thesis as broken.'
        : 'Filing on ${hits.first.$2.date} mentions "${hits.first.$1}", which you listed as a reason to sell.';
    final s = make(1, h, h.ledger.units4, 'Thesis break: ${h.name}', why, {
      'marked': th.broken,
      'keywords': [for (final x in hits) x.$1],
      'filingDates': [for (final x in hits) x.$2.date],
    });
    if (s != null) out.add(s);
  }

  // 2. Goal due: money for a goal under 3 years away still sits in equity.
  for (final g in p.goals.where((g) => g.taggedPaise > 0 && g.daysLeft < goalEquityDays)) {
    for (final h in usable) {
      final units = h.ledger.open.where((l) => l.goalId == g.goal.id).fold(0, (a, l) => a + l.units4);
      if (units == 0) continue;
      final s = make(2, h, units, 'Goal due: ${g.goal.name}',
          '"${g.goal.name}" is ${(g.daysLeft / 30.4).round()} months away. Money for it is safer in debt or liquid funds.', {
        'goal': g.goal.name,
        'goalDate': g.goal.targetDate,
        'daysLeft': g.daysLeft,
      });
      if (s != null) out.add(s);
    }
  }

  // 3. Rebalance: satellite share above target by more than 5 points.
  final total = p.valuePaise;
  if (total > 0) {
    final satBps = p.satellitePaise * 10000 ~/ total;
    final targetBps = satelliteTargetPct * 100;
    if (satBps > targetBps + rebalanceBandBps) {
      final sats = usable.where((h) => h.bucket == 'satellite').toList()
        ..sort((a, b) => b.valuePaise.compareTo(a.valuePaise));
      if (sats.isNotEmpty) {
        final h = sats.first;
        final excess = mulDiv(total, satBps - targetBps, 10000);
        final units = unitsFor(excess, h.price!.closeE4).clamp(0, h.ledger.units4);
        final s = make(3, h, units, 'Rebalance: satellite ${satBps ~/ 100}% vs target $satelliteTargetPct%',
            'First redirect new SIP money to core funds. Trimming ${h.name} is the fallback.', {
          'satelliteBps': satBps,
          'targetBps': targetBps,
          'excessPaise': excess,
        });
        if (s != null) out.add(s);
      }
    }
  }

  // 4. Tax harvest: Feb-Mar, exemption left, long-term lots in gain.
  // FIFO sells the oldest lots first, so only a long-term prefix qualifies.
  var room = p.fyTax.exemptionLeftPaise;
  if ((today.month == 2 || today.month == 3) && room > 0) {
    for (final h in usable) {
      if (room <= 0) break;
      var units = 0, gain = 0;
      for (final l in h.ledger.open) {
        if (!isLongTerm(l.buyDate, today)) break;
        final lotGain = valuePaise(l.units4, h.price!.closeE4) - l.costPaise;
        if (lotGain <= 0) break;
        if (gain + lotGain <= room) {
          units += l.units4;
          gain += lotGain;
        } else {
          final part = mulDiv(l.units4, room - gain, lotGain);
          units += part;
          gain += mulDiv(lotGain, part, l.units4);
          break;
        }
      }
      if (units == 0) continue;
      final s = make(4, h, units, 'Tax harvest: ${h.name}',
          'Sell and rebuy the same day to book ${rupees(gain, decimals: false)} of long-term gain tax-free '
              'and raise your cost base. Exemption resets on 1 April.', {
        'gainPaise': gain,
        'exemptionLeftPaise': room,
      });
      if (s != null) {
        out.add(s);
        room -= gain;
      }
    }
  }

  // 5. Risk stop: satellite stocks below the 200-day average AND 25% under the 1-year peak.
  for (final h in usable.where((h) => h.bucket == 'satellite' && !h.isMf)) {
    final sma = p.book.sma(h.instrumentId, riskStopSmaDays);
    final peak = p.book.peak(h.instrumentId, 365);
    final px = h.price!.closeE4;
    if (sma == null || peak == null) continue;
    final ddBps = (peak - px) * 10000 ~/ peak;
    if (px < sma && ddBps >= riskStopDrawdownBps) {
      final s = make(5, h, h.ledger.units4, 'Risk stop: ${h.name}',
          'Below its 200-day average and ${ddBps ~/ 100}% under its 1-year high. Placeholder thresholds, not backtested.', {
        'smaE4': sma,
        'peakE4': peak,
        'drawdownBps': ddBps,
      });
      if (s != null) out.add(s);
    }
  }
  return out;
}
