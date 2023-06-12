import 'dart:async';
import 'dart:collection';

import 'package:rxdart/rxdart.dart';
import 'package:rxdart/src/rx.dart';
import 'package:rxdart/src/streams/replay_stream.dart';
import 'package:rxdart/src/subjects/subject.dart';
import 'package:rxdart/src/transformers/start_with_error.dart';

/// A special StreamController that captures all of the items that have been
/// added to the controller, and emits those as the first items to any new
/// listener.
///
/// This subject allows sending data, error and done events to the listener.
/// As items are added to the subject, the ReplaySubject will store them.
/// When the stream is listened to, those recorded items will be emitted to
/// the listener. After that, any new events will be appropriately sent to the
/// listeners. It is possible to cap the number of stored events by setting
/// a maxSize value.
///
/// ReplaySubject is, by default, a broadcast (aka hot) controller, in order
/// to fulfill the Rx Subject contract. This means the Subject's `stream` can
/// be listened to multiple times.
///
/// ### Example
///
///     final subject = ReplaySubject<int>();
///
///     subject.add(1);
///     subject.add(2);
///     subject.add(3);
///
///     subject.stream.listen(print); // prints 1, 2, 3
///     subject.stream.listen(print); // prints 1, 2, 3
///     subject.stream.listen(print); // prints 1, 2, 3
///
/// ### Example with maxSize
///
///     final subject = ReplaySubject<int>(maxSize: 2);
///
///     subject.add(1);
///     subject.add(2);
///     subject.add(3);
///
///     subject.stream.listen(print); // prints 2, 3
///     subject.stream.listen(print); // prints 2, 3
///     subject.stream.listen(print); // prints 2, 3
class ReplaySubject<T> extends Subject<T> implements ReplayStream<T> {
  final Queue<_Event<T>> _queue;
  final int _maxSize;

  /// Constructs a [ReplaySubject], optionally pass handlers for
  /// [onListen], [onCancel] and a flag to handle events [sync].
  ///
  /// See also [StreamController.broadcast]
  factory ReplaySubject({
    int maxSize,
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

    final queue = Queue<_Event<T>>();

    return ReplaySubject<T>._(
      controller,
      Rx.defer<T>(
        () => queue.toList(growable: false).reversed.fold(controller.stream,
            (stream, event) {
          if (event.isError) {
            final errorAndStackTrace = event.errorAndStackTrace;

            return stream.transform(
              StartWithErrorStreamTransformer(
                errorAndStackTrace.error,
                errorAndStackTrace.stackTrace,
              ),
            );
          } else {
            return stream.transform(StartWithStreamTransformer(event.data));
          }
        }),
        reusable: true,
      ),
      queue,
      maxSize,
    );
  }

  ReplaySubject._(
    StreamController<T> controller,
    Stream<T> stream,
    this._queue,
    this._maxSize,
  ) : super(controller, stream);

  @override
  void onAdd(T event) {
    if (_queue.length == _maxSize) {
      _queue.removeFirst();
    }

    _queue.add(_Event.data(event));
  }

  @override
  void onAddError(Object error, [StackTrace stackTrace]) {
    if (_queue.length == _maxSize) {
      _queue.removeFirst();
    }

    _queue.add(_Event<T>.error(ErrorAndStackTrace(error, stackTrace)));
  }

  @override
  List<T> get values => _queue
      .where((event) => !event.isError)
      .map((event) => event.data)
      .toList(growable: false);

  @override
  List<ErrorAndStackTrace> get errorAndStackTraces => _queue
      .where((event) => event.isError)
      .map((event) => event.errorAndStackTrace)
      .toList(growable: false);

  @override
  ReplaySubject<R> createForwardingSubject<R>({
    void Function() onListen,
    void Function() onCancel,
    bool sync = false,
  }) =>
      ReplaySubject(
        maxSize: _maxSize,
        onCancel: onCancel,
        onListen: onListen,
        sync: sync,
      );
}

class _Event<T> {
  final bool isError;
  final T data;
  final ErrorAndStackTrace errorAndStackTrace;

  _Event._({this.isError, this.data, this.errorAndStackTrace});

  factory _Event.data(T data) => _Event._(isError: false, data: data);

  factory _Event.error(ErrorAndStackTrace e) =>
      _Event._(isError: true, errorAndStackTrace: e);
}
