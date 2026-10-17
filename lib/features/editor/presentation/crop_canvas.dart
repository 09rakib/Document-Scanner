import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/page_edit.dart';
import 'crop_overlay.dart';

class CropCanvas extends StatefulWidget {
  const CropCanvas({
    super.key,
    required this.preview,
    required this.crop,
    required this.onChanged,
  });
  final PagePreview preview;
  final PageCrop crop;
  final ValueChanged<PageCrop>? onChanged;
  @override
  State<CropCanvas> createState() => _CropCanvasState();
}

class _CropCanvasState extends State<CropCanvas> {
  int? _drag, _selected;
  @override
  void didUpdateWidget(covariant CropCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.preview, widget.preview) ||
        widget.onChanged == null) {
      _selected = null;
      _drag = null;
    }
  }

  List<Offset> _handles(double w, double h) {
    final p = widget.crop.points.map((p) => Offset(p.x * w, p.y * h)).toList();
    return [...p, for (var i = 0; i < 4; i++) (p[i] + p[(i + 1) % 4]) / 2];
  }

  int? _hit(Offset p, double w, double h) {
    final distances = _handles(
      w,
      h,
    ).map((handle) => (p - handle).distance).toList();
    final nearest = distances.reduce(math.min);
    return nearest <= 36 ? distances.indexOf(nearest) : null;
  }

  void _place(int handle, Offset p, double w, double h) {
    if (handle < 4) {
      widget.onChanged!(
        widget.crop.moveCorner(handle, CropPoint(p.dx / w, p.dy / h)),
      );
    } else {
      final mid = _handles(w, h)[handle];
      widget.onChanged!(
        widget.crop.moveEdge(
          handle - 4,
          (p.dx - mid.dx) / w,
          (p.dy - mid.dy) / h,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final w = math.min(
        constraints.maxWidth,
        constraints.maxHeight * widget.preview.width / widget.preview.height,
      );
      final h = w * widget.preview.height / widget.preview.width;
      return Center(
        child: SizedBox(
          width: w,
          height: h,
          child: Semantics(
            label: AppLocalizations.of(context).cropHelp,
            value: _selected == null
                ? null
                : AppLocalizations.of(context).cropCornerSelected,
            liveRegion: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onTapUp: widget.onChanged == null
                  ? null
                  : (event) {
                      final selected = _selected;
                      if (selected == null) {
                        setState(
                          () => _selected = _hit(event.localPosition, w, h),
                        );
                      } else {
                        setState(() => _selected = null);
                        _place(selected, event.localPosition, w, h);
                      }
                    },
              onPanStart: widget.onChanged == null
                  ? null
                  : (event) {
                      setState(() => _selected = null);
                      final path = Path()
                        ..addPolygon(_handles(w, h).take(4).toList(), true);
                      _drag =
                          _hit(event.localPosition, w, h) ??
                          (path.contains(event.localPosition) ? 8 : null);
                    },
              onPanUpdate: widget.onChanged == null
                  ? null
                  : (event) {
                      final handle = _drag;
                      if (handle == null) return;
                      if (handle < 4) {
                        _place(handle, event.localPosition, w, h);
                      } else if (handle < 8) {
                        widget.onChanged!(
                          widget.crop.moveEdge(
                            handle - 4,
                            event.delta.dx / w,
                            event.delta.dy / h,
                          ),
                        );
                      } else {
                        widget.onChanged!(
                          widget.crop.translated(
                            event.delta.dx / w,
                            event.delta.dy / h,
                          ),
                        );
                      }
                    },
              onPanEnd: (_) => _drag = null,
              onPanCancel: () => _drag = null,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Image.memory(
                    widget.preview.bytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    excludeFromSemantics: true,
                  ),
                  CustomPaint(
                    painter: CropOverlay(
                      widget.crop,
                      Theme.of(context).colorScheme.primary,
                      _selected,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
