// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/base/backend_cast.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/device_buffer.h"

namespace impeller {

// https://github.com/flutter/flutter/issues/112387
// This buffer can be freed once the command buffer is disposed.
// vmaDestroyBuffer(allocator_, buffer_, allocation_);
struct BackingAllocationVK {
  VmaAllocator* allocator = nullptr;
  VmaAllocation allocation = nullptr;
  VmaAllocationInfo allocation_info = {};
};

struct DeviceBufferAllocationVK {
  vk::Buffer buffer = VK_NULL_HANDLE;
  BackingAllocationVK backing_allocation = {};

  void* GetMapping() const;

  vk::Buffer GetBufferHandle() const;
};

class DeviceBufferVK final : public DeviceBuffer,
                             public BackendCast<DeviceBufferVK, DeviceBuffer> {
 public:
  DeviceBufferVK(DeviceBufferDescriptor desc,
                 ContextVK& context,
                 std::unique_ptr<DeviceBufferAllocationVK> device_allocation);

  // |DeviceBuffer|
  ~DeviceBufferVK() override;

  vk::Buffer GetVKBufferHandle() const;

 private:
  friend class AllocatorVK;

  ContextVK& context_;
  std::unique_ptr<DeviceBufferAllocationVK> device_allocation_;

  // |DeviceBuffer|
  uint8_t* OnGetContents() const override;

  // |DeviceBuffer|
  bool OnCopyHostBuffer(const uint8_t* source,
                        Range source_range,
                        size_t offset) override;

  // |DeviceBuffer|
  bool SetLabel(const std::string& label) override;

  // |DeviceBuffer|
  bool SetLabel(const std::string& label, Range range) override;

  FML_DISALLOW_COPY_AND_ASSIGN(DeviceBufferVK);
};

}  // namespace impeller
