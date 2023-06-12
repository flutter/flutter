import 'dart:async';

/// Emits the given value after a specified amount of time.
///
/// ### Example
///
///     TimerStream('hi', Duration(minutes: 1))
///         .listen((i) => print(i)); // print 'hi' after 1 minute
class TimerStream<T> extends Stream<T> {
  final StreamController<T> _controller;

  /// Constructs a [Stream] which emits [value] after the specified [Duration].
  TimerStream(T value, Duration duration)
      : _controller = _buildController(value, duration);

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  static StreamController<T> _buildController<T>(T value, Duration duration) {
    final watch = Stopwatch();
    Timer? timer;
    late StreamController<T> controller;
    Duration? totalElapsed = Duration.zero;

    void onResume() {
      // Already cancelled or is not paused.
      if (totalElapsed == null || timer != null) return;

      totalElapsed = totalElapsed! + watch.elapsed;
      watch.start();

      timer = Timer(duration - totalElapsed!, () {
        controller.add(value);
        controller.close();
      });
    }

    controller = StreamController(
      sync: true,
      onListen: () {
        watch.start();
        timer = Timer(duration, () {
          controller.add(value);
          controller.close();
        });
      },
      onPause: () {
        timer?.cancel();
        timer = null;
        watch.stop();
      },
      onResume: onResume,
      onCancel: () {
        timer?.cancel();
        timer = null;
        totalElapsed = null;
      },
    );
    return controller;
  }
}
