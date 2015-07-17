// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <vector>

#include "base/bind.h"
#include "base/json/json_reader.h"
#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram_macros.h"
#include "base/metrics/sparse_histogram.h"
#include "base/metrics/statistics_recorder.h"
#include "base/values.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

class StatisticsRecorderTest : public testing::Test {
 protected:
  void SetUp() override {
    // Each test will have a clean state (no Histogram / BucketRanges
    // registered).
    InitializeStatisticsRecorder();
  }

  void TearDown() override { UninitializeStatisticsRecorder(); }

  void InitializeStatisticsRecorder() {
    statistics_recorder_ = new StatisticsRecorder();
  }

  void UninitializeStatisticsRecorder() {
    delete statistics_recorder_;
    statistics_recorder_ = NULL;
  }

  Histogram* CreateHistogram(const std::string& name,
                             HistogramBase::Sample min,
                             HistogramBase::Sample max,
                             size_t bucket_count) {
    BucketRanges* ranges = new BucketRanges(bucket_count + 1);
    Histogram::InitializeBucketRanges(min, max, ranges);
    const BucketRanges* registered_ranges =
        StatisticsRecorder::RegisterOrDeleteDuplicateRanges(ranges);
    return new Histogram(name, min, max, registered_ranges);
  }

  void DeleteHistogram(HistogramBase* histogram) {
    delete histogram;
  }

  StatisticsRecorder* statistics_recorder_;
};

TEST_F(StatisticsRecorderTest, NotInitialized) {
  UninitializeStatisticsRecorder();

  ASSERT_FALSE(StatisticsRecorder::IsActive());

  StatisticsRecorder::Histograms registered_histograms;
  std::vector<const BucketRanges*> registered_ranges;

  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(0u, registered_histograms.size());

  Histogram* histogram = CreateHistogram("TestHistogram", 1, 1000, 10);

  // When StatisticsRecorder is not initialized, register is a noop.
  EXPECT_EQ(histogram,
            StatisticsRecorder::RegisterOrDeleteDuplicate(histogram));
  // Manually delete histogram that was not registered.
  DeleteHistogram(histogram);

  // RegisterOrDeleteDuplicateRanges is a no-op.
  BucketRanges* ranges = new BucketRanges(3);;
  ranges->ResetChecksum();
  EXPECT_EQ(ranges,
            StatisticsRecorder::RegisterOrDeleteDuplicateRanges(ranges));
  StatisticsRecorder::GetBucketRanges(&registered_ranges);
  EXPECT_EQ(0u, registered_ranges.size());
}

TEST_F(StatisticsRecorderTest, RegisterBucketRanges) {
  std::vector<const BucketRanges*> registered_ranges;

  BucketRanges* ranges1 = new BucketRanges(3);;
  ranges1->ResetChecksum();
  BucketRanges* ranges2 = new BucketRanges(4);;
  ranges2->ResetChecksum();

  // Register new ranges.
  EXPECT_EQ(ranges1,
            StatisticsRecorder::RegisterOrDeleteDuplicateRanges(ranges1));
  EXPECT_EQ(ranges2,
            StatisticsRecorder::RegisterOrDeleteDuplicateRanges(ranges2));
  StatisticsRecorder::GetBucketRanges(&registered_ranges);
  ASSERT_EQ(2u, registered_ranges.size());

  // Register some ranges again.
  EXPECT_EQ(ranges1,
            StatisticsRecorder::RegisterOrDeleteDuplicateRanges(ranges1));
  registered_ranges.clear();
  StatisticsRecorder::GetBucketRanges(&registered_ranges);
  ASSERT_EQ(2u, registered_ranges.size());
  // Make sure the ranges is still the one we know.
  ASSERT_EQ(3u, ranges1->size());
  EXPECT_EQ(0, ranges1->range(0));
  EXPECT_EQ(0, ranges1->range(1));
  EXPECT_EQ(0, ranges1->range(2));

  // Register ranges with same values.
  BucketRanges* ranges3 = new BucketRanges(3);;
  ranges3->ResetChecksum();
  EXPECT_EQ(ranges1,  // returning ranges1
            StatisticsRecorder::RegisterOrDeleteDuplicateRanges(ranges3));
  registered_ranges.clear();
  StatisticsRecorder::GetBucketRanges(&registered_ranges);
  ASSERT_EQ(2u, registered_ranges.size());
}

TEST_F(StatisticsRecorderTest, RegisterHistogram) {
  // Create a Histogram that was not registered.
  Histogram* histogram = CreateHistogram("TestHistogram", 1, 1000, 10);

  StatisticsRecorder::Histograms registered_histograms;
  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(0u, registered_histograms.size());

  // Register the Histogram.
  EXPECT_EQ(histogram,
            StatisticsRecorder::RegisterOrDeleteDuplicate(histogram));
  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(1u, registered_histograms.size());

  // Register the same Histogram again.
  EXPECT_EQ(histogram,
            StatisticsRecorder::RegisterOrDeleteDuplicate(histogram));
  registered_histograms.clear();
  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(1u, registered_histograms.size());
}

