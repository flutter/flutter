// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/surface.h"
#include "vulkan/vulkan_handles.hpp"

namespace impeller {

struct SurfaceProducerCreateInfoVK {
  vk::Device device;
  vk::Queue graphics_queue;
  vk::Queue present_queue;
  SwapchainVK* swapchain;
};

class SurfaceSyncObjectsVK {
 public:
  vk::UniqueSemaphore image_available_semaphore;
  vk::UniqueSemaphore render_finished_semaphore;
  vk::UniqueFence in_flight_fence;

  static std::unique_ptr<SurfaceSyncObjectsVK> Create(vk::Device device);
};

class SurfaceProducerVK {
 public:
  static std::unique_ptr<SurfaceProducerVK> Create(
      const std::weak_ptr<Context>& context,
      const SurfaceProducerCreateInfoVK& create_info);

  SurfaceProducerVK(std::weak_ptr<Context> context,
                    const SurfaceProducerCreateInfoVK& create_info);

  ~SurfaceProducerVK();

  std::unique_ptr<Surface> AcquireSurface(size_t current_frame);

 private:
  std::weak_ptr<Context> context_;

  bool SetupSyncObjects();

  bool Submit(uint32_t frame_num);

  bool Present(size_t frame_num, uint32_t image_index);

  const SurfaceProducerCreateInfoVK create_info_;

  // sync objects
  std::unique_ptr<SurfaceSyncObjectsVK> sync_objects_[kMaxFramesInFlight];

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceProducerVK);
};

}  // namespace impeller
