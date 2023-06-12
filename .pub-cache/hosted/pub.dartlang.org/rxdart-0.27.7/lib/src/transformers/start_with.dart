import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _StartWithStreamSink<S> extends ForwardingSink<S, S> {
  final S _startValue;

  _StartWithStreamSink(this._startValue);

  @override
  void onData(S data) => sink.add(data);

  @override
  void onError(Object e, StackTrace st) => sink.addError(e, st);

  @override
  void onDone() => sink.close();

  @override
  FutureOr onCancel() {}

  @override
  void onListen() {
    sink.add(_startValue);
  }

  @override
  void onPause() {}

  @override
  void onResume() {}
}

/// Prepends a value to the source [Stream].
///
/// ### Example
///
///     Stream.fromIterable([2])
///       .transform(StartWithStreamTransformer(1))
///       .listen(print); // prints 1, 2
class StartWithStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The starting event of this [Stream]
  final S startValue;

  /// Constructs a [StreamTransformer] which prepends the source [Stream]
  /// with [startValue].
  StartWithStreamTransformer(this.startValue);

  @override
  Stream<S> bind(Stream<S> stream) =>
      forwardStream(stream, () => _StartWithStreamSink(startValue));
}

/// Extends the [Stream] class with the ability to emit the given value as the
/// first item.
extension StartWithExtension<T> on Stream<T> {
  /// Prepends a value to the source [Stream].
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([2]).startWith(1).listen(print); // prints 1, 2
  Stream<T> startWith(T startValue) =>
      StartWithStreamTransformer<T>(startValue).bind(this);
}
