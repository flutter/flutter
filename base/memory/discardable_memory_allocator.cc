// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/discardable_memory_allocator.h"

#include "base/logging.h"

namespace base {
namespace {

DiscardableMemoryAllocator* g_allocator = nullptr;

}  // namespace

// static
void DiscardableMemoryAllocator::SetInstance(
    DiscardableMemoryAllocator* allocator) {
  DCHECK(allocator);

  // Make sure this function is only called once before the first call
  // to GetInstance().
  DCHECK(!g_allocator);

  g_allocator = allocator;
}

// static
DiscardableMemoryAllocator* DiscardableMemoryAllocator::GetInstance() {
  DCHECK(g_allocator);
  return g_allocator;
}

}  // namespace base
