// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library is used for testing asynchronous tests.
/// If a test is asynchronous, it needs to notify the testing driver
/// about this (otherwise tests may get reported as passing [after main()
/// finished] even if the asynchronous operations fail).
/// Tests which can't use the unittest framework should use the helper functions
/// in this library.
/// This library provides four methods
///  - asyncStart(): Needs to be called before an asynchronous operation is
///                  scheduled.
///  - asyncEnd(): Needs to be called as soon as the asynchronous operation
///                ended.
///  - asyncSuccess(_): Variant of asyncEnd useful together with Future.then.
///  - asyncTest(f()): Helper method that wraps a computation that returns a
///                    Future with matching calls to asyncStart() and
///                    asyncSuccess(_).
/// After the last asyncStart() called was matched with a corresponding
/// asyncEnd() or asyncSuccess(_) call, the testing driver will be notified that
/// the tests is done.

library async_helper;

// TODO(kustermann): This is problematic because we rely on a working
// 'dart:isolate' (i.e. it is in particular problematic with dart2js).
// It would be nice if we could use a different mechanism for different
// runtimes.
import 'dart:isolate';

bool _initialized = false;
ReceivePort _port = null;
int _asyncLevel = 0;

Exception _buildException(String msg) {
  return new Exception('Fatal: $msg. This is most likely a bug in your test.');
}

/// Call this method before an asynchronous test is created.
void asyncStart() {
  if (_initialized && _asyncLevel == 0) {
    throw _buildException('asyncStart() was called even though we are done '
                          'with testing.');
  }
  if (!_initialized) {
    print('unittest-suite-wait-for-done');
    _initialized = true;
    _port = new ReceivePort();
  }
  _asyncLevel++;
}

/// Call this after an asynchronous test has ended successfully.
void asyncEnd() {
  if (_asyncLevel <= 0) {
    if (!_initialized) {
      throw _buildException('asyncEnd() was called before asyncStart().');
    } else {
      throw _buildException('asyncEnd() was called more often than '
                            'asyncStart().');
    }
  }
  _asyncLevel--;
  if (_asyncLevel == 0) {
    _port.close();
    _port = null;
    print('unittest-suite-success');
  }
}

/**
 * Call this after an asynchronous test has ended successfully. This is a helper
 * for calling [asyncEnd].
 *
 * This method intentionally has a signature that matches [:Future.then:] as a
 * convenience for calling [asyncEnd] when a [:Future:] completes without error,
 * like this:
 *
 *     asyncStart();
 *     Future result = test();
 *     result.then(asyncSuccess);
 */
void asyncSuccess(_) => asyncEnd();

/**
 * Helper method for performing asynchronous tests involving [:Future:].
 *
 * [f] must return a [:Future:] for the test computation.
 */
void asyncTest(f()) {
  asyncStart();
  f().then(asyncSuccess);
}
