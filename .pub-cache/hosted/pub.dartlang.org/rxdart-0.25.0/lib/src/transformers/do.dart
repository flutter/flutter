import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';
import 'package:rxdart/src/utils/notification.dart';

class _DoStreamSink<S> implements ForwardingSink<S, S> {
  final dynamic Function() _onCancel;
  final void Function(S event) _onData;
  final void Function() _onDone;
  final void Function(Notification<S> notification) _onEach;
  final void Function(Object, StackTrace) _onError;
  final void Function() _onListen;
  final void Function() _onPause;
  final void Function() _onResume;

  _DoStreamSink(
    this._onCancel,
    this._onData,
    this._onDone,
    this._onEach,
    this._onError,
    this._onListen,
    this._onPause,
    this._onResume,
  );

  @override
  void add(EventSink<S> sink, S data) {
    try {
      _onData?.call(data);
    } catch (e, s) {
      sink.addError(e, s);
    }
    try {
      _onEach?.call(Notification.onData(data));
    } catch (e, s) {
      sink.addError(e, s);
    }
    sink.add(data);
  }

  @override
  void addError(EventSink<S> sink, dynamic e, [st]) {
    try {
      _onError?.call(e, st);
    } catch (e, s) {
      sink.addError(e, s);
    }
    try {
      _onEach?.call(Notification.onError(e, st));
    } catch (e, s) {
      sink.addError(e, s);
    }
    sink.addError(e, st);
  }

  @override
  void close(EventSink<S> sink) {
    try {
      _onDone?.call();
    } catch (e, s) {
      sink.addError(e, s);
    }
    try {
      _onEach?.call(Notification.onDone());
    } catch (e, s) {
      sink.addError(e, s);
    }
    sink.close();
  }

  @override
  FutureOr onCancel(EventSink<S> sink) => _onCancel?.call();

  @override
  void onListen(EventSink<S> sink) {
    _onListen?.call();
  }

  @override
  void onPause(EventSink<S> sink) => _onPause?.call();

  @override
  void onResume(EventSink<S> sink) => _onResume?.call();
}

/// Invokes the given callback at the corresponding point the the stream
/// lifecycle. For example, if you pass in an onDone callback, it will
/// be invoked when the stream finishes emitting items.
///
/// This transformer can be used for debugging, logging, etc. by intercepting
/// the stream at different points to run arbitrary actions.
///
/// It is possible to hook onto the following parts of the stream lifecycle:
///
///   - onCancel
///   - onData
///   - onDone
///   - onError
///   - onListen
///   - onPause
///   - onResume
///
/// In addition, the `onEach` argument is called at `onData`, `onDone`, and
/// `onError` with a [Notification] passed in. The [Notification] argument
/// contains the [Kind] of event (OnData, OnDone, OnError), and the item or
/// error that was emitted. In the case of onDone, no data is emitted as part
/// of the [Notification].
///
/// If no callbacks are passed in, a runtime error will be thrown in dev mode
/// in order to 'fail fast' and alert the developer that the transformer should
/// be used or safely removed.
///
/// ### Example
///
///     Stream.fromIterable([1])
///         .transform(DoStreamTransformer(
///           onData: print,
///           onError: (e, s) => print('Oh no!'),
///           onDone: () => print('Done')))
///         .listen(null); // Prints: 1, 'Done'
class DoStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// fires when all subscriptions have cancelled.
  final dynamic Function() onCancel;

  /// fires when data is emitted
  final void Function(S event) onData;

  /// fires on close
  final void Function() onDone;

  /// fires on data, close and error
  final void Function(Notification<S> notification) onEach;

  /// fires on errors
  final void Function(Object, StackTrace) onError;

  /// fires when a subscription first starts
  final void Function() onListen;

  /// fires when the subscription pauses
  final void Function() onPause;

  /// fires when the subscription resumes
  final void Function() onResume;

  /// Constructs a [StreamTransformer] which will trigger any of the provided
  /// handlers as they occur.
  DoStreamTransformer(
      {this.onCancel,
      this.onData,
      this.onDone,
      this.onEach,
      this.onError,
      this.onListen,
      this.onPause,
      this.onResume}) {
    if (onCancel == null &&
        onData == null &&
        onDone == null &&
        onEach == null &&
        onError == null &&
        onListen == null &&
        onPause == null &&
        onResume == null) {
      throw ArgumentError('Must provide at least one handler');
    }
  }

  @override
  Stream<S> bind(Stream<S> stream) => forwardStream<S, S>(
        stream,
        _DoStreamSink<S>(
          onCancel,
          onData,
          onDone,
          onEach,
          onError,
          onListen,
          onPause,
          onResume,
        ),
      );
}

