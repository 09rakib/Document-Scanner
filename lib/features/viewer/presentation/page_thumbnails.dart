import 'dart:io';

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../documents/data/scanned_document.dart';

class PageThumbnails extends StatelessWidget {
  const PageThumbnails({
    super.key,
    required this.document,
    required this.page,
    required this.onSelected,
  });
  final ScannedDocument document;
  final int page;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 96,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: document.pageCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(4),
        child: Semantics(
          selected: page == index,
          button: true,
          label: AppLocalizations.of(context)
              .currentPage(index + 1, document.pageCount),
          child: InkWell(
            onTap: () => onSelected(index),
            child: Container(
              width: 64,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: page == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: page == index ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.file(
                File(
                  '${File(document.pdfPath).parent.path}/page_${index + 1}.jpg',
                ),
                cacheWidth: 128,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.description_outlined),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
