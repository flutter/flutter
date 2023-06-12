import 'dart:async';

class _IgnoreElementsStreamSink<S> implements EventSink<S> {
  final EventSink<Never> _outputSink;

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
/// [ReactiveX doc](http://reactivex.io/documentation/operators/ignoreelements.html)
/// [Interactive marble diagram](https://rxmarbles.com/#ignoreElements)
///
/// ### Example
///
///     MergeStream([
///       Stream.fromIterable([1]),
///       ErrorStream(Exception())
///     ])
///     .transform(IgnoreElementsStreamTransformer())
///     .listen(print, onError: print); // prints Exception
class IgnoreElementsStreamTransformer<S>
    extends StreamTransformerBase<S, Never> {
  /// Constructs a [StreamTransformer] which simply ignores all events from
  /// the source [Stream], except for error or completed events.
  IgnoreElementsStreamTransformer();

  @override
  Stream<Never> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _IgnoreElementsStreamSink<S>(sink));
}

/// Extends the Stream class with the ability to skip, or ignore, data events.
extension IgnoreElementsExtension<T> on Stream<T> {
  /// Creates a Stream where all emitted items are ignored, only the error /
  /// completed notifications are passed
  ///
  /// [ReactiveX doc](http://reactivex.io/documentation/operators/ignoreelements.html)
  /// [Interactive marble diagram](https://rxmarbles.com/#ignoreElements)
  ///
  /// ### Example
  ///
  ///     MergeStream([
  ///       Stream.fromIterable([1]),
  ///       Stream<int>.error(Exception())
  ///     ])
  ///     .ignoreElements()
  ///     .listen(print, onError: print); // prints Exception
  Stream<Never> ignoreElements() =>
      IgnoreElementsStreamTransformer<T>().bind(this);
}
