// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/pipeline_use_counter.h"

#include "impeller/renderer/pipeline_library.h"

namespace impeller {

void PipelineUseCounter::Flush(PipelineLibrary& library) {
#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DEBUG || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_PROFILE
  for (const auto& entry : entries_) {
    library.LogPipelineUsage(entry.descriptor, entry.count);
  }
  entries_.clear();
#endif
}

}  // namespace impeller
