// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The spike's test: a gtest binary that runs under Fuchsia's gtest runner
// and checks that it is running on Fuchsia with the sysroot the IDK ships.

#include <zircon/syscalls.h>
#include <zircon/types.h>

#include <string>

#include "gtest/gtest.h"

namespace {

TEST(Spike, RunsOnFuchsia) {
#if defined(__Fuchsia__)
  SUCCEED();
#else
  FAIL() << "not compiled for Fuchsia";
#endif
}

TEST(Spike, SyscallsLink) {
  // The sysroot's libzircon: a system-call that cannot fail.
  const zx_time_t ticks = zx_ticks_get();
  EXPECT_GE(ticks, 0);
  const zx_ticks_t per_second = zx_ticks_per_second();
  EXPECT_GT(per_second, 0);
}

TEST(Spike, StandardLibrary) {
  const std::string hello = "hello, " + std::string("fuchsia");
  EXPECT_EQ(hello, "hello, fuchsia");
}

}  // namespace
