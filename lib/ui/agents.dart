import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/db.dart';
import '../engine/agent_stats.dart';
import '../engine/agents.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../db/open_db.dart';
import '../pipeline/agents_run.dart';
import '../pipeline/background.dart';
import 'holding.dart';
import 'theme.dart';
import 'widgets.dart';

String _pc(double x) => '${x >= 0 ? '+' : ''}${(x * 100).toStringAsFixed(2)}%';

/// Latest known price per instrument (agents store theirs in the shared price table).
Map<int, int> _prices(Portfolio p, Iterable<int> ids) => {
      for (final id in ids) id: ?p.book.latest(id)?.closeE4,
    };

/// The autonomous paper portfolios: three agents, Rs 25 lakh each, NIFTY 500 only.
class AgentsTab extends StatelessWidget {
  final Session session;
  const AgentsTab({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final m = session.market;
    return ValueListenableBuilder(
      valueListenable: session.portfolio,
      builder: (context, p, _) => p == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: (m.select(m.agentTrades)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch(),
              builder: (context, trades) => StreamBuilder(
                stream: (m.select(m.agentRuns)..orderBy([(r) => OrderingTerm.asc(r.id)])).watch(),
                builder: (context, runs) => _body(context, p, trades.data ?? const [], runs.data ?? const []),
              ),
            ),
    );
  }

  Widget _body(BuildContext context, Portfolio p, List<AgentTrade> trades, List<AgentRun> runs) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final books = {for (final k in AgentKind.values) k: bookFor(trades, k)};
    final prices = _prices(p, {for (final b in books.values) ...b.positions.keys});
    final total = books.values.fold(0, (a, b) => a + b.valueAt(prices));
    final start = agentStartCashPaise * AgentKind.values.length;
    return CustomScrollView(slivers: [
      const SliverAppBar(floating: true, title: Text('Agents')),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
        sliver: SliverList.list(children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.smart_toy_outlined, color: cs.primary),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Autonomous paper portfolios', style: TextStyle(fontWeight: FontWeight.w700))),
                  Pill('Paper money', color: cs.warn),
                ]),
                const SizedBox(height: 10),
                Money(total, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('${_pc(total / start - 1)} on ${rupees(start, decimals: false)} across 3 agents',
                    style: TextStyle(color: cs.signed(total - start), fontWeight: FontWeight.w600)),
                if (runs.isNotEmpty && runs.last.regime != null) ...[
                  const SizedBox(height: 8),
                  Text('Market mood: ${runs.last.regime}', style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
                ],
                const SizedBox(height: 10),
                _RunStatus(session: session, runs: runs),
              ]),
            ),
          ),
          const _Background(),
          if ({for (final r in runs) r.date}.length >= 2) _Race(p: p, runs: runs),
          for (final k in AgentKind.values) _AgentCard(session: session, kind: k, book: books[k]!, prices: prices, runs: runs),
          _Notes(session: session),
          const Fine('Simulation only: no real money, no real orders. Prices come from public sources a few minutes late; '
              'fills assume the latest price plus 0.1% costs. Limits per agent: Rs 50,000 per stock per day and Rs 4 lakh '
              'of new money per calendar month. Past simulated results do not predict real returns.'),
        ]),
      ),
    ]);
  }
}

const _power = MethodChannel('signal/power');

/// Background runs need the battery exemption; shows it (and the last wake) until granted.
class _Background extends StatefulWidget {
  const _Background();
  @override
  State<_Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<_Background> with WidgetsBindingObserver {
  bool? _ok;
  DateTime? _wake;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check(); // back from the system dialog
  }

