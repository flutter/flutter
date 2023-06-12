// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:async/async.dart';
import 'package:stack_trace/stack_trace.dart';

/// Manages an abstract pool of resources with a limit on how many may be in use
/// at once.
///
/// When a resource is needed, the user should call [request]. When the returned
/// future completes with a [PoolResource], the resource may be allocated. Once
/// the resource has been released, the user should call [PoolResource.release].
/// The pool will ensure that only a certain number of [PoolResource]s may be
/// allocated at once.
class Pool {
  /// Completers for requests beyond the first [_maxAllocatedResources].
  ///
  /// When an item is released, the next element of [_requestedResources] will
  /// be completed.
  final _requestedResources = Queue<Completer<PoolResource>>();

  /// Callbacks that must be called before additional resources can be
  /// allocated.
  ///
  /// See [PoolResource.allowRelease].
  final _onReleaseCallbacks = Queue<void Function()>();

  /// Completers that will be completed once `onRelease` callbacks are done
  /// running.
  ///
  /// These are kept in a queue to ensure that the earliest request completes
  /// first regardless of what order the `onRelease` callbacks complete in.
  final _onReleaseCompleters = Queue<Completer<PoolResource>>();

  /// The maximum number of resources that may be allocated at once.
  final int _maxAllocatedResources;

  /// The number of resources that are currently allocated.
  int _allocatedResources = 0;

  /// The timeout timer.
  ///
  /// This timer is canceled as long as the pool is below the resource limit.
  /// It's reset once the resource limit is reached and again every time an
  /// resource is released or a new resource is requested. If it fires, that
  /// indicates that the caller became deadlocked, likely due to files waiting
  /// for additional files to be read before they could be closed.
  ///
  /// This is `null` if this pool shouldn't time out.
  RestartableTimer? _timer;

  /// The amount of time to wait before timing out the pending resources.
  final Duration? _timeout;

  /// A [FutureGroup] that tracks all the `onRelease` callbacks for resources
  /// that have been marked releasable.
  ///
  /// This is `null` until [close] is called.
  FutureGroup? _closeGroup;

  /// Whether [close] has been called.
  bool get isClosed => _closeMemo.hasRun;

  /// A future that completes once the pool is closed and all its outstanding
  /// resources have been released.
  ///
  /// If any [PoolResource.allowRelease] callback throws an exception after the
  /// pool is closed, this completes with that exception.
  Future get done => _closeMemo.future;

  /// Creates a new pool with the given limit on how many resources may be
  /// allocated at once.
  ///
  /// If [timeout] is passed, then if that much time passes without any activity
  /// all pending [request] futures will throw a [TimeoutException]. This is
  /// intended to avoid deadlocks.
  Pool(this._maxAllocatedResources, {Duration? timeout}) : _timeout = timeout {
    if (_maxAllocatedResources <= 0) {
      throw ArgumentError.value(_maxAllocatedResources, 'maxAllocatedResources',
          'Must be greater than zero.');
    }

    if (timeout != null) {
      // Start the timer canceled since we only want to start counting down once
      // we've run out of available resources.
      _timer = RestartableTimer(timeout, _onTimeout)..cancel();
    }
  }

  /// Request a [PoolResource].
  ///
  /// If the maximum number of resources is already allocated, this will delay
  /// until one of them is released.
  Future<PoolResource> request() {
    if (isClosed) {
      throw StateError('request() may not be called on a closed Pool.');
    }

    if (_allocatedResources < _maxAllocatedResources) {
      _allocatedResources++;
      return Future.value(PoolResource._(this));
    } else if (_onReleaseCallbacks.isNotEmpty) {
      return _runOnRelease(_onReleaseCallbacks.removeFirst());
    } else {
      var completer = Completer<PoolResource>();
      _requestedResources.add(completer);
      _resetTimer();
      return completer.future;
    }
  }

