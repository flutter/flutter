// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/allocator.h"

namespace impeller {

Allocator::Allocator() = default;

Allocator::~Allocator() = default;

bool Allocator::RequiresExplicitHostSynchronization(StorageMode mode) {
  if (mode != StorageMode::kHostVisible) {
    return false;
  }

#if FML_OS_IOS
  // StorageMode::kHostVisible is MTLStorageModeShared already.
  return false;
#else   // OS_IOS
  // StorageMode::kHostVisible is MTLResourceStorageModeManaged.
  return true;
#endif  // OS_IOS
}

}  // namespace impeller