  Future<void> _check() async {
    bool? ok;
    try {
      ok = await _power.invokeMethod<bool>('isIgnoring');
    } catch (_) {
      ok = null; // no platform (tests)
    }
    final w = DateTime.tryParse(await storage.read(key: lastWakeKey).catchError((_) => null) ?? '');
    if (mounted) {
      setState(() {
        _ok = ok;
        _wake = w;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ok != false) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        color: cs.errorContainer.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.battery_alert_outlined, color: cs.error),
              const SizedBox(width: 8),
              const Expanded(child: Text('Let the agents run when the app is closed', style: TextStyle(fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 6),
            Text(
                'Battery optimisation can stop background runs. Tap Allow and choose Allow. On Xiaomi, Redmi, Oppo, Vivo, Realme '
                'and OnePlus phones also open App settings and turn on Autostart, and set Battery to No restrictions.'
                '${_wake == null ? ' No background run has happened yet.' : ' Last background run: ${prettyDay(_wake!.toLocal())}, ${TimeOfDay.fromDateTime(_wake!.toLocal()).format(context)}.'}',
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              FilledButton(onPressed: () => _power.invokeMethod('request').catchError((_) => null), child: const Text('Allow')),
              OutlinedButton(onPressed: () => _power.invokeMethod('appSettings').catchError((_) => null), child: const Text('App settings')),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _RunStatus extends StatelessWidget {
  final Session session;
  final List<AgentRun> runs;
  const _RunStatus({required this.session, required this.runs});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: session.agentStatus,
        builder: (context, status, _) {
          final cs = Theme.of(context).colorScheme;
          final now = DateTime.now().toUtc();
          final today = fmtDay(istDay(now));
          final ranToday = runs.where((r) => r.date == today).map((r) => r.agent).toSet();
          final canTrade = agentsCanTrade(now);
          final last = runs.isEmpty ? null : runs.last.at;
          final text = status ??
              (ranToday.length == AgentKind.values.length
                  ? 'All three traded today at ${TimeOfDay.fromDateTime(runs.last.at.toLocal()).format(context)}. Next: the next market day, from 9:45 AM.'
                  : canTrade
                      ? 'Ready to trade today.'
                      : 'They trade once every market day after 9:45 AM: in the background, or as soon as you open the app.${last == null ? '' : ' Last run ${prettyDay(last.toLocal())}.'}');
          final row = Row(children: [
            if (status != null) ...[
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(text, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5))),
            if (status == null && canTrade && ranToday.length < AgentKind.values.length)
              FilledButton.tonal(onPressed: () => session.runAgents?.call(), child: const Text('Run now')),
          ]);
          return ValueListenableBuilder(
            valueListenable: session.agentError,
            builder: (context, err, _) => err == null || status != null || ranToday.length == AgentKind.values.length
                ? row
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    row,
                    const SizedBox(height: 8),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.error_outline, size: 18, color: cs.error),
                      const SizedBox(width: 6),
                      Expanded(child: Text(err, style: TextStyle(color: cs.error, fontSize: 12.5))),
                    ]),
                  ]),
          );
        },
      );
}

class _AgentCard extends StatelessWidget {
  final Session session;
  final AgentKind kind;
  final AgentBook book;
  final Map<int, int> prices;
  final List<AgentRun> runs;
  const _AgentCard({required this.session, required this.kind, required this.book, required this.prices, required this.runs});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cfg = agentConfigs[kind]!;
    final value = book.valueAt(prices);
    final mine = [for (final r in runs) if (r.agent == kind.name) r];
    final month = fmtDay(istDay(DateTime.now().toUtc())).substring(0, 7);
    final used = book.monthNet(month);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AgentScreen(session: session, kind: kind))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(cfg.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(width: 8),
                Text('${book.positions.length} holdings', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
                const Spacer(),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ]),
              const SizedBox(height: 6),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Money(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Text(_pc(value / agentStartCashPaise - 1),
                    style: TextStyle(color: cs.signed(value - agentStartCashPaise), fontWeight: FontWeight.w700)),
              ]),
              Text('Cash ${rupees(book.cashPaise, decimals: false)} · this month ${rupees(used, decimals: false)} of ₹4,00,000',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
              const SizedBox(height: 6),
              Meter(used / agentMonthlyLimitPaise, height: 5),
              if (mine.length >= 2) ...[const SizedBox(height: 10), _Spark(runs: mine)],
              const SizedBox(height: 8),
              Text(mine.isEmpty ? cfg.style : '${prettyDay(parseDay(mine.last.date))}: ${mine.last.summary}',
                  maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Spark extends StatelessWidget {
  final List<AgentRun> runs;
  const _Spark({required this.runs});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, agentStartCashPaise / 100),
              for (final (i, r) in runs.indexed) FlSpot(i + 1.0, r.valuePaise / 100),
            ],
            color: cs.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
      )),
    );
  }
}

