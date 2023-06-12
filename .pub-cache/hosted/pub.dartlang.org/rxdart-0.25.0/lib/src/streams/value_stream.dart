import 'package:rxdart/src/utils/error_and_stacktrace.dart';

/// An [Stream] that provides synchronous access to the last emitted item
abstract class ValueStream<T> implements Stream<T> {
  /// Last emitted value, or null if there has been no emission yet
  /// See [hasValue]
  T get value;

  /// A flag that turns true as soon as at least one event has been emitted.
  bool get hasValue;

  /// Last emitted error and the corresponding stack trace,
  /// or null if no error added or value exists.
  /// See [hasError]
  ErrorAndStackTrace get errorAndStackTrace;

  /// A flag that turns true as soon as at an error event has been emitted.
  bool get hasError;
}
