import 'dart:async';

import 'package:rxdart/src/rx.dart';
import 'package:rxdart/src/streams/value_stream.dart';
import 'package:rxdart/src/subjects/subject.dart';
import 'package:rxdart/src/transformers/start_with.dart';
import 'package:rxdart/src/transformers/start_with_error.dart';
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
  final Stream<T> _stream;

  BehaviorSubject._(
    StreamController<T> controller,
    this._stream,
    this._wrapper,
  ) : super(controller, _stream);

  /// Constructs a [BehaviorSubject], optionally pass handlers for
  /// [onListen], [onCancel] and a flag to handle events [sync].
  ///
  /// See also [StreamController.broadcast]
  factory BehaviorSubject({
    void Function() onListen,
    void Function() onCancel,
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
    void Function() onListen,
    void Function() onCancel,
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
        if (wrapper.latestIsError) {
          final errorAndStackTrace = wrapper.latestErrorAndStackTrace;

          return controller.stream.transform(
            StartWithErrorStreamTransformer(
              errorAndStackTrace.error,
              errorAndStackTrace.stackTrace,
            ),
          );
        } else if (wrapper.latestIsValue) {
          return controller.stream
              .transform(StartWithStreamTransformer(wrapper.latestValue));
        }

        return controller.stream;
      };

  @override
  void onAdd(T event) => _wrapper.setValue(event);

  @override
  void onAddError(Object error, [StackTrace stackTrace]) =>
      _wrapper.setError(error, stackTrace);

  @override
  ValueStream<T> get stream => this;

  @override
  bool get hasValue => _wrapper.latestIsValue;

  /// Get the latest value emitted by the Subject
  @override
  T get value => _wrapper.latestValue;

  /// Set and emit the new value
  set value(T newValue) => add(newValue);

  @override
  bool get hasError => _wrapper.latestIsError;

  @override
  ErrorAndStackTrace get errorAndStackTrace =>
      _wrapper.latestErrorAndStackTrace;

  @override
  BehaviorSubject<R> createForwardingSubject<R>({
    void Function() onListen,
    void Function() onCancel,
    bool sync = false,
  }) =>
      BehaviorSubject(
        onListen: onListen,
        onCancel: onCancel,
        sync: sync,
      );

  // Override built-in operators.

  @override
  ValueStream<T> where(bool Function(T event) test) =>
      _forwardBehaviorSubject<T>((s) => s.where(test));

  @override
  ValueStream<S> map<S>(S Function(T event) convert) =>
      _forwardBehaviorSubject<S>((s) => s.map(convert));

  @override
  ValueStream<E> asyncMap<E>(FutureOr<E> Function(T event) convert) =>
      _forwardBehaviorSubject<E>((s) => s.asyncMap(convert));

  @override
  ValueStream<E> asyncExpand<E>(Stream<E> Function(T event) convert) =>
      _forwardBehaviorSubject<E>((s) => s.asyncExpand(convert));

  @override
  ValueStream<T> handleError(Function onError,
          {bool Function(Object error) test}) =>
      _forwardBehaviorSubject<T>((s) => s.handleError(onError, test: test));

  @override
  ValueStream<S> expand<S>(Iterable<S> Function(T element) convert) =>
      _forwardBehaviorSubject<S>((s) => s.expand(convert));

  @override
  ValueStream<S> transform<S>(StreamTransformer<T, S> streamTransformer) =>
      _forwardBehaviorSubject<S>((s) => s.transform(streamTransformer));

  @override
  ValueStream<R> cast<R>() => _forwardBehaviorSubject<R>((s) => s.cast<R>());

  @override
  ValueStream<T> take(int count) =>
      _forwardBehaviorSubject<T>((s) => s.take(count));

  @override
  ValueStream<T> takeWhile(bool Function(T element) test) =>
      _forwardBehaviorSubject<T>((s) => s.takeWhile(test));

  @override
  ValueStream<T> skip(int count) =>
      _forwardBehaviorSubject<T>((s) => s.skip(count));

  @override
  ValueStream<T> skipWhile(bool Function(T element) test) =>
      _forwardBehaviorSubject<T>((s) => s.skipWhile(test));

  @override
  ValueStream<T> distinct([bool Function(T previous, T next) equals]) =>
      _forwardBehaviorSubject<T>((s) => s.distinct(equals));

  @override
  ValueStream<T> timeout(Duration timeLimit,
          {void Function(EventSink<T> sink) onTimeout}) =>
      _forwardBehaviorSubject<T>(
          (s) => s.timeout(timeLimit, onTimeout: onTimeout));

  ValueStream<R> _forwardBehaviorSubject<R>(
      Stream<R> Function(Stream<T> s) transformerStream) {
    ArgumentError.checkNotNull(transformerStream, 'transformerStream');

    BehaviorSubject<R> subject;
    StreamSubscription<R> subscription;

    final onListen = () => subscription = transformerStream(_stream).listen(
          subject.add,
          onError: subject.addError,
          onDone: subject.close,
        );

    final onCancel = () => subscription.cancel();

    return subject = createForwardingSubject(
      onListen: onListen,
      onCancel: onCancel,
      sync: true,
    );
  }
}

class _Wrapper<T> {
  T latestValue;
  ErrorAndStackTrace latestErrorAndStackTrace;

  bool latestIsValue = false, latestIsError = false;

  /// Non-seeded constructor
  _Wrapper();

  _Wrapper.seeded(this.latestValue) : latestIsValue = true;

  void setValue(T event) {
    latestIsValue = true;
    latestIsError = false;

    latestValue = event;

    latestErrorAndStackTrace = null;
  }

  void setError(Object error, [StackTrace stackTrace]) {
    latestIsValue = false;
    latestIsError = true;

    latestValue = null;

    latestErrorAndStackTrace = ErrorAndStackTrace(error, stackTrace);
  }
}
