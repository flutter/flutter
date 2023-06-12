part of hive;

/// An error related to Hive.
class HiveError extends Error {
  /// A description of the error.
  final String message;

  /// Create a new Hive error (internal)
  HiveError(this.message);

  @override
  String toString() {
    return 'HiveError: $message';
  }
}
