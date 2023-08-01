// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/host_buffer.h"

#include <algorithm>
#include <cstring>

#include "flutter/fml/logging.h"

#include "impeller/core/allocator.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/device_buffer.h"

namespace impeller {

std::shared_ptr<HostBuffer> HostBuffer::Create() {
  return std::shared_ptr<HostBuffer>(new HostBuffer());
}

HostBuffer::HostBuffer() = default;

HostBuffer::~HostBuffer() = default;

void HostBuffer::SetLabel(std::string label) {
  label_ = std::move(label);
}

BufferView HostBuffer::Emplace(const void* buffer,
                               size_t length,
                               size_t align) {
  if (align == 0 || (GetLength() % align) == 0) {
    return Emplace(buffer, length);
  }

  {
    auto pad = Emplace(nullptr, align - (GetLength() % align));
    if (!pad) {
      return {};
    }
  }

  return Emplace(buffer, length);
}

BufferView HostBuffer::Emplace(const void* buffer, size_t length) {
  auto old_length = GetLength();
  if (!Truncate(old_length + length)) {
    return {};
  }
  generation_++;
  if (buffer) {
    ::memmove(GetBuffer() + old_length, buffer, length);
  }
  return BufferView{shared_from_this(), GetBuffer(), Range{old_length, length}};
}

BufferView HostBuffer::Emplace(size_t length,
                               size_t align,
                               const EmplaceProc& cb) {
  if (!cb) {
    return {};
  }
  auto old_length = GetLength();
  if (!Truncate(old_length + length)) {
    return {};
  }
  generation_++;
  cb(GetBuffer() + old_length);

  return BufferView{shared_from_this(), GetBuffer(), Range{old_length, length}};
}

std::shared_ptr<const DeviceBuffer> HostBuffer::GetDeviceBuffer(
    Allocator& allocator) const {
  if (generation_ == device_buffer_generation_) {
    return device_buffer_;
  }
  auto new_buffer = allocator.CreateBufferWithCopy(GetBuffer(), GetLength());
  if (!new_buffer) {
    return nullptr;
  }
  new_buffer->SetLabel(label_);
  device_buffer_generation_ = generation_;
  device_buffer_ = std::move(new_buffer);
  return device_buffer_;
}

void HostBuffer::Reset() {
  generation_ += 1;
  device_buffer_ = nullptr;
  bool did_truncate = Truncate(0);
  FML_CHECK(did_truncate);
}

size_t HostBuffer::GetSize() const {
  return GetReservedLength();
}

}  // namespace impeller
