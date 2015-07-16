// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A mutex class, with support for thread annotations.
//
// TODO(vtl): Currently, this is a fork of Chromium's
// base/synchronization/lock.h (with names changed and minor modifications; it
// still cheats and uses Chromium's lock_impl.*), but eventually we'll want our
// own and, e.g., add support for non-exclusive (reader) locks.

#ifndef MOJO_EDK_SYSTEM_MUTEX_H_
#define MOJO_EDK_SYSTEM_MUTEX_H_

#include "base/synchronization/lock_impl.h"
#include "base/threading/platform_thread.h"
#include "mojo/edk/system/system_impl_export.h"
#include "mojo/edk/system/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// Mutex -----------------------------------------------------------------------

class MOJO_SYSTEM_IMPL_EXPORT MOJO_LOCKABLE Mutex {
 public:
#if defined(NDEBUG) && !defined(DCHECK_ALWAYS_ON)
  Mutex() : lock_() {}
  ~Mutex() {}

  void Lock() MOJO_EXCLUSIVE_LOCK_FUNCTION() { lock_.Lock(); }
  void Unlock() MOJO_UNLOCK_FUNCTION() { lock_.Unlock(); }

  bool TryLock() MOJO_EXCLUSIVE_TRYLOCK_FUNCTION(true) { return lock_.Try(); }

  void AssertHeld() const MOJO_ASSERT_EXCLUSIVE_LOCK() {}
#else
  Mutex();
  ~Mutex();

  void Lock() MOJO_EXCLUSIVE_LOCK_FUNCTION() {
    lock_.Lock();
    CheckUnheldAndMark();
  }
  void Unlock() MOJO_UNLOCK_FUNCTION() {
    CheckHeldAndUnmark();
    lock_.Unlock();
  }

  bool TryLock() MOJO_EXCLUSIVE_TRYLOCK_FUNCTION(true) {
    bool rv = lock_.Try();
    if (rv)
      CheckUnheldAndMark();
    return rv;
  }

  void AssertHeld() const MOJO_ASSERT_EXCLUSIVE_LOCK();
#endif  // NDEBUG && !DCHECK_ALWAYS_ON

 private:
#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
  void CheckHeldAndUnmark();
  void CheckUnheldAndMark();

  base::PlatformThreadRef owning_thread_ref_;
#endif  // !NDEBUG || DCHECK_ALWAYS_ON

  base::internal::LockImpl lock_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Mutex);
};

// MutexLocker -----------------------------------------------------------------

class MOJO_SYSTEM_IMPL_EXPORT MOJO_SCOPED_LOCKABLE MutexLocker {
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

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MUTEX_H_