/// Extends the Stream class with the ability to execute a callback function
/// at different points in the Stream's lifecycle.
extension DoExtensions<T> on Stream<T> {
  /// Invokes the given callback function when the stream subscription is
  /// cancelled. Often called doOnUnsubscribe or doOnDispose in other
  /// implementations.
  ///
  /// ### Example
  ///
  ///     final subscription = TimerStream(1, Duration(minutes: 1))
  ///       .doOnCancel(() => print('hi'));
  ///       .listen(null);
  ///
  ///     subscription.cancel(); // prints 'hi'
  Stream<T> doOnCancel(void Function() onCancel) =>
      transform(DoStreamTransformer<T>(onCancel: onCancel));

  /// Invokes the given callback function when the stream emits an item. In
  /// other implementations, this is called doOnNext.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3])
  ///       .doOnData(print)
  ///       .listen(null); // prints 1, 2, 3
  Stream<T> doOnData(void Function(T event) onData) =>
      transform(DoStreamTransformer<T>(onData: onData));

  /// Invokes the given callback function when the stream finishes emitting
  /// items. In other implementations, this is called doOnComplete(d).
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3])
  ///       .doOnDone(() => print('all set'))
  ///       .listen(null); // prints 'all set'
  Stream<T> doOnDone(void Function() onDone) =>
      transform(DoStreamTransformer<T>(onDone: onDone));

  /// Invokes the given callback function when the stream emits data, emits
  /// an error, or emits done. The callback receives a [Notification] object.
  ///
  /// The [Notification] object contains the [Kind] of event (OnData, onDone,
  /// or OnError), and the item or error that was emitted. In the case of
  /// onDone, no data is emitted as part of the [Notification].
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1])
  ///       .doOnEach(print)
  ///       .listen(null); // prints Notification{kind: OnData, value: 1, errorAndStackTrace: null}, Notification{kind: OnDone, value: null, errorAndStackTrace: null}
  Stream<T> doOnEach(void Function(Notification<T> notification) onEach) =>
      transform(DoStreamTransformer<T>(onEach: onEach));

  /// Invokes the given callback function when the stream emits an error.
  ///
  /// ### Example
  ///
  ///     Stream.error(Exception())
  ///       .doOnError((error, stacktrace) => print('oh no'))
  ///       .listen(null); // prints 'Oh no'
  Stream<T> doOnError(void Function(Object, StackTrace) onError) =>
      transform(DoStreamTransformer<T>(onError: onError));

  /// Invokes the given callback function when the stream is first listened to.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1])
  ///       .doOnListen(() => print('Is someone there?'))
  ///       .listen(null); // prints 'Is someone there?'
  Stream<T> doOnListen(void Function() onListen) =>
      transform(DoStreamTransformer<T>(onListen: onListen));

  /// Invokes the given callback function when the stream subscription is
  /// paused.
  ///
  /// ### Example
  ///
  ///     final subscription = Stream.fromIterable([1])
  ///       .doOnPause(() => print('Gimme a minute please'))
  ///       .listen(null);
  ///
  ///     subscription.pause(); // prints 'Gimme a minute please'
  Stream<T> doOnPause(void Function() onPause) =>
      transform(DoStreamTransformer<T>(onPause: onPause));

  /// Invokes the given callback function when the stream subscription
  /// resumes receiving items.
  ///
  /// ### Example
  ///
  ///     final subscription = Stream.fromIterable([1])
  ///       .doOnResume(() => print('Let's do this!'))
  ///       .listen(null);
  ///
  ///     subscription.pause();
  ///     subscription.resume(); 'Let's do this!'
  Stream<T> doOnResume(void Function() onResume) =>
      transform(DoStreamTransformer<T>(onResume: onResume));
}
