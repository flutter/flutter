// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_PIPELINE_USE_COUNTER_H_
#define FLUTTER_IMPELLER_RENDERER_PIPELINE_USE_COUNTER_H_

#include <vector>

#include "impeller/renderer/pipeline.h"
#include "impeller/renderer/pipeline_descriptor.h"

namespace impeller {

class PipelineLibrary;

//------------------------------------------------------------------------------
/// @brief      Counts one render pass's pipeline uses and reports them to a
///             pipeline library in one batch per distinct pipeline. Counting
///             a use compares pointers, while reporting one hashes the
///             descriptor under the library's lock, so this keeps that work
///             out of every draw. Does nothing in release builds, which keep
///             no use counts.
///
class PipelineUseCounter {
 public:
  /// Counts a use of [pipeline].
  void Count(PipelineRef pipeline);

  /// Reports the uses counted since the last flush to [library].
  void Flush(PipelineLibrary& library);

 private:
  struct Entry {
    PipelineRef pipeline;
    // Copied, so a pipeline evicted before the flush still reports.
    PipelineDescriptor descriptor{};
    int count = 0;
  };
  std::vector<Entry> entries_;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_PIPELINE_USE_COUNTER_H_
