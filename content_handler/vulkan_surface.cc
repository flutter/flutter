// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/vulkan_surface.h"
#include "flutter/common/threads.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/gpu/GrBackendSemaphore.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrContext.h"
#include "third_party/skia/src/gpu/vk/GrVkImage.h"

namespace flutter_runner {

VulkanSurface::VulkanSurface(vulkan::VulkanProcTable& p_vk,
                             sk_sp<GrContext> context,
                             sk_sp<GrVkBackendContext> backend_context,
                             scenic_lib::Session* session,
                             const SkISize& size)
    : vk_(p_vk),
      backend_context_(std::move(backend_context)),
      session_(session) {
  ASSERT_IS_GPU_THREAD;

  FXL_DCHECK(session_);

  mx::vmo exported_vmo;
  if (!AllocateDeviceMemory(std::move(context), size, exported_vmo)) {
    FXL_DLOG(INFO) << "Could not allocate device memory.";
    return;
  }

  if (!CreateFences()) {
    FXL_DLOG(INFO) << "Could not create signal fences.";
    return;
  }

  if (!PushSessionImageSetupOps(session, std::move(exported_vmo))) {
    FXL_DLOG(INFO) << "Could not push session image setup ops.";
    return;
  }

  event_handler_key_ = fsl::MessageLoop::GetCurrent()->AddHandler(
      this, release_event_.get(), MX_EVENT_SIGNALED);

  // Probably not necessary as the events should be in the unsignalled state
  // already.
  Reset();

  valid_ = true;
}

VulkanSurface::~VulkanSurface() {
  ASSERT_IS_GPU_THREAD;
  if (event_handler_key_ != 0) {
    fsl::MessageLoop::GetCurrent()->RemoveHandler(event_handler_key_);
    event_handler_key_ = 0;
  }
}

bool VulkanSurface::IsValid() const {
  return valid_;
}

SkISize VulkanSurface::GetSize() const {
  if (!valid_) {
    return SkISize::Make(0, 0);
  }

  return SkISize::Make(sk_surface_->width(), sk_surface_->height());
}

GrBackendSemaphore VulkanSurface::GetAcquireSemaphore() const {
  GrBackendSemaphore gr_semaphore;
  gr_semaphore.initVulkan(acquire_semaphore_);
  return gr_semaphore;
}

vulkan::VulkanHandle<VkSemaphore>
VulkanSurface::SemaphoreFromEvent(const mx::event &event) const {
  VkResult result;
  VkSemaphore semaphore;

  mx::event semaphore_event;
  mx_status_t status = event.duplicate(MX_RIGHT_SAME_RIGHTS, &semaphore_event);
  if (status != MX_OK) {
    FXL_DLOG(ERROR) << "failed to duplicate semaphore event";
    return vulkan::VulkanHandle<VkSemaphore>();
  }

  VkSemaphoreCreateInfo create_info = {
      .sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
  };

  result = VK_CALL_LOG_ERROR(vk_.CreateSemaphore(
      backend_context_->fDevice, &create_info, nullptr, &semaphore));
  if (result != VK_SUCCESS) {
    return vulkan::VulkanHandle<VkSemaphore>();
  }

  VkImportSemaphoreFdInfoKHR import_info = {
      .sType = VK_STRUCTURE_TYPE_IMPORT_SEMAPHORE_FD_INFO_KHR,
      .pNext = nullptr,
      .semaphore = semaphore,
      .handleType = VK_EXTERNAL_SEMAPHORE_HANDLE_TYPE_SYNC_FD_BIT_KHR,
      .fd = semaphore_event.release()};

  result = VK_CALL_LOG_ERROR(
      vk_.ImportSemaphoreFdKHR(backend_context_->fDevice, &import_info));
  if (result != VK_SUCCESS) {
    return vulkan::VulkanHandle<VkSemaphore>();
  }

  return vulkan::VulkanHandle<VkSemaphore>(
      semaphore, [this](VkSemaphore semaphore) {
        vk_.DestroySemaphore(backend_context_->fDevice, semaphore, nullptr);
      });
}

bool VulkanSurface::CreateFences() {
  if (mx::event::create(0, &acquire_event_) != MX_OK) {
    return false;
  }

  acquire_semaphore_ = SemaphoreFromEvent(acquire_event_);
  if (!acquire_semaphore_) {
    FXL_DLOG(ERROR) << "failed to create acquire semaphore";
    return false;
  }

  if (mx::event::create(0, &release_event_) != MX_OK) {
    return false;
  }

  return true;
}

bool VulkanSurface::AllocateDeviceMemory(sk_sp<GrContext> context,
                                         const SkISize& size,
                                         mx::vmo& exported_vmo) {
  if (size.isEmpty()) {
    return false;
  }

  if (backend_context_ == nullptr) {
    return false;
  }

  // Create the image.
  const VkImageCreateInfo image_create_info = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
      .pNext = nullptr,
      .flags = VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT,
      .imageType = VK_IMAGE_TYPE_2D,
      .format = VK_FORMAT_B8G8R8A8_UNORM,
      .extent = VkExtent3D{static_cast<uint32_t>(size.width()),
                           static_cast<uint32_t>(size.height()), 1},
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

  {
    VkImage vk_image = VK_NULL_HANDLE;

    if (VK_CALL_LOG_ERROR(vk_.CreateImage(backend_context_->fDevice,
                                          &image_create_info, nullptr,
                                          &vk_image)) != VK_SUCCESS) {
      return false;
    }

    vk_image_ = {vk_image, [this](VkImage image) {
                   vk_.DestroyImage(backend_context_->fDevice, image, NULL);
                 }};
  }

  // Create the memory.
  VkMemoryRequirements memory_reqs;
  vk_.GetImageMemoryRequirements(backend_context_->fDevice,  //
                                 vk_image_,                  //
                                 &memory_reqs                //
                                 );

  uint32_t memory_type = 0;
  for (; memory_type < 32; memory_type++) {
    if ((memory_reqs.memoryTypeBits & (1 << memory_type))) {
      break;
    }
  }

  const VkMemoryAllocateInfo alloc_info = {
      .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
      .pNext = nullptr,
      .allocationSize = memory_reqs.size,
      .memoryTypeIndex = memory_type,
  };

  {
    VkDeviceMemory vk_memory = VK_NULL_HANDLE;
    if (VK_CALL_LOG_ERROR(vk_.AllocateMemory(backend_context_->fDevice,
                                             &alloc_info, NULL, &vk_memory)) !=
        VK_SUCCESS) {
      return false;
    }

    vk_memory_ = {vk_memory, [this](VkDeviceMemory memory) {
                    vk_.FreeMemory(backend_context_->fDevice, memory, NULL);
                  }};
  }

  // Bind image memory.
  if (VK_CALL_LOG_ERROR(vk_.BindImageMemory(
          backend_context_->fDevice, vk_image_, vk_memory_, 0)) != VK_SUCCESS) {
    return false;
  }

  {
    // Acquire the VMO for the device memory.
    uint32_t vmo_handle = 0;
    if (VK_CALL_LOG_ERROR(vk_.ExportDeviceMemoryMAGMA(
            backend_context_->fDevice, vk_memory_, &vmo_handle)) !=
        VK_SUCCESS) {
      return false;
    }
    exported_vmo.reset(static_cast<mx_handle_t>(vmo_handle));
  }

  // Assert that the VMO size was sufficient.
  size_t vmo_size = 0;
  if (exported_vmo.get_size(&vmo_size) != MX_OK ||
      vmo_size < memory_reqs.size) {
    return false;
  }

  return SetupSkiaSurface(std::move(context), size, image_create_info,
                          memory_reqs);
}

bool VulkanSurface::SetupSkiaSurface(sk_sp<GrContext> context,
                                     const SkISize& size,
                                     const VkImageCreateInfo& image_create_info,
                                     const VkMemoryRequirements& memory_reqs) {
  if (context == nullptr) {
    return false;
  }

  const GrVkImageInfo image_info = {
      .fImage = vk_image_,
      .fAlloc = {vk_memory_, 0, memory_reqs.size, 0},
      .fImageTiling = image_create_info.tiling,
      .fImageLayout = image_create_info.initialLayout,
      .fFormat = image_create_info.format,
      .fLevelCount = image_create_info.mipLevels,
  };

  GrBackendRenderTarget sk_render_target(size.width(), size.height(), 0, 0, image_info);

  SkSurfaceProps sk_surface_props(
      SkSurfaceProps::InitType::kLegacyFontHost_InitType);

  auto sk_surface =
      SkSurface::MakeFromBackendRenderTarget(context.get(),            //
                                             sk_render_target,         //
                                             kTopLeft_GrSurfaceOrigin, //
                                             nullptr,                  //
                                             &sk_surface_props         //
                                             );

  if (!sk_surface || sk_surface->getCanvas() == nullptr) {
    return false;
  }
  sk_surface_ = std::move(sk_surface);

  return true;
}

bool VulkanSurface::PushSessionImageSetupOps(scenic_lib::Session* session,
                                             mx::vmo exported_vmo) {
  if (sk_surface_ == nullptr) {
    return false;
  }

  scenic_lib::Memory memory(session, std::move(exported_vmo),
                                scenic::MemoryType::VK_DEVICE_MEMORY);

  auto image_info = scenic::ImageInfo::New();
  image_info->width = sk_surface_->width();
  image_info->height = sk_surface_->height();
  image_info->stride = 4 * sk_surface_->width();
  image_info->pixel_format = scenic::ImageInfo::PixelFormat::BGRA_8;
  image_info->color_space = scenic::ImageInfo::ColorSpace::SRGB;
  image_info->tiling = scenic::ImageInfo::Tiling::LINEAR;

  session_image_ = std::make_unique<scenic_lib::Image>(
      memory, 0 /* memory offset */, std::move(image_info));

  return session_image_ != nullptr;
}

scenic_lib::Image* VulkanSurface::GetImage() {
  ASSERT_IS_GPU_THREAD;
  if (!valid_) {
    return 0;
  }
  return session_image_.get();
}

sk_sp<SkSurface> VulkanSurface::GetSkiaSurface() const {
  ASSERT_IS_GPU_THREAD;
  return valid_ ? sk_surface_ : nullptr;
}

size_t VulkanSurface::AdvanceAndGetAge() {
  age_++;
  return age_;
}

bool VulkanSurface::FlushSessionAcquireAndReleaseEvents() {
  mx::event acquire, release;

  if (acquire_event_.duplicate(MX_RIGHT_SAME_RIGHTS, &acquire) != MX_OK ||
      release_event_.duplicate(MX_RIGHT_SAME_RIGHTS, &release) != MX_OK) {
    return false;
  }

  session_->EnqueueAcquireFence(std::move(acquire));
  session_->EnqueueReleaseFence(std::move(release));
  age_ = 0;
  return true;
}

void VulkanSurface::SignalWritesFinished(
    std::function<void(void)> on_writes_committed) {
  ASSERT_IS_GPU_THREAD;
  FXL_DCHECK(on_writes_committed);

  if (!valid_) {
    on_writes_committed();
    return;
  }

  FXL_CHECK(pending_on_writes_committed_ == nullptr)
      << "Attempted to signal a write on the surface when the previous write "
         "has not yet been acknowledged by the compositor.";

  pending_on_writes_committed_ = on_writes_committed;
}

void VulkanSurface::Reset() {
  ASSERT_IS_GPU_THREAD;

  if (acquire_event_.signal(MX_EVENT_SIGNALED, 0u) != MX_OK ||
      release_event_.signal(MX_EVENT_SIGNALED, 0u) != MX_OK) {
    valid_ = false;
    FXL_DLOG(ERROR)
        << "Could not reset fences. The surface is no longer valid.";
  }

  // Need to make a new  acquire semaphore every frame or else validation layers
  // get confused about why no one is waiting on it in this VkInstance
  acquire_semaphore_.Reset();
  acquire_semaphore_ = SemaphoreFromEvent(acquire_event_);
  if (!acquire_semaphore_) {
    FXL_DLOG(ERROR) << "failed to create acquire semaphore";
  }

  // It is safe for the caller to collect the surface in the callback.
  auto callback = pending_on_writes_committed_;
  pending_on_writes_committed_ = nullptr;
  if (callback) {
    callback();
  }
}

void VulkanSurface::OnHandleReady(mx_handle_t handle,
                                  mx_signals_t pending,
                                  uint64_t count) {
  ASSERT_IS_GPU_THREAD;
  FXL_DCHECK(pending & MX_EVENT_SIGNALED);
  FXL_DCHECK(handle == release_event_.get());
  Reset();
}

}  // namespace flutter_runner
