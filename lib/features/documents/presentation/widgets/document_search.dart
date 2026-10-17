import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../providers/document_list_providers.dart';

class DocumentSearch extends ConsumerStatefulWidget {
  const DocumentSearch({super.key, required this.enabled});
  final bool enabled;
  @override
  ConsumerState<DocumentSearch> createState() => _DocumentSearchState();
}

class _DocumentSearchState extends ConsumerState<DocumentSearch> {
  late final _controller = TextEditingController(
    text: ref.read(searchProvider),
  );
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final sort = ref.watch(sortProvider);
    final labels = {
      DocumentSort.newest: s.sortNewest,
      DocumentSort.oldest: s.sortOldest,
      DocumentSort.name: s.sortName,
    };
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              decoration: InputDecoration(
                labelText: s.searchDocuments,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: s.clearSearch,
                  onPressed: widget.enabled
                      ? () {
                          _debounce?.cancel();
                          _controller.clear();
                          ref.read(searchProvider.notifier).set('');
                        }
                      : null,
                  icon: const Icon(Icons.clear),
                ),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 250), () {
                  ref.read(searchProvider.notifier).set(value);
                });
              },
            ),
          ),
          PopupMenuButton<DocumentSort>(
            enabled: widget.enabled,
            tooltip: '${s.sort}: ${labels[sort]}',
            initialValue: sort,
            icon: const Icon(Icons.sort),
            onSelected: (value) => ref.read(sortProvider.notifier).set(value),
            itemBuilder: (_) => [
              for (final entry in labels.entries)
                CheckedPopupMenuItem(
                  value: entry.key,
                  checked: entry.key == sort,
                  child: Text(entry.value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
