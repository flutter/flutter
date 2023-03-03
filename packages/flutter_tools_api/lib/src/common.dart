/// Exceptions thrown from the root isolate that wrap errors from the extensions isolate.
class ExtensionException implements Exception {
  /// Call with a tuple passed from Isolate.addErrorListener.
  factory ExtensionException(List<Object?> tuple) {
    return ExtensionException._(tuple[0]! as String, tuple[1]! as String);
  }

  ExtensionException._(this.message, this.stackTrace);

  /// Error message.
  final String message;

  /// Stringified [StackTrace].
  final String stackTrace;

  @override
  String toString() => 'A tool extension threw an unhandled exception: $message\n\n$stackTrace';
}

/// A request from the root to child isolate.
class RequestWrapper<T extends Request> {
  /// Create a new [RequestWrapper].
  RequestWrapper({
    required this.id,
    required this.request,
  });

  /// Unique identifier for this request that will match with its response.
  final int id;
  final T request;

  @override
  String toString() => 'Request (ID $id)';
}

abstract class Request {}

typedef RequestHandler<T extends Request> = void Function(RequestWrapper<T>, Response?);

/// A response to the root from the child isolate.
abstract class Response {
  /// Create a new [Response].
  Response({
    required this.id,
  });

  /// Unique identifier for this response that will match with a previous request.
  final int id;

  @override
  String toString() => 'Response (ID $id)';
}
