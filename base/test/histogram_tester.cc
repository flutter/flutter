// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/histogram_tester.h"

#include "base/metrics/histogram.h"
#include "base/metrics/histogram_samples.h"
#include "base/metrics/statistics_recorder.h"
#include "base/stl_util.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

HistogramTester::HistogramTester() {
  StatisticsRecorder::Initialize();  // Safe to call multiple times.

  // Record any histogram data that exists when the object is created so it can
  // be subtracted later.
  StatisticsRecorder::Histograms histograms;
  StatisticsRecorder::GetSnapshot(std::string(), &histograms);
  for (size_t i = 0; i < histograms.size(); ++i) {
    histograms_snapshot_[histograms[i]->histogram_name()] =
        histograms[i]->SnapshotSamples().release();
  }
}

HistogramTester::~HistogramTester() {
  STLDeleteValues(&histograms_snapshot_);
}

void HistogramTester::ExpectUniqueSample(
    const std::string& name,
    base::HistogramBase::Sample sample,
    base::HistogramBase::Count expected_count) const {
  base::HistogramBase* histogram =
      base::StatisticsRecorder::FindHistogram(name);
  EXPECT_NE(static_cast<base::HistogramBase*>(NULL), histogram)
      << "Histogram \"" << name << "\" does not exist.";

  if (histogram) {
    scoped_ptr<base::HistogramSamples> samples(histogram->SnapshotSamples());
    CheckBucketCount(name, sample, expected_count, *samples);
    CheckTotalCount(name, expected_count, *samples);
  }
}

void HistogramTester::ExpectBucketCount(
    const std::string& name,
    base::HistogramBase::Sample sample,
    base::HistogramBase::Count expected_count) const {
  base::HistogramBase* histogram =
      base::StatisticsRecorder::FindHistogram(name);
  EXPECT_NE(static_cast<base::HistogramBase*>(NULL), histogram)
      << "Histogram \"" << name << "\" does not exist.";

  if (histogram) {
    scoped_ptr<base::HistogramSamples> samples(histogram->SnapshotSamples());
    CheckBucketCount(name, sample, expected_count, *samples);
  }
}

void HistogramTester::ExpectTotalCount(const std::string& name,
                                       base::HistogramBase::Count count) const {
  base::HistogramBase* histogram =
      base::StatisticsRecorder::FindHistogram(name);
  if (histogram) {
    scoped_ptr<base::HistogramSamples> samples(histogram->SnapshotSamples());
    CheckTotalCount(name, count, *samples);
  } else {
    // No histogram means there were zero samples.
    EXPECT_EQ(count, 0) << "Histogram \"" << name << "\" does not exist.";
  }
}

scoped_ptr<HistogramSamples> HistogramTester::GetHistogramSamplesSinceCreation(
    const std::string& histogram_name) {
  HistogramBase* histogram = StatisticsRecorder::FindHistogram(histogram_name);
  if (!histogram)
    return scoped_ptr<HistogramSamples>();
  scoped_ptr<HistogramSamples> named_samples(histogram->SnapshotSamples());
  HistogramSamples* named_original_samples =
      histograms_snapshot_[histogram_name];
  if (named_original_samples)
    named_samples->Subtract(*named_original_samples);
  return named_samples.Pass();
}

void HistogramTester::CheckBucketCount(
    const std::string& name,
    base::HistogramBase::Sample sample,
    base::HistogramBase::Count expected_count,
    const base::HistogramSamples& samples) const {
  int actual_count = samples.GetCount(sample);
  std::map<std::string, HistogramSamples*>::const_iterator histogram_data;
  histogram_data = histograms_snapshot_.find(name);
  if (histogram_data != histograms_snapshot_.end())
    actual_count -= histogram_data->second->GetCount(sample);

  EXPECT_EQ(expected_count, actual_count)
      << "Histogram \"" << name
      << "\" does not have the right number of samples (" << expected_count
      << ") in the expected bucket (" << sample << "). It has (" << actual_count
      << ").";
}

void HistogramTester::CheckTotalCount(
    const std::string& name,
    base::HistogramBase::Count expected_count,
    const base::HistogramSamples& samples) const {
  int actual_count = samples.TotalCount();
  std::map<std::string, HistogramSamples*>::const_iterator histogram_data;
  histogram_data = histograms_snapshot_.find(name);
  if (histogram_data != histograms_snapshot_.end())
    actual_count -= histogram_data->second->TotalCount();

  EXPECT_EQ(expected_count, actual_count)
      << "Histogram \"" << name
      << "\" does not have the right total number of samples ("
      << expected_count << "). It has (" << actual_count << ").";
}

}  // namespace base
