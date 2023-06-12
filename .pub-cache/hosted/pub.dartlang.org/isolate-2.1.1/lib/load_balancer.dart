// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A load-balancing runner pool.
library isolate.load_balancer;

import 'dart:async' show Completer, FutureOr;

import 'runner.dart';
import 'src/errors.dart';
import 'src/util.dart';

/// A pool of runners, ordered by load.
///
/// Keeps a pool of runners,
/// and allows running function through the runner with the lowest current load.
///
/// The number of pool runner entries is fixed when the pool is created.
/// When the pool is [close]d, all runners are closed as well.
///
/// The load balancer is not reentrant.
/// Executing a [run] function should not *synchronously*
/// call methods on the load balancer.
class LoadBalancer implements Runner {
  /// A stand-in future which can be used as a default value.
  ///
  /// The future never completes, so it should not be exposed to users.
  static final _defaultFuture = Completer<Never>().future;

  /// Reusable empty fixed-length list.
  static final _emptyQueue = List<_LoadBalancerEntry>.empty(growable: false);

  /// A heap-based priority queue of entries, prioritized by `load`.
  ///
  /// The entries of the list never change, only their positions.
  /// Those with positions below `_length`
  /// are considered to currently be in the queue.
  /// All operations except [close] should end up with all entries
  /// still in the pool. Some entries may be removed temporarily in order
  /// to change their load and then add them back.
  ///
  /// Each [_LoadBalancerEntry] has its current position in the queue
  /// as [_LoadBalancerEntry.queueIndex].
  ///
  /// Is set to an empty list on clear.
  List<_LoadBalancerEntry> _queue;

  /// Current number of elements in [_queue].
  ///
  /// Always a number between zero and [_queue.length].
  /// Elements with indices below this value are
  /// in the queue, and maintain the heap invariant.
  /// Elements with indices above this value are temporarily
  /// removed from the queue and are ordered by when they
  /// were removed.
  int _length;

  /// The future returned by [stop].
  ///
  /// Is `null` until [stop] is first called.
  Future<void>? _stopFuture;

  /// Create a load balancer backed by the [Runner]s of [runners].
  LoadBalancer(Iterable<Runner> runners) : this._(_createEntries(runners));

  LoadBalancer._(List<_LoadBalancerEntry> entries)
      : _queue = entries,
        _length = entries.length;

  /// The number of runners currently in the pool.
  int get length => _length;

  /// Asynchronously create [size] runners and create a `LoadBalancer` of those.
  ///
  /// This is a helper function that makes it easy to create a `LoadBalancer`
  /// with asynchronously created runners, for example:
  /// ```dart
  /// var isolatePool = LoadBalancer.create(10, IsolateRunner.spawn);
  /// ```
  static Future<LoadBalancer> create(
      int size, Future<Runner> Function() createRunner) {
    return Future.wait(Iterable.generate(size, (_) => createRunner()),
        cleanUp: (Runner runner) {
      runner.close();
    }).then((runners) => LoadBalancer(runners));
  }

  static List<_LoadBalancerEntry> _createEntries(Iterable<Runner> runners) {
    var index = 0;
    return runners
        .map((runner) => _LoadBalancerEntry(runner, index++))
        .toList(growable: false);
  }

  /// Execute the command in the currently least loaded isolate.
  ///
  /// The optional [load] parameter represents the load that the command
  /// is causing on the isolate where it runs.
  /// The number has no fixed meaning, but should be seen as relative to
  /// other commands run in the same load balancer.
  /// The `load` must not be negative.
  ///
  /// If [timeout] and [onTimeout] are provided, they are forwarded to
  /// the runner running the function, which will handle a timeout
  /// as normal. If the runners are running in other isolates, then
  /// the [onTimeout] function must be a constant function.
  @override
  Future<R> run<R, P>(FutureOr<R> Function(P argument) function, P argument,
      {Duration? timeout, FutureOr<R> Function()? onTimeout, int load = 100}) {
    RangeError.checkNotNegative(load, 'load');
    if (_length == 0) {
      // Can happen if created with zero runners,
      // or after being closed.
      if (_stopFuture != null) {
        throw StateError("Load balancer has been closed");
      }
      throw StateError("No runners in pool");
    }
    var entry = _queue.first;
    entry.load += load;
    _bubbleDown(entry, 0);
    return entry.run(this, load, function, argument, timeout, onTimeout);
  }

