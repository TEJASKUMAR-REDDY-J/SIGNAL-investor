import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../db/db.dart';
import '../db/open_db.dart';
import '../engine/calendar.dart';
import '../engine/lots.dart';
import '../engine/money.dart';
import '../engine/tax.dart';
import '../engine/valuation.dart' show benchmarkScheme;
import '../pipeline/instruments.dart';
import '../sources/net.dart';
import 'ask.dart';
import 'widgets.dart';

const tourDoneKey = 'tour_done';

// ---------------- Help ----------------

const _faq = [
  (
    'How do I add a stock or fund I bought?',
    'Search for it on Home, open it and tap "I bought this". For a stock, enter how many shares; the price for that day '
        'fills in (change it to the price on your contract note). For a fund, enter the amount; the NAV fills in and units '
        'and stamp duty are worked out.'
  ),
  (
    'How do I track a SIP?',
    'Go to Plan and add a SIP plan (fund, amount, day of month). Each month, record the instalment from Plan or with Add '
        '> SIP. Missed instalments show up in "Do next".'
  ),
  (
    'Are prices live?',
    'Stock and index prices update every minute while the market is open and you are in the app. They come from free '
        'public sources and run a few minutes behind the exchange. Fund NAVs update once a day, in the evening.'
  ),
  (
    'What is the Advisor?',
    'Fixed rules, not opinions: every NIFTY 500 company is checked for profit, debt, cash flow and size, then ranked on '
        'quality, growth, value and momentum. Funds are ranked within their category on 3- and 5-year growth and how far '
        'they fell in bad times. Tap Why? for the AI to explain. A ranking is a starting point for research, not a tip.'
  ),
  (
    'What is the News pulse?',
    'At 8 AM and 4 PM the app reads business news and NSE filings for companies you own, watch, or that the Advisor '
        'likes. The AI labels each headline good (+1) or bad (-1) for the company; the pulse adds them up over 7 days. '
        'You get one short notification with the summary.'
  ),
  (
    'What do the colours mean?',
    'Blue is up or good, orange is down or a warning. Red and green are avoided on purpose: they push people to trade on '
        'every move.'
  ),
  (
    'Why does it slow me down before selling?',
    'Selling within 12 months is taxed at 20%; after 12 months at 12.5%, and the first Rs 1.25 lakh of long-term gains '
        'each year is tax-free. "Thinking of selling?" shows exactly what waiting would save.'
  ),
  (
    'Core and satellite?',
    'Core is the steady part (index funds). Satellite is your own picks. Many plans keep satellite at 20 to 30%.'
  ),
  (
    'Where is my data?',
    'Only on this phone, encrypted, opened with your fingerprint or screen lock. No account, no cloud. Uninstalling the '
        'app deletes it. The AI assistant receives your portfolio only when you ask it something with "Use my portfolio" on.'
  ),
];

void showHelp(BuildContext context, Session s) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
          Text('How to use SIGNAL', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                openTour(context, s);
              },
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Replay the tour'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => AskScreen(session: s)));
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Ask SIGNAL'),
            ),
          ]),
          const SizedBox(height: 8),
          for (final (q, a) in _faq)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
              childrenPadding: const EdgeInsets.only(bottom: 12),
              children: [Text(a, style: const TextStyle(height: 1.45))],
            ),
        ]),
      ),
    );

// ---------------- Tour ----------------

/// Shows the tour; builds the demo portfolio if the user picks it.
Future<void> openTour(BuildContext context, Session s) async {
  final demo = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => TourScreen(session: s)));
  if (demo == true && context.mounted) await startDemo(context, s);
}

class TourScreen extends StatefulWidget {
  final Session session;
  const TourScreen({super.key, required this.session});
  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final _pages = PageController();
  int _i = 0;

