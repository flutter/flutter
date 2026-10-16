// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/core/host_buffer.h"

#include <cstring>
#include <tuple>

#include "impeller/base/validation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/device_buffer_descriptor.h"
#include "impeller/core/formats.h"

namespace impeller {

constexpr size_t kAllocatorBlockSize = 1024000;  // 1024 Kb.

std::shared_ptr<HostBuffer> HostBuffer::Create(
    const std::shared_ptr<Allocator>& allocator,
    const std::shared_ptr<const IdleWaiter>& idle_waiter,
    size_t minimum_uniform_alignment,
    std::shared_ptr<const GpuSubmissionTracker> submission_tracker) {
  return std::shared_ptr<HostBuffer>(
      new HostBuffer(allocator, idle_waiter, minimum_uniform_alignment,
                     std::move(submission_tracker)));
}

HostBuffer::HostBuffer(
    const std::shared_ptr<Allocator>& allocator,
    const std::shared_ptr<const IdleWaiter>& idle_waiter,
    size_t minimum_uniform_alignment,
    std::shared_ptr<const GpuSubmissionTracker> submission_tracker)
    : allocator_(allocator),
      idle_waiter_(idle_waiter),
      submission_tracker_(std::move(submission_tracker)),
      minimum_uniform_alignment_(minimum_uniform_alignment) {
  DeviceBufferDescriptor desc;
  desc.size = kAllocatorBlockSize;
  desc.storage_mode = StorageMode::kHostVisible;
  for (auto i = 0u; i < kHostBufferArenaSize; i++) {
    std::shared_ptr<DeviceBuffer> device_buffer = allocator->CreateBuffer(desc);
    FML_CHECK(device_buffer) << "Failed to allocate device buffer.";
    device_buffers_[i].push_back(device_buffer);
  }
}

HostBuffer::~HostBuffer() {
  if (idle_waiter_) {
    // Since we hold on to DeviceBuffers we should make sure they aren't being
    // used while we are deleting the HostBuffer.
    idle_waiter_->WaitIdle();
  }
};

BufferView HostBuffer::Emplace(const void* buffer,
                               size_t length,
                               size_t align) {
  auto [range, device_buffer, raw_device_buffer] =
      EmplaceInternal(buffer, length, align);
  if (device_buffer) {
    return BufferView(std::move(device_buffer), range);
  } else if (raw_device_buffer) {
    return BufferView(raw_device_buffer, range);
  } else {
    return {};
  }
}

BufferView HostBuffer::Emplace(const void* buffer, size_t length) {
  auto [range, device_buffer, raw_device_buffer] =
      EmplaceInternal(buffer, length);
  if (device_buffer) {
    return BufferView(std::move(device_buffer), range);
  } else if (raw_device_buffer) {
    return BufferView(raw_device_buffer, range);
  } else {
    return {};
  }
}

BufferView HostBuffer::Emplace(size_t length,
                               size_t align,
                               const EmplaceProc& cb) {
  auto [range, device_buffer, raw_device_buffer] =
      EmplaceInternal(length, align, cb);
  if (device_buffer) {
    return BufferView(std::move(device_buffer), range);
  } else if (raw_device_buffer) {
    return BufferView(raw_device_buffer, range);
  } else {
    return {};
  }
}

HostBuffer::TestStateQuery HostBuffer::GetStateForTest() {
  return HostBuffer::TestStateQuery{
      .current_frame = frame_index_,
      .current_buffer = current_buffer_,
      .total_buffer_count = device_buffers_[frame_index_].size(),
  };
}

bool HostBuffer::MaybeCreateNewBuffer() {
  current_buffer_++;
  if (current_buffer_ >= device_buffers_[frame_index_].size()) {
    DeviceBufferDescriptor desc;
    desc.size = kAllocatorBlockSize;
    desc.storage_mode = StorageMode::kHostVisible;
    std::shared_ptr<DeviceBuffer> buffer = allocator_->CreateBuffer(desc);
    if (!buffer) {
      VALIDATION_LOG << "Failed to allocate host buffer of size " << desc.size;
      return false;
    }
    device_buffers_[frame_index_].push_back(std::move(buffer));
  }
  offset_ = 0;
  return true;
}

std::tuple<Range, std::shared_ptr<DeviceBuffer>, DeviceBuffer*>
HostBuffer::EmplaceInternal(size_t length,
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
    std::shared_ptr<DeviceBuffer> device_buffer =
        allocator_->CreateBuffer(desc);
    if (!device_buffer) {
      return {};
    }
    if (cb) {
      cb(device_buffer->OnGetContents());
      device_buffer->Flush(Range{0, length});
    }
    return std::make_tuple(Range{0, length}, std::move(device_buffer), nullptr);
  }

