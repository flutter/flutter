// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_METRICS_HISTOGRAM_DELTA_SERIALIZATION_H_
#define BASE_METRICS_HISTOGRAM_DELTA_SERIALIZATION_H_

#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram_flattener.h"
#include "base/metrics/histogram_snapshot_manager.h"

namespace base {

class HistogramBase;

// Serializes and restores histograms deltas.
class BASE_EXPORT HistogramDeltaSerialization : public HistogramFlattener {
 public:
  // |caller_name| is string used in histograms for counting inconsistencies.
  explicit HistogramDeltaSerialization(const std::string& caller_name);
  ~HistogramDeltaSerialization() override;

  // Computes deltas in histogram bucket counts relative to the previous call to
  // this method. Stores the deltas in serialized form into |serialized_deltas|.
  // If |serialized_deltas| is NULL, no data is serialized, though the next call
  // will compute the deltas relative to this one.
  void PrepareAndSerializeDeltas(std::vector<std::string>* serialized_deltas);

  // Deserialize deltas and add samples to corresponding histograms, creating
  // them if necessary. Silently ignores errors in |serialized_deltas|.
  static void DeserializeAndAddSamples(
      const std::vector<std::string>& serialized_deltas);

 private:
  // HistogramFlattener implementation.
  void RecordDelta(const HistogramBase& histogram,
                   const HistogramSamples& snapshot) override;
  void InconsistencyDetected(HistogramBase::Inconsistency problem) override;
  void UniqueInconsistencyDetected(
      HistogramBase::Inconsistency problem) override;
  void InconsistencyDetectedInLoggedCount(int amount) override;

  // Calculates deltas in histogram counters.
  HistogramSnapshotManager histogram_snapshot_manager_;

  // Output buffer for serialized deltas.
  std::vector<std::string>* serialized_deltas_;

  // Histograms to count inconsistencies in snapshots.
  HistogramBase* inconsistencies_histogram_;
  HistogramBase* inconsistencies_unique_histogram_;
  HistogramBase* inconsistent_snapshot_histogram_;

  DISALLOW_COPY_AND_ASSIGN(HistogramDeltaSerialization);
};

}  // namespace base

#endif  // BASE_METRICS_HISTOGRAM_DELTA_SERIALIZATION_H_
