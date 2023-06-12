import 'dart:async';

class _DefaultIfEmptyStreamSink<S> implements EventSink<S> {
  final S _defaultValue;
  final EventSink<S> _outputSink;
  bool _isEmpty = true;

  _DefaultIfEmptyStreamSink(this._outputSink, this._defaultValue);

  @override
  void add(S data) {
    _isEmpty = false;
    _outputSink.add(data);
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() {
    if (_isEmpty) {
      _outputSink.add(_defaultValue);
    }

    _outputSink.close();
  }
}

/// Emit items from the source [Stream], or a single default item if the source
/// Stream emits nothing.
///
/// ### Example
///
///     Stream.empty()
///       .transform(DefaultIfEmptyStreamTransformer(10))
///       .listen(print); // prints 10
class DefaultIfEmptyStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The event that should be emitted if the source [Stream] is empty
  final S defaultValue;

  /// Constructs a [StreamTransformer] which either emits from the source [Stream],
  /// or just a [defaultValue] if the source [Stream] emits nothing.
  DefaultIfEmptyStreamTransformer(this.defaultValue);

  @override
  Stream<S> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _DefaultIfEmptyStreamSink<S>(sink, defaultValue));
}

///
extension DefaultIfEmptyExtension<T> on Stream<T> {
  /// Emit items from the source Stream, or a single default item if the source
  /// Stream emits nothing.
  ///
  /// ### Example
  ///
  ///     Stream.empty().defaultIfEmpty(10).listen(print); // prints 10
  Stream<T> defaultIfEmpty(T defaultValue) =>
      transform(DefaultIfEmptyStreamTransformer<T>(defaultValue));
}
