// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"

#include "fml/logging.h"
#include "vulkan/vulkan_handles.hpp"

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
    // https://github.com/flutter/flutter/issues/112387
    // This buffer can be freed once the command buffer is disposed.
    // vmaDestroyBuffer(allocator_, buffer_, allocation_);
  }
}

vk::Buffer DeviceBufferAllocationVK::GetBufferHandle() const {
  return buffer_;
}

void* DeviceBufferAllocationVK::GetMapping() const {
  return allocation_info_.pMappedData;
}

DeviceBufferVK::DeviceBufferVK(
    DeviceBufferDescriptor desc,
    ContextVK& context,
    std::unique_ptr<DeviceBufferAllocationVK> device_allocation)
    : DeviceBuffer(std::move(desc)),
      context_(context),
      device_allocation_(std::move(device_allocation)) {}

DeviceBufferVK::~DeviceBufferVK() = default;

bool DeviceBufferVK::OnCopyHostBuffer(const uint8_t* source,
                                      Range source_range,
                                      size_t offset) {
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

vk::Buffer DeviceBufferVK::GetVKBufferHandle() const {
  return device_allocation_->GetBufferHandle();
}

}  // namespace impeller
