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
  state_->label = std::move(label);
}

BufferView HostBuffer::Emplace(const void* buffer,
                               size_t length,
                               size_t align) {
  auto [device_buffer, range] = state_->Emplace(buffer, length, align);
  if (!device_buffer) {
    return {};
  }
  return BufferView{state_, device_buffer, range};
}

BufferView HostBuffer::Emplace(const void* buffer, size_t length) {
  auto [device_buffer, range] = state_->Emplace(buffer, length);
  if (!device_buffer) {
    return {};
  }
  return BufferView{state_, device_buffer, range};
}

BufferView HostBuffer::Emplace(size_t length,
                               size_t align,
                               const EmplaceProc& cb) {
  auto [buffer, range] = state_->Emplace(length, align, cb);
  if (!buffer) {
    return {};
  }
  return BufferView{state_, buffer, range};
}

std::shared_ptr<const DeviceBuffer> HostBuffer::GetDeviceBuffer(
    Allocator& allocator) const {
  return state_->GetDeviceBuffer(allocator);
}

void HostBuffer::Reset() {
  state_->Reset();
}

size_t HostBuffer::GetSize() const {
  return state_->GetReservedLength();
}

size_t HostBuffer::GetLength() const {
  return state_->GetLength();
}

std::pair<uint8_t*, Range> HostBuffer::HostBufferState::Emplace(
    size_t length,
    size_t align,
    const EmplaceProc& cb) {
  if (!cb) {
    return {};
  }
  auto old_length = GetLength();
  if (!Truncate(old_length + length)) {
    return {};
  }
  generation++;
  cb(GetBuffer() + old_length);

  return std::make_pair(GetBuffer(), Range{old_length, length});
}

std::shared_ptr<const DeviceBuffer>
HostBuffer::HostBufferState::GetDeviceBuffer(Allocator& allocator) const {
  if (generation == device_buffer_generation) {
    return device_buffer;
  }
  auto new_buffer = allocator.CreateBufferWithCopy(GetBuffer(), GetLength());
  if (!new_buffer) {
    return nullptr;
  }
  new_buffer->SetLabel(label);
  device_buffer_generation = generation;
  device_buffer = std::move(new_buffer);
  return device_buffer;
}

std::pair<uint8_t*, Range> HostBuffer::HostBufferState::Emplace(
    const void* buffer,
    size_t length) {
  auto old_length = GetLength();
  if (!Truncate(old_length + length)) {
    return {};
  }
  generation++;
  if (buffer) {
    ::memmove(GetBuffer() + old_length, buffer, length);
  }
  return std::make_pair(GetBuffer(), Range{old_length, length});
}

std::pair<uint8_t*, Range> HostBuffer::HostBufferState::Emplace(
    const void* buffer,
    size_t length,
    size_t align) {
  if (align == 0 || (GetLength() % align) == 0) {
    return Emplace(buffer, length);
  }

  {
    auto [buffer, range] = Emplace(nullptr, align - (GetLength() % align));
    if (!buffer) {
      return {};
    }
  }

  return Emplace(buffer, length);
}

void HostBuffer::HostBufferState::Reset() {
  generation += 1;
  device_buffer = nullptr;
  bool did_truncate = Truncate(0);
  FML_CHECK(did_truncate);
}

}  // namespace impeller
