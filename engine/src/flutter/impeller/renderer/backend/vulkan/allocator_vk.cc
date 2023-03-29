// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/allocator_vk.h"

#include <memory>

#include "flutter/fml/memory/ref_ptr.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"

namespace impeller {

AllocatorVK::AllocatorVK(std::weak_ptr<Context> context,
                         uint32_t vulkan_api_version,
                         const vk::PhysicalDevice& physical_device,
                         const vk::Device& logical_device,
                         const vk::Instance& instance,
                         PFN_vkGetInstanceProcAddr get_instance_proc_address,
                         PFN_vkGetDeviceProcAddr get_device_proc_address)
    : context_(std::move(context)), device_(logical_device) {
  vk_ = fml::MakeRefCounted<vulkan::VulkanProcTable>(get_instance_proc_address);

  auto instance_handle = vulkan::VulkanHandle<VkInstance>(instance);
  if (!vk_->SetupInstanceProcAddresses(instance_handle)) {
    return;
  }

  auto device_handle = vulkan::VulkanHandle<VkDevice>(logical_device);
  if (!vk_->SetupDeviceProcAddresses(device_handle)) {
    return;
  }

  auto limits = physical_device.getProperties().limits;
  max_texture_size_.width = max_texture_size_.height =
      limits.maxImageDimension2D;

  VmaVulkanFunctions proc_table = {};
  proc_table.vkGetInstanceProcAddr = get_instance_proc_address;
  proc_table.vkGetDeviceProcAddr = get_device_proc_address;

#define PROVIDE_PROC(tbl, proc, provider) tbl.vk##proc = provider->proc;
  PROVIDE_PROC(proc_table, GetPhysicalDeviceProperties, vk_);
  PROVIDE_PROC(proc_table, GetPhysicalDeviceMemoryProperties, vk_);
  PROVIDE_PROC(proc_table, AllocateMemory, vk_);
  PROVIDE_PROC(proc_table, FreeMemory, vk_);
  PROVIDE_PROC(proc_table, MapMemory, vk_);
  PROVIDE_PROC(proc_table, UnmapMemory, vk_);
  PROVIDE_PROC(proc_table, FlushMappedMemoryRanges, vk_);
  PROVIDE_PROC(proc_table, InvalidateMappedMemoryRanges, vk_);
  PROVIDE_PROC(proc_table, BindBufferMemory, vk_);
  PROVIDE_PROC(proc_table, BindImageMemory, vk_);
  PROVIDE_PROC(proc_table, GetBufferMemoryRequirements, vk_);
  PROVIDE_PROC(proc_table, GetImageMemoryRequirements, vk_);
  PROVIDE_PROC(proc_table, CreateBuffer, vk_);
  PROVIDE_PROC(proc_table, DestroyBuffer, vk_);
  PROVIDE_PROC(proc_table, CreateImage, vk_);
  PROVIDE_PROC(proc_table, DestroyImage, vk_);
  PROVIDE_PROC(proc_table, CmdCopyBuffer, vk_);

#define PROVIDE_PROC_COALESCE(tbl, proc, provider) \
  tbl.vk##proc##KHR = provider->proc ? provider->proc : provider->proc##KHR;
  // See the following link for why we have to pick either KHR version or
  // promoted non-KHR version:
  // https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/issues/203
  PROVIDE_PROC_COALESCE(proc_table, GetBufferMemoryRequirements2, vk_);
  PROVIDE_PROC_COALESCE(proc_table, GetImageMemoryRequirements2, vk_);
  PROVIDE_PROC_COALESCE(proc_table, BindBufferMemory2, vk_);
  PROVIDE_PROC_COALESCE(proc_table, BindImageMemory2, vk_);
  PROVIDE_PROC_COALESCE(proc_table, GetPhysicalDeviceMemoryProperties2, vk_);
#undef PROVIDE_PROC_COALESCE

#undef PROVIDE_PROC

  VmaAllocatorCreateInfo allocator_info = {};
  allocator_info.vulkanApiVersion = vulkan_api_version;
  allocator_info.physicalDevice = physical_device;
  allocator_info.device = logical_device;
  allocator_info.instance = instance;
  allocator_info.pVulkanFunctions = &proc_table;

  VmaAllocator allocator = {};
  auto result = vk::Result{::vmaCreateAllocator(&allocator_info, &allocator)};
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create memory allocator";
    return;
  }
  allocator_ = allocator;
  is_valid_ = true;
}

