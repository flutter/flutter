// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <errno.h>

#include "base/scoped_clear_errno.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(ScopedClearErrno, TestNoError) {
  errno = 1;
  {
    ScopedClearErrno clear_error;
    EXPECT_EQ(0, errno);
  }
  EXPECT_EQ(1, errno);
}

TEST(ScopedClearErrno, TestError) {
  errno = 1;
  {
    ScopedClearErrno clear_error;
    errno = 2;
  }
  EXPECT_EQ(2, errno);
}

}  // namespace base
