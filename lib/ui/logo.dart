import 'package:flutter/material.dart';

/// SIGNAL mark: a calm line that rises slowly and ends in a leaf.
/// Patience as growth. Painted, so it is crisp at every size and is also
/// rendered to the Android launcher icons (see test/screenshots_test.dart).
class SignalLogo extends StatelessWidget {
  final bool background;
  const SignalLogo({super.key, this.background = true});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: LogoPainter(background: background), child: const SizedBox.expand());
}

class LogoPainter extends CustomPainter {
  final bool background;
  const LogoPainter({this.background = true});

  static const deep = Color(0xFF0B3D33);
  static const mid = Color(0xFF14A37F);
  static const glow = Color(0xFF5EEAD4);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    if (background) {
      final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(w * 0.24));
      c.drawRRect(
          r,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [mid, deep],
            ).createShader(Offset.zero & s));
      // Soft horizon glow.
      c.drawCircle(Offset(w * 0.78, w * 0.22), w * 0.32,
          Paint()..shader = RadialGradient(colors: [glow.withValues(alpha: 0.35), glow.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: Offset(w * 0.78, w * 0.22), radius: w * 0.32)));
    }
    final ink = background ? Colors.white : mid;
    // Slow rise: long flat start, gentle climb.
    final line = Path()
      ..moveTo(w * 0.16, w * 0.72)
      ..cubicTo(w * 0.34, w * 0.72, w * 0.40, w * 0.70, w * 0.48, w * 0.62)
      ..cubicTo(w * 0.56, w * 0.54, w * 0.60, w * 0.50, w * 0.66, w * 0.42);
    c.drawPath(
        line,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.075
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    // Leaf at the tip.
    final tip = Offset(w * 0.66, w * 0.42);
    final leaf = Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(tip.dx + w * 0.02, tip.dy - w * 0.20, tip.dx + w * 0.18, tip.dy - w * 0.22, tip.dx + w * 0.20, tip.dy - w * 0.20)
      ..cubicTo(tip.dx + w * 0.20, tip.dy - w * 0.06, tip.dx + w * 0.10, tip.dy + w * 0.02, tip.dx, tip.dy)
      ..close();
    c.drawPath(leaf, Paint()..color = background ? glow : mid.withValues(alpha: 0.8));
    // Leaf vein.
    c.drawLine(
        tip,
        Offset(tip.dx + w * 0.15, tip.dy - w * 0.15),
        Paint()
          ..color = background ? deep.withValues(alpha: 0.55) : Colors.white
          ..strokeWidth = w * 0.022
          ..strokeCap = StrokeCap.round);
    // Seed dot at the start: where patience begins.
    c.drawCircle(Offset(w * 0.16, w * 0.72), w * 0.055, Paint()..color = background ? glow : mid);
  }

  @override
  bool shouldRepaint(LogoPainter o) => o.background != background;
}
