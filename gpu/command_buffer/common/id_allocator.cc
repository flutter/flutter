// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the implementation of IdAllocator.

#include "gpu/command_buffer/common/id_allocator.h"

#include <limits>
#include "base/logging.h"

namespace gpu {

IdAllocator::IdAllocator() {
  COMPILE_ASSERT(kInvalidResource == 0u, invalid_resource_is_not_zero);
  // Simplify the code by making sure that lower_bound(id) never
  // returns the beginning of the map, if id is valid (eg !=
  // kInvalidResource).
  used_ids_.insert(std::make_pair(0u, 0u));
}

IdAllocator::~IdAllocator() {}

ResourceId IdAllocator::AllocateID() {
  return AllocateIDRange(1u);
}

ResourceId IdAllocator::AllocateIDAtOrAbove(ResourceId desired_id) {
  if (desired_id == 0u || desired_id == 1u) {
    return AllocateIDRange(1u);
  }

  ResourceIdRangeMap::iterator current = used_ids_.lower_bound(desired_id);
  ResourceIdRangeMap::iterator next = current;
  if (current == used_ids_.end() || current->first > desired_id) {
    current--;
  } else {
    next++;
  }

  ResourceId first_id = current->first;
  ResourceId last_id = current->second;

  DCHECK(desired_id >= first_id);

  if (desired_id - 1u <= last_id) {
    // Append to current range.
    last_id++;
    if (last_id == 0) {
      // The increment overflowed.
      return AllocateIDRange(1u);
    }

    current->second = last_id;

    if (next != used_ids_.end() && next->first - 1u == last_id) {
      // Merge with next range.
      current->second = next->second;
      used_ids_.erase(next);
    }
    return last_id;
  } else if (next != used_ids_.end() && next->first - 1u == desired_id) {
    // Prepend to next range.
    ResourceId last_existing_id = next->second;
    used_ids_.erase(next);
    used_ids_.insert(std::make_pair(desired_id, last_existing_id));
    return desired_id;
  }
  used_ids_.insert(std::make_pair(desired_id, desired_id));
  return desired_id;
}

ResourceId IdAllocator::AllocateIDRange(uint32_t range) {
  DCHECK(range > 0u);

  ResourceIdRangeMap::iterator current = used_ids_.begin();
  ResourceIdRangeMap::iterator next = current;

  while (++next != used_ids_.end()) {
    if (next->first - current->second > range) {
      break;
    }
    current = next;
  }

  ResourceId first_id = current->second + 1u;
  ResourceId last_id = first_id + range - 1u;

  if (first_id == 0u || last_id < first_id) {
    return kInvalidResource;
  }

  current->second = last_id;

  if (next != used_ids_.end() && next->first - 1u == last_id) {
    // Merge with next range.
    current->second = next->second;
    used_ids_.erase(next);
  }

  return first_id;
}

bool IdAllocator::MarkAsUsed(ResourceId id) {
  DCHECK(id);
  ResourceIdRangeMap::iterator current = used_ids_.lower_bound(id);
  if (current != used_ids_.end() && current->first == id) {
    return false;
  }

  ResourceIdRangeMap::iterator next = current;
  --current;

  if (current->second >= id) {
    return false;
  }

  DCHECK(current->first < id && current->second < id);

  if (current->second + 1u == id) {
    // Append to current range.
    current->second = id;
    if (next != used_ids_.end() && next->first - 1u == id) {
      // Merge with next range.
      current->second = next->second;
      used_ids_.erase(next);
    }
    return true;
  } else if (next != used_ids_.end() && next->first - 1u == id) {
    // Prepend to next range.
    ResourceId last_existing_id = next->second;
    used_ids_.erase(next);
    used_ids_.insert(std::make_pair(id, last_existing_id));
    return true;
  }

  used_ids_.insert(std::make_pair(id, id));
  return true;
}

void IdAllocator::FreeID(ResourceId id) {
  FreeIDRange(id, 1u);
}

void IdAllocator::FreeIDRange(ResourceId first_id, uint32 range) {
  COMPILE_ASSERT(kInvalidResource == 0u, invalid_resource_is_not_zero);

  if (range == 0u || (first_id == 0u && range == 1u)) {
    return;
  }

  if (first_id == 0u) {
    first_id++;
    range--;
  }

  ResourceId last_id = first_id + range - 1u;
  if (last_id < first_id) {
    last_id = std::numeric_limits<ResourceId>::max();
  }

  while (true) {
    ResourceIdRangeMap::iterator current = used_ids_.lower_bound(last_id);
    if (current == used_ids_.end() || current->first > last_id) {
      --current;
    }

    if (current->second < first_id) {
      return;
    }

    if (current->first >= first_id) {
      ResourceId last_existing_id = current->second;
      used_ids_.erase(current);
      if (last_id < last_existing_id) {
        used_ids_.insert(std::make_pair(last_id + 1u, last_existing_id));
      }
    } else if (current->second <= last_id) {
      current->second = first_id - 1u;
    } else {
      DCHECK(current->first < first_id && current->second > last_id);
      ResourceId last_existing_id = current->second;
      current->second = first_id - 1u;
      used_ids_.insert(std::make_pair(last_id + 1u, last_existing_id));
    }
  }
}

bool IdAllocator::InUse(ResourceId id) const {
  if (id == kInvalidResource) {
    return false;
  }

  ResourceIdRangeMap::const_iterator current = used_ids_.lower_bound(id);
  if (current != used_ids_.end()) {
    if (current->first == id) {
      return true;
    }
  }

  --current;
  return current->second >= id;
}

}  // namespace gpu
