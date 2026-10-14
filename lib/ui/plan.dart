import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/portfolio.dart';
import 'add_transaction.dart';
import 'theme.dart';
import 'widgets.dart';

class PlanTab extends StatelessWidget {
  final Session session;
  const PlanTab({super.key, required this.session});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: session.portfolio,
        builder: (context, p, _) {
          if (p == null) return const Center(child: CircularProgressIndicator());
          return CustomScrollView(slivers: [
            const SliverAppBar(floating: true, title: Text('Plan')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 40),
              sliver: SliverList.list(children: [
                SectionHeader('Goals',
                    trailing: TextButton.icon(
                        onPressed: () => editGoal(context, session), icon: const Icon(Icons.add), label: const Text('Goal'))),
                if (p.goals.isEmpty)
                  const _Hint('Money for goals under 3 years away should not sit in equity. Create a goal, then tag buys and SIPs to it.')
                else
                  for (final g in p.goals) _GoalCard(session: session, g: g),
                SectionHeader('SIP plans',
                    trailing: TextButton.icon(
                        onPressed: () => editSip(context, session), icon: const Icon(Icons.add), label: const Text('SIP'))),
                if (p.sips.isEmpty)
                  const _Hint('Add each SIP once. The app checks every month and flags instalments you have not recorded.')
                else
                  for (final s in p.sips) _SipCard(session: session, s: s, p: p),
                const Fine('A due date on a weekend or NSE holiday counts as due on the next business day. '
                    'Instalments get a 7-day grace before they are flagged.'),
              ]),
            ),
          ]);
        },
      );
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
}

class _GoalCard extends StatelessWidget {
  final Session session;
  final GoalStatus g;
  const _GoalCard({required this.session, required this.g});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          onTap: () => editGoal(context, session, g.goal),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(g.goal.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                Text('${(g.progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: tabular)),
              ]),
              const SizedBox(height: 4),
              Text('${prettyDay(parseDay(g.goal.targetDate))} · ${g.daysLeft < 0 ? 'past due' : inDays(g.daysLeft)}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 10),
              Meter(g.progress, color: g.equityTooClose ? cs.loss : null),
              const SizedBox(height: 6),
              Text('${rupees(g.taggedPaise, decimals: false)} of ${rupees(g.goal.targetPaise, decimals: false)} (at cost)',
                  style: const TextStyle(fontFeatures: tabular)),
              if (g.equityTooClose) ...[
                const SizedBox(height: 10),
                Notice(
                  icon: Icons.warning_amber,
                  color: cs.loss,
                  text: 'Under 3 years away and invested in equity. Consider moving it to debt or liquid funds as the date nears.',
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _SipCard extends StatelessWidget {
  final Session session;
  final SipStatus s;
  final Portfolio p;
  const _SipCard({required this.session, required this.s, required this.p});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plan = s.plan;
    final name = p.instruments[plan.instrumentId]?.name ?? 'Unknown fund';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          onTap: () => editSip(context, session, plan),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.autorenew, color: plan.active ? cs.primary : cs.outline),
                const SizedBox(width: 10),
                Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                Money(plan.amountPaise, style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                Pill('Day ${plan.dayOfMonth}', color: cs.primary, icon: Icons.event),
                Pill('${s.recorded} recorded', color: cs.gain, icon: Icons.check),
                if (!plan.active) Pill('Paused', color: cs.outline, icon: Icons.pause),
                if (s.missed.isNotEmpty) Pill('${s.missed.length} missed', color: cs.warn, icon: Icons.event_busy),
              ]),
              if (s.nextDue != null) ...[
                const SizedBox(height: 8),
                Text('Next: ${prettyDay(s.nextDue!)}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
              if (s.missed.isNotEmpty) ...[
                const SizedBox(height: 10),
                for (final d in s.missed.take(6))
                  Row(children: [
                    Expanded(child: Text('Due ${prettyDay(d)}')),
                    TextButton(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AddTransaction(session: session, sipPlan: plan, date: d))),
                      child: const Text('Record'),
                    ),
                  ]),
                if (s.missed.length > 6) Text('+ ${s.missed.length - 6} more', style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

Future<void> editGoal(BuildContext context, Session s, [Goal? g]) async {
  final name = TextEditingController(text: g?.name ?? '');
  final amount = TextEditingController(text: g == null ? '' : formatScaled(g.targetPaise, 2));
  var date = g == null ? DateTime.utc(istToday().year + 3, istToday().month, 1) : parseDay(g.targetDate);
  final form = GlobalKey<FormState>();
  final res = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(g == null ? 'New goal' : 'Edit goal', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: name,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Name', hintText: "e.g. Master's abroad"),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Target amount', prefixText: '₹ '),
              validator: (v) => (parseScaled(v ?? '', 2) ?? 0) > 0 ? null : 'Enter an amount',
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text('Target date: ${prettyDay(date)}'),
              onTap: () async {
                final d = await showDatePicker(
                    context: ctx, initialDate: date, firstDate: DateTime.utc(2000), lastDate: DateTime.utc(2100));
                if (d != null) set(() => date = DateTime.utc(d.year, d.month, d.day));
              },
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(ctx, 'save');
              },
              child: const Text('Save'),
            ),
            if (g != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: Text('Delete goal', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ),
          ]),
        ),
      ),
    ),
  );
  if (res == 'save') {
    await s.db.saveGoal(GoalsCompanion(
      id: g == null ? const Value.absent() : Value(g.id),
      name: Value(name.text.trim()),
      targetDate: Value(fmtDay(date)),
      targetPaise: Value(parseScaled(amount.text, 2)!),
    ));
  } else if (res == 'delete' && context.mounted &&
      await confirm(context, 'Delete goal?', 'Transactions tagged to "${g!.name}" stay, just untagged.')) {
    await s.db.deleteGoal(g.id);
  }
}

