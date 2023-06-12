import 'dart:async';

/// Returns a non-terminating stream sequence, which can be used to denote
/// an infinite duration.
///
/// The never operator is one with very specific and limited behavior. These
/// are useful for testing purposes, and sometimes also for combining with
/// other Streams or as parameters to operators that expect other
/// Streams as parameters.
///
/// ### Example
///
///     NeverStream().listen(print); // Neither prints nor terminates
class NeverStream<T> extends Stream<T> {
  // ignore: close_sinks
  final _controller = StreamController<T>();

  /// Constructs a [Stream] which never emits an event and simply remains
  /// open until implicitly closed by the developer.
  NeverStream();

  @override
  StreamSubscription<T> listen(void Function(T event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _controller.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}
