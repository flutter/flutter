// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "base/metrics/histogram.h"
#include "base/metrics/histogram_base.h"
#include "base/metrics/sparse_histogram.h"
#include "base/metrics/statistics_recorder.h"
#include "base/pickle.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

class HistogramBaseTest : public testing::Test {
 protected:
  HistogramBaseTest() {
    // Each test will have a clean state (no Histogram / BucketRanges
    // registered).
    statistics_recorder_ = NULL;
    ResetStatisticsRecorder();
  }

  ~HistogramBaseTest() override { delete statistics_recorder_; }

  void ResetStatisticsRecorder() {
    delete statistics_recorder_;
    statistics_recorder_ = new StatisticsRecorder();
  }

 private:
  StatisticsRecorder* statistics_recorder_;
};

TEST_F(HistogramBaseTest, DeserializeHistogram) {
  HistogramBase* histogram = Histogram::FactoryGet(
      "TestHistogram", 1, 1000, 10,
      (HistogramBase::kUmaTargetedHistogramFlag |
      HistogramBase::kIPCSerializationSourceFlag));

  Pickle pickle;
  ASSERT_TRUE(histogram->SerializeInfo(&pickle));

  PickleIterator iter(pickle);
  HistogramBase* deserialized = DeserializeHistogramInfo(&iter);
  EXPECT_EQ(histogram, deserialized);

  ResetStatisticsRecorder();

  PickleIterator iter2(pickle);
  deserialized = DeserializeHistogramInfo(&iter2);
  EXPECT_TRUE(deserialized);
  EXPECT_NE(histogram, deserialized);
  EXPECT_EQ("TestHistogram", deserialized->histogram_name());
  EXPECT_TRUE(deserialized->HasConstructionArguments(1, 1000, 10));

  // kIPCSerializationSourceFlag will be cleared.
  EXPECT_EQ(HistogramBase::kUmaTargetedHistogramFlag, deserialized->flags());
}

TEST_F(HistogramBaseTest, DeserializeLinearHistogram) {
  HistogramBase* histogram = LinearHistogram::FactoryGet(
      "TestHistogram", 1, 1000, 10,
      HistogramBase::kIPCSerializationSourceFlag);

  Pickle pickle;
  ASSERT_TRUE(histogram->SerializeInfo(&pickle));

  PickleIterator iter(pickle);
  HistogramBase* deserialized = DeserializeHistogramInfo(&iter);
  EXPECT_EQ(histogram, deserialized);

  ResetStatisticsRecorder();

  PickleIterator iter2(pickle);
  deserialized = DeserializeHistogramInfo(&iter2);
  EXPECT_TRUE(deserialized);
  EXPECT_NE(histogram, deserialized);
  EXPECT_EQ("TestHistogram", deserialized->histogram_name());
  EXPECT_TRUE(deserialized->HasConstructionArguments(1, 1000, 10));
  EXPECT_EQ(0, deserialized->flags());
}

TEST_F(HistogramBaseTest, DeserializeBooleanHistogram) {
  HistogramBase* histogram = BooleanHistogram::FactoryGet(
      "TestHistogram", HistogramBase::kIPCSerializationSourceFlag);

  Pickle pickle;
  ASSERT_TRUE(histogram->SerializeInfo(&pickle));

  PickleIterator iter(pickle);
  HistogramBase* deserialized = DeserializeHistogramInfo(&iter);
  EXPECT_EQ(histogram, deserialized);

  ResetStatisticsRecorder();

  PickleIterator iter2(pickle);
  deserialized = DeserializeHistogramInfo(&iter2);
  EXPECT_TRUE(deserialized);
  EXPECT_NE(histogram, deserialized);
  EXPECT_EQ("TestHistogram", deserialized->histogram_name());
  EXPECT_TRUE(deserialized->HasConstructionArguments(1, 2, 3));
  EXPECT_EQ(0, deserialized->flags());
}

TEST_F(HistogramBaseTest, DeserializeCustomHistogram) {
  std::vector<HistogramBase::Sample> ranges;
  ranges.push_back(13);
  ranges.push_back(5);
  ranges.push_back(9);

  HistogramBase* histogram = CustomHistogram::FactoryGet(
      "TestHistogram", ranges, HistogramBase::kIPCSerializationSourceFlag);

  Pickle pickle;
  ASSERT_TRUE(histogram->SerializeInfo(&pickle));

  PickleIterator iter(pickle);
  HistogramBase* deserialized = DeserializeHistogramInfo(&iter);
  EXPECT_EQ(histogram, deserialized);

  ResetStatisticsRecorder();

  PickleIterator iter2(pickle);
  deserialized = DeserializeHistogramInfo(&iter2);
  EXPECT_TRUE(deserialized);
  EXPECT_NE(histogram, deserialized);
  EXPECT_EQ("TestHistogram", deserialized->histogram_name());
  EXPECT_TRUE(deserialized->HasConstructionArguments(5, 13, 4));
  EXPECT_EQ(0, deserialized->flags());
}

TEST_F(HistogramBaseTest, DeserializeSparseHistogram) {
  HistogramBase* histogram = SparseHistogram::FactoryGet(
      "TestHistogram", HistogramBase::kIPCSerializationSourceFlag);

  Pickle pickle;
  ASSERT_TRUE(histogram->SerializeInfo(&pickle));

  PickleIterator iter(pickle);
  HistogramBase* deserialized = DeserializeHistogramInfo(&iter);
  EXPECT_EQ(histogram, deserialized);

  ResetStatisticsRecorder();

  PickleIterator iter2(pickle);
  deserialized = DeserializeHistogramInfo(&iter2);
  EXPECT_TRUE(deserialized);
  EXPECT_NE(histogram, deserialized);
  EXPECT_EQ("TestHistogram", deserialized->histogram_name());
  EXPECT_EQ(0, deserialized->flags());
}

}  // namespace base
