import 'dart:async';

import 'package:rxdart/src/utils/forwarding_sink.dart';
import 'package:rxdart/src/utils/forwarding_stream.dart';

class _TimeIntervalStreamSink<S> implements ForwardingSink<S, TimeInterval<S>> {
  final _stopwatch = Stopwatch();

  @override
  void add(EventSink<TimeInterval<S>> sink, S data) {
    _stopwatch.stop();
    sink.add(
      TimeInterval<S>(
        data,
        Duration(
          microseconds: _stopwatch.elapsedMicroseconds,
        ),
      ),
    );
    _stopwatch
      ..reset()
      ..start();
  }

  @override
  void addError(EventSink<TimeInterval<S>> sink, dynamic e, [st]) =>
      sink.addError(e, st);

  @override
  void close(EventSink<TimeInterval<S>> sink) => sink.close();

  @override
  FutureOr onCancel(EventSink<TimeInterval<S>> sink) {}

  @override
  void onListen(EventSink<TimeInterval<S>> sink) => _stopwatch.start();

  @override
  void onPause(EventSink<TimeInterval<S>> sink) {}

  @override
  void onResume(EventSink<TimeInterval<S>> sink) {}
}

/// Records the time interval between consecutive values in an stream
/// sequence.
///
/// ### Example
///
///     Stream.fromIterable([1])
///       .transform(IntervalStreamTransformer(Duration(seconds: 1)))
///       .transform(TimeIntervalStreamTransformer())
///       .listen(print); // prints TimeInterval{interval: 0:00:01, value: 1}
class TimeIntervalStreamTransformer<S>
    extends StreamTransformerBase<S, TimeInterval<S>> {
  /// Constructs a [StreamTransformer] which emits events from the
  /// source [Stream] as snapshots in the form of [TimeInterval].
  TimeIntervalStreamTransformer();

  @override
  Stream<TimeInterval<S>> bind(Stream<S> stream) =>
      forwardStream(stream, _TimeIntervalStreamSink());
}

/// A class that represents a snapshot of the current value emitted by a
/// [Stream], at a specified interval.
class TimeInterval<T> {
  /// The interval at which this snapshot was taken
  final Duration interval;

  /// The value at the moment of [interval]
  final T value;

  /// Constructs a snapshot of a [Stream], containing the [Stream]'s event
  /// at the specified [interval] as [value].
  TimeInterval(this.value, this.interval);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TimeInterval &&
        interval == other.interval &&
        value == other.value;
  }

  @override
  int get hashCode {
    return interval.hashCode ^ value.hashCode;
  }

  @override
  String toString() {
    return 'TimeInterval{interval: $interval, value: $value}';
  }
}

/// Extends the Stream class with the ability to record the time interval
/// between consecutive values in an stream
extension TimeIntervalExtension<T> on Stream<T> {
  /// Records the time interval between consecutive values in a Stream sequence.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1])
  ///       .interval(Duration(seconds: 1))
  ///       .timeInterval()
  ///       .listen(print); // prints TimeInterval{interval: 0:00:01, value: 1}
  Stream<TimeInterval<T>> timeInterval() =>
      transform(TimeIntervalStreamTransformer<T>());
}
