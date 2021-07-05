// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/geometry/size.h"

namespace impeller {
namespace testing {

TEST(GeometryTest, CanGenerateMipCounts) {
  ASSERT_EQ((Size{128, 128}.MipCount()), 7u);
  ASSERT_EQ((Size{128, 256}.MipCount()), 8u);
  ASSERT_EQ((Size{128, 130}.MipCount()), 8u);
  ASSERT_EQ((Size{128, 257}.MipCount()), 9u);
  ASSERT_EQ((Size{257, 128}.MipCount()), 9u);
  ASSERT_EQ((Size{128, 0}.MipCount()), 1u);
  ASSERT_EQ((Size{128, -25}.MipCount()), 1u);
  ASSERT_EQ((Size{-128, 25}.MipCount()), 1u);
}

}  // namespace testing
}  // namespace impeller
