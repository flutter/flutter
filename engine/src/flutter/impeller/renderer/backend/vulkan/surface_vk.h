// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/context_vk.h"
#include "impeller/renderer/backend/vulkan/swapchain_image_vk.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class SurfaceVK final : public Surface {
 public:
  using SwapCallback = std::function<bool(void)>;

  static std::unique_ptr<SurfaceVK> WrapSwapchainImage(
      const std::shared_ptr<Context>& context,
      const std::shared_ptr<SwapchainImageVK>& swapchain_image,
      SwapCallback swap_callback);

  // |Surface|
  ~SurfaceVK() override;

 private:
  SwapCallback swap_callback_;

  SurfaceVK(const RenderTarget& target, SwapCallback swap_callback);

  // |Surface|
  bool Present() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceVK);
};

}  // namespace impeller
