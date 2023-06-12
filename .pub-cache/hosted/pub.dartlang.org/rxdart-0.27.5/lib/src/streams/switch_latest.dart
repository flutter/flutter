import 'dart:async';

/// Convert a [Stream] that emits [Stream]s (aka a 'Higher Order Stream') into a
/// single [Stream] that emits the items emitted by the most-recently-emitted of
/// those [Stream]s.
///
/// This stream will unsubscribe from the previously-emitted Stream when a new
/// Stream is emitted from the source Stream.
///
/// ### Example
///
/// ```dart
/// final switchLatestStream = SwitchLatestStream<String>(
///   Stream.fromIterable(<Stream<String>>[
///     Rx.timer('A', Duration(seconds: 2)),
///     Rx.timer('B', Duration(seconds: 1)),
///     Stream.value('C'),
///   ]),
/// );
///
/// // Since the first two Streams do not emit data for 1-2 seconds, and the 3rd
/// // Stream will be emitted before that time, only data from the 3rd Stream
/// // will be emitted to the listener.
/// switchLatestStream.listen(print); // prints 'C'
/// ```
class SwitchLatestStream<T> extends Stream<T> {
  // ignore: close_sinks
  final StreamController<T> _controller;

  /// Constructs a [Stream] that emits [Stream]s (aka a 'Higher Order Stream") into a
  /// single [Stream] that emits the items emitted by the most-recently-emitted of
  /// those [Stream]s.
  SwitchLatestStream(Stream<Stream<T>> streams)
      : _controller = _buildController(streams);

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  static StreamController<T> _buildController<T>(Stream<Stream<T>> streams) {
    late StreamController<T> controller;
    late StreamSubscription<Stream<T>> subscription;
    StreamSubscription<T>? otherSubscription;
    var leftClosed = false, rightClosed = false, hasMainEvent = false;

    controller = StreamController<T>(
        sync: true,
        onListen: () {
          void closeLeft() {
            leftClosed = true;

            if (rightClosed || !hasMainEvent) controller.close();
          }

          void closeRight() {
            rightClosed = true;

            if (leftClosed) controller.close();
          }

          subscription = streams.listen((stream) {
            try {
              otherSubscription?.cancel();

              hasMainEvent = true;

              otherSubscription = stream.listen(
                controller.add,
                onError: controller.addError,
                onDone: closeRight,
              );
            } catch (e, s) {
              controller.addError(e, s);
            }
          }, onError: controller.addError, onDone: closeLeft);
        },
        onPause: () {
          subscription.pause();
          otherSubscription?.pause();
        },
        onResume: () {
          subscription.resume();
          otherSubscription?.resume();
        },
        onCancel: () async {
          await subscription.cancel();

          if (hasMainEvent) await otherSubscription?.cancel();
        });

    return controller;
  }
}
