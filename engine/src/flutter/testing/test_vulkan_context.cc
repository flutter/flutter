// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cassert>
#include <memory>
#include <optional>

#include "flutter/flutter_vma/flutter_skia_vma.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/common/context_options.h"
#include "flutter/testing/test_vulkan_context.h"
#include "flutter/vulkan/vulkan_skia_proc_table.h"

#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/native_library.h"
#include "flutter/vulkan/swiftshader_path.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/vk/GrVkDirectContext.h"
#include "third_party/skia/include/gpu/vk/VulkanBackendContext.h"
#include "third_party/skia/include/gpu/vk/VulkanExtensions.h"
#include "vulkan/vulkan_core.h"

namespace flutter::testing {

TestVulkanContext::TestVulkanContext() {
  // ---------------------------------------------------------------------------
  // Initialize basic Vulkan state using the Swiftshader ICD.
  // ---------------------------------------------------------------------------

  const char* vulkan_icd = VULKAN_SO_PATH;

  // TODO(96949): Clean this up and pass a native library directly to
  //              VulkanProcTable.
  if (!fml::NativeLibrary::Create(VULKAN_SO_PATH)) {
    FML_LOG(ERROR) << "Couldn't find Vulkan ICD \"" << vulkan_icd
                   << "\", trying \"libvulkan.so\" instead.";
    vulkan_icd = "libvulkan.so";
  }

  FML_LOG(INFO) << "Using Vulkan ICD: " << vulkan_icd;

  vk_ = fml::MakeRefCounted<vulkan::VulkanProcTable>(vulkan_icd);
  if (!vk_ || !vk_->HasAcquiredMandatoryProcAddresses()) {
    FML_LOG(ERROR) << "Proc table has not acquired mandatory proc addresses.";
    return;
  }

  application_ = std::make_unique<vulkan::VulkanApplication>(
      *vk_, "Flutter Unittests", std::vector<std::string>{},
      VK_MAKE_VERSION(1, 0, 0), VK_MAKE_VERSION(1, 1, 0), true);
  if (!application_->IsValid()) {
    FML_LOG(ERROR) << "Failed to initialize basic Vulkan state.";
    return;
  }
  if (!vk_->AreInstanceProcsSetup()) {
    FML_LOG(ERROR) << "Failed to acquire full proc table.";
    return;
  }

  device_ = application_->AcquireFirstCompatibleLogicalDevice();
  if (!device_ || !device_->IsValid()) {
    FML_LOG(ERROR) << "Failed to create compatible logical device.";
    return;
  }

  // ---------------------------------------------------------------------------
  // Create a Skia context.
  // For creating SkSurfaces from VkImages and snapshotting them, etc.
  // ---------------------------------------------------------------------------

  VkPhysicalDeviceFeatures features;
  if (!device_->GetPhysicalDeviceFeatures(&features)) {
    FML_LOG(ERROR) << "Failed to get physical device features.";

    return;
  }

  auto get_proc = vulkan::CreateSkiaGetProc(vk_);
  if (get_proc == nullptr) {
    FML_LOG(ERROR) << "Failed to create Vulkan getProc for Skia.";
    return;
  }

  sk_sp<skgpu::VulkanMemoryAllocator> allocator =
      flutter::FlutterSkiaVulkanMemoryAllocator::Make(
          VK_MAKE_VERSION(1, 1, 0), application_->GetInstance(),
          device_->GetPhysicalDeviceHandle(), device_->GetHandle(), vk_, true);

  skgpu::VulkanExtensions extensions;

  skgpu::VulkanBackendContext backend_context = {};
  backend_context.fInstance = application_->GetInstance();
  backend_context.fPhysicalDevice = device_->GetPhysicalDeviceHandle();
  backend_context.fDevice = device_->GetHandle();
  backend_context.fQueue = device_->GetQueueHandle();
  backend_context.fGraphicsQueueIndex = device_->GetGraphicsQueueIndex();
  backend_context.fMaxAPIVersion = VK_MAKE_VERSION(1, 1, 0);
  backend_context.fDeviceFeatures = &features;
  backend_context.fVkExtensions = &extensions;
  backend_context.fGetProc = get_proc;
  backend_context.fMemoryAllocator = allocator;

  GrContextOptions options =
      MakeDefaultContextOptions(ContextType::kRender, GrBackendApi::kVulkan);
  options.fReduceOpsTaskSplitting = GrContextOptions::Enable::kNo;
  context_ = GrDirectContexts::MakeVulkan(backend_context, options);
}

TestVulkanContext::~TestVulkanContext() {
  if (context_) {
    context_->releaseResourcesAndAbandonContext();
  }
}

std::optional<TestVulkanImage> TestVulkanContext::CreateImage(
    const DlISize& size) const {
  return CreateImage(size, VK_FORMAT_R8G8B8A8_UNORM);
}

std::optional<TestVulkanImage> TestVulkanContext::CreateImage(
    const DlISize& size,
    VkFormat format) const {
  TestVulkanImage result;

  VkImageCreateInfo info = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .imageType = VK_IMAGE_TYPE_2D,
      .format = format,
      .extent = VkExtent3D{static_cast<uint32_t>(size.width),
                           static_cast<uint32_t>(size.height), 1},
      .mipLevels = 1,
      .arrayLayers = 1,
      .samples = VK_SAMPLE_COUNT_1_BIT,
      .tiling = VK_IMAGE_TILING_OPTIMAL,
      .usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
               VK_IMAGE_USAGE_TRANSFER_DST_BIT |
               VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_SAMPLED_BIT,
      .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .queueFamilyIndexCount = 0,
      .pQueueFamilyIndices = nullptr,
      .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
  };

