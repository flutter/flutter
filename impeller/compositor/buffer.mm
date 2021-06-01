// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/buffer.h"

#include "flutter/fml/logging.h"

namespace impeller {

Buffer::Buffer(id<MTLBuffer> buffer,
               size_t size,
               StorageMode mode,
               std::string label)
    : buffer_(buffer), size_(size), mode_(mode), label_(std::move(label)) {}

Buffer::~Buffer() = default;

std::shared_ptr<HostBuffer> HostBuffer::Create() {
  return std::shared_ptr<HostBuffer>(new HostBuffer());
}

HostBuffer::HostBuffer() = default;

HostBuffer::~HostBuffer() {
  ::free(buffer_);
}

std::shared_ptr<BufferView> HostBuffer::Emplace(size_t length) {
  auto old_length = length_;
  if (!Truncate(length_ + length)) {
    return nullptr;
  }
  return std::shared_ptr<BufferView>(
      new BufferView(shared_from_this(), Range{old_length, length}));
}

bool HostBuffer::Truncate(size_t length) {
  if (!ReserveNPOT(length)) {
    return false;
  }
  length_ = length;
  return true;
}

static uint32_t NextPowerOfTwoSize(uint32_t x) {
  if (x == 0) {
    return 1;
  }

  --x;

  x |= x >> 1;
  x |= x >> 2;
  x |= x >> 4;
  x |= x >> 8;
  x |= x >> 16;

  return x + 1;
}

bool HostBuffer::ReserveNPOT(size_t reserved) {
  return Reserve(NextPowerOfTwoSize(reserved));
}

bool HostBuffer::Reserve(size_t reserved) {
  if (reserved == reserved_) {
    return true;
  }
  auto new_allocation = ::realloc(buffer_, reserved);
  if (!new_allocation) {
    // If new length is zero, a minimum non-zero sized allocation is returned.
    // So this check will not trip and this routine will indicate success as
    // expected.
    FML_LOG(ERROR) << "Allocation failed. Out of memory.";
    return false;
  }
  buffer_ = static_cast<uint8_t*>(new_allocation);
  reserved_ = reserved;
  return true;
}

}  // namespace impeller
