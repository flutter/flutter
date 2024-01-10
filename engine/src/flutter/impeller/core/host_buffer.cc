// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/host_buffer.h"

#include <cstring>
#include <tuple>

#include "impeller/core/allocator.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"

namespace impeller {

constexpr size_t kAllocatorBlockSize = 1024000;  // 1024 Kb.

std::shared_ptr<HostBuffer> HostBuffer::Create(
    const std::shared_ptr<Allocator>& allocator) {
  return std::shared_ptr<HostBuffer>(new HostBuffer(allocator));
}

HostBuffer::HostBuffer(const std::shared_ptr<Allocator>& allocator) {
  state_->allocator = allocator;
  DeviceBufferDescriptor desc;
  desc.size = kAllocatorBlockSize;
  desc.storage_mode = StorageMode::kHostVisible;
  for (auto i = 0u; i < kHostBufferArenaSize; i++) {
    state_->device_buffers[i].push_back(allocator->CreateBuffer(desc));
  }
}

HostBuffer::~HostBuffer() = default;

void HostBuffer::SetLabel(std::string label) {
  state_->label = std::move(label);
}

BufferView HostBuffer::Emplace(const void* buffer,
                               size_t length,
                               size_t align) {
  auto [data, range, device_buffer] = state_->Emplace(buffer, length, align);
  if (!device_buffer) {
    return {};
  }
  return BufferView{std::move(device_buffer), data, range};
}

BufferView HostBuffer::Emplace(const void* buffer, size_t length) {
  auto [data, range, device_buffer] = state_->Emplace(buffer, length);
  if (!device_buffer) {
    return {};
  }
  return BufferView{std::move(device_buffer), data, range};
}

BufferView HostBuffer::Emplace(size_t length,
                               size_t align,
                               const EmplaceProc& cb) {
  auto [data, range, device_buffer] = state_->Emplace(length, align, cb);
  if (!device_buffer) {
    return {};
  }
  return BufferView{std::move(device_buffer), data, range};
}

HostBuffer::TestStateQuery HostBuffer::GetStateForTest() {
  return HostBuffer::TestStateQuery{
      .current_frame = state_->frame_index,
      .current_buffer = state_->current_buffer,
      .total_buffer_count = state_->device_buffers[state_->frame_index].size(),
  };
}

void HostBuffer::Reset() {
  state_->Reset();
}

void HostBuffer::HostBufferState::MaybeCreateNewBuffer(size_t required_size) {
  current_buffer++;
  if (current_buffer >= device_buffers[frame_index].size()) {
    FML_DCHECK(required_size <= kAllocatorBlockSize);
    DeviceBufferDescriptor desc;
    desc.size = kAllocatorBlockSize;
    desc.storage_mode = StorageMode::kHostVisible;
    device_buffers[frame_index].push_back(allocator->CreateBuffer(desc));
  }
  offset = 0;
}

std::tuple<uint8_t*, Range, std::shared_ptr<DeviceBuffer>>
HostBuffer::HostBufferState::Emplace(size_t length,
                                     size_t align,
                                     const EmplaceProc& cb) {
  if (!cb) {
    return {};
  }

  // If the requested allocation is bigger than the block size, create a one-off
  // device buffer and write to that.
  if (length > kAllocatorBlockSize) {
    DeviceBufferDescriptor desc;
    desc.size = length;
    desc.storage_mode = StorageMode::kHostVisible;
    auto device_buffer = allocator->CreateBuffer(desc);
    if (!device_buffer) {
      return {};
    }
    if (cb) {
      cb(device_buffer->OnGetContents());
      device_buffer->Flush(Range{0, length});
    }
    return std::make_tuple(device_buffer->OnGetContents(), Range{0, length},
                           device_buffer);
  }

  auto old_length = GetLength();
  if (old_length + length > kAllocatorBlockSize) {
    MaybeCreateNewBuffer(length);
  }
  old_length = GetLength();

  cb(GetCurrentBuffer()->OnGetContents() + old_length);
  GetCurrentBuffer()->Flush(Range{old_length, length});

  offset += length;
  return std::make_tuple(GetCurrentBuffer()->OnGetContents(),
                         Range{old_length, length}, GetCurrentBuffer());
}

std::tuple<uint8_t*, Range, std::shared_ptr<DeviceBuffer>>
HostBuffer::HostBufferState::Emplace(const void* buffer, size_t length) {
  // If the requested allocation is bigger than the block size, create a one-off
  // device buffer and write to that.
  if (length > kAllocatorBlockSize) {
    DeviceBufferDescriptor desc;
    desc.size = length;
    desc.storage_mode = StorageMode::kHostVisible;
    auto device_buffer = allocator->CreateBuffer(desc);
    if (!device_buffer) {
      return {};
    }
    if (buffer) {
      if (!device_buffer->CopyHostBuffer(static_cast<const uint8_t*>(buffer),
                                         Range{0, length})) {
        return {};
      }
    }
    return std::make_tuple(device_buffer->OnGetContents(), Range{0, length},
                           device_buffer);
  }

  auto old_length = GetLength();
  if (old_length + length > kAllocatorBlockSize) {
    MaybeCreateNewBuffer(length);
  }
  old_length = GetLength();

  if (buffer) {
    ::memmove(GetCurrentBuffer()->OnGetContents() + old_length, buffer, length);
    GetCurrentBuffer()->Flush(Range{old_length, length});
  }
  offset += length;
  return std::make_tuple(GetCurrentBuffer()->OnGetContents(),
                         Range{old_length, length}, GetCurrentBuffer());
}

std::tuple<uint8_t*, Range, std::shared_ptr<DeviceBuffer>>
HostBuffer::HostBufferState::Emplace(const void* buffer,
                                     size_t length,
                                     size_t align) {
  if (align == 0 || (GetLength() % align) == 0) {
    return Emplace(buffer, length);
  }

  {
    auto [buffer, range, device_buffer] =
        Emplace(nullptr, align - (GetLength() % align));
    if (!buffer) {
      return {};
    }
  }

  return Emplace(buffer, length);
}

void HostBuffer::HostBufferState::Reset() {
  // When resetting the host buffer state at the end of the frame, check if
  // there are any unused buffers and remove them.
  while (device_buffers[frame_index].size() > current_buffer + 1) {
    device_buffers[frame_index].pop_back();
  }

  offset = 0u;
  current_buffer = 0u;
  frame_index = (frame_index + 1) % kHostBufferArenaSize;
}

}  // namespace impeller
