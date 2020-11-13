// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_VULKAN_H_

#include <jni.h>

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/gpu/gpu_surface_vulkan_delegate.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "flutter/vulkan/vulkan_window.h"

namespace flutter {

class AndroidSurfaceVulkan : public AndroidSurface,
                             public GPUSurfaceVulkanDelegate {
 public:
  AndroidSurfaceVulkan(const AndroidContext& android_context,
                       std::shared_ptr<PlatformViewAndroidJNI> jni_facade);

  ~AndroidSurfaceVulkan() override;

  // |AndroidSurface|
  bool IsValid() const override;

  // |AndroidSurface|
  std::unique_ptr<Surface> CreateGPUSurface(
      GrDirectContext* gr_context) override;

  // |AndroidSurface|
  void TeardownOnScreenContext() override;

  // |AndroidSurface|
  bool OnScreenSurfaceResize(const SkISize& size) override;

  // |AndroidSurface|
  bool ResourceContextMakeCurrent() override;

  // |AndroidSurface|
  bool ResourceContextClearCurrent() override;

  // |AndroidSurface|
  bool SetNativeWindow(fml::RefPtr<AndroidNativeWindow> window) override;

  // |GPUSurfaceVulkanDelegate|
  fml::RefPtr<vulkan::VulkanProcTable> vk() override;

 private:
  fml::RefPtr<vulkan::VulkanProcTable> proc_table_;
  fml::RefPtr<AndroidNativeWindow> native_window_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceVulkan);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_VULKAN_H_
