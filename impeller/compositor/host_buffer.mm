// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/compositor/host_buffer.h"

#include <algorithm>

#include "flutter/fml/logging.h"

#include "impeller/compositor/allocator.h"
#include "impeller/compositor/buffer_view.h"
#include "impeller/compositor/device_buffer.h"

namespace impeller {

std::shared_ptr<HostBuffer> HostBuffer::Create() {
  return std::shared_ptr<HostBuffer>(new HostBuffer());
}

HostBuffer::HostBuffer() = default;

HostBuffer::~HostBuffer() {
  ::free(buffer_);
}

void HostBuffer::SetLabel(std::string label) {
  label_ = std::move(label);
}

size_t HostBuffer::GetLength() const {
  return length_;
}

size_t HostBuffer::GetReservedLength() const {
  return reserved_;
}

BufferView HostBuffer::Emplace(const void* buffer,
                               size_t length,
                               size_t align) {
  if (align == 0 || (length_ % align) == 0) {
    return Emplace(buffer, length);
  }

  {
    auto pad = Emplace(nullptr, align - (length_ % align));
    if (!pad) {
      return {};
    }
  }

  return Emplace(buffer, length);
}

BufferView HostBuffer::Emplace(const void* buffer, size_t length) {
  auto old_length = length_;
  if (!Truncate(length_ + length)) {
    return {};
  }
  FML_DCHECK(buffer_);
  generation_++;
  if (buffer) {
    ::memmove(buffer_, buffer, length);
  }
  return BufferView{shared_from_this(), Range{old_length, length}};
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
  // Reserve at least one page of data.
  reserved = std::max<size_t>(4096u, reserved);

  if (reserved == reserved_) {
    return true;
  }

  auto new_allocation = ::realloc(buffer_, reserved);
  if (!new_allocation) {
    // If new length is zero, a minimum non-zero sized allocation is returned.
    // So this check will not trip and this routine will indicate success as
    // expected.
    FML_LOG(ERROR) << "Allocation failed. Out of host memory.";
    return false;
  }

  buffer_ = static_cast<uint8_t*>(new_allocation);
  reserved_ = reserved;

  return true;
}

std::shared_ptr<const DeviceBuffer> HostBuffer::GetDeviceBuffer(
    Allocator& allocator) const {
  if (generation_ == device_buffer_generation_) {
    return device_buffer_;
  }
  auto new_buffer = allocator.CreateBufferWithCopy(buffer_, length_);
  if (!new_buffer) {
    return nullptr;
  }
  new_buffer->SetLabel(label_);
  device_buffer_generation_ = generation_;
  device_buffer_ = std::move(new_buffer);
  return device_buffer_;
}

}  // namespace impeller
