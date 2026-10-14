import 'dart:convert';

import 'package:flutter/material.dart';

import '../engine/fund_rank.dart';
import '../engine/portfolio.dart';
import '../engine/scan_config.dart';
import '../engine/scoring.dart';
import '../pipeline/instruments.dart';
import '../pipeline/scan.dart';
import '../sources/amfi.dart';
import '../sources/net.dart';
import 'ask.dart';
import 'holding.dart';
import 'lab.dart';
import 'sandbox.dart';
import 'theme.dart';
import 'widgets.dart';

const categoryBlurb = {
  'Large Cap Fund': 'India\'s 100 biggest companies. The steadiest kind of equity fund.',
  'Flexi Cap Fund': 'Any company size; the manager decides the mix.',
  'Large & Mid Cap Fund': 'At least 35% each in large and mid-sized companies.',
  'Mid Cap Fund': 'Companies ranked 101 to 250. More growth, bigger swings.',
  'Small Cap Fund': 'Smaller companies. The biggest swings; for money you will not touch for 7+ years.',
  'Multi Cap Fund': 'At least 25% each in large, mid and small companies.',
  'ELSS': 'Tax-saving funds (old tax regime) with a 3-year lock-in.',
  'Focused Fund': 'At most 30 stocks, so results depend more on a few picks.',
  'Value Fund': 'Buys companies that look cheap against their earnings or assets.',
};

/// Rule-ranked ideas. The rules choose; "Why?" asks the AI to explain.
class AdvisorScreen extends StatefulWidget {
  final Session session;
  final int initialTab;
  const AdvisorScreen({super.key, required this.session, this.initialTab = 0});
  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  Session get s => widget.session;
  CancelToken? _cancel;
  int _done = 0, _total = 0;
  String _what = '';
  String? _error;
  // One lookup per idea: rebuilds must not race to insert the same instrument twice.
  final _ids = <String, Future<int>>{};

