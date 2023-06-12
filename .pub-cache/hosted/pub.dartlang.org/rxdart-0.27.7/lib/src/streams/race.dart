import 'dart:async';

import 'package:rxdart/src/utils/collection_extensions.dart';
import 'package:rxdart/src/utils/subscription.dart';

/// Given two or more source streams, emit all of the items from only
/// the first of these streams to emit an item or notification.
///
/// If the provided streams is empty, the resulting sequence completes immediately
/// without emitting any items.
///
/// [Interactive marble diagram](http://rxmarbles.com/#race)
///
/// ### Example
///
///     RaceStream([
///       TimerStream(1, Duration(days: 1)),
///       TimerStream(2, Duration(days: 2)),
///       TimerStream(3, Duration(seconds: 3))
///     ]).listen(print); // prints 3
class RaceStream<T> extends StreamView<T> {
  /// Constructs a [Stream] which emits all events from a single [Stream]
  /// inside [streams]. The selected [Stream] is the first one which emits
  /// an event.
  /// After this event, all other [Stream]s in [streams] are discarded.
  RaceStream(Iterable<Stream<T>> streams)
      : super(_buildController(streams).stream);

  static StreamController<T> _buildController<T>(Iterable<Stream<T>> streams) {
    final controller = StreamController<T>(sync: true);
    late List<StreamSubscription<T>> subscriptions;

    controller.onListen = () {
      void reduceToWinner(int winnerIndex) {
        final winner = subscriptions.removeAt(winnerIndex);

        subscriptions.cancelAll()?.onError<Object>((e, s) {
          if (!controller.isClosed && controller.hasListener) {
            controller.addError(e, s);
          }
        });

        subscriptions = [winner];
      }

      void Function(T value) doUpdate(int index) {
        return (T value) {
          if (subscriptions.length > 1) {
            reduceToWinner(index);
          }
          controller.add(value);
        };
      }

      subscriptions = streams
          .mapIndexed((index, stream) => stream.listen(doUpdate(index),
              onError: controller.addError, onDone: controller.close))
          .toList();

      if (subscriptions.isEmpty) {
        controller.close();
      }
    };
    controller.onPause = () => subscriptions.pauseAll();
    controller.onResume = () => subscriptions.resumeAll();
    controller.onCancel = () => subscriptions.cancelAll();

    return controller;
  }
}
