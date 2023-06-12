import 'dart:async';

import 'package:rxdart/src/streams/timer.dart';
import 'package:rxdart/src/transformers/backpressure/backpressure.dart';

/// A [StreamTransformer] that emits a value from the source [Stream],
/// then ignores subsequent source values while the window [Stream] is open,
/// then repeats this process.
///
/// If leading is true, then the first item in each window is emitted.
/// If trailing is true, then the last item in each window is emitted.
///
/// ### Example
///
///     Stream.fromIterable([1, 2, 3])
///       .transform(ThrottleStreamTransformer((_) => TimerStream(true, const Duration(seconds: 1))))
///       .listen(print); // prints 1
class ThrottleStreamTransformer<T> extends BackpressureStreamTransformer<T, T> {
  /// Construct a [StreamTransformer] that emits a value from the source [Stream],
  /// then ignores subsequent source values while the window [Stream] is open,
  /// then repeats this process.
  ///
  /// If [leading] is true, then the first item in each window is emitted.
  /// If [trailing] is true, then the last item in each window is emitted.
  ThrottleStreamTransformer(
    Stream Function(T event) window, {
    bool trailing = false,
    bool leading = true,
  }) : super(WindowStrategy.eventAfterLastWindow, window,
            onWindowStart: leading ? (event) => event : null,
            onWindowEnd: trailing ? (Iterable<T> queue) => queue.last : null,
            dispatchOnClose: trailing) {
    assert(window != null, 'window stream factory cannot be null');
  }
}

/// Extends the Stream class with the ability to throttle events in various ways
extension ThrottleExtensions<T> on Stream<T> {
  /// Emits a value from the source [Stream], then ignores subsequent source values
  /// while the window [Stream] is open, then repeats this process.
  ///
  /// If leading is true, then the first item in each window is emitted.
  /// If trailing is true, then the last item in each window is emitted.
  ///
  /// You can use the value of the last throttled event to determine the length
  /// of the next [window].
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3])
  ///       .throttle((_) => TimerStream(true, Duration(seconds: 1)))
  Stream<T> throttle(Stream Function(T event) window,
          {bool trailing = false, bool leading = true}) =>
      transform(
        ThrottleStreamTransformer<T>(
          window,
          trailing: trailing,
          leading: leading,
        ),
      );

  /// Emits a value from the source [Stream], then ignores subsequent source values
  /// for a duration, then repeats this process.
  ///
  /// If leading is true, then the first item in each window is emitted.
  /// If [trailing] is true, then the last item is emitted instead.
  ///
  /// ### Example
  ///
  ///     Stream.fromIterable([1, 2, 3])
  ///       .throttleTime(Duration(seconds: 1))
  Stream<T> throttleTime(Duration duration,
      {bool trailing = false, bool leading = true}) {
    ArgumentError.checkNotNull(duration, 'duration');
    return transform(
      ThrottleStreamTransformer<T>(
        (_) => TimerStream<bool>(true, duration),
        trailing: trailing,
        leading: leading,
      ),
    );
  }
}
