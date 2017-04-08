// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/vulkan_rasterizer.h"

#include <utility>

#include <unistd.h>
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/include/gpu/vk/GrVkTypes.h"
#include "third_party/skia/src/gpu/vk/GrVkUtil.h"

namespace flutter_runner {

VulkanRasterizer::VulkanSurfaceProducer::VulkanSurfaceProducer() {
  valid_ = Initialize();
  if (!valid_)
    FTL_DLOG(INFO) << "VulkanSurfaceProducer failed to initialize";
}

sk_sp<SkSurface> VulkanRasterizer::VulkanSurfaceProducer::ProduceSurface(
    SkISize size,
    mozart::ImagePtr* out_image) {
  if (size.isEmpty()) {
    FTL_DLOG(INFO) << "Attempting to create surface with empty size";
    return nullptr;
  }

  // these casts are safe because of the early out on frame_size.isEmpty()
  auto width = static_cast<uint32_t>(size.width());
  auto height = static_cast<uint32_t>(size.height());

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
    FTL_DLOG(INFO) << "MakeFromBackendRenderTarget Failed";
    return nullptr;
  }

  uint32_t vmo_handle;
  vk_result = VK_CALL_LOG_ERROR(vkExportDeviceMemoryMAGMA(
      backend_context_->fDevice, vk_memory, &vmo_handle));
  if (vk_result)
    return nullptr;

  mx::eventpair retention_events[2];
  auto mx_status =
      mx::eventpair::create(0, &retention_events[0], &retention_events[1]);
  if (mx_status) {
    FTL_DLOG(INFO) << "Failed to create retention eventpair";
    return nullptr;
  }

  if (!sk_surface || sk_surface->getCanvas() == nullptr) {
    FTL_DLOG(INFO) << "surface invalid";
    return nullptr;
  }

  surfaces_.emplace_back(
      sk_surface,                      // sk_sp<SkSurface> sk_surface
      mx::vmo(vmo_handle),             // mx::vmo vmo
      std::move(retention_events[0]),  // mx::eventpair local_retention_event;
      std::move(retention_events[1]),  // mx::eventpair remote_retention_event;
      mx::eventpair(),                 // mx::eventpair fence_event
      vk_image, vk_memory);

  auto surface = &surfaces_.back();

  size_t vmo_size;
  surface->vmo.get_size(&vmo_size);

  if (vmo_size < memory_reqs.size) {
    FTL_DLOG(INFO) << "Failed to allocate sufficiently large vmo";
    return nullptr;
  }

  mx_status_t status;
  auto buffer = mozart::Buffer::New();
  status = surface->vmo.duplicate(MX_RIGHT_SAME_RIGHTS, &buffer->vmo);
  if (status) {
    FTL_DLOG(INFO) << "failed to duplicate vmo";
    return nullptr;
  }

  buffer->memory_type = mozart::Buffer::MemoryType::VK_DEVICE_MEMORY;

  status = mx::eventpair::create(0, &surface->fence_event, &buffer->fence);
  if (status) {
    FTL_DLOG(INFO) << "failed to create fence eventpair";
    return nullptr;
  }

  status = surface->remote_retention_event.duplicate(MX_RIGHT_SAME_RIGHTS,
                                                     &buffer->retention);
  if (status) {
    FTL_DLOG(INFO) << "failed to duplicate retention eventpair";
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

  return sk_surface;
}

bool VulkanRasterizer::VulkanSurfaceProducer::Tick() {
  mx_status_t status;

  for (auto& surface : surfaces_) {
    GrVkImageInfo* image_info = nullptr;
    if (!surface.sk_surface->getRenderTargetHandle(
            reinterpret_cast<GrBackendObject*>(&image_info),
            SkSurface::kFlushRead_BackendHandleAccess)) {
      FTL_DLOG(INFO) << "Could not get render target handle.";
      return false;
    }
    (void)image_info;

    status = surface.fence_event.signal_peer(0u, MX_EPAIR_SIGNALED);
    if (status) {
      FTL_DLOG(INFO) << "failed to signal fence event";
      return false;
    }

    vkFreeMemory(backend_context_->fDevice, surface.vk_memory, NULL);

    vkDestroyImage(backend_context_->fDevice, surface.vk_image, NULL);
  }

  surfaces_.clear();
  return true;
}

bool VulkanRasterizer::VulkanSurfaceProducer::Initialize() {
  auto vk = ftl::MakeRefCounted<vulkan::VulkanProcTable>();

  std::vector<std::string> extensions = {VK_KHR_SURFACE_EXTENSION_NAME};
  application_ = std::make_unique<vulkan::VulkanApplication>(
      *vk, "Flutter", std::move(extensions));

  if (!application_->IsValid() || !vk->AreInstanceProcsSetup()) {
    // Make certain the application instance was created and it setup the
    // instance proc table entries.
    FTL_DLOG(INFO) << "Instance proc addresses have not been setup.";
    return false;
  }

  // Create the device.

  logical_device_ = application_->AcquireFirstCompatibleLogicalDevice();

  if (logical_device_ == nullptr || !logical_device_->IsValid() ||
      !vk->AreDeviceProcsSetup()) {
    // Make certain the device was created and it setup the device proc table
    // entries.
    FTL_DLOG(INFO) << "Device proc addresses have not been setup.";
    return false;
  }

  if (!vk->HasAcquiredMandatoryProcAddresses()) {
    FTL_DLOG(INFO) << "Failed to acquire mandatory proc addresses";
    return false;
  }

  if (!vk->IsValid()) {
    FTL_DLOG(INFO) << "VulkanProcTable invalid";
    return false;
  }

  auto interface = vk->CreateSkiaInterface();

  if (interface == nullptr || !interface->validate(0)) {
    FTL_DLOG(INFO) << "interface invalid";
    return false;
  }

  uint32_t skia_features = 0;
  if (!logical_device_->GetPhysicalDeviceFeaturesSkia(&skia_features)) {
    FTL_DLOG(INFO) << "Failed to get physical device features";

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

  return true;
}

VulkanRasterizer::VulkanRasterizer() : compositor_context_(nullptr) {}

VulkanRasterizer::~VulkanRasterizer() = default;

bool VulkanRasterizer::IsValid() const {
  return !surface_producer_ || surface_producer_->IsValid();
}

void VulkanRasterizer::SetScene(fidl::InterfaceHandle<mozart::Scene> scene) {
  scene_.Bind(std::move(scene));
  surface_producer_.reset(new VulkanSurfaceProducer());
}

void VulkanRasterizer::Draw(std::unique_ptr<flow::LayerTree> layer_tree,
                            ftl::Closure callback) {
  Draw(std::move(layer_tree));
  callback();
}

bool VulkanRasterizer::Draw(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (layer_tree == nullptr) {
    FTL_DLOG(INFO) << "Layer tree was not valid.";
    return false;
  }

  if (!scene_) {
    FTL_DLOG(INFO) << "Scene was not valid.";
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
    FTL_DLOG(INFO) << "Publishing empty node";

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
  if (!surface_producer_->Tick()) {
    FTL_DLOG(INFO) << "Failed to tick surface producer";
    return false;
  }

  return true;
}

}  // namespace flutter_runner
