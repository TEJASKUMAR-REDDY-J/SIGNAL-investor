import 'package:flutter_test/flutter_test.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/engine/lots.dart';
import 'package:signal_investor/engine/portfolio.dart';
import 'package:signal_investor/engine/sell_rules.dart';
import 'package:signal_investor/engine/valuation.dart';

DateTime d(String s) => parseDay(s);

Transaction tx(int id, int inst, String date, String type, int units4, int price4, {int? goal}) => Transaction(
    id: id, instrumentId: inst, date: date, type: type, unitsE4: units4, priceE4: price4,
    feesPaise: 0, goalId: goal, note: '', sttPaise: 0);

const stock = Instrument(id: 1, kind: 'stock', name: 'Pick', aliases: '', nseSymbol: 'PICK', yahooTicker: 'PICK.NS');
const fund = Instrument(id: 2, kind: 'mf', name: 'Index', aliases: '', schemeCode: '1');

PriceBook book(Map<int, List<(String, int)>> rows) {
  final b = PriceBook();
  for (final e in rows.entries) {
    for (final (day, c) in e.value) {
      b.add(e.key, e.key == 2 ? 'mfapi' : 'yahoo', day, c);
    }
  }
  return b..seal();
}

/// Daily closes from [start] for [n] days, all [price], ending on [end] with [last].
List<(String, int)> flat(String start, int n, int price, {int? last}) => [
      for (var i = 0; i < n; i++)
        (fmtDay(d(start).add(Duration(days: i))), i == n - 1 && last != null ? last : price),
    ];

