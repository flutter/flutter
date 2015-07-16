// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/sample_vector.h"

#include "base/logging.h"
#include "base/metrics/bucket_ranges.h"

namespace base {

typedef HistogramBase::Count Count;
typedef HistogramBase::Sample Sample;

SampleVector::SampleVector(const BucketRanges* bucket_ranges)
    : counts_(bucket_ranges->bucket_count()),
      bucket_ranges_(bucket_ranges) {
  CHECK_GE(bucket_ranges_->bucket_count(), 1u);
}

SampleVector::~SampleVector() {}

void SampleVector::Accumulate(Sample value, Count count) {
  size_t bucket_index = GetBucketIndex(value);
  subtle::NoBarrier_Store(&counts_[bucket_index],
      subtle::NoBarrier_Load(&counts_[bucket_index]) + count);
  IncreaseSum(count * value);
  IncreaseRedundantCount(count);
}

Count SampleVector::GetCount(Sample value) const {
  size_t bucket_index = GetBucketIndex(value);
  return subtle::NoBarrier_Load(&counts_[bucket_index]);
}

Count SampleVector::TotalCount() const {
  Count count = 0;
  for (size_t i = 0; i < counts_.size(); i++) {
    count += subtle::NoBarrier_Load(&counts_[i]);
  }
  return count;
}

Count SampleVector::GetCountAtIndex(size_t bucket_index) const {
  DCHECK(bucket_index < counts_.size());
  return subtle::NoBarrier_Load(&counts_[bucket_index]);
}

scoped_ptr<SampleCountIterator> SampleVector::Iterator() const {
  return scoped_ptr<SampleCountIterator>(
      new SampleVectorIterator(&counts_, bucket_ranges_));
}

bool SampleVector::AddSubtractImpl(SampleCountIterator* iter,
                                   HistogramSamples::Operator op) {
  HistogramBase::Sample min;
  HistogramBase::Sample max;
  HistogramBase::Count count;

  // Go through the iterator and add the counts into correct bucket.
  size_t index = 0;
  while (index < counts_.size() && !iter->Done()) {
    iter->Get(&min, &max, &count);
    if (min == bucket_ranges_->range(index) &&
        max == bucket_ranges_->range(index + 1)) {
      // Sample matches this bucket!
      HistogramBase::Count old_counts =
          subtle::NoBarrier_Load(&counts_[index]);
      subtle::NoBarrier_Store(&counts_[index],
          old_counts + ((op ==  HistogramSamples::ADD) ? count : -count));
      iter->Next();
    } else if (min > bucket_ranges_->range(index)) {
      // Sample is larger than current bucket range. Try next.
      index++;
    } else {
      // Sample is smaller than current bucket range. We scan buckets from
      // smallest to largest, so the sample value must be invalid.
      return false;
    }
  }

  return iter->Done();
}

// Use simple binary search.  This is very general, but there are better
// approaches if we knew that the buckets were linearly distributed.
size_t SampleVector::GetBucketIndex(Sample value) const {
  size_t bucket_count = bucket_ranges_->bucket_count();
  CHECK_GE(bucket_count, 1u);
  CHECK_GE(value, bucket_ranges_->range(0));
  CHECK_LT(value, bucket_ranges_->range(bucket_count));

  size_t under = 0;
  size_t over = bucket_count;
  size_t mid;
  do {
    DCHECK_GE(over, under);
    mid = under + (over - under)/2;
    if (mid == under)
      break;
    if (bucket_ranges_->range(mid) <= value)
      under = mid;
    else
      over = mid;
  } while (true);

  DCHECK_LE(bucket_ranges_->range(mid), value);
  CHECK_GT(bucket_ranges_->range(mid + 1), value);
  return mid;
}

SampleVectorIterator::SampleVectorIterator(const std::vector<Count>* counts,
                                           const BucketRanges* bucket_ranges)
    : counts_(counts),
      bucket_ranges_(bucket_ranges),
      index_(0) {
  CHECK_GE(bucket_ranges_->bucket_count(), counts_->size());
  SkipEmptyBuckets();
}

SampleVectorIterator::~SampleVectorIterator() {}

bool SampleVectorIterator::Done() const {
  return index_ >= counts_->size();
}

void SampleVectorIterator::Next() {
  DCHECK(!Done());
  index_++;
  SkipEmptyBuckets();
}

void SampleVectorIterator::Get(HistogramBase::Sample* min,
                               HistogramBase::Sample* max,
                               HistogramBase::Count* count) const {
  DCHECK(!Done());
  if (min != NULL)
    *min = bucket_ranges_->range(index_);
  if (max != NULL)
    *max = bucket_ranges_->range(index_ + 1);
  if (count != NULL)
    *count = subtle::NoBarrier_Load(&(*counts_)[index_]);
}

bool SampleVectorIterator::GetBucketIndex(size_t* index) const {
  DCHECK(!Done());
  if (index != NULL)
    *index = index_;
  return true;
}

void SampleVectorIterator::SkipEmptyBuckets() {
  if (Done())
    return;

  while (index_ < counts_->size()) {
    if (subtle::NoBarrier_Load(&(*counts_)[index_]) != 0)
      return;
    index_++;
  }
}

}  // namespace base
