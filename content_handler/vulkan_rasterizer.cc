// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/vulkan_rasterizer.h"

#include <utility>

#include <unistd.h>
#include <chrono>
#include <thread>

#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/include/gpu/vk/GrVkTypes.h"
#include "third_party/skia/src/gpu/vk/GrVkUtil.h"

namespace flutter_runner {

VulkanRasterizer::VulkanSurfaceProducer::VulkanSurfaceProducer() {
  valid_ = Initialize();
  if (!valid_)
    FTL_LOG(ERROR) << "VulkanSurfaceProducer failed to initialize";
}

std::unique_ptr<VulkanRasterizer::VulkanSurfaceProducer::Surface>
VulkanRasterizer::VulkanSurfaceProducer::CreateSurface(uint32_t width,
                                                       uint32_t height) {
  VkResult vk_result;

  VkImageCreateInfo image_create_info = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
      .pNext = nullptr,
      .flags = VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT,
      .imageType = VK_IMAGE_TYPE_2D,
      .format = VK_FORMAT_B8G8R8A8_UNORM,
      .extent = VkExtent3D{width, height, 1},
      .mipLevels = 1,
      .arrayLayers = 1,
      .samples = VK_SAMPLE_COUNT_1_BIT,
      .tiling = VK_IMAGE_TILING_OPTIMAL,
      .usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
      .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .queueFamilyIndexCount = 0,
      .pQueueFamilyIndices = nullptr,
      .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
  };

  VkImage vk_image;
  vk_result = VK_CALL_LOG_ERROR(vkCreateImage(
      backend_context_->fDevice, &image_create_info, nullptr, &vk_image));
  if (vk_result)
    return nullptr;

  VkMemoryRequirements memory_reqs;
  vkGetImageMemoryRequirements(backend_context_->fDevice, vk_image,
                               &memory_reqs);

  uint32_t memory_type = 0;
  for (; memory_type < 32; memory_type++) {
    if ((memory_reqs.memoryTypeBits & (1 << memory_type)))
      break;
  }

  VkMemoryAllocateInfo alloc_info = {
      .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
      .pNext = nullptr,
      .allocationSize = memory_reqs.size,
      .memoryTypeIndex = memory_type,
  };

  VkDeviceMemory vk_memory;
  vk_result = VK_CALL_LOG_ERROR(vkAllocateMemory(
      backend_context_->fDevice, &alloc_info, NULL, &vk_memory));
  if (vk_result)
    return nullptr;

  vk_result = VK_CALL_LOG_ERROR(
      vkBindImageMemory(backend_context_->fDevice, vk_image, vk_memory, 0));
  if (vk_result)
    return nullptr;

  const GrVkImageInfo image_info = {
      .fImage = vk_image,
      .fAlloc = {vk_memory, 0, memory_reqs.size, 0},
      .fImageTiling = image_create_info.tiling,
      .fImageLayout = image_create_info.initialLayout,
      .fFormat = image_create_info.format,
      .fLevelCount = image_create_info.mipLevels,
  };

  GrBackendRenderTargetDesc desc;
  desc.fWidth = width;
  desc.fHeight = height;
  desc.fConfig = kSBGRA_8888_GrPixelConfig;
  desc.fOrigin = kTopLeft_GrSurfaceOrigin;
  desc.fSampleCnt = 0;
  desc.fStencilBits = 0;

  desc.fRenderTargetHandle = reinterpret_cast<GrBackendObject>(&image_info);

  SkSurfaceProps props(SkSurfaceProps::InitType::kLegacyFontHost_InitType);

  auto sk_surface = SkSurface::MakeFromBackendRenderTarget(
      context_.get(), desc, SkColorSpace::MakeSRGB(), &props);
  if (!sk_surface) {
    FTL_LOG(ERROR) << "MakeFromBackendRenderTarget Failed";
    return nullptr;
  }

  uint32_t vmo_handle;
  vk_result = VK_CALL_LOG_ERROR(vkExportDeviceMemoryMAGMA(
      backend_context_->fDevice, vk_memory, &vmo_handle));
  if (vk_result)
    return nullptr;

