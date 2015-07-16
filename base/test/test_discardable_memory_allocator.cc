// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_discardable_memory_allocator.h"

#include <stdint.h>

#include "base/memory/discardable_memory.h"

namespace base {
namespace {

class DiscardableMemoryImpl : public DiscardableMemory {
 public:
  explicit DiscardableMemoryImpl(size_t size) : data_(new uint8_t[size]) {}

  // Overridden from DiscardableMemory:
  bool Lock() override { return false; }
  void Unlock() override {}
  void* data() const override { return data_.get(); }

 private:
  scoped_ptr<uint8_t[]> data_;
};

}  // namespace

TestDiscardableMemoryAllocator::TestDiscardableMemoryAllocator() {
}

TestDiscardableMemoryAllocator::~TestDiscardableMemoryAllocator() {
}

scoped_ptr<DiscardableMemory>
TestDiscardableMemoryAllocator::AllocateLockedDiscardableMemory(size_t size) {
  return make_scoped_ptr(new DiscardableMemoryImpl(size));
}

}  // namespace base
