import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../documents/data/scanned_document.dart';
import '../data/editor_service.dart';
import '../data/page_edit.dart';
import '../providers/editor_providers.dart';
import 'editor_preview.dart';
import 'editor_controls.dart';
import 'crop_screen.dart';
import 'editor_copy.dart';

class EditorForm extends ConsumerStatefulWidget {
  const EditorForm({super.key, required this.document, this.initialPage = 0});
  final ScannedDocument document;
  final int initialPage;
  @override
  ConsumerState<EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends ConsumerState<EditorForm> {
  EditingSession? _session;
  List<PageEdit> _pages = [];
  Future<PagePreview>? _preview;
  Object? _loadError;
  int _index = 0;
  bool _dirty = false, _leaving = false, _asking = false, _rendering = false;
  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(editorControllerProvider.notifier).reset();
    });
  }

  Future<void> _load() async {
    try {
      final session = await ref
          .read(editorServiceProvider)
          .prepare(widget.document);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loadError = null;
        _pages = session.pages.map(PageEdit.new).toList();
        _index = widget.initialPage.clamp(0, _pages.length - 1);
        _render();
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  void _render() {
    _rendering = true;
    final future = ref
        .read(editorServiceProvider)
        .previewEdited(_pages[_index]);
    _preview = future;
    void finished() {
      if (mounted && identical(_preview, future)) {
        setState(() => _rendering = false);
      }
    }

    unawaited(
      future.then(
        (_) => finished(),
        onError: (Object _, StackTrace _) => finished(),
      ),
    );
  }

  void _change(PageEdit value, {bool render = true}) => setState(() {
    _pages[_index] = value;
    _dirty = true;
    if (render) _render();
  });
  Future<void> _crop() async {
    final result = await Navigator.of(context).push<PageEdit>(
      MaterialPageRoute(
        builder: (_) => CropScreen(
          page: _pages[_index],
          loadPreview: ref.read(editorServiceProvider).preview,
        ),
      ),
    );
    if (result != null && mounted) _change(result);
  }

  Future<void> _leave() async {
    if (_asking) return;
    _asking = true;
    final s = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.discardEdits),
        content: Text(s.discardEditsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.discardEdits),
          ),
        ],
      ),
    );
    _asking = false;
    if (discard == true && mounted) {
      setState(() => _leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    }
  }

  Future<void> _remove() async {
    final s = AppLocalizations.of(context);
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.removePage),
        content: Text(s.removePageBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.removePage),
          ),
        ],
      ),
    );
    if (remove == true && mounted && _pages.length > 1) {
      setState(() {
        _pages.removeAt(_index);
        _index = _index.clamp(0, _pages.length - 1);
        _dirty = true;
        _render();
      });
    }
  }

  void _move(int direction) => setState(() {
    final page = _pages.removeAt(_index);
    _index += direction;
    _pages.insert(_index, page);
    _dirty = true;
  });
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(editorControllerProvider);
    final controller = ref.read(editorControllerProvider.notifier);
    return PopScope(
      canPop: !state.busy && (!_dirty || _leaving),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (state.busy) {
            unawaited(controller.cancel());
          } else {
            unawaited(_leave());
          }
        }
      },
      child: _session == null
          ? Center(
              child: _loadError == null
                  ? CircularProgressIndicator(semanticsLabel: s.loading)
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(editFailureMessage(s, _loadError)),
                          FilledButton(onPressed: _load, child: Text(s.retry)),
                        ],
                      ),
                    ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.document.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(s.editOriginalKept),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey('page-$_index-${_pages.length}'),
                  initialValue: _index,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: s.documentTitle),
                  items: [
                    for (var i = 0; i < _pages.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(s.currentPage(i + 1, _pages.length)),
                      ),
                  ],
                  onChanged: state.busy || _rendering
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _index = value;
                              _render();
                            });
                          }
                        },
                ),
                const SizedBox(height: 16),
                EditorPreview(future: _preview),
                const SizedBox(height: 12),
                EditorControls(
                  page: _pages[_index],
                  index: _index,
                  count: _pages.length,
                  busy: state.busy || _rendering,
                  onChanged: _change,
                  onMove: _move,
                  onRemove: _remove,
                  onCrop: _crop,
                ),
                if (state.failure != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      editFailureMessage(s, state.failure),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (state.busy) ...[
                  LinearProgressIndicator(
                    value: state.committing ? null : state.progress,
                    semanticsLabel: s.loading,
                  ),
                  Text(s.editSaving),
                  TextButton(
                    onPressed: state.committing ? null : controller.cancel,
                    child: Text(s.cancel),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: !_dirty || _rendering
                        ? null
                        : () async {
                            final saved = await controller.save(
                              _session!,
                              _pages,
                              s.editedDocumentName(widget.document.name),
                            );
                            if (saved != null && context.mounted) {
                              setState(() => _leaving = true);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  context.go('/documents/${saved.id}');
                                }
                              });
                            }
                          },
                    icon: const Icon(Icons.save_alt),
                    label: Text(s.saveEditedCopy),
                  ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
