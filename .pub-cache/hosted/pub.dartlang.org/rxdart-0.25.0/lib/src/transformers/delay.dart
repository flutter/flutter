import 'dart:async';

class _DelayStreamSink<S> implements EventSink<S> {
  final Duration _duration;
  final EventSink<S> _outputSink;
  var _openTimers = 0;
  var _inputClosed = false;

  _DelayStreamSink(this._outputSink, this._duration);

  @override
  void add(S data) {
    _openTimers++;

    Timer(_duration, () {
      _openTimers--;

      _outputSink.add(data);

      if (_inputClosed && _openTimers == 0) {
        _outputSink.close();
      }
    });
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() {
    _inputClosed = true;

    if (_openTimers == 0) {
      _outputSink.close();
    }
  }
}

/// The Delay operator modifies its source Stream by pausing for
/// a particular increment of time (that you specify) before emitting
/// each of the source Stream’s items.
/// This has the effect of shifting the entire sequence of items emitted
/// by the Stream forward in time by that specified increment.
///
/// [Interactive marble diagram](http://rxmarbles.com/#delay)
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3, 4])
///       .delay(Duration(seconds: 1))
///       .listen(print); // [after one second delay] prints 1, 2, 3, 4 immediately
class DelayStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The delay used to pause initial emission of events by
  final Duration duration;

  /// Constructs a [StreamTransformer] which will first pause for [duration] of time,
  /// before submitting events from the source [Stream].
  DelayStreamTransformer(this.duration);

  @override
  Stream<S> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _DelayStreamSink<S>(sink, duration));
}

/// Extends the Stream class with the ability to delay events being emitted
extension DelayExtension<T> on Stream<T> {
  /// The Delay operator modifies its source Stream by pausing for a particular
  /// increment of time (that you specify) before emitting each of the source
  /// Stream’s items. This has the effect of shifting the entire sequence of
  /// items emitted by the Stream forward in time by that specified increment.
  ///
  /// [Interactive marble diagram](http://rxmarbles.com/#delay)
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3, 4])
  ///       .delay(Duration(seconds: 1))
  ///       .listen(print); // [after one second delay] prints 1, 2, 3, 4 immediately
  Stream<T> delay(Duration duration) =>
      transform(DelayStreamTransformer<T>(duration));
}
