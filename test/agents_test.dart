import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/engine/agents.dart';
import 'package:signal_investor/engine/calendar.dart';
import 'package:signal_investor/pipeline/agents_run.dart';
import 'package:signal_investor/sources/groq.dart';
import 'package:signal_investor/sources/net.dart';
import 'package:signal_investor/sources/yahoo.dart';

const rs = 100; // paise per rupee
AgentCand cand(int id, double price,
        {List<double>? closes, double? adv = 0.7, double n1 = 0, double n7 = 0, double? growth = 0.6, double? mom = 0.6}) =>
    AgentCand(id, 'S$id', 'Stock $id', (price * 10000).round(),
        [for (final c in closes ?? List.filled(21, price)) (c * 10000).round()],
        advisorScore: adv, quality: 0.6, growth: growth, momentum: mom, news1: n1, news7: n7);

void main() {
  final today = DateTime.utc(2026, 10, 14); // Wednesday, trading day

  group('book', () {
    test('cash, average cost, booked P&L, month net and per-day buys', () {
      final b = AgentBook([
        ('2026-10-13', 'buy', 1, 100 * 10000, 1000 * 10000, 100 * rs),
        ('2026-10-14', 'buy', 1, 50 * 10000, 1100 * 10000, 55 * rs),
        ('2026-10-14', 'sell', 1, 75 * 10000, 1200 * 10000, 90 * rs),
      ]);
      expect(b.cashPaise, agentStartCashPaise - 100100 * rs - 55055 * rs + 89910 * rs);
      final p = b.positions[1]!;
      expect(p.units4, 75 * 10000);
      expect(p.costPaise, (155155 * rs) ~/ 2); // half the cost left
      expect(b.realizedPaise, 89910 * rs - (155155 * rs) ~/ 2);
      expect(b.monthNet('2026-10'), (100000 + 55000 - 90000) * rs);
      expect(b.boughtOn('2026-10-14', 1), 55000 * rs);
      expect(b.monthRoom('2026-10'), agentMonthlyLimitPaise - 65000 * rs);
    });
  });

  group('hard limits', () {
    test('Rs 50,000 per stock per day, whole shares, monthly room, cash', () {
      final b = AgentBook([('2026-10-14', 'buy', 1, 10 * 10000, 3000 * 10000, 0)]); // Rs 30,000 of S1 already today
      final c = {1: cand(1, 3000), 2: cand(2, 333.33), 3: cand(3, 100)};
      final o = enforce(b, AgentPlan([
        PlannedBuy(1, 50000 * rs, 'x'), // only Rs 20,000 left today -> 6 shares
        PlannedBuy(2, 900000 * rs, 'y'), // capped at Rs 50,000 -> 150 shares
        PlannedBuy(9, 1000 * rs, 'unknown'), // not a candidate
      ], const [], const []), c, today);
      expect(o.map((x) => (x.instrumentId, x.units4 ~/ 10000)), [(1, 6), (2, 150)]);
      for (final x in o) {
        expect(x.units4 % 10000, 0);
        expect(x.feesPaise, closeTo(x.units4 * x.priceE4 / 1000000 * agentCostBps / 10000, 1));
      }
    });

    test('monthly room: Rs 4 lakh net; sales free room first', () {
      final b = AgentBook([
        for (var i = 0; i < 8; i++) ('2026-10-0${i + 1}', 'buy', 10 + i, 500 * 10000, 100 * 10000, 0), // 8 x Rs 50,000 = 4 lakh
      ]);
      final c = {for (var i = 0; i < 8; i++) 10 + i: cand(10 + i, 100), 2: cand(2, 100)};
      expect(enforce(b, AgentPlan([PlannedBuy(2, 50000 * rs, 'x')], const [], const []), c, today), isEmpty);
      final o = enforce(b, AgentPlan([PlannedBuy(2, 50000 * rs, 'x')], [PlannedSell(10, 'stop')], const []), c, today);
      expect(o.map((x) => x.side), ['sell', 'buy']);
      expect(o.last.units4 ~/ 10000, 500);
      // Selling what is not held does nothing.
      expect(enforce(b, AgentPlan(const [], [PlannedSell(99, 'x')], const []), c, today), isEmpty);
    });
  });

  group('rules', () {
    test('daily: stop-loss, take-profit, bad news exits; buys catalysts in uptrends', () {
      final b = AgentBook([
        ('2026-10-12', 'buy', 1, 10 * 10000, 100 * 10000, 0),
        ('2026-10-12', 'buy', 2, 10 * 10000, 100 * 10000, 0),
        ('2026-10-12', 'buy', 3, 10 * 10000, 100 * 10000, 0),
      ]);
      final up = [for (var i = 0; i <= 20; i++) 90.0 + i]; // +22% month, rising
      final c = {
        1: cand(1, 96.5), // -3.5% -> stop
        2: cand(2, 106), // +6% -> target
        3: cand(3, 101, n1: -0.9), // bad news today
        4: cand(4, 110, closes: up, n1: 0.8), // catalyst in an uptrend
        5: cand(5, 110, closes: up.reversed.toList(), n1: 0.8), // downtrend: no
      };
      final p = propose(AgentKind.daily, b, c, today, rebalanceDay: false, tradingDaysLeftInMonth: 12);
      expect(p.sells.map((s) => s.instrumentId), [1, 2, 3]);
      expect(p.sells.first.reason, startsWith('stop-loss'));
      expect(p.buys.map((x) => x.instrumentId), [4]);
      expect(p.buys.single.amountPaise, agentPerStockDayPaise);
    });

    test('weekly buys only on the first trading day of the week', () {
      final up = [for (var i = 0; i <= 20; i++) 90.0 + i];
      final c = {4: cand(4, 110, closes: up)};
      expect(propose(AgentKind.weekly, AgentBook(const []), c, today, rebalanceDay: false, tradingDaysLeftInMonth: 12).buys, isEmpty);
      expect(propose(AgentKind.weekly, AgentBook(const []), c, today, rebalanceDay: true, tradingDaysLeftInMonth: 12).buys, hasLength(1));
      bool td(DateTime d) => d.weekday < 6 && d != DateTime.utc(2026, 10, 12);
      expect(isFirstTradingDayOfWeek(DateTime.utc(2026, 10, 13), td), isTrue); // Monday was a holiday
      expect(isFirstTradingDayOfWeek(DateTime.utc(2026, 10, 14), td), isFalse);
      expect(isFirstTradingDayOfWeek(DateTime.utc(2026, 10, 19), td), isTrue);
    });

    test('monthly spreads the month\'s Rs 4 lakh across the trading days left', () {
      final c = {for (var i = 1; i <= 30; i++) i: cand(i, 100, adv: 0.5 + i / 100)};
      final p = propose(AgentKind.monthly, AgentBook(const []), c, today, rebalanceDay: false, tradingDaysLeftInMonth: 13);
      final total = p.buys.fold(0, (a, b) => a + b.amountPaise);
      expect(total, (agentMonthlyLimitPaise / 13).ceil());
      expect(p.buys.first.instrumentId, 30); // highest advisor score first
      expect(p.buys.every((b) => b.amountPaise <= agentPerStockDayPaise), isTrue);
      expect(tradingDaysLeft(today, (d) => d.weekday < 6), 13); // 14-16, 19-23, 26-30 Oct
      // Fails the filters or bad news: not bought.
      final c2 = {1: cand(1, 100, adv: null), 2: cand(2, 100, n7: -1.5)};
      expect(propose(AgentKind.monthly, AgentBook(const []), c2, today, rebalanceDay: false, tradingDaysLeftInMonth: 13).buys, isEmpty);
    });
  });

  test('AI decision: only shortlisted / held symbols, amounts capped', () {
    final d = validateDecision(
        '{"buys":[{"symbol":"tcs","rupees":90000,"reason":"new deal"},{"symbol":"EVIL","rupees":1000}],'
        '"sells":[{"symbol":"INFY","reason":"bad news"},{"symbol":"NOTHELD"}],"summary":"**Bought** TCS"}',
        {'TCS'},
        {'INFY'},
        50000)!;
    expect(d.buys, [('TCS', 50000, 'new deal')]);
    expect(d.sells, [('INFY', 'bad news')]);
    expect(d.summary, 'Bought TCS');
    expect(validateDecision('nope', {}, {}, 1), isNull);
  });

  test('spark history: closes and yesterday as previous close', () {
    final h = parseSparkHistory(File('test/fixtures/yahoo_spark_1mo.json').readAsStringSync());
    final (q, closes) = h['TCS.NS']!;
    expect(closes, hasLength(21));
    expect(q.prevCloseE4, closes[closes.length - 2]);
    expect(q.priceE4, 23049000);
  });

  test('end to end: data -> rules -> AI -> limits -> log; once per day', () async {
    final m = MarketDb(NativeDatabase.memory());
    nse = MarketCalendar(const {});
    for (final s in ['AAA', 'BBB', 'CCC']) {
      await m.into(m.universe).insert(UniverseCompanion.insert(symbol: s, name: '$s Ltd', nifty500: const Value(true)));
      // Cached advisor data: passes filters, 3 years of rising closes.
      await m.into(m.fundamentals).insert(FundamentalsCompanion.insert(
          symbol: s,
          json: jsonEncode({
            'f': {'roe': 0.25, 'debtToEquity': 10, 'freeCashflow': 1e9, 'marketCap': 1e12, 'pe': 20, 'revenueGrowth': 0.2, 'earningsGrowth': 0.2},
            'c': [for (var i = 0; i < 800; i++) [DateTime.utc(2023, 8, 1).add(Duration(days: i)).toIso8601String().substring(0, 10), 1000000 + i * 1000]],
            'pAt': '2026-10-13T00:00:00.000Z',
          }),
          fetchedAt: DateTime.utc(2026, 10, 13)));
    }
    await m.into(m.agentNotes).insert(AgentNotesCompanion.insert(at: DateTime.utc(2026, 10, 14), body: 'Prefer AAA'));
    String? brief;
    final net = Net(client: MockClient((r) async {
      if (r.url.path.contains('spark')) {
        final syms = r.url.queryParameters['symbols']!.split(',');
        return http.Response(
            jsonEncode({
              'spark': {
                'result': [
                  for (final s in syms)
                    {
                      'symbol': s,
                      'response': [
                        {
                          'meta': {'regularMarketPrice': 125.0, 'chartPreviousClose': 90.0, 'regularMarketTime': 1791966626},
                          'indicators': {
                            'quote': [
                              {'close': [for (var i = 0; i <= 20; i++) 100.0 + i]}
                            ]
                          }
                        }
                      ]
                    }
                ]
              }
            }),
            200);
      }
      if (r.url.host == 'api.groq.com') {
        brief = ((jsonDecode(r.body) as Map)['messages'] as List).last['content'] as String;
        return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': jsonEncode({
                      'buys': [
                        {'symbol': 'AAA', 'rupees': 80000, 'reason': 'owner prefers it, strong growth'},
                        {'symbol': 'ZZZ', 'rupees': 5000, 'reason': 'not allowed'},
                      ],
                      'sells': [],
                      'summary': 'Bought AAA.'
                    })
                  }
                }
              ]
            }),
            200);
      }
      return http.Response('', 404);
    }));
    final now = DateTime.utc(2026, 10, 14, 5, 30); // 11:00 IST
    final lines = await runAgents(m, net, groqKey: 'k', nowUtc: now);
    expect(lines, hasLength(3));
    expect(brief, contains('Prefer AAA'));
    expect(brief, contains('Shortlist'));
    final trades = await m.select(m.agentTrades).get();
    expect(trades, isNotEmpty);
    for (final k in AgentKind.values) {
      final mine = trades.where((t) => t.agent == k.name).toList();
      // The AI asked for Rs 80,000 of AAA: capped at Rs 50,000; ZZZ ignored.
      expect(mine.map((t) => t.instrumentId).toSet().length, 1, reason: k.name);
      expect(mine.every((t) => t.unitsE4 * t.priceE4 ~/ 1000000 <= 5000000), isTrue);
      expect(mine.single.reason, 'owner prefers it, strong growth');
    }
    final runs = await m.select(m.agentRuns).get();
    expect(runs.map((r) => r.agent).toSet(), {'daily', 'weekly', 'monthly'});
    expect(runs.every((r) => r.ai && r.summary == 'Bought AAA.'), isTrue);
    // Same day again: nothing.
    expect(await runAgents(m, net, groqKey: 'k', nowUtc: now.add(const Duration(hours: 2))), isEmpty);
    // Before 09:45 IST or on a weekend: no trading.
    expect(agentsCanTrade(DateTime.utc(2026, 10, 15, 3, 0)), isFalse); // 08:30 IST
    expect(agentsCanTrade(DateTime.utc(2026, 10, 17, 6, 0)), isFalse); // Saturday
    await m.close();
  });
}
