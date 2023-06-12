// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A utility to end a stream based on an external trigger.
extension TakeUntil<T> on Stream<T> {
  /// Takes values from this stream which are emitted before [trigger]
  /// completes.
  ///
  /// Completing [trigger] differs from canceling a subscription in that values
  /// which are emitted before the trigger, but have further asynchronous delays
  /// in transformations following the takeUtil, will still go through.
  /// Cancelling a subscription immediately stops values.
  Stream<T> takeUntil(Future<void> trigger) {
    var controller = isBroadcast
        ? StreamController<T>.broadcast(sync: true)
        : StreamController<T>(sync: true);

    StreamSubscription<T>? subscription;
    var isDone = false;
    trigger.then((_) {
      if (isDone) return;
      isDone = true;
      subscription?.cancel();
      controller.close();
    });

    controller.onListen = () {
      if (isDone) return;
      subscription =
          listen(controller.add, onError: controller.addError, onDone: () {
        if (isDone) return;
        isDone = true;
        controller.close();
      });
      if (!isBroadcast) {
        controller
          ..onPause = subscription!.pause
          ..onResume = subscription!.resume;
      }
      controller.onCancel = () {
        if (isDone) return null;
        var toCancel = subscription!;
        subscription = null;
        return toCancel.cancel();
      };
    };
    return controller.stream;
  }
}
