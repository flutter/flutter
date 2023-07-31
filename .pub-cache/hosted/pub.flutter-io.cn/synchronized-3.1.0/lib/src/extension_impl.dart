// list of waiting/running locks
// empty when nothing running
import 'dart:async';

import 'package:synchronized/src/basic_lock.dart';

/// All basic lock
final cacheLocks = <Object, BasicLock>{};

/// Returns the associate basic lock
BasicLock objectMakeLock(Object monitor) {
  // get or create Lock object
  var synchronizedLock = cacheLocks[monitor];
  if (synchronizedLock == null) {
    synchronizedLock = BasicLock();
    cacheLocks[monitor] = synchronizedLock;
  }
  return synchronizedLock;
}

/// Remove object for global cache
void cleanUpLock(Object monitor) {
  cacheLocks.remove(monitor);
}

/// Execute [computation] when lock is available. Only one block can run while
/// the lock is retained. Any object can be a lock, locking is based on identity.
Future<T> objectSynchronized<T>(
    Object monitor, FutureOr<T> Function() computation,
    {Duration? timeout}) async {
  // Make any object a lock object
  var lockImpl = objectMakeLock(monitor);
  try {
    return await lockImpl.synchronized(() async {
      var result = computation();
      if (result is Future) {
        result = await result;
      }
      return result;
    }, timeout: timeout);
  } finally {
    // Clean up if unlocked
    if (!lockImpl.locked) {
      cleanUpLock(monitor);
    }
  }
}
