// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/mutex.h"

#if !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
#include <errno.h>

#include "mojo/edk/util/logging_internal.h"

namespace mojo {
namespace util {

Mutex::Mutex() {
  pthread_mutexattr_t attr;
  int error = pthread_mutexattr_init(&attr);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_mutexattr_init", error);
  error = pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_mutexattr_settype", error);
  error = pthread_mutex_init(&impl_, &attr);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_mutex_init", error);
  error = pthread_mutexattr_destroy(&attr);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_mutexattr_destroy", error);
}

Mutex::~Mutex() {
  int error = pthread_mutex_destroy(&impl_);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_mutex_destroy", error);
}

void Mutex::Lock() MOJO_EXCLUSIVE_LOCK_FUNCTION() {
  int error = pthread_mutex_lock(&impl_);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_mutex_lock", error);
}

void Mutex::Unlock() MOJO_UNLOCK_FUNCTION() {
  int error = pthread_mutex_unlock(&impl_);
  INTERNAL_DCHECK_WITH_ERRNO(!error, "pthread_mutex_unlock", error);
}

bool Mutex::TryLock() MOJO_EXCLUSIVE_TRYLOCK_FUNCTION(true) {
  int error = pthread_mutex_trylock(&impl_);
  INTERNAL_DCHECK_WITH_ERRNO(!error || error == EBUSY, "pthread_mutex_trylock",
                             error);
  return !error;
}

void Mutex::AssertHeld() MOJO_ASSERT_EXCLUSIVE_LOCK() {
  int error = pthread_mutex_lock(&impl_);
  INTERNAL_DCHECK_WITH_ERRNO(error == EDEADLK, "pthread_mutex_lock", error);
}

}  // namespace util
}  // namespace mojo

#endif  // !defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)
