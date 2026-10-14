import 'dart:convert';

import 'package:xml/xml.dart';

import 'net.dart';

// Probed 2026-10-14: all four return RSS 2.0 <item><title/><link/><pubDate/>.
const rssFeeds = {
  'ET Markets': 'https://economictimes.indiatimes.com/markets/rssfeeds/1977021501.cms',
  'Moneycontrol': 'https://www.moneycontrol.com/rss/marketreports.xml',
  'Mint': 'https://www.livemint.com/rss/markets',
  'Business Standard': 'https://www.business-standard.com/rss/markets-106.rss',
};

class Headline {
  final String url;
  final String title;
  final String publisher;
  final DateTime publishedUtc;
  const Headline(this.url, this.title, this.publisher, this.publishedUtc);
}

const _mon = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

/// RFC 822 date ("Tue, 14 Oct 2026 09:15:00 +0530" / "GMT") -> UTC.
DateTime? parseRfc822(String s) {
  final m = RegExp(r'(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|GMT|UTC|Z|IST)?')
      .firstMatch(s);
  if (m == null) return null;
  final mon = _mon.indexOf(m[2]!.toLowerCase());
  if (mon < 0) return null;
  var t = DateTime.utc(int.parse(m[3]!), mon + 1, int.parse(m[1]!), int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6] ?? '0'));
  final z = m[7] ?? 'GMT';
  if (z == 'IST') return t.subtract(const Duration(hours: 5, minutes: 30));
  if (z.startsWith('+') || z.startsWith('-')) {
    final off = Duration(hours: int.parse(z.substring(1, 3)), minutes: int.parse(z.substring(3, 5)));
    t = z.startsWith('+') ? t.subtract(off) : t.add(off);
  }
  return t;
}

String _clean(String s) => s
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&amp;', '&')
    .replaceAll('&#39;', "'")
    .replaceAll('&quot;', '"')
    .replaceAll(RegExp(r'#39;'), "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

List<Headline> parseRss(String body, String publisher) {
  final doc = XmlDocument.parse(body);
  final out = <Headline>[];
  for (final item in doc.findAllElements('item')) {
    final title = _clean(item.getElement('title')?.innerText ?? '');
    final link = (item.getElement('link')?.innerText ?? '').trim();
    final date = parseRfc822(item.getElement('pubDate')?.innerText ?? '');
    if (title.isEmpty || !link.startsWith('https://') || date == null) continue;
    out.add(Headline(link, title, publisher, date));
  }
  return out;
}

Future<List<Headline>> fetchRss(Net n, String publisher, String url) async =>
    parseRss((await n.get('rss', Uri.parse(url), headers: const {'Accept': 'application/rss+xml, application/xml'})).body,
        publisher);

/// GDELT DOC 2.0 artlist (allows about 1 request per 5 s; we send at most one per refresh).
List<Headline> parseGdelt(String body) {
  final j = jsonDecode(body);
  final arts = j is Map ? j['articles'] : null;
  if (arts is! List) return const [];
  final out = <Headline>[];
  for (final a in arts) {
    if (a is! Map) continue;
    final url = a['url']?.toString() ?? '';
    final title = _clean(a['title']?.toString() ?? '');
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$').firstMatch(a['seendate']?.toString() ?? '');
    if (!url.startsWith('https://') || title.isEmpty || m == null) continue;
    out.add(Headline(url, title, a['domain']?.toString() ?? 'GDELT',
        DateTime.utc(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!), int.parse(m[5]!), int.parse(m[6]!))));
  }
  return out;
}

Future<List<Headline>> fetchGdelt(Net n, List<String> companies) async {
  if (companies.isEmpty) return const [];
  final q = '(${companies.take(12).map((c) => '"$c"').join(' OR ')}) sourcecountry:IN sourcelang:english';
  final r = await n.get('gdelt', Uri.https('api.gdeltproject.org', '/api/v2/doc/doc',
      {'query': q, 'mode': 'artlist', 'format': 'json', 'maxrecords': '75', 'timespan': '72h'}));
  return parseGdelt(r.body);
}

/// 64-bit FNV-1a of the URL, hex. Stable dedupe key, not a security hash.
String urlHash(String url) {
  var h = BigInt.parse('cbf29ce484222325', radix: 16);
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = (BigInt.one << 64) - BigInt.one;
  for (final b in utf8.encode(url.trim())) {
    h = ((h ^ BigInt.from(b)) * prime) & mask;
  }
  return h.toRadixString(16).padLeft(16, '0');
}

/// Lowercase letters and digits only: catches the same story under two URLs.
String normTitle(String t) => t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

const _generic = {'ltd', 'limited', 'ltd.', 'the', 'india', 'of', 'and', '&', 'co', 'company', 'corporation', 'corp', 'inc'};

List<String> _nameWords(String name) => [for (final w in normTitle(name).split(' ')) if (w.isNotEmpty && !_generic.contains(w)) w];

/// One- and two-word name prefixes used by two or more listed companies
/// ("tata", "bajaj", "anand rathi"): too vague to identify a company on their own.
Set<String> sharedPrefixes(Iterable<String> listedNames) {
  final seen = <String, int>{};
  for (final n in listedNames) {
    final w = _nameWords(n);
    for (var k = 1; k <= 2 && k <= w.length; k++) {
      final p = w.take(k).join(' ');
      seen[p] = (seen[p] ?? 0) + 1;
    }
  }
  return {for (final e in seen.entries) if (e.value >= 2) e.key};
}

/// Phrases that identify a company in a headline: the shortest name prefix no other
/// listed company shares ("anand rathi wealth", not "anand rathi", which is also
/// Anand Rathi Share and Stock Brokers), the NSE symbol (4+ letters) and user aliases.
List<String> matchTerms(String name, String? symbol, String aliases, {Set<String> shared = const {}}) {
  final words = _nameWords(name);
  String? prefix;
  for (var k = 1; k <= words.length; k++) {
    final p = words.take(k).join(' ');
    if (k == 1 && p.length < 5) continue; // "hdfc", "itc": too short alone
    if (!shared.contains(p)) {
      prefix = p;
      break;
    }
  }
  final terms = <String>{
    ?prefix,
    if (prefix == null && words.isNotEmpty) words.join(' '),
    if (symbol != null && symbol.length >= 4 && !shared.contains(symbol.toLowerCase())) symbol.toLowerCase(),
    for (final a in aliases.split(',')) if (normTitle(a).length >= 3 && a.toLowerCase() != 'benchmark') normTitle(a),
  };
  return terms.toList();
}

bool mentions(String headline, List<String> terms) {
  final h = ' ${normTitle(headline)} ';
  return terms.any((t) => h.contains(' $t '));
}
