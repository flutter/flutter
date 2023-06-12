import 'dart:async';

class _WhereTypeStreamSink<S, T> implements EventSink<S> {
  final EventSink<T> _outputSink;

  _WhereTypeStreamSink(this._outputSink);

  @override
  void add(S data) {
    if (data is T) {
      _outputSink.add(data);
    }
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();
}

/// This transformer is a shorthand for [Stream.where] followed by [Stream.cast].
///
/// Events that do not match [T] are filtered out, the resulting
/// [Stream] will be of Type [T].
///
/// ### Example
///
///     Stream.fromIterable([1, 'two', 3, 'four'])
///       .whereType<int>()
///       .listen(print); // prints 1, 3
///
/// // as opposed to:
///
///     Stream.fromIterable([1, 'two', 3, 'four'])
///       .where((event) => event is int)
///       .cast<int>()
///       .listen(print); // prints 1, 3
///
class WhereTypeStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  /// Constructs a [StreamTransformer] which combines [Stream.where] followed by [Stream.cast].
  WhereTypeStreamTransformer();

  @override
  Stream<T> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _WhereTypeStreamSink<S, T>(sink));
}

/// Extends the Stream class with the ability to filter down events to only
/// those of a specific type.
extension WhereTypeExtension<T> on Stream<T> {
  /// This transformer is a shorthand for [Stream.where] followed by
  /// [Stream.cast].
  ///
  /// Events that do not match [T] are filtered out, the resulting [Stream] will
  /// be of Type [T].
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 'two', 3, 'four'])
  ///       .whereType<int>()
  ///       .listen(print); // prints 1, 3
  ///
  /// #### as opposed to:
  ///
  ///     Stream.fromIterable([1, 'two', 3, 'four'])
  ///       .where((event) => event is int)
  ///       .cast<int>()
  ///       .listen(print); // prints 1, 3
  Stream<S> whereType<S>() => transform(WhereTypeStreamTransformer<T, S>());
}
