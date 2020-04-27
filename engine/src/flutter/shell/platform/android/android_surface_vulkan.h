// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_VULKAN_H_

#include <jni.h>
#include <memory>
#include "flutter/fml/macros.h"
#include "flutter/shell/gpu/gpu_surface_vulkan_delegate.h"
#include "flutter/shell/platform/android/android_native_window.h"
#include "flutter/shell/platform/android/android_surface.h"
#include "flutter/shell/platform/android/external_view_embedder/external_view_embedder.h"
#include "flutter/vulkan/vulkan_window.h"

namespace flutter {

class AndroidSurfaceVulkan : public AndroidSurface,
                             public GPUSurfaceVulkanDelegate {
 public:
  AndroidSurfaceVulkan();

  ~AndroidSurfaceVulkan() override;

  // |AndroidSurface|
  bool IsValid() const override;

  // |AndroidSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  // |AndroidSurface|
  void TeardownOnScreenContext() override;

  // |AndroidSurface|
  bool OnScreenSurfaceResize(const SkISize& size) const override;

  // |AndroidSurface|
  bool ResourceContextMakeCurrent() override;

  // |AndroidSurface|
  bool ResourceContextClearCurrent() override;

  // |AndroidSurface|
  bool SetNativeWindow(fml::RefPtr<AndroidNativeWindow> window) override;

  // |GPUSurfaceVulkanDelegate|
  ExternalViewEmbedder* GetExternalViewEmbedder() override;

  // |GPUSurfaceVulkanDelegate|
  fml::RefPtr<vulkan::VulkanProcTable> vk() override;

 private:
  fml::RefPtr<vulkan::VulkanProcTable> proc_table_;
  fml::RefPtr<AndroidNativeWindow> native_window_;
  std::unique_ptr<AndroidExternalViewEmbedder> external_view_embedder_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceVulkan);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_VULKAN_H_
