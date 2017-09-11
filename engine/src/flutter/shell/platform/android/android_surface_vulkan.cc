// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_vulkan.h"

#include <utility>

#include "flutter/shell/gpu/gpu_surface_vulkan.h"
#include "flutter/vulkan/vulkan_native_surface_android.h"
#include "lib/fxl/logging.h"

namespace shell {

AndroidSurfaceVulkan::AndroidSurfaceVulkan()
    : proc_table_(fxl::MakeRefCounted<vulkan::VulkanProcTable>()) {}

AndroidSurfaceVulkan::~AndroidSurfaceVulkan() = default;

bool AndroidSurfaceVulkan::IsValid() const {
  return proc_table_->HasAcquiredMandatoryProcAddresses();
}

void AndroidSurfaceVulkan::TeardownOnScreenContext() {
  //
}

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

SkISize AndroidSurfaceVulkan::OnScreenSurfaceSize() const {
  return native_window_ ? native_window_->GetSize() : SkISize::Make(0, 0);
}

bool AndroidSurfaceVulkan::OnScreenSurfaceResize(const SkISize& size) const {
  return true;
}

bool AndroidSurfaceVulkan::ResourceContextMakeCurrent() {
  return false;
}

void AndroidSurfaceVulkan::SetFlutterView(
    const fml::jni::JavaObjectWeakGlobalRef& flutter_view) {}

bool AndroidSurfaceVulkan::SetNativeWindow(
    fxl::RefPtr<AndroidNativeWindow> window,
    PlatformView::SurfaceConfig config) {
  native_window_ = std::move(window);
  return native_window_ && native_window_->IsValid();
}

}  // namespace shell
