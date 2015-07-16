// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_METRICS_HISTOGRAM_SNAPSHOT_MANAGER_H_
#define BASE_METRICS_HISTOGRAM_SNAPSHOT_MANAGER_H_

#include <map>
#include <string>

#include "base/basictypes.h"
#include "base/metrics/histogram_base.h"

namespace base {

class HistogramSamples;
class HistogramFlattener;

// HistogramSnapshotManager handles the logistics of gathering up available
// histograms for recording either to disk or for transmission (such as from
// renderer to browser, or from browser to UMA upload). Since histograms can sit
// in memory for an extended period of time, and are vulnerable to memory
// corruption, this class also validates as much rendundancy as it can before
// calling for the marginal change (a.k.a., delta) in a histogram to be
// recorded.
class BASE_EXPORT HistogramSnapshotManager {
 public:
  explicit HistogramSnapshotManager(HistogramFlattener* histogram_flattener);
  virtual ~HistogramSnapshotManager();

  // Snapshot all histograms, and ask |histogram_flattener_| to record the
  // delta. |flags_to_set| is used to set flags for each histogram.
  // |required_flags| is used to select histograms to be recorded.
  // Only histograms that have all the flags specified by the argument will be
  // chosen. If all histograms should be recorded, set it to
  // |Histogram::kNoFlags|.
  void PrepareDeltas(HistogramBase::Flags flags_to_set,
                     HistogramBase::Flags required_flags);

 private:
  // Snapshot this histogram, and record the delta.
  void PrepareDelta(const HistogramBase& histogram);

  // Try to detect and fix count inconsistency of logged samples.
  void InspectLoggedSamplesInconsistency(
      const HistogramSamples& new_snapshot,
      HistogramSamples* logged_samples);

  // For histograms, track what we've already recorded (as a sample for
  // each histogram) so that we can record only the delta with the next log.
  std::map<std::string, HistogramSamples*> logged_samples_;

  // List of histograms found to be corrupt, and their problems.
  std::map<std::string, int> inconsistencies_;

  // |histogram_flattener_| handles the logistics of recording the histogram
  // deltas.
  HistogramFlattener* histogram_flattener_;  // Weak.

  DISALLOW_COPY_AND_ASSIGN(HistogramSnapshotManager);
};

}  // namespace base

#endif  // BASE_METRICS_HISTOGRAM_SNAPSHOT_MANAGER_H_
