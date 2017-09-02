// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/vulkan_surface_producer.h"
#include <memory>
#include <string>
#include <vector>
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/include/gpu/vk/GrVkTypes.h"
#include "third_party/skia/src/gpu/vk/GrVkUtil.h"

namespace flutter_runner {

VulkanSurfaceProducer::VulkanSurfaceProducer(
    scenic_lib::Session* mozart_session) {
  valid_ = Initialize(mozart_session);

  if (valid_) {
    FTL_LOG(INFO)
        << "Flutter engine: Vulkan surface producer initialization: Successful";
  } else {
    FTL_LOG(ERROR)
        << "Flutter engine: Vulkan surface producer initialization: Failed";
  }
}

VulkanSurfaceProducer::~VulkanSurfaceProducer() = default;

bool VulkanSurfaceProducer::Initialize(
    scenic_lib::Session* mozart_session) {
  vk_ = ftl::MakeRefCounted<vulkan::VulkanProcTable>();

  std::vector<std::string> extensions = {VK_KHR_SURFACE_EXTENSION_NAME};
  application_ = std::make_unique<vulkan::VulkanApplication>(
      *vk_, "FlutterContentHandler", std::move(extensions));

  if (!application_->IsValid() || !vk_->AreInstanceProcsSetup()) {
    // Make certain the application instance was created and it setup the
    // instance proc table entries.
    FTL_LOG(ERROR) << "Instance proc addresses have not been setup.";
    return false;
  }

  // Create the device.

  logical_device_ = application_->AcquireFirstCompatibleLogicalDevice();

  if (logical_device_ == nullptr || !logical_device_->IsValid() ||
      !vk_->AreDeviceProcsSetup()) {
    // Make certain the device was created and it setup the device proc table
    // entries.
    FTL_LOG(ERROR) << "Device proc addresses have not been setup.";
    return false;
  }

  if (!vk_->HasAcquiredMandatoryProcAddresses()) {
    FTL_LOG(ERROR) << "Failed to acquire mandatory proc addresses.";
    return false;
  }

  if (!vk_->IsValid()) {
    FTL_LOG(ERROR) << "VulkanProcTable invalid";
    return false;
  }

  auto interface = vk_->CreateSkiaInterface();

  if (interface == nullptr || !interface->validate(0)) {
    FTL_LOG(ERROR) << "Skia interface invalid.";
    return false;
  }

  uint32_t skia_features = 0;
  if (!logical_device_->GetPhysicalDeviceFeaturesSkia(&skia_features)) {
    FTL_LOG(ERROR) << "Failed to get physical device features.";

    return false;
  }

  backend_context_ = sk_make_sp<GrVkBackendContext>();
  backend_context_->fInstance = application_->GetInstance();
  backend_context_->fPhysicalDevice =
      logical_device_->GetPhysicalDeviceHandle();
  backend_context_->fDevice = logical_device_->GetHandle();
  backend_context_->fQueue = logical_device_->GetQueueHandle();
  backend_context_->fGraphicsQueueIndex =
      logical_device_->GetGraphicsQueueIndex();
  backend_context_->fMinAPIVersion = application_->GetAPIVersion();
  backend_context_->fFeatures = skia_features;
  backend_context_->fInterface.reset(interface.release());

  logical_device_->ReleaseDeviceOwnership();
  application_->ReleaseInstanceOwnership();

  context_.reset(GrContext::Create(
      kVulkan_GrBackend,
      reinterpret_cast<GrBackendContext>(backend_context_.get())));

  context_->setResourceCacheLimits(vulkan::kGrCacheMaxCount,
                                   vulkan::kGrCacheMaxByteSize);

  surface_pool_ = std::make_unique<VulkanSurfacePool>(
      *vk_, context_, backend_context_, mozart_session);

  return true;
}

void VulkanSurfaceProducer::OnSurfacesPresented(
    std::vector<
        std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>>
        surfaces) {
  // Do a single flush for all canvases derived from the context.
  context_->flush();

  // Do a CPU wait.
  // TODO(chinmaygarde): Remove this once we have support for Vulkan semaphores.
  VkResult wait_result =
      VK_CALL_LOG_ERROR(vk_->QueueWaitIdle(backend_context_->fQueue));
  FTL_DCHECK(wait_result == VK_SUCCESS);

  // Submit surface, this signals acquire events sent along the session.
  for (auto& surface : surfaces) {
    SubmitSurface(std::move(surface));
  }

  // Buffer management.
  surface_pool_->AgeAndCollectOldBuffers();
}

std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface>
VulkanSurfaceProducer::ProduceSurface(const SkISize& size) {
  FTL_DCHECK(valid_);
  return surface_pool_->AcquireSurface(size);
}

void VulkanSurfaceProducer::SubmitSurface(
    std::unique_ptr<flow::SceneUpdateContext::SurfaceProducerSurface> surface) {
  FTL_DCHECK(valid_ && surface != nullptr);
  surface_pool_->SubmitSurface(std::move(surface));
}

}  // namespace flutter_runner
