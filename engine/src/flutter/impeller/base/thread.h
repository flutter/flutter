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

  Mutex(const Mutex&) = delete;

  Mutex(Mutex&&) = delete;

  Mutex& operator=(const Mutex&) = delete;

  Mutex& operator=(Mutex&&) = delete;
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

  RWMutex(const RWMutex&) = delete;

  RWMutex(RWMutex&&) = delete;

  RWMutex& operator=(const RWMutex&) = delete;

  RWMutex& operator=(RWMutex&&) = delete;
};

class IPLR_SCOPED_CAPABILITY Lock {
 public:
  explicit Lock(Mutex& mutex) IPLR_ACQUIRE(mutex) : mutex_(mutex) {
    mutex_.Lock();
  }

  ~Lock() IPLR_RELEASE() { mutex_.Unlock(); }

 private:
  Mutex& mutex_;

  Lock(const Lock&) = delete;

  Lock(Lock&&) = delete;

  Lock& operator=(const Lock&) = delete;

  Lock& operator=(Lock&&) = delete;
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

  ReaderLock(const ReaderLock&) = delete;

  ReaderLock(ReaderLock&&) = delete;

  ReaderLock& operator=(const ReaderLock&) = delete;

  ReaderLock& operator=(ReaderLock&&) = delete;
};

class IPLR_SCOPED_CAPABILITY WriterLock {
 public:
  explicit WriterLock(RWMutex& mutex) IPLR_ACQUIRE(mutex) : mutex_(mutex) {
    mutex_.LockWriter();
  }

  ~WriterLock() IPLR_RELEASE() { mutex_.UnlockWriter(); }

 private:
  RWMutex& mutex_;

  WriterLock(const WriterLock&) = delete;

  WriterLock(WriterLock&&) = delete;

  WriterLock& operator=(const WriterLock&) = delete;

  WriterLock& operator=(WriterLock&&) = delete;
};

}  // namespace impeller
