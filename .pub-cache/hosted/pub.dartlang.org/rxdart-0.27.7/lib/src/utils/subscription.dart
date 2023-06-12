import 'dart:async';

import 'package:rxdart/src/utils/future.dart';

/// @internal
/// Extensions for [Iterable] of [StreamSubscription]s.
extension StreamSubscriptionsIterableExtensions
    on Iterable<StreamSubscription<void>> {
  /// @internal
  /// Pause all subscriptions.
  void pauseAll([Future<void>? resumeSignal]) {
    for (final s in this) {
      s.pause(resumeSignal);
    }
  }

  /// @internal
  /// Resume all subscriptions.
  void resumeAll() {
    for (final s in this) {
      s.resume();
    }
  }
}

/// @internal
/// Extensions for [Iterable] of [StreamSubscription]s.
extension StreamSubscriptionsIterableExtension
    on Iterable<StreamSubscription<void>> {
  /// @internal
  /// Cancel all subscriptions.
  Future<void>? cancelAll() =>
      waitFuturesList([for (final s in this) s.cancel()]);
}
