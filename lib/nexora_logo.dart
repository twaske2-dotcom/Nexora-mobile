import 'package:flutter/material.dart';

// Concept: shared CustomPainter - reusable logo across multiple screens
class NexoraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF4D67A), Color(0xFFF4D67A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.32, h * 0.68);
    path.lineTo(w * 0.32, h * 0.32);
    path.cubicTo(w * 0.32, h * 0.32, w * 0.68, h * 0.68, w * 0.68, h * 0.32);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
