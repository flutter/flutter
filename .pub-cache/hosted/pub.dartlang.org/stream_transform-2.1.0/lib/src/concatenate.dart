// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Utilities to append or prepend to a stream.
extension Concatenate<T> on Stream<T> {
  /// Emits all values and errors from [next] following all values and errors
  /// from this stream.
  ///
  /// If this stream never finishes, the [next] stream will never get a
  /// listener.
  ///
  /// If this stream is a broadcast stream, the result will be as well.
  /// If a single-subscription follows a broadcast stream it may be listened
  /// to and never canceled since there may be broadcast listeners added later.
  ///
  /// If a broadcast stream follows any other stream it will miss any events or
  /// errors which occur before this stream is done.
  /// If a broadcast stream follows a single-subscription stream, pausing the
  /// stream while it is listening to the second stream will cause events to be
  /// dropped rather than buffered.
  Stream<T> followedBy(Stream<T> next) {
    var controller = isBroadcast
        ? StreamController<T>.broadcast(sync: true)
        : StreamController<T>(sync: true);

    next = isBroadcast && !next.isBroadcast ? next.asBroadcastStream() : next;

    StreamSubscription<T>? subscription;
    var currentStream = this;
    var thisDone = false;
    var secondDone = false;

    late void Function() currentDoneHandler;

    void listen() {
      subscription = currentStream.listen(controller.add,
          onError: controller.addError, onDone: () => currentDoneHandler());
    }

    void onSecondDone() {
      secondDone = true;
      controller.close();
    }

    void onThisDone() {
      thisDone = true;
      currentStream = next;
      currentDoneHandler = onSecondDone;
      listen();
    }

    currentDoneHandler = onThisDone;

    controller.onListen = () {
      assert(subscription == null);
      listen();
      if (!isBroadcast) {
        controller
          ..onPause = () {
            if (!thisDone || !next.isBroadcast) return subscription!.pause();
            subscription!.cancel();
            subscription = null;
          }
          ..onResume = () {
            if (!thisDone || !next.isBroadcast) return subscription!.resume();
            listen();
          };
      }
      controller.onCancel = () {
        if (secondDone) return null;
        var toCancel = subscription!;
        subscription = null;
        return toCancel.cancel();
      };
    };
    return controller.stream;
  }

  /// Emits [initial] before any values or errors from the this stream.
  ///
  /// If this stream is a broadcast stream the result will be as well.
  Stream<T> startWith(T initial) =>
      startWithStream(Future.value(initial).asStream());

  /// Emits all values in [initial] before any values or errors from this
  /// stream.
  ///
  /// If this stream is a broadcast stream the result will be as well.
  /// If this stream is a broadcast stream it will miss any events which
  /// occur before the initial values are all emitted.
  Stream<T> startWithMany(Iterable<T> initial) =>
      startWithStream(Stream.fromIterable(initial));

  /// Emits all values and errors in [initial] before any values or errors from
  /// this stream.
  ///
  /// If this stream is a broadcast stream the result will be as well.
  /// If this stream is a broadcast stream it will miss any events which occur
  /// before [initial] closes.
  Stream<T> startWithStream(Stream<T> initial) {
    if (isBroadcast && !initial.isBroadcast) {
      initial = initial.asBroadcastStream();
    }
    return initial.followedBy(this);
  }
}
