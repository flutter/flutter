// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_TEST_UTILS_H_
#define MOJO_EDK_SYSTEM_TEST_UTILS_H_

#include "base/time/time.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {
namespace test {

MojoDeadline DeadlineFromMilliseconds(unsigned milliseconds);

// A timeout smaller than |TestTimeouts::tiny_timeout()|, as a |MojoDeadline|.
// Warning: This may lead to flakiness, but this is unavoidable if, e.g., you're
// trying to ensure that functions with timeouts are reasonably accurate. We
// want this to be as small as possible without causing too much flakiness.
MojoDeadline EpsilonDeadline();

// |TestTimeouts::tiny_timeout()|, as a |MojoDeadline|. (Expect this to be on
// the order of 100 ms.)
MojoDeadline TinyDeadline();

// |TestTimeouts::action_timeout()|, as a |MojoDeadline|. (Expect this to be on
// the order of 10 s.)
MojoDeadline ActionDeadline();

// Sleeps for at least the specified duration.
void Sleep(MojoDeadline deadline);

// Stopwatch -------------------------------------------------------------------

// A simple "stopwatch" for measuring time elapsed from a given starting point.
class Stopwatch {
 public:
  Stopwatch();
  ~Stopwatch();

  void Start();
  // Returns the amount of time elapsed since the last call to |Start()| (in
  // microseconds).
  MojoDeadline Elapsed();

 private:
  base::TimeTicks start_time_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Stopwatch);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_UTILS_H_
