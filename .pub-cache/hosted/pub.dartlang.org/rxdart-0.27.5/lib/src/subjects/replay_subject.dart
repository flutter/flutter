import 'dart:async';
import 'dart:collection';

import 'package:rxdart/src/rx.dart';
import 'package:rxdart/src/streams/replay_stream.dart';
import 'package:rxdart/src/subjects/subject.dart';
import 'package:rxdart/src/transformers/start_with.dart';
import 'package:rxdart/src/transformers/start_with_error.dart';
import 'package:rxdart/src/utils/collection_extensions.dart';
import 'package:rxdart/src/utils/empty.dart';
import 'package:rxdart/src/utils/error_and_stacktrace.dart';

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
  final int? _maxSize;

  /// Constructs a [ReplaySubject], optionally pass handlers for
  /// [onListen], [onCancel] and a flag to handle events [sync].
  ///
  /// See also [StreamController.broadcast]
  factory ReplaySubject({
    int? maxSize,
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

    final queue = Queue<_Event<T>>();

    return ReplaySubject<T>._(
      controller,
      Rx.defer<T>(
        () => queue.toList(growable: false).reversed.fold(
          controller.stream,
          (stream, event) {
            final errorAndStackTrace = event.errorAndStackTrace;

            if (errorAndStackTrace != null) {
              return stream.transform(
                StartWithErrorStreamTransformer(
                  errorAndStackTrace.error,
                  errorAndStackTrace.stackTrace,
                ),
              );
            } else {
              return stream
                  .transform(StartWithStreamTransformer(event.data as T));
            }
          },
        ),
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
  void onAddError(Object error, [StackTrace? stackTrace]) {
    if (_queue.length == _maxSize) {
      _queue.removeFirst();
    }

    _queue.add(_Event.error(ErrorAndStackTrace(error, stackTrace)));
  }

  @override
  List<T> get values => _queue
      .where((event) => event.errorAndStackTrace == null)
      .map((event) => event.data as T)
      .toList(growable: false);

  @override
  List<Object> get errors => _queue
      .mapNotNull((event) => event.errorAndStackTrace?.error)
      .toList(growable: false);

  @override
  List<StackTrace?> get stackTraces => _queue
      .where((event) => event.errorAndStackTrace != null)
      .map((event) => event.errorAndStackTrace!.stackTrace)
      .toList(growable: false);
}

class _Event<T> {
  final Object? data;
  final ErrorAndStackTrace? errorAndStackTrace;

  _Event._({required this.data, required this.errorAndStackTrace});

  factory _Event.data(T data) => _Event._(data: data, errorAndStackTrace: null);

  factory _Event.error(ErrorAndStackTrace e) =>
      _Event._(errorAndStackTrace: e, data: EMPTY);
}
