/// An [Stream] that provides synchronous access to the last emitted item
abstract class ValueStream<T> implements Stream<T> {
  /// Returns the last emitted value, failing if there is no value.
  /// See [hasValue] to determine whether [value] has already been set.
  ///
  /// Throws [ValueStreamError] if this Stream has no value.
  T get value;

  /// Returns either [value], or `null`, should [value] not yet have been set.
  T? get valueOrNull;

  /// Returns `true` when [value] is available.
  bool get hasValue;

  /// Returns last emitted error, failing if there is no error.
  ///
  /// Throws [ValueStreamError] if this Stream has no error.
  Object get error;

  /// Last emitted error, or `null` if no error added.
  Object? get errorOrNull;

  /// Returns `true` when [error] is available.
  bool get hasError;

  /// Returns [StackTrace] of the last emitted error,
  /// or `null` if no error added or the added error has no [StackTrace].
  StackTrace? get stackTrace;
}

enum _MissingCase {
  value,
  error,
}

/// The error throw by [ValueStream.value] or [ValueStream.error].
class ValueStreamError extends Error {
  final _MissingCase _missingCase;

  ValueStreamError._(this._missingCase);

  /// Construct an [ValueStreamError] thrown by [ValueStream.value] when there is no value.
  factory ValueStreamError.hasNoValue() =>
      ValueStreamError._(_MissingCase.value);

  /// Construct an [ValueStreamError] thrown by [ValueStream.error] when there is no error.
  factory ValueStreamError.hasNoError() =>
      ValueStreamError._(_MissingCase.error);

  @override
  String toString() {
    switch (_missingCase) {
      case _MissingCase.value:
        return 'ValueStream has no value. You should check ValueStream.hasValue '
            'before accessing ValueStream.value, or use ValueStream.valueOrNull instead.';
      case _MissingCase.error:
        return 'ValueStream has no error. You should check ValueStream.hasError '
            'before accessing ValueStream.error, or use ValueStream.errorOrNull instead.';
    }
  }
}
