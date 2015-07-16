// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/sample_map.h"

#include "base/logging.h"

namespace base {

typedef HistogramBase::Count Count;
typedef HistogramBase::Sample Sample;

SampleMap::SampleMap() {}

SampleMap::~SampleMap() {}

void SampleMap::Accumulate(Sample value, Count count) {
  sample_counts_[value] += count;
  IncreaseSum(count * value);
  IncreaseRedundantCount(count);
}

Count SampleMap::GetCount(Sample value) const {
  std::map<Sample, Count>::const_iterator it = sample_counts_.find(value);
  if (it == sample_counts_.end())
    return 0;
  return it->second;
}

Count SampleMap::TotalCount() const {
  Count count = 0;
  for (const auto& entry : sample_counts_) {
    count += entry.second;
  }
  return count;
}

scoped_ptr<SampleCountIterator> SampleMap::Iterator() const {
  return scoped_ptr<SampleCountIterator>(new SampleMapIterator(sample_counts_));
}

bool SampleMap::AddSubtractImpl(SampleCountIterator* iter,
                                HistogramSamples::Operator op) {
  Sample min;
  Sample max;
  Count count;
  for (; !iter->Done(); iter->Next()) {
    iter->Get(&min, &max, &count);
    if (min + 1 != max)
      return false;  // SparseHistogram only supports bucket with size 1.

    sample_counts_[min] += (op == HistogramSamples::ADD) ? count : -count;
  }
  return true;
}

SampleMapIterator::SampleMapIterator(const SampleToCountMap& sample_counts)
    : iter_(sample_counts.begin()),
      end_(sample_counts.end()) {
  SkipEmptyBuckets();
}

SampleMapIterator::~SampleMapIterator() {}

bool SampleMapIterator::Done() const {
  return iter_ == end_;
}

void SampleMapIterator::Next() {
  DCHECK(!Done());
  ++iter_;
  SkipEmptyBuckets();
}

void SampleMapIterator::Get(Sample* min, Sample* max, Count* count) const {
  DCHECK(!Done());
  if (min != NULL)
    *min = iter_->first;
  if (max != NULL)
    *max = iter_->first + 1;
  if (count != NULL)
    *count = iter_->second;
}

void SampleMapIterator::SkipEmptyBuckets() {
  while (!Done() && iter_->second == 0) {
    ++iter_;
  }
}

}  // namespace base
