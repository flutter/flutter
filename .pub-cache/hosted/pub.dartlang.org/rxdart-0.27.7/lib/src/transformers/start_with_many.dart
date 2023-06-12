import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _StartWithManyStreamSink<S> extends ForwardingSink<S, S> {
  final Iterable<S> _startValues;

  _StartWithManyStreamSink(this._startValues);

  @override
  void onData(S data) => sink.add(data);

  @override
  void onError(Object e, StackTrace st) => sink.addError(e, st);

  @override
  void onDone() => sink.close();

  @override
  FutureOr<void> onCancel() {}

  @override
  void onListen() {
    _startValues.forEach(sink.add);
  }

  @override
  void onPause() {}

  @override
  void onResume() {}
}

/// Prepends a sequence of values to the source [Stream].
///
/// ### Example
///
///     Stream.fromIterable([3])
///       .transform(StartWithManyStreamTransformer([1, 2]))
///       .listen(print); // prints 1, 2, 3
class StartWithManyStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The starting events of this [Stream]
  final Iterable<S> startValues;

  /// Constructs a [StreamTransformer] which prepends the source [Stream]
  /// with [startValues].
  StartWithManyStreamTransformer(this.startValues);

  @override
  Stream<S> bind(Stream<S> stream) =>
      forwardStream(stream, () => _StartWithManyStreamSink(startValues));
}

/// Extends the [Stream] class with the ability to emit the given values as the
/// first items.
extension StartWithManyExtension<T> on Stream<T> {
  /// Prepends a sequence of values to the source [Stream].
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([3]).startWithMany([1, 2])
  ///       .listen(print); // prints 1, 2, 3
  Stream<T> startWithMany(List<T> startValues) =>
      StartWithManyStreamTransformer<T>(startValues).bind(this);
}
