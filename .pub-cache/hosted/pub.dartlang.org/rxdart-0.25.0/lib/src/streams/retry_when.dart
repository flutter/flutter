import 'dart:async';

import 'package:rxdart/src/streams/utils.dart';
import 'package:rxdart/src/utils/error_and_stacktrace.dart';

/// Creates a Stream that will recreate and re-listen to the source
/// Stream when the notifier emits a new value. If the source Stream
/// emits an error or it completes, the Stream terminates.
///
/// If the [retryWhenFactory] emits an error a [RetryError] will be
/// thrown. The RetryError will contain all of the [Error]s and
/// [StackTrace]s that caused the failure.
///
/// ### Basic Example
/// ```dart
/// RetryWhenStream<int>(
///   () => Stream<int>.fromIterable(<int>[1]),
///   (dynamic error, StackTrace s) => throw error,
/// ).listen(print); // Prints 1
/// ```
///
/// ### Periodic Example
/// ```dart
/// RetryWhenStream<int>(
///   () => Stream<int>
///       .periodic(const Duration(seconds: 1), (int i) => i)
///       .map((int i) => i == 2 ? throw 'exception' : i),
///   (dynamic e, StackTrace s) {
///     return Rx<String>
///         .timer('random value', const Duration(milliseconds: 200));
///   },
/// ).take(4).listen(print); // Prints 0, 1, 0, 1
/// ```
///
/// ### Complex Example
/// ```dart
/// bool errorHappened = false;
/// RetryWhenStream(
///   () => Stream
///       .periodic(const Duration(seconds: 1), (i) => i)
///       .map((i) {
///         if (i == 3 && !errorHappened) {
///           throw 'We can take this. Please restart.';
///         } else if (i == 4) {
///           throw 'It\'s enough.';
///         } else {
///           return i;
///         }
///       }),
///   (e, s) {
///     errorHappened = true;
///     if (e == 'We can take this. Please restart.') {
///       return Stream.value('Ok. Here you go!');
///     } else {
///       return Stream.error(e);
///     }
///   },
/// ).listen(
///   print,
///   onError: (e, s) => print(e),
/// ); // Prints 0, 1, 2, 0, 1, 2, 3, RetryError
/// ```
class RetryWhenStream<T> extends Stream<T> {
  /// The factory method used at subscription time
  final Stream<T> Function() streamFactory;

  /// The factory method used to create the [Stream] which triggers a re-listen
  final RetryWhenStreamFactory retryWhenFactory;
  StreamController<T> _controller;
  StreamSubscription<T> _subscription;
  final _errors = <ErrorAndStackTrace>[];

  /// Constructs a [Stream] that will recreate and re-listen to the source
  /// [Stream] (created by the provided factory method).
  /// The retry will trigger whenever the [Stream] created by the retryWhen
  /// factory emits and event.
  RetryWhenStream(this.streamFactory, this.retryWhenFactory);

  @override
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    _controller ??= StreamController<T>(
      sync: true,
      onListen: _retry,
      onPause: () => _subscription.pause(),
      onResume: () => _subscription.resume(),
      onCancel: () => _subscription.cancel(),
    );

    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void _retry() {
    _subscription = streamFactory().listen(
      _controller.add,
      onError: (Object e, [StackTrace s]) {
        _subscription.cancel();

        StreamSubscription<void> sub;
        sub = retryWhenFactory(e, s).listen(
          (event) {
            sub.cancel();
            _errors.add(ErrorAndStackTrace(e, s));
            _retry();
          },
          onError: (Object e, [StackTrace s]) {
            sub.cancel();
            _controller
              ..addError(RetryError.onReviveFailed(
                _errors..add(ErrorAndStackTrace(e, s)),
              ))
              ..close();
          },
        );
      },
      onDone: _controller.close,
      cancelOnError: false,
    );
  }
}
