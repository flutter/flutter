// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// A pool of streams whose events are unified and emitted through a central
/// stream.
class StreamPool<T> {
  /// The stream through which all events from streams in the pool are emitted.
  Stream<T> get stream => _controller.stream;
  final StreamController<T> _controller;

  /// Subscriptions to the streams that make up the pool.
  final _subscriptions = <Stream<T>, StreamSubscription<T>>{};

  /// Whether this pool should be closed when it becomes empty.
  bool _closeWhenEmpty = false;

  /// Creates a new stream pool that only supports a single subscriber.
  ///
  /// Any events from broadcast streams in the pool will be buffered until a
  /// listener is subscribed.
  StreamPool()
      // Create the controller as sync so that any sync input streams will be
      // forwarded synchronously. Async input streams will have their asynchrony
      // preserved, since _controller.add will be called asynchronously.
      : _controller = StreamController<T>(sync: true);

  /// Creates a new stream pool where [stream] can be listened to more than
  /// once.
  ///
  /// Any events from buffered streams in the pool will be emitted immediately,
  /// regardless of whether [stream] has any subscribers.
  StreamPool.broadcast()
      // Create the controller as sync so that any sync input streams will be
      // forwarded synchronously. Async input streams will have their asynchrony
      // preserved, since _controller.add will be called asynchronously.
      : _controller = StreamController<T>.broadcast(sync: true);

  /// Adds [stream] as a member of this pool.
  ///
  /// Any events from [stream] will be emitted through [this.stream]. If
  /// [stream] is sync, they'll be emitted synchronously; if [stream] is async,
  /// they'll be emitted asynchronously.
  void add(Stream<T> stream) {
    if (_subscriptions.containsKey(stream)) return;
    _subscriptions[stream] = stream.listen(_controller.add,
        onError: _controller.addError, onDone: () => remove(stream));
  }

  /// Removes [stream] as a member of this pool.
  void remove(Stream<T> stream) {
    var subscription = _subscriptions.remove(stream);
    if (subscription != null) subscription.cancel();
    if (_closeWhenEmpty && _subscriptions.isEmpty) close();
  }

  /// Removes all streams from this pool and closes [stream].
  void close() {
    for (var subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _controller.close();
  }

  /// The next time this pool becomes empty, close it.
  void closeWhenEmpty() {
    if (_subscriptions.isEmpty) close();
    _closeWhenEmpty = true;
  }
}
