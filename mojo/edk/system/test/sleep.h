// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Function for sleeping in tests. (Please use sparingly.)

#ifndef MOJO_EDK_SYSTEM_TEST_SLEEP_H_
#define MOJO_EDK_SYSTEM_TEST_SLEEP_H_

#include "mojo/public/c/system/types.h"

namespace mojo {
namespace system {
namespace test {

// Sleeps for at least the specified duration.
void Sleep(MojoDeadline duration);
void SleepMilliseconds(unsigned duration_milliseconds);

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_SLEEP_H_
