import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/open_db.dart';
import '../engine/calendar.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../engine/tax.dart';
import 'holding.dart';
import 'settings.dart';
import 'theme.dart';
import 'widgets.dart';

/// Tile id -> title. Order here is the default order.
const tileTitles = {
  'summary': 'Portfolio',
  'alloc': 'Allocation',
  'growth': 'Net invested',
  'tax': 'Tax this FY',
  'longterm': 'Turning long-term',
  'sips': 'SIPs',
  'goals': 'Goals',
  'top': 'Top holdings',
  'market': 'Market calendar',
};
const _defaultSize = {'summary': 3, 'alloc': 1, 'growth': 1, 'tax': 2, 'goals': 2, 'top': 2, 'market': 2};

class Layout {
  List<String> order;
  Set<String> hidden;
  Map<String, int> sizes; // 1 small, 2 wide, 3 large
  Layout(this.order, this.hidden, this.sizes);

  factory Layout.parse(String? s) {
    final j = s == null ? const {} : jsonDecode(s) as Map;
    final order = [...((j['order'] as List?)?.cast<String>() ?? const <String>[])]
      ..removeWhere((k) => !tileTitles.containsKey(k));
    for (final k in tileTitles.keys) {
      if (!order.contains(k)) order.add(k);
    }
    return Layout(
      order,
      {...((j['hidden'] as List?)?.cast<String>() ?? const <String>[])},
      {...((j['sizes'] as Map?)?.cast<String, int>() ?? const <String, int>{})},
    );
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
  String get _key => 'layout2_${widget.session.profile.id}';

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

  void _customize() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    Expanded(child: Text('Customize home', style: Theme.of(ctx).textTheme.titleLarge)),
                    TextButton(
                      onPressed: () {
                        _layout = Layout.parse(null);
                        _save();
                        setSheet(() {});
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Drag to reorder. Pick a size or hide a card. Tip: long-press a card on Home to resize it.',
                ),
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
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    return ValueListenableBuilder(
      valueListenable: s.portfolio,
      builder: (context, p, _) {
        if (p == null) return const Center(child: CircularProgressIndicator());
        final cs = Theme.of(context).colorScheme;
        final status = nse.status(DateTime.now());
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              titleSpacing: 16,
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: avatarColor(s.profile.id),
                    child: Text(
                      s.profile.badge,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.profile.name, overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: status.phase == MarketPhase.open
                                  ? cs.gain
                                  : (status.phase == MarketPhase.preOpen ? cs.warn : cs.outline),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                status.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Customize home',
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  onPressed: _customize,
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(session: s))),
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
              sliver: SliverToBoxAdapter(child: _body(context, p)),
            ),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, Portfolio p) {
    final cs = Theme.of(context).colorScheme;
    final alerts = <Widget>[
      if (p.missedSipCount > 0)
        Notice(
          icon: Icons.event_busy,
          color: cs.warn,
          text: '${p.missedSipCount} SIP instalment${p.missedSipCount == 1 ? '' : 's'} not recorded',
          onTap: () => widget.onOpenTab(3),
        ),
      for (final g in p.goals.where((g) => g.equityTooClose))
        Notice(
          icon: Icons.flag,
          color: cs.loss,
          text:
              '"${g.goal.name}" is due ${inDays(g.daysLeft)} but ${rupees(g.taggedPaise, decimals: false)} sits in equity',
          onTap: () => widget.onOpenTab(3),
        ),
      for (final h in p.holdings.where((h) => h.ledger.oversold.isNotEmpty))
        Notice(icon: Icons.error_outline, color: cs.loss, text: '${h.name}: a sell exceeds units held'),
    ];
    final children = <Widget>[for (final a in alerts) Padding(padding: const EdgeInsets.only(bottom: 8), child: a)];
    if (p.txs.isEmpty) {
      return Column(
        children: [
          ...children,
          const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Start your ledger',
            message:
                'Tap Add to record your first buy or SIP. Lots, long-term dates and tax estimates '
                'build themselves from your entries.',
          ),
          _tiles(context, p, only: const {'market'}),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        _tiles(context, p),
        const Fine(
          'Values are at cost until live prices arrive. Estimates for listed equity and equity MFs only. '
          'Not investment or tax advice.',
        ),
      ],
    );
  }

  Widget _tiles(BuildContext context, Portfolio p, {Set<String>? only}) => LayoutBuilder(
    builder: (context, c) {
      const gap = 10.0;
      final cols = c.maxWidth < 600 ? 2 : (c.maxWidth < 900 ? 3 : 4);
      final unit = (c.maxWidth - gap * (cols - 1)) / cols;
      double width(int size) => switch (size) {
        1 => unit,
        2 when cols > 2 => unit * 2 + gap,
        _ => c.maxWidth,
      };
      final keys = _layout.order.where((k) => !_layout.hidden.contains(k) && (only == null || only.contains(k)));
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final k in keys)
            AnimatedContainer(
              key: ValueKey('tile-$k'),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: width(_layout.size(k)),
              child: GestureDetector(
                onLongPress: () => _cycle(k),
                child: _Tile(id: k, size: _layout.size(k), p: p, session: widget.session, onOpenTab: widget.onOpenTab),
              ),
            ),
        ],
      );
    },
  );
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
      'summary' => _summary(context),
      'alloc' => _alloc(context),
      'growth' => _growth(context),
      'tax' => _tax(context),
      'longterm' => _longTerm(context),
      'sips' => _sipsTile(context),
      'goals' => _goalsTile(context),
      'top' => _top(context),
      _ => _market(context),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tileTitles[id]!.toUpperCase(),
              style: t.labelSmall?.copyWith(
                letterSpacing: 0.8,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedSize(duration: const Duration(milliseconds: 200), alignment: Alignment.topLeft, child: body),
          ],
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final mfShare = p.investedPaise == 0 ? 0.0 : p.mfPaise / p.investedPaise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          child: Money(p.investedPaise, style: t.displaySmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Text(
          'invested across ${p.holdings.length} holding${p.holdings.length == 1 ? '' : 's'}',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
        if (size >= 2) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill('MF ${(mfShare * 100).round()}%', color: cs.series[0], icon: Icons.pie_chart_outline),
              Pill('Stocks ${((1 - mfShare) * 100).round()}%', color: cs.series[1], icon: Icons.show_chart),
              if (p.dividendsPaise > 0) Pill('Dividends ${rupees(p.dividendsPaise, decimals: false)}', color: cs.gain),
            ],
          ),
        ],
        if (size >= 3 && p.realized.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            children: [
              Text('Realised all time  ', style: TextStyle(color: cs.onSurfaceVariant)),
              Money(
                p.realized.fold(0, (a, r) => a + r.gainPaise),
                signed: true,
                colored: true,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _alloc(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sat = p.satellitePaise, core = p.investedPaise - sat;
    final slices = size >= 2
        ? [
            for (final (i, h) in p.holdings.take(5).indexed) (h.name, h.ledger.costPaise, cs.series[i]),
            if (p.holdings.length > 5)
              ('Others', p.holdings.skip(5).fold(0, (a, h) => a + h.ledger.costPaise), cs.series[5]),
          ]
        : [('Core', core, cs.series[0]), ('Satellite', sat, cs.series[2])];
    final total = slices.fold(0, (a, s) => a + s.$2);
    final chart = SizedBox(
      height: 120,
      width: 120,
      child: RepaintBoundary(
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 36,
            startDegreeOffset: -90,
            sections: [
              for (final s in slices)
                if (s.$2 > 0) PieChartSectionData(value: s.$2.toDouble(), color: s.$3, radius: 18, showTitle: false),
            ],
          ),
        ),
      ),
    );
    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: s.$3, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(s.$1, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(
                  total == 0 ? '0%' : '${(s.$2 * 100 / total).round()}%',
                  style: const TextStyle(fontFeatures: tabular),
                ),
              ],
            ),
          ),
      ],
    );
    // Decide by real width, not tile size: mid-resize the tile is still narrow.
    return LayoutBuilder(
      builder: (context, c) => c.maxWidth < 300
          ? Column(
              children: [
                Center(child: chart),
                const SizedBox(height: 8),
                legend,
              ],
            )
          : Row(
              children: [
                chart,
                const SizedBox(width: 16),
                Expanded(child: legend),
              ],
            ),
    );
  }

  Widget _growth(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pts = p.netInvested;
    if (pts.length < 2) {
      return Text('A chart appears after your second month of entries.', style: TextStyle(color: cs.onSurfaceVariant));
    }
    final spots = [for (final (i, e) in pts.indexed) FlSpot(i.toDouble(), e.$2 / 100)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Money(pts.last.$2, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text('since ${monthYear(pts.first.$1)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 10),
        SizedBox(
          height: size >= 3 ? 180 : 100,
          child: RepaintBoundary(
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => cs.inverseSurface,
                    getTooltipItems: (touched) => [
                      for (final s in touched)
                        LineTooltipItem(
                          '${monthYear(pts[s.x.toInt()].$1)}\n${rupees(pts[s.x.toInt()].$2, decimals: false)}',
                          TextStyle(color: cs.onInverseSurface, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: cs.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [cs.primary.withValues(alpha: 0.28), cs.primary.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tax(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final used = p.fyTax.exemptionUsedPaise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FY ${p.fy}-${(p.fy + 1) % 100}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          children: [
            const Text('LTCG exemption left  '),
            Money(p.fyTax.exemptionLeftPaise, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Meter(used / ltcgExemptionPaise, color: used >= ltcgExemptionPaise ? cs.warn : cs.primary),
        const SizedBox(height: 4),
        Text(
          '${rupees(used, decimals: false)} of ${rupees(ltcgExemptionPaise, decimals: false)} used',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        if (size >= 2) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _kv(context, 'STCG', Money(p.fyGains.st, colored: true))),
              Expanded(child: _kv(context, 'LTCG', Money(p.fyGains.lt, colored: true))),
              Expanded(child: _kv(context, 'Est. tax', Money(p.fyTax.taxPaise))),
            ],
          ),
        ],
        if (size >= 3)
          const Fine(
            'STCG 20%, LTCG 12.5% above ₹1.25L, plus 4% cess. Excludes surcharge, '
            'other income and carried-forward losses.',
          ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, Widget v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(k, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      DefaultTextStyle.merge(
        style: const TextStyle(fontWeight: FontWeight.w600),
        child: v,
      ),
    ],
  );

  Widget _longTerm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final up = p.upcomingLongTerm;
    if (up.isEmpty) {
      return Text('No lots turn long-term in the next 90 days.', style: TextStyle(color: cs.onSurfaceVariant));
    }
    return Column(
      children: [
        for (final (h, l) in up.take(size == 1 ? 2 : (size == 2 ? 4 : 8)))
          InkWell(
            onTap: () => _open(context, h.instrumentId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(Icons.hourglass_bottom, size: 18, color: cs.warn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          '${prettyDay(l.longTermDate)} · ${inDays(l.longTermDate.difference(p.today).inDays)}',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (size >= 2) Money(l.costPaise, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
        if (size >= 2) const Fine('Selling before these dates is taxed as STCG (20%).'),
      ],
    );
  }

  Widget _sipsTile(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = p.sips.where((s) => s.plan.active).toList();
    if (p.sips.isEmpty) {
      return InkWell(
        onTap: () => onOpenTab(3),
        child: Text(
          'Add your SIP plans in Plan to track missed instalments.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }
    final monthly = active.fold(0, (a, s) => a + s.plan.amountPaise);
    final next = [...active.where((s) => s.nextDue != null)]..sort((a, b) => a.nextDue!.compareTo(b.nextDue!));
    return InkWell(
      onTap: () => onOpenTab(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Money(monthly, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text('per month · ${active.length} active', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          if (p.missedSipCount > 0) ...[
            const SizedBox(height: 8),
            Pill('${p.missedSipCount} missed', color: cs.warn, icon: Icons.event_busy),
          ],
          if (next.isNotEmpty && size >= 2) ...[
            const SizedBox(height: 8),
            for (final s in next.take(3))
              Text(
                '${p.instruments[s.plan.instrumentId]?.name ?? 'SIP'} · ${prettyDay(s.nextDue!)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
          ],
        ],
      ),
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
      child: Column(
        children: [
          for (final g in p.goals.take(size == 1 ? 2 : 4))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(g.goal.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (g.equityTooClose) Icon(Icons.warning_amber, size: 16, color: cs.loss),
                      Text(' ${(g.progress * 100).round()}%', style: const TextStyle(fontFeatures: tabular)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Meter(g.progress, height: 6, color: g.equityTooClose ? cs.loss : null),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _top(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (p.holdings.isEmpty) return Text('No holdings.', style: TextStyle(color: cs.onSurfaceVariant));
    return Column(
      children: [
        for (final h in p.holdings.take(size == 1 ? 3 : (size == 2 ? 5 : 10)))
          InkWell(
            onTap: () => _open(context, h.instrumentId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(h.isMf ? Icons.pie_chart_outline : Icons.show_chart, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(h.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (size >= 2 && h.bucket == 'satellite') ...[
                    Flexible(child: Pill('Satellite', color: cs.series[2])),
                    const SizedBox(width: 8),
                  ],
                  Money(h.ledger.costPaise, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _market(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = istToday();
    final st = nse.status(DateTime.now());
    final up = nse.upcoming(today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(st.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(
          'Last trading day: ${prettyDay(nse.lastTradingDay(DateTime.now()))}',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        if (up.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final (d, name) in up.take(size == 1 ? 2 : (size == 2 ? 3 : 8)))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text('${d.day} ${months[d.month - 1]}', style: const TextStyle(fontFeatures: tabular)),
                  ),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (!nse.knows(today)) const Fine('Holiday list for this year is not loaded; only weekends count as closed.'),
      ],
    );
  }

  void _open(BuildContext context, int id) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HoldingScreen(session: session, instrumentId: id),
    ),
  );
}
