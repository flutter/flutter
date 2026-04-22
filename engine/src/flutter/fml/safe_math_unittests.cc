// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>

#include "flutter/fml/safe_math.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(SafeMathTest, MultiplySizeT) {
  // Multiplication with no overflow.
  fml::SafeMath safe1;
  EXPECT_EQ(safe1.mul(1000, 2000), static_cast<size_t>(2000000));
  EXPECT_FALSE(safe1.overflow_detected());

  // Overflow detection when multiplying size_t values at or near the maximum.
  fml::SafeMath safe2;
  safe2.mul(std::numeric_limits<size_t>::max(),
            std::numeric_limits<size_t>::max());
  EXPECT_TRUE(safe2.overflow_detected());

  fml::SafeMath safe3;
  safe3.mul(std::numeric_limits<size_t>::max() >> 2, 5);
  EXPECT_TRUE(safe3.overflow_detected());

  // Overflow detection for a result that slightly exceeds the range of a
  // uint64_t.
  if (sizeof(size_t) == sizeof(uint64_t)) {
    fml::SafeMath safe4;
    safe4.mul(static_cast<size_t>(1ULL << 32), static_cast<size_t>(1ULL << 32));
    EXPECT_TRUE(safe4.overflow_detected());
  }
}

}  // namespace testing
}  // namespace flutter
