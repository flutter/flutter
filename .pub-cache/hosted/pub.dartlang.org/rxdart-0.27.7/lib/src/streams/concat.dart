import 'dart:async';

/// Concatenates all of the specified stream sequences, as long as the
/// previous stream sequence terminated successfully.
///
/// It does this by subscribing to each stream one by one, emitting all items
/// and completing before subscribing to the next stream.
///
/// If the provided streams is empty, the resulting sequence completes immediately
/// without emitting any items.
///
/// [Interactive marble diagram](http://rxmarbles.com/#concat)
///
/// ### Example
///
///     ConcatStream([
///       Stream.fromIterable([1]),
///       TimerStream(2, Duration(days: 1)),
///       Stream.fromIterable([3])
///     ])
///     .listen(print); // prints 1, 2, 3
class ConcatStream<T> extends StreamView<T> {
  /// Constructs a [Stream] which emits all events from [streams].
  /// The [Iterable] is traversed upwards, meaning that the current first
  /// [Stream] in the [Iterable] needs to complete, before events from the
  /// next [Stream] will be subscribed to.
  ConcatStream(Iterable<Stream<T>> streams)
      : super(_buildController(streams).stream);

  static StreamController<T> _buildController<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>(sync: true);
    StreamSubscription<T>? subscription;

    controller.onListen = () {
      final iterator = streams.iterator;

      void moveNext() {
        if (!iterator.moveNext()) {
          controller.close();
          return;
        }
        subscription?.cancel();
        subscription = iterator.current.listen(controller.add,
            onError: controller.addError, onDone: moveNext);
      }

      moveNext();
    };
    controller.onPause = () => subscription?.pause();
    controller.onResume = () => subscription?.resume();
    controller.onCancel = () => subscription?.cancel();

    return controller;
  }
}

/// Extends the Stream class with the ability to concatenate one stream with
/// another.
extension ConcatExtensions<T> on Stream<T> {
  /// Returns a Stream that emits all items from the current Stream,
  /// then emits all items from the given streams, one after the next.
  ///
  /// ### Example
  ///
  ///     TimerStream(1, Duration(seconds: 10))
  ///         .concatWith([Stream.fromIterable([2])])
  ///         .listen(print); // prints 1, 2
  Stream<T> concatWith(Iterable<Stream<T>> other) {
    final concatStream = ConcatStream<T>([this, ...other]);

    return isBroadcast
        ? concatStream.asBroadcastStream(onCancel: (s) => s.cancel())
        : concatStream;
  }
}
