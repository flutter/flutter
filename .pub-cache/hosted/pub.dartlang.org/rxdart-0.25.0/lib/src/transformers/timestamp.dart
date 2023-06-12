import 'dart:async';

class _TimestampStreamSink<S> implements EventSink<S> {
  final EventSink<Timestamped<S>> _outputSink;

  _TimestampStreamSink(this._outputSink);

  @override
  void add(S data) {
    _outputSink.add(Timestamped(DateTime.now(), data));
  }

  @override
  void addError(e, [st]) => _outputSink.addError(e, st);

  @override
  void close() => _outputSink.close();
}

/// Wraps each item emitted by the source Stream in a [Timestamped] object
/// that includes the emitted item and the time when the item was emitted.
///
/// Example
///
///     Stream.fromIterable([1])
///        .transform(TimestampStreamTransformer())
///        .listen((i) => print(i)); // prints 'TimeStamp{timestamp: XXX, value: 1}';
class TimestampStreamTransformer<S>
    extends StreamTransformerBase<S, Timestamped<S>> {
  /// Constructs a [StreamTransformer] which emits events from the
  /// source [Stream] as snapshots in the form of [Timestamped].
  TimestampStreamTransformer();

  @override
  Stream<Timestamped<S>> bind(Stream<S> stream) =>
      Stream.eventTransformed(stream, (sink) => _TimestampStreamSink<S>(sink));
}

/// A class that represents a snapshot of the current value emitted by a
/// [Stream], at a specified timestamp.
class Timestamped<T> {
  /// The value at the moment of the [timestamp]
  final T value;

  /// The time at which this snapshot was taken
  final DateTime timestamp;

  /// Constructs a snapshot of a [Stream], containing the [Stream]'s event
  /// at the specified [timestamp] as [value].
  Timestamped(this.timestamp, this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Timestamped &&
        timestamp == other.timestamp &&
        value == other.value;
  }

  @override
  int get hashCode {
    return timestamp.hashCode ^ value.hashCode;
  }

  @override
  String toString() {
    return 'TimeStamp{timestamp: $timestamp, value: $value}';
  }
}

/// Extends the Stream class with the ability to wrap each item emitted by the
/// source Stream in a [Timestamped] object that includes the emitted item and
/// the time when the item was emitted.
extension TimeStampExtension<T> on Stream<T> {
  /// Wraps each item emitted by the source Stream in a [Timestamped] object
  /// that includes the emitted item and the time when the item was emitted.
  ///
  /// Example
  ///
  ///     Stream.fromIterable([1])
  ///        .timestamp()
  ///        .listen((i) => print(i)); // prints 'TimeStamp{timestamp: XXX, value: 1}';
  Stream<Timestamped<T>> timestamp() =>
      transform(TimestampStreamTransformer<T>());
}
