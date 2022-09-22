// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/geometry/size.h"
#include "impeller/renderer/backend/vulkan/swapchain_details_vk.h"
#include "impeller/renderer/surface.h"

namespace impeller {

class SwapchainImageVK {
 public:
  SwapchainImageVK(vk::Image image,
                   vk::UniqueImageView image_view,
                   vk::Format image_format,
                   vk::Extent2D extent);

  ~SwapchainImageVK();

  PixelFormat GetPixelFormat() const;

  ISize GetSize() const;

  vk::Image GetImage() const;

  vk::ImageView GetImageView() const;

 private:
  vk::Image image_;
  vk::UniqueImageView image_view_;
  vk::Format image_format_;
  vk::Extent2D extent_;

  FML_DISALLOW_COPY_AND_ASSIGN(SwapchainImageVK);
};

class SwapchainVK {
 public:
  static std::unique_ptr<SwapchainVK> Create(vk::Device device,
                                             vk::SurfaceKHR surface,
                                             SwapchainDetailsVK& details);

  SwapchainVK(vk::Device device,
              vk::UniqueSwapchainKHR swapchain,
              vk::Format image_format,
              vk::Extent2D extent);

  ~SwapchainVK();

  vk::SwapchainKHR GetSwapchain() const;

  SwapchainImageVK* GetSwapchainImage(uint32_t image_index) const;

 private:
  bool CreateSwapchainImages();

  vk::Device device_;
  vk::UniqueSwapchainKHR swapchain_;
  vk::Format image_format_;
  vk::Extent2D extent_;
  std::vector<std::unique_ptr<SwapchainImageVK>> swapchain_images_;

  FML_DISALLOW_COPY_AND_ASSIGN(SwapchainVK);
};

}  // namespace impeller