void main() {
  test('rule 1: marked thesis break overrides the 12-month wait, still shows tax', () {
    final p = Portfolio.compute(
      today: d('2026-10-14'),
      instruments: [stock],
      txs: [tx(1, 1, '2026-06-01', 'buy', 100000, 1000000)], // 10 @ 100, short-term
      book: book({1: [('2026-10-13', 1200000), ('2026-10-14', 1200000)]}),
    );
    final s = sellRules(p: p, theses: {
      1: const Thesis(instrumentId: 1, whyBought: 'x', breaksIf: 'auditor', broken: true),
    });
    expect(s.single.rule, 1);
    expect(s.single.overridesWait, isTrue);
    expect(s.single.shortTermWarning, isFalse);
    expect(s.single.taxNowPaise, 4160); // Rs 200 STCG x 20.8% = Rs 41.60
    expect(s.single.inputsJson, contains('"marked":true'));
  });

  test('rule 1: filing keyword match within 30 days', () {
    final p = Portfolio.compute(
      today: d('2026-10-14'),
      instruments: [stock],
      txs: [tx(1, 1, '2024-06-01', 'buy', 100000, 1000000)],
      book: book({1: [('2026-10-14', 1200000)]}),
    );
    Filing f(String date, String subj) =>
        Filing(id: 1, instrumentId: 1, date: date, category: 'General', subject: subj, url: '');
    const th = Thesis(instrumentId: 1, whyBought: 'x', breaksIf: 'auditor, pledge', broken: false);
    expect(sellRules(p: p, theses: {1: th}, filings: {1: [f('2026-10-10', 'Change in Auditor')]}).single.rule, 1);
    expect(sellRules(p: p, theses: {1: th}, filings: {1: [f('2026-08-01', 'Change in Auditor')]}), isEmpty);
    expect(sellRules(p: p, theses: {1: th}, filings: {1: [f('2026-10-10', 'Board meeting')]}), isEmpty);
  });

  test('rule 2: goal under 3 years with tagged equity lots', () {
    final p = Portfolio.compute(
      today: d('2026-10-14'),
      instruments: [fund],
      goals: [const Goal(id: 7, name: 'Masters', targetDate: '2028-08-01', targetPaise: 100000000)],
      txs: [tx(1, 2, '2025-01-10', 'sip', 100000, 1000000, goal: 7), tx(2, 2, '2025-02-10', 'sip', 100000, 1000000)],
      book: book({2: [('2026-10-14', 1100000)]}),
    );
    final s = sellRules(p: p).single;
    expect(s.rule, 2);
    expect(s.unitsE4, 100000); // only the tagged lot
  });

  test('rule 3: satellite above target + 5 points suggests redirecting SIPs, trims largest', () {
    final p = Portfolio.compute(
      today: d('2026-10-14'),
      instruments: [stock, fund],
      prefs: [const HoldingPref(instrumentId: 1, bucket: 'satellite')],
      txs: [tx(1, 1, '2024-01-01', 'buy', 400000, 1000000), tx(2, 2, '2024-01-01', 'buy', 600000, 1000000)],
      book: book({1: [('2026-10-14', 1000000)], 2: [('2026-10-14', 1000000)]}),
    );
    expect(sellRules(p: p, satelliteTargetPct: 35), isEmpty); // 40% vs 35+5: inside band
    final s = sellRules(p: p, satelliteTargetPct: 30).single;
    expect(s.rule, 3);
    expect(s.reason, contains('redirect new SIP money'));
    expect(s.unitsE4, 100000); // 10% of Rs 10,000 at Rs 100
  });

  test('rule 4: Feb-Mar harvest up to the remaining exemption, long-term prefix only', () {
    Portfolio at(String today) => Portfolio.compute(
          today: d(today),
          instruments: [fund],
          txs: [
            tx(1, 2, '2024-01-10', 'buy', 10000000, 1000000), // 1000 @ 100, LT
            tx(2, 2, '2026-01-10', 'buy', 10000000, 2000000), // ST lot
          ],
          book: book({2: [(today, 3000000)]}),
        );
    expect(sellRules(p: at('2026-10-14')), isEmpty); // not Feb/Mar
    final s = sellRules(p: at('2027-02-15')).single;
    expect(s.rule, 4);
    // Gain per unit Rs 200; Rs 1,25,000 room -> 625 units.
    expect(s.unitsE4, 6250000);
    expect(s.taxNowPaise, 0);
  });

  test('rule 5: satellite stock below 200-day average AND 25% under peak', () {
    final hist = [...flat('2025-10-01', 300, 2000000), ('2026-07-28', 1400000), ('2026-07-29', 1400000)];
    Portfolio p(String bucket, List<(String, int)> rows) => Portfolio.compute(
          today: d('2026-07-29'),
          instruments: [stock],
          prefs: [HoldingPref(instrumentId: 1, bucket: bucket)],
          txs: [tx(1, 1, '2025-01-01', 'buy', 100000, 1500000)],
          book: book({1: rows}),
        );
    final all = sellRules(p: p('satellite', hist));
    expect(all.map((x) => x.rule), containsAll([3, 5])); // 100% satellite also trips rebalance
    final s = all.firstWhere((x) => x.rule == 5);
    expect(s.inputs['drawdownBps'], 3000);
    expect(sellRules(p: p('core', hist)).where((x) => x.rule == 5), isEmpty); // core never risk-stopped
    final mild = [...flat('2025-10-01', 300, 2000000), ('2026-07-29', 1800000)];
    expect(sellRules(p: p('satellite', mild)).where((x) => x.rule == 5), isEmpty); // only 10% down
  });

  test('no signal when sources disagree or price is missing', () {
    final b = PriceBook()
      ..add(1, 'yahoo', '2026-10-14', 1200000)
      ..add(1, 'nse', '2026-10-14', 1100000) // 9% apart
      ..seal();
    final p = Portfolio.compute(
        today: d('2026-10-14'), instruments: [stock], txs: [tx(1, 1, '2026-06-01', 'buy', 100000, 1000000)], book: b);
    const th = Thesis(instrumentId: 1, whyBought: 'x', breaksIf: '', broken: true);
    expect(p.holdings.single.mismatch, isTrue);
    expect(sellRules(p: p, theses: {1: th}), isEmpty);
  });

  test('short-term warning shows extra tax for rules 3-5', () {
    final p = Portfolio.compute(
      today: d('2026-10-14'),
      instruments: [stock, fund],
      prefs: [const HoldingPref(instrumentId: 1, bucket: 'satellite')],
      txs: [tx(1, 1, '2026-06-01', 'buy', 800000, 1000000), tx(2, 2, '2024-01-01', 'buy', 200000, 1000000)],
      book: book({1: [('2026-10-14', 1500000)], 2: [('2026-10-14', 1000000)]}),
    );
    final s = sellRules(p: p, satelliteTargetPct: 25).single;
    expect(s.rule, 3);
    expect(s.shortTermWarning, isTrue);
    expect(s.waitUntil, d('2027-06-02'));
    expect(s.extraTaxVsWaitPaise, greaterThan(0));
  });
}
