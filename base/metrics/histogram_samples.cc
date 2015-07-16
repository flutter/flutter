// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/histogram_samples.h"

#include "base/compiler_specific.h"
#include "base/pickle.h"

namespace base {

namespace {

class SampleCountPickleIterator : public SampleCountIterator {
 public:
  explicit SampleCountPickleIterator(PickleIterator* iter);

  bool Done() const override;
  void Next() override;
  void Get(HistogramBase::Sample* min,
           HistogramBase::Sample* max,
           HistogramBase::Count* count) const override;

 private:
  PickleIterator* const iter_;

  HistogramBase::Sample min_;
  HistogramBase::Sample max_;
  HistogramBase::Count count_;
  bool is_done_;
};

SampleCountPickleIterator::SampleCountPickleIterator(PickleIterator* iter)
    : iter_(iter),
      is_done_(false) {
  Next();
}

bool SampleCountPickleIterator::Done() const {
  return is_done_;
}

void SampleCountPickleIterator::Next() {
  DCHECK(!Done());
  if (!iter_->ReadInt(&min_) ||
      !iter_->ReadInt(&max_) ||
      !iter_->ReadInt(&count_))
    is_done_ = true;
}

void SampleCountPickleIterator::Get(HistogramBase::Sample* min,
                                    HistogramBase::Sample* max,
                                    HistogramBase::Count* count) const {
  DCHECK(!Done());
  *min = min_;
  *max = max_;
  *count = count_;
}

}  // namespace

HistogramSamples::HistogramSamples() : sum_(0), redundant_count_(0) {}

HistogramSamples::~HistogramSamples() {}

void HistogramSamples::Add(const HistogramSamples& other) {
  sum_ += other.sum();
  HistogramBase::Count old_redundant_count =
      subtle::NoBarrier_Load(&redundant_count_);
  subtle::NoBarrier_Store(&redundant_count_,
      old_redundant_count + other.redundant_count());
  bool success = AddSubtractImpl(other.Iterator().get(), ADD);
  DCHECK(success);
}

bool HistogramSamples::AddFromPickle(PickleIterator* iter) {
  int64 sum;
  HistogramBase::Count redundant_count;

  if (!iter->ReadInt64(&sum) || !iter->ReadInt(&redundant_count))
    return false;
  sum_ += sum;
  HistogramBase::Count old_redundant_count =
      subtle::NoBarrier_Load(&redundant_count_);
  subtle::NoBarrier_Store(&redundant_count_,
                          old_redundant_count + redundant_count);

  SampleCountPickleIterator pickle_iter(iter);
  return AddSubtractImpl(&pickle_iter, ADD);
}

void HistogramSamples::Subtract(const HistogramSamples& other) {
  sum_ -= other.sum();
  HistogramBase::Count old_redundant_count =
      subtle::NoBarrier_Load(&redundant_count_);
  subtle::NoBarrier_Store(&redundant_count_,
                          old_redundant_count - other.redundant_count());
  bool success = AddSubtractImpl(other.Iterator().get(), SUBTRACT);
  DCHECK(success);
}

bool HistogramSamples::Serialize(Pickle* pickle) const {
  if (!pickle->WriteInt64(sum_) ||
      !pickle->WriteInt(subtle::NoBarrier_Load(&redundant_count_)))
    return false;

  HistogramBase::Sample min;
  HistogramBase::Sample max;
  HistogramBase::Count count;
  for (scoped_ptr<SampleCountIterator> it = Iterator();
       !it->Done();
       it->Next()) {
    it->Get(&min, &max, &count);
    if (!pickle->WriteInt(min) ||
        !pickle->WriteInt(max) ||
        !pickle->WriteInt(count))
      return false;
  }
  return true;
}

void HistogramSamples::IncreaseSum(int64 diff) {
  sum_ += diff;
}

void HistogramSamples::IncreaseRedundantCount(HistogramBase::Count diff) {
  subtle::NoBarrier_Store(&redundant_count_,
      subtle::NoBarrier_Load(&redundant_count_) + diff);
}

SampleCountIterator::~SampleCountIterator() {}

bool SampleCountIterator::GetBucketIndex(size_t* index) const {
  DCHECK(!Done());
  return false;
}

}  // namespace base
