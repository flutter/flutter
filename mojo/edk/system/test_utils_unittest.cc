// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/test_utils.h"

#include <limits>

#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace test {
namespace {

TEST(TestUtilsTest, RandomInt) {
  static const int kMin = -3;
  static const int kMax = 6;
  static const unsigned kNumBuckets = kMax - kMin + 1;
  unsigned buckets[kNumBuckets];

  static const unsigned kIterations = 10000;
  for (unsigned i = 0; i < kIterations; i++) {
    int value = RandomInt(kMin, kMax);
    ASSERT_GE(value, kMin);
    ASSERT_LE(value, kMax);
    buckets[value - kMin]++;
  }

  for (unsigned i = 0; i < kNumBuckets; i++) {
    // The odds that a value in any bucket is less than the expected value
    // should be very  small (if |kIterations| is sufficiently large compared to
    // |kNumBuckets|).
    // TODO(vtl): Actually calculate these odds, and maybe raise the proportion
    // to something (much) larger than "half".
    EXPECT_GE(buckets[i], kIterations / kNumBuckets / 2);
  }
}

TEST(TestUtilsTest, RandomIntSameValues) {
  static const int kIntMin = std::numeric_limits<int>::min();
  EXPECT_EQ(kIntMin, RandomInt(kIntMin, kIntMin));

  static const int kIntMax = std::numeric_limits<int>::max();
  EXPECT_EQ(kIntMax, RandomInt(kIntMax, kIntMax));

  EXPECT_EQ(0, RandomInt(0, 0));
}

}  // namespace
}  // namespace test
}  // namespace system
}  // namespace mojo
