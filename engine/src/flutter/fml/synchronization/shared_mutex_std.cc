// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/synchronization/shared_mutex_std.h"

namespace fml {

SharedMutex* SharedMutex::Create() {
  return new SharedMutexStd();
}

void SharedMutexStd::Lock() {
  mutex_.lock();
}

void SharedMutexStd::LockShared() {
  mutex_.lock_shared();
}

void SharedMutexStd::Unlock() {
  mutex_.unlock();
}

void SharedMutexStd::UnlockShared() {
  mutex_.unlock_shared();
}

}  // namespace fml
