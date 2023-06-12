import 'dart:async';

/// Returns a Stream that, when listening to it, calls a function you specify
/// and then emits the value returned from that function.
///
/// If result from invoking [callable] function:
/// - Is a [Future]: when the future completes, this stream will fire one event, either
///   data or error, and then close with a done-event.
/// - Is a [T]: this stream emits a single data event and then completes with a done event.
///
/// By default, a [FromCallableStream] is a single-subscription Stream. However, it's possible
/// to make them reusable.
/// This Stream is effectively equivalent to one created by
/// `(() async* { yield await callable() }())` or `(() async* { yield callable(); }())`.
///
/// [ReactiveX doc](http://reactivex.io/documentation/operators/from.html)
///
/// ### Example
///
///     FromCallableStream(() => 'Value').listen(print); // prints Value
///
///     FromCallableStream(() async {
///       await Future<void>.delayed(const Duration(seconds: 1));
///       return 'Value';
///     }).listen(print); // prints Value
class FromCallableStream<T> extends Stream<T> {
  Stream<T>? _stream;

  /// A function will be called at subscription time.
  final FutureOr<T> Function() callable;
  final bool _isReusable;

  /// Construct a Stream that, when listening to it, calls a function you specify
  /// and then emits the value returned from that function.
  /// [reusable] indicates whether this Stream can be listened to multiple times or not.
  FromCallableStream(this.callable, {bool reusable = false})
      : _isReusable = reusable;

  @override
  bool get isBroadcast => _isReusable;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (_isReusable || _stream == null) {
      try {
        final value = callable();

        _stream =
            value is Future<T> ? Stream.fromFuture(value) : Stream.value(value);
      } catch (e, s) {
        _stream = Stream.error(e, s);
      }
    }

    return _stream!.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
