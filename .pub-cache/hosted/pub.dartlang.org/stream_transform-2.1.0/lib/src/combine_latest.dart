// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Utilities to combine events from multiple streams through a callback or into
/// a list.
extension CombineLatest<T> on Stream<T> {
  /// Combines the latest values from this stream with the latest values from
  /// [other] using [combine].
  ///
  /// No event will be emitted until both the source stream and [other] have
  /// each emitted at least one event. If either the source stream or [other]
  /// emit multiple events before the other emits the first event, all but the
  /// last value will be discarded. Once both streams have emitted at least
  /// once, the result stream will emit any time either input stream emits.
  ///
  /// The result stream will not close until both the source stream and [other]
  /// have closed.
  ///
  /// For example:
  ///
  ///     source.combineLatest(other, (a, b) => a + b);
  ///
  ///     source: --1--2--------4--|
  ///     other:  -------3--|
  ///     result: -------5------7--|
  ///
  /// Errors thrown by [combine], along with any errors on the source stream or
  /// [other], are forwarded to the result stream.
  ///
  /// If the source stream is a broadcast stream, the result stream will be as
  /// well, regardless of [other]'s type. If a single subscription stream is
  /// combined with a broadcast stream it may never be canceled.
  Stream<S> combineLatest<T2, S>(
      Stream<T2> other, FutureOr<S> Function(T, T2) combine) {
    final controller = isBroadcast
        ? StreamController<S>.broadcast(sync: true)
        : StreamController<S>(sync: true);

    other =
        (isBroadcast && !other.isBroadcast) ? other.asBroadcastStream() : other;

    StreamSubscription<T>? sourceSubscription;
    StreamSubscription<T2>? otherSubscription;

    var sourceDone = false;
    var otherDone = false;

    late T latestSource;
    late T2 latestOther;

    var sourceStarted = false;
    var otherStarted = false;

    void emitCombined() {
      if (!sourceStarted || !otherStarted) return;
      FutureOr<S> result;
      try {
        result = combine(latestSource, latestOther);
      } catch (e, s) {
        controller.addError(e, s);
        return;
      }
      if (result is Future<S>) {
        sourceSubscription!.pause();
        otherSubscription!.pause();
        result
            .then(controller.add, onError: controller.addError)
            .whenComplete(() {
          sourceSubscription!.resume();
          otherSubscription!.resume();
        });
      } else {
        controller.add(result);
      }
    }

    controller.onListen = () {
      assert(sourceSubscription == null);
      sourceSubscription = listen(
          (s) {
            sourceStarted = true;
            latestSource = s;
            emitCombined();
          },
          onError: controller.addError,
          onDone: () {
            sourceDone = true;
            if (otherDone) {
              controller.close();
            } else if (!sourceStarted) {
              // Nothing can ever be emitted
              otherSubscription!.cancel();
              controller.close();
            }
          });
      otherSubscription = other.listen(
          (o) {
            otherStarted = true;
            latestOther = o;
            emitCombined();
          },
          onError: controller.addError,
          onDone: () {
            otherDone = true;
            if (sourceDone) {
              controller.close();
            } else if (!otherStarted) {
              // Nothing can ever be emitted
              sourceSubscription!.cancel();
              controller.close();
            }
          });
      if (!isBroadcast) {
        controller
          ..onPause = () {
            sourceSubscription!.pause();
            otherSubscription!.pause();
          }
          ..onResume = () {
            sourceSubscription!.resume();
            otherSubscription!.resume();
          };
      }
      controller.onCancel = () {
        var cancels = [
          sourceSubscription!.cancel(),
          otherSubscription!.cancel()
        ]
          // Handle opt-out nulls
          ..removeWhere((Object? f) => f == null);
        sourceSubscription = null;
        otherSubscription = null;
        return Future.wait(cancels).then((_) => null);
      };
    };
    return controller.stream;
  }

  /// Combine the latest value emitted from the source stream with the latest
  /// values emitted from [others].
  ///
  /// [combineLatestAll] subscribes to the source stream and [others] and when
  /// any one of the streams emits, the result stream will emit a [List<T>] of
  /// the latest values emitted from all streams.
  ///
  /// No event will be emitted until all source streams emit at least once. If a
  /// source stream emits multiple values before another starts emitting, all
  /// but the last value will be discarded. Once all source streams have emitted
  /// at least once, the result stream will emit any time any source stream
  /// emits.
  ///
  /// The result stream will not close until all source streams have closed. When
  /// a source stream closes, the result stream will continue to emit the last
  /// value from the closed stream when the other source streams emit until the
  /// result stream has closed. If a source stream closes without emitting any
  /// value, the result stream will close as well.
  ///
  /// For example:
  ///
  ///     final combined = first
  ///         .combineLatestAll([second, third])
  ///         .map((data) => data.join());
  ///
  ///     first:    a----b------------------c--------d---|
  ///     second:   --1---------2-----------------|
  ///     third:    -------&----------%---|
  ///     combined: -------b1&--b2&---b2%---c2%------d2%-|
  ///
  /// Errors thrown by any source stream will be forwarded to the result stream.
  ///
  /// If the source stream is a broadcast stream, the result stream will be as
  /// well, regardless of the types of [others]. If a single subscription stream
  /// is combined with a broadcast source stream, it may never be canceled.
  Stream<List<T>> combineLatestAll(Iterable<Stream<T>> others) {
    final controller = isBroadcast
        ? StreamController<List<T>>.broadcast(sync: true)
        : StreamController<List<T>>(sync: true);

    final allStreams = [
      this,
      for (final other in others)
        !isBroadcast || other.isBroadcast ? other : other.asBroadcastStream(),
    ];

    controller.onListen = () {
      final subscriptions = <StreamSubscription<T>>[];

      final latestData = List<T?>.filled(allStreams.length, null);
      final hasEmitted = <int>{};
      void handleData(int index, T data) {
        latestData[index] = data;
        hasEmitted.add(index);
        if (hasEmitted.length == allStreams.length) {
          controller.add(List.from(latestData));
        }
      }

      var streamId = 0;
      for (final stream in allStreams) {
        final index = streamId;

        final subscription = stream.listen((data) => handleData(index, data),
            onError: controller.addError);
        subscription.onDone(() {
          assert(subscriptions.contains(subscription));
          subscriptions.remove(subscription);
          if (subscriptions.isEmpty || !hasEmitted.contains(index)) {
            controller.close();
          }
        });
        subscriptions.add(subscription);

        streamId++;
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
