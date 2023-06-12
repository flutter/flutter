import 'dart:async';

class _MapNotNullSink<T, R extends Object> implements EventSink<T> {
  final R? Function(T) _transform;
  final EventSink<R> _outputSink;

  _MapNotNullSink(this._outputSink, this._transform);

  @override
  void add(T event) {
    final value = _transform(event);
    if (value != null) {
      _outputSink.add(value);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _outputSink.addError(error, stackTrace);

  @override
  void close() => _outputSink.close();
}

/// Create a Stream containing only the non-`null` results
/// of applying the given [transform] function to each element of the Stream.
///
/// ### Example
///
///     Stream.fromIterable(['1', 'two', '3', 'four'])
///       .transform(MapNotNullStreamTransformer(int.tryParse))
///       .listen(print); // prints 1, 3
///
///     // equivalent to:
///
///     Stream.fromIterable(['1', 'two', '3', 'four'])
///       .map(int.tryParse)
///       .transform(WhereTypeStreamTransformer<int?, int>())
///       .listen(print); // prints 1, 3
class MapNotNullStreamTransformer<T, R extends Object>
    extends StreamTransformerBase<T, R> {
  /// A function that transforms each elements of the Stream.
  final R? Function(T) transform;

  /// Constructs a [StreamTransformer] which emits non-`null` elements
  /// of applying the given [transform] function to each element of the Stream.
  const MapNotNullStreamTransformer(this.transform);

  @override
  Stream<R> bind(Stream<T> stream) => Stream<R>.eventTransformed(
      stream, (sink) => _MapNotNullSink<T, R>(sink, transform));
}

/// Extends the Stream class with the ability to convert the source Stream
/// to a Stream containing only the non-`null` results
/// of applying the given [transform] function to each element of this Stream.
extension MapNotNullExtension<T> on Stream<T> {
  /// Returns a Stream containing only the non-`null` results
  /// of applying the given [transform] function to each element of this Stream.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable(['1', 'two', '3', 'four'])
  ///       .mapNotNull(int.tryParse)
  ///       .listen(print); // prints 1, 3
  ///
  ///     // equivalent to:
  ///
  ///     Stream.fromIterable(['1', 'two', '3', 'four'])
  ///       .map(int.tryParse)
  ///       .whereType<int>()
  ///       .listen(print); // prints 1, 3
  Stream<R> mapNotNull<R extends Object>(R? Function(T) transform) =>
      MapNotNullStreamTransformer<T, R>(transform).bind(this);
}
