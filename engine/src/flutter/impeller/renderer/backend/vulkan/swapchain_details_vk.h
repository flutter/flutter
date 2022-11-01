// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/vulkan/vk.h"

namespace impeller {

class SwapchainDetailsVK {
 public:
  static std::unique_ptr<SwapchainDetailsVK> Create(
      vk::PhysicalDevice physical_device,
      vk::SurfaceKHR surface);

  SwapchainDetailsVK(vk::SurfaceCapabilitiesKHR capabilities,
                     std::vector<vk::SurfaceFormatKHR> surface_formats,
                     std::vector<vk::PresentModeKHR> surface_present_modes,
                     vk::CompositeAlphaFlagBitsKHR composite_alpha);

  ~SwapchainDetailsVK();

  vk::SurfaceFormatKHR PickSurfaceFormat() const;

  vk::PresentModeKHR PickPresentationMode() const;

  vk::CompositeAlphaFlagBitsKHR PickCompositeAlpha() const;

  vk::Extent2D PickExtent() const;

  uint32_t GetImageCount() const;

  vk::SurfaceTransformFlagBitsKHR GetTransform() const;

 private:
  vk::SurfaceCapabilitiesKHR surface_capabilities_;
  std::vector<vk::SurfaceFormatKHR> surface_formats_;
  std::vector<vk::PresentModeKHR> present_modes_;
  vk::CompositeAlphaFlagBitsKHR composite_alpha_;

  FML_DISALLOW_COPY_AND_ASSIGN(SwapchainDetailsVK);
};

}  // namespace impeller
