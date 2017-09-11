// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_ANDROID_H_
#define FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_ANDROID_H_

#include "flutter/vulkan/vulkan_native_surface.h"
#include "lib/fxl/macros.h"

struct ANativeWindow;
typedef struct ANativeWindow ANativeWindow;

namespace vulkan {

class VulkanNativeSurfaceAndroid : public VulkanNativeSurface {
 public:
  /// Create a native surface from the valid ANativeWindow reference. Ownership
  /// of the ANativeWindow is assumed by this instance.
  VulkanNativeSurfaceAndroid(ANativeWindow* native_window);

  ~VulkanNativeSurfaceAndroid();

  const char* GetExtensionName() const override;

  uint32_t GetSkiaExtensionName() const override;

  VkSurfaceKHR CreateSurfaceHandle(
      VulkanProcTable& vk,
      const VulkanHandle<VkInstance>& instance) const override;

  bool IsValid() const override;

  SkISize GetSize() const override;

 private:
  ANativeWindow* native_window_;

  FXL_DISALLOW_COPY_AND_ASSIGN(VulkanNativeSurfaceAndroid);
};

}  // namespace vulkan

#endif  // FLUTTER_VULKAN_VULKAN_NATIVE_SURFACE_ANDROID_H_
