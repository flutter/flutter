// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/partitioned_host_buffer.h"

namespace impeller {

PartitionedHostBuffer::PartitionedHostBuffer(
    const std::shared_ptr<Allocator>& allocator,
    const std::shared_ptr<const IdleWaiter>& idle_waiter,
    size_t minimum_uniform_alignment)
    : _dataBuffer(allocator, idle_waiter, minimum_uniform_alignment),
      _indexBuffer(allocator, idle_waiter, minimum_uniform_alignment) {}

BufferView PartitionedHostBuffer::Emplace(const void* buffer,
                                          size_t length,
                                          size_t align,
                                          BufferCategory category) {
  return _buffer(category).Emplace(buffer, length, align, category);
}

BufferView PartitionedHostBuffer::Emplace(size_t length,
                                          size_t align,
                                          BufferCategory category,
                                          const EmplaceProc& cb) {
  return _buffer(category).Emplace(length, align, category, cb);
}

size_t PartitionedHostBuffer::GetMinimumUniformAlignment() const {
  return _dataBuffer.GetMinimumUniformAlignment();
}

void PartitionedHostBuffer::Reset() {
  _dataBuffer.Reset();
  _indexBuffer.Reset();
}

HostBuffer::TestStateQuery PartitionedHostBuffer::GetStateForTest(
    BufferCategory category) {
  return _buffer(category).GetStateForTest(category);
}

SimpleHostBuffer& PartitionedHostBuffer::_buffer(BufferCategory category) {
  switch (category) {
    case BufferCategory::kData:
      return _dataBuffer;
    case BufferCategory::kIndexes:
      return _indexBuffer;
  }
}

}  // namespace impeller
