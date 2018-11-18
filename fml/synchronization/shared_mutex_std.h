// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_SYNCHRONIZATION_SHARED_MUTEX_STD_H_
#define FLUTTER_FML_SYNCHRONIZATION_SHARED_MUTEX_STD_H_

#include <shared_mutex>
#include "flutter/fml/synchronization/shared_mutex.h"

namespace fml {

class SharedMutexStd : public SharedMutex {
 public:
  virtual void Lock();
  virtual void LockShared();
  virtual void Unlock();

 private:
  friend SharedMutex* SharedMutex::Create();
  SharedMutexStd() = default;

  std::shared_timed_mutex mutex_;
};

}  // namespace fml

#endif  // FLUTTER_FML_SYNCHRONIZATION_SHARED_MUTEX_STD_H_
