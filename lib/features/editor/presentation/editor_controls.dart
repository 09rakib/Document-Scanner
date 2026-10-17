import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../data/page_edit.dart';

class EditorControls extends StatelessWidget {
  const EditorControls({
    super.key,
    required this.page,
    required this.index,
    required this.count,
    required this.busy,
    required this.onChanged,
    required this.onMove,
    required this.onRemove,
    required this.onCrop,
  });
  final PageEdit page;
  final int index, count;
  final bool busy;
  final ValueChanged<PageEdit> onChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove, onCrop;
  Future<void> _filter(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final labels = [s.filterOriginal, s.filterGrayscale, s.filterBlackWhite];
    final selected = await showModalBottomSheet<PageFilter>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                s.pageFilter,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final value in PageFilter.values)
              ListTile(
                title: Text(labels[value.index]),
                selected: value == page.filter,
                trailing: value == page.filter ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) {
      onChanged(page.copyWith(filter: selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: busy ? null : onCrop,
              icon: const Icon(Icons.crop),
              label: Text(s.cropTool),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _filter(context),
              icon: const Icon(Icons.filter_b_and_w),
              label: Text(s.pageFilter),
            ),
            TextButton.icon(
              onPressed: busy ? null : () => onChanged(page.rotate()),
              icon: const Icon(Icons.rotate_right),
              label: Text(s.rotatePage),
            ),
            TextButton(
              onPressed: busy ? null : () => onChanged(PageEdit(page.path)),
              child: Text(s.resetPage),
            ),
          ],
        ),
        const Divider(),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: busy || index == 0 ? null : () => onMove(-1),
              icon: const Icon(Icons.arrow_back),
              label: Text(s.movePageEarlier),
            ),
            TextButton.icon(
              onPressed: busy || index == count - 1 ? null : () => onMove(1),
              icon: const Icon(Icons.arrow_forward),
              label: Text(s.movePageLater),
            ),
            TextButton.icon(
              onPressed: busy || count == 1 ? null : onRemove,
              icon: const Icon(Icons.delete_outline),
              label: Text(s.removePage),
            ),
          ],
        ),
      ],
    );
  }
}
