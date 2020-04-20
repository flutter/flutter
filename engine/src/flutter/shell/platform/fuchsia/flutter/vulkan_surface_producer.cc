// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vulkan_surface_producer.h"

#include <lib/async/cpp/task.h>
#include <lib/async/default.h>

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/gpu/GrBackendSemaphore.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/include/gpu/vk/GrVkBackendContext.h"
#include "third_party/skia/include/gpu/vk/GrVkTypes.h"

namespace flutter_runner {

namespace {

constexpr int kGrCacheMaxCount = 8192;
// Tuning advice:
// If you see the following 3 things happening simultaneously in a trace:
//   * Over budget ("flutter", "GPURasterizer::Draw") durations
//   * Many ("skia", "GrGpu::createTexture") events within the
//     "GPURasterizer::Draw"s
//   * The Skia GPU resource cache is full, as indicated by the
//     "SkiaCacheBytes" field in the ("flutter", "SurfacePool") trace counter
//     (compare it to the bytes value here)
// then you should consider increasing the size of the GPU resource cache.
constexpr size_t kGrCacheMaxByteSize = 1024 * 600 * 12 * 4;

}  // namespace

VulkanSurfaceProducer::VulkanSurfaceProducer(scenic::Session* scenic_session) {
  valid_ = Initialize(scenic_session);

  if (valid_) {
    FML_DLOG(INFO)
        << "Flutter engine: Vulkan surface producer initialization: Successful";
  } else {
    FML_LOG(ERROR)
        << "Flutter engine: Vulkan surface producer initialization: Failed";
  }
}

VulkanSurfaceProducer::~VulkanSurfaceProducer() {
  // Make sure queue is idle before we start destroying surfaces
  if (valid_) {
    VkResult wait_result = VK_CALL_LOG_ERROR(
        vk_->QueueWaitIdle(logical_device_->GetQueueHandle()));
    FML_DCHECK(wait_result == VK_SUCCESS);
  }
};

bool VulkanSurfaceProducer::Initialize(scenic::Session* scenic_session) {
  vk_ = fml::MakeRefCounted<vulkan::VulkanProcTable>();

  std::vector<std::string> extensions = {
      VK_KHR_EXTERNAL_SEMAPHORE_CAPABILITIES_EXTENSION_NAME,
  };
  application_ = std::make_unique<vulkan::VulkanApplication>(
      *vk_, "FlutterRunner", std::move(extensions), VK_MAKE_VERSION(1, 0, 0),
      VK_MAKE_VERSION(1, 1, 0));

  if (!application_->IsValid() || !vk_->AreInstanceProcsSetup()) {
    // Make certain the application instance was created and it setup the
    // instance proc table entries.
    FML_LOG(ERROR) << "Instance proc addresses have not been setup.";
    return false;
  }

  // Create the device.

  logical_device_ = application_->AcquireFirstCompatibleLogicalDevice();

  if (logical_device_ == nullptr || !logical_device_->IsValid() ||
      !vk_->AreDeviceProcsSetup()) {
    // Make certain the device was created and it setup the device proc table
    // entries.
    FML_LOG(ERROR) << "Device proc addresses have not been setup.";
    return false;
  }

  if (!vk_->HasAcquiredMandatoryProcAddresses()) {
    FML_LOG(ERROR) << "Failed to acquire mandatory proc addresses.";
    return false;
  }

  if (!vk_->IsValid()) {
    FML_LOG(ERROR) << "VulkanProcTable invalid";
    return false;
  }

  auto getProc = vk_->CreateSkiaGetProc();

  if (getProc == nullptr) {
    FML_LOG(ERROR) << "Failed to create skia getProc.";
    return false;
  }

  uint32_t skia_features = 0;
  if (!logical_device_->GetPhysicalDeviceFeaturesSkia(&skia_features)) {
    FML_LOG(ERROR) << "Failed to get physical device features.";

    return false;
  }

  GrVkBackendContext backend_context;
  backend_context.fInstance = application_->GetInstance();
  backend_context.fPhysicalDevice = logical_device_->GetPhysicalDeviceHandle();
  backend_context.fDevice = logical_device_->GetHandle();
  backend_context.fQueue = logical_device_->GetQueueHandle();
  backend_context.fGraphicsQueueIndex =
      logical_device_->GetGraphicsQueueIndex();
  backend_context.fMinAPIVersion = application_->GetAPIVersion();
  backend_context.fFeatures = skia_features;
  backend_context.fGetProc = std::move(getProc);
  backend_context.fOwnsInstanceAndDevice = false;

  context_ = GrContext::MakeVulkan(backend_context);

  // Use local limits specified in this file above instead of flutter defaults.
  context_->setResourceCacheLimits(kGrCacheMaxCount, kGrCacheMaxByteSize);

  surface_pool_ =
      std::make_unique<VulkanSurfacePool>(*this, context_, scenic_session);

  return true;
}

void VulkanSurfaceProducer::OnSurfacesPresented(
    std::vector<
        std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>>
        surfaces) {
  TRACE_EVENT0("flutter", "VulkanSurfaceProducer::OnSurfacesPresented");

  // Do a single flush for all canvases derived from the context.
  {
    TRACE_EVENT0("flutter", "GrContext::flushAndSignalSemaphores");
    context_->flush();
  }

  if (!TransitionSurfacesToExternal(surfaces))
    FML_LOG(ERROR) << "TransitionSurfacesToExternal failed";

  // Submit surface
  for (auto& surface : surfaces) {
    SubmitSurface(std::move(surface));
  }

  // Buffer management.
  surface_pool_->AgeAndCollectOldBuffers();

  // If no further surface production has taken place for 10 frames (TODO:
  // Don't hardcode refresh rate here), then shrink our surface pool to fit.
  constexpr auto kShouldShrinkThreshold = zx::msec(10 * 16.67);
  async::PostDelayedTask(
      async_get_default_dispatcher(),
      [self = weak_factory_.GetWeakPtr(), kShouldShrinkThreshold] {
        if (!self) {
          return;
        }
        auto time_since_last_produce =
            async::Now(async_get_default_dispatcher()) -
            self->last_produce_time_;
        if (time_since_last_produce >= kShouldShrinkThreshold) {
          self->surface_pool_->ShrinkToFit();
        }
      },
      kShouldShrinkThreshold);
}

bool VulkanSurfaceProducer::TransitionSurfacesToExternal(
    const std::vector<
        std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>>&
        surfaces) {
  for (auto& surface : surfaces) {
    auto vk_surface = static_cast<VulkanSurface*>(surface.get());

    vulkan::VulkanCommandBuffer* command_buffer =
        vk_surface->GetCommandBuffer(logical_device_->GetCommandPool());
    if (!command_buffer->Begin())
      return false;

    GrBackendRenderTarget backendRT =
        vk_surface->GetSkiaSurface()->getBackendRenderTarget(
            SkSurface::kFlushRead_BackendHandleAccess);
    if (!backendRT.isValid()) {
      return false;
    }
    GrVkImageInfo imageInfo;
    if (!backendRT.getVkImageInfo(&imageInfo)) {
      return false;
    }

    VkImageMemoryBarrier image_barrier = {
        .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .pNext = nullptr,
        .srcAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
        .dstAccessMask = 0,
        .oldLayout = imageInfo.fImageLayout,
        .newLayout = VK_IMAGE_LAYOUT_GENERAL,
        .srcQueueFamilyIndex = 0,
        .dstQueueFamilyIndex = VK_QUEUE_FAMILY_EXTERNAL_KHR,
        .image = vk_surface->GetVkImage(),
        .subresourceRange = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1}};

    if (!command_buffer->InsertPipelineBarrier(
            VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
            VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT,
            0,           // dependencyFlags
            0, nullptr,  // memory barriers
            0, nullptr,  // buffer barriers
            1, &image_barrier))
      return false;

    backendRT.setVkImageLayout(image_barrier.newLayout);

    if (!command_buffer->End())
      return false;

    if (!logical_device_->QueueSubmit(
            {}, {}, {vk_surface->GetAcquireVkSemaphore()},
            {command_buffer->Handle()}, vk_surface->GetCommandBufferFence()))
      return false;
  }
  return true;
}

std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>
VulkanSurfaceProducer::ProduceSurface(
    const SkISize& size,
    const flutter::LayerRasterCacheKey& layer_key,
    std::unique_ptr<scenic::EntityNode> entity_node) {
  FML_DCHECK(valid_);
  last_produce_time_ = async::Now(async_get_default_dispatcher());
  auto surface = surface_pool_->AcquireSurface(size);
  surface->SetRetainedInfo(layer_key, std::move(entity_node));
  return surface;
}

void VulkanSurfaceProducer::SubmitSurface(
    std::unique_ptr<flutter::SceneUpdateContext::SurfaceProducerSurface>
        surface) {
  FML_DCHECK(valid_ && surface != nullptr);
  surface_pool_->SubmitSurface(std::move(surface));
}

}  // namespace flutter_runner
