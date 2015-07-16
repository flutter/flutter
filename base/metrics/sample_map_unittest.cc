// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/sample_map.h"

#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

TEST(SampleMapTest, AccumulateTest) {
  SampleMap samples;

  samples.Accumulate(1, 100);
  samples.Accumulate(2, 200);
  samples.Accumulate(1, -200);
  EXPECT_EQ(-100, samples.GetCount(1));
  EXPECT_EQ(200, samples.GetCount(2));

  EXPECT_EQ(300, samples.sum());
  EXPECT_EQ(100, samples.TotalCount());
  EXPECT_EQ(samples.redundant_count(), samples.TotalCount());
}

TEST(SampleMapTest, AddSubtractTest) {
  SampleMap samples1;
  SampleMap samples2;

  samples1.Accumulate(1, 100);
  samples1.Accumulate(2, 100);
  samples1.Accumulate(3, 100);

  samples2.Accumulate(1, 200);
  samples2.Accumulate(2, 200);
  samples2.Accumulate(4, 200);

  samples1.Add(samples2);
  EXPECT_EQ(300, samples1.GetCount(1));
  EXPECT_EQ(300, samples1.GetCount(2));
  EXPECT_EQ(100, samples1.GetCount(3));
  EXPECT_EQ(200, samples1.GetCount(4));
  EXPECT_EQ(2000, samples1.sum());
  EXPECT_EQ(900, samples1.TotalCount());
  EXPECT_EQ(samples1.redundant_count(), samples1.TotalCount());

  samples1.Subtract(samples2);
  EXPECT_EQ(100, samples1.GetCount(1));
  EXPECT_EQ(100, samples1.GetCount(2));
  EXPECT_EQ(100, samples1.GetCount(3));
  EXPECT_EQ(0, samples1.GetCount(4));
  EXPECT_EQ(600, samples1.sum());
  EXPECT_EQ(300, samples1.TotalCount());
  EXPECT_EQ(samples1.redundant_count(), samples1.TotalCount());
}

TEST(SampleMapIteratorTest, IterateTest) {
  SampleMap samples;
  samples.Accumulate(1, 100);
  samples.Accumulate(2, 200);
  samples.Accumulate(4, -300);
  samples.Accumulate(5, 0);

  scoped_ptr<SampleCountIterator> it = samples.Iterator();

  HistogramBase::Sample min;
  HistogramBase::Sample max;
  HistogramBase::Count count;

  it->Get(&min, &max, &count);
  EXPECT_EQ(1, min);
  EXPECT_EQ(2, max);
  EXPECT_EQ(100, count);
  EXPECT_FALSE(it->GetBucketIndex(NULL));

  it->Next();
  it->Get(&min, &max, &count);
  EXPECT_EQ(2, min);
  EXPECT_EQ(3, max);
  EXPECT_EQ(200, count);

  it->Next();
  it->Get(&min, &max, &count);
  EXPECT_EQ(4, min);
  EXPECT_EQ(5, max);
  EXPECT_EQ(-300, count);

  it->Next();
  EXPECT_TRUE(it->Done());
}

TEST(SampleMapIteratorTest, SkipEmptyRanges) {
  SampleMap samples;
  samples.Accumulate(5, 1);
  samples.Accumulate(10, 2);
  samples.Accumulate(15, 3);
  samples.Accumulate(20, 4);
  samples.Accumulate(25, 5);

  SampleMap samples2;
  samples2.Accumulate(5, 1);
  samples2.Accumulate(20, 4);
  samples2.Accumulate(25, 5);

  samples.Subtract(samples2);

  scoped_ptr<SampleCountIterator> it = samples.Iterator();
  EXPECT_FALSE(it->Done());

  HistogramBase::Sample min;
  HistogramBase::Sample max;
  HistogramBase::Count count;

  it->Get(&min, &max, &count);
  EXPECT_EQ(10, min);
  EXPECT_EQ(11, max);
  EXPECT_EQ(2, count);

  it->Next();
  EXPECT_FALSE(it->Done());

  it->Get(&min, &max, &count);
  EXPECT_EQ(15, min);
  EXPECT_EQ(16, max);
  EXPECT_EQ(3, count);

  it->Next();
  EXPECT_TRUE(it->Done());
}

#if (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)) && GTEST_HAS_DEATH_TEST

TEST(SampleMapIteratorDeathTest, IterateDoneTest) {
  SampleMap samples;

  scoped_ptr<SampleCountIterator> it = samples.Iterator();

  EXPECT_TRUE(it->Done());

  HistogramBase::Sample min;
  HistogramBase::Sample max;
  HistogramBase::Count count;
  EXPECT_DEATH(it->Get(&min, &max, &count), "");

  EXPECT_DEATH(it->Next(), "");

  samples.Accumulate(1, 100);
  it = samples.Iterator();
  EXPECT_FALSE(it->Done());
}

#endif
// (!defined(NDEBUG) || defined(DCHECK_ALWAYS_ON)) && GTEST_HAS_DEATH_TEST

}  // namespace
}  // namespace base
