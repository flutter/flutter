import 'package:rxdart/rxdart.dart';

/// The type of event used in [Notification]
enum Kind {
  /// Specifies an onData event
  OnData,

  /// Specifies an onDone event
  OnDone,

  /// Specifies an error event
  OnError
}

/// A class that encapsulates the [Kind] of event, value of the event in case of
/// onData, or the Error in the case of onError.

/// A container object that wraps the [Kind] of event (OnData, OnDone, OnError),
/// and the item or error that was emitted. In the case of onDone, no data is
/// emitted as part of the [Notification].
class Notification<T> {
  /// References the [Kind] of this [Notification] event.
  final Kind kind;

  /// The wrapped value, if applicable
  final T value;

  /// The wrapped error and stack trace, if applicable
  final ErrorAndStackTrace errorAndStackTrace;

  /// Constructs a [Notification] which, depending on the [kind], wraps either
  /// [value], or [error] and [stackTrace], or neither if it is just a
  /// [Kind.OnData] event.
  const Notification._(this.kind, this.value, this.errorAndStackTrace);

  /// Constructs a [Notification] with [Kind.OnData] and wraps a [value]
  factory Notification.onData(T value) =>
      Notification<T>._(Kind.OnData, value, null);

  /// Constructs a [Notification] with [Kind.OnDone]
  factory Notification.onDone() =>
      const Notification._(Kind.OnDone, null, null);

  /// Constructs a [Notification] with [Kind.OnError] and wraps an [error] and [stackTrace]
  factory Notification.onError(Object error, StackTrace stackTrace) =>
      Notification<T>._(
        Kind.OnError,
        null,
        ErrorAndStackTrace(error, stackTrace),
      );

  @override
  String toString() =>
      'Notification{kind: $kind, value: $value, errorAndStackTrace: $errorAndStackTrace}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          value == other.value &&
          errorAndStackTrace == other.errorAndStackTrace;

  @override
  int get hashCode =>
      kind.hashCode ^ value.hashCode ^ errorAndStackTrace.hashCode;

  /// A test to determine if this [Notification] wraps an onData event
  bool get isOnData => kind == Kind.OnData;

  /// A test to determine if this [Notification] wraps an onDone event
  bool get isOnDone => kind == Kind.OnDone;

  /// A test to determine if this [Notification] wraps an error event
  bool get isOnError => kind == Kind.OnError;
}
