import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:signal_investor/db/db.dart';
import 'package:signal_investor/engine/time_machine.dart';
import 'package:signal_investor/engine/valuation.dart';
import 'package:signal_investor/pipeline/scan.dart';
import 'package:signal_investor/sources/net.dart';

List<Bar> navs(List<double> monthly) => [
      for (final (i, v) in monthly.indexed) Bar(DateTime.utc(2024, 1 + i, 1), (v * 10000).round()),
    ];

void main() {
  test('SIP through a fall and recovery beats lump sum at the same end price', () {
    final nav = navs([100, 80, 60, 80, 100]);
    final sip = simulateSip(nav, DateTime.utc(2024), 100000); // Rs 1,000 a month
    final lump = simulateLump(nav, DateTime.utc(2024), 500000);
    expect(sip.investedPaise, 500000);
    expect(sip.valuePaise, greaterThan(lump.valuePaise)); // bought more units cheap
    expect(lump.valuePaise, 500000); // back to start
    expect(lump.worstDropBps, 4000); // fell 40% along the way
    expect(sip.path, hasLength(5));
    expect(sip.xirr, greaterThan(0));
  });

  test('empty or future start gives an empty result', () {
    expect(simulateSip(navs([100]), DateTime.utc(2030), 100).valuePaise, 0);
  });

  test('scan: filters, pauses, caches, ranks, cancels', () async {
    final m = MarketDb(NativeDatabase.memory());
    for (final s in ['GOOD', 'BAD']) {
      await m.into(m.universe).insert(UniverseCompanion.insert(symbol: s, name: s, nifty500: const Value(true)));
    }
    var priceCalls = 0;
    final closes = [
      for (var i = 0; i < 800; i++) DateTime.utc(2023, 8, 1).add(Duration(days: i)).millisecondsSinceEpoch ~/ 1000,
    ];
    final net = Net(client: MockClient((r) async {
      final u = r.url.toString();
      if (u.contains('fc.yahoo.com')) return http.Response('', 404, headers: {'set-cookie': 'A3=x; Path=/'});
      if (u.contains('getcrumb')) return http.Response('crumb1', 200);
      if (u.contains('quoteSummary')) {
        final good = u.contains('GOOD');
        return http.Response(
            jsonEncode({
              'quoteSummary': {
                'result': [
                  {
                    'financialData': {'returnOnEquity': {'raw': good ? 0.3 : 0.02}, 'debtToEquity': {'raw': 10}, 'freeCashflow': {'raw': 1e10}},
                    'summaryDetail': {'trailingPE': {'raw': 18}, 'marketCap': {'raw': 1e12}},
                  }
                ]
              }
            }),
            200);
      }
      if (u.contains('finance/chart')) {
        priceCalls++;
        return http.Response(
            jsonEncode({
              'chart': {
                'result': [
                  {
                    'timestamp': closes,
                    'indicators': {
                      'quote': [
                        {'close': [for (var i = 0; i < closes.length; i++) 100 + i * 0.05]}
                      ]
                    }
                  }
                ]
              }
            }),
            200);
      }
      return http.Response('', 404);
    }));
    final seen = <String>[];
    final r = await runScan(m, net, onProgress: (d, t, w) => seen.add(w), cancel: CancelToken(), pause: Duration.zero,
        nowUtc: DateTime.utc(2026, 10, 14));
    expect(r.single.input.symbol, 'GOOD');
    expect(priceCalls, 1); // BAD failed the quality filter: no price fetch
    expect(seen, containsAll(['GOOD', 'BAD', 'Ranking']));
    // Second scan within a week uses the cache: no new price calls.
    await runScan(m, net, onProgress: (_, _, _) {}, cancel: CancelToken(), pause: Duration.zero, nowUtc: DateTime.utc(2026, 10, 15));
    expect(priceCalls, 1);
    // Cancelled before start: nothing scanned.
    final c = CancelToken()..cancelled = true;
    expect(await runScan(m, net, onProgress: (_, _, _) {}, cancel: c, pause: Duration.zero), isEmpty);
    await m.close();
  });
}
