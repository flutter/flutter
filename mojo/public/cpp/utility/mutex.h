// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_UTILITY_MUTEX_H_
#define MOJO_PUBLIC_CPP_UTILITY_MUTEX_H_

#ifdef _WIN32
#error "Not implemented: See crbug.com/342893."
#endif

#include <pthread.h>

#include "mojo/public/cpp/system/macros.h"

namespace mojo {

#ifdef NDEBUG
// Note: Make a C++ constant for |PTHREAD_MUTEX_INITIALIZER|. (We can't directly
// use the C macro in an initializer list, since it might expand to |{ ... }|.)
namespace internal {
const pthread_mutex_t kPthreadMutexInitializer = PTHREAD_MUTEX_INITIALIZER;
}
#endif

class Mutex {
 public:
#ifdef NDEBUG
  Mutex() : mutex_(internal::kPthreadMutexInitializer) {}
  ~Mutex() { pthread_mutex_destroy(&mutex_); }

  void Lock() { pthread_mutex_lock(&mutex_); }
  void Unlock() { pthread_mutex_unlock(&mutex_); }
  bool TryLock() { return pthread_mutex_trylock(&mutex_) == 0; }

  void AssertHeld() {}
#else
  Mutex();
  ~Mutex();

  void Lock();
  void Unlock();
  bool TryLock();

  void AssertHeld();
#endif

 private:
  pthread_mutex_t mutex_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Mutex);
};

class MutexLock {
 public:
  explicit MutexLock(Mutex* mutex) : mutex_(mutex) { mutex_->Lock(); }
  ~MutexLock() { mutex_->Unlock(); }

 private:
  Mutex* const mutex_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MutexLock);
};

// Catch bug where variable name is omitted (e.g., |MutexLock (&mu)|).
#define MutexLock(x) static_assert(0, "MutexLock() missing variable name");

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_UTILITY_MUTEX_H_
