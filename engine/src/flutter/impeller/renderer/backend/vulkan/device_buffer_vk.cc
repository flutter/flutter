// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"

#include "fml/logging.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

void* DeviceBufferAllocationVK::GetMapping() const {
  return backing_allocation.allocation_info.pMappedData;
}

vk::Buffer DeviceBufferAllocationVK::GetBufferHandle() const {
  return buffer;
}

DeviceBufferVK::DeviceBufferVK(
    DeviceBufferDescriptor desc,
    ContextVK& context,
    std::unique_ptr<DeviceBufferAllocationVK> device_allocation)
    : DeviceBuffer(desc),
      context_(context),
      device_allocation_(std::move(device_allocation)) {}

DeviceBufferVK::~DeviceBufferVK() = default;

uint8_t* DeviceBufferVK::OnGetContents() const {
  return reinterpret_cast<uint8_t*>(device_allocation_->GetMapping());
}

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
