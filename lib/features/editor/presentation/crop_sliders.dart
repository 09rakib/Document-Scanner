import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/page_edit.dart';

class CropSliders extends StatelessWidget {
  const CropSliders({super.key, required this.crop, required this.onChanged});
  final PageCrop crop;
  final ValueChanged<PageCrop>? onChanged;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final labels = [
      s.cropTopLeft,
      s.cropTopRight,
      s.cropBottomRight,
      s.cropBottomLeft,
    ];
    return ExpansionTile(
      title: Text(s.preciseCrop),
      initiallyExpanded: true,
      children: [
        for (var i = 0; i < 4; i++) ...[
          Text(labels[i], style: Theme.of(context).textTheme.titleSmall),
          for (var axis = 0; axis < 2; axis++)
            Column(
              children: [
                Text(axis == 0 ? s.cropHorizontal : s.cropVertical),
                Slider(
                  value: axis == 0 ? crop.points[i].x : crop.points[i].y,
                  semanticFormatterCallback: (value) =>
                      NumberFormat.percentPattern(s.localeName).format(value),
                  onChanged: onChanged == null
                      ? null
                      : (value) => onChanged!(
                          crop.moveCorner(
                            i,
                            CropPoint(
                              axis == 0 ? value : crop.points[i].x,
                              axis == 1 ? value : crop.points[i].y,
                            ),
                          ),
                        ),
                ),
              ],
            ),
        ],
      ],
    );
  }
}
