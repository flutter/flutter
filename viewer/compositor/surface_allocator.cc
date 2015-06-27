// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/compositor/surface_allocator.h"

#include "base/logging.h"

namespace sky {

SurfaceAllocator::SurfaceAllocator(uint32_t id_namespace)
    : id_namespace_(id_namespace), next_id_(1) {
  DCHECK(id_namespace);
}

SurfaceAllocator::~SurfaceAllocator() {
}

mojo::SurfaceIdPtr SurfaceAllocator::CreateSurfaceId() {
  auto id = mojo::SurfaceId::New();
  id->local = next_id_++;
  id->id_namespace = id_namespace_;
  return id.Pass();
}

}  // namespace sky