  mx::vmo vmo(vmo_handle);

  size_t vmo_size;
  vmo.get_size(&vmo_size);

  FTL_DCHECK(vmo_size >= memory_reqs.size);

  mx::eventpair retention_events[2];
  auto mx_status =
      mx::eventpair::create(0, &retention_events[0], &retention_events[1]);
  if (mx_status) {
    FTL_LOG(ERROR) << "Failed to create retention eventpair";
    return nullptr;
  }

  if (!sk_surface || sk_surface->getCanvas() == nullptr) {
    FTL_LOG(ERROR) << "surface invalid";
    return nullptr;
  }

  return std::make_unique<Surface>(backend_context_, sk_surface, std::move(vmo),
                                   std::move(retention_events[0]),
                                   std::move(retention_events[1]), vk_image,
                                   vk_memory);
}

sk_sp<SkSurface> VulkanRasterizer::VulkanSurfaceProducer::ProduceSurface(
    SkISize size,
    mozart::ImagePtr* out_image) {
  if (size.isEmpty()) {
    FTL_LOG(ERROR) << "Attempting to create surface with empty size";
    return nullptr;
  }

  // these casts are safe because of the early out on frame_size.isEmpty()
  auto width = static_cast<uint32_t>(size.width());
  auto height = static_cast<uint32_t>(size.height());

  std::unique_ptr<Surface> surface;
  // try and find a Swapchain with surfaces of the right size
  auto it = available_surfaces_.find(MakeSizeKey(width, height));
  if (it == available_surfaces_.end()) {
    // No matching Swapchain exists, create a new surfaces
    surface = CreateSurface(width, height);
  } else {
    auto& swapchain = it->second;
    if (swapchain.queue.size() == 0) {
      // matching Swapchain exists, but does not have any buffers available in
      // it
      surface = CreateSurface(width, height);
    } else {
      surface = std::move(swapchain.queue.front());
      swapchain.queue.pop();
      swapchain.tick_count = 0;

      // Need to do some skia foo here to clear all the canvas state from the
      // last frame
      surface->sk_surface->getCanvas()->restoreToCount(0);
      surface->sk_surface->getCanvas()->save();
      surface->sk_surface->getCanvas()->resetMatrix();
    }
  }

  if (!surface) {
    FTL_LOG(ERROR) << "Failed to produce surface";
    return nullptr;
  }

  mx_status_t status;
  auto buffer = mozart::Buffer::New();
  status = surface->vmo.duplicate(MX_RIGHT_SAME_RIGHTS, &buffer->vmo);
  if (status) {
    FTL_LOG(ERROR) << "failed to duplicate vmo";
    return nullptr;
  }

  buffer->memory_type = mozart::Buffer::MemoryType::VK_DEVICE_MEMORY;

  mx::eventpair fence_event;
  status = mx::eventpair::create(0, &fence_event, &buffer->fence);
  if (status) {
    FTL_LOG(ERROR) << "failed to create fence eventpair";
    return nullptr;
  }

  mtl::MessageLoop::HandlerKey handler_key =
      mtl::MessageLoop::GetCurrent()->AddHandler(this, fence_event.get(),
                                                 MX_EPAIR_PEER_CLOSED);

  status = surface->remote_retention_event.duplicate(MX_RIGHT_SAME_RIGHTS,
                                                     &buffer->retention);
  if (status) {
    FTL_LOG(ERROR) << "failed to duplicate retention eventpair";
    return nullptr;
  }

  auto image = mozart::Image::New();
  image->size = mozart::Size::New();
  image->size->width = width;
  image->size->height = height;
  image->stride = 4 * width;
  image->pixel_format = mozart::Image::PixelFormat::B8G8R8A8;
  image->alpha_format = mozart::Image::AlphaFormat::OPAQUE;
  image->color_space = mozart::Image::ColorSpace::SRGB;
  image->buffer = std::move(buffer);
  *out_image = std::move(image);

  auto sk_surface = surface->sk_surface;
  PendingSurfaceInfo info;
  info.handler_key = handler_key;
  info.surface = std::move(surface);
  info.production_fence = std::move(fence_event);
  outstanding_surfaces_.push_back(std::move(info));

  return sk_surface;
}

