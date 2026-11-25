// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_use_counter.h"

#include "impeller/renderer/pipeline_library.h"

namespace impeller {

void PipelineUseCounter::Count(PipelineRef pipeline) {
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  if (!pipeline) {
    return;
  }
  if (!entries_.empty() && entries_.back().pipeline == pipeline) {
    entries_.back().count++;
    return;
  }
  for (auto& entry : entries_) {
    if (entry.pipeline == pipeline) {
      entry.count++;
      return;
    }
  }
  entries_.push_back({.pipeline = pipeline,
                      .descriptor = pipeline->GetDescriptor(),
                      .count = 1});
#endif
}

void PipelineUseCounter::Flush(PipelineLibrary& library) {
  for (const auto& entry : entries_) {
    library.LogPipelineUsage(entry.descriptor, entry.count);
  }
  entries_.clear();
}

}  // namespace impeller
