import 'dart:convert';
import 'dart:isolate';

import 'package:drift/drift.dart';

import '../db/db.dart';
import '../engine/fund_rank.dart';
import '../engine/lots.dart';
import '../engine/scan_config.dart';
import '../engine/scoring.dart';
import '../engine/valuation.dart';
import '../sources/amfi.dart';
import '../sources/mfapi.dart';
import '../sources/net.dart';
import '../sources/nse.dart';
import '../sources/yahoo.dart';

class CancelToken {
  bool cancelled = false;
}

typedef Progress = void Function(int done, int total, String what);

/// Fund metrics share the fundamentals cache under this prefix.
const fundKeyPrefix = 'mf:';

Future<List<Listing>> _members(MarketDb m, Net net, Progress? onProgress) async {
  var members = await (m.select(m.universe)..where((u) => u.nifty500.equals(true))).get();
  if (members.isNotEmpty) return members;
  onProgress?.call(0, 500, 'Fetching the NIFTY 500 list');
  final list = await nifty500(net);
  await m.batch((b) => b.insertAllOnConflictUpdate(m.universe, [
        for (final r in list)
          UniverseCompanion.insert(symbol: r.$1, name: r.$2, industry: Value(r.$3), isin: Value(r.$4), nifty500: const Value(true)),
      ]));
  return (m.select(m.universe)..where((u) => u.nifty500.equals(true))).get();
}

ScanInput _input(Listing u, Map<String, dynamic> data, DateTime now) => ScanInput(
      u.symbol,
      u.name,
      u.industry,
      ((data['f'] as Map?) ?? const {}).cast<String, num?>(),
      [for (final r in (data['c'] as List? ?? const [])) Bar(parseDay(r[0] as String), r[1] as int)],
      data['pAt'] == null ? now : DateTime.parse(data['pAt'] as String),
    );

/// Stale when older than the cache age or fetched before growth fields existed.
bool _fundamentalsStale(Map<String, dynamic> data, int ageDays) =>
    ageDays > fundamentalsMaxAgeDays || data['f'] is! Map || !(data['f'] as Map).containsKey('revenueGrowth');

/// Refreshes one symbol's cached fundamentals (and prices if it passes the filters).
Future<void> _refreshOne(MarketDb m, Net net, YahooSession yahoo, Listing u, Map<String, dynamic> data, DateTime fetchedAt,
    DateTime now, Future<void> Function() polite) async {
  final fAge = now.difference(fetchedAt.toUtc()).inDays;
  if (_fundamentalsStale(data, fAge)) {
    await polite();
    data['f'] = await yahoo.fundamentals('${u.symbol}.NS');
    data['fAt'] = now.toIso8601String();
  }
  final probe = ScanInput(u.symbol, u.name, u.industry, (data['f'] as Map).cast<String, num?>(), const [], now);
  final passes = filterOut(probe) == 'not enough price history'; // prices only for names that pass quality
  final pAt = data['pAt'] == null ? null : DateTime.parse(data['pAt'] as String);
  if (passes && (pAt == null || now.difference(pAt).inDays > pricesMaxAgeDays)) {
    await polite();
    final rows = await yahooDaily(net, '${u.symbol}.NS', range: '3y');
    data['c'] = [for (final (d, c) in rows) [d, c]];
    data['pAt'] = now.toIso8601String();
  }
  await m.into(m.fundamentals).insertOnConflictUpdate(
      FundamentalsCompanion.insert(symbol: u.symbol, json: jsonEncode(data), fetchedAt: now));
}

/// Stock ideas from the cache alone: no network. Decoding ~500 cached entries
/// (with 3 years of prices each) runs on a background isolate to keep the UI smooth.
Future<List<Candidate>> stockIdeas(MarketDb m, {Set<String> exclude = const {}, DateTime? nowUtc, int n = topN}) async {
  final now = (nowUtc ?? DateTime.now()).toUtc();
  final members = {for (final u in await (m.select(m.universe)..where((u) => u.nifty500.equals(true))).get()) u.symbol: u};
  final rows = [
    for (final f in await (m.select(m.fundamentals)..where((f) => f.symbol.like('$fundKeyPrefix%').not())).get())
      if (members[f.symbol] != null) (members[f.symbol]!, f.json),
  ];
  return Isolate.run(() => rankUniverse([
        for (final (u, json) in rows) _input(u, (jsonDecode(json) as Map).cast<String, dynamic>(), now),
      ], exclude: exclude, n: n));
}

