// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_vulkan.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/shell/gpu/gpu_surface_vulkan.h"
#include "flutter/vulkan/vulkan_native_surface_android.h"

namespace shell {

AndroidSurfaceVulkan::AndroidSurfaceVulkan()
    : proc_table_(fml::MakeRefCounted<vulkan::VulkanProcTable>()) {}

AndroidSurfaceVulkan::~AndroidSurfaceVulkan() = default;

bool AndroidSurfaceVulkan::IsValid() const {
  return proc_table_->HasAcquiredMandatoryProcAddresses();
}

// |shell::AndroidSurface|
void AndroidSurfaceVulkan::TeardownOnScreenContext() {
  // Nothing to do.
}

// |shell::AndroidSurface|
std::unique_ptr<Surface> AndroidSurfaceVulkan::CreateGPUSurface() {
  if (!IsValid()) {
    return nullptr;
  }

  if (!native_window_ || !native_window_->IsValid()) {
    return nullptr;
  }

  auto vulkan_surface_android =
      std::make_unique<vulkan::VulkanNativeSurfaceAndroid>(
          native_window_->handle());

  if (!vulkan_surface_android->IsValid()) {
    return nullptr;
  }

  auto gpu_surface = std::make_unique<GPUSurfaceVulkan>(
      proc_table_, std::move(vulkan_surface_android));

  if (!gpu_surface->IsValid()) {
    return nullptr;
  }

  return gpu_surface;
}

// |shell::AndroidSurface|
bool AndroidSurfaceVulkan::OnScreenSurfaceResize(const SkISize& size) const {
  return true;
}

// |shell::AndroidSurface|
bool AndroidSurfaceVulkan::ResourceContextMakeCurrent() {
  FML_DLOG(ERROR) << "The vulkan backend does not support resource contexts.";
  return false;
}

// |shell::AndroidSurface|
bool AndroidSurfaceVulkan::ResourceContextClearCurrent() {
  FML_DLOG(ERROR) << "The vulkan backend does not support resource contexts.";
  return false;
}

// |shell::AndroidSurface|
bool AndroidSurfaceVulkan::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> window) {
  native_window_ = std::move(window);
  return native_window_ && native_window_->IsValid();
}

}  // namespace shell
