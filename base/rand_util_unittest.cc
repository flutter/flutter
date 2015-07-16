// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/rand_util.h"

#include <algorithm>
#include <limits>

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/time/time.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

const int kIntMin = std::numeric_limits<int>::min();
const int kIntMax = std::numeric_limits<int>::max();

}  // namespace

TEST(RandUtilTest, SameMinAndMax) {
  EXPECT_EQ(base::RandInt(0, 0), 0);
  EXPECT_EQ(base::RandInt(kIntMin, kIntMin), kIntMin);
  EXPECT_EQ(base::RandInt(kIntMax, kIntMax), kIntMax);
}

TEST(RandUtilTest, RandDouble) {
  // Force 64-bit precision, making sure we're not in a 80-bit FPU register.
  volatile double number = base::RandDouble();
  EXPECT_GT(1.0, number);
  EXPECT_LE(0.0, number);
}

TEST(RandUtilTest, RandBytes) {
  const size_t buffer_size = 50;
  char buffer[buffer_size];
  memset(buffer, 0, buffer_size);
  base::RandBytes(buffer, buffer_size);
  std::sort(buffer, buffer + buffer_size);
  // Probability of occurrence of less than 25 unique bytes in 50 random bytes
  // is below 10^-25.
  EXPECT_GT(std::unique(buffer, buffer + buffer_size) - buffer, 25);
}

TEST(RandUtilTest, RandBytesAsString) {
  std::string random_string = base::RandBytesAsString(1);
  EXPECT_EQ(1U, random_string.size());
  random_string = base::RandBytesAsString(145);
  EXPECT_EQ(145U, random_string.size());
  char accumulator = 0;
  for (size_t i = 0; i < random_string.size(); ++i)
    accumulator |= random_string[i];
  // In theory this test can fail, but it won't before the universe dies of
  // heat death.
  EXPECT_NE(0, accumulator);
}

// Make sure that it is still appropriate to use RandGenerator in conjunction
// with std::random_shuffle().
TEST(RandUtilTest, RandGeneratorForRandomShuffle) {
  EXPECT_EQ(base::RandGenerator(1), 0U);
  EXPECT_LE(std::numeric_limits<ptrdiff_t>::max(),
            std::numeric_limits<int64>::max());
}

TEST(RandUtilTest, RandGeneratorIsUniform) {
  // Verify that RandGenerator has a uniform distribution. This is a
  // regression test that consistently failed when RandGenerator was
  // implemented this way:
  //
  //   return base::RandUint64() % max;
  //
  // A degenerate case for such an implementation is e.g. a top of
  // range that is 2/3rds of the way to MAX_UINT64, in which case the
  // bottom half of the range would be twice as likely to occur as the
  // top half. A bit of calculus care of jar@ shows that the largest
  // measurable delta is when the top of the range is 3/4ths of the
  // way, so that's what we use in the test.
  const uint64 kTopOfRange = (std::numeric_limits<uint64>::max() / 4ULL) * 3ULL;
  const uint64 kExpectedAverage = kTopOfRange / 2ULL;
  const uint64 kAllowedVariance = kExpectedAverage / 50ULL;  // +/- 2%
  const int kMinAttempts = 1000;
  const int kMaxAttempts = 1000000;

  double cumulative_average = 0.0;
  int count = 0;
  while (count < kMaxAttempts) {
    uint64 value = base::RandGenerator(kTopOfRange);
    cumulative_average = (count * cumulative_average + value) / (count + 1);

    // Don't quit too quickly for things to start converging, or we may have
    // a false positive.
    if (count > kMinAttempts &&
        kExpectedAverage - kAllowedVariance < cumulative_average &&
        cumulative_average < kExpectedAverage + kAllowedVariance) {
      break;
    }

    ++count;
  }

  ASSERT_LT(count, kMaxAttempts) << "Expected average was " <<
      kExpectedAverage << ", average ended at " << cumulative_average;
}

TEST(RandUtilTest, RandUint64ProducesBothValuesOfAllBits) {
  // This tests to see that our underlying random generator is good
  // enough, for some value of good enough.
  uint64 kAllZeros = 0ULL;
  uint64 kAllOnes = ~kAllZeros;
  uint64 found_ones = kAllZeros;
  uint64 found_zeros = kAllOnes;

  for (size_t i = 0; i < 1000; ++i) {
    uint64 value = base::RandUint64();
    found_ones |= value;
    found_zeros &= value;

    if (found_zeros == kAllZeros && found_ones == kAllOnes)
      return;
  }

  FAIL() << "Didn't achieve all bit values in maximum number of tries.";
}

// Benchmark test for RandBytes().  Disabled since it's intentionally slow and
// does not test anything that isn't already tested by the existing RandBytes()
// tests.
TEST(RandUtilTest, DISABLED_RandBytesPerf) {
  // Benchmark the performance of |kTestIterations| of RandBytes() using a
  // buffer size of |kTestBufferSize|.
  const int kTestIterations = 10;
  const size_t kTestBufferSize = 1 * 1024 * 1024;

  scoped_ptr<uint8[]> buffer(new uint8[kTestBufferSize]);
  const base::TimeTicks now = base::TimeTicks::Now();
  for (int i = 0; i < kTestIterations; ++i)
    base::RandBytes(buffer.get(), kTestBufferSize);
  const base::TimeTicks end = base::TimeTicks::Now();

  LOG(INFO) << "RandBytes(" << kTestBufferSize << ") took: "
            << (end - now).InMicroseconds() << "µs";
}
