// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_vulkan.h"

#include <memory>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/shell/gpu/gpu_surface_vulkan.h"
#include "flutter/vulkan/vulkan_native_surface_android.h"
#include "include/core/SkRefCnt.h"

namespace flutter {

AndroidSurfaceVulkan::AndroidSurfaceVulkan(
    const std::shared_ptr<AndroidContext>& android_context,
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade)
    : AndroidSurface(android_context),
      proc_table_(fml::MakeRefCounted<vulkan::VulkanProcTable>()) {}

AndroidSurfaceVulkan::~AndroidSurfaceVulkan() = default;

bool AndroidSurfaceVulkan::IsValid() const {
  return proc_table_->HasAcquiredMandatoryProcAddresses();
}

void AndroidSurfaceVulkan::TeardownOnScreenContext() {
  // Nothing to do.
}

std::unique_ptr<Surface> AndroidSurfaceVulkan::CreateGPUSurface(
    GrDirectContext* gr_context) {
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

  sk_sp<GrDirectContext> provided_gr_context;
  if (gr_context) {
    provided_gr_context = sk_ref_sp(gr_context);
  } else if (android_context_->GetMainSkiaContext()) {
    provided_gr_context = android_context_->GetMainSkiaContext();
  }

  std::unique_ptr<GPUSurfaceVulkan> gpu_surface;
  if (provided_gr_context) {
    gpu_surface = std::make_unique<GPUSurfaceVulkan>(
        provided_gr_context, this, std::move(vulkan_surface_android), true);
  } else {
    gpu_surface = std::make_unique<GPUSurfaceVulkan>(
        this, std::move(vulkan_surface_android), true);
    android_context_->SetMainSkiaContext(sk_ref_sp(gpu_surface->GetContext()));
  }

  if (!gpu_surface->IsValid()) {
    return nullptr;
  }

  return gpu_surface;
}

bool AndroidSurfaceVulkan::OnScreenSurfaceResize(const SkISize& size) {
  return true;
}

bool AndroidSurfaceVulkan::ResourceContextMakeCurrent() {
  FML_DLOG(ERROR) << "The vulkan backend does not support resource contexts.";
  return false;
}

bool AndroidSurfaceVulkan::ResourceContextClearCurrent() {
  FML_DLOG(ERROR) << "The vulkan backend does not support resource contexts.";
  return false;
}

bool AndroidSurfaceVulkan::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> window) {
  native_window_ = std::move(window);
  return native_window_ && native_window_->IsValid();
}

fml::RefPtr<vulkan::VulkanProcTable> AndroidSurfaceVulkan::vk() {
  return proc_table_;
}

}  // namespace flutter
