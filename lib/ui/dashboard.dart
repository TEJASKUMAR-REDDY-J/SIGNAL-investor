import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/db.dart';
import '../db/open_db.dart';
import '../engine/calendar.dart';
import '../engine/habits.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../engine/sell_rules.dart';
import '../engine/valuation.dart';
import '../sources/mfapi.dart';
import 'holding.dart';
import 'logo.dart';
import 'news.dart';
import 'patience.dart';
import 'sell_flow.dart';
import 'settings.dart';
import 'theme.dart';
import 'widgets.dart';
import 'wrapped.dart';

/// Tile id -> title. Order here is the default order.
const tileTitles = {
  'donext': 'Do next',
  'summary': 'Portfolio',
  'growth': 'You vs the index',
  'alloc': 'Allocation',
  'tax': 'Tax this FY',
  'discipline': 'Discipline',
  'longterm': 'Ripening soon',
  'sips': 'SIPs',
  'goals': 'Goals',
  'top': 'Top holdings',
  'market': 'Market calendar',
};
const _defaultSize = {
  'donext': 3,
  'summary': 3,
  'growth': 3,
  'alloc': 1,
  'tax': 1,
  'discipline': 2,
  'goals': 2,
  'top': 2,
  'market': 2,
};

class Layout {
  List<String> order;
  Set<String> hidden;
  Map<String, int> sizes; // 1 small, 2 wide, 3 large
  Layout(this.order, this.hidden, this.sizes);

  factory Layout.parse(String? s) {
    final j = s == null ? const {} : jsonDecode(s) as Map;
    final order = [...((j['order'] as List?)?.cast<String>() ?? const <String>[])]
      ..removeWhere((k) => !tileTitles.containsKey(k));
    for (final (i, k) in tileTitles.keys.indexed) {
      if (!order.contains(k)) order.insert(i.clamp(0, order.length), k);
    }
    return Layout(order, {...((j['hidden'] as List?)?.cast<String>() ?? const <String>[])},
        {...((j['sizes'] as Map?)?.cast<String, int>() ?? const <String, int>{})});
  }

  int size(String k) => sizes[k] ?? _defaultSize[k] ?? 1;
  String encode() => jsonEncode({'order': order, 'hidden': hidden.toList(), 'sizes': sizes});
}

class Dashboard extends StatefulWidget {
  final Session session;
  final ValueChanged<int> onOpenTab;
  const Dashboard({super.key, required this.session, required this.onOpenTab});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Layout _layout = Layout.parse(null);
  String get _key => 'layout3_${widget.session.profile.id}';
  Session get s => widget.session;

  @override
  void initState() {
    super.initState();
    storage.read(key: _key).then((v) {
      if (v != null && mounted) setState(() => _layout = Layout.parse(v));
    });
  }

  void _save() {
    setState(() {});
    storage.write(key: _key, value: _layout.encode());
  }

  void _cycle(String k) {
    HapticFeedback.selectionClick();
    _layout.sizes[k] = _layout.size(k) % 3 + 1;
    _save();
  }

  Future<void> _pullRefresh() async {
    await s.refresh?.call(force: true);
    if (mounted) _showReceipt();
  }

