// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_METRICS_SPARSE_HISTOGRAM_H_
#define BASE_METRICS_SPARSE_HISTOGRAM_H_

#include <map>
#include <string>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram_base.h"
#include "base/metrics/sample_map.h"
#include "base/synchronization/lock.h"

namespace base {

#define UMA_HISTOGRAM_SPARSE_SLOWLY(name, sample) \
    do { \
      base::HistogramBase* histogram = base::SparseHistogram::FactoryGet( \
          name, base::HistogramBase::kUmaTargetedHistogramFlag); \
      histogram->Add(sample); \
    } while (0)

class HistogramSamples;

class BASE_EXPORT_PRIVATE SparseHistogram : public HistogramBase {
 public:
  // If there's one with same name, return the existing one. If not, create a
  // new one.
  static HistogramBase* FactoryGet(const std::string& name, int32 flags);

  ~SparseHistogram() override;

  // HistogramBase implementation:
  HistogramType GetHistogramType() const override;
  bool HasConstructionArguments(Sample expected_minimum,
                                Sample expected_maximum,
                                size_t expected_bucket_count) const override;
  void Add(Sample value) override;
  void AddSamples(const HistogramSamples& samples) override;
  bool AddSamplesFromPickle(base::PickleIterator* iter) override;
  scoped_ptr<HistogramSamples> SnapshotSamples() const override;
  void WriteHTMLGraph(std::string* output) const override;
  void WriteAscii(std::string* output) const override;

 protected:
  // HistogramBase implementation:
  bool SerializeInfoImpl(base::Pickle* pickle) const override;

 private:
  // Clients should always use FactoryGet to create SparseHistogram.
  explicit SparseHistogram(const std::string& name);

  friend BASE_EXPORT_PRIVATE HistogramBase* DeserializeHistogramInfo(
      base::PickleIterator* iter);
  static HistogramBase* DeserializeInfoImpl(base::PickleIterator* iter);

  void GetParameters(DictionaryValue* params) const override;
  void GetCountAndBucketData(Count* count,
                             int64* sum,
                             ListValue* buckets) const override;

  // Helpers for emitting Ascii graphic.  Each method appends data to output.
  void WriteAsciiImpl(bool graph_it,
                      const std::string& newline,
                      std::string* output) const;

  // Write a common header message describing this histogram.
  void WriteAsciiHeader(const Count total_count,
                        std::string* output) const;

  // For constuctor calling.
  friend class SparseHistogramTest;

  // Protects access to |samples_|.
  mutable base::Lock lock_;

  SampleMap samples_;

  DISALLOW_COPY_AND_ASSIGN(SparseHistogram);
};

}  // namespace base

#endif  // BASE_METRICS_SPARSE_HISTOGRAM_H_