/// Notes the user gives the agents; every run reads them.
class _Notes extends StatefulWidget {
  final Session session;
  const _Notes({required this.session});
  @override
  State<_Notes> createState() => _NotesState();
}

class _NotesState extends State<_Notes> {
  final _text = TextEditingController();
  String? _agent; // null = all

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final body = _text.text.trim();
    if (body.isEmpty) return;
    final m = widget.session.market;
    await m.into(m.agentNotes).insert(AgentNotesCompanion.insert(at: DateTime.now(), body: body, agent: Value(_agent)));
    _text.clear();
    if (mounted) snack(context, 'Noted. The agents read this on every run.');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final m = widget.session.market;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader('Tell the agents'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Anything you know or want: "avoid PSU banks", "EV makers look strong", "be more careful this week". '
                'They weigh it with the numbers and the news; they cannot break the money limits.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [
              for (final (v, l) in [(null, 'All'), ('daily', 'Daily'), ('weekly', 'Weekly'), ('monthly', 'Monthly')])
                ChoiceChip(label: Text(l), selected: _agent == v, onSelected: (_) => setState(() => _agent = v)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: const InputDecoration(hintText: 'Write a note for the agents'),
                ),
              ),
              IconButton.filled(tooltip: 'Save note', onPressed: _add, icon: const Icon(Icons.send)),
            ]),
            StreamBuilder(
              stream: (m.select(m.agentNotes)..orderBy([(x) => OrderingTerm.desc(x.at)])).watch(),
              builder: (context, snap) => Column(children: [
                for (final n in snap.data ?? const <AgentNote>[])
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(n.body),
                    subtitle: Text('${n.agent == null ? 'All agents' : agentConfigs[AgentKind.values.byName(n.agent!)]!.name} · ${prettyDay(n.at)}'),
                    trailing: IconButton(
                      tooltip: 'Delete note',
                      icon: const Icon(Icons.close),
                      onPressed: () => (m.delete(m.agentNotes)..where((x) => x.id.equals(n.id))).go(),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    ]);
  }
}

// ---------------- One agent ----------------

class AgentScreen extends StatelessWidget {
  final Session session;
  final AgentKind kind;
  const AgentScreen({super.key, required this.session, required this.kind});

