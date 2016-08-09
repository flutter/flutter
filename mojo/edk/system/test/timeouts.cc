// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test/timeouts.h"

#include "base/test/test_timeouts.h"
#include "build/build_config.h"

namespace mojo {
namespace system {
namespace test {

MojoDeadline DeadlineFromMilliseconds(unsigned milliseconds) {
  return static_cast<MojoDeadline>(milliseconds) * 1000;
}

MojoDeadline EpsilonTimeout() {
// Currently, |tiny_timeout()| is usually 100 ms (possibly scaled under ASAN,
// etc.). Based on this, set it to (usually be) 30 ms on Android and 20 ms
// elsewhere. (We'd like this to be as small as possible, without making things
// flaky)
#if defined(OS_ANDROID)
  return (TinyTimeout() * 3) / 10;
#else
  return (TinyTimeout() * 2) / 10;
#endif
}

MojoDeadline TinyTimeout() {
  return static_cast<MojoDeadline>(
      TestTimeouts::tiny_timeout().InMicroseconds());
}

MojoDeadline ActionTimeout() {
  return static_cast<MojoDeadline>(
      TestTimeouts::action_timeout().InMicroseconds());
}

}  // namespace test
}  // namespace system
}  // namespace mojo