  /// Requests a resource for the duration of [callback], which may return a
  /// Future.
  ///
  /// The return value of [callback] is piped to the returned Future.
  Future<T> withResource<T>(FutureOr<T> Function() callback) async {
    if (isClosed) {
      throw StateError('withResource() may not be called on a closed Pool.');
    }

    var resource = await request();
    try {
      return await callback();
    } finally {
      resource.release();
    }
  }

  /// Returns a [Stream] containing the result of [action] applied to each
  /// element of [elements].
  ///
  /// While [action] is invoked on each element of [elements] in order,
  /// it's possible the return [Stream] may have items out-of-order – especially
  /// if the completion time of [action] varies.
  ///
  /// If [action] throws an error the source item along with the error object
  /// and [StackTrace] are passed to [onError], if it is provided. If [onError]
  /// returns `true`, the error is added to the returned [Stream], otherwise
  /// it is ignored.
  ///
  /// Errors thrown from iterating [elements] will not be passed to
  /// [onError]. They will always be added to the returned stream as an error.
  ///
  /// Note: all of the resources of the this [Pool] will be used when the
  /// returned [Stream] is listened to until it is completed or canceled.
  ///
  /// Note: if this [Pool] is closed before the returned [Stream] is listened
  /// to, a [StateError] is thrown.
  Stream<T> forEach<S, T>(
      Iterable<S> elements, FutureOr<T> Function(S source) action,
      {bool Function(S item, Object error, StackTrace stack)? onError}) {
    onError ??= (item, e, s) => true;

    var cancelPending = false;

    Completer? resumeCompleter;
    late StreamController<T> controller;

    late Iterator<S> iterator;

    Future<void> run(int _) async {
      while (iterator.moveNext()) {
        // caching `current` is necessary because there are async breaks
        // in this code and `iterator` is shared across many workers
        final current = iterator.current;

        _resetTimer();

        if (resumeCompleter != null) {
          await resumeCompleter!.future;
        }

        if (cancelPending) {
          break;
        }

        T value;
        try {
          value = await action(current);
        } catch (e, stack) {
          if (onError!(current, e, stack)) {
            controller.addError(e, stack);
          }
          continue;
        }
        controller.add(value);
      }
    }

    Future<void>? doneFuture;

    void onListen() {
      iterator = elements.iterator;

      assert(doneFuture == null);
      var futures = Iterable<Future<void>>.generate(
          _maxAllocatedResources, (i) => withResource(() => run(i)));
      doneFuture = Future.wait(futures, eagerError: true)
          .then<void>((_) {})
          .catchError(controller.addError);

      doneFuture!.whenComplete(controller.close);
    }

    controller = StreamController<T>(
      sync: true,
      onListen: onListen,
      onCancel: () async {
        assert(!cancelPending);
        cancelPending = true;
        await doneFuture;
      },
      onPause: () {
        assert(resumeCompleter == null);
        resumeCompleter = Completer<void>();
      },
      onResume: () {
        assert(resumeCompleter != null);
        resumeCompleter!.complete();
        resumeCompleter = null;
      },
    );

    return controller.stream;
  }

  /// Closes the pool so that no more resources are requested.
  ///
  /// Existing resource requests remain unchanged.
  ///
  /// Any resources that are marked as releasable using
  /// [PoolResource.allowRelease] are released immediately. Once all resources
  /// have been released and any `onRelease` callbacks have completed, the
  /// returned future completes successfully. If any `onRelease` callback throws
  /// an error, the returned future completes with that error.
  ///
  /// This may be called more than once; it returns the same [Future] each time.
  Future close() => _closeMemo.runOnce(() {
        if (_closeGroup != null) return _closeGroup!.future;

        _resetTimer();

        _closeGroup = FutureGroup();
        for (var callback in _onReleaseCallbacks) {
          _closeGroup!.add(Future.sync(callback));
        }

        _allocatedResources -= _onReleaseCallbacks.length;
        _onReleaseCallbacks.clear();

        if (_allocatedResources == 0) _closeGroup!.close();
        return _closeGroup!.future;
      });
  final _closeMemo = AsyncMemoizer();