  @override
  Widget build(BuildContext context) {
    final m = session.market;
    final cfg = agentConfigs[kind]!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${cfg.name} agent'),
          bottom: const TabBar(tabs: [Tab(text: 'Portfolio'), Tab(text: 'Activity'), Tab(text: 'Rules')]),
        ),
        body: ValueListenableBuilder(
          valueListenable: session.portfolio,
          builder: (context, p, _) => p == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder(
                  stream: (m.select(m.agentTrades)
                        ..where((t) => t.agent.equals(kind.name))
                        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
                      .watch(),
                  builder: (context, tSnap) => StreamBuilder(
                    stream: (m.select(m.agentRuns)
                          ..where((r) => r.agent.equals(kind.name))
                          ..orderBy([(r) => OrderingTerm.asc(r.id)]))
                        .watch(),
                    builder: (context, rSnap) {
                      final trades = tSnap.data ?? const <AgentTrade>[];
                      final runs = rSnap.data ?? const <AgentRun>[];
                      return TabBarView(children: [
                        _portfolio(context, p, trades, runs),
                        _activity(context, p, trades, runs),
                        _rules(context, cfg),
                      ]);
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _portfolio(BuildContext context, Portfolio p, List<AgentTrade> trades, List<AgentRun> runs) {
    final cs = Theme.of(context).colorScheme;
    final book = bookFor(trades, kind);
    final prices = _prices(p, book.positions.keys);
    final value = book.valueAt(prices);
    final invested = book.positions.values.fold(0, (a, x) => a + x.costPaise);
    final today = istDay(DateTime.now().toUtc());
    final rows = book.positions.values.toList()
      ..sort((a, b) => valuePaise(b.units4, prices[b.instrumentId] ?? 0).compareTo(valuePaise(a.units4, prices[a.instrumentId] ?? 0)));
    // Nifty 50 over the same period, for comparison.
    final idx = p.instruments.values.where((i) => i.yahooTicker == '^NSEI').firstOrNull;
    final first = runs.isEmpty ? null : parseDay(runs.first.date);
    final n0 = idx == null || first == null ? null : p.book.on(idx.id, first.subtract(const Duration(days: 1)));
    final n1 = idx == null ? null : p.book.latest(idx.id);
    Widget kv(String k, Widget v) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), child: v),
          ]),
        );
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Money(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text('${_pc(value / agentStartCashPaise - 1)} since start'
                '${n0 != null && n1 != null ? ' · NIFTY 50 ${_pc(n1.closeE4 / n0.closeE4 - 1)}' : ''}',
                style: TextStyle(color: cs.signed(value - agentStartCashPaise), fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(children: [
              kv('Cash', Money(book.cashPaise)),
              kv('Invested', Money(invested)),
              kv('Booked P&L', Money(book.realizedPaise, signed: true, colored: true)),
            ]),
            if (runs.length >= 2) ...[const SizedBox(height: 12), _Spark(runs: runs)],
          ]),
        ),
      ),
      _Scorecard(stats: statsFor(kind, runs, trades, {
        if (idx != null) for (final b in p.book.series(idx.id)) fmtDay(b.day): b.closeE4 / 10000,
      })),
      SectionHeader('Holdings', trailing: Text('${rows.length}')),
      if (rows.isEmpty) const EmptyState(icon: Icons.inventory_2_outlined, title: 'No holdings yet', message: 'The agent buys on its next run.'),
      for (final x in rows)
        Card(
          child: ListTile(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => HoldingScreen(session: session, instrumentId: x.instrumentId))),
            title: Text(p.instruments[x.instrumentId]?.name ?? '#${x.instrumentId}', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${formatScaled(x.units4, 4)} shares · avg ${rupees(mulDiv(x.costPaise, unitScale, x.units4))} · '
                'held ${today.difference(x.firstBuy).inDays} d'),
            trailing: Builder(builder: (context) {
              final v = valuePaise(x.units4, prices[x.instrumentId] ?? 0);
              return Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Money(v, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(_pc(v / x.costPaise - 1), style: TextStyle(color: cs.signed(v - x.costPaise), fontWeight: FontWeight.w600)),
              ]);
            }),
          ),
        ),
    ]);
  }

  Widget _activity(BuildContext context, Portfolio p, List<AgentTrade> trades, List<AgentRun> runs) {
    final cs = Theme.of(context).colorScheme;
    final days = {...runs.map((r) => r.date), ...trades.map((t) => t.date)}.toList()..sort((a, b) => b.compareTo(a));
    if (days.isEmpty) {
      return const EmptyState(icon: Icons.timeline, title: 'No activity yet', message: 'Every decision will appear here with its reason.');
    }
    return ListView(padding: const EdgeInsets.all(12), children: [
      for (final d in days) ...[
        SectionHeader(prettyDay(parseDay(d))),
        for (final r in runs.where((r) => r.date == d)) _RunCard(run: r),
        Card(
          child: Column(children: [
            for (final t in trades.where((t) => t.date == d))
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: (t.side == 'buy' ? cs.gain : cs.loss).withValues(alpha: 0.15),
                  child: Text(t.side == 'buy' ? 'B' : 'S',
                      style: TextStyle(fontWeight: FontWeight.w800, color: t.side == 'buy' ? cs.gain : cs.loss)),
                ),
                title: Text(
                    '${t.side == 'buy' ? 'Bought' : 'Sold'} ${formatScaled(t.unitsE4, 4)} × ${p.instruments[t.instrumentId]?.nseSymbol ?? ''} '
                    '@ ${priceLabel(t.priceE4)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${rupees(valuePaise(t.unitsE4, t.priceE4), decimals: false)} · ${t.reason}'),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => HoldingScreen(session: session, instrumentId: t.instrumentId))),
              ),
          ]),
        ),
      ],
    ]);
  }

  Widget _rules(BuildContext context, AgentConfig cfg) {
    final cs = Theme.of(context).colorScheme;
    final m = session.market;
    final lessons = StreamBuilder(
      stream: (m.select(m.agentMemories)
            ..where((x) => x.agent.equals(kind.name))
            ..orderBy([(x) => OrderingTerm.desc(x.at)])
            ..limit(9))
          .watch(),
      builder: (context, snap) {
        final l = snap.data ?? const <AgentMemory>[];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.psychology_outlined, color: cs.primary),
                const SizedBox(width: 8),
                const Text('What it has learned', style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              if (l.isEmpty)
                Text('Every Monday it reviews its closed trades and writes lessons it then reads before each decision.',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              for (final x in l)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• ${x.body}  (${prettyDay(x.at)})'),
                ),
            ]),
          ),
        );
      },
    );
    Widget line(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 130, child: Text(a, style: TextStyle(color: cs.onSurfaceVariant))),
            Expanded(child: Text(b, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );
    return ListView(padding: const EdgeInsets.all(12), children: [
      lessons,
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cfg.style, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 12),
            line('Starting money', '₹25,00,000 (paper)'),
            line('Universe', 'NIFTY 500 shares only'),
            line('Per stock per day', 'At most ₹50,000'),
            line('New money a month', 'At most ₹4,00,000 net (sales free up room)'),
            line('Holdings', 'At most ${cfg.maxHoldings}'),
            line('Stop-loss', '-${cfg.stopBps / 100}%'),
            if (cfg.targetBps != null) line('Take profit', '+${cfg.targetBps! / 100}%'),
            if (cfg.maxHoldDays != null) line('Longest hold', '${cfg.maxHoldDays} days'),
            line('Costs', '0.1% per trade'),
            line('When', 'Once every market day after 9:45 AM: background check every hour, or when you open the app'),
            line('Sizing', 'Jumpier stocks get smaller positions (volatility targeting)'),
            line('Market mood', 'Risk-off markets cut new buying to 35%; neutral to 70%'),
            line('Drawdown brake', 'Half-size buys after an 8% fall from its peak; none after 15%'),
          ]),
        ),
      ),
      const Fine('How a decision is made: rules rank NIFTY 500 on Advisor data, technicals (RSI, MACD, 50/200-day '
          'averages, relative strength) and AI-scored news, and draft a plan. The AI trader then calls tools to check '
          'technicals, fundamentals, news, the market mood and its own track record, argues a bull and a bear case, and '
          'decides within the shortlist. Code applies every limit above; stop-losses and profit targets always run. '
          'Paper money only.'),
    ]);
  }
}

