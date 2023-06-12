/// An Object which acts as a tuple containing both an error and the
/// corresponding stack trace.
class ErrorAndStackTrace {
  /// A reference to the wrapped error object.
  final Object error;

  /// A reference to the wrapped [StackTrace]
  final StackTrace? stackTrace;

  /// Constructs an object containing both an [error] and the
  /// corresponding [stackTrace].
  ErrorAndStackTrace(this.error, this.stackTrace);

  @override
  String toString() =>
      'ErrorAndStackTrace{error: $error, stacktrace: $stackTrace}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorAndStackTrace &&
          runtimeType == other.runtimeType &&
          error == other.error &&
          stackTrace == other.stackTrace;

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;
}
