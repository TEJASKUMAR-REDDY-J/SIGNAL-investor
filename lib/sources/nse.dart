import 'dart:convert';

import '../engine/lots.dart';
import 'net.dart';

// Probed 2026-10-14:
// - sec_bhavdata_full_DDMMYYYY.csv: all EQ closes for a day, no cookies needed.
// - holiday-master / corporate-announcements: need homepage cookies first.
// - quote-equity: 403 (bot protection) -> not used; bhavcopy is the cross-check.
// - ind_nifty500list.csv, EQUITY_L.csv: constituent and listing CSVs.

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "13-Oct-2026" -> 2026-10-13 (UTC midnight), null on junk.
DateTime? nseDay(String s) {
  final m = RegExp(r'^(\d{1,2})-([A-Za-z]{3})-(\d{4})').firstMatch(s.trim());
  if (m == null) return null;
  final mon = _months.indexWhere((x) => x.toLowerCase() == m[2]!.toLowerCase());
  return mon < 0 ? null : DateTime.utc(int.parse(m[3]!), mon + 1, int.parse(m[1]!));
}

/// Symbol -> CLOSE_PRICE (x1e4) for series EQ.
Map<String, int> parseBhavcopy(String csv) {
  final lines = const LineSplitter().convert(csv);
  if (lines.isEmpty) return const {};
  final head = [for (final h in lines.first.split(',')) h.trim()];
  final si = head.indexOf('SYMBOL'), se = head.indexOf('SERIES'), ci = head.indexOf('CLOSE_PRICE');
  if (si < 0 || se < 0 || ci < 0) throw const FormatException('bhavcopy header');
  final out = <String, int>{};
  for (final l in lines.skip(1)) {
    final f = l.split(',');
    if (f.length <= ci || f[se].trim() != 'EQ') continue;
    final c = decimalE4(f[ci].trim());
    if (c != null) out[f[si].trim()] = c;
  }
  return out;
}

Future<Map<String, int>> bhavcopy(Net n, DateTime day) async {
  String two(int v) => v.toString().padLeft(2, '0');
  final r = await n.get('nse',
      Uri.parse('https://nsearchives.nseindia.com/products/content/sec_bhavdata_full_${two(day.day)}${two(day.month)}${day.year}.csv'));
  return parseBhavcopy(r.body);
}

/// (symbol, company, industry, isin) rows from a constituents/listing CSV.
List<(String, String, String, String)> parseListCsv(String csv) {
  final lines = const LineSplitter().convert(csv);
  if (lines.isEmpty) return const [];
  final head = [for (final h in lines.first.split(',')) h.trim().toUpperCase()];
  int col(List<String> names) => head.indexWhere(names.contains);
  final si = col(['SYMBOL']), ni = col(['COMPANY NAME', 'NAME OF COMPANY']), ii = col(['INDUSTRY']);
  final isi = col(['ISIN CODE', 'ISIN NUMBER']), sei = col(['SERIES']);
  if (si < 0 || ni < 0) throw const FormatException('list csv header');
  final out = <(String, String, String, String)>[];
  for (final l in lines.skip(1)) {
    final f = _csvSplit(l);
    if (f.length <= ni || f.length <= si) continue;
    if (sei >= 0 && f.length > sei && !const {'EQ', 'BE', 'BZ'}.contains(f[sei].trim())) continue;
    out.add((f[si].trim(), f[ni].trim(), ii >= 0 && f.length > ii ? f[ii].trim() : '',
        isi >= 0 && f.length > isi ? f[isi].trim() : ''));
  }
  return out;
}

List<String> _csvSplit(String line) {
  final out = <String>[];
  final b = StringBuffer();
  var q = false;
  for (final ch in line.split('')) {
    if (ch == '"') {
      q = !q;
    } else if (ch == ',' && !q) {
      out.add(b.toString());
      b.clear();
    } else {
      b.write(ch);
    }
  }
  out.add(b.toString());
  return out;
}

Future<List<(String, String, String, String)>> nifty500(Net n) async => parseListCsv(
    (await n.get('nse', Uri.parse('https://nsearchives.nseindia.com/content/indices/ind_nifty500list.csv'))).body);

Future<List<(String, String, String, String)>> nseEquityList(Net n) async => parseListCsv(
    (await n.get('nse', Uri.parse('https://nsearchives.nseindia.com/content/equities/EQUITY_L.csv'))).body);

class Announcement {
  final DateTime day;
  final String subject; // "desc"
  final String text; // "attchmntText"
  final String url;
  const Announcement(this.day, this.subject, this.text, this.url);
}

List<Announcement> parseAnnouncements(String body) {
  final j = jsonDecode(body);
  if (j is! List) throw const FormatException('announcements shape');
  return [
    for (final a in j)
      if (a is Map && nseDay(a['an_dt']?.toString() ?? '') != null)
        Announcement(nseDay(a['an_dt'].toString())!, a['desc']?.toString() ?? '', a['attchmntText']?.toString() ?? '',
            (a['attchmntFile']?.toString() ?? '').startsWith('https://') ? a['attchmntFile'].toString() : ''),
  ];
}

/// (date, name) for the Capital Market segment.
List<(String, String)> parseHolidays(String body) {
  final j = jsonDecode(body);
  final cm = j is Map ? j['CM'] : null;
  if (cm is! List) throw const FormatException('holiday shape');
  return [
    for (final h in cm)
      if (h is Map && nseDay(h['tradingDate']?.toString() ?? '') != null)
        (fmtDay(nseDay(h['tradingDate'].toString())!), h['description']?.toString() ?? 'Holiday'),
  ];
}

/// Cookie-warmed session for nseindia.com/api (homepage first, as NSE requires).
class NseSession {
  final Net n;
  String? _cookie;
  NseSession(this.n);

  Future<String> _api(String path, Map<String, String> q, String referer) async {
    if (_cookie == null) {
      final home = await n.client.get(Uri.parse('https://www.nseindia.com/'),
          headers: {'User-Agent': mobileUa, 'Accept': 'text/html,application/xhtml+xml', 'Accept-Language': 'en-US,en;q=0.9'}).timeout(n.timeout);
      _cookie = [
        for (final c in (home.headers['set-cookie'] ?? '').split(RegExp(r',(?=[^ ;]+=)')))
          if (c.contains('=')) c.split(';').first.trim(),
      ].join('; ');
    }
    final r = await n.get('nse', Uri.https('www.nseindia.com', path, q),
        headers: {'User-Agent': mobileUa, 'Cookie': _cookie!, 'Referer': referer, 'Accept': 'application/json'});
    return r.body;
  }

  Future<List<(String, String)>> holidays() async =>
      parseHolidays(await _api('/api/holiday-master', {'type': 'trading'}, 'https://www.nseindia.com/resources/exchange-communication-holidays'));

  Future<List<Announcement>> announcements(String symbol, DateTime from, DateTime to) async {
    String d(DateTime x) => '${x.day.toString().padLeft(2, '0')}-${x.month.toString().padLeft(2, '0')}-${x.year}';
    return parseAnnouncements(await _api('/api/corporate-announcements',
        {'index': 'equities', 'symbol': symbol, 'from_date': d(from), 'to_date': d(to)},
        'https://www.nseindia.com/companies-listing/corporate-filings-announcements'));
  }
}
