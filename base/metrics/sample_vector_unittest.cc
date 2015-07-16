// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/sample_vector.h"

#include <vector>

#include "base/memory/scoped_ptr.h"
#include "base/metrics/bucket_ranges.h"
#include "base/metrics/histogram.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

TEST(SampleVectorTest, AccumulateTest) {
  // Custom buckets: [1, 5) [5, 10)
  BucketRanges ranges(3);
  ranges.set_range(0, 1);
  ranges.set_range(1, 5);
  ranges.set_range(2, 10);
  SampleVector samples(&ranges);

  samples.Accumulate(1, 200);
  samples.Accumulate(2, -300);
  EXPECT_EQ(-100, samples.GetCountAtIndex(0));

  samples.Accumulate(5, 200);
  EXPECT_EQ(200, samples.GetCountAtIndex(1));

  EXPECT_EQ(600, samples.sum());
  EXPECT_EQ(100, samples.redundant_count());
  EXPECT_EQ(samples.TotalCount(), samples.redundant_count());

  samples.Accumulate(5, -100);
  EXPECT_EQ(100, samples.GetCountAtIndex(1));

  EXPECT_EQ(100, samples.sum());
  EXPECT_EQ(0, samples.redundant_count());
  EXPECT_EQ(samples.TotalCount(), samples.redundant_count());
}

TEST(SampleVectorTest, AddSubtractTest) {
  // Custom buckets: [0, 1) [1, 2) [2, 3) [3, INT_MAX)
  BucketRanges ranges(5);
  ranges.set_range(0, 0);
  ranges.set_range(1, 1);
  ranges.set_range(2, 2);
  ranges.set_range(3, 3);
  ranges.set_range(4, INT_MAX);

  SampleVector samples1(&ranges);
  samples1.Accumulate(0, 100);
  samples1.Accumulate(2, 100);
  samples1.Accumulate(4, 100);
  EXPECT_EQ(600, samples1.sum());
  EXPECT_EQ(300, samples1.TotalCount());
  EXPECT_EQ(samples1.redundant_count(), samples1.TotalCount());

  SampleVector samples2(&ranges);
  samples2.Accumulate(1, 200);
  samples2.Accumulate(2, 200);
  samples2.Accumulate(4, 200);
  EXPECT_EQ(1400, samples2.sum());
  EXPECT_EQ(600, samples2.TotalCount());
  EXPECT_EQ(samples2.redundant_count(), samples2.TotalCount());

  samples1.Add(samples2);
  EXPECT_EQ(100, samples1.GetCountAtIndex(0));
  EXPECT_EQ(200, samples1.GetCountAtIndex(1));
  EXPECT_EQ(300, samples1.GetCountAtIndex(2));
  EXPECT_EQ(300, samples1.GetCountAtIndex(3));
  EXPECT_EQ(2000, samples1.sum());
  EXPECT_EQ(900, samples1.TotalCount());
  EXPECT_EQ(samples1.redundant_count(), samples1.TotalCount());

  samples1.Subtract(samples2);
  EXPECT_EQ(100, samples1.GetCountAtIndex(0));
  EXPECT_EQ(0, samples1.GetCountAtIndex(1));
  EXPECT_EQ(100, samples1.GetCountAtIndex(2));
  EXPECT_EQ(100, samples1.GetCountAtIndex(3));
  EXPECT_EQ(600, samples1.sum());
  EXPECT_EQ(300, samples1.TotalCount());
  EXPECT_EQ(samples1.redundant_count(), samples1.TotalCount());
}

#if (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)) && GTEST_HAS_DEATH_TEST
TEST(SampleVectorDeathTest, BucketIndexTest) {
  // 8 buckets with exponential layout:
  // [0, 1) [1, 2) [2, 4) [4, 8) [8, 16) [16, 32) [32, 64) [64, INT_MAX)
  BucketRanges ranges(9);
  Histogram::InitializeBucketRanges(1, 64, &ranges);
  SampleVector samples(&ranges);

  // Normal case
  samples.Accumulate(0, 1);
  samples.Accumulate(3, 2);
  samples.Accumulate(64, 3);
  EXPECT_EQ(1, samples.GetCount(0));
  EXPECT_EQ(2, samples.GetCount(2));
  EXPECT_EQ(3, samples.GetCount(65));

  // Extreme case.
  EXPECT_DEATH(samples.Accumulate(INT_MIN, 100), "");
  EXPECT_DEATH(samples.Accumulate(-1, 100), "");
  EXPECT_DEATH(samples.Accumulate(INT_MAX, 100), "");

  // Custom buckets: [1, 5) [5, 10)
  // Note, this is not a valid BucketRanges for Histogram because it does not
  // have overflow buckets.
  BucketRanges ranges2(3);
  ranges2.set_range(0, 1);
  ranges2.set_range(1, 5);
  ranges2.set_range(2, 10);
  SampleVector samples2(&ranges2);

  // Normal case.
  samples2.Accumulate(1, 1);
  samples2.Accumulate(4, 1);
  samples2.Accumulate(5, 2);
  samples2.Accumulate(9, 2);
  EXPECT_EQ(2, samples2.GetCount(1));
  EXPECT_EQ(4, samples2.GetCount(5));

  // Extreme case.
  EXPECT_DEATH(samples2.Accumulate(0, 100), "");
  EXPECT_DEATH(samples2.Accumulate(10, 100), "");
}

