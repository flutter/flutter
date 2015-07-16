// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SYNCHRONIZATION_CANCELLATION_FLAG_H_
#define BASE_SYNCHRONIZATION_CANCELLATION_FLAG_H_

#include "base/base_export.h"
#include "base/atomicops.h"
#include "base/threading/platform_thread.h"

namespace base {

// CancellationFlag allows one thread to cancel jobs executed on some worker
// thread. Calling Set() from one thread and IsSet() from a number of threads
// is thread-safe.
//
// This class IS NOT intended for synchronization between threads.
class BASE_EXPORT CancellationFlag {
 public:
  CancellationFlag() : flag_(false) {
#if !defined(NDEBUG)
    set_on_ = PlatformThread::CurrentId();
#endif
  }
  ~CancellationFlag() {}

  // Set the flag. May only be called on the thread which owns the object.
  void Set();
  bool IsSet() const;  // Returns true iff the flag was set.

  // For subtle reasons that may be different on different architectures,
  // a different thread testing IsSet() may erroneously read 'true' after
  // this method has been called.
  void UnsafeResetForTesting();

 private:
  base::subtle::Atomic32 flag_;
#if !defined(NDEBUG)
  PlatformThreadId set_on_;
#endif

  DISALLOW_COPY_AND_ASSIGN(CancellationFlag);
};

}  // namespace base

#endif  // BASE_SYNCHRONIZATION_CANCELLATION_FLAG_H_
