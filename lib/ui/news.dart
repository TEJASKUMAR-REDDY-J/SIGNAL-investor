import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/db.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import '../engine/alerts.dart';
import '../pipeline/feeds.dart';
import 'theme.dart';
import 'widgets.dart';

Color labelColor(ColorScheme cs, String? l) => switch (l) {
      'positive' => cs.gain,
      'negative' => cs.loss,
      'neutral' => cs.onSurfaceVariant,
      _ => cs.outline,
    };

String ago(DateTime t) {
  final d = DateTime.now().toUtc().difference(t.toUtc());
  if (d.inMinutes < 60) return '${d.inMinutes.clamp(1, 59)} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

/// Filings and matched news for one holding. Tap copies the link.
class NewsSection extends StatelessWidget {
  final Session session;
  final int instrumentId;
  const NewsSection({super.key, required this.session, required this.instrumentId});

  @override
  Widget build(BuildContext context) {
    final m = session.market;
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: (m.select(m.newsItems)
            ..where((n) => n.instrumentId.equals(instrumentId))
            ..orderBy([(n) => OrderingTerm.desc(n.publishedAt)])
            ..limit(12))
          .watch(),
      builder: (context, news) => StreamBuilder(
        stream: (m.select(m.filings)
              ..where((f) => f.instrumentId.equals(instrumentId))
              ..orderBy([(f) => OrderingTerm.desc(f.date)])
              ..limit(8))
            .watch(),
        builder: (context, filings) {
          final n = news.data ?? const <NewsItem>[];
          final f = filings.data ?? const <Filing>[];
          if (n.isEmpty && f.isEmpty) return const SizedBox.shrink();
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionHeader('Filings and news'),
            Card(
              child: Column(children: [
                for (final x in f)
                  ListTile(
                    dense: true,
                    leading: Icon(filingCategory('${x.category} ${x.subject}') == null ? Icons.description_outlined : Icons.priority_high,
                        color: filingCategory('${x.category} ${x.subject}') == null ? cs.onSurfaceVariant : cs.warn),
                    title: Text(x.category, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('NSE filing · ${prettyDayIso(x.date)}${x.subject.isEmpty ? '' : '\n${x.subject}'}',
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    onTap: x.url.isEmpty ? null : () => _copy(context, x.url),
                  ),
                for (final x in n)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.article_outlined, color: labelColor(cs, x.label)),
                    title: Text(x.title, maxLines: 3, overflow: TextOverflow.ellipsis),
                    subtitle: Text([
                      x.publisher,
                      ago(x.publishedAt),
                      if (x.label != null) 'AI: ${x.label}${x.reason == null ? '' : ' (${x.reason})'}',
                    ].join(' · ')),
                    onTap: () => _copy(context, x.url),
                  ),
              ]),
            ),
            const Fine('Tap to copy the link. News labels are AI guesses from headlines only. Alerts need 2+ publishers.'),
          ]);
        },
      ),
    );
  }

  void _copy(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    snack(context, 'Link copied');
  }
}

String prettyDayIso(String ymd) {
  final p = ymd.split('-');
  return p.length == 3 ? '${int.parse(p[2])} ${months[int.parse(p[1]) - 1]} ${p[0]}' : ymd;
}

/// Alerts per section 7: 2+ publishers negative within 48 h, or an alert-class filing.
class AlertsScreen extends StatelessWidget {
  final Session session;
  const AlertsScreen({super.key, required this.session});
  @override
  Widget build(BuildContext context) {
    final p = session.portfolio.value!;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: FutureBuilder(
        future: loadAlerts(session.market, {for (final h in p.holdings) h.instrumentId}, DateTime.now().toUtc()),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'All quiet',
              message: 'Alerts appear only for serious filings or negative coverage from two or more publishers. '
                  'One headline is never a reason to act.',
            );
          }
          return ListView(padding: const EdgeInsets.all(12), children: [
            for (final a in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: Icon(a.kind == 'filing' ? Icons.gavel : Icons.campaign_outlined, color: cs.warn),
                    title: Text('${p.instruments[a.instrumentId]?.name ?? ''}: ${a.title}'),
                    subtitle: Text(a.detail, maxLines: 4, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            const Fine('An alert is a reason to read, not to sell. Check it against your written thesis first.'),
          ]);
        },
      ),
    );
  }
}

/// Bell with a dot when there is something to read.
class AlertBell extends StatelessWidget {
  final Session session;
  const AlertBell({super.key, required this.session});
  @override
  Widget build(BuildContext context) {
    final p = session.portfolio.value;
    return FutureBuilder(
      future: p == null
          ? Future.value(const <Alert>[])
          : loadAlerts(session.market, {for (final h in p.holdings) h.instrumentId}, DateTime.now().toUtc()),
      builder: (context, snap) => IconButton(
        tooltip: 'Alerts',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AlertsScreen(session: session))),
        icon: Badge(
          isLabelVisible: (snap.data?.length ?? 0) > 0,
          label: Text('${snap.data?.length ?? 0}'),
          child: const Icon(Icons.notifications_outlined),
        ),
      ),
    );
  }
}
