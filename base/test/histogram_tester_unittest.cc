// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/histogram_tester.h"

#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram_macros.h"
#include "base/metrics/histogram_samples.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

using ::testing::ElementsAre;

const std::string kHistogram1 = "Test1";
const std::string kHistogram2 = "Test2";
const std::string kHistogram3 = "Test3";
const std::string kHistogram4 = "Test4";
const std::string kHistogram5 = "Test5";

typedef testing::Test HistogramTesterTest;

TEST_F(HistogramTesterTest, Scope) {
  // Record a histogram before the creation of the recorder.
  UMA_HISTOGRAM_BOOLEAN(kHistogram1, true);

  HistogramTester tester;

  // Verify that no histogram is recorded.
  scoped_ptr<HistogramSamples> samples(
      tester.GetHistogramSamplesSinceCreation(kHistogram1));
  EXPECT_FALSE(samples);

  // Record a histogram after the creation of the recorder.
  UMA_HISTOGRAM_BOOLEAN(kHistogram1, true);

  // Verify that one histogram is recorded.
  samples = tester.GetHistogramSamplesSinceCreation(kHistogram1);
  EXPECT_TRUE(samples);
  EXPECT_EQ(1, samples->TotalCount());
}

TEST_F(HistogramTesterTest, TestUniqueSample) {
  HistogramTester tester;

  // Record into a sample thrice
  UMA_HISTOGRAM_COUNTS_100(kHistogram2, 2);
  UMA_HISTOGRAM_COUNTS_100(kHistogram2, 2);
  UMA_HISTOGRAM_COUNTS_100(kHistogram2, 2);

  tester.ExpectUniqueSample(kHistogram2, 2, 3);
}

TEST_F(HistogramTesterTest, TestBucketsSample) {
  HistogramTester tester;

  // Record into a sample twice
  UMA_HISTOGRAM_COUNTS_100(kHistogram3, 2);
  UMA_HISTOGRAM_COUNTS_100(kHistogram3, 2);
  UMA_HISTOGRAM_COUNTS_100(kHistogram3, 2);
  UMA_HISTOGRAM_COUNTS_100(kHistogram3, 2);
  UMA_HISTOGRAM_COUNTS_100(kHistogram3, 3);

  tester.ExpectBucketCount(kHistogram3, 2, 4);
  tester.ExpectBucketCount(kHistogram3, 3, 1);

  tester.ExpectTotalCount(kHistogram3, 5);
}

TEST_F(HistogramTesterTest, TestBucketsSampleWithScope) {
  // Record into a sample twice, once before the tester creation and once after.
  UMA_HISTOGRAM_COUNTS_100(kHistogram4, 2);

  HistogramTester tester;
  UMA_HISTOGRAM_COUNTS_100(kHistogram4, 3);

  tester.ExpectBucketCount(kHistogram4, 2, 0);
  tester.ExpectBucketCount(kHistogram4, 3, 1);

  tester.ExpectTotalCount(kHistogram4, 1);
}

TEST_F(HistogramTesterTest, TestGetAllSamples) {
  HistogramTester tester;
  UMA_HISTOGRAM_ENUMERATION(kHistogram5, 2, 5);
  UMA_HISTOGRAM_ENUMERATION(kHistogram5, 3, 5);
  UMA_HISTOGRAM_ENUMERATION(kHistogram5, 3, 5);
  UMA_HISTOGRAM_ENUMERATION(kHistogram5, 5, 5);

  EXPECT_THAT(tester.GetAllSamples(kHistogram5),
              ElementsAre(Bucket(2, 1), Bucket(3, 2), Bucket(5, 1)));
}

}  // namespace base
