// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MEMORY_DISCARDABLE_MEMORY_ALLOCATOR_H_
#define BASE_MEMORY_DISCARDABLE_MEMORY_ALLOCATOR_H_

#include "base/base_export.h"
#include "base/memory/scoped_ptr.h"

namespace base {
class DiscardableMemory;

class BASE_EXPORT DiscardableMemoryAllocator {
 public:
  // Returns the allocator instance.
  static DiscardableMemoryAllocator* GetInstance();

  // Sets the allocator instance. Can only be called once, e.g. on startup.
  // Ownership of |instance| remains with the caller.
  static void SetInstance(DiscardableMemoryAllocator* allocator);

  virtual scoped_ptr<DiscardableMemory> AllocateLockedDiscardableMemory(
      size_t size) = 0;

 protected:
  virtual ~DiscardableMemoryAllocator() {}
};

}  // namespace base

#endif  // BASE_MEMORY_DISCARDABLE_MEMORY_ALLOCATOR_H_
