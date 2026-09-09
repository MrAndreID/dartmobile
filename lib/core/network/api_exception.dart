/// Raised by the network layer when a request fails.
///
/// This is a transport-level exception. Repositories catch it and map it to a
/// [Failure] before it reaches the presentation layer.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;

  /// HTTP status code, when the request reached the server.
  final int? statusCode;

  /// The `code` field from the goapi error envelope, when present.
  final String? code;

  bool get isNetworkError => statusCode == null;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Raised when a response reached the app but could not be parsed into the
/// expected shape (malformed body, missing fields, wrong types).
///
/// Kept distinct from [ApiException] so repositories can translate it into a
/// [ParsingFailure] rather than a generic server error.
class ParsingException extends ApiException {
  const ParsingException([super.message = 'Malformed response from server.']);
}