  VkImage image;
  if (VK_CALL_LOG_ERROR(VK_CALL_LOG_ERROR(
          vk_->CreateImage(device_->GetHandle(), &info, nullptr, &image)))) {
    return std::nullopt;
  }

  result.image_ = vulkan::VulkanHandle<VkImage>(
      image, [&vk = vk_, &device = device_](VkImage image) {
        vk->DestroyImage(device->GetHandle(), image, nullptr);
      });

  VkMemoryRequirements mem_req;
  vk_->GetImageMemoryRequirements(device_->GetHandle(), image, &mem_req);
  VkMemoryAllocateInfo alloc_info{};
  alloc_info.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  alloc_info.allocationSize = mem_req.size;
  alloc_info.memoryTypeIndex = static_cast<uint32_t>(__builtin_ctz(
      mem_req.memoryTypeBits & VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT));

  VkDeviceMemory memory;
  if (VK_CALL_LOG_ERROR(vk_->AllocateMemory(device_->GetHandle(), &alloc_info,
                                            nullptr, &memory)) != VK_SUCCESS) {
    return std::nullopt;
  }

  result.memory_ = vulkan::VulkanHandle<VkDeviceMemory>{
      memory, [&vk = vk_, &device = device_](VkDeviceMemory memory) {
        vk->FreeMemory(device->GetHandle(), memory, nullptr);
      }};

  if (VK_CALL_LOG_ERROR(VK_CALL_LOG_ERROR(vk_->BindImageMemory(
          device_->GetHandle(), result.image_, result.memory_, 0)))) {
    return std::nullopt;
  }

  result.context_ =
      fml::RefPtr<TestVulkanContext>(const_cast<TestVulkanContext*>(this));

  return result;
}

