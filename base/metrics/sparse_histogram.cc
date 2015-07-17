// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/sparse_histogram.h"

#include "base/metrics/sample_map.h"
#include "base/metrics/statistics_recorder.h"
#include "base/pickle.h"
#include "base/strings/stringprintf.h"
#include "base/synchronization/lock.h"

namespace base {

typedef HistogramBase::Count Count;
typedef HistogramBase::Sample Sample;

// static
HistogramBase* SparseHistogram::FactoryGet(const std::string& name,
                                           int32 flags) {
  HistogramBase* histogram = StatisticsRecorder::FindHistogram(name);

  if (!histogram) {
    // To avoid racy destruction at shutdown, the following will be leaked.
    HistogramBase* tentative_histogram = new SparseHistogram(name);
    tentative_histogram->SetFlags(flags);
    histogram =
        StatisticsRecorder::RegisterOrDeleteDuplicate(tentative_histogram);
  }
  DCHECK_EQ(SPARSE_HISTOGRAM, histogram->GetHistogramType());
  return histogram;
}

SparseHistogram::~SparseHistogram() {}

HistogramType SparseHistogram::GetHistogramType() const {
  return SPARSE_HISTOGRAM;
}

bool SparseHistogram::HasConstructionArguments(
    Sample expected_minimum,
    Sample expected_maximum,
    size_t expected_bucket_count) const {
  // SparseHistogram never has min/max/bucket_count limit.
  return false;
}

void SparseHistogram::Add(Sample value) {
  {
    base::AutoLock auto_lock(lock_);
    samples_.Accumulate(value, 1);
  }

  FindAndRunCallback(value);
}

scoped_ptr<HistogramSamples> SparseHistogram::SnapshotSamples() const {
  scoped_ptr<SampleMap> snapshot(new SampleMap());

  base::AutoLock auto_lock(lock_);
  snapshot->Add(samples_);
  return snapshot.Pass();
}

void SparseHistogram::AddSamples(const HistogramSamples& samples) {
  base::AutoLock auto_lock(lock_);
  samples_.Add(samples);
}

bool SparseHistogram::AddSamplesFromPickle(PickleIterator* iter) {
  base::AutoLock auto_lock(lock_);
  return samples_.AddFromPickle(iter);
}

void SparseHistogram::WriteHTMLGraph(std::string* output) const {
  output->append("<PRE>");
  WriteAsciiImpl(true, "<br>", output);
  output->append("</PRE>");
}

void SparseHistogram::WriteAscii(std::string* output) const {
  WriteAsciiImpl(true, "\n", output);
}

bool SparseHistogram::SerializeInfoImpl(Pickle* pickle) const {
  return pickle->WriteString(histogram_name()) && pickle->WriteInt(flags());
}

SparseHistogram::SparseHistogram(const std::string& name)
    : HistogramBase(name) {}

HistogramBase* SparseHistogram::DeserializeInfoImpl(PickleIterator* iter) {
  std::string histogram_name;
  int flags;
  if (!iter->ReadString(&histogram_name) || !iter->ReadInt(&flags)) {
    DLOG(ERROR) << "Pickle error decoding Histogram: " << histogram_name;
    return NULL;
  }

  DCHECK(flags & HistogramBase::kIPCSerializationSourceFlag);
  flags &= ~HistogramBase::kIPCSerializationSourceFlag;

  return SparseHistogram::FactoryGet(histogram_name, flags);
}

void SparseHistogram::GetParameters(DictionaryValue* params) const {
  // TODO(kaiwang): Implement. (See HistogramBase::WriteJSON.)
}

void SparseHistogram::GetCountAndBucketData(Count* count,
                                            int64* sum,
                                            ListValue* buckets) const {
  // TODO(kaiwang): Implement. (See HistogramBase::WriteJSON.)
}

void SparseHistogram::WriteAsciiImpl(bool graph_it,
                                     const std::string& newline,
                                     std::string* output) const {
  // Get a local copy of the data so we are consistent.
  scoped_ptr<HistogramSamples> snapshot = SnapshotSamples();
  Count total_count = snapshot->TotalCount();
  double scaled_total_count = total_count / 100.0;

  WriteAsciiHeader(total_count, output);
  output->append(newline);

  // Determine how wide the largest bucket range is (how many digits to print),
  // so that we'll be able to right-align starts for the graphical bars.
  // Determine which bucket has the largest sample count so that we can
  // normalize the graphical bar-width relative to that sample count.
  Count largest_count = 0;
  Sample largest_sample = 0;
  scoped_ptr<SampleCountIterator> it = snapshot->Iterator();
  while (!it->Done()) {
    Sample min;
    Sample max;
    Count count;
    it->Get(&min, &max, &count);
    if (min > largest_sample)
      largest_sample = min;
    if (count > largest_count)
      largest_count = count;
    it->Next();
  }
  size_t print_width = GetSimpleAsciiBucketRange(largest_sample).size() + 1;

  // iterate over each item and display them
  it = snapshot->Iterator();
  while (!it->Done()) {
    Sample min;
    Sample max;
    Count count;
    it->Get(&min, &max, &count);

    // value is min, so display it
    std::string range = GetSimpleAsciiBucketRange(min);
    output->append(range);
    for (size_t j = 0; range.size() + j < print_width + 1; ++j)
      output->push_back(' ');

    if (graph_it)
      WriteAsciiBucketGraph(count, largest_count, output);
    WriteAsciiBucketValue(count, scaled_total_count, output);
    output->append(newline);
    it->Next();
  }
}

void SparseHistogram::WriteAsciiHeader(const Count total_count,
                                       std::string* output) const {
  StringAppendF(output,
                "Histogram: %s recorded %d samples",
                histogram_name().c_str(),
                total_count);
  if (flags() & ~kHexRangePrintingFlag)
    StringAppendF(output, " (flags = 0x%x)", flags() & ~kHexRangePrintingFlag);
}

}  // namespace base
