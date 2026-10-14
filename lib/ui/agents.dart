import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/agents.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import '../pipeline/agents_run.dart';
import 'holding.dart';
import 'theme.dart';
import 'widgets.dart';

String _pc(double x) => '${x >= 0 ? '+' : ''}${(x * 100).toStringAsFixed(2)}%';

/// Latest known price per instrument (agents store theirs in the shared price table).
Map<int, int> _prices(Portfolio p, Iterable<int> ids) => {for (final id in ids) id: p.book.latest(id)?.closeE4 ?? 0};

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
                const SizedBox(height: 10),
                _RunStatus(session: session, runs: runs),
              ]),
            ),
          ),
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
                  ? 'All three traded today at ${TimeOfDay.fromDateTime(runs.last.at.toLocal()).format(context)}. Next: the next trading day, 11:00 AM.'
                  : canTrade
                      ? 'Ready to trade today.'
                      : 'They trade every market day at about 11:00 AM, even with the app closed.${last == null ? '' : ' Last run ${prettyDay(last.toLocal())}.'}');
          return Row(children: [
            if (status != null) ...[
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(text, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5))),
            if (status == null && canTrade && ranToday.length < AgentKind.values.length)
              FilledButton.tonal(onPressed: () => session.runAgents?.call(), child: const Text('Run now')),
          ]);
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
        for (final r in runs.where((r) => r.date == d))
          Notice(
            icon: r.ai ? Icons.auto_awesome : Icons.rule,
            color: cs.primary,
            text: '${r.summary}  (${rupees(r.valuePaise, decimals: false)} after)',
          ),
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
    Widget line(String a, String b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 130, child: Text(a, style: TextStyle(color: cs.onSurfaceVariant))),
            Expanded(child: Text(b, style: const TextStyle(fontWeight: FontWeight.w600))),
          ]),
        );
    return ListView(padding: const EdgeInsets.all(12), children: [
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
            line('When', 'Every market day about 11:00 AM; 4:00 PM if it missed'),
          ]),
        ),
      ),
      const Fine('How a decision is made: fixed rules rank NIFTY 500 using the Advisor data (quality, growth, value, '
          'momentum), recent price moves and AI-scored news, and draft a plan. The AI agent then picks from that shortlist, '
          'reading your notes. Code applies the limits above to whatever it picks; stop-losses and profit targets always '
          'run. Paper money only.'),
    ]);
  }
}
