import 'dart:math' as math;

import 'package:image/image.dart' as image;

import 'page_edit.dart';

/// Inverse projective mapping: output rectangle → source quadrilateral. Unlike
/// bilinear corner blending, this homography keeps straight document lines straight.
image.Image rectifyPage(
  image.Image source,
  PageCrop crop, {
  void Function()? check,
}) {
  if (!crop.valid) throw const EditException(EditFailure.corrupt);
  if (crop.axisAligned) {
    final left = (crop.left * source.width).round().clamp(0, source.width - 1);
    final top = (crop.top * source.height).round().clamp(0, source.height - 1);
    final right = (crop.right * source.width).round().clamp(
      left + 1,
      source.width,
    );
    final bottom = (crop.bottom * source.height).round().clamp(
      top + 1,
      source.height,
    );
    if (left == 0 &&
        top == 0 &&
        right == source.width &&
        bottom == source.height) {
      return source;
    }
    return image.copyCrop(
      source,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
  }
  final p = crop.points;
  double length(int i, int j) => math.sqrt(
    math.pow((p[i].x - p[j].x) * source.width, 2) +
        math.pow((p[i].y - p[j].y) * source.height, 2),
  );
  var width = math.max(length(0, 1), length(3, 2)).round().clamp(2, 32768);
  var height = math.max(length(0, 3), length(1, 2)).round().clamp(2, 32768);
  const maxPixels = 16 * 1024 * 1024;
  if (width * height > maxPixels) {
    final factor = math.sqrt(maxPixels / (width * height));
    width = math.max(2, (width * factor).floor());
    height = math.max(2, (height * factor).floor());
  }
  final dx1 = p[1].x - p[2].x, dx2 = p[3].x - p[2].x;
  final dy1 = p[1].y - p[2].y, dy2 = p[3].y - p[2].y;
  final sx = p[0].x - p[1].x + p[2].x - p[3].x;
  final sy = p[0].y - p[1].y + p[2].y - p[3].y;
  final determinant = dx1 * dy2 - dx2 * dy1;
  if (determinant.abs() < 1e-10) throw const EditException(EditFailure.corrupt);
  final g = (sx * dy2 - dx2 * sy) / determinant;
  final h = (dx1 * sy - sx * dy1) / determinant;
  final a = p[1].x - p[0].x + g * p[1].x;
  final b = p[3].x - p[0].x + h * p[3].x;
  final d = p[1].y - p[0].y + g * p[1].y;
  final e = p[3].y - p[0].y + h * p[3].y;
  final output = image.Image(width: width, height: height, numChannels: 3);
  for (var y = 0; y < height; y++) {
    if (y % 32 == 0) check?.call();
    final v = y / (height - 1);
    for (var x = 0; x < width; x++) {
      final u = x / (width - 1);
      final denominator = g * u + h * v + 1;
      final sourceX =
          ((a * u + b * v + p[0].x) / denominator * (source.width - 1)).clamp(
            0.0,
            source.width - 1.0,
          );
      final sourceY =
          ((d * u + e * v + p[0].y) / denominator * (source.height - 1)).clamp(
            0.0,
            source.height - 1.0,
          );
      output.setPixel(
        x,
        y,
        source.getPixelInterpolate(
          sourceX,
          sourceY,
          interpolation: image.Interpolation.linear,
        ),
      );
    }
  }
  return output;
}
