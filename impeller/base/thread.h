// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <mutex>
#include <thread>

#include "flutter/fml/macros.h"
#include "flutter/fml/synchronization/shared_mutex.h"
#include "impeller/base/thread_safety.h"

namespace impeller {

class IPLR_CAPABILITY("mutex") Mutex {
 public:
  Mutex() = default;

  ~Mutex() = default;

  void Lock() IPLR_ACQUIRE() { mutex_.lock(); }

  void Unlock() IPLR_RELEASE() { mutex_.unlock(); }

 private:
  std::mutex mutex_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(Mutex);
};

class IPLR_CAPABILITY("mutex") RWMutex {
 public:
  RWMutex()
      : mutex_(std::unique_ptr<fml::SharedMutex>(fml::SharedMutex::Create())) {}

  ~RWMutex() = default;

  void LockWriter() IPLR_ACQUIRE() { mutex_->Lock(); }

  void UnlockWriter() IPLR_RELEASE() { mutex_->Unlock(); }

  void LockReader() IPLR_ACQUIRE_SHARED() { mutex_->LockShared(); }

  void UnlockReader() IPLR_RELEASE_SHARED() { mutex_->UnlockShared(); }

 private:
  std::unique_ptr<fml::SharedMutex> mutex_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(RWMutex);
};

class IPLR_SCOPED_CAPABILITY Lock {
 public:
  explicit Lock(Mutex& mutex) IPLR_ACQUIRE(mutex) : mutex_(mutex) {
    mutex_.Lock();
  }

  ~Lock() IPLR_RELEASE() { mutex_.Unlock(); }

 private:
  Mutex& mutex_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(Lock);
};

class IPLR_SCOPED_CAPABILITY ReaderLock {
 public:
  explicit ReaderLock(RWMutex& mutex) IPLR_ACQUIRE_SHARED(mutex)
      : mutex_(mutex) {
    mutex_.LockReader();
  }

  ~ReaderLock() IPLR_RELEASE() { mutex_.UnlockReader(); }

 private:
  RWMutex& mutex_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(ReaderLock);
};

class IPLR_SCOPED_CAPABILITY WriterLock {
 public:
  explicit WriterLock(RWMutex& mutex) IPLR_ACQUIRE(mutex) : mutex_(mutex) {
    mutex_.LockWriter();
  }

  ~WriterLock() IPLR_RELEASE() { mutex_.UnlockWriter(); }

 private:
  RWMutex& mutex_;

  FML_DISALLOW_COPY_ASSIGN_AND_MOVE(WriterLock);
};

}  // namespace impeller
