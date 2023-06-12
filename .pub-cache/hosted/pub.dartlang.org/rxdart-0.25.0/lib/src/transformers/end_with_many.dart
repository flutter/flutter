import 'dart:async';

class _EndWithManyStreamSink<S> implements EventSink<S> {
  final Iterable<S> _endValues;
  final EventSink<S> _outputSink;

  _EndWithManyStreamSink(this._outputSink, this._endValues);

  @override
  void add(S data) => _outputSink.add(data);

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() {
    _endValues.forEach(_outputSink.add);
    _outputSink.close();
  }
}

/// Appends a sequence of values to the source [Stream].
///
/// ### Example
///
///     Stream.fromIterable([3])
///       .transform(EndWithManyStreamTransformer([1, 2]))
///       .listen(print); // prints 3, 1, 2
class EndWithManyStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The ending events of this [Stream]
  final Iterable<S> endValues;

  /// Constructs a [StreamTransformer] which appends the source [Stream]
  /// with [endValues] before closing.
  EndWithManyStreamTransformer(this.endValues) {
    if (endValues == null) {
      throw ArgumentError('startValues cannot be null');
    }
  }

  @override
  Stream<S> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _EndWithManyStreamSink<S>(sink, endValues));
}

/// Extends the Stream class with the ability to emit the given value as the
/// final item before closing.
extension EndWithManyExtension<T> on Stream<T> {
  /// Appends a sequence of values as final events to the source [Stream] before closing.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([2]).endWithMany([1, 0]).listen(print); // prints 2, 1, 0
  Stream<T> endWithMany(Iterable<T> endValues) =>
      transform(EndWithManyStreamTransformer<T>(endValues));
}
