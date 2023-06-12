import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _SkipUntilStreamSink<S, T> extends ForwardingSink<S, S> {
  final Stream<T> _otherStream;
  StreamSubscription<T>? _otherSubscription;
  var _canAdd = false;

  _SkipUntilStreamSink(this._otherStream);

  @override
  void onData(S data) {
    if (_canAdd) {
      sink.add(data);
    }
  }

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
      .listen(null, onError: sink.addError, onDone: () => _canAdd = true);

  @override
  void onPause() => _otherSubscription?.pause();

  @override
  void onResume() => _otherSubscription?.resume();
}

/// Starts emitting events only after the given stream emits an event.
///
/// ### Example
///
///     MergeStream([
///       Stream.value(1),
///       TimerStream(2, Duration(minutes: 2))
///     ])
///     .transform(SkipUntilStreamTransformer(TimerStream(1, Duration(minutes: 1))))
///     .listen(print); // prints 2;
class SkipUntilStreamTransformer<S, T> extends StreamTransformerBase<S, S> {
  /// The [Stream] which is required to emit first, before this [Stream] starts emitting
  final Stream<T> otherStream;

  /// Constructs a [StreamTransformer] which starts emitting events
  /// only after [otherStream] emits an event.
  SkipUntilStreamTransformer(this.otherStream);

  @override
  Stream<S> bind(Stream<S> stream) =>
      forwardStream(stream, () => _SkipUntilStreamSink(otherStream));
}

/// Extends the Stream class with the ability to skip events until another
/// Stream emits an item.
extension SkipUntilExtension<T> on Stream<T> {
  /// Starts emitting items only after the given stream emits an item.
  ///
  /// ### Example
  ///
  ///     MergeStream([
  ///         Stream.fromIterable([1]),
  ///         TimerStream(2, Duration(minutes: 2))
  ///       ])
  ///       .skipUntil(TimerStream(true, Duration(minutes: 1)))
  ///       .listen(print); // prints 2;
  Stream<T> skipUntil<S>(Stream<S> otherStream) =>
      SkipUntilStreamTransformer<T, S>(otherStream).bind(this);
}
