import 'dart:math' as math;

class CropPoint {
  const CropPoint(this.x, this.y);
  final double x, y;
  CropPoint get clockwise => CropPoint(1 - y, x);
  CropPoint shifted(double dx, double dy) => CropPoint(x + dx, y + dy);
  @override
  bool operator ==(Object other) =>
      other is CropPoint && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

/// Clockwise, normalized source points. A corner never shares coordinates with
/// another corner. Rectangle arguments keep older call sites compatible.
class PageCrop {
  const PageCrop({
    double left = 0,
    double top = 0,
    double right = 1,
    double bottom = 1,
    CropPoint? topLeft,
    CropPoint? topRight,
    CropPoint? bottomRight,
    CropPoint? bottomLeft,
    // Public rectangle argument names are retained for existing edit callers.
    // ignore: prefer_initializing_formals
  }) : _left = left,
       // ignore: prefer_initializing_formals
       _top = top,
       // ignore: prefer_initializing_formals
       _right = right,
       // ignore: prefer_initializing_formals
       _bottom = bottom,
       _tl = topLeft,
       _tr = topRight,
       _br = bottomRight,
       _bl = bottomLeft;
  final double _left, _top, _right, _bottom;
  final CropPoint? _tl, _tr, _br, _bl;
  CropPoint get topLeft => _tl ?? CropPoint(_left, _top);
  CropPoint get topRight => _tr ?? CropPoint(_right, _top);
  CropPoint get bottomRight => _br ?? CropPoint(_right, _bottom);
  CropPoint get bottomLeft => _bl ?? CropPoint(_left, _bottom);
  List<CropPoint> get points => [topLeft, topRight, bottomRight, bottomLeft];
  double get left => points.map((p) => p.x).reduce(math.min);
  double get top => points.map((p) => p.y).reduce(math.min);
  double get right => points.map((p) => p.x).reduce(math.max);
  double get bottom => points.map((p) => p.y).reduce(math.max);
  bool get axisAligned =>
      topLeft.y == topRight.y &&
      bottomLeft.y == bottomRight.y &&
      topLeft.x == bottomLeft.x &&
      topRight.x == bottomRight.x;

  bool get valid {
    final p = points;
    if (p.any(
      (v) =>
          !v.x.isFinite ||
          !v.y.isFinite ||
          v.x < 0 ||
          v.x > 1 ||
          v.y < 0 ||
          v.y > 1,
    )) {
      return false;
    }
    for (var i = 0; i < 4; i++) {
      final a = p[i], b = p[(i + 1) % 4], c = p[(i + 2) % 4];
      // Strict convexity excludes crossed edges, collapsed and inverted crops.
      if ((b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x) < .0025) {
        return false;
      }
      if (math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2) < .0025) return false;
    }
    return true;
  }

  static PageCrop fromPoints(List<CropPoint> p) => PageCrop(
    topLeft: p[0],
    topRight: p[1],
    bottomRight: p[2],
    bottomLeft: p[3],
  );
  PageCrop get clockwise => fromPoints([
    bottomLeft.clockwise,
    topLeft.clockwise,
    topRight.clockwise,
    bottomRight.clockwise,
  ]);

  PageCrop moveCorner(int index, CropPoint destination) => _move(
    [index],
    destination.x - points[index].x,
    destination.y - points[index].y,
  );
  PageCrop moveEdge(int index, double dx, double dy) =>
      _move([index, (index + 1) % 4], dx, dy);
  PageCrop translated(double dx, double dy) => _move([0, 1, 2, 3], dx, dy);

  PageCrop _move(List<int> indices, double dx, double dy) {
    if (!valid || !dx.isFinite || !dy.isFinite) return this;
    final p = points;
    final moving = indices.map((i) => p[i]);
    dx = dx.clamp(
      -moving.map((v) => v.x).reduce(math.min),
      1 - moving.map((v) => v.x).reduce(math.max),
    );
    dy = dy.clamp(
      -moving.map((v) => v.y).reduce(math.min),
      1 - moving.map((v) => v.y).reduce(math.max),
    );
    PageCrop candidate(double fraction) => fromPoints([
      for (var i = 0; i < 4; i++)
        indices.contains(i) ? p[i].shifted(dx * fraction, dy * fraction) : p[i],
    ]);
    final full = candidate(1);
    if (full.valid) return full;
    // Stop at the last valid shape rather than jumping or crossing an edge.
    var low = 0.0, high = 1.0;
    for (var i = 0; i < 24; i++) {
      final middle = (low + high) / 2;
      if (candidate(middle).valid) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return candidate(low);
  }
}
