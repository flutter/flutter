import 'dart:async';

/// Flattens the items emitted by the given streams into a single Stream
/// sequence.
///
/// If the provided streams is empty, the resulting sequence completes immediately
/// without emitting any items.
///
/// [Interactive marble diagram](http://rxmarbles.com/#merge)
///
/// ### Example
///
///     MergeStream([
///       TimerStream(1, Duration(days: 10)),
///       Stream.fromIterable([2])
///     ])
///     .listen(print); // prints 2, 1
class MergeStream<T> extends Stream<T> {
  final StreamController<T> _controller;

  /// Constructs a [Stream] which flattens all events in [streams] and emits
  /// them in a single sequence.
  MergeStream(Iterable<Stream<T>> streams)
      : _controller = _buildController(streams);

  @override
  StreamSubscription<T> listen(void Function(T event) onData,
          {Function onError, void Function() onDone, bool cancelOnError}) =>
      _controller.stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  static StreamController<T> _buildController<T>(Iterable<Stream<T>> streams) {
    if (streams == null) {
      throw ArgumentError('streams cannot be null');
    }
    if (streams.isEmpty) {
      return StreamController<T>()..close();
    }
    if (streams.any((Stream<T> stream) => stream == null)) {
      throw ArgumentError('One of the provided streams is null');
    }

    final len = streams.length;
    final subscriptions = List<StreamSubscription<T>>(len);
    StreamController<T> controller;

    controller = StreamController<T>(
        sync: true,
        onListen: () {
          var completed = 0;

          final onDone = () {
            completed++;

            if (completed == len) controller.close();
          };

          for (var i = 0; i < len; i++) {
            var stream = streams.elementAt(i);

            subscriptions[i] = stream.listen(controller.add,
                onError: controller.addError, onDone: onDone);
          }
        },
        onPause: () =>
            subscriptions.forEach((subscription) => subscription.pause()),
        onResume: () =>
            subscriptions.forEach((subscription) => subscription.resume()),
        onCancel: () => Future.wait<dynamic>(subscriptions
            .map((subscription) => subscription.cancel())
            .where((cancelFuture) => cancelFuture != null)));

    return controller;
  }
}

/// Extends the Stream class with the ability to merge one stream with another.
extension MergeExtension<T> on Stream<T> {
  /// Combines the items emitted by multiple streams into a single stream of
  /// items. The items are emitted in the order they are emitted by their
  /// sources.
  ///
  /// ### Example
  ///
  ///     TimerStream(1, Duration(seconds: 10))
  ///         .mergeWith([Stream.fromIterable([2])])
  ///         .listen(print); // prints 2, 1
  Stream<T> mergeWith(Iterable<Stream<T>> streams) {
    final stream = MergeStream<T>([this, ...streams]);

    return isBroadcast
        ? stream.asBroadcastStream(onCancel: (s) => s.cancel())
        : stream;
  }
}
