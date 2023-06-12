import 'dart:async';

import 'package:rxdart/src/rx.dart';
import 'package:rxdart/src/streams/value_stream.dart';
import 'package:rxdart/src/subjects/subject.dart';
import 'package:rxdart/src/transformers/start_with.dart';
import 'package:rxdart/src/transformers/start_with_error.dart';
import 'package:rxdart/src/utils/empty.dart';
import 'package:rxdart/src/utils/error_and_stacktrace.dart';

/// A special StreamController that captures the latest item that has been
/// added to the controller, and emits that as the first item to any new
/// listener.
///
/// This subject allows sending data, error and done events to the listener.
/// The latest item that has been added to the subject will be sent to any
/// new listeners of the subject. After that, any new events will be
/// appropriately sent to the listeners. It is possible to provide a seed value
/// that will be emitted if no items have been added to the subject.
///
/// BehaviorSubject is, by default, a broadcast (aka hot) controller, in order
/// to fulfill the Rx Subject contract. This means the Subject's `stream` can
/// be listened to multiple times.
///
/// ### Example
///
///     final subject = BehaviorSubject<int>();
///
///     subject.add(1);
///     subject.add(2);
///     subject.add(3);
///
///     subject.stream.listen(print); // prints 3
///     subject.stream.listen(print); // prints 3
///     subject.stream.listen(print); // prints 3
///
/// ### Example with seed value
///
///     final subject = BehaviorSubject<int>.seeded(1);
///
///     subject.stream.listen(print); // prints 1
///     subject.stream.listen(print); // prints 1
///     subject.stream.listen(print); // prints 1
class BehaviorSubject<T> extends Subject<T> implements ValueStream<T> {
  final _Wrapper<T> _wrapper;

  BehaviorSubject._(
    StreamController<T> controller,
    Stream<T> stream,
    this._wrapper,
  ) : super(controller, stream);

  /// Constructs a [BehaviorSubject], optionally pass handlers for
  /// [onListen], [onCancel] and a flag to handle events [sync].
  ///
  /// See also [StreamController.broadcast]
  factory BehaviorSubject({
    void Function()? onListen,
    void Function()? onCancel,
    bool sync = false,
  }) {
    // ignore: close_sinks
    final controller = StreamController<T>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    final wrapper = _Wrapper<T>();

    return BehaviorSubject<T>._(
        controller,
        Rx.defer<T>(_deferStream(wrapper, controller, sync), reusable: true),
        wrapper);
  }

  /// Constructs a [BehaviorSubject], optionally pass handlers for
  /// [onListen], [onCancel] and a flag to handle events [sync].
  ///
  /// [seedValue] becomes the current [value] and is emitted immediately.
  ///
  /// See also [StreamController.broadcast]
  factory BehaviorSubject.seeded(
    T seedValue, {
    void Function()? onListen,
    void Function()? onCancel,
    bool sync = false,
  }) {
    // ignore: close_sinks
    final controller = StreamController<T>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    final wrapper = _Wrapper<T>.seeded(seedValue);

    return BehaviorSubject<T>._(
      controller,
      Rx.defer<T>(_deferStream(wrapper, controller, sync), reusable: true),
      wrapper,
    );
  }

  static Stream<T> Function() _deferStream<T>(
          _Wrapper<T> wrapper, StreamController<T> controller, bool sync) =>
      () {
        final errorAndStackTrace = wrapper.errorAndStackTrace;
        if (errorAndStackTrace != null && !wrapper.isValue) {
          return controller.stream.transform(
            StartWithErrorStreamTransformer(
              errorAndStackTrace.error,
              errorAndStackTrace.stackTrace,
            ),
          );
        }

        final value = wrapper.value;
        if (isNotEmpty(value) && wrapper.isValue) {
          return controller.stream
              .transform(StartWithStreamTransformer(value as T));
        }

        return controller.stream;
      };

  @override
  void onAdd(T event) => _wrapper.setValue(event);

  @override
  void onAddError(Object error, [StackTrace? stackTrace]) =>
      _wrapper.setError(error, stackTrace);

  @override
  ValueStream<T> get stream => this;

  @override
  bool get hasValue => isNotEmpty(_wrapper.value);

  @override
  T get value {
    final value = _wrapper.value;
    if (isNotEmpty(value)) {
      return value as T;
    }
    throw ValueStreamError.hasNoValue();
  }

  @override
  T? get valueOrNull => unbox(_wrapper.value);

  /// Set and emit the new value.
  set value(T newValue) => add(newValue);

  @override
  bool get hasError => _wrapper.errorAndStackTrace != null;

  @override
  Object? get errorOrNull => _wrapper.errorAndStackTrace?.error;

  @override
  Object get error {
    final errorAndSt = _wrapper.errorAndStackTrace;
    if (errorAndSt != null) {
      return errorAndSt.error;
    }
    throw ValueStreamError.hasNoError();
  }

  @override
  StackTrace? get stackTrace => _wrapper.errorAndStackTrace?.stackTrace;
}

class _Wrapper<T> {
  bool isValue;
  var value = EMPTY;
  ErrorAndStackTrace? errorAndStackTrace;

  /// Non-seeded constructor
  _Wrapper() : isValue = false;

  _Wrapper.seeded(this.value) : isValue = true;

  void setValue(T event) {
    value = event;
    isValue = true;
  }

  void setError(Object error, StackTrace? stackTrace) {
    errorAndStackTrace = ErrorAndStackTrace(error, stackTrace);
    isValue = false;
  }
}
