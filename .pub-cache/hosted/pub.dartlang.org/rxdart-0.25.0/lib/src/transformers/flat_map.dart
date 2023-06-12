import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _FlatMapStreamSink<S, T> implements ForwardingSink<S, T> {
  final Stream<T> Function(S value) _mapper;
  final List<StreamSubscription<T>> _subscriptions = <StreamSubscription<T>>[];
  int _openSubscriptions = 0;
  bool _inputClosed = false;

  _FlatMapStreamSink(this._mapper);

  @override
  void add(EventSink<T> sink, S data) {
    final mappedStream = _mapper(data);

    _openSubscriptions++;

    StreamSubscription<T> subscription;

    subscription = mappedStream.listen(
      sink.add,
      onError: sink.addError,
      onDone: () {
        _openSubscriptions--;
        _subscriptions.remove(subscription);

        if (_inputClosed && _openSubscriptions == 0) {
          sink.close();
        }
      },
    );

    _subscriptions.add(subscription);
  }

  @override
  void addError(EventSink<T> sink, dynamic e, [st]) => sink.addError(e, st);

  @override
  void close(EventSink<T> sink) {
    _inputClosed = true;

    if (_openSubscriptions == 0) {
      sink.close();
    }
  }

  @override
  FutureOr onCancel(EventSink<T> sink) =>
      Future.wait<dynamic>(_subscriptions.map((s) => s.cancel()));

  @override
  void onListen(EventSink<T> sink) {}

  @override
  void onPause(EventSink<T> sink) => _subscriptions.forEach((s) => s.pause());

  @override
  void onResume(EventSink<T> sink) => _subscriptions.forEach((s) => s.resume());
}

/// Converts each emitted item into a new Stream using the given mapper
/// function. The newly created Stream will be listened to and begin
/// emitting items downstream.
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

  /// Constructs a [StreamTransformer] which emits events from the source [Stream] using the given [mapper].
  /// The mapped [Stream] will be listened to and begin emitting items downstream.
  FlatMapStreamTransformer(this.mapper);

  @override
  Stream<T> bind(Stream<S> stream) =>
      forwardStream(stream, _FlatMapStreamSink(mapper));
}

/// Extends the Stream class with the ability to convert the source Stream into
/// a new Stream each time the source emits an item.
extension FlatMapExtension<T> on Stream<T> {
  /// Converts each emitted item into a Stream using the given mapper
  /// function. The newly created Stream will be be listened to and begin
  /// emitting items downstream.
  ///
  /// The items emitted by each of the Streams are emitted downstream in the
  /// same order they arrive. In other words, the sequences are merged
  /// together.
  ///
  /// ### Example
  ///
  ///     RangeStream(4, 1)
  ///       .flatMap((i) => TimerStream(i, Duration(minutes: i))
  ///       .listen(print); // prints 1, 2, 3, 4
  Stream<S> flatMap<S>(Stream<S> Function(T value) mapper) =>
      transform(FlatMapStreamTransformer<T, S>(mapper));

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
  ///       .flatMapIterable((i) => Stream.fromIterable([[i]])
  ///       .listen(print); // prints 1, 2, 3, 4
  Stream<S> flatMapIterable<S>(Stream<Iterable<S>> Function(T value) mapper) =>
      transform(FlatMapStreamTransformer<T, Iterable<S>>(mapper))
          .expand((Iterable<S> iterable) => iterable);
}
