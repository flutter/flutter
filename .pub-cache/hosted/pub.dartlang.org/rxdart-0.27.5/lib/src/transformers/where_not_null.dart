import 'dart:async';

class _WhereNotNullStreamSink<T extends Object> implements EventSink<T?> {
  final EventSink<T> _outputSink;

  _WhereNotNullStreamSink(this._outputSink);

  @override
  void add(T? event) {
    if (event != null) {
      _outputSink.add(event);
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _outputSink.addError(error, stackTrace);

  @override
  void close() => _outputSink.close();
}

/// Create a Stream which emits all the non-`null` elements of the Stream,
/// in their original emission order.
///
/// ### Example
///
///     Stream.fromIterable(<int?>[1, 2, 3, null, 4, null])
///       .transform(WhereNotNullStreamTransformer())
///       .listen(print); // prints 1, 2, 3, 4
///
///     // equivalent to:
///
///     Stream.fromIterable(<int?>[1, 2, 3, null, 4, null])
///       .transform(WhereTypeStreamTransformer<int?, int>())
///       .listen(print); // prints 1, 2, 3, 4
class WhereNotNullStreamTransformer<T extends Object>
    extends StreamTransformerBase<T?, T> {
  @override
  Stream<T> bind(Stream<T?> stream) => Stream<T>.eventTransformed(
      stream, (sink) => _WhereNotNullStreamSink<T>(sink));
}

/// Extends the Stream class with the ability to convert the source Stream
/// to a Stream which emits all the non-`null` elements
/// of this Stream, in their original emission order.
extension WhereNotNullExtension<T extends Object> on Stream<T?> {
  /// Returns a Stream which emits all the non-`null` elements
  /// of this Stream, in their original emission order.
  ///
  /// For a `Stream<T?>`, this method is equivalent to `.whereType<T>()`.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable(<int?>[1, 2, 3, null, 4, null])
  ///       .whereNotNull()
  ///       .listen(print); // prints 1, 2, 3, 4
  ///
  ///     // equivalent to:
  ///
  ///     Stream.fromIterable(<int?>[1, 2, 3, null, 4, null])
  ///       .whereType<int>()
  ///       .listen(print); // prints 1, 2, 3, 4
  Stream<T> whereNotNull() => WhereNotNullStreamTransformer<T>().bind(this);
}
