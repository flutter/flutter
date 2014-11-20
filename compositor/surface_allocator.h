// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_COMPOSITOR_SURFACE_ALLOCATOR_H_
#define SKY_COMPOSITOR_SURFACE_ALLOCATOR_H_

#include "base/basictypes.h"

namespace sky {

class SurfaceAllocator {
 public:
  SurfaceAllocator(uint32_t id_namespace);
  ~SurfaceAllocator();

  uint64_t CreateSurfaceId();

 private:
  uint32_t id_namespace_;
  uint32_t next_id_;

  DISALLOW_COPY_AND_ASSIGN(SurfaceAllocator);
};

}  // namespace sky

#endif  // SKY_COMPOSITOR_SURFACE_ALLOCATOR_H_
