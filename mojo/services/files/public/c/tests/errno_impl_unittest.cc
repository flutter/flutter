// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This basically tests |ErrnoImpl::Setter|, since |ErrnoImpl| itself is just a
// simple interface.

#include "files/public/c/lib/errno_impl.h"

#include "files/public/c/tests/mock_errno_impl.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojio {
namespace {

TEST(ErrnoImplTest, Setter) {
  const int kLastErrorSentinel = -12345;

  test::MockErrnoImpl errno_impl(-123);

  // Make sure |TestErrnoImpl| isn't totally broken.
  ASSERT_EQ(-123, errno_impl.Get());
  ASSERT_FALSE(errno_impl.was_set());

  errno_impl.Set(-456);
  ASSERT_EQ(-456, errno_impl.Get());
  ASSERT_TRUE(errno_impl.was_set());

  errno_impl.Reset(kLastErrorSentinel);
  {
    ErrnoImpl::Setter setter(&errno_impl);
    EXPECT_TRUE(setter.Set(0));
    EXPECT_FALSE(errno_impl.was_set());  // Shouldn't be set until destruction.
    // We may fiddle with the value.
    errno_impl.Reset(123);
  }
  EXPECT_TRUE(errno_impl.was_set());
  // But it'll be reset to the original value.
  EXPECT_EQ(kLastErrorSentinel, errno_impl.Get());

  errno_impl.Reset(kLastErrorSentinel);
  {
    ErrnoImpl::Setter setter(&errno_impl);
    // We may fiddle with the value.
    errno_impl.Reset(78);
    EXPECT_FALSE(setter.Set(456));
    // We may fiddle with the value again.
    errno_impl.Reset(90);
    EXPECT_FALSE(errno_impl.was_set());  // Shouldn't be set until destruction.
  }
  EXPECT_TRUE(errno_impl.was_set());
  // But it'll be set to the explicitly-set value.
  EXPECT_EQ(456, errno_impl.Get());
}

}  // namespace
}  // namespace mojio
