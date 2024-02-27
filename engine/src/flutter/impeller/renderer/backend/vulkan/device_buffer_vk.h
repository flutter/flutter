// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DEVICE_BUFFER_VK_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DEVICE_BUFFER_VK_H_

#include <memory>

#include "impeller/base/backend_cast.h"
#include "impeller/core/device_buffer.h"
#include "impeller/renderer/backend/vulkan/resource_manager_vk.h"
#include "impeller/renderer/backend/vulkan/vma.h"

namespace impeller {

class DeviceBufferVK final : public DeviceBuffer,
                             public BackendCast<DeviceBufferVK, DeviceBuffer> {
 public:
  DeviceBufferVK(DeviceBufferDescriptor desc,
                 std::weak_ptr<Context> context,
                 UniqueBufferVMA buffer,
                 VmaAllocationInfo info);

  // |DeviceBuffer|
  ~DeviceBufferVK() override;

  vk::Buffer GetBuffer() const;

 private:
  friend class AllocatorVK;

  struct BufferResource {
    UniqueBufferVMA buffer;
    VmaAllocationInfo info = {};

    BufferResource() = default;

    BufferResource(UniqueBufferVMA p_buffer, VmaAllocationInfo p_info)
        : buffer(std::move(p_buffer)), info(p_info) {}

    BufferResource(BufferResource&& o) {
      std::swap(o.buffer, buffer);
      std::swap(o.info, info);
    }

    BufferResource(const BufferResource&) = delete;

    BufferResource& operator=(const BufferResource&) = delete;
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

  // |DeviceBuffer|
  void Flush(std::optional<Range> range) const override;

  // |DeviceBuffer|
  void Invalidate(std::optional<Range> range) const override;

  DeviceBufferVK(const DeviceBufferVK&) = delete;

  DeviceBufferVK& operator=(const DeviceBufferVK&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_VULKAN_DEVICE_BUFFER_VK_H_
