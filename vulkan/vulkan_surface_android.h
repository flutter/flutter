// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_SURFACE_ANDROID_H_
#define FLUTTER_VULKAN_VULKAN_SURFACE_ANDROID_H_

#include "lib/ftl/macros.h"
#include "vulkan_surface.h"

struct ANativeWindow;
typedef struct ANativeWindow ANativeWindow;

namespace vulkan {

class VulkanSurfaceAndroid : public VulkanSurface {
 public:
  VulkanSurfaceAndroid(ANativeWindow* native_window);

  ~VulkanSurfaceAndroid() override;

  const char* ExtensionName() override;

  VkSurfaceKHR CreateSurfaceHandle(VulkanProcTable& vk,
                                   VulkanHandle<VkInstance>& instance) override;

  bool IsValid() const override;

 private:
  ANativeWindow* native_window_;

  FTL_DISALLOW_COPY_AND_ASSIGN(VulkanSurfaceAndroid);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_SURFACE_ANDROID_H_