  size_t padding = 0;
  if (align > 0 && offset_ % align) {
    padding = align - (offset_ % align);
  }
  if (offset_ + padding + length > kAllocatorBlockSize) {
    if (!MaybeCreateNewBuffer()) {
      return {};
    }
  } else {
    offset_ += padding;
  }

  const std::shared_ptr<DeviceBuffer>& current_buffer = GetCurrentBuffer();
  auto contents = current_buffer->OnGetContents();
  cb(contents + offset_);
  Range output_range(offset_, length);
  current_buffer->Flush(output_range);

  offset_ += length;
  return std::make_tuple(output_range, nullptr, current_buffer.get());
}

std::tuple<Range, std::shared_ptr<DeviceBuffer>, DeviceBuffer*>
HostBuffer::EmplaceInternal(const void* buffer, size_t length) {
  // If the requested allocation is bigger than the block size, create a one-off
  // device buffer and write to that.
  if (length > kAllocatorBlockSize) {
    DeviceBufferDescriptor desc;
    desc.size = length;
    desc.storage_mode = StorageMode::kHostVisible;
    std::shared_ptr<DeviceBuffer> device_buffer =
        allocator_->CreateBuffer(desc);
    if (!device_buffer) {
      return {};
    }
    if (buffer) {
      if (!device_buffer->CopyHostBuffer(static_cast<const uint8_t*>(buffer),
                                         Range{0, length})) {
        return {};
      }
    }
    return std::make_tuple(Range{0, length}, std::move(device_buffer), nullptr);
  }

  auto old_length = GetLength();
  if (old_length + length > kAllocatorBlockSize) {
    if (!MaybeCreateNewBuffer()) {
      return {};
    }
  }
  old_length = GetLength();

  const std::shared_ptr<DeviceBuffer>& current_buffer = GetCurrentBuffer();
  auto contents = current_buffer->OnGetContents();
  if (buffer) {
    ::memmove(contents + old_length, buffer, length);
    current_buffer->Flush(Range{old_length, length});
  }
  offset_ += length;
  return std::make_tuple(Range{old_length, length}, nullptr,
                         current_buffer.get());
}

std::tuple<Range, std::shared_ptr<DeviceBuffer>, DeviceBuffer*>
HostBuffer::EmplaceInternal(const void* buffer, size_t length, size_t align) {
  if (align == 0 || (GetLength() % align) == 0) {
    return EmplaceInternal(buffer, length);
  }

  {
    auto padding = align - (GetLength() % align);
    if (offset_ + padding < kAllocatorBlockSize) {
      offset_ += padding;
    } else if (!MaybeCreateNewBuffer()) {
      return {};
    }
  }

  return EmplaceInternal(buffer, length);
}

const std::shared_ptr<DeviceBuffer>& HostBuffer::GetCurrentBuffer() const {
  return device_buffers_[frame_index_][current_buffer_];
}

void HostBuffer::Reset() {
  // When resetting the host buffer state at the end of the frame, check if
  // there are any unused buffers and remove them.
  while (device_buffers_[frame_index_].size() > current_buffer_ + 1) {
    device_buffers_[frame_index_].pop_back();
  }

  if (submission_tracker_) {
    // Everything submitted so far may reference this entry's buffers.
    entry_stamps_[frame_index_] = submission_tracker_->LatestSubmission();
  }

  offset_ = 0u;
  current_buffer_ = 0u;
  frame_index_ = (frame_index_ + 1) % kHostBufferArenaSize;

  if (!submission_tracker_) {
    return;
  }
  uint64_t completed = submission_tracker_->CompletedThrough();

  // Release retired buffers the GPU has completed with.
  std::erase_if(retired_buffers_, [completed](const auto& retired) {
    return retired.first <= completed;
  });

  if (entry_stamps_[frame_index_] <= completed) {
    return;
  }

  // The GPU may still be reading the next entry's buffers. Retire them and
  // start the entry over with a fresh allocation, since reusing them would
  // race the reads of an incomplete earlier frame.
  DeviceBufferDescriptor desc;
  desc.size = kAllocatorBlockSize;
  desc.storage_mode = StorageMode::kHostVisible;
  std::shared_ptr<DeviceBuffer> buffer = allocator_->CreateBuffer(desc);
  if (!buffer) {
    VALIDATION_LOG << "Failed to replace an in-flight host buffer entry.";
    return;
  }
  retired_buffers_.emplace_back(entry_stamps_[frame_index_],
                                std::move(device_buffers_[frame_index_]));
  device_buffers_[frame_index_].clear();
  device_buffers_[frame_index_].push_back(std::move(buffer));
  entry_stamps_[frame_index_] = 0;
}

size_t HostBuffer::GetMinimumUniformAlignment() const {
  return minimum_uniform_alignment_;
}

}  // namespace impeller
