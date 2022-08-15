// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/swapchain_vk.h"
#include "impeller/renderer/backend/vulkan/vk.h"
#include "impeller/renderer/surface.h"

namespace impeller {

struct SurfaceProducerCreateInfoVK {
  vk::Device device;
  vk::Queue graphics_queue;
  vk::Queue present_queue;
  SwapchainVK* swapchain;
};

class SurfaceProducerVK {
 public:
  static std::unique_ptr<SurfaceProducerVK> Create(
      std::weak_ptr<Context> context,
      const SurfaceProducerCreateInfoVK& create_info);

  SurfaceProducerVK(std::weak_ptr<Context> context,
                    const SurfaceProducerCreateInfoVK& create_info);

  ~SurfaceProducerVK();

  std::unique_ptr<Surface> AcquireSurface();

  bool Submit(vk::CommandBuffer buffer);

 private:
  std::weak_ptr<Context> context_;

  bool SetupSyncObjects();

  bool Present(uint32_t image_index);

  const SurfaceProducerCreateInfoVK create_info_;

  // sync objects
  vk::UniqueSemaphore image_available_semaphore_;
  vk::UniqueSemaphore render_finished_semaphore_;
  vk::UniqueFence in_flight_fence_;

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceProducerVK);
};

}  // namespace impeller