  void _showReceipt() => showModalBottomSheet(
        context: context,
        builder: (ctx) => ValueListenableBuilder(
          valueListenable: s.receipt,
          builder: (ctx, lines, _) {
            final cs = Theme.of(ctx).colorScheme;
            final t = TimeOfDay.now().format(ctx);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Refresh receipt', style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Each source, checked at $t', style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  if (lines == null || lines.isEmpty) const Text('Everything was already up to date.'),
                  for (final (i, l) in (lines ?? const []).indexed)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 250 + i * 120),
                      builder: (ctx, v, child) => Opacity(opacity: v, child: child),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Icon(l.ok ? Icons.check_circle : Icons.error_outline, color: l.ok ? cs.gain : cs.loss, size: 20),
                          const SizedBox(width: 10),
                          SizedBox(width: 130, child: Text(l.label, style: const TextStyle(fontWeight: FontWeight.w600))),
                          Expanded(child: Text(l.detail, style: TextStyle(color: cs.onSurfaceVariant))),
                        ]),
                      ),
                    ),
                  const Fine('Prices: Yahoo (unofficial), cross-checked with NSE bhavcopy. NAVs: mfapi.in.'),
                ]),
              ),
            );
          },
        ),
      );

  void _customize() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setSheet) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.75,
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                  child: Row(children: [
                    Expanded(child: Text('Customize home', style: Theme.of(ctx).textTheme.titleLarge)),
                    TextButton(
                      onPressed: () {
                        _layout = Layout.parse(null);
                        _save();
                        setSheet(() {});
                      },
                      child: const Text('Reset'),
                    ),
                  ]),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Drag to reorder. Pick a size or hide a card. Tip: long-press a card on Home to resize it.'),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ReorderableListView(
                    buildDefaultDragHandles: false,
                    onReorderItem: (a, b) {
                      _layout.order.insert(b, _layout.order.removeAt(a));
                      _save();
                      setSheet(() {});
                    },
                    children: [
                      for (final (i, k) in _layout.order.indexed)
                        ListTile(
                          key: ValueKey(k),
                          leading: ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_indicator)),
                          title: Text(tileTitles[k]!),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: SegmentedButton<int>(
                                showSelectedIcon: false,
                                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                                segments: const [
                                  ButtonSegment(value: 1, label: Text('S')),
                                  ButtonSegment(value: 2, label: Text('M')),
                                  ButtonSegment(value: 3, label: Text('L')),
                                ],
                                selected: {_layout.size(k)},
                                onSelectionChanged: (v) {
                                  _layout.sizes[k] = v.first;
                                  _save();
                                  setSheet(() {});
                                },
                              ),
                            ),
                          ),
                          trailing: Switch(
                            value: !_layout.hidden.contains(k),
                            onChanged: (on) {
                              on ? _layout.hidden.remove(k) : _layout.hidden.add(k);
                              _save();
                              setSheet(() {});
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: s.portfolio,
        builder: (context, p, _) {
          if (p == null) return const Center(child: CircularProgressIndicator());
          final cs = Theme.of(context).colorScheme;
          final status = nse.status(DateTime.now());
          return RefreshIndicator(
            onRefresh: _pullRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  titleSpacing: 16,
                  title: Row(children: [
                    const _Mark(),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: avatarColor(s.profile.id),
                      child: Text(s.profile.badge, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.profile.name, overflow: TextOverflow.ellipsis),
                        Row(children: [
                          Icon(Icons.circle,
                              size: 8,
                              color: status.phase == MarketPhase.open
                                  ? cs.gain
                                  : (status.phase == MarketPhase.preOpen ? cs.warn : cs.outline)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(status.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w400)),
                          ),
                        ]),
                      ]),
                    ),
                  ]),
                  actions: [
                    ValueListenableBuilder(
                      valueListenable: hideMoney,
                      builder: (context, hide, _) => IconButton(
                        tooltip: hide ? 'Show amounts' : 'Hide amounts',
                        icon: Icon(hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => hideMoney.value = !hide,
                      ),
                    ),
                    AlertBell(session: s),
                    IconButton(tooltip: 'Customize home', icon: const Icon(Icons.dashboard_customize_outlined), onPressed: _customize),
                    IconButton(
                      tooltip: 'Settings',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(session: s))),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                  sliver: SliverToBoxAdapter(child: _body(context, p)),
                ),
              ],
            ),
          );
        },
      );

  Widget _status(BuildContext context, Portfolio p) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: Listenable.merge([s.refreshing, s.lastRefresh]),
      builder: (context, _) {
        final stale = p.staleHoldings;
        final mism = p.holdings.where((h) => h.mismatch).length;
        final String text;
        IconData icon = Icons.check_circle_outline;
        Color color = cs.onSurfaceVariant;
        if (s.refreshing.value) {
          text = 'Refreshing prices…';
          icon = Icons.sync;
        } else if (p.holdings.isNotEmpty && !p.anyPriced) {
          text = 'No prices yet. Pull down to fetch. Values shown at cost.';
          icon = Icons.cloud_off_outlined;
          color = cs.warn;
        } else if (stale.isNotEmpty) {
          final oldest = stale.map((h) => h.price!.day).reduce((a, b) => a.isBefore(b) ? a : b);
          text = 'Prices stale since ${prettyDay(oldest)} · pull to retry';
          icon = Icons.history;
          color = cs.warn;
        } else {
          final t = s.lastRefresh.value;
          text = t == null ? 'Pull down to refresh' : 'Updated ${TimeOfDay.fromDateTime(t.toLocal()).format(context)}';
        }
        return InkWell(
          onTap: _showReceipt,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
            child: Row(children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: color))),
              if (mism > 0) Pill('$mism price check${mism == 1 ? '' : 's'} failed', color: cs.loss, icon: Icons.compare_arrows),
            ]),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, Portfolio p) {
    final cs = Theme.of(context).colorScheme;
    final today = p.today;
    final children = <Widget>[_status(context, p)];

    // Bad-day mode: perspective from the index history the app has fetched.
    final f = p.fall;
    if (f != null) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.waves, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('NIFTY 50 is down ${(-f.todayBps / 100).toStringAsFixed(1)}% today',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ]),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final s = p.book.series(p.indexId!);
                final years = (s.last.day.difference(s.first.day).inDays / 365.25).round();
                final text = f.similarFalls == 0
                    ? 'This is the deepest one-day fall in the $years years of index history on this phone. '
                        'Big days stand out because they are rare.'
                    : 'In the $years years of index history on this phone there were ${f.similarFalls} one-day falls '
                        'at least this deep. '
                        '${f.medianRecoveryDays == null ? '' : 'Half of them were back to the prior close within ${f.medianRecoveryDays} trading days. '}'
                        '${f.unrecovered > 0 ? '${f.unrecovered} have not recovered yet.' : ''}';
                return Text(text, style: TextStyle(color: cs.onSurfaceVariant, height: 1.4));
              }),
              const Fine('Past recoveries are history, not a promise.'),
            ]),
          ),
        ),
      ));
    }

    // Ripe-day card (shown once, after a lot turns long-term).
    children.add(ValueListenableBuilder(
      valueListenable: s.ripened,
      builder: (context, ripe, _) => ripe.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Notice(
                icon: Icons.eco,
                color: cs.gain,
                text: ripe.length == 1
                    ? '${ripe.first.$1}: a lot ripened. It is now long-term and cheaper to sell.'
                    : '${ripe.length} lots ripened since your last visit. They are now long-term.',
                onTap: () => s.ripened.value = const [],
              ),
            ),
    ));

    if (today.month == 4 && p.realized.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Notice(
          icon: Icons.auto_awesome,
          color: cs.primary,
          text: 'Your FY ${p.fy - 1}-${p.fy % 100} Wrapped is ready',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WrappedScreen(p: p, fy: p.fy - 1))),
        ),
      ));
    }

    if (p.txs.isEmpty) {
      return Column(children: [
        ...children,
        const EmptyState(
          icon: Icons.spa_outlined,
          title: 'Nothing here yet',
          message: 'The best day to start a SIP was years ago. The second best is the 5th of next month. '
              'Tap Add to record your first one.',
        ),
        _tiles(context, p, only: const {'market'}),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ...children,
      _tiles(context, p),
      const Fine('Prices are end-of-day from public sources and can be late or wrong. Estimates for listed equity '
          'and equity MFs only. Not investment or tax advice.'),
    ]);
  }

  Widget _tiles(BuildContext context, Portfolio p, {Set<String>? only}) => LayoutBuilder(builder: (context, c) {
        const gap = 10.0;
        final cols = c.maxWidth < 600 ? 2 : (c.maxWidth < 900 ? 3 : 4);
        final unit = (c.maxWidth - gap * (cols - 1)) / cols;
        double width(int size) => switch (size) {
              1 => unit,
              2 when cols > 2 => unit * 2 + gap,
              _ => c.maxWidth,
            };
        final keys = _layout.order.where((k) => !_layout.hidden.contains(k) && (only == null || only.contains(k)));
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (final k in keys)
            AnimatedContainer(
              key: ValueKey('tile-$k'),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: width(_layout.size(k)),
              child: GestureDetector(
                onLongPress: () => _cycle(k),
                child: _Tile(id: k, size: _layout.size(k), p: p, session: s, onOpenTab: widget.onOpenTab),
              ),
            ),
        ]);
      });
}

