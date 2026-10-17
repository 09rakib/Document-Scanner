enum DocumentFailure { invalidDocument, invalidName, notFound, storage }

/// UI maps the code to localized copy; internal causes are never shown verbatim.
class DocumentRepositoryException implements Exception {
  const DocumentRepositoryException(this.failure, {this.cause});

  final DocumentFailure failure;
  final Object? cause;

  @override
  String toString() => 'DocumentRepositoryException(${failure.name})';
}
