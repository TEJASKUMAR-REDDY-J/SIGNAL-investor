import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/scan_config.dart';
import '../engine/scoring.dart';
import '../engine/valuation.dart';
import '../sources/net.dart';
import '../sources/nse.dart';
import '../sources/yahoo.dart';

class CancelToken {
  bool cancelled = false;
}

typedef Progress = void Function(int done, int total, String what);

/// Manual weekly scan of NIFTY 500. One request at a time with a pause between
/// calls; cached fundamentals (30 d) and prices (7 d) are reused.
Future<List<Candidate>> runScan(
  MarketDb m,
  Net net, {
  required Progress onProgress,
  required CancelToken cancel,
  Duration pause = const Duration(seconds: 1),
  Set<String> exclude = const {},
  DateTime? nowUtc,
}) async {
  final now = (nowUtc ?? DateTime.now()).toUtc();
  var members = await (m.select(m.universe)..where((u) => u.nifty500.equals(true))).get();
  if (members.isEmpty) {
    onProgress(0, 500, 'Fetching the NIFTY 500 list');
    final list = await nifty500(net);
    await m.batch((b) => b.insertAllOnConflictUpdate(m.universe, [
          for (final r in list)
            UniverseCompanion.insert(symbol: r.$1, name: r.$2, industry: Value(r.$3), isin: Value(r.$4), nifty500: const Value(true)),
        ]));
    members = await (m.select(m.universe)..where((u) => u.nifty500.equals(true))).get();
  }
  final cache = {for (final f in await m.select(m.fundamentals).get()) f.symbol: f};
  final yahoo = YahooSession(net);
  final inputs = <ScanInput>[];
  var calls = 0;
  Future<void> polite() async {
    if (calls++ > 0) await Future<void>.delayed(pause);
  }

  for (final (i, u) in members.indexed) {
    if (cancel.cancelled) break;
    onProgress(i, members.length, u.symbol);
    final old = cache[u.symbol];
    Map<String, dynamic> data = old == null ? {} : (jsonDecode(old.json) as Map).cast<String, dynamic>();
    final fAge = old == null ? 9999 : now.difference(old.fetchedAt.toUtc()).inDays;
    try {
      if (fAge > fundamentalsMaxAgeDays || data['f'] == null) {
        await polite();
        data['f'] = await yahoo.fundamentals('${u.symbol}.NS');
        data['fAt'] = now.toIso8601String();
      }
      final f = (data['f'] as Map).cast<String, num?>();
      final probe = ScanInput(u.symbol, u.name, u.industry, f, const [], now);
      // Prices only for stocks that pass the quality filters.
      final passes = filterOut(probe) == 'not enough price history';
      final pAt = data['pAt'] == null ? null : DateTime.parse(data['pAt'] as String);
      if (passes && (pAt == null || now.difference(pAt).inDays > pricesMaxAgeDays)) {
        if (cancel.cancelled) break;
        await polite();
        final rows = await yahooDaily(net, '${u.symbol}.NS', range: '3y');
        data['c'] = [for (final (d, c) in rows) [d, c]];
        data['pAt'] = now.toIso8601String();
      }
      await m.into(m.fundamentals).insertOnConflictUpdate(
          FundamentalsCompanion.insert(symbol: u.symbol, json: jsonEncode(data), fetchedAt: now));
      final closes = [for (final r in (data['c'] as List? ?? const [])) Bar(parseDay(r[0] as String), r[1] as int)];
      inputs.add(ScanInput(u.symbol, u.name, u.industry, f, closes,
          data['pAt'] == null ? now : DateTime.parse(data['pAt'] as String)));
    } on FetchError catch (e) {
      if (e.message.contains('429') || e.message.contains('backing off')) {
        throw FetchError('scan', 'Yahoo is rate-limiting. Partial results kept; try again later.');
      }
    } catch (_) {
      // Skip one bad symbol, keep scanning.
    }
  }
  onProgress(members.length, members.length, 'Ranking');
  await m.logFetch('scan', rows: inputs.length, at: now);
  return rankUniverse(inputs, exclude: exclude);
}