/// Small brand mark in the app bar.
class _Mark extends StatelessWidget {
  const _Mark();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 26, height: 26, child: SignalLogo());
}

class _Tile extends StatelessWidget {
  final String id;
  final int size;
  final Portfolio p;
  final Session session;
  final ValueChanged<int> onOpenTab;
  const _Tile({required this.id, required this.size, required this.p, required this.session, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final body = switch (id) {
      'donext' => _doNext(context),
      'summary' => _summary(context),
      'alloc' => _alloc(context),
      'growth' => _growth(context),
      'tax' => _tax(context),
      'discipline' => _discipline(context),
      'longterm' => _longTerm(context),
      'sips' => _sipsTile(context),
      'goals' => _goalsTile(context),
      'top' => _top(context),
      _ => _market(context),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tileTitles[id]!.toUpperCase(),
              style: t.labelSmall?.copyWith(letterSpacing: 0.8, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AnimatedSize(duration: const Duration(milliseconds: 200), alignment: Alignment.topLeft, child: body),
        ]),
      ),
    );
  }

  // ---- Do next: one inbox of actions, from rules and dates ----
  Widget _doNext(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final items = <(IconData, Color, String, VoidCallback?)>[];
    for (final x in session.suggestions.value) {
      items.add((
        Icons.rule,
        x.rule <= 2 ? cs.loss : cs.warn,
        'Rule ${x.rule} ${ruleNames[x.rule]}: ${p.instruments[x.instrumentId]?.name ?? ''}'
            '${x.shortTermWarning ? ' · +${rupees(x.extraTaxVsWaitPaise, decimals: false)} tax if sold now' : ''}',
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SellFlow(session: session, instrumentId: x.instrumentId, suggestion: x))),
      ));
    }
    for (final sig in session.openSignals.value.where((s) => s.rule == manualSellRule && s.userAction == 'planned')) {
      final ready = coolOffDone(sig, now);
      items.add((
        ready ? Icons.task_alt : Icons.bedtime_outlined,
        cs.primary,
        ready
            ? 'You planned to sell ${p.instruments[sig.instrumentId]?.name ?? ''} yesterday. Still sure?'
            : 'Sleeping on a sale of ${p.instruments[sig.instrumentId]?.name ?? ''} until ${TimeOfDay.fromDateTime(sig.actedAt!.add(coolOff)).format(context)} tomorrow',
        ready
            ? () => _plannedSheet(context, sig)
            : null,
      ));
    }
    for (final (h, l) in p.upcomingLongTerm.where((e) => e.$2.longTermDate.difference(p.today).inDays <= 14)) {
      items.add((Icons.eco_outlined, cs.gain, '${h.name} ripens ${inDays(l.longTermDate.difference(p.today).inDays)}', () => _open(context, h.instrumentId)));
    }
    if (p.missedSipCount > 0) {
      items.add((Icons.event_busy, cs.warn, '${p.missedSipCount} SIP instalment${p.missedSipCount == 1 ? '' : 's'} not recorded', () => onOpenTab(3)));
    }
    for (final g in p.goals.where((g) => g.equityTooClose)) {
      items.add((Icons.flag, cs.loss, '"${g.goal.name}" is due ${inDays(g.daysLeft)} with ${rupees(g.taggedPaise, decimals: false)} in equity', () => onOpenTab(3)));
    }
    for (final th in session.theses.value.values.where((t) => t.reviewDate != null && !parseDay(t.reviewDate!).isAfter(p.today))) {
      items.add((Icons.rate_review_outlined, cs.primary, 'Review your thesis for ${p.instruments[th.instrumentId]?.name ?? ''}', () => _open(context, th.instrumentId)));
    }
    for (final h in p.holdings.where((h) => h.isMf && isRegularPlan('${h.name} ${h.instrument?.aliases ?? ''}'))) {
      final lo = mulDiv(h.valuePaise, 50, 10000), hi = mulDiv(h.valuePaise, 150, 10000);
      items.add((Icons.savings_outlined, cs.warn,
          '${h.name} looks like a Regular plan: typically ${rupees(lo, decimals: false)}–${rupees(hi, decimals: false)} a year more than Direct',
          () => _open(context, h.instrumentId)));
    }
    for (final h in p.holdings.where((h) => h.mismatch)) {
      items.add((Icons.compare_arrows, cs.loss, '${h.name}: price sources disagree, signals paused', () => _open(context, h.instrumentId)));
    }
    if (items.isEmpty) {
      return Row(children: [
        Icon(Icons.self_improvement, color: cs.gain),
        const SizedBox(width: 10),
        const Expanded(child: Text('Nothing to do. Holding is the plan.')),
      ]);
    }
    final shown = items.take(size == 1 ? 2 : (size == 2 ? 4 : 8)).toList();
    return Column(children: [
      for (final (icon, color, text, tap) in shown)
        InkWell(
          onTap: tap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              if (tap != null) Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
      if (items.length > shown.length)
        Align(alignment: Alignment.centerLeft, child: Text('+ ${items.length - shown.length} more', style: TextStyle(color: cs.onSurfaceVariant))),
    ]);
  }

  void _plannedSheet(BuildContext context, Signal sig) {
    final inputs = jsonDecode(sig.inputsJson) as Map;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Still sure?', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Your reason yesterday: "${sig.note}"'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                session.db.actOnSignal(sig.id, 'done', note: sig.note);
                Navigator.pop(ctx);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SellFlow(session: session, instrumentId: sig.instrumentId)));
              },
              child: Text('Yes, go ahead (sell ${formatScaled((inputs['unitsE4'] as int?) ?? 0, 4)} units)'),
            ),
            TextButton(
              onPressed: () {
                session.db.actOnSignal(sig.id, 'dismissed', note: 'kept holding');
                Navigator.pop(ctx);
                snack(context, 'Kept holding.');
              },
              child: const Text('No, keep holding'),
            ),
          ]),
        ),
      ),
    );
  }

  // ---- Portfolio: since-start figure; today's move only on press-and-hold ----
  Widget _summary(BuildContext context) => _Summary(p: p, size: size);

  Widget _alloc(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sat = p.satellitePaise, core = p.valuePaise - sat;
    final slices = size >= 2
        ? [
            for (final (i, h) in p.holdings.take(5).indexed) (h.name, h.valuePaise, cs.series[i]),
            if (p.holdings.length > 5) ('Others', p.holdings.skip(5).fold(0, (a, h) => a + h.valuePaise), cs.series[5]),
          ]
        : [('Core', core, cs.series[0]), ('Satellite', sat, cs.series[2])];
    final total = slices.fold(0, (a, s) => a + s.$2);
    final chart = SizedBox(
      height: 110,
      width: 110,
      child: RepaintBoundary(
        child: PieChart(PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 32,
          startDegreeOffset: -90,
          sections: [
            for (final s in slices)
              if (s.$2 > 0) PieChartSectionData(value: s.$2.toDouble(), color: s.$3, radius: 16, showTitle: false),
          ],
        )),
      ),
    );
    final legend = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final s in slices)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(child: Text(s.$1, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text(total == 0 ? '0%' : '${(s.$2 * 100 / total).round()}%', style: const TextStyle(fontFeatures: tabular)),
          ]),
        ),
      if (!p.allPriced) Text('Unpriced holdings at cost', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
    ]);
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth < 300
          ? Column(children: [Center(child: chart), const SizedBox(height: 8), legend])
          : Row(children: [chart, const SizedBox(width: 16), Expanded(child: legend)]),
    );
  }

  // ---- You vs the index: value line racing its ghost twin ----
  Widget _growth(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pts = p.months;
    if (pts.length < 2) {
      return Text('A chart appears after your second month of entries.', style: TextStyle(color: cs.onSurfaceVariant));
    }
    final hasValue = pts.every((m) => m.valuePaise != null);
    final hasGhost = pts.every((m) => m.ghostPaise != null);
    List<FlSpot> line(int? Function(MonthPoint) f) =>
        [for (final (i, m) in pts.indexed) if (f(m) != null) FlSpot(i.toDouble(), f(m)! / 100)];
    final you = p.xirr, ghost = p.ghostXirr;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (you != null && ghost != null)
        Wrap(spacing: 16, runSpacing: 4, children: [
          _legend(cs.primary, 'You ${(you * 100).toStringAsFixed(1)}% a year'),
          _legend(cs.onSurfaceVariant.withValues(alpha: 0.6), 'Nifty 50 ghost ${(ghost * 100).toStringAsFixed(1)}%'),
        ])
      else
        Text(hasValue ? 'Fetching index history for the ghost line…' : 'Market values appear after the first refresh.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      if (you != null && ghost != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            you >= ghost
                ? 'Ahead of the index fund by ${((you - ghost) * 100).toStringAsFixed(1)} points a year.'
                : 'Behind the index fund by ${((ghost - you) * 100).toStringAsFixed(1)} points a year. '
                    'If that holds for 12 months, the plan says: switch picks off, keep the index.',
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
        ),
      const SizedBox(height: 10),
      SizedBox(
        height: size >= 3 ? 190 : 110,
        child: RepaintBoundary(
          child: LineChart(LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => cs.inverseSurface,
                getTooltipItems: (touched) => [
                  for (final t in touched)
                    LineTooltipItem(
                      '${t.barIndex == 0 ? monthYear(pts[t.x.toInt()].month) : ''}${t.barIndex == 0 ? '\n' : ''}'
                      '${['Value', 'Ghost', 'Invested'][t.barIndex]} ${rupees((t.y * 100).round(), decimals: false)}',
                      TextStyle(color: cs.onInverseSurface, fontSize: 12),
                    ),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: hasValue ? line((m) => m.valuePaise) : line((m) => m.investedPaise),
                isCurved: true,
                preventCurveOverShooting: true,
                color: cs.primary,
                barWidth: 2.6,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [cs.primary.withValues(alpha: 0.25), cs.primary.withValues(alpha: 0)]),
                ),
              ),
              LineChartBarData(
                show: hasGhost,
                spots: hasGhost ? line((m) => m.ghostPaise) : const [],
                isCurved: true,
                preventCurveOverShooting: true,
                color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                barWidth: 2,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: line((m) => m.investedPaise),
                isStepLineChart: true,
                color: cs.outline.withValues(alpha: 0.5),
                barWidth: 1.2,
                dashArray: [4, 4],
                dotData: const FlDotData(show: false),
              ),
            ],
          )),
        ),
      ),
      const SizedBox(height: 4),
      Wrap(spacing: 14, children: [
        _legend(cs.primary, hasValue ? 'Market value' : 'At cost'),
        if (hasGhost) _legend(cs.onSurfaceVariant.withValues(alpha: 0.45), 'Same money in a Nifty 50 index fund'),
        _legend(cs.outline, 'Money put in'),
      ]),
    ]);
  }

  Widget _legend(Color c, String s) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 3, color: c),
        const SizedBox(width: 6),
        Text(s, style: const TextStyle(fontSize: 12)),
      ]);

  // ---- Tax: the exemption jar ----
  Widget _tax(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final used = p.fyTax.exemptionUsedPaise;
    final left = p.fyTax.exemptionLeftPaise;
    final march = p.today.month == 2 || p.today.month == 3;
    final jar = ExemptionJar(usedPaise: used, today: p.today, size: size == 1 ? 80 : 96);
    final text = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FY ${p.fy}-${(p.fy + 1) % 100}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      Money(left, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      Text('tax-free room left', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      if (march && left > 0)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Use it or lose it on 31 March.', style: TextStyle(color: cs.warn, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
      if (size >= 2) ...[
        const SizedBox(height: 8),
        Wrap(spacing: 14, runSpacing: 4, children: [
          _kv(context, 'STCG', Money(p.fyGains.st, colored: true)),
          _kv(context, 'LTCG', Money(p.fyGains.lt, colored: true)),
          _kv(context, 'Est. tax', Money(p.fyTax.taxPaise)),
        ]),
      ],
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      size == 1
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: jar), const SizedBox(height: 8), text])
          : Row(children: [jar, const SizedBox(width: 18), Expanded(child: text)]),
      if (size >= 3)
        const Fine('STCG 20%, LTCG 12.5% above ₹1.25L, plus 4% cess. Excludes surcharge, other income and carried-forward losses.'),
    ]);
  }

  Widget _kv(BuildContext context, String k, Widget v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w600), child: v),
      ]);

  // ---- Discipline streaks, never usage streaks ----
  Widget _discipline(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final h = habits(p);
    Widget stat(IconData icon, String big, String small) => Expanded(
          child: Row(children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(big, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                Text(small, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ]),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        stat(Icons.autorenew, '${h.sipStreakMonths} mo', 'SIPs kept${h.freePassUsed ? ' (pass used)' : ''}'),
        stat(Icons.hourglass_full, '${h.monthsWithoutShortTermSell} mo', 'no short-term sell'),
      ]),
      if (size >= 2 && h.longestHeld != null) ...[
        const SizedBox(height: 10),
        Text('Longest held: ${h.longestHeld!.$1.name}, since ${prettyDay(h.longestHeld!.$2.buyDate)}',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
      ],
    ]);
  }

  Widget _longTerm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final up = p.upcomingLongTerm;
    if (up.isEmpty) return Text('No lots ripen in the next 90 days.', style: TextStyle(color: cs.onSurfaceVariant));
    return Column(children: [
      for (final (h, l) in up.take(size == 1 ? 2 : (size == 2 ? 4 : 8)))
        InkWell(
          onTap: () => _open(context, h.instrumentId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Icon(Icons.eco_outlined, size: 18, color: cs.gain),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${prettyDay(l.longTermDate)} · ${inDays(l.longTermDate.difference(p.today).inDays)}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
              ),
              if (size >= 2) Money(l.costPaise, style: const TextStyle(fontSize: 13)),
            ]),
          ),
        ),
      if (size >= 2) const Fine('Selling before these dates is taxed as STCG (20%).'),
    ]);
  }

  Widget _sipsTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = p.sips.where((s) => s.plan.active).toList();
    if (p.sips.isEmpty) {
      return InkWell(
        onTap: () => onOpenTab(3),
        child: Text('Add your SIP plans in Plan to track missed instalments.', style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    final monthly = active.fold(0, (a, s) => a + s.plan.amountPaise);
    final next = [...active.where((s) => s.nextDue != null)]..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
    return InkWell(
      onTap: () => onOpenTab(3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Money(monthly, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text('per month · ${active.length} active', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        if (p.missedSipCount > 0) ...[
          const SizedBox(height: 8),
          Pill('${p.missedSipCount} missed', color: cs.warn, icon: Icons.event_busy),
        ],
        if (next.isNotEmpty && size >= 2) ...[
          const SizedBox(height: 8),
          for (final s in next.take(3))
            Text('${p.instruments[s.plan.instrumentId]?.name ?? 'SIP'} · ${prettyDay(s.nextDue!)}',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        ],
      ]),
    );
  }

  Widget _goalsTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (p.goals.isEmpty) {
      return InkWell(
        onTap: () => onOpenTab(3),
        child: Text('Create goals in Plan and tag investments to them.', style: TextStyle(color: cs.onSurfaceVariant)),
      );
    }
    return InkWell(
      onTap: () => onOpenTab(3),
      child: Column(children: [
        for (final g in p.goals.take(size == 1 ? 2 : 4))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(g.goal.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (g.equityTooClose) Icon(Icons.warning_amber, size: 16, color: cs.loss),
                Text(' ${(g.progress * 100).round()}%', style: const TextStyle(fontFeatures: tabular)),
              ]),
              const SizedBox(height: 4),
              Meter(g.progress, height: 6, color: g.equityTooClose ? cs.loss : null),
              if (g.goal.unitPaise != null && g.goal.unitPaise! > 0 && size >= 2)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text('= ${(g.taggedPaise / g.goal.unitPaise!).toStringAsFixed(1)} ${g.goal.unitName ?? 'units'}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ),
            ]),
          ),
      ]),
    );
  }

  Widget _top(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (p.holdings.isEmpty) return Text('No holdings.', style: TextStyle(color: cs.onSurfaceVariant));
    return Column(children: [
      for (final h in p.holdings.take(size == 1 ? 3 : (size == 2 ? 5 : 10)))
        InkWell(
          onTap: () => _open(context, h.instrumentId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Icon(h.isMf ? Icons.pie_chart_outline : Icons.show_chart, size: 18, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (size >= 2 && h.bucket == 'satellite') ...[
                Flexible(child: Pill('Satellite', color: cs.series[2])),
                const SizedBox(width: 8),
              ],
              Money(h.valuePaise, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
    ]);
  }

  Widget _market(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = istToday();
    final st = nse.status(DateTime.now());
    final up = nse.upcoming(today);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(st.label, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text('Last trading day: ${prettyDay(nse.lastTradingDay(DateTime.now()))}',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      if (up.isNotEmpty) ...[
        const SizedBox(height: 10),
        for (final (d, name) in up.take(size == 1 ? 2 : (size == 2 ? 3 : 8)))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(width: 64, child: Text('${d.day} ${months[d.month - 1]}', style: const TextStyle(fontFeatures: tabular))),
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant))),
            ]),
          ),
      ],
      if (!nse.knows(today)) const Fine('Holiday list for this year is not loaded yet; only weekends count as closed.'),
    ]);
  }

  void _open(BuildContext context, int id) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => HoldingScreen(session: session, instrumentId: id)));
}