  /// Execute the same function in the least loaded [count] isolates.
  ///
  /// This guarantees that the function isn't run twice in the same isolate,
  /// so `count` is not allowed to exceed [length].
  ///
  /// The optional [load] parameter represents the load that the command
  /// is causing on the isolate where it runs.
  /// The number has no fixed meaning, but should be seen as relative to
  /// other commands run in the same load balancer.
  /// The `load` must not be negative.
  ///
  /// If [timeout] and [onTimeout] are provided, they are forwarded to
  /// the runners running the function, which will handle any timeouts
  /// as normal.
  List<Future<R>> runMultiple<R, P>(
      int count, FutureOr<R> Function(P argument) function, P argument,
      {Duration? timeout, FutureOr<R> Function()? onTimeout, int load = 100}) {
    RangeError.checkValueInInterval(count, 1, _length, 'count');
    RangeError.checkNotNegative(load, 'load');
    if (count == 1) {
      return List<Future<R>>.filled(
          1,
          run(function, argument,
              load: load, timeout: timeout, onTimeout: onTimeout));
    }
    var result = List<Future<R>>.filled(count, _defaultFuture);
    if (count == _length) {
      // No need to change the order of entries in the queue.
      for (var i = 0; i < _length; i++) {
        var entry = _queue[i];
        entry.load += load;
        result[i] =
            entry.run(this, load, function, argument, timeout, onTimeout);
      }
    } else {
      // Remove the [count] least loaded services and run the
      // command on each, then add them back to the queue.
      for (var i = 0; i < count; i++) {
        _removeFirst();
      }
      // The removed entries are stored in `_queue` in positions from
      // `_length` to `_length + count - 1`.
      for (var i = 0; i < count; i++) {
        var entry = _queue[_length];
        entry.load += load;
        _addNext();
        result[i] =
            entry.run(this, load, function, argument, timeout, onTimeout);
      }
    }
    return result;
  }

  @override
  Future<void> close() {
    var stopFuture = _stopFuture;
    if (stopFuture != null) return stopFuture;
    var queue = _queue;
    var length = _length;
    _queue = _emptyQueue;
    _length = 0;
    return _stopFuture = MultiError.waitUnordered(
      [for (var i = 0; i < length; i++) queue[i].close()],
    ).then(ignore);
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has higher priority than the
  /// parent, swap it with the parent.
  ///
  /// Ignores [element]'s initial [_LoadBalancerEntry.queueIndex],
  /// but sets it to the final position when the element has
  /// been placed.
  void _bubbleUp(_LoadBalancerEntry element, int index) {
    while (index > 0) {
      var parentIndex = (index - 1) ~/ 2;
      var parent = _queue[parentIndex];
      if (element.compareTo(parent) > 0) break;
      _queue[index] = parent..queueIndex = index;
      index = parentIndex;
    }
    _queue[index] = element..queueIndex = index;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has lower priority than either child,
  /// swap it with the highest priority child.
  ///
  /// Ignores [element]'s initial [_LoadBalancerEntry.queueIndex],
  /// but sets it to the final position when the element has
  /// been placed.
  void _bubbleDown(_LoadBalancerEntry element, int index) {
    while (true) {
      var childIndex = index * 2 + 1; // Left child index.
      if (childIndex >= _length) break;
      var child = _queue[childIndex];
      var rightChildIndex = childIndex + 1;
      if (rightChildIndex < _length) {
        var rightChild = _queue[rightChildIndex];
        if (rightChild.compareTo(child) < 0) {
          childIndex = rightChildIndex;
          child = rightChild;
        }
      }
      if (element.compareTo(child) <= 0) break;
      _queue[index] = child..queueIndex = index;
      index = childIndex;
    }
    _queue[index] = element..queueIndex = index;
  }

  /// Removes the first entry from the queue, but doesn't stop its service.
  ///
  /// The entry is expected to be either added back to the queue
  /// immediately or have its stop method called.
  ///
  /// After the remove, the entry is stored as `_queue[_length]`.
  _LoadBalancerEntry _removeFirst() {
    assert(_length > 0);
    _LoadBalancerEntry entry = _queue.first;
    _length--;
    if (_length > 0) {
      var replacement = _queue[_length];
      _queue[_length] = entry..queueIndex = _length;
      _bubbleDown(replacement, 0);
    }
    return entry;
  }

  /// Adds next unused entry to the queue.
  ///
  /// Adds the entry at [_length] to the queue.
  void _addNext() {
    assert(_length < _queue.length);
    var index = _length;
    var entry = _queue[index];
    _length = index + 1;
    _bubbleUp(entry, index);
  }

  /// Decreases the load of an element which is currently in the queue.
  ///
  /// Elements outside the queue can just have their `load` modified directly.
  void _decreaseLoad(_LoadBalancerEntry entry, int load) {
    assert(load >= 0);
    entry.load -= load;
    var index = entry.queueIndex;
    // Should always be the case unless the load balancer
    // has been closed, or events are happening out of their
    // proper order.
    if (index < _length) {
      _bubbleUp(entry, index);
    }
  }
}

class _LoadBalancerEntry implements Comparable<_LoadBalancerEntry> {
  /// The position in the heap queue.
  ///
  /// Maintained when entries move around the queue.
  /// Only needed for [LoadBalancer._decreaseLoad].
  int queueIndex;

  // The current load on the isolate.
  int load = 0;

  // The service used to execute commands.
  Runner runner;

  _LoadBalancerEntry(this.runner, this.queueIndex);

  Future<R> run<R, P>(
      LoadBalancer balancer,
      int load,
      FutureOr<R> Function(P argument) function,
      P argument,
      Duration? timeout,
      FutureOr<R> Function()? onTimeout) {
    return runner
        .run<R, P>(function, argument, timeout: timeout, onTimeout: onTimeout)
        .whenComplete(() {
      balancer._decreaseLoad(this, load);
    });
  }

  Future close() => runner.close();

  @override
  int compareTo(_LoadBalancerEntry other) => load - other.load;
}
