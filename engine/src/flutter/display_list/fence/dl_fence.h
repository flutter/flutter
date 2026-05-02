// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_DISPLAY_LIST_FENCE_DL_FENCE_H_
#define FLUTTER_DISPLAY_LIST_FENCE_DL_FENCE_H_

#include "third_party/skia/include/core/SkRefCnt.h"
#include "third_party/skia/include/gpu/ganesh/GrBackendSemaphore.h"

using DlMetalEvent = const void*;

namespace flutter {
class DlFence : public SkRefCnt {
 public:
  static sk_sp<DlFence> MakeFromMetalEvent(DlMetalEvent event, uint64_t value);

  virtual ~DlFence() = default;

  virtual GrBackendSemaphore CreateGrBackendSemaphore(
      uint64_t increment) const = 0;

  virtual void FreeBackendSemaphore(GrBackendSemaphore& semaphore) const = 0;
};
}  // namespace flutter

#endif  // FLUTTER_DISPLAY_LIST_FENCE_DL_FENCE_H_
