// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/backend_cast.h"
#include "impeller/core/device_buffer.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/resource_manager_vk.h"

namespace impeller {

class DeviceBufferVK final : public DeviceBuffer,
                             public BackendCast<DeviceBufferVK, Buffer> {
 public:
  DeviceBufferVK(DeviceBufferDescriptor desc,
                 std::weak_ptr<Context> context,
                 VmaAllocator allocator,
                 VmaAllocation allocation,
                 VmaAllocationInfo info,
                 vk::Buffer buffer);

  // |DeviceBuffer|
  ~DeviceBufferVK() override;

  vk::Buffer GetBuffer() const;

 private:
  friend class AllocatorVK;

  struct BufferResource {
    VmaAllocator allocator = {};
    VmaAllocation allocation = {};
    VmaAllocationInfo info = {};
    vk::Buffer buffer = {};

    BufferResource() = default;

    BufferResource(VmaAllocator p_allocator,
                   VmaAllocation p_allocation,
                   VmaAllocationInfo p_info,
                   vk::Buffer p_buffer)
        : allocator(p_allocator),
          allocation(p_allocation),
          info(p_info),
          buffer(p_buffer) {}

    BufferResource(BufferResource&& o) {
      std::swap(o.allocator, allocator);
      std::swap(o.allocation, allocation);
      std::swap(o.info, info);
      std::swap(o.buffer, buffer);
    }

    ~BufferResource() {
      if (!buffer) {
        return;
      }
      TRACE_EVENT0("impeller", "DestroyDeviceBuffer");
      ::vmaDestroyBuffer(allocator,
                         static_cast<decltype(buffer)::NativeType>(buffer),
                         allocation);
    }

    FML_DISALLOW_COPY_AND_ASSIGN(BufferResource);
  };

  std::weak_ptr<Context> context_;
  UniqueResourceVKT<BufferResource> resource_;

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
