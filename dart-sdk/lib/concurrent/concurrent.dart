// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Classes that help implementing synchronized, concurrently-safe code.
///
/// {@category Core}
/// {@nodoc}
library dart.concurrent;

/// A *mutex* synchronization primitive.
///
/// Mutex can be used to synchronize access to a native resource shared between
/// multiple threads.
///
/// Mutex objects are owned by an isolate which created them.
abstract interface class Mutex {
  factory Mutex() => Mutex._();

  external factory Mutex._();

  external Object _runLocked(Object action);

  /// Run the given synchronous `action` under a mutex.
  ///
  /// This function takes exclusive ownership of the mutex, executes `action`
  /// and then releases the mutex. It returns the value returned by `action`.
  ///
  /// **Warning**: you can't combine `runLocked` with an asynchronous code.
  R runLocked<R>(R Function() action);
}

/// A *condition variable* synchronization primitive.
///
/// Condition variable can be used to synchronously wait for a condition to
/// occur.
///
/// [ConditionVariable] objects are owned by an isolate which created them.
abstract interface class ConditionVariable {
  factory ConditionVariable() => ConditionVariable._();

  external factory ConditionVariable._();

  /// Block and wait until another thread calls [notify].
  ///
  /// `mutex` must be a [Mutex] object exclusively held by the current thread.
  /// It will be released and the thread will block until another thread
  /// calls [notify].
  ///
  /// If `timeout` is provided, it must be positive or zero.
  /// Default zero value indicates that the method will wait to be notified
  /// infinitely, without timeout.
  /// If it is greater than zero, then after this many milliseconds the method
  /// will return even if the variable was not notified.
  external void wait(Mutex mutex, [int timeout = 0]);

  /// Wake up at least one thread waiting on this condition variable.
  external void notify();

  /// Wake up all threads waiting on this condition variable.
  external void notifyAll();
}
