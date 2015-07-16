// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_METRICS_HISTOGRAM_SAMPLES_H_
#define BASE_METRICS_HISTOGRAM_SAMPLES_H_

#include "base/basictypes.h"
#include "base/metrics/histogram_base.h"
#include "base/memory/scoped_ptr.h"

namespace base {

class Pickle;
class PickleIterator;
class SampleCountIterator;

// HistogramSamples is a container storing all samples of a histogram.
class BASE_EXPORT HistogramSamples {
 public:
  HistogramSamples();
  virtual ~HistogramSamples();

  virtual void Accumulate(HistogramBase::Sample value,
                          HistogramBase::Count count) = 0;
  virtual HistogramBase::Count GetCount(HistogramBase::Sample value) const = 0;
  virtual HistogramBase::Count TotalCount() const = 0;

  virtual void Add(const HistogramSamples& other);

  // Add from serialized samples.
  virtual bool AddFromPickle(PickleIterator* iter);

  virtual void Subtract(const HistogramSamples& other);

  virtual scoped_ptr<SampleCountIterator> Iterator() const = 0;
  virtual bool Serialize(Pickle* pickle) const;

  // Accessor fuctions.
  int64 sum() const { return sum_; }
  HistogramBase::Count redundant_count() const {
    return subtle::NoBarrier_Load(&redundant_count_);
  }

 protected:
  // Based on |op| type, add or subtract sample counts data from the iterator.
  enum Operator { ADD, SUBTRACT };
  virtual bool AddSubtractImpl(SampleCountIterator* iter, Operator op) = 0;

  void IncreaseSum(int64 diff);
  void IncreaseRedundantCount(HistogramBase::Count diff);

 private:
  int64 sum_;

  // |redundant_count_| helps identify memory corruption. It redundantly stores
  // the total number of samples accumulated in the histogram. We can compare
  // this count to the sum of the counts (TotalCount() function), and detect
  // problems. Note, depending on the implementation of different histogram
  // types, there might be races during histogram accumulation and snapshotting
  // that we choose to accept. In this case, the tallies might mismatch even
  // when no memory corruption has happened.
  HistogramBase::AtomicCount redundant_count_;
};

class BASE_EXPORT SampleCountIterator {
 public:
  virtual ~SampleCountIterator();

  virtual bool Done() const = 0;
  virtual void Next() = 0;

  // Get the sample and count at current position.
  // |min| |max| and |count| can be NULL if the value is not of interest.
  // Requires: !Done();
  virtual void Get(HistogramBase::Sample* min,
                   HistogramBase::Sample* max,
                   HistogramBase::Count* count) const = 0;

  // Get the index of current histogram bucket.
  // For histograms that don't use predefined buckets, it returns false.
  // Requires: !Done();
  virtual bool GetBucketIndex(size_t* index) const;
};

}  // namespace base

#endif  // BASE_METRICS_HISTOGRAM_SAMPLES_H_
