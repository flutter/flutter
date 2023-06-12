import 'dart:async';

/// Creates a Stream that will recreate and re-listen to the source
/// Stream when the notifier emits a new value. If the source Stream
/// emits an error or it completes, the Stream terminates.
///
/// If the [retryWhenFactory] throws an error or returns a Stream that emits an error,
/// original error will be emitted. And then, the error from [retryWhenFactory] will be emitted
/// if it is not identical with original error.
///
/// ### Basic Example
///
/// ```dart
///     RetryWhenStream<int>(
///       () => Stream<int>.fromIterable(<int>[1]),
///       (Object error, StackTrace s) => throw error,
///     ).listen(print); // Prints 1
/// ```
///
/// ### Periodic Example
///
/// ```dart
///     RetryWhenStream<int>(
///       () => Stream<int>.periodic(const Duration(seconds: 1), (int i) => i)
///           .map((int i) => i == 2 ? throw 'exception' : i),
///       (Object e, StackTrace s) =>
///           Rx.timer<void>(null, const Duration(milliseconds: 200)),
///     ).take(4).listen(print); // Prints 0, 1, 0, 1
/// ```
///
/// ### Complex Example
///
/// ```dart
///     var errorHappened = false;
///     RetryWhenStream<int>(
///       () => Stream.periodic(const Duration(seconds: 1), (i) => i).map((i) {
///         if (i == 3 && !errorHappened) {
///           throw 'We can take this. Please restart.';
///         } else if (i == 4) {
///           throw 'It\'s enough.';
///         } else {
///           return i;
///         }
///       }),
///       (e, s) {
///         errorHappened = true;
///         if (e == 'We can take this. Please restart.') {
///           return Stream.value('Ok. Here you go!');
///         } else {
///           return Stream.error(e, s);
///         }
///       },
///     ).listen(print, onError: print); // Prints 0, 1, 2, 0, 1, 2, 3, It's enough.
/// ```
class RetryWhenStream<T> extends Stream<T> {
  /// The factory method used at subscription time
  final Stream<T> Function() streamFactory;

  /// The factory method used to create the [Stream] which triggers a re-listen
  final Stream<void> Function(
    Object error,
    StackTrace stackTrace,
  ) retryWhenFactory;

  late final _controller = StreamController<T>(
    sync: true,
    onListen: _retry,
    onPause: () => _subscription!.pause(),
    onResume: () => _subscription!.resume(),
    onCancel: () => _subscription?.cancel(),
  );
  StreamSubscription<void>? _subscription;

  /// Constructs a [Stream] that will recreate and re-listen to the source
  /// [Stream] (created by the provided factory method).
  /// The retry will trigger whenever the [Stream] created by the retryWhen
  /// factory emits and event.
  RetryWhenStream(this.streamFactory, this.retryWhenFactory);

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

  void _retry() {
    void onError(Object originalError, StackTrace originalStacktrace) {
      _cancelSubscription();

      Stream<void> retryStream;
      try {
        retryStream = retryWhenFactory(originalError, originalStacktrace);
      } catch (e, s) {
        return _addErrorAndClose(originalError, originalStacktrace, e, s);
      }

      _subscription = retryStream.listen(
        (_) {
          _cancelSubscription();
          _retry();
        },
        onError: (Object e, StackTrace s) {
          _cancelSubscription();
          _addErrorAndClose(originalError, originalStacktrace, e, s);
        },
        cancelOnError: false,
      );
    }

    _subscription = streamFactory().listen(
      _controller.add,
      onError: onError,
      onDone: _controller.close,
      cancelOnError: false,
    );
  }

  void _addErrorAndClose(
    Object originalError,
    StackTrace originalStacktrace,
    Object e,
    StackTrace s,
  ) {
    if (identical(originalError, e)) {
      _controller.addError(originalError, originalStacktrace);
    } else {
      _controller.addError(originalError, originalStacktrace);
      _controller.addError(e, s);
    }
    _controller.close();
  }

  void _cancelSubscription() {
    _subscription!.cancel();
    _subscription = null;
  }
}
