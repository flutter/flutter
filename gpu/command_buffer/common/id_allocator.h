// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the definition of the IdAllocator class.

#ifndef GPU_COMMAND_BUFFER_CLIENT_ID_ALLOCATOR_H_
#define GPU_COMMAND_BUFFER_CLIENT_ID_ALLOCATOR_H_

#include <stdint.h>

#include <map>
#include <utility>

#include "base/compiler_specific.h"
#include "base/macros.h"
#include "gpu/gpu_export.h"

namespace gpu {

// A resource ID, key to the resource maps.
typedef uint32_t ResourceId;
// Invalid resource ID.
static const ResourceId kInvalidResource = 0u;

// A class to manage the allocation of resource IDs.
class GPU_EXPORT IdAllocator {
 public:
  IdAllocator();
  ~IdAllocator();

  // Allocates a new resource ID.
  ResourceId AllocateID();

  // Allocates an Id starting at or above desired_id.
  // Note: may wrap if it starts near limit.
  ResourceId AllocateIDAtOrAbove(ResourceId desired_id);

  // Allocates |range| amount of contiguous ids.
  // Returns the first id to |first_id| or |kInvalidResource| if
  // allocation failed.
  ResourceId AllocateIDRange(uint32_t range);

  // Marks an id as used. Returns false if id was already used.
  bool MarkAsUsed(ResourceId id);

  // Frees a resource ID.
  void FreeID(ResourceId id);

  // Frees a |range| amount of contiguous ids, starting from |first_id|.
  void FreeIDRange(ResourceId first_id, uint32_t range);

  // Checks whether or not a resource ID is in use.
  bool InUse(ResourceId id) const;

 private:
  // first_id -> last_id mapping.
  typedef std::map<ResourceId, ResourceId> ResourceIdRangeMap;

  ResourceIdRangeMap used_ids_;

  DISALLOW_COPY_AND_ASSIGN(IdAllocator);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_ID_ALLOCATOR_H_
