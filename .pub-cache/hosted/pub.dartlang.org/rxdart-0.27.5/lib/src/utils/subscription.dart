import 'dart:async';
import 'dart:collection';

/// Extensions for [Iterable] of [StreamSubscription]s.
extension StreamSubscriptionsIterableExtensions
    on Iterable<StreamSubscription<void>> {
  /// Pause all subscriptions.
  void pauseAll([Future<void>? resumeSignal]) {
    for (final s in this) {
      s.pause(resumeSignal);
    }
  }

  /// Resume all subscriptions.
  void resumeAll() {
    for (final s in this) {
      s.resume();
    }
  }
}

/// Extensions for [List] of [StreamSubscription]s.
extension StreamSubscriptionsListExtension on List<StreamSubscription<void>> {
  /// Cancel all subscriptions.
  Future<void>? cancelAll() {
    if (isEmpty) {
      return null;
    }
    if (length == 1) {
      return this[0].cancel();
    }
    return Future.wait(map((s) => s.cancel())).then((_) => null);
  }
}

/// Extensions for [Queue] of [StreamSubscription]s.
extension StreamSubscriptionsQueueExtension on Queue<StreamSubscription<void>> {
  /// Cancel all subscriptions.
  Future<void>? cancelAll() {
    if (isEmpty) {
      return null;
    }
    if (length == 1) {
      return first.cancel();
    }
    return Future.wait(map((s) => s.cancel())).then((value) => null);
  }
}
