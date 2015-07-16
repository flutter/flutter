// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// BucketRanges stores the vector of ranges that delimit what samples are
// tallied in the corresponding buckets of a histogram. Histograms that have
// same ranges for all their corresponding buckets should share the same
// BucketRanges object.
//
// E.g. A 5 buckets LinearHistogram with 1 as minimal value and 4 as maximal
// value will need a BucketRanges with 6 ranges:
// 0, 1, 2, 3, 4, INT_MAX
//
// TODO(kaiwang): Currently we keep all negative values in 0~1 bucket. Consider
// changing 0 to INT_MIN.

#ifndef BASE_METRICS_BUCKET_RANGES_H_
#define BASE_METRICS_BUCKET_RANGES_H_

#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/gtest_prod_util.h"
#include "base/metrics/histogram_base.h"

namespace base {

class BASE_EXPORT BucketRanges {
 public:
  typedef std::vector<HistogramBase::Sample> Ranges;

  explicit BucketRanges(size_t num_ranges);
  ~BucketRanges();

  size_t size() const { return ranges_.size(); }
  HistogramBase::Sample range(size_t i) const { return ranges_[i]; }
  void set_range(size_t i, HistogramBase::Sample value);
  uint32 checksum() const { return checksum_; }
  void set_checksum(uint32 checksum) { checksum_ = checksum; }

  // A bucket is defined by a consecutive pair of entries in |ranges|, so there
  // is one fewer bucket than there are ranges.  For example, if |ranges| is
  // [0, 1, 3, 7, INT_MAX], then the buckets in this histogram are
  // [0, 1), [1, 3), [3, 7), and [7, INT_MAX).
  size_t bucket_count() const { return ranges_.size() - 1; }

  // Checksum methods to verify whether the ranges are corrupted (e.g. bad
  // memory access).
  uint32 CalculateChecksum() const;
  bool HasValidChecksum() const;
  void ResetChecksum();

  // Return true iff |other| object has same ranges_ as |this| object's ranges_.
  bool Equals(const BucketRanges* other) const;

 private:
  // A monotonically increasing list of values which determine which bucket to
  // put a sample into.  For each index, show the smallest sample that can be
  // added to the corresponding bucket.
  Ranges ranges_;

  // Checksum for the conntents of ranges_.  Used to detect random over-writes
  // of our data, and to quickly see if some other BucketRanges instance is
  // possibly Equal() to this instance.
  // TODO(kaiwang): Consider change this to uint64. Because we see a lot of
  // noise on UMA dashboard.
  uint32 checksum_;

  DISALLOW_COPY_AND_ASSIGN(BucketRanges);
};

//////////////////////////////////////////////////////////////////////////////
// Expose only for test.
BASE_EXPORT_PRIVATE extern const uint32 kCrcTable[256];

}  // namespace base

#endif  // BASE_METRICS_BUCKET_RANGES_H_