TEST_F(StatisticsRecorderTest, FindHistogram) {
  HistogramBase* histogram1 = Histogram::FactoryGet(
      "TestHistogram1", 1, 1000, 10, HistogramBase::kNoFlags);
  HistogramBase* histogram2 = Histogram::FactoryGet(
      "TestHistogram2", 1, 1000, 10, HistogramBase::kNoFlags);

  EXPECT_EQ(histogram1, StatisticsRecorder::FindHistogram("TestHistogram1"));
  EXPECT_EQ(histogram2, StatisticsRecorder::FindHistogram("TestHistogram2"));
  EXPECT_TRUE(StatisticsRecorder::FindHistogram("TestHistogram") == NULL);
}

TEST_F(StatisticsRecorderTest, GetSnapshot) {
  Histogram::FactoryGet("TestHistogram1", 1, 1000, 10, Histogram::kNoFlags);
  Histogram::FactoryGet("TestHistogram2", 1, 1000, 10, Histogram::kNoFlags);
  Histogram::FactoryGet("TestHistogram3", 1, 1000, 10, Histogram::kNoFlags);

  StatisticsRecorder::Histograms snapshot;
  StatisticsRecorder::GetSnapshot("Test", &snapshot);
  EXPECT_EQ(3u, snapshot.size());

  snapshot.clear();
  StatisticsRecorder::GetSnapshot("1", &snapshot);
  EXPECT_EQ(1u, snapshot.size());

  snapshot.clear();
  StatisticsRecorder::GetSnapshot("hello", &snapshot);
  EXPECT_EQ(0u, snapshot.size());
}

TEST_F(StatisticsRecorderTest, RegisterHistogramWithFactoryGet) {
  StatisticsRecorder::Histograms registered_histograms;

  StatisticsRecorder::GetHistograms(&registered_histograms);
  ASSERT_EQ(0u, registered_histograms.size());

  // Create a histogram.
  HistogramBase* histogram = Histogram::FactoryGet(
      "TestHistogram", 1, 1000, 10, HistogramBase::kNoFlags);
  registered_histograms.clear();
  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(1u, registered_histograms.size());

  // Get an existing histogram.
  HistogramBase* histogram2 = Histogram::FactoryGet(
      "TestHistogram", 1, 1000, 10, HistogramBase::kNoFlags);
  registered_histograms.clear();
  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(1u, registered_histograms.size());
  EXPECT_EQ(histogram, histogram2);

  // Create a LinearHistogram.
  histogram = LinearHistogram::FactoryGet(
      "TestLinearHistogram", 1, 1000, 10, HistogramBase::kNoFlags);
  registered_histograms.clear();
  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(2u, registered_histograms.size());

  // Create a BooleanHistogram.
  histogram = BooleanHistogram::FactoryGet(
      "TestBooleanHistogram", HistogramBase::kNoFlags);
  registered_histograms.clear();
  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(3u, registered_histograms.size());

  // Create a CustomHistogram.
  std::vector<int> custom_ranges;
  custom_ranges.push_back(1);
  custom_ranges.push_back(5);
  histogram = CustomHistogram::FactoryGet(
      "TestCustomHistogram", custom_ranges, HistogramBase::kNoFlags);
  registered_histograms.clear();
  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(4u, registered_histograms.size());
}

TEST_F(StatisticsRecorderTest, RegisterHistogramWithMacros) {
  StatisticsRecorder::Histograms registered_histograms;

  HistogramBase* histogram = Histogram::FactoryGet(
      "TestHistogramCounts", 1, 1000000, 50, HistogramBase::kNoFlags);

  // The histogram we got from macro is the same as from FactoryGet.
  LOCAL_HISTOGRAM_COUNTS("TestHistogramCounts", 30);
  registered_histograms.clear();
  StatisticsRecorder::GetHistograms(&registered_histograms);
  ASSERT_EQ(1u, registered_histograms.size());
  EXPECT_EQ(histogram, registered_histograms[0]);

  LOCAL_HISTOGRAM_TIMES("TestHistogramTimes", TimeDelta::FromDays(1));
  LOCAL_HISTOGRAM_ENUMERATION("TestHistogramEnumeration", 20, 200);

  registered_histograms.clear();
  StatisticsRecorder::GetHistograms(&registered_histograms);
  EXPECT_EQ(3u, registered_histograms.size());
}