  Future<bool> _okToDownload(String what) async {
    if (await onWifi()) return true;
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Not on Wi-Fi'),
            content: Text('$what Continue on mobile data?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Later')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _run(bool funds) async {
    if (!await _okToDownload(funds
        ? 'Updating fund data downloads about 10 MB the first time (5 years of NAVs for ~200 funds).'
        : 'The first stock scan downloads about 15 MB (fundamentals and prices for the NIFTY 500).')) {
      return;
    }
    final c = CancelToken();
    setState(() => (_cancel = c, _error = null, _done = 0, _total = 0));
    void progress(int d, int t, String w) {
      if (mounted) setState(() => (_done = d, _total = t, _what = w));
    }

    try {
      if (funds) {
        await runFundScan(s.market, onProgress: progress, cancel: c);
      } else {
        final held = {for (final h in s.portfolio.value?.holdings ?? const <Holding>[]) ?h.instrument?.nseSymbol};
        final r = await runScan(s.market, Net(), onProgress: progress, cancel: c, exclude: held);
        for (final x in r) {
          await s.db.upsertSignal(await ensureStock(s.market, x.input.symbol, x.input.name), buyCandidateRule,
              jsonEncode(x.inputs), scanRuleVersion);
        }
      }
      await s.reloadIdeas?.call();
    } on FetchError catch (e) {
      if (mounted) setState(() => _error = e.message);
      await s.reloadIdeas?.call();
    } catch (e) {
      if (mounted) setState(() => _error = 'Stopped: $e');
    } finally {
      if (mounted) setState(() => _cancel = null);
    }
  }

  Widget _progress() {
    final running = _cancel != null;
    if (!running) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LinearProgressIndicator(value: _total == 0 ? null : _done / _total),
          const SizedBox(height: 6),
          Text('$_done / $_total · $_what', maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          const Text('You can leave this screen; finished parts are saved.', style: TextStyle(fontSize: 12)),
          TextButton(onPressed: () => _cancel!.cancelled = true, child: const Text('Stop')),
        ]),
      ),
    );
  }

  Future<void> _open(int id) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => HoldingScreen(session: s, instrumentId: id)));

  void _why(String name, String question, List<String> facts) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AskScreen(session: s, initialQuestion: question, extraContext: ['About $name:', ...facts])));

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        initialIndex: widget.initialTab,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Advisor'),
            bottom: const TabBar(tabs: [Tab(text: 'Stocks'), Tab(text: 'Mutual funds')]),
          ),
          body: TabBarView(children: [_stocks(context), _funds(context)]),
        ),
      );

  Widget _stocks(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: s.stockIdeas,
      builder: (context, ideas, _) => ListView(padding: const EdgeInsets.all(12), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('How the picks are made', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Every NIFTY 500 company (large, mid and small caps) is checked for profitability (ROE ≥ ${(minRoe * 100).round()}%), '
                'low debt, positive cash flow and size. Those that pass are ranked on quality ${(wQuality * 100).round()}%, '
                'growth ${(wGrowth * 100).round()}%, value ${(wValue * 100).round()}% and momentum ${(wMomentum * 100).round()}%. '
                'Companies you already own are left out. Fixed rules, not opinions; the AI only explains them.',
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 10),
              if (_cancel == null)
                FilledButton.tonalIcon(
                  onPressed: () => _run(false),
                  icon: const Icon(Icons.refresh),
                  label: Text(ideas == null || ideas.isEmpty ? 'Run the first scan (about 3 minutes)' : 'Update data'),
                ),
            ]),
          ),
        ),
        _progress(),
        if (_error != null) Notice(icon: Icons.error_outline, color: cs.loss, text: _error!),
        if (ideas != null && ideas.isEmpty && _cancel == null)
          const EmptyState(
              icon: Icons.radar,
              title: 'No ideas yet',
              message: 'Run the first scan. After that, ideas load instantly and refresh a little every day in the background.'),
        for (final (i, c) in (ideas ?? const <Candidate>[]).indexed) _stockCard(context, i, c),
        const Fine('A ranking is not a recommendation. Fundamentals and prices from Yahoo Finance (unofficial). Promoter '
            'pledge data is not available from a free source, so check it yourself. Most active fund managers trail the '
            'index over 10 years; keep most money in index funds.'),
      ]),
    );
  }

  Widget _stockCard(BuildContext context, int i, Candidate c) {
    final cs = Theme.of(context).colorScheme;
    Future<int> id() => _ids.putIfAbsent('s:${c.input.symbol}', () => ensureStock(s.market, c.input.symbol, c.input.name));
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async => _open(await id()),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 14, backgroundColor: cs.primaryContainer, child: Text('${i + 1}', style: TextStyle(color: cs.onPrimaryContainer))),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.input.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${c.input.symbol} · ${c.input.industry}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ]),
                ),
                Column(children: [
                  Text('${(c.score * 100).round()}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.primary)),
                  Text('score', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ]),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                _bar(context, 'Quality', c.quality),
                _bar(context, 'Growth', c.growth),
                _bar(context, 'Value', c.value),
                _bar(context, 'Momentum', c.momentum),
              ]),
              const SizedBox(height: 8),
              for (final r in c.reasons) Text('• $r'),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  dense: true,
                  title: Text('What would break the case', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  children: [for (final b in c.breaks) Align(alignment: Alignment.centerLeft, child: Text('• $b'))],
                ),
              ),
              Row(children: [
                TextButton.icon(
                  onPressed: () => _why(
                      c.input.name,
                      'Why does ${c.input.name} rank #${i + 1} in the Advisor? Explain its growth, what the numbers mean, '
                      'the risks, and how it compares with the other top ideas.',
                      [...c.reasons, 'Advisor score ${(c.score * 100).round()} of 100']),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Why?'),
                ),
                ValueListenableBuilder(
                  valueListenable: s.watch,
                  builder: (context, w, _) => FutureBuilder(
                    future: id(),
                    builder: (context, snap) {
                      final on = snap.hasData && w.contains(snap.data);
                      return TextButton.icon(
                        onPressed: snap.hasData ? () => s.db.setWatched(snap.data!, !on) : null,
                        icon: Icon(on ? Icons.star : Icons.star_border, size: 18),
                        label: Text(on ? 'Watching' : 'Watch'),
                      );
                    },
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final i = await id();
                    if (context.mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SandboxScreen(session: s, buyInstrumentId: i)));
                    }
                  },
                  child: const Text('Practice'),
                ),
              ]),
              Text('Data as of ${prettyDay(c.input.dataAsOf)}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, String label, double v) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.06 + 0.16 * v), borderRadius: BorderRadius.circular(8)),
      child: Text('$label ${(v * 100).round()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _funds(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: s.fundIdeas,
      builder: (context, ideas, _) => ListView(padding: const EdgeInsets.all(12), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('How funds are ranked', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Direct plans only (no distributor commission). Within each category: 3-year growth 40%, 5-year growth 30%, '
                'and a smaller worst fall 30%, all from real NAV history. Funds younger than 3 years are left out. '
                'For most people the core is a low-cost Nifty 50 index fund; these are for the rest.',
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 10),
              if (_cancel == null)
                FilledButton.tonalIcon(
                  onPressed: () => _run(true),
                  icon: const Icon(Icons.refresh),
                  label: Text(ideas == null || ideas.isEmpty ? 'Load fund rankings (about 2 minutes)' : 'Update data'),
                ),
            ]),
          ),
        ),
        _progress(),
        if (_error != null) Notice(icon: Icons.error_outline, color: cs.loss, text: _error!),
        for (final cat in fundCategories)
          if ((ideas ?? const {})[cat]?.isNotEmpty ?? false) ...[
            SectionHeader(cat.replaceAll(' Fund', '')),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(categoryBlurb[cat] ?? '', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
            ),
            for (final (i, f) in ideas![cat]!.indexed) _fundCard(context, i, f),
          ],
        const Fine('Past returns do not repeat on schedule. NAV history from AMFI via mfapi.in. Check the expense ratio and '
            'the fund\'s factsheet before investing. A ranking is not a recommendation.'),
      ]),
    );
  }

  Widget _fundCard(BuildContext context, int i, FundIdea f) {
    final cs = Theme.of(context).colorScheme;
    Future<int> id() => _ids.putIfAbsent('f:${f.m.code}', () => ensureFund(s.market, f.m.code, f.m.name));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async => _open(await id()),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${i + 1}  ', style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary)),
              Expanded(child: Text(f.m.name, style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 4),
            for (final r in f.reasons) Text('• $r', style: const TextStyle(fontSize: 13)),
            Row(children: [
              TextButton.icon(
                onPressed: () => _why(f.m.name, 'Explain ${f.m.name}: its strategy, why it ranks well in its category, its risks, '
                    'and whether it suits a long-term SIP.', f.reasons),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Why?'),
              ),
              ValueListenableBuilder(
                valueListenable: s.watch,
                builder: (context, w, _) => FutureBuilder(
                  future: id(),
                  builder: (context, snap) {
                    final on = snap.hasData && w.contains(snap.data);
                    return TextButton.icon(
                      onPressed: snap.hasData ? () => s.db.setWatched(snap.data!, !on) : null,
                      icon: Icon(on ? Icons.star : Icons.star_border, size: 18),
                      label: Text(on ? 'Watching' : 'Watch'),
                    );
                  },
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