bool VulkanRasterizer::VulkanSurfaceProducer::FinishFrame() {
  mx_status_t status;

  // Finish Rendering
  context_->flush();
  VkResult result =
      VK_CALL_LOG_ERROR(vkQueueWaitIdle(backend_context_->fQueue));
  if (result)
    return false;

  for (auto& info : outstanding_surfaces_) {
    // info.surface->sk_surface->prepareForExternalIO();
    // Signal the compositor
    status = info.production_fence.signal_peer(0u, MX_EPAIR_SIGNALED);
    if (status) {
      FTL_LOG(ERROR) << "failed to signal fence event";
      return false;
    }

    pending_surfaces_.insert(
        std::make_pair(info.production_fence.get(), std::move(info)));
  }
  outstanding_surfaces_.clear();
  return true;
}

void VulkanRasterizer::VulkanSurfaceProducer::Tick() {
  for (auto it = available_surfaces_.begin();
       it != available_surfaces_.end();) {
    auto& swapchain = it->second;
    swapchain.tick_count++;
    if (swapchain.tick_count > Swapchain::kMaxTickBeforeDiscard)
      it = available_surfaces_.erase(it);
    else
      it++;
  }
}

void VulkanRasterizer::VulkanSurfaceProducer::OnHandleReady(
    mx_handle_t handle,
    mx_signals_t pending) {
  FTL_DCHECK(pending & MX_EPAIR_PEER_CLOSED);

  auto it = pending_surfaces_.find(handle);
  FTL_DCHECK(it != pending_surfaces_.end());

  // Add the newly available buffer to the swapchain.
  PendingSurfaceInfo& info = it->second;
  mtl::MessageLoop::GetCurrent()->RemoveHandler(info.handler_key);

  // try and find a Swapchain with surfaces of the right size
  size_key_t key = MakeSizeKey(info.surface->sk_surface->width(),
                               info.surface->sk_surface->height());
  auto swapchain_it = available_surfaces_.find(key);
  if (swapchain_it == available_surfaces_.end()) {
    // No matching Swapchain exists, create one
    Swapchain swapchain;
    if (swapchain.queue.size() + 1 <= Swapchain::kMaxSurfaces) {
      swapchain.queue.push(std::move(info.surface));
    }
    available_surfaces_.insert(std::make_pair(key, std::move(swapchain)));
  } else {
    auto& swapchain = swapchain_it->second;
    if (swapchain.queue.size() + 1 <= Swapchain::kMaxSurfaces) {
      swapchain.queue.push(std::move(info.surface));
    }
  }

  pending_surfaces_.erase(it);
}

