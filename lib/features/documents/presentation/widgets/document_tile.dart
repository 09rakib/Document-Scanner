import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/scanned_document.dart';

class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
  });
  final ScannedDocument document;
  final bool selected;
  final bool selecting;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final number = NumberFormat('0.#', s.localeName);
    final bytes = document.fileSizeBytes;
    final size = bytes < 1024 * 1024
        ? s.sizeKilobytes(number.format(bytes / 1024))
        : s.sizeMegabytes(number.format(bytes / (1024 * 1024)));
    return ListTile(
      selected: selected,
      minVerticalPadding: 12,
      leading: selecting
          ? Checkbox(
              value: selected,
              semanticLabel: document.name,
              onChanged: onTap == null ? null : (_) => onTap!(),
            )
          : SizedBox(
              width: 48,
              height: 64,
              child: Image.file(
                File(document.thumbnailPath),
                cacheWidth: 120,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.description_outlined),
              ),
            ),
      title: Text(document.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${s.pageCount(document.pageCount)} · $size\n${DateFormat.yMMMd(s.localeName).format(document.createdAt.toLocal())}',
      ),
      isThreeLine: true,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
