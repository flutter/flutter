import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _TakeUntilStreamSink<S, T> extends ForwardingSink<S, S> {
  final Stream<T> _otherStream;
  StreamSubscription<T>? _otherSubscription;

  _TakeUntilStreamSink(this._otherStream);

  @override
  void onData(S data) => sink.add(data);

  @override
  void onError(Object e, StackTrace st) => sink.addError(e, st);

  @override
  void onDone() {
    _otherSubscription?.cancel();
    sink.close();
  }

  @override
  FutureOr<void> onCancel() => _otherSubscription?.cancel();

  @override
  void onListen() => _otherSubscription = _otherStream
      .take(1)
      .listen(null, onError: sink.addError, onDone: sink.close);

  @override
  void onPause() => _otherSubscription?.pause();

  @override
  void onResume() => _otherSubscription?.resume();
}

/// Returns the values from the source stream sequence until the other
/// stream sequence produces a value.
///
/// ### Example
///
///     MergeStream([
///         Stream.fromIterable([1]),
///         TimerStream(2, Duration(minutes: 1))
///       ])
///       .transform(TakeUntilStreamTransformer(
///         TimerStream(3, Duration(seconds: 10))))
///       .listen(print); // prints 1
class TakeUntilStreamTransformer<S, T> extends StreamTransformerBase<S, S> {
  /// The [Stream] which closes this [Stream] as soon as it emits an event.
  final Stream<T> otherStream;

  /// Constructs a [StreamTransformer] which emits events from the source [Stream],
  /// until [otherStream] fires.
  TakeUntilStreamTransformer(this.otherStream);

  @override
  Stream<S> bind(Stream<S> stream) =>
      forwardStream(stream, () => _TakeUntilStreamSink(otherStream));
}

/// Extends the Stream class with the ability receive events from the source
/// Stream until another Stream produces a value.
extension TakeUntilExtension<T> on Stream<T> {
  /// Returns the values from the source Stream sequence until the other Stream
  /// sequence produces a value.
  ///
  /// ### Example
  ///
  ///     MergeStream([
  ///         Stream.fromIterable([1]),
  ///         TimerStream(2, Duration(minutes: 1))
  ///       ])
  ///       .takeUntil(TimerStream(3, Duration(seconds: 10)))
  ///       .listen(print); // prints 1
  Stream<T> takeUntil<S>(Stream<S> otherStream) =>
      TakeUntilStreamTransformer<T, S>(otherStream).bind(this);
}
