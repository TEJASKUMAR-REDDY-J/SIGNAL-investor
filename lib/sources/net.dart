import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Browser-like UA: Yahoo rate-limits mobile/unknown agents (probed 2026-10-14).
const browserUa =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';

/// NSE's bot filter accepts this one more reliably than the desktop UA (probed 2026-10-14).
const mobileUa =
    'Mozilla/5.0 (Linux; Android 14; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36';

class FetchError implements Exception {
  final String source;
  final String message;
  FetchError(this.source, this.message);
  @override
  String toString() => '$source: $message';
}

/// Shared HTTP rules: HTTPS only, max 4 in flight, 10 s timeout, 1 retry,
/// 10-minute backoff per source after HTTP 429. Never logs bodies.
class Net {
  final http.Client client;
  final Duration timeout;
  final DateTime Function() now;
  Net({http.Client? client, this.timeout = const Duration(seconds: 10), DateTime Function()? now})
      : client = client ?? http.Client(),
        now = now ?? DateTime.now;

  static const maxConcurrent = 4;
  static const backoff = Duration(minutes: 10);
  int _active = 0;
  final _queue = <Completer<void>>[];
  final _blockedUntil = <String, DateTime>{};

  bool blocked(String source) => _blockedUntil[source]?.isAfter(now()) ?? false;

  Future<http.Response> get(String source, Uri url, {Map<String, String> headers = const {}}) async {
    if (url.scheme != 'https') throw FetchError(source, 'HTTPS only');
    if (blocked(source)) throw FetchError(source, 'rate-limited, backing off');
    while (_active >= maxConcurrent) {
      final c = Completer<void>();
      _queue.add(c);
      await c.future;
    }
    _active++;
    try {
      for (var attempt = 0;; attempt++) {
        try {
          final r = await client
              .get(url, headers: {'User-Agent': browserUa, 'Accept-Language': 'en-US,en;q=0.9', ...headers})
              .timeout(timeout);
          if (r.statusCode == 429) {
            _blockedUntil[source] = now().add(backoff);
            throw FetchError(source, 'HTTP 429');
          }
          if (r.statusCode >= 500 && attempt == 0) continue;
          if (r.statusCode != 200) throw FetchError(source, 'HTTP ${r.statusCode}');
          return r;
        } on TimeoutException {
          if (attempt == 0) continue;
          throw FetchError(source, 'timeout');
        } on SocketException {
          if (attempt == 0) continue;
          throw FetchError(source, 'offline');
        } on http.ClientException catch (e) {
          if (attempt == 0) continue;
          throw FetchError(source, e.message);
        }
      }
    } finally {
      _active--;
      if (_queue.isNotEmpty) _queue.removeAt(0).complete();
    }
  }
}

/// "123.45678" -> 1234568 (x1e4, half-up). Null on junk or non-positive.
int? decimalE4(String? s) {
  if (s == null) return null;
  final m = RegExp(r'^\s*(\d+)(?:\.(\d+))?\s*$').firstMatch(s.replaceAll(',', ''));
  if (m == null) return null;
  final frac = (m[2] ?? '').padRight(5, '0');
  var v = int.parse(m[1]!) * 10000 + int.parse(frac.substring(0, 4));
  if (int.parse(frac[4]) >= 5) v++;
  return v > 0 ? v : null;
}

/// Same for doubles from JSON (prices are 2 dp; rounding error is far below 1e-4).
int? doubleE4(Object? d) => d is num && d > 0 && d.isFinite ? (d * 10000).round() : null;
