// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

typedef ItemProcessor<T> = Future<void> Function(T item);

/// A queue of items that are sequentially, asynchronously processed.
///
/// Unlike [Stream.map] or [Stream.forEach], the callback used to process each
/// item returns a [Future], and it will not advance to the next item until the
/// current item is finished processing.
///
/// Items can be added at any point in time and processing will be started as
/// needed. When all items are processed, it stops processing until more items
/// are added.
class AsyncQueue<T> {
  final _items = Queue<T>();

  /// Whether or not the queue is currently waiting on a processing future to
  /// complete.
  bool _isProcessing = false;

  /// The callback to invoke on each queued item.
  ///
  /// The next item in the queue will not be processed until the [Future]
  /// returned by this completes.
  final ItemProcessor<T> _processor;

  /// The handler for errors thrown during processing.
  ///
  /// Used to avoid top-leveling asynchronous errors.
  final void Function(Object, StackTrace) _errorHandler;

  AsyncQueue(this._processor,
      {required void Function(Object, StackTrace) onError})
      : _errorHandler = onError;

  /// Enqueues [item] to be processed and starts asynchronously processing it
  /// if a process isn't already running.
  void add(T item) {
    _items.add(item);

    // Start up the asynchronous processing if not already running.
    if (_isProcessing) return;
    _isProcessing = true;

    _processNextItem().catchError(_errorHandler);
  }

  /// Removes all remaining items to be processed.
  void clear() {
    _items.clear();
  }

  /// Pulls the next item off [_items] and processes it.
  ///
  /// When complete, recursively calls itself to continue processing unless
  /// the process was cancelled.
  Future<void> _processNextItem() async {
    var item = _items.removeFirst();
    await _processor(item);
    if (_items.isNotEmpty) return _processNextItem();

    // We have drained the queue, stop processing and wait until something
    // has been enqueued.
    _isProcessing = false;
  }
}
