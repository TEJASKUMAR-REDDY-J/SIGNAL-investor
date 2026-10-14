import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/lots.dart';
import '../engine/tax.dart';
import 'theme.dart';
import 'widgets.dart';

/// Number that rolls to its new value instead of jumping.
class RollingMoney extends StatelessWidget {
  final int paise;
  final TextStyle? style;
  const RollingMoney(this.paise, {super.key, this.style});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: paise.toDouble()),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Money(v.round(), decimals: true, style: style),
      );
}

/// The Rs 1.25L tax-free allowance as a jar that fills with booked long-term gains.
class ExemptionJar extends StatelessWidget {
  final int usedPaise;
  final DateTime today;
  final double size;
  const ExemptionJar({super.key, required this.usedPaise, required this.today, this.size = 92});

  bool get glowing => (today.month == 2 || today.month == 3) && usedPaise < ltcgExemptionPaise;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fill = (usedPaise / ltcgExemptionPaise).clamp(0.0, 1.0);
    return Semantics(
      label: 'Tax-free allowance ${(fill * 100).round()} percent used',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fill),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          size: Size(size * 0.78, size),
          painter: _JarPainter(v, cs.primary, cs.onSurfaceVariant, glowing ? cs.warn : null),
        ),
      ),
    );
  }
}

class _JarPainter extends CustomPainter {
  final double fill;
  final Color liquid, outline;
  final Color? glow;
  _JarPainter(this.fill, this.liquid, this.outline, this.glow);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.06, h * 0.18, w * 0.88, h * 0.8), Radius.circular(w * 0.22));
    final neck = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.24, h * 0.04, w * 0.52, h * 0.16), Radius.circular(w * 0.06));
    if (glow != null) {
      c.drawRRect(body.inflate(4), Paint()
        ..color = glow!.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    c.save();
    c.clipRRect(body);
    final top = body.bottom - (body.height * fill);
    final wave = Path()..moveTo(body.left, top);
    for (var x = 0.0; x <= body.width; x += 4) {
      wave.lineTo(body.left + x, top + math.sin(x / body.width * math.pi * 2) * 2.5);
    }
    wave
      ..lineTo(body.right, body.bottom)
      ..lineTo(body.left, body.bottom)
      ..close();
    c.drawPath(wave, Paint()..color = liquid.withValues(alpha: 0.75));
    c.restore();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = outline.withValues(alpha: 0.7);
    c.drawRRect(body, stroke);
    c.drawRRect(neck, stroke);
  }

  @override
  bool shouldRepaint(_JarPainter o) => o.fill != fill || o.glow != glow || o.liquid != liquid;
}

/// Each lot is a fruit that grows from sprout to ripe over its 12 months.
class Orchard extends StatelessWidget {
  final List<Lot> lots;
  final DateTime today;
  const Orchard({super.key, required this.lots, required this.today});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(spacing: 14, runSpacing: 14, children: [
      for (final l in lots)
        Builder(builder: (context) {
          final total = l.longTermDate.difference(l.buyDate).inDays;
          final p = (today.difference(l.buyDate).inDays / total).clamp(0.0, 1.0);
          final ripe = isLongTerm(l.buyDate, today);
          return Tooltip(
            message: ripe
                ? 'Ripe since ${prettyDay(l.longTermDate)}'
                : 'Ripens ${inDays(l.longTermDate.difference(today).inDays)} (${prettyDay(l.longTermDate)})',
            child: SizedBox(
              width: 62,
              child: Column(children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: p),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, v, _) =>
                      CustomPaint(size: const Size(48, 52), painter: _FruitPainter(v, ripe, cs.primary, cs.warn)),
                ),
                const SizedBox(height: 4),
                Text(ripe ? 'ripe' : '${(p * 100).round()}%',
                    style: TextStyle(fontSize: 11, color: ripe ? cs.warn : cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                Text('${months[l.buyDate.month - 1]} ${l.buyDate.year % 100}',
                    style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
              ]),
            ),
          );
        }),
    ]);
  }
}

class _FruitPainter extends CustomPainter {
  final double p;
  final bool ripe;
  final Color young, ripeColor;
  _FruitPainter(this.p, this.ripe, this.young, this.ripeColor);

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final r = 6 + 14 * p;
    final cy = s.height - r - 2;
    final color = Color.lerp(young.withValues(alpha: 0.55), ripeColor, ripe ? 1 : p * 0.7)!;
    // Stem and leaf.
    final stem = Paint()
      ..color = young
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx, cy - r), Offset(cx, cy - r - 7), stem);
    final leaf = Path()
      ..moveTo(cx, cy - r - 5)
      ..quadraticBezierTo(cx + 9, cy - r - 12, cx + 12, cy - r - 4)
      ..quadraticBezierTo(cx + 5, cy - r - 2, cx, cy - r - 5);
    c.drawPath(leaf, Paint()..color = young.withValues(alpha: 0.9));
    c.drawCircle(Offset(cx, cy), r, Paint()..color = color);
    c.drawCircle(Offset(cx - r * 0.35, cy - r * 0.35), r * 0.22, Paint()..color = Colors.white.withValues(alpha: 0.35));
  }

  @override
  bool shouldRepaint(_FruitPainter o) => o.p != p || o.ripe != ripe;
}

/// Press and hold for 3 seconds while a ring fills; a stronger haptic at the end.
/// Releasing early cancels. Used for the one action that matters: deciding to sell.
class HoldToConfirm extends StatefulWidget {
  final String label;
  final String? sublabel;
  final Color? color;
  final VoidCallback onConfirmed;
  final Duration duration;
  const HoldToConfirm(
      {super.key,
      required this.label,
      this.sublabel,
      this.color,
      required this.onConfirmed,
      this.duration = const Duration(seconds: 3)});
  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
        _c.reset();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = widget.color ?? cs.primary;
    return Semantics(
      button: true,
      label: '${widget.label}. Press and hold for three seconds.',
      onLongPress: widget.onConfirmed, // screen-reader long-press action; pointers still need the 3 s ring
      child: GestureDetector(
        onLongPressStart: (_) {
          HapticFeedback.selectionClick();
          _c.forward();
        },
        onLongPressEnd: (_) => _c.isCompleted ? null : _c.reverse(),
        onLongPressCancel: () => _c.reverse(),
        onTap: () => snack(context, 'Press and hold to confirm'),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Column(children: [
            SizedBox(
              width: 132,
              height: 132,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _c.value,
                    strokeWidth: 9,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.touch_app, color: color, size: 30),
                    if (widget.sublabel != null)
                      Text(widget.sublabel!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