TEST_F(StatisticsRecorderTest, BucketRangesSharing) {
  std::vector<const BucketRanges*> ranges;
  StatisticsRecorder::GetBucketRanges(&ranges);
  EXPECT_EQ(0u, ranges.size());

  Histogram::FactoryGet("Histogram", 1, 64, 8, HistogramBase::kNoFlags);
  Histogram::FactoryGet("Histogram2", 1, 64, 8, HistogramBase::kNoFlags);

  StatisticsRecorder::GetBucketRanges(&ranges);
  EXPECT_EQ(1u, ranges.size());

  Histogram::FactoryGet("Histogram3", 1, 64, 16, HistogramBase::kNoFlags);

  ranges.clear();
  StatisticsRecorder::GetBucketRanges(&ranges);
  EXPECT_EQ(2u, ranges.size());
}

TEST_F(StatisticsRecorderTest, ToJSON) {
  LOCAL_HISTOGRAM_COUNTS("TestHistogram1", 30);
  LOCAL_HISTOGRAM_COUNTS("TestHistogram1", 40);
  LOCAL_HISTOGRAM_COUNTS("TestHistogram2", 30);
  LOCAL_HISTOGRAM_COUNTS("TestHistogram2", 40);

  std::string json(StatisticsRecorder::ToJSON(std::string()));

  // Check for valid JSON.
  scoped_ptr<Value> root;
  root.reset(JSONReader::DeprecatedRead(json));
  ASSERT_TRUE(root.get());

  DictionaryValue* root_dict = NULL;
  ASSERT_TRUE(root->GetAsDictionary(&root_dict));

  // No query should be set.
  ASSERT_FALSE(root_dict->HasKey("query"));

  ListValue* histogram_list = NULL;
  ASSERT_TRUE(root_dict->GetList("histograms", &histogram_list));
  ASSERT_EQ(2u, histogram_list->GetSize());

  // Examine the first histogram.
  DictionaryValue* histogram_dict = NULL;
  ASSERT_TRUE(histogram_list->GetDictionary(0, &histogram_dict));

  int sample_count;
  ASSERT_TRUE(histogram_dict->GetInteger("count", &sample_count));
  EXPECT_EQ(2, sample_count);

  // Test the query filter.
  std::string query("TestHistogram2");
  json = StatisticsRecorder::ToJSON(query);

  root.reset(JSONReader::DeprecatedRead(json));
  ASSERT_TRUE(root.get());
  ASSERT_TRUE(root->GetAsDictionary(&root_dict));

  std::string query_value;
  ASSERT_TRUE(root_dict->GetString("query", &query_value));
  EXPECT_EQ(query, query_value);

  ASSERT_TRUE(root_dict->GetList("histograms", &histogram_list));
  ASSERT_EQ(1u, histogram_list->GetSize());

  ASSERT_TRUE(histogram_list->GetDictionary(0, &histogram_dict));

  std::string histogram_name;
  ASSERT_TRUE(histogram_dict->GetString("name", &histogram_name));
  EXPECT_EQ("TestHistogram2", histogram_name);

  json.clear();
  UninitializeStatisticsRecorder();

  // No data should be returned.
  json = StatisticsRecorder::ToJSON(query);
  EXPECT_TRUE(json.empty());
}

namespace {

// CallbackCheckWrapper is simply a convenient way to check and store that
// a callback was actually run.
struct CallbackCheckWrapper {
  CallbackCheckWrapper() : called(false), last_histogram_value(0) {}

  void OnHistogramChanged(base::HistogramBase::Sample histogram_value) {
    called = true;
    last_histogram_value = histogram_value;
  }

  bool called;
  base::HistogramBase::Sample last_histogram_value;
};

}  // namespace

// Check that you can't overwrite the callback with another.
TEST_F(StatisticsRecorderTest, SetCallbackFailsWithoutHistogramTest) {
  CallbackCheckWrapper callback_wrapper;

  bool result = base::StatisticsRecorder::SetCallback(
      "TestHistogram", base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                                  base::Unretained(&callback_wrapper)));
  EXPECT_TRUE(result);

  result = base::StatisticsRecorder::SetCallback(
      "TestHistogram", base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                                  base::Unretained(&callback_wrapper)));
  EXPECT_FALSE(result);
}

