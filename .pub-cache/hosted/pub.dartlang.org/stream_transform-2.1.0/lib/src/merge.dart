// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Utilities to interleave events from multiple streams.
extension Merge<T> on Stream<T> {
  /// Merges values and errors from this stream and [other] in any order as they
  /// arrive.
  ///
  /// The result stream will not close until both this stream and [other] have
  /// closed.
  ///
  /// For example:
  ///
  ///     final result = source.merge(other);
  ///
  ///     source:  1--2-----3--|
  ///     other:   ------4-------5--|
  ///     result:  1--2--4--3----5--|
  ///
  /// If this stream is a broadcast stream, the result stream will be as
  /// well, regardless of [other]'s type. If a single subscription stream is
  /// merged into a broadcast stream it may never be canceled since there may be
  /// broadcast listeners added later.
  ///
  /// If a broadcast stream is merged into a single-subscription stream any
  /// events emitted by [other] before the result stream has a subscriber will
  /// be discarded.
  Stream<T> merge(Stream<T> other) => mergeAll([other]);

  /// Merges values and errors from this stream and any stream in [others] in
  /// any order as they arrive.
  ///
  /// The result stream will not close until this stream and all streams
  /// in [others] have closed.
  ///
  /// For example:
  ///
  ///     final result = first.mergeAll([second, third]);
  ///
  ///     first:   1--2--------3--|
  ///     second:  ---------4-------5--|
  ///     third:   ------6---------------7--|
  ///     result:  1--2--6--4--3----5----7--|
  ///
  /// If this stream is a broadcast stream, the result stream will be as
  /// well, regardless the types of streams in [others]. If a single
  /// subscription stream is merged into a broadcast stream it may never be
  /// canceled since there may be broadcast listeners added later.
  ///
  /// If a broadcast stream is merged into a single-subscription stream any
  /// events emitted by that stream before the result stream has a subscriber
  /// will be discarded.
  Stream<T> mergeAll(Iterable<Stream<T>> others) {
    final controller = isBroadcast
        ? StreamController<T>.broadcast(sync: true)
        : StreamController<T>(sync: true);

    final allStreams = [
      this,
      for (final other in others)
        !isBroadcast || other.isBroadcast ? other : other.asBroadcastStream(),
    ];

    controller.onListen = () {
      final subscriptions = <StreamSubscription<T>>[];
      for (final stream in allStreams) {
        final subscription =
            stream.listen(controller.add, onError: controller.addError);
        subscription.onDone(() {
          subscriptions.remove(subscription);
          if (subscriptions.isEmpty) controller.close();
        });
        subscriptions.add(subscription);
      }
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
        if (cancels.isEmpty) return null;
        return Future.wait(cancels).then((_) => null);
      };
    };
    return controller.stream;
  }
}
