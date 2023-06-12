import 'dart:async';

class _TakeWhileInclusiveStreamSink<S> implements EventSink<S> {
  final bool Function(S) _test;
  final EventSink<S> _outputSink;

  _TakeWhileInclusiveStreamSink(this._outputSink, this._test);

  @override
  void add(S data) {
    bool satisfies;

    try {
      satisfies = _test(data);
    } catch (e, s) {
      _outputSink.addError(e, s);
      // The test didn't say true. Didn't say false either, but we stop anyway.
      _outputSink.close();
      return;
    }

    if (satisfies) {
      _outputSink.add(data);
    } else {
      _outputSink.add(data);
      _outputSink.close();
    }
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();
}

/// Emits values emitted by the source Stream so long as each value
/// satisfies the given test. When the test is not satisfied by a value, it
/// will emit this value as a final event and then complete.
///
/// ### Example
///
///     Stream.fromIterable([2, 3, 4, 5, 6, 1, 2, 3])
///       .transform(TakeWhileInclusiveStreamTransformer((i) => i < 4))
///       .listen(print); // prints 2, 3, 4
class TakeWhileInclusiveStreamTransformer<S>
    extends StreamTransformerBase<S, S> {
  /// Method used to test incoming events
  final bool Function(S) test;

  /// Constructs a [StreamTransformer] which forwards data events while [test]
  /// is successful, and includes last event that caused [test] to return false.
  TakeWhileInclusiveStreamTransformer(this.test) {
    if (test == null) {
      throw ArgumentError.notNull('test');
    }
  }

  @override
  Stream<S> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _TakeWhileInclusiveStreamSink<S>(sink, test));
}

/// Extends the Stream class with the ability to take events while they pass
/// the condition given and include last event that doesn't pass the condition.
extension TakeWhileInclusiveExtension<T> on Stream<T> {
  /// Emits values emitted by the source Stream so long as each value
  /// satisfies the given test. When the test is not satisfied by a value, it
  /// will emit this value as a final event and then complete.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([2, 3, 4, 5, 6, 1, 2, 3])
  ///       .takeWhileInclusive((i) => i < 4)
  ///       .listen(print); // prints 2, 3, 4
  Stream<T> takeWhileInclusive(bool Function(T) test) =>
      transform(TakeWhileInclusiveStreamTransformer(test));
}
