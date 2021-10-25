// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/host_buffer.h"

#include <algorithm>

#include "flutter/fml/logging.h"

#include "impeller/renderer/allocator.h"
#include "impeller/renderer/buffer_view.h"
#include "impeller/renderer/device_buffer.h"

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
  return BufferView{shared_from_this(), Range{old_length, length}};
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

}  // namespace impeller