AllocatorVK::~AllocatorVK() {
  if (allocator_) {
    ::vmaDestroyAllocator(allocator_);
  }
}

// |Allocator|
bool AllocatorVK::IsValid() const {
  return is_valid_;
}

// |Allocator|
ISize AllocatorVK::GetMaxTextureSizeSupported() const {
  return max_texture_size_;
}

static constexpr vk::ImageUsageFlags ToVKImageUsageFlags(PixelFormat format,
                                                         TextureUsageMask usage,
                                                         StorageMode mode) {
  vk::ImageUsageFlags vk_usage;

  switch (mode) {
    case StorageMode::kHostVisible:
    case StorageMode::kDevicePrivate:
      break;
    case StorageMode::kDeviceTransient:
      vk_usage |= vk::ImageUsageFlagBits::eTransientAttachment;
      break;
  }

  if (usage & static_cast<TextureUsageMask>(TextureUsage::kRenderTarget)) {
    if (PixelFormatIsDepthStencil(format)) {
      vk_usage |= vk::ImageUsageFlagBits::eDepthStencilAttachment;
    } else {
      vk_usage |= vk::ImageUsageFlagBits::eColorAttachment;
    }
  }

  if (usage & static_cast<TextureUsageMask>(TextureUsage::kShaderRead)) {
    vk_usage |= vk::ImageUsageFlagBits::eSampled;
    // Device transient images can only be used as attachments. The caller
    // specified incorrect usage flags and is attempting to read a device
    // transient image in a shader. Unset the transient attachment flag. See:
    // https://github.com/flutter/flutter/issues/121633
    if (mode == StorageMode::kDeviceTransient) {
      vk_usage &= ~vk::ImageUsageFlagBits::eTransientAttachment;
    }
  }

  if (usage & static_cast<TextureUsageMask>(TextureUsage::kShaderWrite)) {
    vk_usage |= vk::ImageUsageFlagBits::eStorage;
    // Device transient images can only be used as attachments. The caller
    // specified incorrect usage flags and is attempting to read a device
    // transient image in a shader. Unset the transient attachment flag. See:
    // https://github.com/flutter/flutter/issues/121633
    if (mode == StorageMode::kDeviceTransient) {
      vk_usage &= ~vk::ImageUsageFlagBits::eTransientAttachment;
    }
  }

  if (mode != StorageMode::kDeviceTransient) {
    // TODO (https://github.com/flutter/flutter/issues/121634):
    // Add transfer usage flags to support blit passes
    vk_usage |= vk::ImageUsageFlagBits::eTransferSrc |
                vk::ImageUsageFlagBits::eTransferDst;
  }

  return vk_usage;
}

static constexpr VmaMemoryUsage ToVMAMemoryUsage() {
  return VMA_MEMORY_USAGE_AUTO;
}

static constexpr VkMemoryPropertyFlags ToVKMemoryPropertyFlags(
    StorageMode mode,
    bool is_texture) {
  switch (mode) {
    case StorageMode::kHostVisible:
      if (is_texture) {
        return VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT;
      } else {
        return VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
               VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;
      }
    case StorageMode::kDevicePrivate:
      return VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
    case StorageMode::kDeviceTransient:
      return VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT;
  }
  FML_UNREACHABLE();
}

