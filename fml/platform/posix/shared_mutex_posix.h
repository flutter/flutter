// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_SYNCHRONIZATION_SHARED_MUTEX_POSIX_H_
#define FLUTTER_FML_SYNCHRONIZATION_SHARED_MUTEX_POSIX_H_

#include <shared_mutex>

#include "flutter/fml/synchronization/shared_mutex.h"

namespace fml {

class SharedMutexPosix : public SharedMutex {
 public:
  virtual void Lock();
  virtual void LockShared();
  virtual void Unlock();
  virtual void UnlockShared();

 private:
  friend SharedMutex* SharedMutex::Create();
  SharedMutexPosix();

  pthread_rwlock_t rwlock_;
};

}  // namespace fml

#endif  // FLUTTER_FML_SYNCHRONIZATION_SHARED_MUTEX_POSIX_H_
