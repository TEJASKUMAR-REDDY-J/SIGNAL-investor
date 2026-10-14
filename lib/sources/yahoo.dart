import 'dart:convert';
import 'dart:math';

import '../engine/lots.dart';
import 'net.dart';

// query1.finance.yahoo.com/v8/finance/chart/{T}.NS?range=..&interval=1d, probed 2026-10-14
// (unofficial; 429 for mobile UAs). chart.result[0]: {meta, timestamp[], indicators.quote[0].close[]}
// quoteSummary needs a cookie (fc.yahoo.com) + crumb (/v1/test/getcrumb).
// v7/finance/spark?symbols=A,B&range=1d&interval=1d (probed 2026-10-14): up to 20 symbols per call (more -> 400);
// spark.result[i] = {symbol, response:[{meta:{regularMarketPrice, chartPreviousClose, previousClose?, regularMarketTime}}]}.

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
    // Yahoo sends float closes (2309.1000976...): NSE prices move in paise, so round to 2 dp.
    final raw = closes[i];
    final c = raw is num && raw > 0 && raw.isFinite ? (raw * 100).round() * 100 : null;
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

/// Latest traded price and the previous close; Yahoo's NSE feed is delayed a few minutes.
class Quote {
  final String ticker;
  final int priceE4;
  final int prevCloseE4;
  final DateTime timeUtc;
  const Quote(this.ticker, this.priceE4, this.prevCloseE4, this.timeUtc);

  /// IST calendar day of the last trade, as stored in the prices table.
  String get day {
    final ist = timeUtc.add(const Duration(hours: 5, minutes: 30));
    return fmtDay(DateTime.utc(ist.year, ist.month, ist.day));
  }

  int get changeBps => prevCloseE4 == 0 ? 0 : ((priceE4 - prevCloseE4) * 10000 / prevCloseE4).round();
}

int? _paiseE4(Object? v) => v is num && v > 0 && v.isFinite ? (v * 100).round() * 100 : null;

List<Quote> parseSpark(String body) {
  final j = jsonDecode(body);
  final res = j is Map && j['spark'] is Map ? (j['spark'] as Map)['result'] : null;
  if (res is! List) throw const FormatException('spark shape');
  final out = <Quote>[];
  for (final r in res) {
    if (r is! Map || r['response'] is! List || (r['response'] as List).isEmpty) continue;
    final first = (r['response'] as List).first;
    final m = first is Map ? first['meta'] : null;
    if (m is! Map) continue;
    final price = _paiseE4(m['regularMarketPrice']);
    final prev = _paiseE4(m['previousClose'] ?? m['chartPreviousClose']);
    final t = m['regularMarketTime'];
    if (price == null || prev == null || t is! int) continue;
    out.add(Quote(r['symbol'].toString(), price, prev, DateTime.fromMillisecondsSinceEpoch(t * 1000, isUtc: true)));
  }
  return out;
}

/// Batched live quotes, 20 tickers per request.
Future<List<Quote>> yahooQuotes(Net n, List<String> tickers) async {
  final ok = [for (final t in tickers) if (RegExp(r'^[\^A-Z0-9&.\-]{1,25}$').hasMatch(t)) t];
  final out = <Quote>[];
  for (var i = 0; i < ok.length; i += 20) {
    final batch = ok.sublist(i, i + 20 > ok.length ? ok.length : i + 20);
    final r = await n.get('yahoo', Uri.https('query1.finance.yahoo.com', '/v7/finance/spark',
        {'symbols': batch.join(','), 'range': '1d', 'interval': '1d'}));
    out.addAll(parseSpark(r.body));
  }
  return out;
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
    // Growth (year on year, latest quarter) and context for the stock page.
    'revenueGrowth': raw('financialData', 'revenueGrowth'),
    'earningsGrowth': raw('financialData', 'earningsGrowth'),
    'operatingMargins': raw('financialData', 'operatingMargins'),
    'forwardPe': raw('defaultKeyStatistics', 'forwardPE'),
    'dividendYield': raw('summaryDetail', 'dividendYield'),
    'high52': raw('summaryDetail', 'fiftyTwoWeekHigh'),
    'low52': raw('summaryDetail', 'fiftyTwoWeekLow'),
    'beta': raw('defaultKeyStatistics', 'beta'),
  };
}

