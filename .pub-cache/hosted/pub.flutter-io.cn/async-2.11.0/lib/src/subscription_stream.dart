// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'delegate/stream_subscription.dart';

/// A [Stream] adapter for a [StreamSubscription].
///
/// This class allows a `StreamSubscription` to be treated as a `Stream`.
///
/// The subscription is paused until the stream is listened to,
/// then it is resumed and the events are passed on to the
/// stream's new subscription.
///
/// This class assumes that is has control over the original subscription.
/// If other code is accessing the subscription, results may be unpredictable.
class SubscriptionStream<T> extends Stream<T> {
  /// The subscription providing the events for this stream.
  StreamSubscription<T>? _source;

  /// Create a single-subscription `Stream` from [subscription].
  ///
  /// The `subscription` should not be paused. This class will not resume prior
  /// pauses, so being paused is indistinguishable from not providing any
  /// events.
  ///
  /// If the `subscription` doesn't send any `done` events, neither will this
  /// stream. That may be an issue if `subscription` was made to cancel on
  /// an error.
  SubscriptionStream(StreamSubscription<T> subscription)
      : _source = subscription {
    var source = _source!;
    source.pause();
    // Clear callbacks to avoid keeping them alive unnecessarily.
    source.onData(null);
    source.onError(null);
    source.onDone(null);
  }

  @override
  StreamSubscription<T> listen(void Function(T)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    var subscription = _source;
    if (subscription == null) {
      throw StateError('Stream has already been listened to.');
    }
    cancelOnError = (true == cancelOnError);
    _source = null;

    var result = cancelOnError
        ? _CancelOnErrorSubscriptionWrapper<T>(subscription)
        : subscription;
    result.onData(onData);
    result.onError(onError);
    result.onDone(onDone);
    subscription.resume();
    return result;
  }
}

/// Subscription wrapper that cancels on error.
///
/// Used by [SubscriptionStream] when forwarding a subscription
/// created with `cancelOnError` as `true` to one with (assumed)
/// `cancelOnError` as `false`. It automatically cancels the
/// source subscription on the first error.
class _CancelOnErrorSubscriptionWrapper<T>
    extends DelegatingStreamSubscription<T> {
  _CancelOnErrorSubscriptionWrapper(super.subscription);

  @override
  void onError(Function? handleError) {
    // Cancel when receiving an error.
    super.onError((error, StackTrace stackTrace) {
      // Wait for the cancel to complete before sending the error event.
      super.cancel().whenComplete(() {
        if (handleError is ZoneBinaryCallback) {
          handleError(error, stackTrace);
        } else if (handleError != null) {
          (handleError as ZoneUnaryCallback)(error);
        }
      });
    });
  }
}
