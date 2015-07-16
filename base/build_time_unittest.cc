// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/build_time.h"

#include "testing/gtest/include/gtest/gtest.h"

TEST(BuildTime, DateLooksValid) {
#if !defined(DONT_EMBED_BUILD_METADATA)
  char build_date[] = __DATE__;
#else
  char build_date[] = "Sep 02 2008";
#endif

  EXPECT_EQ(11u, strlen(build_date));
  EXPECT_EQ(' ', build_date[3]);
  EXPECT_EQ(' ', build_date[6]);
}

TEST(BuildTime, TimeLooksValid) {
#if defined(DONT_EMBED_BUILD_METADATA)
  char build_time[] = "08:00:00";
#else
  char build_time[] = __TIME__;
#endif

  EXPECT_EQ(8u, strlen(build_time));
  EXPECT_EQ(':', build_time[2]);
  EXPECT_EQ(':', build_time[5]);
}

TEST(BuildTime, DoesntCrash) {
  // Since __DATE__ isn't updated unless one does a clobber build, we can't
  // really test the value returned by it, except to check that it doesn't
  // crash.
  base::GetBuildTime();
}