static VmaAllocationCreateFlags ToVmaAllocationCreateFlags(StorageMode mode,
                                                           bool is_texture) {
  VmaAllocationCreateFlags flags = 0;
  switch (mode) {
    case StorageMode::kHostVisible:
      if (is_texture) {
        flags |= {};
      } else {
        flags |= VMA_ALLOCATION_CREATE_HOST_ACCESS_RANDOM_BIT;
        flags |= VMA_ALLOCATION_CREATE_MAPPED_BIT;
      }
      return flags;
    case StorageMode::kDevicePrivate:
      if (is_texture) {
        flags |= VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT;
      }
      return flags;
    case StorageMode::kDeviceTransient:
      return flags;
  }
  FML_UNREACHABLE();
}

class AllocatedTextureSourceVK final : public TextureSourceVK {
 public:
  AllocatedTextureSourceVK(const TextureDescriptor& desc,
                           VmaAllocator allocator,
                           vk::Device device)
      : TextureSourceVK(desc) {
    vk::ImageCreateInfo image_info;
    image_info.flags = ToVKImageCreateFlags(desc.type);
    image_info.imageType = vk::ImageType::e2D;
    image_info.format = ToVKImageFormat(desc.format);
    image_info.extent = VkExtent3D{
        static_cast<uint32_t>(desc.size.width),   // width
        static_cast<uint32_t>(desc.size.height),  // height
        1u                                        // depth
    };
    image_info.samples = ToVKSampleCount(desc.sample_count);
    image_info.mipLevels = desc.mip_count;
    image_info.arrayLayers = ToArrayLayerCount(desc.type);
    image_info.tiling = vk::ImageTiling::eOptimal;
    image_info.initialLayout = vk::ImageLayout::eUndefined;
    image_info.usage =
        ToVKImageUsageFlags(desc.format, desc.usage, desc.storage_mode);
    image_info.sharingMode = vk::SharingMode::eExclusive;

    VmaAllocationCreateInfo alloc_nfo = {};

    alloc_nfo.usage = ToVMAMemoryUsage();
    alloc_nfo.preferredFlags = ToVKMemoryPropertyFlags(desc.storage_mode, true);
    alloc_nfo.flags = ToVmaAllocationCreateFlags(desc.storage_mode, true);

    auto create_info_native =
        static_cast<vk::ImageCreateInfo::NativeType>(image_info);

    VkImage vk_image = VK_NULL_HANDLE;
    VmaAllocation allocation = {};
    VmaAllocationInfo allocation_info = {};
    {
      auto result = vk::Result{::vmaCreateImage(allocator,            //
                                                &create_info_native,  //
                                                &alloc_nfo,           //
                                                &vk_image,            //
                                                &allocation,          //
                                                &allocation_info      //
                                                )};
      if (result != vk::Result::eSuccess) {
        VALIDATION_LOG << "Unable to allocate Vulkan Image: "
                       << vk::to_string(result)
                       << " Type: " << TextureTypeToString(desc.type)
                       << " Mode: " << StorageModeToString(desc.storage_mode)
                       << " Usage: " << TextureUsageMaskToString(desc.usage)
                       << " [VK]Flags: " << vk::to_string(image_info.flags)
                       << " [VK]Format: " << vk::to_string(image_info.format)
                       << " [VK]Usage: " << vk::to_string(image_info.usage)
                       << " [VK]Mem. Flags: "
                       << vk::to_string(vk::MemoryPropertyFlags(
                              alloc_nfo.preferredFlags));
        return;
      }
    }

    image_ = vk::Image{vk_image};
    allocator_ = allocator;
    allocation_ = allocation;

    vk::ImageViewCreateInfo view_info = {};
    view_info.image = image_;
    view_info.viewType = ToVKImageViewType(desc.type);
    view_info.format = image_info.format;
    view_info.subresourceRange.aspectMask = ToVKImageAspectFlags(desc.format);
    view_info.subresourceRange.levelCount = image_info.mipLevels;
    view_info.subresourceRange.layerCount = ToArrayLayerCount(desc.type);

    // Vulkan does not have an image format that is equivalent to
    // `MTLPixelFormatA8Unorm`, so we use `R8Unorm` instead. Given that the
    // shaders expect that alpha channel to be set in the cases, we swizzle.
    // See: https://github.com/flutter/flutter/issues/115461 for more details.
    if (desc.format == PixelFormat::kA8UNormInt) {
      view_info.components.a = vk::ComponentSwizzle::eR;
      view_info.components.r = vk::ComponentSwizzle::eA;
    }

    auto [result, image_view] = device.createImageViewUnique(view_info);
    if (result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Unable to create an image view for allocation: "
                     << vk::to_string(result);
      return;
    }
    image_view_ = std::move(image_view);

    is_valid_ = true;
  }

