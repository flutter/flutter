import 'package:synchronized/src/basic_lock.dart';
import 'package:synchronized/src/reentrant_lock.dart';
import 'package:synchronized/synchronized.dart';

export 'package:synchronized/src/utils.dart';

abstract class LockFactory {
  Lock newLock();
}

class BasicLockFactory implements LockFactory {
  @override
  Lock newLock() => BasicLock();
}

class ReentrantLockFactory implements LockFactory {
  @override
  Lock newLock() => ReentrantLock();
}
