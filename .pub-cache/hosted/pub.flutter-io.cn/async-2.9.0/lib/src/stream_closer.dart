// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

/// A [StreamTransformer] that allows the caller to forcibly close the
/// transformed [Stream](s).
///
/// When [close] is called, any stream (or streams) transformed by this
/// transformer that haven't already completed or been cancelled will emit a
/// done event and cancel their underlying subscriptions.
///
/// Note that unlike most [StreamTransformer]s, each instance of [StreamCloser]
/// has its own state (whether or not it's been closed), so it's a good idea to
/// construct a new one for each use unless you need to close multiple streams
/// at the same time.
@sealed
class StreamCloser<T> extends StreamTransformerBase<T, T> {
  /// The subscriptions to streams passed to [bind].
  final _subscriptions = <StreamSubscription<T>>{};

  /// The controllers for streams returned by [bind].
  final _controllers = <StreamController<T>>{};

  /// Closes all transformed streams.
  ///
  /// Returns a future that completes when all inner subscriptions'
  /// [StreamSubscription.cancel] futures have completed. Note that a stream's
  /// subscription won't be canceled until the transformed stream has a
  /// listener.
  ///
  /// If a transformed stream is listened to after [close] is called, the
  /// original stream will be listened to and then the subscription immediately
  /// canceled. If that cancellation throws an error, it will be silently
  /// ignored.
  Future<void> close() => _closeFuture ??= () {
        var futures = [
          for (var subscription in _subscriptions) subscription.cancel()
        ];
        _subscriptions.clear();

        var controllers = _controllers.toList();
        _controllers.clear();
        scheduleMicrotask(() {
          for (var controller in controllers) {
            scheduleMicrotask(controller.close);
          }
        });

        return Future.wait(futures, eagerError: true);
      }();
  Future<void>? _closeFuture;

  /// Whether [close] has been called.
  bool get isClosed => _closeFuture != null;

  @override
  Stream<T> bind(Stream<T> stream) {
    var controller = stream.isBroadcast
        ? StreamController<T>.broadcast(sync: true)
        : StreamController<T>(sync: true);

    controller.onListen = () {
      if (isClosed) {
        // Ignore errors here, because otherwise there would be no way for the
        // user to handle them gracefully.
        stream.listen(null).cancel().catchError((_) {});
        return;
      }

      var subscription =
          stream.listen(controller.add, onError: controller.addError);
      subscription.onDone(() {
        _subscriptions.remove(subscription);
        _controllers.remove(controller);
        controller.close();
      });
      _subscriptions.add(subscription);

      if (!stream.isBroadcast) {
        controller.onPause = subscription.pause;
        controller.onResume = subscription.resume;
      }

      controller.onCancel = () {
        _controllers.remove(controller);

        // If the subscription has already been removed, that indicates that the
        // underlying stream has been cancelled by [close] and its cancellation
        // future has been handled there. In that case, we shouldn't forward it
        // here as well.
        if (_subscriptions.remove(subscription)) return subscription.cancel();
        return null;
      };
    };

    if (isClosed) {
      controller.close();
    } else {
      _controllers.add(controller);
    }

    return controller.stream;
  }
}
