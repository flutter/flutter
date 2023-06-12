import 'dart:async';

import 'package:rxdart/src/utils/error_and_stacktrace.dart';

/// Creates a [Stream] that will recreate and re-listen to the source
/// [Stream] the specified number of times until the [Stream] terminates
/// successfully.
///
/// If the retry count is not specified, it retries indefinitely. If the retry
/// count is met, but the Stream has not terminated successfully, all of the errors
/// and StackTraces that caused the failure will be emitted.
///
/// ### Example
///
///     RetryStream(() => Stream.value(1))
///         .listen((i) => print(i)); // Prints 1
///
///     RetryStream(
///       () => Stream.value(1).concatWith([Stream<int>.error(Error())]),
///       1,
///     ).listen(
///       print,
///       onError: (Object e, StackTrace s) => print(e),
///     ); // Prints 1, 1, Instance of 'Error', Instance of 'Error'
class RetryStream<T> extends Stream<T> {
  /// The factory method used at subscription time
  final Stream<T> Function() streamFactory;

  /// The amount of retry attempts that will be made
  /// If null, then an indefinite amount of attempts will be made.
  final int? count;

  var _retryStep = 0;
  final _errors = <ErrorAndStackTrace>[];
  late final StreamController<T> _controller = StreamController<T>(
    sync: true,
    onListen: _retry,
    onPause: () => _subscription!.pause(),
    onResume: () => _subscription!.resume(),
    onCancel: () {
      _errors.clear();
      return _subscription?.cancel();
    },
  );
  StreamSubscription<void>? _subscription;

  /// Constructs a [Stream] that will recreate and re-listen to the source
  /// [Stream] (created by the provided factory method) the specified number
  /// of times until the [Stream] terminates successfully.
  /// If [count] is not specified, it retries indefinitely.
  RetryStream(this.streamFactory, [this.count]);

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
    void onError(Object e, StackTrace s) {
      _subscription!.cancel();
      _subscription = null;

      _errors.add(ErrorAndStackTrace(e, s));

      if (count == _retryStep) {
        for (var e in [..._errors]) {
          _controller.addError(e.error, e.stackTrace);
        }
        _controller.close();
      } else {
        ++_retryStep;
        _retry();
      }
    }

    _subscription = streamFactory().listen(
      _controller.add,
      onError: onError,
      onDone: _controller.close,
      cancelOnError: false,
    );
  }
}
