// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Test timeouts.

#ifndef MOJO_EDK_SYSTEM_TEST_TIMEOUTS_H_
#define MOJO_EDK_SYSTEM_TEST_TIMEOUTS_H_

#include "mojo/public/c/system/time.h"

namespace mojo {
namespace system {
namespace test {

MojoDeadline DeadlineFromMilliseconds(unsigned milliseconds);

// A timeout smaller than |TestTimeouts::tiny_timeout()|, as a |MojoDeadline|.
// Warning: This may lead to flakiness, but this is unavoidable if, e.g., you're
// trying to ensure that functions with timeouts are reasonably accurate. We
// want this to be as small as possible without causing too much flakiness.
MojoDeadline EpsilonTimeout();

// |TestTimeouts::tiny_timeout()|, as a |MojoDeadline|. (Expect this to be on
// the order of 100 ms.)
MojoDeadline TinyTimeout();

// |TestTimeouts::action_timeout()|, as a |MojoDeadline|. (Expect this to be on
// the order of 10 s.)
MojoDeadline ActionTimeout();

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_TIMEOUTS_H_