  /// If there are any pending requests, this will fire the oldest one.
  void _onResourceReleased() {
    _resetTimer();

    if (_requestedResources.isNotEmpty) {
      var pending = _requestedResources.removeFirst();
      pending.complete(PoolResource._(this));
    } else {
      _allocatedResources--;
      if (isClosed && _allocatedResources == 0) _closeGroup!.close();
    }
  }

  /// If there are any pending requests, this will fire the oldest one after
  /// running [onRelease].
  void _onResourceReleaseAllowed(Function() onRelease) {
    _resetTimer();

    if (_requestedResources.isNotEmpty) {
      var pending = _requestedResources.removeFirst();
      pending.complete(_runOnRelease(onRelease));
    } else if (isClosed) {
      _closeGroup!.add(Future.sync(onRelease));
      _allocatedResources--;
      if (_allocatedResources == 0) _closeGroup!.close();
    } else {
      var zone = Zone.current;
      var registered = zone.registerCallback(onRelease);
      _onReleaseCallbacks.add(() => zone.run(registered));
    }
  }

  /// Runs [onRelease] and returns a Future that completes to a resource once an
  /// [onRelease] callback completes.
  ///
  /// Futures returned by [_runOnRelease] always complete in the order they were
  /// created, even if earlier [onRelease] callbacks take longer to run.
  Future<PoolResource> _runOnRelease(Function() onRelease) {
    Future.sync(onRelease).then((value) {
      _onReleaseCompleters.removeFirst().complete(PoolResource._(this));
    }).catchError((Object error, StackTrace stackTrace) {
      _onReleaseCompleters.removeFirst().completeError(error, stackTrace);
    });

    var completer = Completer<PoolResource>.sync();
    _onReleaseCompleters.add(completer);
    return completer.future;
  }

  /// A resource has been requested, allocated, or released.
  void _resetTimer() {
    if (_timer == null) return;

    if (_requestedResources.isEmpty) {
      _timer!.cancel();
    } else {
      _timer!.reset();
    }
  }

  /// Handles [_timer] timing out by causing all pending resource completers to
  /// emit exceptions.
  void _onTimeout() {
    for (var completer in _requestedResources) {
      completer.completeError(
          TimeoutException(
              'Pool deadlock: all resources have been '
              'allocated for too long.',
              _timeout),
          Chain.current());
    }
    _requestedResources.clear();
    _timer = null;
  }
}

/// A member of a [Pool].
///
/// A [PoolResource] is a token that indicates that a resource is allocated.
/// When the associated resource is released, the user should call [release].
class PoolResource {
  final Pool _pool;

  /// Whether `this` has been released yet.
  bool _released = false;

  PoolResource._(this._pool);

  /// Tells the parent [Pool] that the resource associated with this resource is
  /// no longer allocated, and that a new [PoolResource] may be allocated.
  void release() {
    if (_released) {
      throw StateError('A PoolResource may only be released once.');
    }
    _released = true;
    _pool._onResourceReleased();
  }

  /// Tells the parent [Pool] that the resource associated with this resource is
  /// no longer necessary, but should remain allocated until more resources are
  /// needed.
  ///
  /// When [Pool.request] is called and there are no remaining available
  /// resources, the [onRelease] callback is called. It should free the
  /// resource, and it may return a Future or `null`. Once that completes, the
  /// [Pool.request] call will complete to a new [PoolResource].
  ///
  /// This is useful when a resource's main function is complete, but it may
  /// produce additional information later on. For example, an isolate's task
  /// may be complete, but it could still emit asynchronous errors.
  void allowRelease(Function() onRelease) {
    if (_released) {
      throw StateError('A PoolResource may only be released once.');
    }
    _released = true;
    _pool._onResourceReleaseAllowed(onRelease);
  }
}