/// Return, risk and what has worked, the same numbers the agent reads about itself.
class _Scorecard extends StatelessWidget {
  final AgentStats stats;
  const _Scorecard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = stats;
    Widget cell(String k, String v, [Color? c]) => SizedBox(
          width: 150,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            Text(v, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c, fontFeatures: tabular)),
          ]),
        );
    String p(double? x) => x == null ? '—' : '${x >= 0 ? '+' : ''}${(x * 100).toStringAsFixed(1)}%';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Scorecard', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 12, children: [
            cell('Return', p(s.totalReturn), cs.signed((s.totalReturn * 10000).round())),
            cell('vs NIFTY 50', p(s.alpha), s.alpha == null ? null : cs.signed((s.alpha! * 10000).round())),
            cell('Sharpe', s.sharpe == null ? 'needs 6 days' : s.sharpe!.toStringAsFixed(2)),
            cell('Worst fall', '-${(s.maxDrawdown * 100).toStringAsFixed(1)}%', cs.loss),
            cell('Win rate', s.winRate == null ? 'no closed trades' : '${(s.winRate! * 100).round()}% of ${s.closed.length}'),
            cell('Avg hold', s.avgHoldDays == null ? '—' : '${s.avgHoldDays!.toStringAsFixed(0)} days'),
          ]),
          if (s.bySignal.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
                'Wins by signal: ${s.bySignal.entries.map((e) => '${e.key} ${e.value.$1}/${e.value.$2}').join(' · ')}',
                style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
          ],
        ]),
      ),
    );
  }
}

