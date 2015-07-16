// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/utility/mutex.h"

#include <assert.h>
#include <errno.h>

namespace mojo {

// Release builds have inlined (non-error-checking) definitions in the header.
#if !defined(NDEBUG)
Mutex::Mutex() {
  pthread_mutexattr_t mutexattr;
  int rv = pthread_mutexattr_init(&mutexattr);
  assert(rv == 0);
  rv = pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_ERRORCHECK);
  assert(rv == 0);
  rv = pthread_mutex_init(&mutex_, &mutexattr);
  assert(rv == 0);
  rv = pthread_mutexattr_destroy(&mutexattr);
  assert(rv == 0);
}

Mutex::~Mutex() {
  int rv = pthread_mutex_destroy(&mutex_);
  assert(rv == 0);
}

void Mutex::Lock() {
  int rv = pthread_mutex_lock(&mutex_);
  assert(rv == 0);
}

void Mutex::Unlock() {
  int rv = pthread_mutex_unlock(&mutex_);
  assert(rv == 0);
}

bool Mutex::TryLock() {
  int rv = pthread_mutex_trylock(&mutex_);
  assert(rv == 0 || rv == EBUSY);
  return rv == 0;
}

void Mutex::AssertHeld() {
  assert(pthread_mutex_lock(&mutex_) == EDEADLK);
}
#endif  // !defined(NDEBUG)

}  // namespace mojo
