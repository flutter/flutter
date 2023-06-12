import 'dart:async';

class _EndWithStreamSink<S> implements EventSink<S> {
  final S _endValue;
  final EventSink<S> _outputSink;

  _EndWithStreamSink(this._outputSink, this._endValue);

  @override
  void add(S data) => _outputSink.add(data);

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() {
    _outputSink.add(_endValue);
    _outputSink.close();
  }
}

/// Appends a value to the source [Stream] before closing.
///
/// ### Example
///
///     Stream.fromIterable([2])
///       .transform(EndWithStreamTransformer(1))
///       .listen(print); // prints 2, 1
class EndWithStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The ending event of this [Stream]
  final S endValue;

  /// Constructs a [StreamTransformer] which appends the source [Stream]
  /// with [endValue] just before it closes.
  EndWithStreamTransformer(this.endValue);

  @override
  Stream<S> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _EndWithStreamSink<S>(sink, endValue));
}

/// Extends the [Stream] class with the ability to emit the given value as the
/// final item before closing.
extension EndWithExtension<T> on Stream<T> {
  /// Appends a value to the source [Stream] before closing.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([2]).endWith(1).listen(print); // prints 2, 1
  Stream<T> endWith(T endValue) =>
      transform(EndWithStreamTransformer<T>(endValue));
}
