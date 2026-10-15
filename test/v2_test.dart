import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/engine/fund_rank.dart';
import 'package:signal_investor/engine/news_score.dart';
import 'package:signal_investor/engine/scoring.dart';
import 'package:signal_investor/engine/valuation.dart';
import 'package:signal_investor/pipeline/background.dart';
import 'package:signal_investor/pipeline/instruments.dart';
import 'package:signal_investor/pipeline/live.dart';
import 'package:signal_investor/sources/amfi.dart';
import 'package:signal_investor/sources/mfapi.dart';
import 'package:signal_investor/sources/net.dart';
import 'package:signal_investor/sources/yahoo.dart';

List<Bar> _series(double start, double drift, {int days = 800}) => [
      for (var i = 0; i < days; i++)
        Bar(DateTime.utc(2023, 8, 1).add(Duration(days: i)), (start * 10000 * (1 + drift * i)).round()),
    ];

void main() {
  group('live quotes (Yahoo spark)', () {
    test('parses real spark response: price, previous close, IST day, change', () {
      final q = parseSpark(File('test/fixtures/yahoo_spark.json').readAsStringSync());
      expect(q.map((x) => x.ticker), containsAll(['^NSEI', '^BSESN', '^NSEBANK', 'TCS.NS']));
      final tcs = q.firstWhere((x) => x.ticker == 'TCS.NS');
      expect(tcs.priceE4, 23077000); // 2307.70, rounded to paise
      expect(tcs.prevCloseE4, 22693000);
      expect(tcs.day, '2026-10-14');
      expect(tcs.changeBps, 169);
      expect(() => parseSpark('{"x":1}'), throwsFormatException);
    });

    test('batches 20 tickers per request and stores the price as today\'s close', () async {
      final m = MarketDb(NativeDatabase.memory());
      final calls = <int>[];
      final net = Net(client: MockClient((r) async {
        final syms = r.url.queryParameters['symbols']!.split(',');
        calls.add(syms.length);
        return http.Response(
            '{"spark":{"result":[${syms.map((s) => '{"symbol":"$s","response":[{"meta":{"regularMarketPrice":101.5,"chartPreviousClose":100,"regularMarketTime":1791966626}}]}').join(',')}]}}',
            200);
      }));
      final idx = await ensureIndices(m);
      expect(idx.map((i) => i.name), ['NIFTY 50', 'SENSEX', 'NIFTY BANK']);
      expect((await ensureIndices(m)).map((i) => i.id), idx.map((i) => i.id)); // idempotent
      final stocks = [for (var k = 0; k < 22; k++) await ensureStock(m, 'S$k', 'Stock $k')];
      final all = await m.select(m.instruments).get();
      final q = await liveQuotes(m, net, all);
      expect(calls, [20, 5]);
      expect(q.length, 25);
      final row = await (m.select(m.prices)..where((p) => p.instrumentId.equals(stocks.first))).getSingle();
      expect((row.date, row.closeE4, row.source), ('2026-10-14', 1015000, 'yahoo'));
      await m.close();
    });
  });

  group('growth fundamentals', () {
    test('quoteSummary growth and context fields are parsed', () {
      final f = parseFundamentals('{"quoteSummary":{"result":[{"financialData":{"revenueGrowth":{"raw":0.112},"earningsGrowth":{"raw":0.15},'
          '"operatingMargins":{"raw":0.24}},"summaryDetail":{"fiftyTwoWeekHigh":{"raw":3350},"fiftyTwoWeekLow":{"raw":1976.8},'
          '"dividendYield":{"raw":0.0212}},"defaultKeyStatistics":{"forwardPE":{"raw":14.3},"beta":{"raw":0.18}}}]}}');
      expect(f['revenueGrowth'], 0.112);
      expect(f['earningsGrowth'], 0.15);
      expect(f['high52'], 3350);
      expect(f['forwardPe'], 14.3);
      expect(f['roe'], isNull);
    });

    test('ranking rewards growth; missing growth sits in the middle, not the bottom', () {
      ScanInput s(String sym, {double? rev, double? earn}) => ScanInput(
          sym,
          sym,
          'X',
          {'roe': 0.2, 'debtToEquity': 30, 'freeCashflow': 1e9, 'marketCap': 5e11, 'pe': 20, 'revenueGrowth': rev, 'earningsGrowth': earn},
          _series(100, 0.0005),
          DateTime.utc(2026, 10, 9));
      final r = rankUniverse([s('SLOW', rev: 0.01, earn: -0.05), s('FAST', rev: 0.3, earn: 0.4), s('NONE')]);
      expect(r.map((c) => c.input.symbol), ['FAST', 'NONE', 'SLOW']);
      expect(r.first.growth, 1.0);
      expect(r[1].growth, 0.5);
      expect(r.first.reasons.any((x) => x.startsWith('Growth: sales +30%, profit +40%')), isTrue);
      expect(r.first.inputs['revenueGrowth'], 0.3);
    });
  });

  group('funds', () {
    test('AMFI NAVAll: only direct growth plans in advisor categories', () {
      final rows = parseNavAll(File('test/fixtures/amfi_navall.txt').readAsStringSync());
      expect(rows, isNotEmpty);
      expect(rows.every((r) => fundCategories.contains(r.category)), isTrue); // liquid funds dropped
      final pp = rows.where((r) => r.code == '122639').single;
      expect((pp.category, pp.navE4), ('Flexi Cap Fund', 895841));
      expect(rows.any((r) => r.code == '122640'), isFalse); // regular plan
      expect(rows.any((r) => r.code == '153964'), isFalse); // IDCW option
      expect(rows.map((r) => r.category).toSet(), {'Flexi Cap Fund', 'Small Cap Fund'});
    });

    test('metrics from a real 5-year NAV window', () {
      final navs = parseMfapi(File('test/fixtures/mfapi_122639_5y.json').readAsStringSync()).navs;
      final m = fundMetrics('122639', 'PPFAS', 'Flexi Cap Fund', navs)!;
      expect(m.cagr1, isNotNull);
      expect(m.cagr3, isNotNull);
      expect(m.cagr3!, inInclusiveRange(-0.5, 1.0));
      expect(m.maxDrawdown, inInclusiveRange(0.0, 1.0));
      expect(m.asOf, navs.last.$1);
      expect(FundMetrics.fromJson('122639', m.toJson()).cagr3, m.cagr3);
    });

    test('CAGR and drawdown arithmetic; too-young funds have no 3-year figure', () {
      // Doubles in 3 years with a 50% fall in the middle.
      final navs = <(String, int)>[];
      var d = DateTime.utc(2023, 10, 14);
      while (!d.isAfter(DateTime.utc(2026, 10, 14))) {
        final t = d.difference(DateTime.utc(2023, 10, 14)).inDays / 1096;
        final v = t < 0.5 ? 1 + t : (t < 0.6 ? 0.75 : 0.75 + (t - 0.6) / 0.4 * 1.25);
        navs.add(('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}', (v * 100000).round()));
        d = d.add(const Duration(days: 1));
      }
      final m = fundMetrics('1', 'X', 'Mid Cap Fund', navs)!;
      expect(m.cagr3!, closeTo(0.26, 0.01)); // 2x in 3 years = 26% a year
      expect(m.cagr5, isNull);
      expect(m.maxDrawdown, closeTo(0.5, 0.01));
      expect(fundMetrics('1', 'X', 'Mid Cap Fund', navs.sublist(navs.length - 400))!.cagr3, isNull);
    });

    test('ranking within category: growth and smaller falls win', () {
      FundMetrics f(String c, double g3, double dd, [String cat = 'Mid Cap Fund']) => FundMetrics(c, c, cat, 0.1, g3, g3, dd, '2026-10-13');
      final r = rankFunds([
        f('A', 0.20, 0.30),
        f('B', 0.25, 0.20),
        f('C', 0.10, 0.40),
        f('L', 0.12, 0.15, 'Large Cap Fund'),
        FundMetrics('YOUNG', 'Y', 'Mid Cap Fund', 0.5, null, null, 0.1, '2026-10-13'),
      ]);
      expect(r['Mid Cap Fund']!.map((x) => x.m.code), ['B', 'A', 'C']);
      expect(r['Large Cap Fund']!.single.m.code, 'L');
      expect(r['Mid Cap Fund']!.first.reasons.first, '3 yr 25.0% a year · 5 yr 25.0% a year');
    });
  });

  group('news pulse', () {
    final now = DateTime.utc(2026, 10, 14, 10);
    NewsItem n(int inst, String label, int hoursAgo, [double conf = 1]) => NewsItem(
        urlHash: '$inst$label$hoursAgo', url: 'https://x.test', title: 't$hoursAgo', publisher: 'P',
        publishedAt: now.subtract(Duration(hours: hoursAgo)), instrumentId: inst, label: label, confidence: conf);

    test('points: +1 good, -1 bad, confidence-weighted, 7 days, strongest first', () {
      final s = newsScores([
        n(1, 'positive', 2), n(1, 'positive', 5, 0.5), n(1, 'negative', 9),
        n(2, 'negative', 1), n(2, 'negative', 3), n(2, 'neutral', 4),
        n(3, 'positive', 24 * 8), // older than 7 days
      ], now);
      expect(s.map((x) => x.instrumentId), [2, 1]);
      expect(s.first.points, -2.0);
      expect(s.first.label, 'negative');
      expect((s[1].points, s[1].positive, s[1].negative, s[1].total), (0.5, 2, 1, 3));
      expect(s[1].latest!.title, 't2');
    });

    test('digest line, or nothing when no labelled news', () {
      expect(digestLine(const [], const {}), isNull);
      final s = newsScores([n(1, 'positive', 2), n(2, 'negative', 1)], now);
      expect(digestLine(s, {1: 'TCS', 2: 'Infosys'}), startsWith('1 positive, 1 negative across 2 companies. '));
    });

    test('digest slots: 08:00, 11:00 and 16:00 IST; due once per slot', () {
      // 06:00 IST -> yesterday 16:00 IST
      expect(lastSlotUtc(DateTime.utc(2026, 10, 14, 0, 30)), DateTime.utc(2026, 10, 13, 10, 30));
      // 09:00 IST -> 08:00 IST
      expect(lastSlotUtc(DateTime.utc(2026, 10, 14, 3, 30)), DateTime.utc(2026, 10, 14, 2, 30));
      // exactly 11:00 IST -> that slot
      expect(lastSlotUtc(DateTime.utc(2026, 10, 14, 5, 30)), DateTime.utc(2026, 10, 14, 5, 30));
      // 17:00 IST -> 16:00 IST
      expect(lastSlotUtc(DateTime.utc(2026, 10, 14, 11, 30)), DateTime.utc(2026, 10, 14, 10, 30));
      final now = DateTime.utc(2026, 10, 14, 6); // 11:30 IST
      expect(digestDue(now, null), isTrue);
      expect(digestDue(now, DateTime.utc(2026, 10, 14, 3)), isTrue); // last ran 08:30, 11:00 slot since
      expect(digestDue(now, DateTime.utc(2026, 10, 14, 5, 40)), isFalse); // already ran after 11:00
    });
  });

  group('trade price autofill', () {
    test('stored close for a past day, NAV window fetch for funds, offline falls back', () async {
      final m = MarketDb(NativeDatabase.memory());
      var fetches = 0;
      final net = Net(client: MockClient((r) async {
        fetches++;
        if (r.url.host == 'api.mfapi.in') {
          expect(r.url.queryParameters['endDate'], '2026-10-12');
          return http.Response('{"meta":{"scheme_name":"F"},"data":[{"date":"12-10-2026","nav":"89.58410"},{"date":"09-10-2026","nav":"88.00000"}]}', 200);
        }
        return http.Response('', 500);
      }));
      final sid = await ensureStock(m, 'TCS', 'TCS');
      await m.putPrices(sid, 'yahoo', [('2026-10-09', 22000000), ('2026-10-12', 22500000)]);
      final stock = await (m.select(m.instruments)..where((i) => i.id.equals(sid))).getSingle();
      expect(await priceForDay(m, net, stock, DateTime.utc(2026, 10, 12)), (DateTime.utc(2026, 10, 12), 22500000));
      expect(fetches, 0); // exact day stored: no network
      // Missing day, network down: best earlier price.
      expect(await priceForDay(m, net, stock, DateTime.utc(2026, 10, 10)), (DateTime.utc(2026, 10, 9), 22000000));
      final fid = await ensureFund(m, '122639', 'PPFAS');
      final fund = await (m.select(m.instruments)..where((i) => i.id.equals(fid))).getSingle();
      expect(await priceForDay(m, net, fund, DateTime.utc(2026, 10, 12)), (DateTime.utc(2026, 10, 12), 895841));
      expect(await ensureFund(m, '122639', 'again'), fid);
      await m.close();
    });
  });

  test('watchlist: add, remove, audited; profile v4', () async {
    final db = ProfileDb(NativeDatabase.memory());
    await db.setWatched(7, true);
    await db.setWatched(7, true);
    expect((await db.select(db.watchlist).get()).single.instrumentId, 7);
    await db.setWatched(7, false);
    expect(await db.select(db.watchlist).get(), isEmpty);
    expect((await db.select(db.auditLog).get()).map((a) => a.detail), ['watch 7 true', 'watch 7 true', 'watch 7 false']);
    expect(db.schemaVersion, 4);
    await db.into(db.watchlist).insert(WatchlistCompanion.insert(instrumentId: const Value(3), addedAt: DateTime(2026)));
    await db.close();
  });
}
