// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_SYNCHRONIZATION_SHARED_MUTEX_H_
#define FLUTTER_FML_SYNCHRONIZATION_SHARED_MUTEX_H_

namespace fml {

// Interface for a reader/writer lock.
class SharedMutex {
 public:
  static SharedMutex* Create();
  virtual ~SharedMutex() = default;

  virtual void Lock() = 0;
  virtual void LockShared() = 0;
  virtual void Unlock() = 0;
};

// RAII wrapper that does a shared acquire of a SharedMutex.
class SharedLock {
 public:
  explicit SharedLock(SharedMutex& shared_mutex) : shared_mutex_(shared_mutex) {
    shared_mutex_.LockShared();
  }

  ~SharedLock() { shared_mutex_.Unlock(); }

 private:
  SharedMutex& shared_mutex_;
};

// RAII wrapper that does an exclusive acquire of a SharedMutex.
class UniqueLock {
 public:
  explicit UniqueLock(SharedMutex& shared_mutex) : shared_mutex_(shared_mutex) {
    shared_mutex_.Lock();
  }

  ~UniqueLock() { shared_mutex_.Unlock(); }

 private:
  SharedMutex& shared_mutex_;
};

}  // namespace fml

#endif  // FLUTTER_FML_SYNCHRONIZATION_SHARED_MUTEX_H_
