import '../db/db.dart';

/// News points for one company: each AI-labelled headline counts +1 (positive)
/// or -1 (negative), weighted by the model's confidence. Neutral/unclear count 0.
class NewsScore {
  final int instrumentId;
  final double points;
  final int positive, negative, total;
  final NewsItem? latest; // newest labelled headline
  const NewsScore(this.instrumentId, this.points, this.positive, this.negative, this.total, this.latest);

  String get label => points >= 0.5 ? 'positive' : (points <= -0.5 ? 'negative' : 'mixed');
}

/// Scores over [window] (default 7 days) for every company with labelled news,
/// sorted by how strong the signal is (largest absolute points first).
List<NewsScore> newsScores(Iterable<NewsItem> items, DateTime nowUtc, {Duration window = const Duration(days: 7)}) {
  final from = nowUtc.subtract(window);
  final by = <int, List<NewsItem>>{};
  for (final n in items) {
    if (n.instrumentId == null || n.label == null || n.publishedAt.toUtc().isBefore(from)) continue;
    (by[n.instrumentId!] ??= []).add(n);
  }
  final out = <NewsScore>[];
  for (final e in by.entries) {
    var pts = 0.0, pos = 0, neg = 0;
    for (final n in e.value) {
      final c = n.confidence ?? 0.5;
      if (n.label == 'positive') {
        pts += c;
        pos++;
      } else if (n.label == 'negative') {
        pts -= c;
        neg++;
      }
    }
    e.value.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    out.add(NewsScore(e.key, (pts * 10).round() / 10, pos, neg, e.value.length, e.value.first));
  }
  out.sort((a, b) => b.points.abs().compareTo(a.points.abs()));
  return out;
}

/// One-line digest for the notification, or null when there is nothing labelled.
String? digestLine(List<NewsScore> scores, Map<int, String> names) {
  final pos = scores.fold(0, (a, s) => a + s.positive), neg = scores.fold(0, (a, s) => a + s.negative);
  if (pos + neg == 0) return null;
  final top = scores.first;
  final name = names[top.instrumentId] ?? 'A company you follow';
  return '$pos positive, $neg negative across ${scores.length} compan${scores.length == 1 ? 'y' : 'ies'}. '
      '$name: ${top.latest?.title ?? ''}';
}
