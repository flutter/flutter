import 'dart:async';

class _IgnoreElementsStreamSink<S> implements EventSink<S> {
  final EventSink<S> _outputSink;

  _IgnoreElementsStreamSink(this._outputSink);

  @override
  void add(S data) {}

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();
}

/// Creates a [Stream] where all emitted items are ignored, only the
/// error / completed notifications are passed
///
/// ### Example
///
///     MergeStream([
///       Stream.fromIterable([1]),
///       ErrorStream(Exception())
///     ])
///     .listen(print, onError: print); // prints Exception
@Deprecated('Use the drain method from the Stream class instead')
class IgnoreElementsStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// Constructs a [StreamTransformer] which simply ignores all events from
  /// the source [Stream], except for error or completed events.
  IgnoreElementsStreamTransformer();

  @override
  Stream<S> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _IgnoreElementsStreamSink<S>(sink));
}

/// Extends the Stream class with the ability to skip, or ignore, data events.
extension IgnoreElementsExtension<T> on Stream<T> {
  /// Creates a Stream where all emitted items are ignored, only the error /
  /// completed notifications are passed
  ///
  /// ### Example
  ///
  ///    MergeStream([
  ///      Stream.fromIterable([1]),
  ///      Stream.error(Exception())
  ///    ])
  ///    .listen(print, onError: print); // prints Exception
  @Deprecated('Use the drain method from the Stream class instead')
  Stream<T> ignoreElements() => transform(IgnoreElementsStreamTransformer<T>());
}
