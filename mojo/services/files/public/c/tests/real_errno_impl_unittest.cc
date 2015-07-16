// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/lib/real_errno_impl.h"

#include <errno.h>

#include "testing/gtest/include/gtest/gtest.h"

namespace mojio {
namespace {

TEST(RealErrnoImplTest, GetSet) {
  RealErrnoImpl errno_impl;

  errno = 123;
  EXPECT_EQ(123, errno_impl.Get());

  errno_impl.Set(456);
  EXPECT_EQ(456, errno);
}

}  // namespace
}  // namespace mojio
