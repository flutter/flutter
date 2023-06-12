import 'dart:async';

import 'package:rxdart/src/utils/error_and_stacktrace.dart';

/// The function used to create the [Stream] which triggers a re-listen.
typedef RetryWhenStreamFactory = Stream<void> Function(
    dynamic error, StackTrace stack);

/// An [Error] which can be thrown by a retry [Stream].
class RetryError extends Error {
  /// Message describing the retry error.
  final String message;

  /// A [List] of errors that where thrown while attempting to retry.
  final List<ErrorAndStackTrace> errors;

  RetryError._(this.message, this.errors);

  /// Constructs a [RetryError], including the [errors] that were encountered
  /// during the [count] retry stages.
  factory RetryError.withCount(int count, List<ErrorAndStackTrace> errors) =>
      RetryError._('Received an error after attempting $count retries', errors);

  /// Constructs a [RetryError], including the [errors] that were encountered
  /// during the retry stage.
  factory RetryError.onReviveFailed(List<ErrorAndStackTrace> errors) =>
      RetryError._('Received an error after attempting to retry.', errors);

  @override
  String toString() => message;
}
