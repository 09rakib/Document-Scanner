import 'package:docscan/features/documents/data/scanned_document.dart';
import 'package:docscan/features/documents/providers/document_list_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ScannedDocument row(int id, String name, int day) => ScannedDocument(
    id: id,
    name: name,
    pdfPath: '/documents/$id.pdf',
    thumbnailPath: '/documents/$id.jpg',
    pageCount: 1,
    fileSizeBytes: 2048,
    createdAt: DateTime.utc(2026, 1, day),
    updatedAt: DateTime.utc(2026, 1, day),
  );
  final rows = [
    row(1, 'Alpha', 1),
    row(2, 'নথি 100%_A', 2),
    row(3, 'beta', 3),
    row(4, 'ALPHA', 1),
  ];
  test(
    'search supports Bangla, literal wildcards and case-insensitive English',
    () {
      expect(filterDocuments((rows, 'নথি', DocumentSort.newest)).single.id, 2);
      expect(filterDocuments((rows, '%_', DocumentSort.newest)).single.id, 2);
      expect(
        filterDocuments((rows, ' ALPHA ', DocumentSort.newest))
            .map((row) => row.id),
        [4, 1],
      );
      expect(filterDocuments((rows, 'missing', DocumentSort.newest)), isEmpty);
    },
  );
  test(
    'sort uses date or name and a stable id tie breaker without mutating input',
    () {
      expect(
        filterDocuments((rows, '', DocumentSort.newest)).map((row) => row.id),
        [3, 2, 4, 1],
      );
      expect(
        filterDocuments((rows, '', DocumentSort.oldest)).map((row) => row.id),
        [4, 1, 2, 3],
      );
      expect(
        filterDocuments((rows, '', DocumentSort.name)).map((row) => row.id),
        [4, 1, 3, 2],
      );
      expect(rows.map((row) => row.id), [1, 2, 3, 4]);
    },
  );
}
