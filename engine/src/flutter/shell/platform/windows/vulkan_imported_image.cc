// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/vulkan_imported_image.h"

#include "flutter/fml/logging.h"

namespace flutter {

namespace {

// Finds a device-local memory type from |type_bits|. Returns UINT32_MAX if
// none exists.
uint32_t FindDeviceLocalMemoryType(
    const VkPhysicalDeviceMemoryProperties& props,
    uint32_t type_bits) {
  for (uint32_t i = 0; i < props.memoryTypeCount; i++) {
    if (!(type_bits & (1u << i))) {
      continue;
    }
    if (props.memoryTypes[i].propertyFlags &
        VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) {
      return i;
    }
  }
  return UINT32_MAX;
}

}  // namespace

// static
std::unique_ptr<VulkanImportedImage> VulkanImportedImage::Import(
    VulkanManager* manager,
    HANDLE nt_handle,
    uint32_t width,
    uint32_t height) {
  FML_DCHECK(manager != nullptr);
  if (nt_handle == nullptr || width == 0 || height == 0) {
    return nullptr;
  }

  VkInstance instance = manager->GetInstance();
  VkDevice device = manager->GetDevice();
  auto* vk = manager->GetProcTable();

  auto get_image_memory_requirements =
      reinterpret_cast<PFN_vkGetImageMemoryRequirements>(
          manager->GetInstanceProcAddress(instance,
                                          "vkGetImageMemoryRequirements"));
  auto get_memory_properties =
      reinterpret_cast<PFN_vkGetPhysicalDeviceMemoryProperties>(
          manager->GetInstanceProcAddress(
              instance, "vkGetPhysicalDeviceMemoryProperties"));
  if (!get_image_memory_requirements || !get_memory_properties) {
    FML_LOG(ERROR) << "Failed to resolve memory entry points.";
    return nullptr;
  }

  // The image mirrors the Direct3D texture: BGRA8, one mip, one layer,
  // usable as a color attachment (Impeller's onscreen resolve target) and
  // as a transfer source.
  VkExternalMemoryImageCreateInfo external_info = {};
  external_info.sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO;
  external_info.handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT;

  VkImageCreateInfo image_info = {};
  image_info.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
  image_info.pNext = &external_info;
  image_info.imageType = VK_IMAGE_TYPE_2D;
  image_info.format = VK_FORMAT_B8G8R8A8_UNORM;
  image_info.extent = {width, height, 1};
  image_info.mipLevels = 1;
  image_info.arrayLayers = 1;
  image_info.samples = VK_SAMPLE_COUNT_1_BIT;
  image_info.tiling = VK_IMAGE_TILING_OPTIMAL;
  image_info.usage =
      VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
  image_info.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
  image_info.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;

  VkImage image = VK_NULL_HANDLE;
  VkResult result = vk->CreateImage(device, &image_info, nullptr, &image);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to create importable VkImage (result=" << result
                   << ").";
    return nullptr;
  }

  VkMemoryRequirements requirements = {};
  get_image_memory_requirements(device, image, &requirements);

  VkPhysicalDeviceMemoryProperties memory_props = {};
  get_memory_properties(manager->GetPhysicalDevice(), &memory_props);

  uint32_t memory_type =
      FindDeviceLocalMemoryType(memory_props, requirements.memoryTypeBits);
  if (memory_type == UINT32_MAX) {
    FML_LOG(ERROR) << "No device-local memory type for imported image.";
    vk->DestroyImage(device, image, nullptr);
    return nullptr;
  }

  // Direct3D 11 texture imports require a dedicated allocation.
  VkMemoryDedicatedAllocateInfo dedicated_info = {};
  dedicated_info.sType = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO;
  dedicated_info.image = image;

  VkImportMemoryWin32HandleInfoKHR import_info = {};
  import_info.sType = VK_STRUCTURE_TYPE_IMPORT_MEMORY_WIN32_HANDLE_INFO_KHR;
  import_info.pNext = &dedicated_info;
  import_info.handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_D3D11_TEXTURE_BIT;
  import_info.handle = nt_handle;

  VkMemoryAllocateInfo alloc_info = {};
  alloc_info.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
  alloc_info.pNext = &import_info;
  alloc_info.allocationSize = requirements.size;
  alloc_info.memoryTypeIndex = memory_type;

  VkDeviceMemory memory = VK_NULL_HANDLE;
  result = vk->AllocateMemory(device, &alloc_info, nullptr, &memory);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to import Direct3D texture memory (result="
                   << result << ").";
    vk->DestroyImage(device, image, nullptr);
    return nullptr;
  }

  result = vk->BindImageMemory(device, image, memory, 0);
  if (result != VK_SUCCESS) {
    FML_LOG(ERROR) << "Failed to bind imported image memory (result=" << result
                   << ").";
    vk->FreeMemory(device, memory, nullptr);
    vk->DestroyImage(device, image, nullptr);
    return nullptr;
  }

  return std::unique_ptr<VulkanImportedImage>(
      new VulkanImportedImage(manager, image, memory, width, height));
}

VulkanImportedImage::VulkanImportedImage(VulkanManager* manager,
                                         VkImage image,
                                         VkDeviceMemory memory,
                                         uint32_t width,
                                         uint32_t height)
    : manager_(manager),
      image_(image),
      memory_(memory),
      width_(width),
      height_(height) {}

VulkanImportedImage::~VulkanImportedImage() {
  auto* vk = manager_->GetProcTable();
  VkDevice device = manager_->GetDevice();
  if (image_ != VK_NULL_HANDLE) {
    vk->DestroyImage(device, image_, nullptr);
  }
  if (memory_ != VK_NULL_HANDLE) {
    vk->FreeMemory(device, memory_, nullptr);
  }
}

}  // namespace flutter
