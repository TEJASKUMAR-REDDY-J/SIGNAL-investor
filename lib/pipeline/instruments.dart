import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../sources/mfapi.dart';
import '../sources/net.dart';
import '../sources/yahoo.dart';

/// The instrument row for an NSE symbol, created on first use.
Future<int> ensureStock(MarketDb m, String symbol, String name) async {
  final hit = await (m.select(m.instruments)..where((i) => i.nseSymbol.equals(symbol))).getSingleOrNull();
  return hit?.id ??
      await m.into(m.instruments).insert(InstrumentsCompanion.insert(
          kind: 'stock', name: name, nseSymbol: Value(symbol), yahooTicker: Value('$symbol.NS')));
}

/// The instrument row for an AMFI scheme code, created on first use.
Future<int> ensureFund(MarketDb m, String code, String name) async {
  final hit = await (m.select(m.instruments)..where((i) => i.schemeCode.equals(code))).getSingleOrNull();
  return hit?.id ?? await m.into(m.instruments).insert(InstrumentsCompanion.insert(kind: 'mf', name: name, schemeCode: Value(code)));
}

/// Price history for an instrument seen for the first time (stock page, demo, autofill).
Future<void> ensureHistory(MarketDb m, Net n, Instrument i) async {
  final have = await (m.select(m.prices)..where((p) => p.instrumentId.equals(i.id))..limit(30)).get();
  if (have.length >= 30) return;
  if (i.kind == 'mf' && i.schemeCode != null) {
    await m.putPrices(i.id, 'mfapi', (await mfNavs(n, i.schemeCode!)).navs);
  } else if (i.yahooTicker != null) {
    await m.putPrices(i.id, 'yahoo', await yahooDaily(n, i.yahooTicker!, range: '5y')); // 3- and 5-year growth
  }
  await m.logFetch('${i.kind == 'mf' ? 'nav' : 'px'}:${i.id}', at: DateTime.now());
}

/// Cached fundamentals for an NSE symbol (fetched when older than [maxAge]).
Future<Map<String, num?>?> stockFundamentals(MarketDb m, Net n, String symbol, {Duration maxAge = const Duration(days: 7)}) async {
  final row = await (m.select(m.fundamentals)..where((f) => f.symbol.equals(symbol))).getSingleOrNull();
  final data = row == null ? <String, dynamic>{} : (jsonDecode(row.json) as Map).cast<String, dynamic>();
  final fresh = row != null &&
      DateTime.now().difference(row.fetchedAt).compareTo(maxAge) < 0 &&
      data['f'] is Map &&
      (data['f'] as Map).containsKey('revenueGrowth');
  if (!fresh) {
    try {
      data['f'] = await YahooSession(n).fundamentals('$symbol.NS');
      data['fAt'] = DateTime.now().toUtc().toIso8601String();
      await m.into(m.fundamentals).insertOnConflictUpdate(
          FundamentalsCompanion.insert(symbol: symbol, json: jsonEncode(data), fetchedAt: DateTime.now()));
    } catch (_) {
      // Fall back to whatever is cached.
    }
  }
  return data['f'] is Map ? (data['f'] as Map).cast<String, num?>() : null;
}

/// Price for a trade on [day]: that day's close (stocks: today's delayed live
/// price) or the fund's NAV for that day. Fetches when the phone lacks it.
/// Returns the day the price belongs to (it can be earlier, e.g. before the open).
Future<(DateTime, int)?> priceForDay(MarketDb m, Net n, Instrument i, DateTime day) async {
  final src = i.kind == 'mf' ? 'mfapi' : 'yahoo';
  Future<(DateTime, int)?> fromDb() async {
    final r = await (m.select(m.prices)
          ..where((p) => p.instrumentId.equals(i.id) & p.source.equals(src) & p.date.isSmallerOrEqualValue(fmtDay(day)))
          ..orderBy([(p) => OrderingTerm.desc(p.date)])
          ..limit(1))
        .getSingleOrNull();
    return r == null ? null : (parseDay(r.date), r.closeE4);
  }

  final hit = await fromDb();
  final isToday = fmtDay(day) == fmtDay(istToday());
  // Exact day already stored (and not today's, which keeps moving): done.
  if (hit != null && fmtDay(hit.$1) == fmtDay(day) && !isToday) return hit;
  try {
    if (i.kind == 'mf' && i.schemeCode != null) {
      final r = await mfNavsBetween(n, i.schemeCode!, day.subtract(const Duration(days: 10)), day);
      await m.putPrices(i.id, 'mfapi', r.navs);
    } else if (i.yahooTicker != null) {
      final age = istToday().difference(day).inDays;
      final range = age <= 4 ? '5d' : (age <= 360 ? '1y' : (age <= 1800 ? '5y' : '10y'));
      await m.putPrices(i.id, 'yahoo', await yahooDaily(n, i.yahooTicker!, range: range));
    }
  } catch (_) {
    return hit; // offline: best stored price
  }
  return fromDb();
}
