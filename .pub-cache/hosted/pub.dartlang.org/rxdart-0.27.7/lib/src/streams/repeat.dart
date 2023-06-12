import 'dart:async';

/// Creates a [Stream] that will recreate and re-listen to the source
/// Stream the specified number of times until the [Stream] terminates
/// successfully.
///
/// If [count] is not specified, it repeats indefinitely.
///
/// ### Example
///
///     RepeatStream((int repeatCount) =>
///       Stream.value('repeat index: $repeatCount'), 3)
///         .listen((i) => print(i)); // Prints 'repeat index: 0, repeat index: 1, repeat index: 2'
class RepeatStream<T> extends Stream<T> {
  /// The factory method used at subscription time
  final Stream<T> Function(int) streamFactory;

  /// The amount of repeat attempts that will be made
  /// If 0, then an indefinite amount of attempts will be made.
  final int? count;
  int _repeatStep = 0;
  StreamController<T>? _controller;
  StreamSubscription<T>? _subscription;

  /// Constructs a [Stream] that will recreate and re-listen to the source
  /// [Stream] (created with the provided factory method).
  /// The count parameter specifies number of times the repeat will take place,
  /// until this [Stream] terminates successfully.
  /// If the count parameter is not specified, then this [Stream] will repeat
  /// indefinitely.
  RepeatStream(this.streamFactory, [this.count]);

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    _controller ??= StreamController<T>(
        sync: true,
        onListen: _maybeRepeatNext,
        onPause: () => _subscription?.pause(),
        onResume: () => _subscription?.resume(),
        onCancel: () => _subscription?.cancel());

    return _controller!.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void _repeatNext() {
    void onDone() {
      _subscription?.cancel();

      _maybeRepeatNext();
    }

    final controller = _controller!;
    try {
      _subscription = streamFactory(_repeatStep++).listen(
        controller.add,
        onError: controller.addError,
        onDone: onDone,
        cancelOnError: false,
      );
    } catch (e, s) {
      controller.addError(e, s);
    }
  }

  void _maybeRepeatNext() {
    if (_repeatStep == count) {
      _controller!.close();
    } else {
      _repeatNext();
    }
  }
}
