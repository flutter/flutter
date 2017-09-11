// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_SURFACE_H_
#define FLUTTER_VULKAN_VULKAN_SURFACE_H_

#include "flutter/vulkan/vulkan_handle.h"
#include "lib/fxl/macros.h"
#include "third_party/skia/include/core/SkSize.h"

namespace vulkan {

class VulkanProcTable;
class VulkanApplication;
class VulkanNativeSurface;

class VulkanSurface {
 public:
  VulkanSurface(VulkanProcTable& vk,
                VulkanApplication& application,
                std::unique_ptr<VulkanNativeSurface> native_surface);

  ~VulkanSurface();

  bool IsValid() const;

  /// Returns the current size of the surface or (0, 0) if invalid.
  SkISize GetSize() const;

  const VulkanHandle<VkSurfaceKHR>& Handle() const;

  const VulkanNativeSurface& GetNativeSurface() const;

 private:
  VulkanProcTable& vk;
  VulkanApplication& application_;
  std::unique_ptr<VulkanNativeSurface> native_surface_;
  VulkanHandle<VkSurfaceKHR> surface_;
  bool valid_;

  FXL_DISALLOW_COPY_AND_ASSIGN(VulkanSurface);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_SURFACE_H_
