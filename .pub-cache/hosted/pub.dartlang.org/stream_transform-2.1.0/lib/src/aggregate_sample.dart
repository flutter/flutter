// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

extension AggregateSample<T> on Stream<T> {
  /// Computes a value based on sequences of events, then emits that value when
  /// [trigger] emits an event.
  ///
  /// Every time this stream emits an event, an intermediate value is created
  /// by combining the new event with the previous intermediate value, or with
  /// `null` if there is no previous value, using the [aggregate] function.
  ///
  /// When [trigger] emits value, the returned stream emits the current
  /// intermediate value and clears it.
  ///
  /// If [longPoll] is `false`, if there is no intermediate value when [trigger]
  /// emits an event, the [onEmpty] function is called with a [Sink] which can
  /// add events to the returned stream.
  ///
  /// If [longPoll] is `true`, and there is no intermediate value when [trigger]
  /// emits one or more events, then the *next* event from this stream is
  /// immediately put through [aggregate] and emitted on the returned stream.
  /// Subsequent events on [trigger] while there have been no events on this
  /// stream are ignored.
  /// In that case, [onEmpty] is never used.
  ///
  /// The result stream will close as soon as there is a guarantee it will not
  /// emit any more events. There will not be any more events emitted if:
  /// - [trigger] is closed and there is no waiting long poll.
  /// - Or, the source stream is closed and there are no buffered events.
  ///
  /// If the source stream is a broadcast stream, the result will be as well.
  /// Errors from the source stream or the trigger are immediately forwarded to
  /// the output.
  Stream<S> aggregateSample<S>(
      {required Stream<void> trigger,
      required S Function(T, S?) aggregate,
      required bool longPoll,
      required void Function(Sink<S>) onEmpty}) {
    var controller = isBroadcast
        ? StreamController<S>.broadcast(sync: true)
        : StreamController<S>(sync: true);

    S? currentResults;
    var hasCurrentResults = false;
    var activeLongPoll = false;
    var isTriggerDone = false;
    var isValueDone = false;
    StreamSubscription<T>? valueSub;
    StreamSubscription<void>? triggerSub;

    void emit(S results) {
      currentResults = null;
      hasCurrentResults = false;
      controller.add(results);
    }

    void onValue(T value) {
      currentResults = aggregate(value, currentResults);
      hasCurrentResults = true;
      if (!longPoll) return;

      if (activeLongPoll) {
        activeLongPoll = false;
        emit(currentResults as S);
      }

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
      if (hasCurrentResults) {
        emit(currentResults as S);
      } else if (longPoll) {
        activeLongPoll = true;
      } else {
        onEmpty(controller);
      }

      if (isValueDone) {
        triggerSub!.cancel();
        controller.close();
      }
    }

    void onTriggerDone() {
      isTriggerDone = true;
      if (!activeLongPoll) {
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
