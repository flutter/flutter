// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_METRICS_HISTOGRAM_FLATTENER_H_
#define BASE_METRICS_HISTOGRAM_FLATTENER_H_

#include <map>
#include <string>

#include "base/basictypes.h"
#include "base/metrics/histogram.h"

namespace base {

class HistogramSamples;

// HistogramFlattener is an interface used by HistogramSnapshotManager, which
// handles the logistics of gathering up available histograms for recording.
// The implementors handle the exact lower level recording mechanism, or
// error report mechanism.
class BASE_EXPORT HistogramFlattener {
 public:
  virtual void RecordDelta(const HistogramBase& histogram,
                           const HistogramSamples& snapshot) = 0;

  // Will be called each time a type of Inconsistency is seen on a histogram,
  // during inspections done internally in HistogramSnapshotManager class.
  virtual void InconsistencyDetected(HistogramBase::Inconsistency problem) = 0;

  // Will be called when a type of Inconsistency is seen for the first time on
  // a histogram.
  virtual void UniqueInconsistencyDetected(
      HistogramBase::Inconsistency problem) = 0;

  // Will be called when the total logged sample count of a histogram
  // differs from the sum of logged sample count in all the buckets.  The
  // argument |amount| is the non-zero discrepancy.
  virtual void InconsistencyDetectedInLoggedCount(int amount) = 0;

 protected:
  HistogramFlattener() {}
  virtual ~HistogramFlattener() {}

 private:
  DISALLOW_COPY_AND_ASSIGN(HistogramFlattener);
};

}  // namespace base

#endif  // BASE_METRICS_HISTOGRAM_FLATTENER_H_
