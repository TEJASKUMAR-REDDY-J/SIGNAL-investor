import 'package:drift/drift.dart';

import '../db/db.dart';
import '../engine/calendar.dart';
import '../engine/lots.dart';
import '../engine/valuation.dart' show benchmarkScheme;
import '../sources/mfapi.dart';
import '../sources/net.dart';
import '../sources/nse.dart';
import '../sources/yahoo.dart';

const indexTicker = '^NSEI';

// ---- staleness rules (all instants UTC; IST handled by the calendar) ----

bool fullRefreshDue(DateTime? lastFullUtc, DateTime nowUtc) =>
    lastFullUtc == null || nowUtc.difference(lastFullUtc) >= const Duration(minutes: 30);

/// Stock prices: stale if the last success is before the latest trading-day 16:00 IST.
bool stockStale(DateTime? lastOkUtc, DateTime nowUtc, [MarketCalendar? cal]) =>
    lastOkUtc == null || lastOkUtc.toUtc().isBefore((cal ?? nse).lastCloseUtc(nowUtc));

/// MF NAV: stale if the newest stored NAV is older than the last trading day
/// AND the last attempt was over 3 hours ago (NAVs land late in the evening).
bool navStale(String? latestNavDate, DateTime? lastAttemptUtc, DateTime nowUtc, [MarketCalendar? cal]) {
  final behind = latestNavDate == null || parseDay(latestNavDate).isBefore((cal ?? nse).lastTradingDay(nowUtc));
  final quiet = lastAttemptUtc == null || nowUtc.difference(lastAttemptUtc.toUtc()) > const Duration(hours: 3);
  return behind && quiet;
}

/// Filings and news: stale after 3 hours.
bool feedStale(DateTime? lastOkUtc, DateTime nowUtc) =>
    lastOkUtc == null || nowUtc.difference(lastOkUtc.toUtc()) > const Duration(hours: 3);

class ReceiptLine {
  final String label;
  final bool ok;
  final String detail;
  const ReceiptLine(this.label, this.ok, this.detail);
}

/// Extra pipeline step (filings, news, tagging) plugged in by later phases.
/// [force] (pull to refresh, "Check now") skips the step's own staleness check.
typedef Step = Future<ReceiptLine?> Function(DateTime nowUtc, bool force);

class Refresher {
  final MarketDb m;
  final Net net;
  final List<Step> extra;
  Refresher(this.m, this.net, {this.extra = const []});

  Future<Instrument> _ensure(String kind, String name, {String? code, String? ticker, String aliases = ''}) async {
    final q = m.select(m.instruments)
      ..where((i) => code != null ? i.schemeCode.equals(code) : i.yahooTicker.equals(ticker!));
    final hit = await q.getSingleOrNull();
    if (hit != null) return hit;
    final id = await m.into(m.instruments).insert(InstrumentsCompanion.insert(
        kind: kind, name: name, schemeCode: Value(code), yahooTicker: Value(ticker), aliases: Value(aliases)));
    return (await (m.select(m.instruments)..where((i) => i.id.equals(id))).getSingle());
  }

  Future<Instrument> benchmark() => _ensure('mf', 'Nifty 50 index fund (benchmark)', code: benchmarkScheme, aliases: 'benchmark');
  Future<Instrument> index() => _ensure('index', 'NIFTY 50', ticker: indexTicker, aliases: 'index');

  Future<int> _count(int id) async {
    final c = m.prices.instrumentId.count();
    return (await (m.selectOnly(m.prices)
              ..addColumns([c])
              ..where(m.prices.instrumentId.equals(id)))
            .map((r) => r.read(c))
            .getSingle()) ??
        0;
  }

  Future<String?> _latestDate(int id, String source) async {
    final r = await (m.select(m.prices)
          ..where((p) => p.instrumentId.equals(id) & p.source.equals(source))
          ..orderBy([(p) => OrderingTerm.desc(p.date)])
          ..limit(1))
        .getSingleOrNull();
    return r?.date;
  }

