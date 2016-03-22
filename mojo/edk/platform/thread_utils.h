// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_THREAD_UTILS_H_
#define MOJO_EDK_PLATFORM_THREAD_UTILS_H_

#include "mojo/public/c/system/time.h"

namespace mojo {
namespace platform {

// Causes the calling thread to try to yield (allowing another thread to be
// scheduled).
void ThreadYield();

// Causes the calling thread to sleep for at least the specified duration (which
// must not be |MOJO_DEADLINE_INDEFINITE|).
void ThreadSleep(MojoDeadline duration);

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_THREAD_UTILS_H_