TEST(SampleVectorDeathTest, AddSubtractBucketNotMatchTest) {
  // Custom buckets 1: [1, 3) [3, 5)
  BucketRanges ranges1(3);
  ranges1.set_range(0, 1);
  ranges1.set_range(1, 3);
  ranges1.set_range(2, 5);
  SampleVector samples1(&ranges1);

  // Custom buckets 2: [0, 1) [1, 3) [3, 6) [6, 7)
  BucketRanges ranges2(5);
  ranges2.set_range(0, 0);
  ranges2.set_range(1, 1);
  ranges2.set_range(2, 3);
  ranges2.set_range(3, 6);
  ranges2.set_range(4, 7);
  SampleVector samples2(&ranges2);

  samples2.Accumulate(1, 100);
  samples1.Add(samples2);
  EXPECT_EQ(100, samples1.GetCountAtIndex(0));

  // Extra bucket in the beginning.
  samples2.Accumulate(0, 100);
  EXPECT_DEATH(samples1.Add(samples2), "");
  EXPECT_DEATH(samples1.Subtract(samples2), "");

  // Extra bucket in the end.
  samples2.Accumulate(0, -100);
  samples2.Accumulate(6, 100);
  EXPECT_DEATH(samples1.Add(samples2), "");
  EXPECT_DEATH(samples1.Subtract(samples2), "");

  // Bucket not match: [3, 5) VS [3, 6)
  samples2.Accumulate(6, -100);
  samples2.Accumulate(3, 100);
  EXPECT_DEATH(samples1.Add(samples2), "");
  EXPECT_DEATH(samples1.Subtract(samples2), "");
}

#endif
// (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)) && GTEST_HAS_DEATH_TEST

TEST(SampleVectorIteratorTest, IterateTest) {
  BucketRanges ranges(5);
  ranges.set_range(0, 0);
  ranges.set_range(1, 1);
  ranges.set_range(2, 2);
  ranges.set_range(3, 3);
  ranges.set_range(4, 4);

  std::vector<HistogramBase::Count> counts(3);
  counts[0] = 1;
  counts[1] = 0;  // Iterator will bypass this empty bucket.
  counts[2] = 2;

  // BucketRanges can have larger size than counts.
  SampleVectorIterator it(&counts, &ranges);
  size_t index;

  HistogramBase::Sample min;
  HistogramBase::Sample max;
  HistogramBase::Count count;
  it.Get(&min, &max, &count);
  EXPECT_EQ(0, min);
  EXPECT_EQ(1, max);
  EXPECT_EQ(1, count);
  EXPECT_TRUE(it.GetBucketIndex(&index));
  EXPECT_EQ(0u, index);

  it.Next();
  it.Get(&min, &max, &count);
  EXPECT_EQ(2, min);
  EXPECT_EQ(3, max);
  EXPECT_EQ(2, count);
  EXPECT_TRUE(it.GetBucketIndex(&index));
  EXPECT_EQ(2u, index);

  it.Next();
  EXPECT_TRUE(it.Done());

  // Create iterator from SampleVector.
  SampleVector samples(&ranges);
  samples.Accumulate(0, 0);
  samples.Accumulate(1, 1);
  samples.Accumulate(2, 2);
  samples.Accumulate(3, 3);
  scoped_ptr<SampleCountIterator> it2 = samples.Iterator();

  int i;
  for (i = 1; !it2->Done(); i++, it2->Next()) {
    it2->Get(&min, &max, &count);
    EXPECT_EQ(i, min);
    EXPECT_EQ(i + 1, max);
    EXPECT_EQ(i, count);

    size_t index;
    EXPECT_TRUE(it2->GetBucketIndex(&index));
    EXPECT_EQ(static_cast<size_t>(i), index);
  }
  EXPECT_EQ(4, i);
}

#if (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)) && GTEST_HAS_DEATH_TEST

TEST(SampleVectorIteratorDeathTest, IterateDoneTest) {
  BucketRanges ranges(5);
  ranges.set_range(0, 0);
  ranges.set_range(1, 1);
  ranges.set_range(2, 2);
  ranges.set_range(3, 3);
  ranges.set_range(4, INT_MAX);
  SampleVector samples(&ranges);

  scoped_ptr<SampleCountIterator> it = samples.Iterator();

  EXPECT_TRUE(it->Done());

  HistogramBase::Sample min;
  HistogramBase::Sample max;
  HistogramBase::Count count;
  EXPECT_DEATH(it->Get(&min, &max, &count), "");

  EXPECT_DEATH(it->Next(), "");

  samples.Accumulate(2, 100);
  it = samples.Iterator();
  EXPECT_FALSE(it->Done());
}

#endif
// (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)) && GTEST_HAS_DEATH_TEST

}  // namespace
}  // namespace base
