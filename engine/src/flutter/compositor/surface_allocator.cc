// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/compositor/surface_allocator.h"

#include "base/logging.h"

namespace sky {

SurfaceAllocator::SurfaceAllocator(uint32_t id_namespace)
    : id_namespace_(id_namespace), next_id_(1) {
  DCHECK(id_namespace);
}

SurfaceAllocator::~SurfaceAllocator() {
}

uint64_t SurfaceAllocator::CreateSurfaceId() {
  // Surface IDs are 64 integers. The high 32 bits are the namespace of the ID,
  // which is assigned to us by the surfaces service. The lower 32 bits are ours
  // to allocate as we see fit. For simplicity, we just allocate them
  // sequentially. In principle, we could run out, but at 60 Hz, it takes
  // several years to run out.
  return static_cast<uint64_t>(id_namespace_) << 32 | next_id_++;
}

}  // namespace sky
