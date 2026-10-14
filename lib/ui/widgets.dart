import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../db/db.dart';
import '../db/open_db.dart';
import '../engine/money.dart';
import '../engine/lots.dart';
import '../engine/portfolio.dart';
import '../engine/fund_rank.dart';
import '../engine/news_score.dart';
import '../engine/scoring.dart';
import '../engine/sell_rules.dart';
import '../pipeline/refresh.dart';
import '../sources/yahoo.dart';
import 'theme.dart';

/// Everything a signed-in screen needs. One portfolio, computed once per change.
class Session {
  final Profile profile;
  final ProfileDb db;
  final MarketDb market;
  final ValueNotifier<Portfolio?> portfolio;
  final VoidCallback lock;
  final refreshing = ValueNotifier(false);
  final receipt = ValueNotifier<List<ReceiptLine>?>(null);
  final lastRefresh = ValueNotifier<DateTime?>(null);
  final suggestions = ValueNotifier<List<SellSuggestion>>(const []);
  final openSignals = ValueNotifier<List<Signal>>(const []);
  final theses = ValueNotifier<Map<int, Thesis>>(const {});
  final filings = ValueNotifier<Map<int, List<Filing>>>(const {});
  /// Lots that turned long-term since the last visit: (holding name, lot).
  final ripened = ValueNotifier<List<(String, Lot)>>(const []);
  /// Live quotes (delayed a few minutes) by instrument id: indices, holdings, watchlist.
  final quotes = ValueNotifier<Map<int, Quote>>(const {});
  final watch = ValueNotifier<Set<int>>(const {});
  /// Advisor output from the cache; null until first loaded.
  final stockIdeas = ValueNotifier<List<Candidate>?>(null);
  final fundIdeas = ValueNotifier<Map<String, List<FundIdea>>?>(null);
  /// 7-day news points for every tracked company, strongest first.
  final news = ValueNotifier<List<NewsScore>>(const []);
  Future<void> Function({bool force})? refresh;
  /// Reloads advisor ideas from the cache (after a scan).
  Future<void> Function()? reloadIdeas;
  /// Paper agents: progress text while a run is going, and the run trigger.
  final agentStatus = ValueNotifier<String?>(null);
  Future<void> Function()? runAgents;
  Session(this.profile, this.db, this.market, this.portfolio, this.lock);
}

/// Tap the eye to blur every rupee amount (public places).
final hideMoney = ValueNotifier(false);

class Money extends StatelessWidget {
  final int paise;
  final TextStyle? style;
  final bool decimals;
  final bool signed;
  final bool colored;
  const Money(this.paise, {super.key, this.style, this.decimals = false, this.signed = false, this.colored = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = rupees(paise, decimals: decimals);
    final text = Text(signed && paise > 0 ? '+$s' : s,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: (style ?? const TextStyle()).copyWith(
            fontFeatures: tabular, color: colored ? cs.signed(paise) : null));
    return ValueListenableBuilder(
      valueListenable: hideMoney,
      builder: (context, hide, child) => hide
          ? ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7), child: ExcludeSemantics(child: child!))
          : child!,
      child: text,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Row(children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          ?trailing,
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
          child: Icon(icon, size: 36, color: cs.primary),
        ),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(message, style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ]),
    );
  }
}

/// Small coloured label, e.g. "LTCG", "Satellite".
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Pill(this.text, {super.key, required this.color, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

class Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;
  const Notice({super.key, required this.icon, required this.text, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500))),
              if (onTap != null) Icon(Icons.chevron_right, color: color),
            ]),
          ),
        ),
      );
}

/// Footnote style disclaimer.
class Fine extends StatelessWidget {
  final String text;
  const Fine(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ]),
      );
}

/// Thin rounded progress bar.
class Meter extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  const Meter(this.value, {super.key, this.color, this.height = 8});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: height,
          color: color,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      );
}

Future<bool> confirm(BuildContext context, String title, String body, {String ok = 'Delete'}) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
                foregroundColor: Theme.of(ctx).colorScheme.onError,
                minimumSize: const Size(64, 40)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ok),
          ),
        ],
      ),
    ) ==
    true;

void snack(BuildContext context, String m) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));
}

String txLabel(String type) => switch (type) {
      'buy' => 'Buy',
      'sip' => 'SIP',
      'sell' => 'Sell',
      'dividend' => 'Dividend',
      'split' => 'Split',
      'bonus' => 'Bonus',
      _ => type,
    };

IconData txIcon(String type) => switch (type) {
      'buy' => Icons.add_shopping_cart,
      'sip' => Icons.autorenew,
      'sell' => Icons.sell_outlined,
      'dividend' => Icons.payments_outlined,
      'split' => Icons.call_split,
      'bonus' => Icons.card_giftcard,
      _ => Icons.circle,
    };

/// Per-unit price: "₹3,350.00", or "₹45.6789" when it has more than 2 decimals.
String priceLabel(int price4) => price4 % 100 == 0
    ? rupees(price4 ~/ 100)
    : '₹${formatScaled(price4, 4, minDecimals: 2)}';

/// "₹1,234" for buys/sells, "1 → 5" for splits, "1:1" bonus.
String txSummary(Transaction t) => switch (t.type) {
      'dividend' => rupees(valuePaise(unitScale, t.priceE4)),
      'split' => '1 → ${formatScaled(t.unitsE4, 4)}',
      'bonus' => '${formatScaled(t.unitsE4, 4)} : 1',
      _ => '${formatScaled(t.unitsE4, 4)} @ ${priceLabel(t.priceE4)}',
    };

const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String prettyDay(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';
String monthYear(DateTime d) => '${months[d.month - 1]} ${d.year}';

String inDays(int days) {
  if (days <= 0) return 'today';
  if (days == 1) return 'tomorrow';
  if (days < 60) return 'in $days days';
  if (days < 730) return 'in ${(days / 30.4).round()} months';
  return 'in ${(days / 365.25).toStringAsFixed(1)} years';
}
