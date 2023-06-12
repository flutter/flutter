import 'dart:async';

import 'package:rxdart/src/streams/concat.dart';

/// Concatenates all of the specified stream sequences, as long as the
/// previous stream sequence terminated successfully.
///
/// In the case of concatEager, rather than subscribing to one stream after
/// the next, all streams are immediately subscribed to. The events are then
/// captured and emitted at the correct time, after the previous stream has
/// finished emitting items.
///
/// If the provided streams is empty, the resulting sequence completes immediately
/// without emitting any items.
///
/// [Interactive marble diagram](http://rxmarbles.com/#concat)
///
/// ### Example
///
///     ConcatEagerStream([
///       Stream.fromIterable([1]),
///       TimerStream(2, Duration(days: 1)),
///       Stream.fromIterable([3])
///     ])
///     .listen(print); // prints 1, 2, 3
class ConcatEagerStream<T> extends Stream<T> {
  final StreamController<T> _controller;

  /// Constructs a [Stream] which emits all events from [streams].
  /// Unlike [ConcatStream], all [Stream]s inside [streams] are
  /// immediately subscribed to and events captured at the correct time,
  /// but emitted only after the previous [Stream] in [streams] is
  /// successfully closed.
  ConcatEagerStream(Iterable<Stream<T>> streams)
      : _controller = _buildController(streams);

  @override
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

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
    final completeEvents = List.generate(len, (_) => Completer<dynamic>());
    List<StreamSubscription<T>> subscriptions;
    StreamController<T> controller;
    //ignore: cancel_subscriptions
    StreamSubscription<T> activeSubscription;

    controller = StreamController<T>(
        sync: true,
        onListen: () {
          var index = -1, completed = 0;

          final onDone = (int index) {
            final completer = completeEvents[index];

            return () {
              completer.complete();

              if (++completed == len) {
                controller.close();
              } else {
                activeSubscription = subscriptions[index + 1];
              }
            };
          };

          final createSubscription = (Stream<T> stream) {
            index++;
            //ignore: cancel_subscriptions
            final subscription = stream.listen(controller.add,
                onError: controller.addError, onDone: onDone(index));

            // pause all subscriptions, except the first, initially
            if (index > 0) subscription.pause(completeEvents[index - 1].future);

            return subscription;
          };

          subscriptions =
              streams.map(createSubscription).toList(growable: false);

          // initially, the very first subscription is the active one
          activeSubscription = subscriptions.first;
        },
        onPause: () => activeSubscription.pause(),
        onResume: () => activeSubscription.resume(),
        onCancel: () => Future.wait<dynamic>(subscriptions
            .map((subscription) => subscription.cancel())
            .where((cancelFuture) => cancelFuture != null)));

    return controller;
  }
}
