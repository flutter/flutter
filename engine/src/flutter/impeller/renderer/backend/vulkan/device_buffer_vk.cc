// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"

#include "fml/logging.h"

namespace impeller {

DeviceBufferAllocationVK::DeviceBufferAllocationVK(
    const VmaAllocator& allocator,
    VkBuffer buffer,
    VmaAllocation allocation,
    VmaAllocationInfo allocation_info)
    : allocator_(allocator),
      buffer_(buffer),
      allocation_(allocation),
      allocation_info_(allocation_info) {}

DeviceBufferAllocationVK::~DeviceBufferAllocationVK() {
  if (buffer_) {
    vmaDestroyBuffer(allocator_, buffer_, allocation_);
  }
}

vk::Buffer DeviceBufferAllocationVK::GetBufferHandle() const {
  return buffer_;
}

void* DeviceBufferAllocationVK::GetMapping() const {
  return allocation_info_.pMappedData;
}

DeviceBufferVK::DeviceBufferVK(
    size_t size,
    StorageMode mode,
    ContextVK& context,
    std::unique_ptr<DeviceBufferAllocationVK> device_allocation)
    : DeviceBuffer(size, mode),
      context_(context),
      device_allocation_(std::move(device_allocation)) {}

DeviceBufferVK::~DeviceBufferVK() = default;

bool DeviceBufferVK::CopyHostBuffer(const uint8_t* source,
                                    Range source_range,
                                    size_t offset) {
  if (mode_ != StorageMode::kHostVisible) {
    // One of the storage modes where a transfer queue must be used.
    return false;
  }

  if (offset + source_range.length > size_) {
    // Out of bounds of this buffer.
    return false;
  }

  auto dest = static_cast<uint8_t*>(device_allocation_->GetMapping());

  if (!dest) {
    return false;
  }

  if (source) {
    ::memmove(dest + offset, source + source_range.offset, source_range.length);
  }

  return true;
}

bool DeviceBufferVK::SetLabel(const std::string& label) {
  context_.SetDebugName(device_allocation_->GetBufferHandle(), label);
  return true;
}

bool DeviceBufferVK::SetLabel(const std::string& label, Range range) {
  return SetLabel(label);
}

}  // namespace impeller
