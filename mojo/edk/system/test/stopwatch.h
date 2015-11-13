// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A simple "stopwatch" for measuring elapsed time.

#ifndef MOJO_EDK_SYSTEM_TEST_STOPWATCH_H_
#define MOJO_EDK_SYSTEM_TEST_STOPWATCH_H_

#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {
namespace test {

// A simple "stopwatch" for measuring time elapsed from a given starting point.
class Stopwatch final {
 public:
  Stopwatch();
  ~Stopwatch();

  void Start();
  // Returns the amount of time elapsed since the last call to |Start()| (in
  // microseconds).
  MojoDeadline Elapsed();

 private:
  // TODO(vtl): We need this for |GetTimeTicksNow()|. Maybe we should have a
  // singleton for tests instead? Or maybe it should be injected?
  embedder::SimplePlatformSupport platform_support_;

  MojoTimeTicks start_time_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(Stopwatch);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_TEST_STOPWATCH_H_
