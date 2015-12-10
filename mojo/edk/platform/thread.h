// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides an interface for extremely abstract threads.

#ifndef MOJO_EDK_PLATFORM_THREAD_H_
#define MOJO_EDK_PLATFORM_THREAD_H_

#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace platform {

// An interface for an abstract "thread". Implementations are typically not
// thread-safe and should be used only on the thread it was created on.
class Thread {
 public:
  // Note: If "started", the thread must be joined (i.e., |Stop()| must be
  // called) before destruction.
  virtual ~Thread() {}

  // Requests that the thread stop (if applicable) and joins it.
  virtual void Stop() = 0;

 protected:
  Thread() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(Thread);
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_THREAD_H_
