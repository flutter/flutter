// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/sparse_histogram.h"

#include <string>

#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram_base.h"
#include "base/metrics/histogram_samples.h"
#include "base/metrics/sample_map.h"
#include "base/metrics/statistics_recorder.h"
#include "base/pickle.h"
#include "base/strings/stringprintf.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

class SparseHistogramTest : public testing::Test {
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

  scoped_ptr<SparseHistogram> NewSparseHistogram(const std::string& name) {
    return scoped_ptr<SparseHistogram>(new SparseHistogram(name));
  }

  StatisticsRecorder* statistics_recorder_;
};

TEST_F(SparseHistogramTest, BasicTest) {
  scoped_ptr<SparseHistogram> histogram(NewSparseHistogram("Sparse"));
  scoped_ptr<HistogramSamples> snapshot(histogram->SnapshotSamples());
  EXPECT_EQ(0, snapshot->TotalCount());
  EXPECT_EQ(0, snapshot->sum());

  histogram->Add(100);
  scoped_ptr<HistogramSamples> snapshot1(histogram->SnapshotSamples());
  EXPECT_EQ(1, snapshot1->TotalCount());
  EXPECT_EQ(1, snapshot1->GetCount(100));

  histogram->Add(100);
  histogram->Add(101);
  scoped_ptr<HistogramSamples> snapshot2(histogram->SnapshotSamples());
  EXPECT_EQ(3, snapshot2->TotalCount());
  EXPECT_EQ(2, snapshot2->GetCount(100));
  EXPECT_EQ(1, snapshot2->GetCount(101));
}

TEST_F(SparseHistogramTest, MacroBasicTest) {
  UMA_HISTOGRAM_SPARSE_SLOWLY("Sparse", 100);
  UMA_HISTOGRAM_SPARSE_SLOWLY("Sparse", 200);
  UMA_HISTOGRAM_SPARSE_SLOWLY("Sparse", 100);

  StatisticsRecorder::Histograms histograms;
  StatisticsRecorder::GetHistograms(&histograms);

  ASSERT_EQ(1U, histograms.size());
  HistogramBase* sparse_histogram = histograms[0];

  EXPECT_EQ(SPARSE_HISTOGRAM, sparse_histogram->GetHistogramType());
  EXPECT_EQ("Sparse", sparse_histogram->histogram_name());
  EXPECT_EQ(HistogramBase::kUmaTargetedHistogramFlag,
            sparse_histogram->flags());

  scoped_ptr<HistogramSamples> samples = sparse_histogram->SnapshotSamples();
  EXPECT_EQ(3, samples->TotalCount());
  EXPECT_EQ(2, samples->GetCount(100));
  EXPECT_EQ(1, samples->GetCount(200));
}

TEST_F(SparseHistogramTest, MacroInLoopTest) {
  // Unlike the macros in histogram.h, SparseHistogram macros can have a
  // variable as histogram name.
  for (int i = 0; i < 2; i++) {
    std::string name = StringPrintf("Sparse%d", i + 1);
    UMA_HISTOGRAM_SPARSE_SLOWLY(name, 100);
  }

  StatisticsRecorder::Histograms histograms;
  StatisticsRecorder::GetHistograms(&histograms);
  ASSERT_EQ(2U, histograms.size());

  std::string name1 = histograms[0]->histogram_name();
  std::string name2 = histograms[1]->histogram_name();
  EXPECT_TRUE(("Sparse1" == name1 && "Sparse2" == name2) ||
              ("Sparse2" == name1 && "Sparse1" == name2));
}

TEST_F(SparseHistogramTest, Serialize) {
  scoped_ptr<SparseHistogram> histogram(NewSparseHistogram("Sparse"));
  histogram->SetFlags(HistogramBase::kIPCSerializationSourceFlag);

  Pickle pickle;
  histogram->SerializeInfo(&pickle);

  PickleIterator iter(pickle);

  int type;
  EXPECT_TRUE(iter.ReadInt(&type));
  EXPECT_EQ(SPARSE_HISTOGRAM, type);

  std::string name;
  EXPECT_TRUE(iter.ReadString(&name));
  EXPECT_EQ("Sparse", name);

  int flag;
  EXPECT_TRUE(iter.ReadInt(&flag));
  EXPECT_EQ(HistogramBase::kIPCSerializationSourceFlag, flag);

  // No more data in the pickle.
  EXPECT_FALSE(iter.SkipBytes(1));
}

}  // namespace base
