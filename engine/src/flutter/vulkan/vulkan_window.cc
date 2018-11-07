// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/vulkan/vulkan_window.h"

#include <memory>
#include <string>

#include "flutter/vulkan/vulkan_application.h"
#include "flutter/vulkan/vulkan_device.h"
#include "flutter/vulkan/vulkan_native_surface.h"
#include "flutter/vulkan/vulkan_surface.h"
#include "flutter/vulkan/vulkan_swapchain.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace vulkan {

VulkanWindow::VulkanWindow(fml::RefPtr<VulkanProcTable> proc_table,
                           std::unique_ptr<VulkanNativeSurface> native_surface)
    : valid_(false), vk(std::move(proc_table)) {
  if (!vk || !vk->HasAcquiredMandatoryProcAddresses()) {
    FML_DLOG(INFO) << "Proc table has not acquired mandatory proc addresses.";
    return;
  }

  if (native_surface == nullptr || !native_surface->IsValid()) {
    FML_DLOG(INFO) << "Native surface is invalid.";
    return;
  }

  // Create the application instance.

  std::vector<std::string> extensions = {
      VK_KHR_SURFACE_EXTENSION_NAME,      // parent extension
      native_surface->GetExtensionName()  // child extension
  };

  application_ = std::make_unique<VulkanApplication>(*vk, "Flutter",
                                                     std::move(extensions));

  if (!application_->IsValid() || !vk->AreInstanceProcsSetup()) {
    // Make certain the application instance was created and it setup the
    // instance proc table entries.
    FML_DLOG(INFO) << "Instance proc addresses have not been setup.";
    return;
  }

  // Create the device.

  logical_device_ = application_->AcquireFirstCompatibleLogicalDevice();

  if (logical_device_ == nullptr || !logical_device_->IsValid() ||
      !vk->AreDeviceProcsSetup()) {
    // Make certain the device was created and it setup the device proc table
    // entries.
    FML_DLOG(INFO) << "Device proc addresses have not been setup.";
    return;
  }

  // Create the logical surface from the native platform surface.

  surface_ = std::make_unique<VulkanSurface>(*vk, *application_,
                                             std::move(native_surface));

  if (!surface_->IsValid()) {
    FML_DLOG(INFO) << "Vulkan surface is invalid.";
    return;
  }

  // Create the Skia GrContext.

  if (!CreateSkiaGrContext()) {
    FML_DLOG(INFO) << "Could not create Skia context.";
    return;
  }

  // Create the swapchain.

  if (!RecreateSwapchain()) {
    FML_DLOG(INFO) << "Could not setup the swapchain initially.";
    return;
  }

  valid_ = true;
}

VulkanWindow::~VulkanWindow() = default;

bool VulkanWindow::IsValid() const {
  return valid_;
}

GrContext* VulkanWindow::GetSkiaGrContext() {
  return skia_gr_context_.get();
}

bool VulkanWindow::CreateSkiaGrContext() {
  GrVkBackendContext backend_context;

  if (!CreateSkiaBackendContext(&backend_context)) {
    return false;
  }

  sk_sp<GrContext> context = GrContext::MakeVulkan(backend_context);

  if (context == nullptr) {
    return false;
  }

  context->setResourceCacheLimits(kGrCacheMaxCount, kGrCacheMaxByteSize);

  skia_gr_context_ = context;

  return true;
}

bool VulkanWindow::CreateSkiaBackendContext(GrVkBackendContext* context) {
  auto getProc = vk->CreateSkiaGetProc();

  if (getProc == nullptr) {
    return false;
  }

  uint32_t skia_features = 0;
  if (!logical_device_->GetPhysicalDeviceFeaturesSkia(&skia_features)) {
    return false;
  }

  context->fInstance = application_->GetInstance();
  context->fPhysicalDevice = logical_device_->GetPhysicalDeviceHandle();
  context->fDevice = logical_device_->GetHandle();
  context->fQueue = logical_device_->GetQueueHandle();
  context->fGraphicsQueueIndex = logical_device_->GetGraphicsQueueIndex();
  context->fMinAPIVersion = application_->GetAPIVersion();
  context->fExtensions = kKHR_surface_GrVkExtensionFlag |
                         kKHR_swapchain_GrVkExtensionFlag |
                         surface_->GetNativeSurface().GetSkiaExtensionName();
  context->fFeatures = skia_features;
  context->fGetProc = std::move(getProc);
  context->fOwnsInstanceAndDevice = false;
  return true;
}

