// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_PLATFORM_TIME_TICKS_H_
#define MOJO_EDK_PLATFORM_TIME_TICKS_H_

#include "mojo/public/c/system/time.h"

namespace mojo {
namespace platform {

// Gets the number of microseconds elapsed since an undefined epoch. (This is
// from a monotonic clock of undefined resolution.)
//
// Implementations of this function should be thread-safe. The returned value
// should be non-negative, and nondecreasing with respect to time/causality
// including across threads (as observable).
//
// TODO(vtl): Add different types of clocks. (What does "monotonic" mean exactly
// -- does it continue to "run" in various "sleep" states?)
MojoTimeTicks GetTimeTicks();

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_TIME_TICKS_H_