bool VulkanRasterizer::VulkanSurfaceProducer::Initialize() {
  auto vk = ftl::MakeRefCounted<vulkan::VulkanProcTable>();

  std::vector<std::string> extensions = {VK_KHR_SURFACE_EXTENSION_NAME};
  application_ = std::make_unique<vulkan::VulkanApplication>(
      *vk, "Flutter", std::move(extensions));

  if (!application_->IsValid() || !vk->AreInstanceProcsSetup()) {
    // Make certain the application instance was created and it setup the
    // instance proc table entries.
    FTL_LOG(ERROR) << "Instance proc addresses have not been setup.";
    return false;
  }

  // Create the device.

  logical_device_ = application_->AcquireFirstCompatibleLogicalDevice();

  if (logical_device_ == nullptr || !logical_device_->IsValid() ||
      !vk->AreDeviceProcsSetup()) {
    // Make certain the device was created and it setup the device proc table
    // entries.
    FTL_LOG(ERROR) << "Device proc addresses have not been setup.";
    return false;
  }

  if (!vk->HasAcquiredMandatoryProcAddresses()) {
    FTL_LOG(ERROR) << "Failed to acquire mandatory proc addresses";
    return false;
  }

  if (!vk->IsValid()) {
    FTL_LOG(ERROR) << "VulkanProcTable invalid";
    return false;
  }

  auto interface = vk->CreateSkiaInterface();

  if (interface == nullptr || !interface->validate(0)) {
    FTL_LOG(ERROR) << "interface invalid";
    return false;
  }

  uint32_t skia_features = 0;
  if (!logical_device_->GetPhysicalDeviceFeaturesSkia(&skia_features)) {
    FTL_LOG(ERROR) << "Failed to get physical device features";

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

  context_.reset(GrContext::Create(
      kVulkan_GrBackend,
      reinterpret_cast<GrBackendContext>(backend_context_.get())));

  FTL_DLOG(INFO) << "Successfully initialized VulkanRasterizer";
  return true;
}

VulkanRasterizer::VulkanRasterizer() : compositor_context_(nullptr) {
  // todo(SY-88) We need to not create this surface producer until
  // the graphics driver finishes coming up. Not sure where thats going to
  // happen eventually but for now we paper over the race by sleeping for 10 ms
  std::this_thread::sleep_for(std::chrono::milliseconds(10));
  surface_producer_.reset(new VulkanSurfaceProducer());
}

VulkanRasterizer::~VulkanRasterizer() = default;

bool VulkanRasterizer::IsValid() const {
  return surface_producer_ && surface_producer_->IsValid();
}

void VulkanRasterizer::SetScene(fidl::InterfaceHandle<mozart::Scene> scene) {
  scene_.Bind(std::move(scene));
}

void VulkanRasterizer::Draw(std::unique_ptr<flow::LayerTree> layer_tree,
                            ftl::Closure callback) {
  Draw(std::move(layer_tree));
  callback();
}

bool VulkanRasterizer::Draw(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (layer_tree == nullptr) {
    FTL_LOG(ERROR) << "Layer tree was not valid.";
    return false;
  }

  if (!scene_) {
    FTL_LOG(ERROR) << "Scene was not valid.";
    return false;
  }

  const SkISize& frame_size = layer_tree->frame_size();

  auto update = mozart::SceneUpdate::New();
  // TODO(abarth): Support incremental updates.
  update->clear_resources = true;
  update->clear_nodes = true;

  if (frame_size.isEmpty()) {
    update->nodes.insert(mozart::kSceneRootNodeId, mozart::Node::New());
    // Publish the updated scene contents.
    // TODO(jeffbrown): We should set the metadata's presentation_time here too.
    scene_->Update(std::move(update));
    auto metadata = mozart::SceneMetadata::New();
    metadata->version = layer_tree->scene_version();
    scene_->Publish(std::move(metadata));
    FTL_LOG(ERROR) << "Publishing empty node";

    return false;
  }

  flow::CompositorContext::ScopedFrame frame =
      compositor_context_.AcquireFrame(nullptr, nullptr);

  layer_tree->Preroll(frame);

  flow::SceneUpdateContext context(update.get(), surface_producer_.get());
  auto root_node = mozart::Node::New();
  root_node->hit_test_behavior = mozart::HitTestBehavior::New();
  layer_tree->UpdateScene(context, root_node.get());
  update->nodes.insert(mozart::kSceneRootNodeId, std::move(root_node));

  // Publish the updated scene contents.
  // TODO(jeffbrown): We should set the metadata's presentation_time here too.
  scene_->Update(std::move(update));
  auto metadata = mozart::SceneMetadata::New();
  metadata->version = layer_tree->scene_version();
  scene_->Publish(std::move(metadata));

  // Draw the contents of the scene to a surface.
  // We do this after publishing to take advantage of pipelining.
  context.ExecutePaintTasks(frame);
  if (!surface_producer_->FinishFrame()) {
    FTL_LOG(ERROR) << "Failed to Finish Frame";
    return false;
  }
  surface_producer_->Tick();

  return true;
}

}  // namespace flutter_runner