  ~AllocatedTextureSourceVK() {
    image_view_.reset();
    if (image_) {
      ::vmaDestroyImage(
          allocator_,                                                  //
          static_cast<typename decltype(image_)::NativeType>(image_),  //
          allocation_                                                  //
      );
    }
  }

  bool IsValid() const { return is_valid_; }

  vk::Image GetImage() const override { return image_; }

  vk::ImageView GetImageView() const override { return image_view_.get(); }

 private:
  vk::Image image_ = {};
  VmaAllocator allocator_ = {};
  VmaAllocation allocation_ = {};
  vk::UniqueImageView image_view_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AllocatedTextureSourceVK);
};

// |Allocator|
std::shared_ptr<Texture> AllocatorVK::OnCreateTexture(
    const TextureDescriptor& desc) {
  if (!IsValid()) {
    return nullptr;
  }
  auto source = std::make_shared<AllocatedTextureSourceVK>(desc,        //
                                                           allocator_,  //
                                                           device_      //
  );
  if (!source->IsValid()) {
    return nullptr;
  }
  return std::make_shared<TextureVK>(context_, std::move(source));
}

// |Allocator|
std::shared_ptr<DeviceBuffer> AllocatorVK::OnCreateBuffer(
    const DeviceBufferDescriptor& desc) {
  vk::BufferCreateInfo buffer_info;
  buffer_info.usage = vk::BufferUsageFlagBits::eVertexBuffer |
                      vk::BufferUsageFlagBits::eIndexBuffer |
                      vk::BufferUsageFlagBits::eUniformBuffer |
                      vk::BufferUsageFlagBits::eTransferSrc |
                      vk::BufferUsageFlagBits::eTransferDst;
  buffer_info.size = desc.size;
  buffer_info.sharingMode = vk::SharingMode::eExclusive;
  auto buffer_info_native =
      static_cast<vk::BufferCreateInfo::NativeType>(buffer_info);

  VmaAllocationCreateInfo allocation_info = {};
  allocation_info.usage = ToVMAMemoryUsage();
  allocation_info.preferredFlags =
      ToVKMemoryPropertyFlags(desc.storage_mode, false);
  allocation_info.flags = ToVmaAllocationCreateFlags(desc.storage_mode, false);

  VkBuffer buffer = {};
  VmaAllocation buffer_allocation = {};
  VmaAllocationInfo buffer_allocation_info = {};
  auto result = vk::Result{::vmaCreateBuffer(allocator_,              //
                                             &buffer_info_native,     //
                                             &allocation_info,        //
                                             &buffer,                 //
                                             &buffer_allocation,      //
                                             &buffer_allocation_info  //
                                             )};

  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Unable to allocate a device buffer: "
                   << vk::to_string(result);
    return {};
  }

  return std::make_shared<DeviceBufferVK>(desc,                    //
                                          context_,                //
                                          allocator_,              //
                                          buffer_allocation,       //
                                          buffer_allocation_info,  //
                                          vk::Buffer{buffer}       //
  );
}

}  // namespace impeller
