// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/tools/debugger/prompt/trace_collector.h"

namespace sky {
namespace debugger {

TraceCollector::TraceCollector(mojo::ScopedDataPipeConsumerHandle source)
    : drainer_(this, source.Pass()), is_complete_(false) {
}

TraceCollector::~TraceCollector() {
}

void TraceCollector::GetTrace(TraceCallback callback) {
  DCHECK(!callback_.is_null());
  if (is_complete_) {
    callback.Run(GetTraceAsString());
    return;
  }
  callback_ = callback;
}

void TraceCollector::OnDataAvailable(const void* data, size_t num_bytes) {
  DCHECK(!is_complete_);
  const char* chars = static_cast<const char*>(data);
  trace_.insert(trace_.end(), chars, chars + num_bytes);
}

void TraceCollector::OnDataComplete() {
  DCHECK(!is_complete_);
  is_complete_ = true;
  if (!callback_.is_null())
    callback_.Run(GetTraceAsString());
}

std::string TraceCollector::GetTraceAsString() {
  return std::string(&trace_.front(), trace_.size());
}

}  // namespace debugger
}  // namespace sky
