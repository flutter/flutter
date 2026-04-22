// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <limits>

#include "flutter/fml/safe_math.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(SafeMathTest, MultiplySizeT) {
  fml::SafeMath safe1;
  safe1.mul(std::numeric_limits<size_t>::max(),
            std::numeric_limits<size_t>::max());
  EXPECT_TRUE(safe1.overflow_detected());

  fml::SafeMath safe2;
  EXPECT_EQ(safe2.mul(1000, 2000), static_cast<size_t>(2000000));
  EXPECT_FALSE(safe2.overflow_detected());

  fml::SafeMath safe3;
  safe3.mul(std::numeric_limits<size_t>::max() >> 2, 5);
  EXPECT_TRUE(safe3.overflow_detected());

  if (sizeof(size_t) == sizeof(uint64_t)) {
    fml::SafeMath safe4;
    safe4.mul(static_cast<size_t>(1ULL << 32), static_cast<size_t>(1ULL << 32));
    EXPECT_TRUE(safe4.overflow_detected());
  }
}

}  // namespace testing
}  // namespace flutter
