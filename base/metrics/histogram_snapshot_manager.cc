// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/histogram_snapshot_manager.h"

#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram_flattener.h"
#include "base/metrics/histogram_samples.h"
#include "base/metrics/statistics_recorder.h"
#include "base/stl_util.h"

namespace base {

HistogramSnapshotManager::HistogramSnapshotManager(
    HistogramFlattener* histogram_flattener)
    : histogram_flattener_(histogram_flattener) {
  DCHECK(histogram_flattener_);
}

HistogramSnapshotManager::~HistogramSnapshotManager() {
  STLDeleteValues(&logged_samples_);
}

void HistogramSnapshotManager::PrepareDeltas(
    HistogramBase::Flags flag_to_set,
    HistogramBase::Flags required_flags) {
  StatisticsRecorder::Histograms histograms;
  StatisticsRecorder::GetHistograms(&histograms);
  for (StatisticsRecorder::Histograms::const_iterator it = histograms.begin();
       histograms.end() != it;
       ++it) {
    (*it)->SetFlags(flag_to_set);
    if (((*it)->flags() & required_flags) == required_flags)
      PrepareDelta(**it);
  }
}

void HistogramSnapshotManager::PrepareDelta(const HistogramBase& histogram) {
  DCHECK(histogram_flattener_);

  // Get up-to-date snapshot of sample stats.
  scoped_ptr<HistogramSamples> snapshot(histogram.SnapshotSamples());
  const std::string& histogram_name = histogram.histogram_name();

  int corruption = histogram.FindCorruption(*snapshot);

  // Crash if we detect that our histograms have been overwritten.  This may be
  // a fair distance from the memory smasher, but we hope to correlate these
  // crashes with other events, such as plugins, or usage patterns, etc.
  if (HistogramBase::BUCKET_ORDER_ERROR & corruption) {
    // The checksum should have caught this, so crash separately if it didn't.
    CHECK_NE(0, HistogramBase::RANGE_CHECKSUM_ERROR & corruption);
    CHECK(false);  // Crash for the bucket order corruption.
  }
  // Checksum corruption might not have caused order corruption.
  CHECK_EQ(0, HistogramBase::RANGE_CHECKSUM_ERROR & corruption);

  // Note, at this point corruption can only be COUNT_HIGH_ERROR or
  // COUNT_LOW_ERROR and they never arise together, so we don't need to extract
  // bits from corruption.
  if (corruption) {
    DLOG(ERROR) << "Histogram: " << histogram_name
                << " has data corruption: " << corruption;
    histogram_flattener_->InconsistencyDetected(
        static_cast<HistogramBase::Inconsistency>(corruption));
    // Don't record corrupt data to metrics services.
    int old_corruption = inconsistencies_[histogram_name];
    if (old_corruption == (corruption | old_corruption))
      return;  // We've already seen this corruption for this histogram.
    inconsistencies_[histogram_name] |= corruption;
    histogram_flattener_->UniqueInconsistencyDetected(
        static_cast<HistogramBase::Inconsistency>(corruption));
    return;
  }

  HistogramSamples* to_log;
  std::map<std::string, HistogramSamples*>::iterator it =
      logged_samples_.find(histogram_name);
  if (it == logged_samples_.end()) {
    to_log = snapshot.release();

    // This histogram has not been logged before, add a new entry.
    logged_samples_[histogram_name] = to_log;
  } else {
    HistogramSamples* already_logged = it->second;
    InspectLoggedSamplesInconsistency(*snapshot, already_logged);
    snapshot->Subtract(*already_logged);
    already_logged->Add(*snapshot);
    to_log = snapshot.get();
  }

  if (to_log->TotalCount() > 0)
    histogram_flattener_->RecordDelta(histogram, *to_log);
}

void HistogramSnapshotManager::InspectLoggedSamplesInconsistency(
      const HistogramSamples& new_snapshot,
      HistogramSamples* logged_samples) {
  HistogramBase::Count discrepancy =
      logged_samples->TotalCount() - logged_samples->redundant_count();
  if (!discrepancy)
    return;

  histogram_flattener_->InconsistencyDetectedInLoggedCount(discrepancy);
  if (discrepancy > Histogram::kCommonRaceBasedCountMismatch) {
    // Fix logged_samples.
    logged_samples->Subtract(*logged_samples);
    logged_samples->Add(new_snapshot);
  }
}

}  // namespace base