/// One day's decision: summary, market mood, and the AI's bull and bear case.
class _RunCard extends StatelessWidget {
  final AgentRun run;
  const _RunCard({required this.run});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = run;
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(r.ai ? Icons.auto_awesome : Icons.rule, color: cs.primary),
          title: Text(r.summary, style: const TextStyle(fontSize: 14.5)),
          subtitle: Text(
              '${rupees(r.valuePaise, decimals: false)} after${r.toolCalls > 0 ? ' · ${r.toolCalls} data look-ups' : ''}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.regime != null) Text('Market: ${r.regime}', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            if (r.bull != null && r.bull!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Bull case', style: TextStyle(fontWeight: FontWeight.w700, color: cs.gain)),
              Text(r.bull!),
            ],
            if (r.bear != null && r.bear!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Bear case', style: TextStyle(fontWeight: FontWeight.w700, color: cs.loss)),
              Text(r.bear!),
            ],
            if (!r.ai) Text('Rules only (no AI key or the AI was unavailable).', style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// The three agents and NIFTY 50 on one chart: return since the first run.
class _Race extends StatelessWidget {
  final Portfolio p;
  final List<AgentRun> runs;
  const _Race({required this.p, required this.runs});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dates = {for (final r in runs) r.date}.toList()..sort();
    final idx = p.instruments.values.where((i) => i.yahooTicker == '^NSEI').firstOrNull;
    final base = idx == null ? null : p.book.on(idx.id, parseDay(dates.first).subtract(const Duration(days: 1)))?.closeE4;
    List<FlSpot> agentLine(AgentKind k) {
      var last = agentStartCashPaise;
      return [
        const FlSpot(0, 0),
        for (final (i, d) in dates.indexed)
          FlSpot(i + 1.0, ((last = runs.lastWhere((r) => r.agent == k.name && r.date == d, orElse: () => _carry(k, d, last)).valuePaise) / agentStartCashPaise - 1) * 100),
      ];
    }

    final nifty = base == null
        ? const <FlSpot>[]
        : [
            const FlSpot(0, 0),
            for (final (i, d) in dates.indexed)
              if (p.book.on(idx!.id, parseDay(d)) case final b?) FlSpot(i + 1.0, (b.closeE4 / base - 1) * 100),
          ];
    final colors = [cs.series[0], cs.series[1], cs.series[2]];
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('The race: return since the start', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: LineChart(LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  for (final (i, k) in AgentKind.values.indexed)
                    LineChartBarData(spots: agentLine(k), color: colors[i], barWidth: 2.4, dotData: const FlDotData(show: false)),
                  if (nifty.length >= 2)
                    LineChartBarData(spots: nifty, color: cs.onSurfaceVariant, barWidth: 1.6, dashArray: [5, 4], dotData: const FlDotData(show: false)),
                ],
              )),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 14, runSpacing: 4, children: [
              for (final (i, k) in AgentKind.values.indexed) _key(colors[i], agentConfigs[k]!.name),
              if (nifty.length >= 2) _key(cs.onSurfaceVariant, 'NIFTY 50'),
            ]),
          ]),
        ),
      ),
    );
  }

  AgentRun _carry(AgentKind k, String d, int value) =>
      AgentRun(id: 0, agent: k.name, date: d, at: DateTime(2000), summary: '', valuePaise: value, cashPaise: 0, ai: false, toolCalls: 0);

  Widget _key(Color c, String s) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 3, color: c),
        const SizedBox(width: 6),
        Text(s, style: const TextStyle(fontSize: 12)),
      ]);
}