sk_sp<SkSurface> VulkanWindow::AcquireSurface() {
  if (!IsValid()) {
    FML_DLOG(INFO) << "Surface is invalid.";
    return nullptr;
  }

  auto surface_size = surface_->GetSize();

  // This check is theoretically unnecessary as the swapchain should report that
  // the surface is out-of-date and perform swapchain recreation at the new
  // configuration. However, on Android, the swapchain never reports that it is
  // of date. Hence this extra check. Platforms that don't have this issue, or,
  // cant report this information (which is optional anyway), report a zero
  // size.
  if (surface_size != SkISize::Make(0, 0) &&
      surface_size != swapchain_->GetSize()) {
    FML_DLOG(INFO) << "Swapchain and surface sizes are out of sync. Recreating "
                      "swapchain.";
    if (!RecreateSwapchain()) {
      FML_DLOG(INFO) << "Could not recreate swapchain.";
      valid_ = false;
      return nullptr;
    }
  }

  while (true) {
    sk_sp<SkSurface> surface;
    auto acquire_result = VulkanSwapchain::AcquireStatus::ErrorSurfaceLost;

    std::tie(acquire_result, surface) = swapchain_->AcquireSurface();

    if (acquire_result == VulkanSwapchain::AcquireStatus::Success) {
      // Successfully acquired a surface from the swapchain. Nothing more to do.
      return surface;
    }

    if (acquire_result == VulkanSwapchain::AcquireStatus::ErrorSurfaceLost) {
      // Surface is lost. This is an unrecoverable error.
      FML_DLOG(INFO) << "Swapchain reported surface was lost.";
      return nullptr;
    }

    if (acquire_result ==
        VulkanSwapchain::AcquireStatus::ErrorSurfaceOutOfDate) {
      // Surface out of date. Recreate the swapchain at the new configuration.
      if (RecreateSwapchain()) {
        // Swapchain was recreated, try surface acquisition again.
        continue;
      } else {
        // Could not recreate the swapchain at the new configuration.
        FML_DLOG(INFO) << "Swapchain reported surface was out of date but "
                          "could not recreate the swapchain at the new "
                          "configuration.";
        valid_ = false;
        return nullptr;
      }
    }

    break;
  }

  FML_DCHECK(false) << "Unhandled VulkanSwapchain::AcquireResult";
  return nullptr;
}

bool VulkanWindow::SwapBuffers() {
  if (!IsValid()) {
    FML_DLOG(INFO) << "Window was invalid.";
    return false;
  }

  return swapchain_->Submit();
}

bool VulkanWindow::RecreateSwapchain() {
  // This way, we always lose our reference to the old swapchain. Even if we
  // cannot create a new one to replace it.
  auto old_swapchain = std::move(swapchain_);

  if (!vk->IsValid()) {
    return false;
  }

  if (logical_device_ == nullptr || !logical_device_->IsValid()) {
    return false;
  }

  if (surface_ == nullptr || !surface_->IsValid()) {
    return false;
  }

  if (skia_gr_context_ == nullptr) {
    return false;
  }

  auto swapchain = std::make_unique<VulkanSwapchain>(
      *vk, *logical_device_, *surface_, skia_gr_context_.get(),
      std::move(old_swapchain), logical_device_->GetGraphicsQueueIndex());

  if (!swapchain->IsValid()) {
    return false;
  }

  swapchain_ = std::move(swapchain);
  return true;
}

}  // namespace vulkan