/// Full NIFTY 500 refresh: two requests in flight with a pause each, cached
/// fundamentals (30 d) and prices (7 d) reused. About 3 minutes the first time.
Future<List<Candidate>> runScan(
  MarketDb m,
  Net net, {
  required Progress onProgress,
  required CancelToken cancel,
  Duration pause = const Duration(milliseconds: 600),
  Set<String> exclude = const {},
  DateTime? nowUtc,
  int? limit, // refresh only the [limit] stalest symbols (background job)
}) async {
  final now = (nowUtc ?? DateTime.now()).toUtc();
  final members = await _members(m, net, onProgress);
  final cache = {for (final f in await m.select(m.fundamentals).get()) f.symbol: f};
  var todo = [...members];
  if (limit != null) {
    DateTime at(Listing u) => cache[u.symbol]?.fetchedAt.toUtc() ?? DateTime.utc(2000);
    todo.sort((a, b) => at(a).compareTo(at(b)));
    todo = todo.take(limit).toList();
  }
  final yahoo = YahooSession(net);
  Future<void> polite() => Future<void>.delayed(pause);
  var done = 0;
  FetchError? limited;
  Future<void> worker(Iterator<Listing> it) async {
    while (!cancel.cancelled && limited == null) {
      final Listing u;
      // Shared iterator: each worker takes the next symbol.
      if (!it.moveNext()) return;
      u = it.current;
      onProgress(done, todo.length, u.symbol);
      final old = cache[u.symbol];
      final data = old == null ? <String, dynamic>{} : (jsonDecode(old.json) as Map).cast<String, dynamic>();
      try {
        await _refreshOne(m, net, yahoo, u, data, old?.fetchedAt ?? DateTime.utc(2000), now, polite);
      } on FetchError catch (e) {
        if (e.message.contains('429') || e.message.contains('backing off')) {
          limited = FetchError('scan', 'Yahoo is rate-limiting. Partial results kept; try again later.');
        }
      } catch (_) {
        // Skip one bad symbol, keep scanning.
      }
      done++;
    }
  }

  final it = todo.iterator;
  await Future.wait([worker(it), worker(it)]);
  onProgress(todo.length, todo.length, 'Ranking');
  await m.logFetch('scan', rows: done, at: now);
  if (limited != null && limit == null) throw limited!;
  return stockIdeas(m, exclude: exclude, nowUtc: now);
}

// ---------------- Funds ----------------

/// Fund ideas from the cache alone.
Future<Map<String, List<FundIdea>>> fundIdeas(MarketDb m) async {
  final rows = await (m.select(m.fundamentals)..where((f) => f.symbol.like('$fundKeyPrefix%'))).get();
  return rankFunds([
    for (final r in rows) FundMetrics.fromJson(r.symbol.substring(fundKeyPrefix.length), jsonDecode(r.json) as Map),
  ]);
}

/// Every direct-growth fund in the advisor's categories (AMFI list), then a
/// 5-year NAV window each from mfapi. Metrics cached 30 days.
Future<Map<String, List<FundIdea>>> runFundScan(
  MarketDb m, {
  required Progress onProgress,
  required CancelToken cancel,
  DateTime? nowUtc,
  Net? net,
}) async {
  final now = (nowUtc ?? DateTime.now()).toUtc();
  final n = net ?? Net();
  onProgress(0, 1, 'Fetching the AMFI fund list');
  final funds = await amfiFunds(net ?? amfiNet());
  final cached = {
    for (final r in await (m.select(m.fundamentals)..where((f) => f.symbol.like('$fundKeyPrefix%'))).get())
      r.symbol.substring(fundKeyPrefix.length): r.fetchedAt.toUtc(),
  };
  final todo = [for (final f in funds) if (now.difference(cached[f.code] ?? DateTime.utc(2000)).inDays > fundamentalsMaxAgeDays) f];
  var done = 0;
  final start = DateTime.utc(now.year - 5, now.month, now.day).subtract(const Duration(days: 15));
  for (var i = 0; i < todo.length && !cancel.cancelled; i += Net.maxConcurrent) {
    await Future.wait(todo.skip(i).take(Net.maxConcurrent).map((f) async {
      try {
        final navs = await mfNavsBetween(n, f.code, start, now);
        final mtx = fundMetrics(f.code, f.name, f.category, navs.navs);
        if (mtx != null) {
          await m.into(m.fundamentals).insertOnConflictUpdate(
              FundamentalsCompanion.insert(symbol: '$fundKeyPrefix${f.code}', json: jsonEncode(mtx.toJson()), fetchedAt: now));
        }
      } catch (_) {
        // Skip one fund.
      }
      onProgress(++done, todo.length, f.name);
    }));
  }
  await m.logFetch('fundscan', rows: done, at: now);
  return fundIdeas(m);
}
