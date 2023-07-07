// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stream_transform/src/merge.dart';

/// A utility to take events from the most recent sub stream returned by a
/// callback.
extension Switch<T> on Stream<T> {
  /// Maps events to a Stream and emits values from the most recently created
  /// Stream.
  ///
  /// When the source emits a value it will be converted to a [Stream] using
  /// [convert] and the output will switch to emitting events from that result.
  /// Like [asyncExpand] but the [Stream] emitted by a previous element
  /// will be ignored as soon as the source stream emits a new event.
  ///
  /// This means that the source stream is not paused until a sub stream
  /// returned from the [convert] callback is done. Instead, the subscription
  /// to the sub stream is canceled as soon as the source stream emits a new event.
  ///
  /// Errors from [convert], the source stream, or any of the sub streams are
  /// forwarded to the result stream.
  ///
  /// The result stream will not close until the source stream closes and
  /// the current sub stream have closed.
  ///
  /// If the source stream is a broadcast stream, the result will be as well,
  /// regardless of the types of streams created by [convert]. In this case,
  /// some care should be taken:
  ///
  ///  * If [convert] returns a single subscription stream it may be listened to
  /// and never canceled.
  ///
  /// See also:
  ///
  /// * [concurrentAsyncExpand], which emits events from all sub streams
  ///   concurrently instead of cancelling subscriptions to previous subs streams.
  Stream<S> switchMap<S>(Stream<S> Function(T) convert) {
    return map(convert).switchLatest();
  }
}

/// A utility to take events from the most recent sub stream.
extension SwitchLatest<T> on Stream<Stream<T>> {
  /// Emits values from the most recently emitted Stream.
  ///
  /// When the source emits a stream the output will switch to emitting events
  /// from that stream.
  ///
  /// If the source stream is a broadcast stream, the result stream will be as
  /// well, regardless of the types of streams emitted.
  Stream<T> switchLatest() {
    var controller = isBroadcast
        ? StreamController<T>.broadcast(sync: true)
        : StreamController<T>(sync: true);

    controller.onListen = () {
      StreamSubscription<T>? innerSubscription;
      var outerStreamDone = false;

      final outerSubscription = listen(
          (innerStream) {
            innerSubscription?.cancel();
            innerSubscription = innerStream.listen(controller.add,
                onError: controller.addError, onDone: () {
              innerSubscription = null;
              if (outerStreamDone) controller.close();
            });
          },
          onError: controller.addError,
          onDone: () {
            outerStreamDone = true;
            if (innerSubscription == null) controller.close();
          });
      if (!isBroadcast) {
        controller
          ..onPause = () {
            innerSubscription?.pause();
            outerSubscription.pause();
          }
          ..onResume = () {
            innerSubscription?.resume();
            outerSubscription.resume();
          };
      }
      controller.onCancel = () {
        var cancels = [
          if (!outerStreamDone) outerSubscription.cancel(),
          if (innerSubscription != null) innerSubscription!.cancel(),
        ]
          // Handle opt-out nulls
          ..removeWhere((Object? f) => f == null);
        if (cancels.isEmpty) return null;
        return Future.wait(cancels).then((_) => null);
      };
    };
    return controller.stream;
  }
}
