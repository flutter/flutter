// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'switch.dart';

/// Alternatives to [asyncExpand].
///
/// The built in [asyncExpand] will not overlap the inner streams and every
/// event will be sent to the callback individually.
///
/// - [concurrentAsyncExpand] allow overlap and merges inner streams without
///   ordering guarantees.
extension AsyncExpand<T> on Stream<T> {
  /// Like [asyncExpand] but the [convert] callback may be called for an element
  /// before the [Stream] emitted by the previous element has closed.
  ///
  /// Events on the result stream will be emitted in the order they are emitted
  /// by the sub streams, which may not match the order of this stream.
  ///
  /// Errors from [convert], the source stream, or any of the sub streams are
  /// forwarded to the result stream.
  ///
  /// The result stream will not close until the source stream closes and all
  /// sub streams have closed.
  ///
  /// If the source stream is a broadcast stream, the result will be as well,
  /// regardless of the types of streams created by [convert]. In this case,
  /// some care should be taken:
  /// -  If [convert] returns a single subscription stream it may be listened to
  /// and never canceled.
  /// -  For any period of time where there are no listeners on the result
  /// stream, any sub streams from previously emitted events will be ignored,
  /// regardless of whether they emit further events after a listener is added
  /// back.
  ///
  /// See also:
  /// - [switchMap], which cancels subscriptions to the previous sub stream
  /// instead of concurrently emitting events from all sub streams.
  Stream<S> concurrentAsyncExpand<S>(Stream<S> Function(T) convert) {
    final controller = isBroadcast
        ? StreamController<S>.broadcast(sync: true)
        : StreamController<S>(sync: true);

    controller.onListen = () {
      final subscriptions = <StreamSubscription<dynamic>>[];
      final outerSubscription = map(convert).listen((inner) {
        if (isBroadcast && !inner.isBroadcast) {
          inner = inner.asBroadcastStream();
        }
        final subscription =
            inner.listen(controller.add, onError: controller.addError);
        subscription.onDone(() {
          subscriptions.remove(subscription);
          if (subscriptions.isEmpty) controller.close();
        });
        subscriptions.add(subscription);
      }, onError: controller.addError);
      outerSubscription.onDone(() {
        subscriptions.remove(outerSubscription);
        if (subscriptions.isEmpty) controller.close();
      });
      subscriptions.add(outerSubscription);
      if (!isBroadcast) {
        controller
          ..onPause = () {
            for (final subscription in subscriptions) {
              subscription.pause();
            }
          }
          ..onResume = () {
            for (final subscription in subscriptions) {
              subscription.resume();
            }
          };
      }
      controller.onCancel = () {
        if (subscriptions.isEmpty) return null;
        var cancels = [for (var s in subscriptions) s.cancel()]
          // Handle opt-out nulls
          ..removeWhere((Object? f) => f == null);
        return Future.wait(cancels).then((_) => null);
      };
    };
    return controller.stream;
  }
}
