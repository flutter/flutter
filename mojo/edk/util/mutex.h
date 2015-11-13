// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A mutex class, with support for thread annotations.
//
// TODO(vtl): Add support for non-exclusive (reader) locks.

#ifndef MOJO_EDK_UTIL_MUTEX_H_
#define MOJO_EDK_UTIL_MUTEX_H_

#include <pthread.h>

#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace util {

// Mutex -----------------------------------------------------------------------

class CondVar;

class MOJO_LOCKABLE Mutex final {
 public:
#if defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)
  Mutex() { pthread_mutex_init(&impl_, nullptr); }
  ~Mutex() { pthread_mutex_destroy(&impl_); }

  // Takes an exclusive lock.
  void Lock() MOJO_EXCLUSIVE_LOCK_FUNCTION() { pthread_mutex_lock(&impl_); }

  // Releases a lock.
  void Unlock() MOJO_UNLOCK_FUNCTION() { pthread_mutex_unlock(&impl_); }

  // Tries to take an exclusive lock, returning true if successful.
  bool TryLock() MOJO_EXCLUSIVE_TRYLOCK_FUNCTION(true) {
    return !pthread_mutex_trylock(&impl_);
  }

  // Asserts that an exclusive lock is held by the calling thread. (Does nothing
  // for non-Debug builds.)
  void AssertHeld() MOJO_ASSERT_EXCLUSIVE_LOCK() {}
#else
  Mutex();
  ~Mutex();

  void Lock() MOJO_EXCLUSIVE_LOCK_FUNCTION();
  void Unlock() MOJO_UNLOCK_FUNCTION();

  bool TryLock() MOJO_EXCLUSIVE_TRYLOCK_FUNCTION(true);

  void AssertHeld() MOJO_ASSERT_EXCLUSIVE_LOCK();
#endif  // defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)

 private:
  friend class CondVar;

  pthread_mutex_t impl_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Mutex);
};

// MutexLocker -----------------------------------------------------------------

class MOJO_SCOPED_LOCKABLE MutexLocker final {
 public:
  explicit MutexLocker(Mutex* mutex) MOJO_EXCLUSIVE_LOCK_FUNCTION(mutex)
      : mutex_(mutex) {
    this->mutex_->Lock();
  }
  ~MutexLocker() MOJO_UNLOCK_FUNCTION() { this->mutex_->Unlock(); }

 private:
  Mutex* const mutex_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MutexLocker);
};

}  // namespace util
}  // namespace mojo

#endif  // MOJO_EDK_UTIL_MUTEX_H_
