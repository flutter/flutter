// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

/// Used to protect global state accessed in blocks containing calls to
/// asynchronous methods.
class Mutex {
  /// Executes a block of code containing asynchronous calls atomically.
  ///
  /// If no other asynchronous context is currently executing within
  /// [criticalSection] or a [runGuardedWeak] scope, it will immediately be
  /// called. Otherwise, the caller will be suspended and entered into a queue
  /// to be resumed once the lock is released.
  Future<T> runGuarded<T>(FutureOr<T> Function() criticalSection) async {
    try {
      await _acquireLock();
      return await criticalSection();
    } finally {
      _releaseLock();
    }
  }

  /// Executes a block of code containing asynchronous calls, allowing for other
  /// weakly guarded sections to be executed concurrently.
  ///
  /// If no other asynchronous context is currently executing within a
  /// [runGuarded] scope, [criticalSection] will immediately be called.
  /// Otherwise, the caller will be suspended and entered into a queue to be
  /// resumed once the lock is released.
  Future<T> runGuardedWeak<T>(FutureOr<T> Function() criticalSection) async {
    _weakGuards++;
    if (_weakGuards == 1) {
      // Reinitialize if this is the only weakly guarded scope.
      _outstandingReadersCompleter = Completer<void>();
    }
    final T result;
    try {
      await _acquireLock(strong: false);
      result = await criticalSection();
    } finally {
      _weakGuards--;
      if (_weakGuards == 0) {
        // Notify callers of `runGuarded` that they can try to execute again.
        _outstandingReadersCompleter.complete();
      }
    }
    return result;
  }

  Future<void> _acquireLock({bool strong = true}) async {
    // The lock cannot be acquired by `runGuarded` if there is outstanding
    // execution in weakly guarded sections. Loop in case we've entered another
    // weakly guarded scope before we've woken up.
    while (strong && _weakGuards > 0) {
      await _outstandingReadersCompleter.future;
    }
    if (!_locked) {
      if (strong) {
        // Don't actually lock for weakly guarded sections, just make sure the
        // lock isn't held before entering.
        _locked = true;
      }
      return;
    }

    final request = Completer<void>();
    _outstandingRequests.add(request);
    await request.future;
  }

  void _releaseLock() {
    _locked = false;
    if (_outstandingRequests.isNotEmpty) {
      final request = _outstandingRequests.removeFirst();
      request.complete();
    }
  }

  int _weakGuards = 0;
  bool _locked = false;
  var _outstandingReadersCompleter = Completer<void>();
  final _outstandingRequests = Queue<Completer<void>>();
}
