import 'dart:async';
import 'dart:collection';

class _IntervalStreamSink<S> implements EventSink<S> {
  final Duration _duration;
  final EventSink<S> _outputSink;
  final _queue = Queue<S>();
  var _inputClosed = false;
  var _openIntervals = 0;

  bool get noOpenIntervals => _openIntervals == 0;

  _IntervalStreamSink(this._outputSink, this._duration);

  @override
  void add(S data) {
    _queue.add(data);

    if (noOpenIntervals) {
      _addNext();
    }
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() {
    _inputClosed = true;

    if (noOpenIntervals) {
      _outputSink.close();
    }
  }

  void _addNext() {
    if (_queue.isNotEmpty) {
      _addDelayed(_queue.removeFirst()).whenComplete(_addNext);
    }
  }

  Future<void> _addDelayed(S data) {
    _openIntervals++;

    return Future.delayed(_duration, () => data)
        .then(_outputSink.add)
        .whenComplete(() {
      _openIntervals--;

      if (_inputClosed && _queue.isEmpty) {
        _outputSink.close();
      }
    });
  }
}

/// Creates a Stream that emits each item in the Stream after a given
/// duration.
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3])
///       .transform(IntervalStreamTransformer(Duration(seconds: 1)))
///       .listen((i) => print('$i sec'); // prints 1 sec, 2 sec, 3 sec
class IntervalStreamTransformer<S> extends StreamTransformerBase<S, S> {
  /// The interval after which incoming events need to be emitted.
  final Duration duration;

  /// Constructs a [StreamTransformer] which emits each item from the source [Stream],
  /// after a given duration.
  IntervalStreamTransformer(this.duration);

  @override
  Stream<S> bind(Stream<S> stream) => Stream.eventTransformed(
      stream, (sink) => _IntervalStreamSink<S>(sink, duration));
}

/// Extends the Stream class with the ability to emit each item after a given
/// duration.
extension IntervalExtension<T> on Stream<T> {
  /// Creates a Stream that emits each item in the Stream after a given
  /// duration.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3])
  ///       .interval(Duration(seconds: 1))
  ///       .listen((i) => print('$i sec'); // prints 1 sec, 2 sec, 3 sec
  Stream<T> interval(Duration duration) =>
      transform(IntervalStreamTransformer<T>(duration));
}
