import 'dart:convert';

import 'net.dart';

// api.mfapi.in, probed 2026-10-14:
// /mf/{code}        -> {meta:{scheme_name,...}, data:[{date:"13-10-2026", nav:"159.99100"}...] newest first}
// /mf/{code}/latest -> same, data has 1 row
// /mf/search?q=     -> [{schemeCode:int, schemeName:str}]

String _iso(String ddmmyyyy) {
  final p = ddmmyyyy.split('-');
  return '${p[2]}-${p[1]}-${p[0]}';
}

class MfNavs {
  final String schemeName;
  final List<(String, int)> navs; // (YYYY-MM-DD, navE4), oldest first
  const MfNavs(this.schemeName, this.navs);
}

MfNavs parseMfapi(String body) {
  final j = jsonDecode(body);
  if (j is! Map || j['data'] is! List) throw const FormatException('mfapi shape');
  final name = (j['meta'] is Map ? j['meta']['scheme_name'] : null)?.toString() ?? '';
  final out = <(String, int)>[];
  for (final r in j['data'] as List) {
    if (r is! Map) continue;
    final d = r['date']?.toString() ?? '';
    final nav = decimalE4(r['nav']?.toString());
    if (nav == null || !RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(d)) continue;
    out.add((_iso(d), nav));
  }
  out.sort((a, b) => a.$1.compareTo(b.$1));
  return MfNavs(name, out);
}

Future<MfNavs> mfNavs(Net n, String code, {bool latestOnly = false}) async {
  if (!RegExp(r'^\d{3,7}$').hasMatch(code)) throw FetchError('mfapi', 'bad scheme code');
  final r = await n.get('mfapi', Uri.parse('https://api.mfapi.in/mf/$code${latestOnly ? '/latest' : ''}'));
  return parseMfapi(r.body);
}

Future<List<(String, String)>> mfSearch(Net n, String q) async {
  final r = await n.get('mfapi', Uri.https('api.mfapi.in', '/mf/search', {'q': q}));
  final j = jsonDecode(r.body);
  if (j is! List) return const [];
  return [
    for (final x in j)
      if (x is Map && x['schemeCode'] != null && x['schemeName'] is String)
        (x['schemeCode'].toString(), x['schemeName'] as String),
  ];
}

/// Regular plans carry distributor commission; direct plans do not.
bool isRegularPlan(String schemeName) {
  final n = schemeName.toLowerCase();
  return n.contains('regular') && !n.contains('direct');
}
