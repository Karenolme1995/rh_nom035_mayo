// lib/widgets/confetti_painter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConfettiPainter extends CustomPainter {
  final double progress;
  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);

    const count = 90;

    for (int i = 0; i < count; i++) {
      final seedX = rng.nextDouble();
      final seedY = rng.nextDouble();
      final seedS = rng.nextDouble();

      final x = seedX * size.width;

      // caída + loop
      final y = ((seedY + progress) % 1.0) * size.height;

      final r = 2.0 + seedS * 4.5;

      // colores vivos sin paquetes
      final color = Color.fromARGB(
        220,
        80 + (i * 13) % 175,
        80 + (i * 29) % 175,
        80 + (i * 47) % 175,
      );

      final paint = Paint()..color = color;

      // rectangulitos inclinados
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((seedS * 2 - 1) * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: r * 1.8,
            height: r * 1.2,
          ),
          Radius.circular(r * 0.4),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