// Check that you can't overwrite the callback with another.
TEST_F(StatisticsRecorderTest, SetCallbackFailsWithHistogramTest) {
  HistogramBase* histogram = Histogram::FactoryGet("TestHistogram", 1, 1000, 10,
                                                   HistogramBase::kNoFlags);
  EXPECT_TRUE(histogram);

  CallbackCheckWrapper callback_wrapper;

  bool result = base::StatisticsRecorder::SetCallback(
      "TestHistogram", base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                                  base::Unretained(&callback_wrapper)));
  EXPECT_TRUE(result);
  EXPECT_EQ(histogram->flags() & base::HistogramBase::kCallbackExists,
            base::HistogramBase::kCallbackExists);

  result = base::StatisticsRecorder::SetCallback(
      "TestHistogram", base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                                  base::Unretained(&callback_wrapper)));
  EXPECT_FALSE(result);
  EXPECT_EQ(histogram->flags() & base::HistogramBase::kCallbackExists,
            base::HistogramBase::kCallbackExists);

  histogram->Add(1);

  EXPECT_TRUE(callback_wrapper.called);
}

// Check that you can't overwrite the callback with another.
TEST_F(StatisticsRecorderTest, ClearCallbackSuceedsWithHistogramTest) {
  HistogramBase* histogram = Histogram::FactoryGet("TestHistogram", 1, 1000, 10,
                                                   HistogramBase::kNoFlags);
  EXPECT_TRUE(histogram);

  CallbackCheckWrapper callback_wrapper;

  bool result = base::StatisticsRecorder::SetCallback(
      "TestHistogram", base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                                  base::Unretained(&callback_wrapper)));
  EXPECT_TRUE(result);
  EXPECT_EQ(histogram->flags() & base::HistogramBase::kCallbackExists,
            base::HistogramBase::kCallbackExists);

  base::StatisticsRecorder::ClearCallback("TestHistogram");
  EXPECT_EQ(histogram->flags() & base::HistogramBase::kCallbackExists, 0);

  histogram->Add(1);

  EXPECT_FALSE(callback_wrapper.called);
}

// Check that callback is used.
TEST_F(StatisticsRecorderTest, CallbackUsedTest) {
  {
    HistogramBase* histogram = Histogram::FactoryGet(
        "TestHistogram", 1, 1000, 10, HistogramBase::kNoFlags);
    EXPECT_TRUE(histogram);

    CallbackCheckWrapper callback_wrapper;

    base::StatisticsRecorder::SetCallback(
        "TestHistogram", base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                                    base::Unretained(&callback_wrapper)));

    histogram->Add(1);

    EXPECT_TRUE(callback_wrapper.called);
    EXPECT_EQ(callback_wrapper.last_histogram_value, 1);
  }

  {
    HistogramBase* linear_histogram = LinearHistogram::FactoryGet(
        "TestLinearHistogram", 1, 1000, 10, HistogramBase::kNoFlags);

    CallbackCheckWrapper callback_wrapper;

    base::StatisticsRecorder::SetCallback(
        "TestLinearHistogram",
        base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                   base::Unretained(&callback_wrapper)));

    linear_histogram->Add(1);

    EXPECT_TRUE(callback_wrapper.called);
    EXPECT_EQ(callback_wrapper.last_histogram_value, 1);
  }

  {
    std::vector<int> custom_ranges;
    custom_ranges.push_back(1);
    custom_ranges.push_back(5);
    HistogramBase* custom_histogram = CustomHistogram::FactoryGet(
        "TestCustomHistogram", custom_ranges, HistogramBase::kNoFlags);

    CallbackCheckWrapper callback_wrapper;

    base::StatisticsRecorder::SetCallback(
        "TestCustomHistogram",
        base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                   base::Unretained(&callback_wrapper)));

    custom_histogram->Add(1);

    EXPECT_TRUE(callback_wrapper.called);
    EXPECT_EQ(callback_wrapper.last_histogram_value, 1);
  }

  {
    HistogramBase* custom_histogram = SparseHistogram::FactoryGet(
        "TestSparseHistogram", HistogramBase::kNoFlags);

    CallbackCheckWrapper callback_wrapper;

    base::StatisticsRecorder::SetCallback(
        "TestSparseHistogram",
        base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                   base::Unretained(&callback_wrapper)));

    custom_histogram->Add(1);

    EXPECT_TRUE(callback_wrapper.called);
    EXPECT_EQ(callback_wrapper.last_histogram_value, 1);
  }
}

// Check that setting a callback before the histogram exists works.
TEST_F(StatisticsRecorderTest, CallbackUsedBeforeHistogramCreatedTest) {
  CallbackCheckWrapper callback_wrapper;

  base::StatisticsRecorder::SetCallback(
      "TestHistogram", base::Bind(&CallbackCheckWrapper::OnHistogramChanged,
                                  base::Unretained(&callback_wrapper)));

  HistogramBase* histogram = Histogram::FactoryGet("TestHistogram", 1, 1000, 10,
                                                   HistogramBase::kNoFlags);
  EXPECT_TRUE(histogram);
  histogram->Add(1);

  EXPECT_TRUE(callback_wrapper.called);
  EXPECT_EQ(callback_wrapper.last_histogram_value, 1);
}

}  // namespace base