  static const _cards = [
    (
      Icons.account_balance_wallet_outlined,
      'Track what you own',
      'Search any NSE stock or mutual fund. Tap "I bought this" and the price fills itself in. Gains, tax and growth '
          'update on their own, with live prices while the market is open.'
    ),
    (
      Icons.emoji_events_outlined,
      'Ideas from fixed rules',
      'The Advisor ranks every NIFTY 500 company and the main fund categories on quality, growth, value and momentum. '
          'Tap "Why?" and the AI explains the numbers in plain words.'
    ),
    (
      Icons.newspaper_outlined,
      'News, twice a day',
      'At 8 AM and 4 PM SIGNAL reads the news and company filings for what you hold and follow, scores each headline '
          '+1 or -1, and sends one short summary. No price alerts, no noise.'
    ),
    (
      Icons.eco_outlined,
      'Patience pays',
      'Holding over 12 months cuts the tax on gains from 20% to 12.5%, and the first Rs 1.25 lakh a year is tax-free. '
          'SIGNAL shows the cost before you sell. It never places orders; you stay in charge.'
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  /// Pops with true when the demo was chosen; [openTour] runs it.
  Future<void> _finish({bool demo = false}) async {
    await storage.write(key: tourDoneKey, value: '1');
    if (mounted) Navigator.pop(context, demo);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final last = _i == _cards.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _finish, child: const Text('Skip'))),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _i = i),
              children: [
                for (final (icon, title, body) in _cards)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(icon, size: 56, color: cs.primary),
                      ),
                      const SizedBox(height: 32),
                      Text(title, textAlign: TextAlign.center, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Text(body, textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(height: 1.5, color: cs.onSurfaceVariant)),
                    ]),
                  ),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var k = 0; k < _cards.length; k++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: k == _i ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(color: k == _i ? cs.primary : cs.outlineVariant, borderRadius: BorderRadius.circular(4)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: last
                ? Column(children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _finish(demo: true),
                        icon: const Icon(Icons.toys_outlined),
                        label: const Text('Explore with a demo portfolio'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(onPressed: _finish, child: const Text('Start with my own')),
                    ),
                  ])
                : SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _pages.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOut),
                      child: const Text('Next'),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

// ---------------- Demo portfolio ----------------

/// Demo entries carry this note so they can be cleared in one tap.
const demoNote = 'demo';

/// (kind, code or symbol, name, months ago, shares or rupees, SIP months)
const _demo = [
  ('mf', benchmarkScheme, 'Nifty 50 index fund (benchmark)', 18, 5000, 18), // monthly SIP of Rs 5,000
  ('mf', '122639', 'Parag Parikh Flexi Cap Fund - Direct Plan - Growth', 14, 50000, 0),
  ('stock', 'TCS', 'Tata Consultancy Services Limited', 16, 10, 0),
  ('stock', 'HDFCBANK', 'HDFC Bank Limited', 8, 20, 0),
  ('stock', 'INFY', 'Infosys Limited', 26, 15, 0),
];

/// Builds a demo portfolio from real past prices, so every screen has something to show.
Future<void> startDemo(BuildContext context, Session s) async {
  final status = ValueNotifier('Fetching real past prices…');
  // Captured now: the caller's context may be gone by the time the work ends.
  final nav = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      content: Row(children: [
        const CircularProgressIndicator(),
        const SizedBox(width: 16),
        Expanded(child: ValueListenableBuilder(valueListenable: status, builder: (_, v, _) => Text(v))),
      ]),
    ),
  );
  var added = 0;
  try {
    final m = s.market, n = Net();
    final today = istToday();
    for (final (kind, code, name, monthsAgo, size, sipMonths) in _demo) {
      status.value = 'Adding $name…';
      final id = kind == 'mf' ? await ensureFund(m, code, name) : await ensureStock(m, code, name);
      final inst = await (m.select(m.instruments)..where((i) => i.id.equals(id))).getSingle();
      await ensureHistory(m, n, inst);
      final dates = sipMonths > 0
          ? [for (var k = sipMonths; k >= 1; k--) nse.onOrAfter(addMonths(DateTime.utc(today.year, today.month, 5), -k))]
          : [nse.onOrAfter(addMonths(today, -monthsAgo))];
      for (final d in dates) {
        final px = await priceForDay(m, n, inst, d);
        if (px == null) continue;
        final (day, price) = px;
        final int units, fees;
        if (kind == 'mf') {
          final amount = size * 100;
          units = unitsFor(amount - mfStampOnAmount(amount), price);
          fees = mfStampOnValue(valuePaise(units, price));
        } else {
          units = size * unitScale;
          fees = 0;
        }
        await s.db.addTx(TransactionsCompanion.insert(
          instrumentId: id,
          date: fmtDay(day),
          type: sipMonths > 0 ? 'sip' : 'buy',
          unitsE4: units,
          priceE4: price,
          feesPaise: Value(fees),
          note: const Value(demoNote),
        ));
        added++;
      }
    }
  } catch (_) {
    // Partial demo is fine; the banner offers to clear it.
  } finally {
    nav.pop();
  }
  messenger.showSnackBar(SnackBar(
      content: Text(added == 0
          ? 'Could not reach the price sources. Check the connection and try again.'
          : 'Demo portfolio ready: $added entries at real past prices.')));
}

Future<void> clearDemo(BuildContext context, Session s) async {
  if (!await confirm(context, 'Clear the demo portfolio?', 'Removes every demo entry. Your own entries stay.', ok: 'Clear')) return;
  for (final t in s.portfolio.value?.txs ?? const <Transaction>[]) {
    if (t.note == demoNote) await s.db.deleteTx(t.id);
  }
  if (context.mounted) snack(context, 'Demo cleared. Search on Home to add your own.');
}
