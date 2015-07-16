// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "SkDiscardableMemory_chrome.h"

#include "base/memory/discardable_memory.h"
#include "base/memory/discardable_memory_allocator.h"

SkDiscardableMemoryChrome::~SkDiscardableMemoryChrome() {}

bool SkDiscardableMemoryChrome::lock() {
  return discardable_->Lock();
}

void* SkDiscardableMemoryChrome::data() {
  return discardable_->data();
}

void SkDiscardableMemoryChrome::unlock() {
  discardable_->Unlock();
}

SkDiscardableMemoryChrome::SkDiscardableMemoryChrome(
    scoped_ptr<base::DiscardableMemory> memory)
    : discardable_(memory.Pass()) {
}

SkDiscardableMemory* SkDiscardableMemory::Create(size_t bytes) {
  return new SkDiscardableMemoryChrome(
      base::DiscardableMemoryAllocator::GetInstance()
          ->AllocateLockedDiscardableMemory(bytes));
}
