import 'dart:async';

class _ScanStreamSink<S, T> implements EventSink<S> {
  final T Function(T accumulated, S value, int index) _accumulator;
  final EventSink<T> _outputSink;
  T _acc;
  var _index = 0;

  _ScanStreamSink(this._outputSink, this._accumulator, [T seed]) : _acc = seed;

  @override
  void add(S data) {
    _acc = _accumulator(_acc, data, _index++);

    _outputSink.add(_acc);
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();
}

/// Applies an accumulator function over an stream sequence and returns
/// each intermediate result. The optional seed value is used as the initial
/// accumulator value.
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3])
///        .transform(ScanStreamTransformer((acc, curr, i) => acc + curr, 0))
///        .listen(print); // prints 1, 3, 6
class ScanStreamTransformer<S, T> extends StreamTransformerBase<S, T> {
  /// Method which accumulates incoming event into a single, accumulated object
  final T Function(T accumulated, S value, int index) accumulator;

  /// The initial value for the accumulated value in the [accumulator]
  final T seed;

  /// Constructs a [ScanStreamTransformer] which applies an accumulator Function
  /// over the source [Stream] and returns each intermediate result.
  /// The optional seed value is used as the initial accumulator value.
  ScanStreamTransformer(this.accumulator, [this.seed]);

  @override
  Stream<T> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _ScanStreamSink<S, T>(sink, accumulator, seed));
}

/// Extends
extension ScanExtension<T> on Stream<T> {
  /// Applies an accumulator function over a Stream sequence and returns each
  /// intermediate result. The optional seed value is used as the initial
  /// accumulator value.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3])
  ///        .scan((acc, curr, i) => acc + curr, 0)
  ///        .listen(print); // prints 1, 3, 6
  Stream<S> scan<S>(
    S Function(S accumulated, T value, int index) accumulator, [
    S seed,
  ]) =>
      transform(ScanStreamTransformer<T, S>(accumulator, seed));
}