  /// Runs every stale source for [heldIds]. Never throws; failures become receipt lines.
  Future<List<ReceiptLine>> run(Set<int> heldIds, {bool force = false, DateTime? nowUtc, void Function(ReceiptLine)? onLine}) async {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final out = <ReceiptLine>[];
    void emit(ReceiptLine l) {
      out.add(l);
      onLine?.call(l);
    }

    if (!force && !fullRefreshDue((await m.fetchState('full'))?.lastOkAt?.toUtc(), now)) return out;

    final bench = await benchmark();
    final idx = await index();
    final inst = await (m.select(m.instruments)..where((i) => i.id.isIn({...heldIds, bench.id, idx.id}))).get();

    // Holidays: refresh when this or (from November) next year is missing.
    final ist = now.add(const Duration(hours: 5, minutes: 30));
    if (!nse.knows(ist) || (ist.month >= 11 && !nse.knows(DateTime.utc(ist.year + 1)))) {
      final st = await m.fetchState('holidays');
      if (force || feedStale(st?.lastAttemptAt?.toUtc(), now)) {
        try {
          final h = await NseSession(net).holidays();
          await m.batch((b) => b.insertAllOnConflictUpdate(
              m.holidays, [for (final (d, n) in h) HolidaysCompanion.insert(date: d, name: n)]));
          await m.logFetch('holidays', rows: h.length, at: now);
          emit(ReceiptLine('NSE holidays', true, '${h.length} dates'));
        } catch (e) {
          await m.logFetch('holidays', error: e, at: now);
          emit(ReceiptLine('NSE holidays', false, _short(e)));
        }
      }
    }
    loadHolidays({for (final h in await m.select(m.holidays).get()) h.date: h.name});

    // MF NAVs.
    final mfs = inst.where((i) => i.kind == 'mf' && i.schemeCode != null).toList();
    var navOk = 0, navFail = 0, navSkip = 0;
    await Future.wait(mfs.map((i) async {
      final key = 'nav:${i.id}';
      final st = await m.fetchState(key);
      if (!force && !navStale(await _latestDate(i.id, 'mfapi'), st?.lastAttemptAt?.toUtc(), now)) {
        navSkip++;
        return;
      }
      try {
        final full = await _count(i.id) < 100;
        final r = await mfNavs(net, i.schemeCode!, latestOnly: !full);
        await m.putPrices(i.id, 'mfapi', r.navs);
        if (r.schemeName.isNotEmpty && i.aliases.isEmpty && !i.name.contains(r.schemeName)) {
          await (m.update(m.instruments)..where((x) => x.id.equals(i.id))).write(InstrumentsCompanion(aliases: Value(r.schemeName)));
        }
        await m.logFetch(key, rows: r.navs.length, at: now);
        navOk++;
      } catch (e) {
        await m.logFetch(key, error: e, at: now);
        navFail++;
      }
    }));
    if (mfs.isNotEmpty) {
      emit(ReceiptLine('Fund NAVs', navFail == 0, '$navOk updated${navSkip > 0 ? ', $navSkip current' : ''}${navFail > 0 ? ', $navFail failed' : ''}'));
    }

    // Stock and index prices (Yahoo).
    final stocks = inst.where((i) => i.yahooTicker != null).toList();
    var pxOk = 0, pxFail = 0, pxSkip = 0;
    await Future.wait(stocks.map((i) async {
      final key = 'px:${i.id}';
      final st = await m.fetchState(key);
      if (!force && !stockStale(st?.lastOkAt?.toUtc(), now)) {
        pxSkip++;
        return;
      }
      try {
        final n = await _count(i.id);
        final range = i.kind == 'index' ? (n < 1000 ? '10y' : '5d') : (n < 300 ? '2y' : '5d');
        final rows = await yahooDaily(net, i.yahooTicker!, range: range);
        await m.putPrices(i.id, 'yahoo', rows);
        await m.logFetch(key, rows: rows.length, at: now);
        pxOk++;
      } catch (e) {
        await m.logFetch(key, error: e, at: now);
        pxFail++;
      }
    }));
    if (stocks.isNotEmpty) {
      emit(ReceiptLine('Stock prices', pxFail == 0, '$pxOk updated${pxSkip > 0 ? ', $pxSkip current' : ''}${pxFail > 0 ? ', $pxFail failed' : ''}'));
    }

    // NSE cross-check: one bhavcopy for the last trading day covers every stock.
    final nseHeld = inst.where((i) => i.nseSymbol != null).toList();
    if (nseHeld.isNotEmpty) {
      final day = nse.lastTradingDay(now);
      final st = await m.fetchState('bhav');
      final have = st?.lastError == null && st?.rows != null && (await _latestDate(nseHeld.first.id, 'nse')) == fmtDay(day);
      if (force || !have) {
        try {
          final closes = await bhavcopy(net, day);
          var n = 0;
          for (final i in nseHeld) {
            final c = closes[i.nseSymbol!];
            if (c == null) continue;
            await m.putPrices(i.id, 'nse', [(fmtDay(day), c)]);
            n++;
          }
          await m.logFetch('bhav', rows: n, at: now);
          emit(ReceiptLine('NSE cross-check', true, '$n of ${nseHeld.length} on ${fmtDay(day)}'));
        } catch (e) {
          await m.logFetch('bhav', error: e, at: now);
          emit(ReceiptLine('NSE cross-check', false, _short(e)));
        }
      }
    }

    // Listing universe for search and the scan, weekly.
    final uni = await m.fetchState('universe');
    if (uni?.lastOkAt == null || now.difference(uni!.lastOkAt!.toUtc()) > const Duration(days: 7)) {
      try {
        final all = await nseEquityList(net);
        final n500 = {for (final r in await nifty500(net)) r.$1: r};
        await m.batch((b) => b.insertAllOnConflictUpdate(m.universe, [
              for (final r in all)
                UniverseCompanion.insert(
                    symbol: r.$1,
                    name: r.$2,
                    isin: Value(r.$4),
                    industry: Value(n500[r.$1]?.$3 ?? ''),
                    nifty500: Value(n500.containsKey(r.$1))),
            ]));
        await m.logFetch('universe', rows: all.length, at: now);
        emit(ReceiptLine('NSE listings', true, '${all.length} stocks, ${n500.length} in NIFTY 500'));
      } catch (e) {
        await m.logFetch('universe', error: e, at: now);
        emit(ReceiptLine('NSE listings', false, _short(e)));
      }
    }

    for (final s in extra) {
      try {
        final l = await s(now, force);
        if (l != null) emit(l);
      } catch (e) {
        emit(ReceiptLine('Step', false, _short(e)));
      }
    }

    await m.logFetch('full', at: now);
    return out;
  }
}

String _short(Object e) {
  final s = e.toString();
  return s.length > 60 ? '${s.substring(0, 60)}…' : s;
}
