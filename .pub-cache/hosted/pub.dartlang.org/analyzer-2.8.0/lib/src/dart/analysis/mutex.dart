// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// Mutual exclusion.
///
/// Usage:
///
///     var m = new Mutex();
///
///     await m.acquire();
///     try {
///       // critical section
///     }
///     finally {
///       m.release();
///     }
class Mutex {
  Completer<void>? _lock;

  /// Acquire a lock.
  ///
  /// Returns a [Future] that will be completed when the lock has been acquired.
  Future<void> acquire() async {
    while (_lock != null) {
      await _lock!.future;
    }
    _lock = Completer<void>();
  }

  /// Run the given [criticalSection] with acquired mutex.
  Future<T> guard<T>(Future<T> Function() criticalSection) async {
    await acquire();
    try {
      return await criticalSection();
    } finally {
      release();
    }
  }

  /// Release a lock.
  ///
  /// Release a lock that has been acquired.
  void release() {
    if (_lock == null) {
      throw StateError('No lock to release.');
    }
    _lock!.complete();
    _lock = null;
  }
}
