// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

extension AggregateSample<T> on Stream<T> {
  /// Aggregates values and emits when it sees a value on [trigger].
  ///
  /// If there are no pending values when [trigger] emits, the next value on the
  /// source Stream will be passed to [aggregate] and emitted on the result
  /// stream immediately. Otherwise, the pending values are released when
  /// [trigger] emits.
  ///
  /// Errors from the source stream or the trigger are immediately forwarded to
  /// the output.
  Stream<S> aggregateSample<S>(
      Stream<void> trigger, S Function(T, S?) aggregate) {
    var controller = isBroadcast
        ? StreamController<S>.broadcast(sync: true)
        : StreamController<S>(sync: true);

    S? currentResults;
    var hasCurrentResults = false;
    var waitingForTrigger = true;
    var isTriggerDone = false;
    var isValueDone = false;
    StreamSubscription<T>? valueSub;
    StreamSubscription<void>? triggerSub;

    void emit() {
      controller.add(currentResults as S);
      currentResults = null;
      hasCurrentResults = false;
      waitingForTrigger = true;
    }

    void onValue(T value) {
      currentResults = aggregate(value, currentResults);
      hasCurrentResults = true;

      if (!waitingForTrigger) emit();

      if (isTriggerDone) {
        valueSub!.cancel();
        controller.close();
      }
    }

    void onValuesDone() {
      isValueDone = true;
      if (!hasCurrentResults) {
        triggerSub?.cancel();
        controller.close();
      }
    }

    void onTrigger(_) {
      waitingForTrigger = false;

      if (hasCurrentResults) emit();

      if (isValueDone) {
        triggerSub!.cancel();
        controller.close();
      }
    }

    void onTriggerDone() {
      isTriggerDone = true;
      if (waitingForTrigger) {
        valueSub?.cancel();
        controller.close();
      }
    }

    controller.onListen = () {
      assert(valueSub == null);
      valueSub =
          listen(onValue, onError: controller.addError, onDone: onValuesDone);
      final priorTriggerSub = triggerSub;
      if (priorTriggerSub != null) {
        if (priorTriggerSub.isPaused) priorTriggerSub.resume();
      } else {
        triggerSub = trigger.listen(onTrigger,
            onError: controller.addError, onDone: onTriggerDone);
      }
      if (!isBroadcast) {
        controller
          ..onPause = () {
            valueSub?.pause();
            triggerSub?.pause();
          }
          ..onResume = () {
            valueSub?.resume();
            triggerSub?.resume();
          };
      }
      controller.onCancel = () {
        var cancels = <Future<void>>[if (!isValueDone) valueSub!.cancel()];
        valueSub = null;
        if (trigger.isBroadcast || !isBroadcast) {
          if (!isTriggerDone) cancels.add(triggerSub!.cancel());
          triggerSub = null;
        } else {
          triggerSub!.pause();
        }
        // Handle opt-out nulls
        cancels.removeWhere((Object? f) => f == null);
        if (cancels.isEmpty) return null;
        return Future.wait(cancels).then((_) => null);
      };
    };
    return controller.stream;
  }
}
