// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/platform/text/ICUError.h"

#include "base/allocator/partition_allocator/oom.h"

namespace blink {

// Distinguish memory allocation failures from other errors.
// https://groups.google.com/a/chromium.org/d/msg/platform-architecture-dev/MP0k9WGnCjA/zIBiJtilBwAJ
static NEVER_INLINE void ICUOutOfMemory() {
  OOM_CRASH();
}

void ICUError::HandleFailure() {
  switch (error_) {
    case U_MEMORY_ALLOCATION_ERROR:
      ICUOutOfMemory();
      break;
    case U_ILLEGAL_ARGUMENT_ERROR:
      CHECK(false) << error_;
      break;
    default:
      break;
  }
}

}  // namespace blink
