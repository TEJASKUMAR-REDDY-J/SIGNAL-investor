import 'package:drift/drift.dart';

import '../db/db.dart';
import '../engine/alerts.dart';
import '../engine/lots.dart';
import '../sources/groq.dart';
import '../sources/net.dart';
import '../sources/nse.dart';
import '../sources/rss.dart';
import 'refresh.dart';

typedef HeldIds = Set<int> Function();
typedef GroqConfig = Future<(String key, String model)?> Function();

/// NSE corporate announcements for held stocks, last 7 days. Optional source:
/// NSE's bot filter sometimes refuses; failures are logged and skipped.
Step filingsStep(MarketDb m, Net net, HeldIds held) => (now) async {
      final st = await m.fetchState('filings');
      if (!feedStale(st?.lastAttemptAt?.toUtc(), now)) return null;
      final inst = await (m.select(m.instruments)
            ..where((i) => i.id.isIn(held()) & i.nseSymbol.isNotNull()))
          .get();
      if (inst.isEmpty) return null;
      final s = NseSession(net);
      var added = 0, failed = 0;
      Future<void> one(Instrument i) async {
        try {
          final list = await s.announcements(i.nseSymbol!, now.subtract(const Duration(days: 7)), now);
          for (final a in list) {
            final day = fmtDay(a.day);
            final dup = await (m.select(m.filings)
                  ..where((f) => f.instrumentId.equals(i.id) & f.date.equals(day) & f.subject.equals(a.text)))
                .getSingleOrNull();
            if (dup != null) continue;
            await m.into(m.filings).insert(FilingsCompanion.insert(
                instrumentId: i.id, date: day, category: a.subject, subject: a.text, url: a.url));
            added++;
          }
        } catch (_) {
          failed++;
        }
      }

      // First call warms NSE's cookie; if NSE refuses it, skip the rest instead of timing out on each.
      await one(inst.first);
      if (failed == 0) await Future.wait(inst.skip(1).map(one)); // Net keeps at most 4 in flight
      if (failed > 0 && added == 0 && inst.length > 1) failed = inst.length;
      await m.logFetch('filings', rows: added, at: now, error: failed == inst.length ? 'all failed' : null);
      return ReceiptLine('NSE filings', failed < inst.length, '$added new${failed > 0 ? ', $failed failed' : ''}');
    };

/// RSS + one GDELT query -> 72h, matched to holdings, deduped, then tagged.
Step newsStep(MarketDb m, Net net, HeldIds held, GroqConfig groq) => (now) async {
      final st = await m.fetchState('news');
      if (!feedStale(st?.lastAttemptAt?.toUtc(), now)) return null;
      final inst = await (m.select(m.instruments)..where((i) => i.id.isIn(held()) & i.kind.equals('stock'))).get();
      if (inst.isEmpty) return null;
      final heads = <Headline>[];
      var fails = 0;
      await Future.wait([
        for (final e in rssFeeds.entries)
          fetchRss(net, e.key, e.value).then(heads.addAll, onError: (_) => fails++),
        fetchGdelt(net, [for (final i in inst) i.name]).then(heads.addAll, onError: (_) => fails++),
      ]);
      final cutoff = now.subtract(const Duration(hours: 72));
      final terms = {for (final i in inst) i.id: matchTerms(i.name, i.nseSymbol, i.aliases)};
      final recent = await (m.select(m.newsItems)..where((n) => n.publishedAt.isBiggerOrEqualValue(cutoff))).get();
      final seenTitles = {for (final n in recent) normTitle(n.title)};
      var added = 0;
      for (final h in heads) {
        if (h.publishedUtc.isBefore(cutoff)) continue;
        final id = terms.entries.where((e) => mentions(h.title, e.value)).firstOrNull?.key;
        if (id == null) continue;
        final t = normTitle(h.title);
        if (seenTitles.contains(t)) continue;
        seenTitles.add(t);
        final inserted = await m.into(m.newsItems).insert(
            NewsItemsCompanion.insert(
                urlHash: urlHash(h.url), url: h.url, title: h.title, publisher: h.publisher, publishedAt: h.publishedUtc, instrumentId: Value(id)),
            mode: InsertMode.insertOrIgnore);
        if (inserted > 0) added++;
      }
      // Tag untagged held-company headlines (max 40 per refresh).
      var tagged = 0;
      String? tagErr;
      final cfg = await groq();
      if (cfg != null) {
        final untagged = await (m.select(m.newsItems)
              ..where((n) => n.label.isNull() & n.instrumentId.isIn(held()) & n.publishedAt.isBiggerOrEqualValue(cutoff))
              ..orderBy([(n) => OrderingTerm.desc(n.publishedAt)])
              ..limit(maxTagsPerRefresh))
            .get();
        final names = {for (final i in inst) i.id: i.name};
        try {
          final tags = await tagHeadlines(net, cfg.$1, cfg.$2, [
            for (final n in untagged) TagInput(n.url, n.title, n.publisher, n.publishedAt.toUtc(), names[n.instrumentId] ?? ''),
          ]);
          for (final t in tags) {
            await (m.update(m.newsItems)..where((n) => n.urlHash.equals(urlHash(t.url)))).write(
                NewsItemsCompanion(label: Value(t.label), confidence: Value(t.confidence), reason: Value(t.reason)));
            tagged++;
          }
        } catch (e) {
          tagErr = e.toString();
        }
      }
      await m.logFetch('news', rows: added, at: now, error: fails > rssFeeds.length ? 'all feeds failed' : null);
      return ReceiptLine('News', fails <= rssFeeds.length,
          '$added new${cfg == null ? '' : ', $tagged tagged'}${tagErr != null ? ' (AI: ${tagErr.replaceFirst('groq: ', '')})' : ''}');
    };

/// Current alerts for the held set (pure rules in engine/alerts.dart).
Future<List<Alert>> loadAlerts(MarketDb m, Set<int> held, DateTime nowUtc) async => alertsFor(
      held: held,
      news: await (m.select(m.newsItems)
            ..where((n) => n.publishedAt.isBiggerOrEqualValue(nowUtc.subtract(const Duration(hours: 72)))))
          .get(),
      filings: await (m.select(m.filings)
            ..where((f) => f.date.isBiggerOrEqualValue(fmtDay(nowUtc.subtract(const Duration(days: 8))))))
          .get(),
      nowUtc: nowUtc,
    );