std::optional<TestVulkanImage> TestVulkanContext::CreateNV12Image(
    const DlISize& size,
    const uint8_t* y_data,
    const uint8_t* uv_data) const {
  const uint32_t width = static_cast<uint32_t>(size.width);
  const uint32_t height = static_cast<uint32_t>(size.height);
  const VkFormat nv12_format = VK_FORMAT_G8_B8R8_2PLANE_420_UNORM;

  // Dynamically load procs not in VulkanProcTable.
  auto vkGetInstanceProcAddr = vk_->NativeGetInstanceProcAddr();
  auto vkGetPhysicalDeviceImageFormatProperties =
      reinterpret_cast<PFN_vkGetPhysicalDeviceImageFormatProperties>(
          vkGetInstanceProcAddr(application_->GetInstance(),
                                "vkGetPhysicalDeviceImageFormatProperties"));
  auto vkCmdCopyBufferToImage =
      reinterpret_cast<PFN_vkCmdCopyBufferToImage>(vkGetInstanceProcAddr(
          application_->GetInstance(), "vkCmdCopyBufferToImage"));

  VkImageFormatProperties format_props;
  if (vkGetPhysicalDeviceImageFormatProperties(
          device_->GetPhysicalDeviceHandle(), nv12_format, VK_IMAGE_TYPE_2D,
          VK_IMAGE_TILING_OPTIMAL,
          VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT, 0,
          &format_props) != VK_SUCCESS) {
    FML_LOG(ERROR) << "NV12 format not supported by device.";
    return std::nullopt;
  }

  VkImageCreateInfo image_info = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
      .pNext = nullptr,
      .flags = 0,
      .imageType = VK_IMAGE_TYPE_2D,
      .format = nv12_format,
      .extent = {width, height, 1},
      .mipLevels = 1,
      .arrayLayers = 1,
      .samples = VK_SAMPLE_COUNT_1_BIT,
      .tiling = VK_IMAGE_TILING_OPTIMAL,
      .usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT,
      .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .queueFamilyIndexCount = 0,
      .pQueueFamilyIndices = nullptr,
      .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
  };

  VkImage image;
  if (VK_CALL_LOG_ERROR(vk_->CreateImage(device_->GetHandle(), &image_info,
                                         nullptr, &image))) {
    return std::nullopt;
  }

  TestVulkanImage result;
  result.image_ = vulkan::VulkanHandle<VkImage>(
      image, [&vk = vk_, &device = device_](VkImage img) {
        vk->DestroyImage(device->GetHandle(), img, nullptr);
      });

  VkMemoryRequirements mem_req;
  vk_->GetImageMemoryRequirements(device_->GetHandle(), image, &mem_req);
  VkMemoryAllocateInfo alloc_info{};
  alloc_info.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  alloc_info.allocationSize = mem_req.size;
  alloc_info.memoryTypeIndex = static_cast<uint32_t>(__builtin_ctz(
      mem_req.memoryTypeBits & VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT));

  VkDeviceMemory memory;
  if (VK_CALL_LOG_ERROR(vk_->AllocateMemory(device_->GetHandle(), &alloc_info,
                                            nullptr, &memory)) != VK_SUCCESS) {
    return std::nullopt;
  }

  result.memory_ = vulkan::VulkanHandle<VkDeviceMemory>{
      memory, [&vk = vk_, &device = device_](VkDeviceMemory mem) {
        vk->FreeMemory(device->GetHandle(), mem, nullptr);
      }};

  if (VK_CALL_LOG_ERROR(
          vk_->BindImageMemory(device_->GetHandle(), image, memory, 0))) {
    return std::nullopt;
  }

  // Create a staging buffer for Y + UV data.
  size_t y_size = width * height;
  size_t uv_width = width / 2;
  size_t uv_height = height / 2;
  size_t uv_size = uv_width * uv_height * 2;
  size_t total_staging_size = y_size + uv_size;

  VkBufferCreateInfo buffer_info = {
      .sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
      .size = total_staging_size,
      .usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
      .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
  };

  VkBuffer staging_buffer;
  if (VK_CALL_LOG_ERROR(vk_->CreateBuffer(device_->GetHandle(), &buffer_info,
                                          nullptr, &staging_buffer))) {
    return std::nullopt;
  }

  VkMemoryRequirements buffer_mem_req;
  vk_->GetBufferMemoryRequirements(device_->GetHandle(), staging_buffer,
                                   &buffer_mem_req);
  VkMemoryAllocateInfo buffer_alloc_info{};
  buffer_alloc_info.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  buffer_alloc_info.allocationSize = buffer_mem_req.size;
  // Use HOST_VISIBLE | HOST_COHERENT for staging.
  buffer_alloc_info.memoryTypeIndex = static_cast<uint32_t>(__builtin_ctz(
      buffer_mem_req.memoryTypeBits & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT &
      VK_MEMORY_PROPERTY_HOST_COHERENT_BIT));

  VkDeviceMemory buffer_memory;
  if (VK_CALL_LOG_ERROR(vk_->AllocateMemory(
          device_->GetHandle(), &buffer_alloc_info, nullptr, &buffer_memory)) !=
      VK_SUCCESS) {
    vk_->DestroyBuffer(device_->GetHandle(), staging_buffer, nullptr);
    return std::nullopt;
  }

  vk_->BindBufferMemory(device_->GetHandle(), staging_buffer, buffer_memory, 0);

  // Map and copy data.
  void* mapped = nullptr;
  if (VK_CALL_LOG_ERROR(vk_->MapMemory(device_->GetHandle(), buffer_memory, 0,
                                       total_staging_size, 0, &mapped))) {
    vk_->FreeMemory(device_->GetHandle(), buffer_memory, nullptr);
    vk_->DestroyBuffer(device_->GetHandle(), staging_buffer, nullptr);
    return std::nullopt;
  }
  memcpy(mapped, y_data, y_size);
  memcpy(static_cast<uint8_t*>(mapped) + y_size, uv_data, uv_size);
  vk_->UnmapMemory(device_->GetHandle(), buffer_memory);

  // Create command buffer for copy operations.
  VkCommandPoolCreateInfo pool_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
      .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
      .queueFamilyIndex = device_->GetGraphicsQueueIndex(),
  };
  VkCommandPool command_pool;
  if (VK_CALL_LOG_ERROR(vk_->CreateCommandPool(device_->GetHandle(), &pool_info,
                                               nullptr, &command_pool))) {
    vk_->FreeMemory(device_->GetHandle(), buffer_memory, nullptr);
    vk_->DestroyBuffer(device_->GetHandle(), staging_buffer, nullptr);
    return std::nullopt;
  }

  VkCommandBufferAllocateInfo cmd_alloc_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
      .commandPool = command_pool,
      .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
      .commandBufferCount = 1,
  };
  VkCommandBuffer cmd_buffer;
  vk_->AllocateCommandBuffers(device_->GetHandle(), &cmd_alloc_info,
                              &cmd_buffer);

  VkCommandBufferBeginInfo begin_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
      .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
  };
  vk_->BeginCommandBuffer(cmd_buffer, &begin_info);

  // Barrier: UNDEFINED -> TRANSFER_DST_OPTIMAL for both planes.
  VkImageMemoryBarrier barrier = {};
  barrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
  barrier.srcAccessMask = 0;
  barrier.dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
  barrier.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED;
  barrier.newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
  barrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  barrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
  barrier.image = image;

  // Plane 0 (Y)
  barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_PLANE_0_BIT;
  barrier.subresourceRange.baseMipLevel = 0;
  barrier.subresourceRange.levelCount = 1;
  barrier.subresourceRange.baseArrayLayer = 0;
  barrier.subresourceRange.layerCount = 1;
  vk_->CmdPipelineBarrier(cmd_buffer, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                          VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nullptr, 0,
                          nullptr, 1, &barrier);

  // Plane 1 (UV)
  barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_PLANE_1_BIT;
  vk_->CmdPipelineBarrier(cmd_buffer, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                          VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nullptr, 0,
                          nullptr, 1, &barrier);

  // Copy Y data to plane 0.
  VkBufferImageCopy y_copy = {};
  y_copy.bufferOffset = 0;
  y_copy.bufferRowLength = 0;
  y_copy.bufferImageHeight = 0;
  y_copy.imageSubresource.aspectMask = VK_IMAGE_ASPECT_PLANE_0_BIT;
  y_copy.imageSubresource.mipLevel = 0;
  y_copy.imageSubresource.baseArrayLayer = 0;
  y_copy.imageSubresource.layerCount = 1;
  y_copy.imageOffset = {0, 0, 0};
  y_copy.imageExtent = {width, height, 1};
  vkCmdCopyBufferToImage(cmd_buffer, staging_buffer, image,
                         VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &y_copy);

  // Copy UV data to plane 1.
  VkBufferImageCopy uv_copy = {};
  uv_copy.bufferOffset = y_size;
  uv_copy.bufferRowLength = 0;
  uv_copy.bufferImageHeight = 0;
  uv_copy.imageSubresource.aspectMask = VK_IMAGE_ASPECT_PLANE_1_BIT;
  uv_copy.imageSubresource.mipLevel = 0;
  uv_copy.imageSubresource.baseArrayLayer = 0;
  uv_copy.imageSubresource.layerCount = 1;
  uv_copy.imageOffset = {0, 0, 0};
  uv_copy.imageExtent = {static_cast<uint32_t>(uv_width),
                         static_cast<uint32_t>(uv_height), 1};
  vkCmdCopyBufferToImage(cmd_buffer, staging_buffer, image,
                         VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, 1, &uv_copy);

  // Barrier: TRANSFER_DST_OPTIMAL -> SHADER_READ_ONLY_OPTIMAL for both planes.
  barrier.srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT;
  barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT;
  barrier.oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
  barrier.newLayout = VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;

  barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_PLANE_0_BIT;
  vk_->CmdPipelineBarrier(cmd_buffer, VK_PIPELINE_STAGE_TRANSFER_BIT,
                          VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nullptr,
                          0, nullptr, 1, &barrier);

  barrier.subresourceRange.aspectMask = VK_IMAGE_ASPECT_PLANE_1_BIT;
  vk_->CmdPipelineBarrier(cmd_buffer, VK_PIPELINE_STAGE_TRANSFER_BIT,
                          VK_PIPELINE_STAGE_FRAGMENT_SHADER_BIT, 0, 0, nullptr,
                          0, nullptr, 1, &barrier);

  vk_->EndCommandBuffer(cmd_buffer);

  VkSubmitInfo submit_info = {};
  submit_info.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
  submit_info.commandBufferCount = 1;
  submit_info.pCommandBuffers = &cmd_buffer;
  vk_->QueueSubmit(device_->GetQueueHandle(), 1, &submit_info, VK_NULL_HANDLE);
  vk_->QueueWaitIdle(device_->GetQueueHandle());

  // Cleanup staging resources.
  vk_->DestroyCommandPool(device_->GetHandle(), command_pool, nullptr);
  vk_->FreeMemory(device_->GetHandle(), buffer_memory, nullptr);
  vk_->DestroyBuffer(device_->GetHandle(), staging_buffer, nullptr);

  result.context_ =
      fml::RefPtr<TestVulkanContext>(const_cast<TestVulkanContext*>(this));

  return result;
}

sk_sp<GrDirectContext> TestVulkanContext::GetGrDirectContext() const {
  return context_;
}

}  // namespace flutter::testing
