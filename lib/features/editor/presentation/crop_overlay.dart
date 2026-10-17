import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/page_edit.dart';

class CropOverlay extends CustomPainter {
  CropOverlay(this.crop, this.color, this.selected);
  final PageCrop crop;
  final Color color;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final p = crop.points
        .map((v) => Offset(v.x * size.width, v.y * size.height))
        .toList();
    final polygon = Path()..addPolygon(p, true);
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addPath(polygon, Offset.zero);
    canvas.drawPath(shade, Paint()..color = Colors.black54);
    canvas.drawPath(
      polygon,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 4; i++) {
      final mid = (p[i] + p[(i + 1) % 4]) / 2;
      final delta = p[(i + 1) % 4] - p[i];
      canvas.save();
      canvas.translate(mid.dx, mid.dy);
      canvas.rotate(math.atan2(delta.dy, delta.dx));
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 30, height: 12),
        const Radius.circular(7),
      );
      if (selected == i + 4) {
        canvas.drawRRect(rect.inflate(5), Paint()..color = color);
      }
      canvas.drawRRect(rect, Paint()..color = Colors.white);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.restore();
      if (selected == i) canvas.drawCircle(p[i], 19, Paint()..color = color);
      canvas.drawCircle(p[i], 10, Paint()..color = Colors.white);
      canvas.drawCircle(
        p[i],
        10,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CropOverlay oldDelegate) =>
      oldDelegate.crop != crop ||
      oldDelegate.color != color ||
      oldDelegate.selected != selected;
}
