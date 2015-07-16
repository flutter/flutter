// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/histogram_snapshot_manager.h"

#include <string>
#include <vector>

#include "base/metrics/histogram.h"
#include "base/metrics/histogram_delta_serialization.h"
#include "base/metrics/statistics_recorder.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

class HistogramFlattenerDeltaRecorder : public HistogramFlattener {
 public:
  HistogramFlattenerDeltaRecorder() {}

  void RecordDelta(const HistogramBase& histogram,
                   const HistogramSamples& snapshot) override {
    recorded_delta_histogram_names_.push_back(histogram.histogram_name());
  }

  void InconsistencyDetected(HistogramBase::Inconsistency problem) override {
    ASSERT_TRUE(false);
  }

  void UniqueInconsistencyDetected(
      HistogramBase::Inconsistency problem) override {
    ASSERT_TRUE(false);
  }

  void InconsistencyDetectedInLoggedCount(int amount) override {
    ASSERT_TRUE(false);
  }

  std::vector<std::string> GetRecordedDeltaHistogramNames() {
    return recorded_delta_histogram_names_;
  }

 private:
  std::vector<std::string> recorded_delta_histogram_names_;

  DISALLOW_COPY_AND_ASSIGN(HistogramFlattenerDeltaRecorder);
};

class HistogramSnapshotManagerTest : public testing::Test {
 protected:
  HistogramSnapshotManagerTest()
      : histogram_snapshot_manager_(&histogram_flattener_delta_recorder_) {}

  ~HistogramSnapshotManagerTest() override {}

  StatisticsRecorder statistics_recorder_;
  HistogramFlattenerDeltaRecorder histogram_flattener_delta_recorder_;
  HistogramSnapshotManager histogram_snapshot_manager_;
};

TEST_F(HistogramSnapshotManagerTest, PrepareDeltasNoFlagsFilter) {
  // kNoFlags filter should record all histograms.
  UMA_HISTOGRAM_ENUMERATION("UmaHistogram", 1, 2);
  UMA_STABILITY_HISTOGRAM_ENUMERATION("UmaStabilityHistogram", 1, 2);

  histogram_snapshot_manager_.PrepareDeltas(HistogramBase::kNoFlags,
                                            HistogramBase::kNoFlags);

  const std::vector<std::string>& histograms =
      histogram_flattener_delta_recorder_.GetRecordedDeltaHistogramNames();
  EXPECT_EQ(2U, histograms.size());
  EXPECT_EQ("UmaHistogram", histograms[0]);
  EXPECT_EQ("UmaStabilityHistogram", histograms[1]);
}

TEST_F(HistogramSnapshotManagerTest, PrepareDeltasUmaHistogramFlagFilter) {
  // Note that kUmaStabilityHistogramFlag includes kUmaTargetedHistogramFlag.
  UMA_HISTOGRAM_ENUMERATION("UmaHistogram", 1, 2);
  UMA_STABILITY_HISTOGRAM_ENUMERATION("UmaStabilityHistogram", 1, 2);

  histogram_snapshot_manager_.PrepareDeltas(
      HistogramBase::kNoFlags, HistogramBase::kUmaTargetedHistogramFlag);

  const std::vector<std::string>& histograms =
      histogram_flattener_delta_recorder_.GetRecordedDeltaHistogramNames();
  EXPECT_EQ(2U, histograms.size());
  EXPECT_EQ("UmaHistogram", histograms[0]);
  EXPECT_EQ("UmaStabilityHistogram", histograms[1]);
}

TEST_F(HistogramSnapshotManagerTest,
       PrepareDeltasUmaStabilityHistogramFlagFilter) {
  UMA_HISTOGRAM_ENUMERATION("UmaHistogram", 1, 2);
  UMA_STABILITY_HISTOGRAM_ENUMERATION("UmaStabilityHistogram", 1, 2);

  histogram_snapshot_manager_.PrepareDeltas(
      HistogramBase::kNoFlags, HistogramBase::kUmaStabilityHistogramFlag);

  const std::vector<std::string>& histograms =
      histogram_flattener_delta_recorder_.GetRecordedDeltaHistogramNames();
  EXPECT_EQ(1U, histograms.size());
  EXPECT_EQ("UmaStabilityHistogram", histograms[0]);
}

}  // namespace base
