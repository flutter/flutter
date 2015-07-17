// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/metrics/histogram_base.h"

#include <climits>

#include "base/json/json_string_value_serializer.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/metrics/histogram.h"
#include "base/metrics/histogram_samples.h"
#include "base/metrics/sparse_histogram.h"
#include "base/metrics/statistics_recorder.h"
#include "base/pickle.h"
#include "base/process/process_handle.h"
#include "base/strings/stringprintf.h"
#include "base/values.h"

namespace base {

std::string HistogramTypeToString(HistogramType type) {
  switch (type) {
    case HISTOGRAM:
      return "HISTOGRAM";
    case LINEAR_HISTOGRAM:
      return "LINEAR_HISTOGRAM";
    case BOOLEAN_HISTOGRAM:
      return "BOOLEAN_HISTOGRAM";
    case CUSTOM_HISTOGRAM:
      return "CUSTOM_HISTOGRAM";
    case SPARSE_HISTOGRAM:
      return "SPARSE_HISTOGRAM";
    default:
      NOTREACHED();
  }
  return "UNKNOWN";
}

HistogramBase* DeserializeHistogramInfo(PickleIterator* iter) {
  int type;
  if (!iter->ReadInt(&type))
    return NULL;

  switch (type) {
    case HISTOGRAM:
      return Histogram::DeserializeInfoImpl(iter);
    case LINEAR_HISTOGRAM:
      return LinearHistogram::DeserializeInfoImpl(iter);
    case BOOLEAN_HISTOGRAM:
      return BooleanHistogram::DeserializeInfoImpl(iter);
    case CUSTOM_HISTOGRAM:
      return CustomHistogram::DeserializeInfoImpl(iter);
    case SPARSE_HISTOGRAM:
      return SparseHistogram::DeserializeInfoImpl(iter);
    default:
      return NULL;
  }
}

const HistogramBase::Sample HistogramBase::kSampleType_MAX = INT_MAX;

HistogramBase::HistogramBase(const std::string& name)
    : histogram_name_(name),
      flags_(kNoFlags) {}

HistogramBase::~HistogramBase() {}

void HistogramBase::CheckName(const StringPiece& name) const {
  DCHECK_EQ(histogram_name(), name);
}

void HistogramBase::SetFlags(int32 flags) {
  flags_ |= flags;
}

void HistogramBase::ClearFlags(int32 flags) {
  flags_ &= ~flags;
}

void HistogramBase::AddTime(const TimeDelta& time) {
  Add(static_cast<Sample>(time.InMilliseconds()));
}

void HistogramBase::AddBoolean(bool value) {
  Add(value ? 1 : 0);
}

bool HistogramBase::SerializeInfo(Pickle* pickle) const {
  if (!pickle->WriteInt(GetHistogramType()))
    return false;
  return SerializeInfoImpl(pickle);
}

int HistogramBase::FindCorruption(const HistogramSamples& samples) const {
  // Not supported by default.
  return NO_INCONSISTENCIES;
}

void HistogramBase::WriteJSON(std::string* output) const {
  Count count;
  int64 sum;
  scoped_ptr<ListValue> buckets(new ListValue());
  GetCountAndBucketData(&count, &sum, buckets.get());
  scoped_ptr<DictionaryValue> parameters(new DictionaryValue());
  GetParameters(parameters.get());

  JSONStringValueSerializer serializer(output);
  DictionaryValue root;
  root.SetString("name", histogram_name());
  root.SetInteger("count", count);
  root.SetDouble("sum", static_cast<double>(sum));
  root.SetInteger("flags", flags());
  root.Set("params", parameters.Pass());
  root.Set("buckets", buckets.Pass());
  root.SetInteger("pid", GetCurrentProcId());
  serializer.Serialize(root);
}

void HistogramBase::FindAndRunCallback(HistogramBase::Sample sample) const {
  if ((flags_ & kCallbackExists) == 0)
    return;

  StatisticsRecorder::OnSampleCallback cb =
      StatisticsRecorder::FindCallback(histogram_name());
  if (!cb.is_null())
    cb.Run(sample);
}

void HistogramBase::WriteAsciiBucketGraph(double current_size,
                                          double max_size,
                                          std::string* output) const {
  const int k_line_length = 72;  // Maximal horizontal width of graph.
  int x_count = static_cast<int>(k_line_length * (current_size / max_size)
                                 + 0.5);
  int x_remainder = k_line_length - x_count;

  while (0 < x_count--)
    output->append("-");
  output->append("O");
  while (0 < x_remainder--)
    output->append(" ");
}

const std::string HistogramBase::GetSimpleAsciiBucketRange(
    Sample sample) const {
  std::string result;
  if (kHexRangePrintingFlag & flags())
    StringAppendF(&result, "%#x", sample);
  else
    StringAppendF(&result, "%d", sample);
  return result;
}

void HistogramBase::WriteAsciiBucketValue(Count current,
                                          double scaled_sum,
                                          std::string* output) const {
  StringAppendF(output, " (%d = %3.1f%%)", current, current/scaled_sum);
}

}  // namespace base
