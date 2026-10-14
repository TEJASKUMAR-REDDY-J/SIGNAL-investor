import '../db/db.dart';

/// Filing categories that raise an alert without any LLM (spec section 7).
const filingAlertKeywords = {
  'results': ['financial result', 'results', 'quarterly result', 'outcome of board meeting'],
  'auditor': ['auditor', 'resignation of statutory auditor'],
  'pledge': ['pledge', 'encumbrance', 'invocation'],
  'credit rating': ['credit rating', 'rating'],
  'management exit': ['resignation', 'cessation', 'key managerial', 'chief executive', 'managing director', 'cfo'],
};

/// Alert category for a filing subject, or null for routine filings.
String? filingCategory(String subject) {
  final s = subject.toLowerCase();
  for (final e in filingAlertKeywords.entries) {
    if (e.value.any(s.contains)) return e.key;
  }
  return null;
}

class Alert {
  final int instrumentId;
  final String title;
  final String detail;
  final DateTime at;
  final String kind; // news | filing
  const Alert(this.instrumentId, this.title, this.detail, this.at, this.kind);
}

/// Alerts fire only for: a negative label on a holding from 2+ different
/// publishers within 48 hours; or a filing in an alert category (last 7 days).
List<Alert> alertsFor({
  required Set<int> held,
  required List<NewsItem> news,
  required List<Filing> filings,
  required DateTime nowUtc,
}) {
  final out = <Alert>[];
  final byInst = <int, List<NewsItem>>{};
  for (final n in news) {
    if (n.instrumentId == null || !held.contains(n.instrumentId) || n.label != 'negative') continue;
    if (nowUtc.difference(n.publishedAt.toUtc()) > const Duration(hours: 48)) continue;
    (byInst[n.instrumentId!] ??= []).add(n);
  }
  for (final e in byInst.entries) {
    final pubs = {for (final n in e.value) n.publisher.toLowerCase()};
    if (pubs.length >= 2) {
      final latest = e.value.map((n) => n.publishedAt).reduce((a, b) => a.isAfter(b) ? a : b);
      out.add(Alert(e.key, 'Negative coverage from ${pubs.length} publishers',
          e.value.map((n) => '${n.publisher}: ${n.title}').take(3).join('\n'), latest, 'news'));
    }
  }
  for (final f in filings) {
    if (!held.contains(f.instrumentId)) continue;
    final cat = filingCategory('${f.category} ${f.subject}');
    final day = DateTime.parse('${f.date}T00:00:00Z');
    if (cat == null || nowUtc.difference(day) > const Duration(days: 7)) continue;
    out.add(Alert(f.instrumentId, 'Filing: $cat', f.subject, day, 'filing'));
  }
  out.sort((a, b) => b.at.compareTo(a.at));
  return out;
}
