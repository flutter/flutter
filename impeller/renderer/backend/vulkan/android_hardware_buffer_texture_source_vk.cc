// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/android_hardware_buffer_texture_source_vk.h"

#include <cstdint>

#include "impeller/renderer/backend/vulkan/texture_source_vk.h"

#ifdef FML_OS_ANDROID

namespace impeller {

namespace {

bool GetHardwareBufferProperties(
    const vk::Device& device,
    struct AHardwareBuffer* hardware_buffer,
    ::impeller::vk::AndroidHardwareBufferPropertiesANDROID* ahb_props,
    ::impeller::vk::AndroidHardwareBufferFormatPropertiesANDROID*
        ahb_format_props) {
  FML_CHECK(ahb_format_props != nullptr);
  FML_CHECK(ahb_props != nullptr);
  ahb_props->pNext = ahb_format_props;
  ::impeller::vk::Result result =
      device.getAndroidHardwareBufferPropertiesANDROID(hardware_buffer,
                                                       ahb_props);
  if (result != impeller::vk::Result::eSuccess) {
    return false;
  }
  return true;
}

vk::ExternalFormatANDROID MakeExternalFormat(
    const vk::AndroidHardwareBufferFormatPropertiesANDROID& format_props) {
  vk::ExternalFormatANDROID external_format;
  external_format.pNext = nullptr;
  external_format.externalFormat = 0;
  if (format_props.format == vk::Format::eUndefined) {
    external_format.externalFormat = format_props.externalFormat;
  }
  return external_format;
}

// Returns -1 if not found.
int FindMemoryTypeIndex(
    const vk::AndroidHardwareBufferPropertiesANDROID& props) {
  uint32_t memory_type_bits = props.memoryTypeBits;
  int32_t type_index = -1;
  for (uint32_t i = 0; memory_type_bits;
       memory_type_bits = memory_type_bits >> 0x1, ++i) {
    if (memory_type_bits & 0x1) {
      type_index = i;
      break;
    }
  }
  return type_index;
}

}  // namespace

AndroidHardwareBufferTextureSourceVK::AndroidHardwareBufferTextureSourceVK(
    TextureDescriptor desc,
    const vk::Device& device,
    struct AHardwareBuffer* hardware_buffer,
    const AHardwareBuffer_Desc& hardware_buffer_desc)
    : TextureSourceVK(desc), device_(device) {
  vk::AndroidHardwareBufferFormatPropertiesANDROID ahb_format_props;
  vk::AndroidHardwareBufferPropertiesANDROID ahb_props;
  if (!GetHardwareBufferProperties(device, hardware_buffer, &ahb_props,
                                   &ahb_format_props)) {
    return;
  }
  vk::ExternalFormatANDROID external_format =
      MakeExternalFormat(ahb_format_props);
  vk::ExternalMemoryImageCreateInfo external_memory_image_info;
  external_memory_image_info.pNext = &external_format;
  external_memory_image_info.handleTypes =
      vk::ExternalMemoryHandleTypeFlagBits::eAndroidHardwareBufferANDROID;
  const int memory_type_index = FindMemoryTypeIndex(ahb_props);
  if (memory_type_index < 0) {
    FML_LOG(ERROR) << "Could not find memory type.";
    return;
  }

  vk::ImageCreateFlags image_create_flags;
  vk::ImageUsageFlags image_usage_flags;
  if (hardware_buffer_desc.usage & AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE) {
    image_usage_flags |= impeller::vk::ImageUsageFlagBits::eSampled |
                         impeller::vk::ImageUsageFlagBits::eInputAttachment;
  }
  if (hardware_buffer_desc.usage & AHARDWAREBUFFER_USAGE_GPU_COLOR_OUTPUT) {
    image_usage_flags |= impeller::vk::ImageUsageFlagBits::eColorAttachment;
  }
  if (hardware_buffer_desc.usage & AHARDWAREBUFFER_USAGE_PROTECTED_CONTENT) {
    image_create_flags |= impeller::vk::ImageCreateFlagBits::eProtected;
  }

  vk::ImageCreateInfo image_create_info;
  image_create_info.pNext = &external_memory_image_info;
  image_create_info.imageType = vk::ImageType::e2D;
  image_create_info.format = ahb_format_props.format;
  image_create_info.extent.width = hardware_buffer_desc.width;
  image_create_info.extent.height = hardware_buffer_desc.height;
  image_create_info.extent.depth = 1;
  image_create_info.mipLevels = 1;
  image_create_info.arrayLayers = 1;
  image_create_info.samples = vk::SampleCountFlagBits::e1;
  image_create_info.tiling = vk::ImageTiling::eOptimal;
  image_create_info.usage = image_usage_flags;
  image_create_info.flags = image_create_flags;
  image_create_info.sharingMode = vk::SharingMode::eExclusive;
  image_create_info.initialLayout = vk::ImageLayout::eUndefined;

  vk::ResultValue<impeller::vk::Image> maybe_image =
      device.createImage(image_create_info);
  if (maybe_image.result != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "device.createImage failed: "
                   << static_cast<int>(maybe_image.result);
    return;
  }
  vk::Image image = maybe_image.value;

  vk::ImportAndroidHardwareBufferInfoANDROID ahb_import_info;
  ahb_import_info.pNext = nullptr;
  ahb_import_info.buffer = hardware_buffer;

  vk::MemoryDedicatedAllocateInfo dedicated_alloc_info;
  dedicated_alloc_info.pNext = &ahb_import_info;
  dedicated_alloc_info.image = image;
  dedicated_alloc_info.buffer = VK_NULL_HANDLE;

  vk::MemoryAllocateInfo mem_alloc_info;
  mem_alloc_info.pNext = &dedicated_alloc_info;
  mem_alloc_info.allocationSize = ahb_props.allocationSize;
  mem_alloc_info.memoryTypeIndex = memory_type_index;

  vk::ResultValue<vk::DeviceMemory> allocate_result =
      device.allocateMemory(mem_alloc_info);
  if (allocate_result.result != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "vkAllocateMemory failed : "
                   << static_cast<int>(allocate_result.result);
    device.destroyImage(image);
    return;
  }
  vk::DeviceMemory device_memory = allocate_result.value;

  // Bind memory to the image object.
  vk::Result bind_image_result =
      device.bindImageMemory(image, device_memory, 0);
  if (bind_image_result != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "vkBindImageMemory failed : "
                   << static_cast<int>(bind_image_result);
    device.destroyImage(image);
    device.freeMemory(device_memory);
    return;
  }
  image_ = image;
  device_memory_ = device_memory;

  // Create image view.
  vk::ImageViewCreateInfo view_info;
  view_info.image = image_;
  view_info.viewType = vk::ImageViewType::e2D;
  view_info.format = ToVKImageFormat(desc.format);
  view_info.subresourceRange.aspectMask = vk::ImageAspectFlagBits::eColor;
  view_info.subresourceRange.baseMipLevel = 0u;
  view_info.subresourceRange.baseArrayLayer = 0u;
  view_info.subresourceRange.levelCount = desc.mip_count;
  view_info.subresourceRange.layerCount = ToArrayLayerCount(desc.type);
  auto [view_result, view] = device.createImageViewUnique(view_info);
  if (view_result != vk::Result::eSuccess) {
    FML_LOG(ERROR) << "createImageViewUnique failed : "
                   << static_cast<int>(view_result);
    return;
  }
  image_view_ = std::move(view);
  is_valid_ = true;
}

// |TextureSourceVK|
AndroidHardwareBufferTextureSourceVK::~AndroidHardwareBufferTextureSourceVK() {
  device_.destroyImage(image_);
  device_.freeMemory(device_memory_);
}

bool AndroidHardwareBufferTextureSourceVK::IsValid() const {
  return is_valid_;
}

// |TextureSourceVK|
vk::Image AndroidHardwareBufferTextureSourceVK::GetImage() const {
  FML_CHECK(IsValid());
  return image_;
}

// |TextureSourceVK|
vk::ImageView AndroidHardwareBufferTextureSourceVK::GetImageView() const {
  FML_CHECK(IsValid());
  return image_view_.get();
}

}  // namespace impeller

#endif
