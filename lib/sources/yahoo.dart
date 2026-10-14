import 'dart:convert';

import '../engine/lots.dart';
import 'net.dart';

// query1.finance.yahoo.com/v8/finance/chart/{T}.NS?range=..&interval=1d, probed 2026-10-14
// (unofficial; 429 for mobile UAs). chart.result[0]: {meta, timestamp[], indicators.quote[0].close[]}
// quoteSummary needs a cookie (fc.yahoo.com) + crumb (/v1/test/getcrumb).

/// (IST date, closeE4), oldest first; null closes skipped.
List<(String, int)> parseYahooChart(String body) {
  final j = jsonDecode(body);
  final chart = j is Map ? j['chart'] : null;
  final res = chart is Map ? chart['result'] : null;
  if (res is! List || res.isEmpty || res.first is! Map) throw const FormatException('yahoo shape');
  final r = res.first as Map;
  final ts = r['timestamp'];
  final ind = r['indicators'];
  final quotes = ind is Map ? ind['quote'] : null;
  final quote = quotes is List && quotes.isNotEmpty ? quotes.first : null;
  final closes = quote is Map ? quote['close'] : null;
  if (ts is! List || closes is! List) return const [];
  final byDay = <String, int>{};
  for (var i = 0; i < ts.length && i < closes.length; i++) {
    final c = doubleE4(closes[i]);
    if (c == null || ts[i] is! int) continue;
    final ist = DateTime.fromMillisecondsSinceEpoch(ts[i] * 1000, isUtc: true)
        .add(const Duration(hours: 5, minutes: 30));
    byDay[fmtDay(DateTime.utc(ist.year, ist.month, ist.day))] = c; // last bar of a day wins
  }
  return byDay.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => a.$1.compareTo(b.$1));
}

Future<List<(String, int)>> yahooDaily(Net n, String ticker, {String range = '5d'}) async {
  if (!RegExp(r'^[\^A-Z0-9&.\-]{1,25}$').hasMatch(ticker)) throw FetchError('yahoo', 'bad ticker');
  final r = await n.get('yahoo',
      Uri.https('query1.finance.yahoo.com', '/v8/finance/chart/$ticker', {'range': range, 'interval': '1d'}));
  return parseYahooChart(r.body);
}

/// Cookie + crumb session for quoteSummary (fundamentals).
class YahooSession {
  final Net n;
  String? _cookie, _crumb;
  YahooSession(this.n);

  Future<void> _open() async {
    // fc.yahoo.com answers 404 but sets the session cookie; read the header directly.
    final raw = await n.client
        .get(Uri.parse('https://fc.yahoo.com/'), headers: {'User-Agent': browserUa}).timeout(n.timeout);
    _cookie = (raw.headers['set-cookie'] ?? '').split(';').first;
    final c = await n.get('yahoo', Uri.parse('https://query2.finance.yahoo.com/v1/test/getcrumb'),
        headers: {'Cookie': _cookie!});
    _crumb = c.body.trim();
    if (_crumb!.isEmpty || _crumb!.contains('<')) throw FetchError('yahoo', 'no crumb');
  }

  /// Selected fundamentals as plain numbers (null when missing).
  Future<Map<String, num?>> fundamentals(String ticker) async {
    if (_crumb == null) await _open();
    final r = await n.get(
        'yahoo',
        Uri.https('query2.finance.yahoo.com', '/v10/finance/quoteSummary/$ticker',
            {'modules': 'financialData,defaultKeyStatistics,summaryDetail', 'crumb': _crumb!}),
        headers: {'Cookie': _cookie!});
    return parseFundamentals(r.body);
  }
}

Map<String, num?> parseFundamentals(String body) {
  final j = jsonDecode(body);
  final qs = j is Map ? j['quoteSummary'] : null;
  final res = qs is Map ? qs['result'] : null;
  final r = res is List && res.isNotEmpty && res.first is Map ? res.first as Map : const {};
  num? raw(String module, String key) {
    final m = r[module];
    final v = m is Map ? m[key] : null;
    final x = v is Map ? v['raw'] : v;
    return x is num && x.isFinite ? x : null;
  }

  return {
    'roe': raw('financialData', 'returnOnEquity'),
    'debtToEquity': raw('financialData', 'debtToEquity'),
    'freeCashflow': raw('financialData', 'freeCashflow'),
    'operatingCashflow': raw('financialData', 'operatingCashflow'),
    'profitMargins': raw('financialData', 'profitMargins'),
    'pe': raw('summaryDetail', 'trailingPE'),
    'pb': raw('defaultKeyStatistics', 'priceToBook'),
    'marketCap': raw('summaryDetail', 'marketCap'),
  };
}
