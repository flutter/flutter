// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_surface_vulkan_impeller.h"

#include <memory>
#include <utility>

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/impeller/renderer/backend/vulkan/context_vk.h"
#include "flutter/shell/gpu/gpu_surface_vulkan_impeller.h"
#include "flutter/vulkan/vulkan_native_surface_android.h"

namespace flutter {

AndroidSurfaceVulkanImpeller::AndroidSurfaceVulkanImpeller(
    const std::shared_ptr<AndroidContextVulkanImpeller>& android_context)
    : android_context_(android_context) {
  is_valid_ = android_context_->IsValid();
}

AndroidSurfaceVulkanImpeller::~AndroidSurfaceVulkanImpeller() = default;

bool AndroidSurfaceVulkanImpeller::IsValid() const {
  return is_valid_;
}

void AndroidSurfaceVulkanImpeller::TeardownOnScreenContext() {
  // Nothing to do.
}

std::unique_ptr<Surface> AndroidSurfaceVulkanImpeller::CreateGPUSurface(
    GrDirectContext* gr_context) {
  if (!IsValid()) {
    return nullptr;
  }

  if (!native_window_ || !native_window_->IsValid()) {
    return nullptr;
  }

  std::unique_ptr<GPUSurfaceVulkanImpeller> gpu_surface =
      std::make_unique<GPUSurfaceVulkanImpeller>(
          android_context_->GetImpellerContext());

  if (!gpu_surface->IsValid()) {
    return nullptr;
  }

  return gpu_surface;
}

bool AndroidSurfaceVulkanImpeller::OnScreenSurfaceResize(const SkISize& size) {
  return true;
}

bool AndroidSurfaceVulkanImpeller::ResourceContextMakeCurrent() {
  return true;
}

bool AndroidSurfaceVulkanImpeller::ResourceContextClearCurrent() {
  return true;
}

bool AndroidSurfaceVulkanImpeller::SetNativeWindow(
    fml::RefPtr<AndroidNativeWindow> window) {
  native_window_ = std::move(window);
  bool success = native_window_ && native_window_->IsValid();
  if (success) {
    auto& context_vk =
        impeller::ContextVK::Cast(*android_context_->GetImpellerContext());
    auto surface = context_vk.CreateAndroidSurface(native_window_->handle());

    if (!surface) {
      FML_LOG(ERROR) << "Could not create a vulkan surface.";
      return false;
    }

    return context_vk.SetWindowSurface(std::move(surface));
  }

  native_window_ = nullptr;
  return false;
}

std::shared_ptr<impeller::Context>
AndroidSurfaceVulkanImpeller::GetImpellerContext() {
  return android_context_->GetImpellerContext();
}

}  // namespace flutter
