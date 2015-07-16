// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/histogram_delta_serialization.h"

#include <vector>

#include "base/metrics/histogram.h"
#include "base/metrics/histogram_base.h"
#include "base/metrics/statistics_recorder.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

TEST(HistogramDeltaSerializationTest, DeserializeHistogramAndAddSamples) {
  StatisticsRecorder statistic_recorder;
  HistogramDeltaSerialization serializer("HistogramDeltaSerializationTest");
  std::vector<std::string> deltas;
  // Nothing was changed yet.
  serializer.PrepareAndSerializeDeltas(&deltas);
  EXPECT_TRUE(deltas.empty());

  HistogramBase* histogram = Histogram::FactoryGet(
      "TestHistogram", 1, 1000, 10, HistogramBase::kIPCSerializationSourceFlag);
  histogram->Add(1);
  histogram->Add(10);
  histogram->Add(100);
  histogram->Add(1000);

  serializer.PrepareAndSerializeDeltas(&deltas);
  EXPECT_FALSE(deltas.empty());

  HistogramDeltaSerialization::DeserializeAndAddSamples(deltas);

  // The histogram has kIPCSerializationSourceFlag. So samples will be ignored.
  scoped_ptr<HistogramSamples> snapshot(histogram->SnapshotSamples());
  EXPECT_EQ(1, snapshot->GetCount(1));
  EXPECT_EQ(1, snapshot->GetCount(10));
  EXPECT_EQ(1, snapshot->GetCount(100));
  EXPECT_EQ(1, snapshot->GetCount(1000));

  // Clear kIPCSerializationSourceFlag to emulate multi-process usage.
  histogram->ClearFlags(HistogramBase::kIPCSerializationSourceFlag);
  HistogramDeltaSerialization::DeserializeAndAddSamples(deltas);

  scoped_ptr<HistogramSamples> snapshot2(histogram->SnapshotSamples());
  EXPECT_EQ(2, snapshot2->GetCount(1));
  EXPECT_EQ(2, snapshot2->GetCount(10));
  EXPECT_EQ(2, snapshot2->GetCount(100));
  EXPECT_EQ(2, snapshot2->GetCount(1000));
}

}  // namespace base
