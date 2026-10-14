import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/engine/calendar.dart';
import 'package:signal_investor/engine/lots.dart';
import 'package:signal_investor/engine/valuation.dart';
import 'package:signal_investor/pipeline/refresh.dart';
import 'package:signal_investor/sources/mfapi.dart';
import 'package:signal_investor/sources/net.dart';
import 'package:signal_investor/sources/nse.dart';
import 'package:signal_investor/sources/yahoo.dart';

String fx(String name) => File('test/fixtures/$name').readAsStringSync();
DateTime d(String s) => parseDay(s);

/// IST wall clock -> UTC instant.
DateTime ist(int y, int m, int day, int h, [int min = 0]) =>
    DateTime.utc(y, m, day, h, min).subtract(const Duration(hours: 5, minutes: 30));

void main() {
  group('parsers on real captured responses', () {
    test('mfapi', () {
      final r = parseMfapi(fx('mfapi_120716.json'));
      expect(r.schemeName, contains('Nifty 50'));
      expect(r.navs.length, 5);
      expect(r.navs.first.$1.compareTo(r.navs.last.$1), lessThan(0)); // oldest first
      expect(r.navs.last.$2, greaterThan(0));
    });
    test('decimalE4 rounds 5-decimal NAVs half-up and rejects junk', () {
      expect(decimalE4('159.99100'), 1599910);
      expect(decimalE4('10.00005'), 100001);
      expect(decimalE4('1,234.5'), 12345000);
      expect(decimalE4('N.A.'), isNull);
      expect(decimalE4('0'), isNull);
    });
    test('yahoo chart -> IST dates, oldest first', () {
      final r = parseYahooChart(fx('yahoo_tcs_5d.json'));
      expect(r, isNotEmpty);
      expect(r.length, lessThanOrEqualTo(5));
      for (final (day, close) in r) {
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day), isTrue);
        expect(close, greaterThan(0));
      }
      expect(() => parseYahooChart('{"chart":{"result":null}}'), throwsFormatException);
    });
    test('bhavcopy closes for EQ series', () {
      final m = parseBhavcopy(fx('bhav_13102026.csv'));
      expect(m['TCS'], 22693000);
      expect(m.keys, containsAll(['INFY', 'RELIANCE', 'HDFCBANK']));
    });
    test('NIFTY 500 list csv', () {
      final r = parseListCsv(fx('nifty500.csv'));
      expect(r.first.$1, '360ONE');
      expect(r.first.$3, 'Financial Services');
    });
    test('NSE announcements and holidays', () {
      final a = parseAnnouncements(fx('nse_announcements_tcs.json'));
      expect(a, isNotEmpty);
      expect(a.first.subject, isNotEmpty);
      final h = parseHolidays(fx('nse_holidays.json'));
      expect(h.first, ('2026-01-15', 'Municipal Corporation Election - Maharashtra'));
    });
    test('regular vs direct plan names', () {
      expect(isRegularPlan('ABC Flexi Cap Fund - Regular Plan - Growth'), isTrue);
      expect(isRegularPlan('UTI Nifty 50 Index Fund - Direct Plan - Growth Option'), isFalse);
    });
  });

  group('staleness rules (fixed IST times)', () {
    test('stocks: weekday before/after 16:00, weekend, holiday', () {
      // Tue 13 Oct 2026. Last success Mon 12 Oct 16:30 IST.
      final ok = ist(2026, 10, 12, 16, 30);
      expect(stockStale(ok, ist(2026, 10, 13, 10)), isFalse); // before today's close
      expect(stockStale(ok, ist(2026, 10, 13, 16, 1)), isTrue); // today's close passed
      // Weekend: Friday 16:30 success is fresh all Sunday.
      expect(stockStale(ist(2026, 10, 16, 16, 30), ist(2026, 10, 18, 20)), isFalse);
      // Holiday Tue 20 Oct (Dussehra): Monday's close still the latest at 18:00.
      expect(stockStale(ist(2026, 10, 19, 16, 10), ist(2026, 10, 20, 18)), isFalse);
      expect(stockStale(null, ist(2026, 10, 20, 18)), isTrue);
    });
    test('MF NAV: behind last trading day AND last attempt > 3h', () {
      final now = ist(2026, 10, 14, 22); // Wed night
      expect(navStale('2026-10-13', ist(2026, 10, 14, 17), now), isTrue);
      expect(navStale('2026-10-13', ist(2026, 10, 14, 20), now), isFalse); // tried 2h ago
      expect(navStale('2026-10-14', null, now), isFalse);
      // Saturday: Friday NAV is current.
      expect(navStale('2026-10-16', null, ist(2026, 10, 17, 12)), isFalse);
    });
    test('feeds 3h, full refresh 30 min', () {
      final now = DateTime.utc(2026, 10, 14, 6);
      expect(feedStale(now.subtract(const Duration(hours: 2)), now), isFalse);
      expect(feedStale(now.subtract(const Duration(hours: 4)), now), isTrue);
      expect(fullRefreshDue(now.subtract(const Duration(minutes: 29)), now), isFalse);
      expect(fullRefreshDue(now.subtract(const Duration(minutes: 30)), now), isTrue);
    });
  });

  group('network rules', () {
    test('429 backs the source off for 10 minutes; https only', () async {
      var calls = 0;
      var clock = DateTime.utc(2026, 10, 14, 6);
      final net = Net(client: MockClient((_) async {
        calls++;
        return http.Response('Too Many Requests', 429);
      }), now: () => clock);
      await expectLater(net.get('yahoo', Uri.parse('https://x.test/a')), throwsA(isA<FetchError>()));
      await expectLater(net.get('yahoo', Uri.parse('https://x.test/a')), throwsA(isA<FetchError>()));
      expect(calls, 1); // second call never hit the network
      clock = clock.add(const Duration(minutes: 11));
      await expectLater(net.get('yahoo', Uri.parse('https://x.test/a')), throwsA(isA<FetchError>()));
      expect(calls, 2);
      await expectLater(net.get('x', Uri.parse('http://x.test/a')), throwsA(isA<FetchError>()));
    });
    test('one retry on 5xx, then success', () async {
      var calls = 0;
      final net = Net(client: MockClient((_) async => ++calls == 1 ? http.Response('', 503) : http.Response('ok', 200)));
      expect((await net.get('s', Uri.parse('https://x.test'))).body, 'ok');
      expect(calls, 2);
    });
    test('never more than 4 requests in flight', () async {
      var inFlight = 0, peak = 0;
      final net = Net(client: MockClient((_) async {
        inFlight++;
        peak = inFlight > peak ? inFlight : peak;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        inFlight--;
        return http.Response('ok', 200);
      }));
      await Future.wait([for (var i = 0; i < 12; i++) net.get('s', Uri.parse('https://x.test/$i'))]);
      expect(peak, 4);
    });
  });

  group('valuation', () {
    PriceBook book(Map<int, List<(String, int)>> rows, [String source = 'yahoo']) {
      final b = PriceBook();
      for (final e in rows.entries) {
        for (final (day, c) in e.value) {
          b.add(e.key, source, day, c);
        }
      }
      return b..seal();
    }

    test('price on date, sma, peak, day change', () {
      final b = book({1: [('2026-01-01', 1000000), ('2026-01-02', 1100000), ('2026-01-05', 1210000)]});
      expect(b.on(1, d('2026-01-03'))!.closeE4, 1100000);
      expect(b.on(1, d('2025-12-31')), isNull);
      expect(b.sma(1, 2), 1155000);
      expect(b.sma(1, 4), isNull);
      expect(b.peak(1, 365), 1210000);
      expect(b.dayChangeBps(1), 1000);
    });
    test('cross-check flags > 0.5% gap on the same day only', () {
      final b = PriceBook()
        ..add(1, 'yahoo', '2026-10-12', 10000000)
        ..add(1, 'yahoo', '2026-10-13', 10100000)
        ..add(1, 'nse', '2026-10-12', 10040000) // 0.40% -> ok
        ..add(2, 'yahoo', '2026-10-13', 10000000)
        ..add(2, 'nse', '2026-10-13', 10060000) // 0.60% -> flag
        ..seal();
      expect(b.crossCheck(1)!.$3, 40);
      expect(b.mismatched(1), isFalse);
      expect(b.mismatched(2), isTrue);
      expect(b.mismatched(3), isFalse);
    });
    test('ghost twin: same flows into the benchmark', () {
      final b = book({9: [('2025-01-01', 1000000), ('2025-07-01', 2000000)]}, 'mfapi');
      final txs = [
        Tx(1, d('2025-01-01'), TxType.buy, 100000, 1000000), // Rs 1,000 -> 10 bench units @100
        Tx(2, d('2025-07-01'), TxType.sell, 50000, 2000000), // Rs 1,000 back -> 5 units @200
      ];
      expect(ghostUnits(txs, b, 9), 50000);
    });
    test('xirr with terminal value, and rate sentence', () {
      final r = xirrOf([Tx(1, d('2025-01-01'), TxType.buy, 10000, 1000000)], 11000, d('2026-01-01'))!;
      expect(r, closeTo(0.10, 0.001));
      expect(rateSentence(0.12), 'At this rate money doubles roughly every 6.1 years.');
      expect(rateSentence(-0.05), contains('shrinks'));
    });
    test('bad-day context from index history', () {
      // 40 flat days, a -3% day that recovers in 4 days, then flat, then today -2.5%.
      final closes = <int>[for (var i = 0; i < 40; i++) 10000000];
      closes.addAll([9700000, 9800000, 9900000, 9950000, 10000000, 10000000, 10000000]);
      closes.add(9750000);
      final bars = [for (final (i, c) in closes.indexed) Bar(DateTime.utc(2026).add(Duration(days: i)), c)];
      final f = badDay(bars)!;
      expect(f.todayBps, -250);
      expect(f.similarFalls, 1);
      expect(f.medianRecoveryDays, 4);
      expect(badDay(bars.sublist(0, 45)), isNull); // no fall today
    });
  });

  test('refresher: offline never throws, logs every failure', () async {
    final m = MarketDb(NativeDatabase.memory());
    final net = Net(client: MockClient((_) async => throw const SocketException('airplane mode')));
    final id = await m.into(m.instruments).insert(InstrumentsCompanion.insert(kind: 'mf', name: 'X', schemeCode: const Value('120716')));
    final lines = await Refresher(m, net).run({id}, nowUtc: ist(2026, 10, 14, 18));
    expect(lines.where((l) => !l.ok), isNotEmpty);
    final log = await m.select(m.fetchLog).get();
    expect(log.any((l) => l.source == 'full'), isTrue);
    expect(log.where((l) => l.source.startsWith('nav:')).single.lastError, contains('offline'));
    // A second open within 30 minutes does nothing.
    expect(await Refresher(m, net).run({id}, nowUtc: ist(2026, 10, 14, 18, 20)), isEmpty);
    await m.close();
  });

  test('refresher: stores NAVs, stock prices and the NSE cross-check from real payloads', () async {
    final m = MarketDb(NativeDatabase.memory());
    final net = Net(client: MockClient((r) async {
      final u = r.url.toString();
      if (u.contains('mfapi')) return http.Response(fx('mfapi_120716.json'), 200);
      if (u.contains('finance/chart')) return http.Response(fx('yahoo_tcs_5d.json'), 200);
      if (u.contains('sec_bhavdata_full')) return http.Response(fx('bhav_13102026.csv'), 200);
      if (u.contains('EQUITY_L') || u.contains('nifty500')) return http.Response(fx('nifty500.csv'), 200);
      return http.Response('nope', 404);
    }));
    final tcs = await m.into(m.instruments).insert(InstrumentsCompanion.insert(
        kind: 'stock', name: 'TCS', nseSymbol: const Value('TCS'), yahooTicker: const Value('TCS.NS')));
    final lines = await Refresher(m, net).run({tcs}, nowUtc: ist(2026, 10, 14, 9));
    expect(lines.map((l) => l.label), containsAll(['Fund NAVs', 'Stock prices', 'NSE cross-check', 'NSE listings']));
    expect(lines.firstWhere((l) => l.label == 'NSE cross-check').ok, isTrue);
    final px = await m.select(m.prices).get();
    expect(px.where((p) => p.instrumentId == tcs && p.source == 'yahoo'), isNotEmpty);
    expect(px.where((p) => p.instrumentId == tcs && p.source == 'nse').single.date, '2026-10-13');
    expect(px.where((p) => p.source == 'mfapi'), hasLength(5)); // benchmark fund
    expect(await m.select(m.universe).get(), hasLength(5));
    expect(nse.knows(DateTime.utc(2026, 5, 1)), isTrue);
    await m.close();
  });
}