/// Quote plus recent daily closes (oldest first, paise-rounded) for many tickers,
/// 20 per request. range: 1mo gives about 21 closes.
Future<Map<String, (Quote, List<int>)>> yahooSparkHistory(Net n, List<String> tickers, {String range = '1mo'}) async {
  final ok = [for (final t in tickers) if (RegExp(r'^[\^A-Z0-9&.\-]{1,25}$').hasMatch(t)) t];
  final out = <String, (Quote, List<int>)>{};
  for (var i = 0; i < ok.length; i += 20) {
    final batch = ok.sublist(i, min(i + 20, ok.length));
    final r = await n.get('yahoo', Uri.https('query1.finance.yahoo.com', '/v7/finance/spark',
        {'symbols': batch.join(','), 'range': range, 'interval': '1d'}));
    out.addAll(parseSparkHistory(r.body));
  }
  return out;
}

Map<String, (Quote, List<int>)> parseSparkHistory(String body) {
  final quotes = {for (final q in parseSpark(body)) q.ticker: q};
  final j = jsonDecode(body) as Map;
  final out = <String, (Quote, List<int>)>{};
  for (final r in ((j['spark'] as Map)['result'] as List)) {
    if (r is! Map) continue;
    final q = quotes[r['symbol']];
    final resp = r['response'];
    if (q == null || resp is! List || resp.isEmpty) continue;
    final ind = (resp.first as Map)['indicators'];
    final quote = ind is Map && ind['quote'] is List && (ind['quote'] as List).isNotEmpty ? (ind['quote'] as List).first : null;
    final closes = quote is Map && quote['close'] is List ? quote['close'] as List : const [];
    final cs = [for (final c in closes) if (_paiseE4(c) != null) _paiseE4(c)!];
    // chartPreviousClose here is the close before the whole range: yesterday is the
    // second-last close instead.
    out[q.ticker] = (Quote(q.ticker, q.priceE4, cs.length >= 2 ? cs[cs.length - 2] : q.prevCloseE4, q.timeUtc), cs);
  }
  return out;
}

/// Daily highs, lows, closes and volumes (oldest first) for ATR and volume surges.
class Ohlc {
  final List<double> high, low, close, volume;
  const Ohlc(this.high, this.low, this.close, this.volume);
}

Ohlc parseYahooOhlc(String body) {
  final r = ((jsonDecode(body) as Map)['chart'] as Map)['result'] as List;
  final q = (((r.first as Map)['indicators'] as Map)['quote'] as List).first as Map;
  final h = <double>[], l = <double>[], c = <double>[], v = <double>[];
  final n = (q['close'] as List).length;
  for (var i = 0; i < n; i++) {
    final hi = (q['high'] as List)[i], lo = (q['low'] as List)[i], cl = (q['close'] as List)[i], vo = (q['volume'] as List)[i];
    if (hi is! num || lo is! num || cl is! num) continue;
    h.add(hi.toDouble());
    l.add(lo.toDouble());
    c.add(cl.toDouble());
    v.add(vo is num ? vo.toDouble() : 0);
  }
  return Ohlc(h, l, c, v);
}

Future<Ohlc> yahooOhlc(Net n, String ticker, {String range = '6mo'}) async {
  if (!RegExp(r'^[\^A-Z0-9&.\-]{1,25}$').hasMatch(ticker)) throw FetchError('yahoo', 'bad ticker');
  final r = await n.get('yahoo', Uri.https('query1.finance.yahoo.com', '/v8/finance/chart/$ticker', {'range': range, 'interval': '1d'}));
  return parseYahooOhlc(r.body);
}
