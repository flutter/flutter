// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.async;

/// A countdown timer that can be configured to fire once or repeatedly.
///
/// The timer counts down from the specified duration to 0.
/// When the timer reaches 0, the timer invokes the specified callback function.
/// Use a periodic timer to repeatedly count down the same interval.
///
/// A negative duration is treated the same as [Duration.zero].
/// If the duration is statically known to be 0, consider using [run].
///
/// ```dart
/// void main() {
///   Timer(const Duration(seconds: 5), handleTimeout);
/// }
///
/// void handleTimeout() {  // callback function
///   // Do some work.
/// }
/// ```
/// **Note:** If Dart code using [Timer] is compiled to JavaScript, the finest
/// granularity available in the browser is 4 milliseconds.
///
/// See also:
/// * [Stopwatch] for measuring elapsed time.
@vmIsolateUnsendable
abstract interface class Timer {
  /// Creates a new timer.
  ///
  /// The [callback] function is invoked after the given [duration].
  ///
  /// Example:
  /// ```dart
  /// final timer =
  ///     Timer(const Duration(seconds: 5), () => print('Timer finished'));
  /// // Outputs after 5 seconds: "Timer finished".
  /// ```
  factory Timer(Duration duration, void Function() callback) {
    if (Zone.current == Zone.root) {
      // No need to bind the callback. We know that the root's timer will
      // be invoked in the root zone.
      return Zone.current.createTimer(duration, callback);
    }
    return Zone.current
        .createTimer(duration, Zone.current.bindCallbackGuarded(callback));
  }

  /// Creates a new repeating timer.
  ///
  /// The [callback] is invoked repeatedly with [duration] intervals until
  /// canceled with the [cancel] function.
  ///
  /// The exact timing depends on the underlying timer implementation.
  /// No more than `n` callbacks will be made in `duration * n` time,
  /// but the time between two consecutive callbacks
  /// can be shorter and longer than `duration`.
  ///
  /// In particular, an implementation may schedule the next callback, e.g.,
  /// a `duration` after either when the previous callback ended,
  /// when the previous callback started, or when the previous callback was
  /// scheduled for - even if the actual callback was delayed.
  ///
  /// A negative [duration] is treated the same as [Duration.zero].
  ///
  /// Example:
  /// ```dart
  /// var counter = 3;
  /// Timer.periodic(const Duration(seconds: 2), (timer) {
  ///   print(timer.tick);
  ///   counter--;
  ///   if (counter == 0) {
  ///     print('Cancel timer');
  ///     timer.cancel();
  ///   }
  /// });
  /// // Outputs:
  /// // 1
  /// // 2
  /// // 3
  /// // "Cancel timer"
  /// ```
  factory Timer.periodic(Duration duration, void callback(Timer timer)) {
    if (Zone.current == Zone.root) {
      // No need to bind the callback. We know that the root's timer will
      // be invoked in the root zone.
      return Zone.current.createPeriodicTimer(duration, callback);
    }
    var boundCallback = Zone.current.bindUnaryCallbackGuarded<Timer>(callback);
    return Zone.current.createPeriodicTimer(duration, boundCallback);
  }

  /// Runs the given [callback] asynchronously as soon as possible.
  ///
  /// This function is equivalent to `new Timer(Duration.zero, callback)`.
  ///
  /// Example:
  /// ```dart
  /// Timer.run(() => print('timer run'));
  /// ```
  static void run(void Function() callback) {
    new Timer(Duration.zero, callback);
  }

  /// Cancels the timer.
  ///
  /// Once a [Timer] has been canceled, the callback function will not be called
  /// by the timer. Calling [cancel] more than once on a [Timer] is allowed, and
  /// will have no further effect.
  ///
  /// Example:
  /// ```dart
  /// final timer =
  ///     Timer(const Duration(seconds: 5), () => print('Timer finished'));
  /// // Cancel timer, callback never called.
  /// timer.cancel();
  /// ```
  void cancel();

  /// The number of durations preceding the most recent timer event.
  ///
  /// The value starts at zero and is incremented each time a timer event
  /// occurs, so each callback will see a larger value than the previous one.
  ///
  /// If a periodic timer with a non-zero duration is delayed too much,
  /// so more than one tick should have happened,
  /// all but the last tick in the past are considered "missed",
  /// and no callback is invoked for them.
  /// The [tick] count reflects the number of durations that have passed and
  /// not the number of callback invocations that have happened.
  ///
  /// Example:
  /// ```dart
  /// final stopwatch = Stopwatch()..start();
  /// Timer.periodic(const Duration(seconds: 1), (timer) {
  ///   print(timer.tick);
  ///   if (timer.tick == 1) {
  ///     while (stopwatch.elapsedMilliseconds < 4500) {
  ///       // Run uninterrupted for another 3.5 seconds!
  ///       // The latest due tick after that is the 4-second tick.
  ///     }
  ///   } else {
  ///     timer.cancel();
  ///   }
  /// });
  /// // Outputs:
  /// // 1
  /// // 4
  /// ```
  int get tick;

  /// Returns whether the timer is still active.
  ///
  /// A non-periodic timer is active if the callback has not been executed,
  /// and the timer has not been canceled.
  ///
  /// A periodic timer is active if it has not been canceled.
  bool get isActive;

  external static Timer _createTimer(
      Duration duration, void Function() callback);
  external static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer));
}
