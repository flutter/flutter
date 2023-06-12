import 'dart:async';

import 'package:rxdart/src/streams/concat.dart';
import 'package:rxdart/src/utils/collection_extensions.dart';
import 'package:rxdart/src/utils/subscription.dart';

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
class ConcatEagerStream<T> extends StreamView<T> {
  /// Constructs a [Stream] which emits all events from [streams].
  /// Unlike [ConcatStream], all [Stream]s inside [streams] are
  /// immediately subscribed to and events captured at the correct time,
  /// but emitted only after the previous [Stream] in [streams] is
  /// successfully closed.
  ConcatEagerStream(Iterable<Stream<T>> streams)
      : super(_buildController(streams).stream);

  static StreamController<T> _buildController<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>(sync: true);
    late List<StreamSubscription<T>> subscriptions;
    StreamSubscription<T>? activeSubscription;

    controller.onListen = () {
      final completeEvents = <Completer<void>>[];

      void Function() onDone(int index) {
        return () {
          if (index < subscriptions.length - 1) {
            completeEvents[index].complete();
            activeSubscription = subscriptions[index + 1];
          } else if (index == subscriptions.length - 1) {
            controller.close();
          }
        };
      }

      StreamSubscription<T> createSubscription(int index, Stream<T> stream) {
        final subscription = stream.listen(controller.add,
            onError: controller.addError, onDone: onDone(index));

        // pause all subscriptions, except the first, initially
        if (index > 0) {
          final completer = Completer<void>.sync();
          completeEvents.add(completer);
          subscription.pause(completer.future);
        }

        return subscription;
      }

      subscriptions =
          streams.mapIndexed(createSubscription).toList(growable: false);
      if (subscriptions.isEmpty) {
        controller.close();
      } else {
        // initially, the very first subscription is the active one
        activeSubscription = subscriptions.first;
      }
    };
    controller.onPause = () => activeSubscription?.pause();
    controller.onResume = () => activeSubscription?.resume();
    controller.onCancel = () {
      activeSubscription = null;
      return subscriptions.cancelAll();
    };

    return controller;
  }
}
