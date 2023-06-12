import 'dart:async';

class _MapToStreamSink<S, T> implements EventSink<S> {
  final T _value;
  final EventSink<T> _outputSink;

  _MapToStreamSink(this._outputSink, this._value);

  @override
  void add(S data) => _outputSink.add(_value);

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();
}

/// Emits the given constant value on the output Stream every time the source
/// Stream emits a value.
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3, 4])
///       .mapTo(true)
///       .listen(print); // prints true, true, true, true
class MapToStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  /// A constant [value] which will always be returned when using this transformer.
  final T value;

  /// Constructs a [StreamTransformer] which always maps every event from
  /// the source [Stream] to a constant [value].
  MapToStreamTransformer(this.value);

  @override
  Stream<T> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _MapToStreamSink<S, T>(sink, value));
}

/// Extends the Stream class with the ability to convert each item to the same
/// value.
extension MapToExtension<S> on Stream<S> {
  /// Emits the given constant value on the output Stream every time the source
  /// Stream emits a value.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3, 4])
  ///       .mapTo(true)
  ///       .listen(print); // prints true, true, true, true
  Stream<T> mapTo<T>(T value) => transform(MapToStreamTransformer(value));
}
