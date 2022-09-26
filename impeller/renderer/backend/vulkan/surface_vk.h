// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain_vk.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class SurfaceVK final : public Surface {
 public:
  using SwapCallback = std::function<bool(void)>;

  static std::unique_ptr<SurfaceVK> WrapSwapchainImage(
      uint32_t frame_num,
      SwapchainImageVK* swapchain_image,
      ContextVK* context,
      SwapCallback swap_callback);

  SurfaceVK(RenderTarget target,
            SwapchainImageVK* swapchain_image,
            SwapCallback swap_callback);

  // |Surface|
  ~SurfaceVK() override;

 private:
  const SwapchainImageVK* swapchain_image_;
  SwapCallback swap_callback_;

  // |Surface|
  bool Present() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceVK);
};

}  // namespace impeller
