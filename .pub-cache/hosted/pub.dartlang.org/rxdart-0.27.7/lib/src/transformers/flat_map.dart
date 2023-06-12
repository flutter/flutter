import 'dart:async';
import 'dart:collection';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';
import 'package:rxdart/src/utils/subscription.dart';

class _FlatMapStreamSink<S, T> extends ForwardingSink<S, T> {
  final Stream<T> Function(S value) _mapper;
  final int? maxConcurrent;

  final List<StreamSubscription<T>> _subscriptions = <StreamSubscription<T>>[];
  final Queue<S> queue = DoubleLinkedQueue();
  bool _inputClosed = false;

  _FlatMapStreamSink(this._mapper, this.maxConcurrent);

  @override
  void onData(S data) {
    if (maxConcurrent != null && _subscriptions.length >= maxConcurrent!) {
      queue.addLast(data);
    } else {
      listenInner(data);
    }
  }

  void listenInner(S data) {
    final Stream<T> mappedStream;
    try {
      mappedStream = _mapper(data);
    } catch (e, s) {
      sink.addError(e, s);
      return;
    }

    final subscription = mappedStream.listen(sink.add, onError: sink.addError);
    subscription.onDone(() {
      _subscriptions.remove(subscription);

      if (queue.isNotEmpty) {
        listenInner(queue.removeFirst());
      } else if (_inputClosed && _subscriptions.isEmpty) {
        sink.close();
      }
    });
    _subscriptions.add(subscription);
  }

  @override
  void onError(Object e, StackTrace st) => sink.addError(e, st);

  @override
  void onDone() {
    _inputClosed = true;

    if (_subscriptions.isEmpty) {
      sink.close();
    }
  }

  @override
  Future<void>? onCancel() {
    queue.clear();
    return _subscriptions.cancelAll();
  }

  @override
  void onListen() {}

  @override
  void onPause() => _subscriptions.pauseAll();

  @override
  void onResume() => _subscriptions.resumeAll();
}

/// Converts each emitted item into a new Stream using the given mapper function,
/// while limiting the maximum number of concurrent subscriptions to these [Stream]s.
/// The newly created Stream will be listened to and begin emitting items downstream.
///
/// The items emitted by each of the new Streams are emitted downstream in the
/// same order they arrive. In other words, the sequences are merged
/// together.
///
/// ### Example
///
///       Stream.fromIterable([4, 3, 2, 1])
///         .transform(FlatMapStreamTransformer((i) =>
///           Stream.fromFuture(
///             Future.delayed(Duration(minutes: i), () => i))
///         .listen(print); // prints 1, 2, 3, 4
class FlatMapStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  /// Method which converts incoming events into a new [Stream]
  final Stream<T> Function(S value) mapper;

  /// Maximum number of inner [Stream] that may be listened to concurrently.
  /// If it's `null`, it means unlimited.
  final int? maxConcurrent;

  /// Constructs a [StreamTransformer] which emits events from the source [Stream] using the given [mapper].
  /// The mapped [Stream] will be listened to and begin emitting items downstream.
  FlatMapStreamTransformer(this.mapper, {this.maxConcurrent});

  @override
  Stream<T> bind(Stream<S> stream) =>
      forwardStream(stream, () => _FlatMapStreamSink(mapper, maxConcurrent));
}

/// Extends the Stream class with the ability to convert the source Stream into
/// a new Stream each time the source emits an item.
extension FlatMapExtension<T> on Stream<T> {
  /// Converts each emitted item into a Stream using the given mapper function,
  /// while limiting the maximum number of concurrent subscriptions to these [Stream]s.
  /// The newly created Stream will be be listened to and begin emitting items downstream.
  ///
  /// The items emitted by each of the Streams are emitted downstream in the
  /// same order they arrive. In other words, the sequences are merged
  /// together.
  ///
  /// ### Example
  ///
  ///     RangeStream(4, 1)
  ///       .flatMap((i) => TimerStream(i, Duration(minutes: i)))
  ///       .listen(print); // prints 1, 2, 3, 4
  Stream<S> flatMap<S>(Stream<S> Function(T value) mapper,
          {int? maxConcurrent}) =>
      FlatMapStreamTransformer<T, S>(mapper, maxConcurrent: maxConcurrent)
          .bind(this);

  /// Converts each item into a Stream. The Stream must return an
  /// Iterable. Then, each item from the Iterable will be emitted one by one.
  ///
  /// Use case: you may have an API that returns a list of items, such as
  /// a Stream<List<String>>. However, you might want to operate on the individual items
  /// rather than the list itself. This is the job of `flatMapIterable`.
  ///
  /// ### Example
  ///
  ///     RangeStream(1, 4)
  ///       .flatMapIterable((i) => Stream.fromIterable([[i]]))
  ///       .listen(print); // prints 1, 2, 3, 4
  Stream<S> flatMapIterable<S>(Stream<Iterable<S>> Function(T value) mapper,
          {int? maxConcurrent}) =>
      FlatMapStreamTransformer<T, Iterable<S>>(mapper,
              maxConcurrent: maxConcurrent)
          .bind(this)
          .expand((Iterable<S> iterable) => iterable);
}
