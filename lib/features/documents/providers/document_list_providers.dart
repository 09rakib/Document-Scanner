import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scanned_document.dart';
import 'document_providers.dart';

enum DocumentSort { newest, oldest, name }

class DocumentListPreference<T> extends Notifier<T> {
  DocumentListPreference(this.initial);
  final T initial;
  @override
  T build() => initial;
  void set(T value) => state = value;
}

final searchProvider = NotifierProvider<DocumentListPreference<String>, String>(
  () => DocumentListPreference(''),
);
final sortProvider =
    NotifierProvider<DocumentListPreference<DocumentSort>, DocumentSort>(
      () => DocumentListPreference(DocumentSort.newest),
    );

List<ScannedDocument> filterDocuments(
  (List<ScannedDocument>, String, DocumentSort) input,
) {
  final (documents, query, sort) = input;
  final needle = query.trim().toLowerCase();
  final rows = documents
      .where((document) => document.name.toLowerCase().contains(needle))
      .toList();
  rows.sort((a, b) {
    final comparison = switch (sort) {
      DocumentSort.newest => b.createdAt.compareTo(a.createdAt),
      DocumentSort.oldest => a.createdAt.compareTo(b.createdAt),
      DocumentSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };
    return comparison != 0 ? comparison : (b.id ?? 0).compareTo(a.id ?? 0);
  });
  return rows;
}

final visibleDocumentsProvider =
    FutureProvider.autoDispose<List<ScannedDocument>>((ref) async {
      final query = ref.watch(searchProvider);
      final sort = ref.watch(sortProvider);
      final documents = await ref.watch(documentsProvider.future);
      if (documents.length > 500) {
        return compute(filterDocuments, (documents, query, sort));
      }
      return filterDocuments((documents, query, sort));
    });