/// Calm by default: the since-start figure; today's move only while pressed.
class _Summary extends StatefulWidget {
  final Portfolio p;
  final int size;
  const _Summary({required this.p, required this.size});
  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary> {
  bool _peek = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final gain = p.gainPaise;
    final pct = p.investedPaise == 0 ? 0.0 : gain / p.investedPaise;
    return GestureDetector(
      onTapDown: (_) => setState(() => _peek = true),
      onTapUp: (_) => setState(() => _peek = false),
      onTapCancel: () => setState(() => _peek = false),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FittedBox(child: Money(p.valuePaise, style: t.displaySmall?.copyWith(fontWeight: FontWeight.w700))),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _peek && p.anyPriced
              ? Row(key: const ValueKey('day'), children: [
                  Text('Today ', style: TextStyle(color: cs.onSurfaceVariant)),
                  Money(p.dayChangePaise, signed: true, colored: true, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(p.dayChangePaise >= 0 ? '  up' : '  down', style: TextStyle(color: cs.onSurfaceVariant)),
                ])
              : Wrap(key: const ValueKey('since'), children: [
                  Text(p.anyPriced ? 'Since start ' : 'Invested at cost · ', style: TextStyle(color: cs.onSurfaceVariant)),
                  if (p.anyPriced) ...[
                    Money(gain, signed: true, colored: true, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(' (${pct >= 0 ? 'up' : 'down'} ${(pct.abs() * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ] else
                    Text('${p.holdings.length} holdings', style: TextStyle(color: cs.onSurfaceVariant)),
                ]),
        ),
        if (p.xirr != null) ...[
          const SizedBox(height: 10),
          Text('XIRR ${(p.xirr! * 100).toStringAsFixed(1)}% a year', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(rateSentence(p.xirr!), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
        ],
        if (widget.size >= 2) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Pill('Invested ${rupees(p.investedPaise, decimals: false)}', color: cs.primary),
            Pill('MF ${p.valuePaise == 0 ? 0 : (p.mfPaise * 100 / p.valuePaise).round()}%', color: cs.series[0]),
            if (p.dividendsPaise > 0) Pill('Dividends ${rupees(p.dividendsPaise, decimals: false)}', color: cs.gain),
          ]),
        ],
        if (widget.size >= 3) ...[
          const SizedBox(height: 8),
          Text('Press and hold the card to see today\'s move.', style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
        ],
      ]),
    );
  }
}