Future<void> editSip(BuildContext context, Session s, [SipPlan? plan]) async {
  final p = s.portfolio.value!;
  final mfs = p.instruments.values.where((i) => i.kind == 'mf').toList()..sort((a, b) => a.name.compareTo(b.name));
  if (mfs.isEmpty) {
    snack(context, 'Add a mutual fund first (Add → New fund / stock).');
    return;
  }
  int? inst = plan?.instrumentId ?? mfs.first.id;
  final amount = TextEditingController(text: plan == null ? '' : formatScaled(plan.amountPaise, 2));
  var day = plan?.dayOfMonth ?? 5;
  var start = plan == null ? istToday() : parseDay(plan.start);
  var active = plan?.active ?? true;
  final form = GlobalKey<FormState>();
  final res = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, set) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(plan == null ? 'New SIP plan' : 'Edit SIP plan', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: inst,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Fund'),
              items: [for (final i in mfs) DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => inst = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monthly amount', prefixText: '₹ '),
              validator: (v) => (parseScaled(v ?? '', 2) ?? 0) > 0 ? null : 'Enter an amount',
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Day of month'),
              Expanded(
                child: Slider(
                  value: day.toDouble(),
                  min: 1,
                  max: 28,
                  divisions: 27,
                  label: '$day',
                  onChanged: (v) => set(() => day = v.round()),
                ),
              ),
              SizedBox(width: 28, child: Text('$day', style: const TextStyle(fontWeight: FontWeight.w700))),
            ]),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text('Started ${prettyDay(start)}'),
              onTap: () async {
                final d = await showDatePicker(
                    context: ctx, initialDate: start, firstDate: DateTime.utc(2000), lastDate: istToday());
                if (d != null) set(() => start = DateTime.utc(d.year, d.month, d.day));
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              subtitle: const Text('Pause to stop missed-instalment alerts'),
              value: active,
              onChanged: (v) => set(() => active = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(ctx, 'save');
              },
              child: const Text('Save'),
            ),
            if (plan != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: Text('Delete plan', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ),
          ]),
        ),
      ),
    ),
  );
  if (res == 'save' && inst != null) {
    await s.db.saveSip(SipPlansCompanion(
      id: plan == null ? const Value.absent() : Value(plan.id),
      instrumentId: Value(inst!),
      amountPaise: Value(parseScaled(amount.text, 2)!),
      dayOfMonth: Value(day),
      start: Value(fmtDay(start)),
      active: Value(active),
    ));
  } else if (res == 'delete' && context.mounted &&
      await confirm(context, 'Delete SIP plan?', 'Recorded SIP transactions are kept.')) {
    await s.db.deleteSip(plan!.id);
  }
}
