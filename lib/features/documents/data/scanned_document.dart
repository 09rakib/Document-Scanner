/// Immutable metadata. Binary PDF/image contents are never stored in SQLite.
class ScannedDocument {
  const ScannedDocument({
    this.id,
    required this.name,
    required this.pdfPath,
    required this.thumbnailPath,
    required this.pageCount,
    required this.fileSizeBytes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Null only before the first insert; SQLite assigns the persisted ID.
  final int? id;
  final String name;
  final String pdfPath;
  final String thumbnailPath;
  final int pageCount;
  final int fileSizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ScannedDocument copyWith({int? id, String? name, DateTime? updatedAt}) =>
      ScannedDocument(
        id: id ?? this.id,
        name: name ?? this.name,
        pdfPath: pdfPath,
        thumbnailPath: thumbnailPath,
        pageCount: pageCount,
        fileSizeBytes: fileSizeBytes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'pdf_path': pdfPath,
    'thumbnail_path': thumbnailPath,
    'page_count': pageCount,
    'file_size_bytes': fileSizeBytes,
    'created_at': createdAt.toUtc().millisecondsSinceEpoch,
    'updated_at': updatedAt.toUtc().millisecondsSinceEpoch,
  };

  factory ScannedDocument.fromMap(Map<String, Object?> map) {
    T value<T>(String key) {
      final result = map[key];
      if (result is! T) throw FormatException('Invalid document field: $key');
      return result;
    }

    return ScannedDocument(
      id: value<int>('id'),
      name: value<String>('name'),
      pdfPath: value<String>('pdf_path'),
      thumbnailPath: value<String>('thumbnail_path'),
      pageCount: value<int>('page_count'),
      fileSizeBytes: value<int>('file_size_bytes'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        value<int>('created_at'),
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        value<int>('updated_at'),
        isUtc: true,
      ),
    );
  }
}
