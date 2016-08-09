// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A class for checking that the current thread is/isn't the same as an initial
// thread.

#ifndef MOJO_EDK_UTIL_THREAD_CHECKER_H_
#define MOJO_EDK_UTIL_THREAD_CHECKER_H_

#include <pthread.h>

#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace util {

// A simple class that records the identity of the thread that it was created
// on, and at later points can tell if the current thread is the same as its
// creation thread. This class is thread-safe.
//
// Note: Unlike Chromium's |base::ThreadChecker|, this is *not* Debug-only (so
// #ifdef it out if you want something Debug-only). (Rationale: Having a
// |CalledOnValidThread()| that lies in Release builds seems bad. Moreover,
// there's a small space cost to having even an empty class. )
class ThreadChecker final {
 public:
  ThreadChecker() : self_(pthread_self()) {}
  ~ThreadChecker() {}

  // Returns true if the current thread is the thread this object was created
  // on and false otherwise.
  bool IsCreationThreadCurrent() const {
    return !!pthread_equal(pthread_self(), self_);
  }

 private:
  const pthread_t self_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ThreadChecker);
};

}  // namespace util
}  // namespace mojo

#endif  // MOJO_EDK_UTIL_THREAD_CHECKER_H_
