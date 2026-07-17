// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/vulkan/allocator_vk.h"

#include <atomic>
#include <memory>
#include <mutex>
#include <utility>

#include "flutter/fml/build_config.h"

#ifdef FML_OS_WIN
#include <psapi.h>
#include <windows.h>
#endif  // FML_OS_WIN

#include "flutter/fml/logging.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/trace_event.h"
#include "impeller/base/allocation_size.h"
#include "impeller/core/formats.h"
#include "impeller/renderer/backend/vulkan/capabilities_vk.h"
#include "impeller/renderer/backend/vulkan/device_buffer_vk.h"
#include "impeller/renderer/backend/vulkan/device_holder_vk.h"
#include "impeller/renderer/backend/vulkan/formats_vk.h"
#include "impeller/renderer/backend/vulkan/texture_vk.h"
#include "vulkan/vulkan_enums.hpp"

namespace impeller {

// Maximum number of VMA buffer pool blocks. 256 blocks x 4 MB = 1 GB.
// Caps pool growth under high-water-mark buffer demand spikes.
static constexpr uint32_t kMaxBufferPoolBlocks = 256;

static constexpr vk::Flags<vk::MemoryPropertyFlagBits>
ToVKBufferMemoryPropertyFlags(StorageMode mode) {
  switch (mode) {
    case StorageMode::kHostVisible:
      return vk::MemoryPropertyFlagBits::eHostVisible;
    case StorageMode::kDevicePrivate:
      return vk::MemoryPropertyFlagBits::eDeviceLocal;
    case StorageMode::kDeviceTransient:
      return vk::MemoryPropertyFlagBits::eLazilyAllocated;
  }
  FML_UNREACHABLE();
}

static VmaAllocationCreateFlags ToVmaAllocationBufferCreateFlags(
    StorageMode mode,
    bool readback) {
  VmaAllocationCreateFlags flags = 0;
  switch (mode) {
    case StorageMode::kHostVisible:
      if (!readback) {
        flags |= VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT;
      } else {
        flags |= VMA_ALLOCATION_CREATE_HOST_ACCESS_RANDOM_BIT;
      }
      flags |= VMA_ALLOCATION_CREATE_MAPPED_BIT;
      return flags;
    case StorageMode::kDevicePrivate:
      FML_DCHECK(!readback);
      return flags;
    case StorageMode::kDeviceTransient:
      FML_DCHECK(!readback);
      return flags;
  }
  FML_UNREACHABLE();
}

static PoolVMA CreateBufferPool(VmaAllocator allocator) {
  vk::BufferCreateInfo buffer_info;
  buffer_info.usage = vk::BufferUsageFlagBits::eVertexBuffer |
                      vk::BufferUsageFlagBits::eIndexBuffer |
                      vk::BufferUsageFlagBits::eUniformBuffer |
                      vk::BufferUsageFlagBits::eStorageBuffer |
                      vk::BufferUsageFlagBits::eTransferSrc |
                      vk::BufferUsageFlagBits::eTransferDst;
  buffer_info.size = 1u;  // doesn't matter
  buffer_info.sharingMode = vk::SharingMode::eExclusive;
  auto buffer_info_native =
      static_cast<vk::BufferCreateInfo::NativeType>(buffer_info);

  VmaAllocationCreateInfo allocation_info = {};
  allocation_info.usage = VMA_MEMORY_USAGE_AUTO;
  allocation_info.preferredFlags = static_cast<VkMemoryPropertyFlags>(
      ToVKBufferMemoryPropertyFlags(StorageMode::kHostVisible));
  allocation_info.flags = ToVmaAllocationBufferCreateFlags(
      StorageMode::kHostVisible, /*readback=*/false);

  uint32_t memTypeIndex;
  auto result = vk::Result{vmaFindMemoryTypeIndexForBufferInfo(
      allocator, &buffer_info_native, &allocation_info, &memTypeIndex)};
  if (result != vk::Result::eSuccess) {
    return {};
  }

  VmaPoolCreateInfo pool_create_info = {};
  pool_create_info.memoryTypeIndex = memTypeIndex;
  pool_create_info.flags = VMA_POOL_CREATE_IGNORE_BUFFER_IMAGE_GRANULARITY_BIT;
  pool_create_info.minBlockCount = 1;
  // Cap at 256 blocks x 4 MB = 1 GB. Without a cap, VMA grows this pool
  // without bound when high-water-mark buffer demand spikes (e.g. during
  // benchmarks), and pool-internal fragmentation may prevent block reuse even
  // after individual allocations are freed.
  pool_create_info.maxBlockCount = kMaxBufferPoolBlocks;

  VmaPool pool = {};
  result = vk::Result{::vmaCreatePool(allocator, &pool_create_info, &pool)};
  if (result != vk::Result::eSuccess) {
    return {};
  }
  return {allocator, pool};
}

AllocatorVK::AllocatorVK(std::weak_ptr<Context> context,
                         uint32_t vulkan_api_version,
                         const vk::PhysicalDevice& physical_device,
                         const std::shared_ptr<DeviceHolderVK>& device_holder,
                         const vk::Instance& instance,
                         const CapabilitiesVK& capabilities)
    : context_(std::move(context)), device_holder_(device_holder) {
  auto limits = physical_device.getProperties().limits;
  max_texture_size_.width = max_texture_size_.height =
      limits.maxImageDimension2D;
  physical_device.getMemoryProperties(&memory_properties_);

  VmaVulkanFunctions proc_table = {};

#define BIND_VMA_PROC(x) proc_table.x = VULKAN_HPP_DEFAULT_DISPATCHER.x;
#define BIND_VMA_PROC_KHR(x)                                \
  proc_table.x##KHR = VULKAN_HPP_DEFAULT_DISPATCHER.x       \
                          ? VULKAN_HPP_DEFAULT_DISPATCHER.x \
                          : VULKAN_HPP_DEFAULT_DISPATCHER.x##KHR;
  BIND_VMA_PROC(vkGetInstanceProcAddr);
  BIND_VMA_PROC(vkGetDeviceProcAddr);
  BIND_VMA_PROC(vkGetPhysicalDeviceProperties);
  BIND_VMA_PROC(vkGetPhysicalDeviceMemoryProperties);
  BIND_VMA_PROC(vkAllocateMemory);
  BIND_VMA_PROC(vkFreeMemory);
  BIND_VMA_PROC(vkMapMemory);
  BIND_VMA_PROC(vkUnmapMemory);
  BIND_VMA_PROC(vkFlushMappedMemoryRanges);
  BIND_VMA_PROC(vkInvalidateMappedMemoryRanges);
  BIND_VMA_PROC(vkBindBufferMemory);
  BIND_VMA_PROC(vkBindImageMemory);
  BIND_VMA_PROC(vkGetBufferMemoryRequirements);
  BIND_VMA_PROC(vkGetImageMemoryRequirements);
  BIND_VMA_PROC(vkCreateBuffer);
  BIND_VMA_PROC(vkDestroyBuffer);
  BIND_VMA_PROC(vkCreateImage);
  BIND_VMA_PROC(vkDestroyImage);
  BIND_VMA_PROC(vkCmdCopyBuffer);
  BIND_VMA_PROC_KHR(vkGetBufferMemoryRequirements2);
  BIND_VMA_PROC_KHR(vkGetImageMemoryRequirements2);
  BIND_VMA_PROC_KHR(vkBindBufferMemory2);
  BIND_VMA_PROC_KHR(vkBindImageMemory2);
  BIND_VMA_PROC_KHR(vkGetPhysicalDeviceMemoryProperties2);
#undef BIND_VMA_PROC_KHR
#undef BIND_VMA_PROC

  VmaAllocatorCreateInfo allocator_info = {};
  allocator_info.vulkanApiVersion = vulkan_api_version;
  allocator_info.physicalDevice = physical_device;
  allocator_info.device = device_holder->GetDevice();
  allocator_info.instance = instance;
  // 4 MB, matching the default used by Skia Vulkan.
  allocator_info.preferredLargeHeapBlockSize = 4 * 1024 * 1024;
  allocator_info.pVulkanFunctions = &proc_table;

  VmaAllocator allocator = {};
  auto result = vk::Result{::vmaCreateAllocator(&allocator_info, &allocator)};
  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Could not create memory allocator";
    return;
  }
  staging_buffer_pool_.reset(CreateBufferPool(allocator));
  created_buffer_pool_ &= staging_buffer_pool_.is_valid();
  allocator_.reset(allocator);
  supports_memoryless_textures_ =
      capabilities.SupportsDeviceTransientTextures();
  is_valid_ = true;
}

AllocatorVK::~AllocatorVK() = default;

// |Allocator|
bool AllocatorVK::IsValid() const {
  return is_valid_;
}

// |Allocator|
ISize AllocatorVK::GetMaxTextureSizeSupported() const {
  return max_texture_size_;
}

int32_t AllocatorVK::FindMemoryTypeIndex(
    uint32_t memory_type_bits_requirement,
    vk::PhysicalDeviceMemoryProperties& memory_properties) {
  int32_t type_index = -1;
  vk::MemoryPropertyFlagBits required_properties =
      vk::MemoryPropertyFlagBits::eDeviceLocal;

  const uint32_t memory_count = memory_properties.memoryTypeCount;
  for (uint32_t memory_index = 0; memory_index < memory_count; ++memory_index) {
    const uint32_t memory_type_bits = (1 << memory_index);
    const bool is_required_memory_type =
        memory_type_bits_requirement & memory_type_bits;

    const auto properties =
        memory_properties.memoryTypes[memory_index].propertyFlags;
    const bool has_required_properties =
        (properties & required_properties) == required_properties;

    if (is_required_memory_type && has_required_properties) {
      return static_cast<int32_t>(memory_index);
    }
  }

  return type_index;
}

vk::ImageUsageFlags AllocatorVK::ToVKImageUsageFlags(
    PixelFormat format,
    TextureUsageMask usage,
    StorageMode mode,
    bool supports_memoryless_textures) {
  vk::ImageUsageFlags vk_usage;

  switch (mode) {
    case StorageMode::kHostVisible:
    case StorageMode::kDevicePrivate:
      break;
    case StorageMode::kDeviceTransient:
      if (supports_memoryless_textures) {
        vk_usage |= vk::ImageUsageFlagBits::eTransientAttachment;
      }
      break;
  }

  if (usage & TextureUsage::kRenderTarget) {
    if (PixelFormatIsDepthStencil(format)) {
      vk_usage |= vk::ImageUsageFlagBits::eDepthStencilAttachment;
    } else {
      vk_usage |= vk::ImageUsageFlagBits::eColorAttachment;
      vk_usage |= vk::ImageUsageFlagBits::eInputAttachment;
    }
  }

  if (usage & TextureUsage::kShaderRead) {
    vk_usage |= vk::ImageUsageFlagBits::eSampled;
  }

  if (usage & TextureUsage::kShaderWrite) {
    vk_usage |= vk::ImageUsageFlagBits::eStorage;
  }

  if (mode != StorageMode::kDeviceTransient) {
    // Add transfer usage flags to support blit passes only if image isn't
    // device transient.
    vk_usage |= vk::ImageUsageFlagBits::eTransferSrc |
                vk::ImageUsageFlagBits::eTransferDst;
  }

  return vk_usage;
}

static constexpr VmaMemoryUsage ToVMAMemoryUsage() {
  return VMA_MEMORY_USAGE_AUTO;
}

static constexpr vk::Flags<vk::MemoryPropertyFlagBits>
ToVKTextureMemoryPropertyFlags(StorageMode mode,
                               bool supports_memoryless_textures) {
  switch (mode) {
    case StorageMode::kHostVisible:
      return vk::MemoryPropertyFlagBits::eHostVisible |
             vk::MemoryPropertyFlagBits::eDeviceLocal;
    case StorageMode::kDevicePrivate:
      return vk::MemoryPropertyFlagBits::eDeviceLocal;
    case StorageMode::kDeviceTransient:
      if (supports_memoryless_textures) {
        return vk::MemoryPropertyFlagBits::eLazilyAllocated |
               vk::MemoryPropertyFlagBits::eDeviceLocal;
      }
      return vk::MemoryPropertyFlagBits::eDeviceLocal;
  }
  FML_UNREACHABLE();
}

static VmaAllocationCreateFlags ToVmaAllocationCreateFlags(StorageMode mode) {
  VmaAllocationCreateFlags flags = 0;
  switch (mode) {
    case StorageMode::kHostVisible:
      return flags;
    case StorageMode::kDevicePrivate:
      return flags;
    case StorageMode::kDeviceTransient:
      return flags;
  }
  FML_UNREACHABLE();
}

class AllocatedTextureSourceVK final : public TextureSourceVK {
 public:
  AllocatedTextureSourceVK(const ContextVK& context,
                           const TextureDescriptor& desc,
                           VmaAllocator allocator,
                           vk::Device device,
                           bool supports_memoryless_textures)
      : TextureSourceVK(desc), resource_(context.GetResourceManager()) {
    FML_DCHECK(desc.format != PixelFormat::kUnknown);
    vk::StructureChain<vk::ImageCreateInfo, vk::ImageCompressionControlEXT>
        image_info_chain;
    auto& image_info = image_info_chain.get();
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
    image_info.usage = AllocatorVK::ToVKImageUsageFlags(
        desc.format, desc.usage, desc.storage_mode,
        supports_memoryless_textures);
    image_info.sharingMode = vk::SharingMode::eExclusive;

    vk::ImageCompressionFixedRateFlagsEXT frc_rates[1] = {
        vk::ImageCompressionFixedRateFlagBitsEXT::eNone};

    const auto frc_rate =
        CapabilitiesVK::Cast(*context.GetCapabilities())
            .GetSupportedFRCRate(desc.compression_type,
                                 FRCFormatDescriptor{image_info});
    if (frc_rate.has_value()) {
      // This array must not be in a temporary scope.
      frc_rates[0] = frc_rate.value();

      auto& compression_info =
          image_info_chain.get<vk::ImageCompressionControlEXT>();
      compression_info.pFixedRateFlags = frc_rates;
      compression_info.compressionControlPlaneCount = 1u;
      compression_info.flags =
          vk::ImageCompressionFlagBitsEXT::eFixedRateExplicit;
    } else {
      image_info_chain.unlink<vk::ImageCompressionControlEXT>();
    }

    VmaAllocationCreateInfo alloc_nfo = {};

    alloc_nfo.usage = ToVMAMemoryUsage();
    alloc_nfo.preferredFlags =
        static_cast<VkMemoryPropertyFlags>(ToVKTextureMemoryPropertyFlags(
            desc.storage_mode, supports_memoryless_textures));
    alloc_nfo.flags = ToVmaAllocationCreateFlags(desc.storage_mode);

    VkImage vk_image = VK_NULL_HANDLE;
    VmaAllocation allocation = {};
    VmaAllocationInfo allocation_info = {};

    // Performs the VMA image allocation using the current create-info chain.
    // The native create-info is re-derived from the chain on each call, so an
    // unlink of the compression-control struct between calls is reflected.
    const auto try_create_image = [&]() -> vk::Result {
      vk::ImageCreateInfo::NativeType create_info_native =
          static_cast<vk::ImageCreateInfo::NativeType>(
              image_info_chain.get<vk::ImageCreateInfo>());
      return vk::Result{::vmaCreateImage(allocator,            //
                                         &create_info_native,  //
                                         &alloc_nfo,           //
                                         &vk_image,            //
                                         &allocation,          //
                                         &allocation_info      //
                                         )};
    };

    // Fixed-rate compression was requested iff a rate was selected above.
    const bool requested_compression = frc_rate.has_value();
    vk::Result alloc_result = try_create_image();

    // Some drivers (e.g. PowerVR) can return VK_ERROR_COMPRESSION_EXHAUSTED_EXT
    // when fixed-rate compression resources are depleted. Per the Vulkan spec
    // this error is only returned for fixed-rate compression requests, so
    // retrying without compression is a valid recovery. Without it the
    // allocation fails, the texture is invalid, and the resulting null render
    // target crashes the raster thread.
    if (alloc_result == vk::Result::eErrorCompressionExhaustedEXT &&
        requested_compression) {
      static std::once_flag warn_once;
      std::call_once(warn_once, [] {
        FML_LOG(WARNING)
            << "Fixed-rate image compression exhausted; falling back to "
               "uncompressed image allocation. (This message is logged once.)";
      });
      // The compression-control struct is only present here because compression
      // was requested above, so unlinking it once is safe (no double-unlink).
      image_info_chain.unlink<vk::ImageCompressionControlEXT>();
      alloc_result = try_create_image();
    }

    if (alloc_result != vk::Result::eSuccess) {
      VALIDATION_LOG << "Unable to allocate Vulkan Image: "
                     << vk::to_string(alloc_result)
                     << " Type: " << TextureTypeToString(desc.type)
                     << " Mode: " << StorageModeToString(desc.storage_mode)
                     << " Usage: " << TextureUsageMaskToString(desc.usage)
                     << " [VK]Flags: " << vk::to_string(image_info.flags)
                     << " [VK]Format: " << vk::to_string(image_info.format)
                     << " [VK]Usage: " << vk::to_string(image_info.usage)
                     << " [VK]Mem. Flags: "
                     << vk::to_string(
                            vk::MemoryPropertyFlags(alloc_nfo.preferredFlags));
      return;
    }

    auto image = vk::Image{vk_image};

    vk::ImageViewCreateInfo view_info = {};
    view_info.image = image;
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
      // Nothing owns the image yet; destroy it to avoid leaking the
      // allocation.
      vmaDestroyImage(allocator, vk_image, allocation);
      return;
    }
    // Create one 2D attachment view per (mip level, array layer) so a
    // specific subresource can be rendered into. Render targets are usually a
    // single 2D mip (one view); cube and mipmapped render targets get the
    // full set. Non-render-target textures only need the base view.
    view_info.viewType = vk::ImageViewType::e2D;
    view_info.subresourceRange.levelCount = 1u;
    view_info.subresourceRange.layerCount = 1u;
    const bool is_render_target = !!(desc.usage & TextureUsage::kRenderTarget);
    const uint32_t rt_mip_count = is_render_target ? image_info.mipLevels : 1u;
    const uint32_t rt_layer_count =
        is_render_target ? ToArrayLayerCount(desc.type) : 1u;
    std::vector<vk::UniqueImageView> rt_image_views;
    rt_image_views.reserve(rt_mip_count * rt_layer_count);
    for (uint32_t mip = 0; mip < rt_mip_count; mip++) {
      for (uint32_t layer = 0; layer < rt_layer_count; layer++) {
        view_info.subresourceRange.baseMipLevel = mip;
        view_info.subresourceRange.baseArrayLayer = layer;
        auto [rt_result, rt_image_view] =
            device.createImageViewUnique(view_info);
        if (rt_result != vk::Result::eSuccess) {
          VALIDATION_LOG << "Unable to create a render target image view: "
                         << vk::to_string(rt_result);
          // Destroy the views created so far, then the image.
          rt_image_views.clear();
          image_view.reset();
          vmaDestroyImage(allocator, vk_image, allocation);
          return;
        }
        rt_image_views.push_back(std::move(rt_image_view));
      }
    }

    resource_.Swap(ImageResource(
        ImageVMA{allocator, allocation, image}, std::move(image_view),
        std::move(rt_image_views), context.GetResourceAllocator(),
        context.GetDeviceHolder()));
    is_valid_ = true;
  }

  ~AllocatedTextureSourceVK() = default;

  bool IsValid() const { return is_valid_; }

  vk::Image GetImage() const override { return resource_->image.get().image; }

  vk::ImageView GetImageView() const override {
    return resource_->image_view.get();
  }

  vk::ImageView GetRenderTargetView(uint32_t mip_level,
                                    uint32_t array_layer) const override {
    const auto& views = resource_->rt_image_views;
    if (views.empty()) {
      return VK_NULL_HANDLE;
    }
    const uint32_t layer_count = ToArrayLayerCount(GetTextureDescriptor().type);
    const size_t index =
        static_cast<size_t>(mip_level) * layer_count + array_layer;
    return index < views.size() ? views[index].get() : views[0].get();
  }

  bool IsSwapchainImage() const override { return false; }

 private:
  struct ImageResource {
    std::shared_ptr<DeviceHolderVK> device_holder;
    std::shared_ptr<Allocator> allocator;
    UniqueImageVMA image;
    vk::UniqueImageView image_view;
    // One attachment view per (mip level, array layer), row-major by mip.
    std::vector<vk::UniqueImageView> rt_image_views;

    ImageResource() = default;

    ImageResource(ImageVMA p_image,
                  vk::UniqueImageView p_image_view,
                  std::vector<vk::UniqueImageView> p_rt_image_views,
                  std::shared_ptr<Allocator> allocator,
                  std::shared_ptr<DeviceHolderVK> device_holder)
        : device_holder(std::move(device_holder)),
          allocator(std::move(allocator)),
          image(p_image),
          image_view(std::move(p_image_view)),
          rt_image_views(std::move(p_rt_image_views)) {}

    ImageResource(ImageResource&& o) = default;

    ImageResource(const ImageResource&) = delete;

    ImageResource& operator=(const ImageResource&) = delete;
  };

  UniqueResourceVKT<ImageResource> resource_;
  bool is_valid_ = false;

  AllocatedTextureSourceVK(const AllocatedTextureSourceVK&) = delete;

  AllocatedTextureSourceVK& operator=(const AllocatedTextureSourceVK&) = delete;
};

// |Allocator|
std::shared_ptr<Texture> AllocatorVK::OnCreateTexture(
    const TextureDescriptor& desc,
    bool threadsafe) {
  if (!IsValid()) {
    return nullptr;
  }
  auto device_holder = device_holder_.lock();
  if (!device_holder) {
    return nullptr;
  }
  auto context = context_.lock();
  if (!context) {
    return nullptr;
  }
  auto source = std::make_shared<AllocatedTextureSourceVK>(
      ContextVK::Cast(*context),     //
      desc,                          //
      allocator_.get(),              //
      device_holder->GetDevice(),    //
      supports_memoryless_textures_  //
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
                      vk::BufferUsageFlagBits::eStorageBuffer |
                      vk::BufferUsageFlagBits::eTransferSrc |
                      vk::BufferUsageFlagBits::eTransferDst;
  buffer_info.size = desc.size;
  buffer_info.sharingMode = vk::SharingMode::eExclusive;
  auto buffer_info_native =
      static_cast<vk::BufferCreateInfo::NativeType>(buffer_info);

  VmaAllocationCreateInfo allocation_info = {};
  allocation_info.usage = ToVMAMemoryUsage();
  allocation_info.preferredFlags = static_cast<VkMemoryPropertyFlags>(
      ToVKBufferMemoryPropertyFlags(desc.storage_mode));
  allocation_info.flags =
      ToVmaAllocationBufferCreateFlags(desc.storage_mode, desc.readback);
  if (created_buffer_pool_ && desc.storage_mode == StorageMode::kHostVisible &&
      !desc.readback) {
    allocation_info.pool = staging_buffer_pool_.get().pool;
  }
  VkBuffer buffer = {};
  VmaAllocation buffer_allocation = {};
  VmaAllocationInfo buffer_allocation_info = {};
  auto result = vk::Result{::vmaCreateBuffer(allocator_.get(),        //
                                             &buffer_info_native,     //
                                             &allocation_info,        //
                                             &buffer,                 //
                                             &buffer_allocation,      //
                                             &buffer_allocation_info  //
                                             )};

  auto type = memory_properties_.memoryTypes[buffer_allocation_info.memoryType];
  bool is_host_coherent =
      !!(type.propertyFlags & vk::MemoryPropertyFlagBits::eHostCoherent);

  if (result != vk::Result::eSuccess) {
    VALIDATION_LOG << "Unable to allocate a device buffer: "
                   << vk::to_string(result);
    return {};
  }

  return std::make_shared<DeviceBufferVK>(
      desc,                                            //
      context_,                                        //
      UniqueBufferVMA{BufferVMA{allocator_.get(),      //
                                buffer_allocation,     //
                                vk::Buffer{buffer}}},  //
      buffer_allocation_info,                          //
      is_host_coherent);
}

Bytes AllocatorVK::DebugGetHeapUsage() const {
  auto count = memory_properties_.memoryHeapCount;
  std::vector<VmaBudget> budgets(count);
  vmaGetHeapBudgets(allocator_.get(), budgets.data());
  size_t total_usage = 0;
  for (auto i = 0u; i < count; i++) {
    const VmaBudget& budget = budgets[i];
    total_usage += budget.usage;
  }
  return Bytes{total_usage};
}

void AllocatorVK::DebugTraceMemoryStatistics() const {
#ifdef IMPELLER_DEBUG
  FML_TRACE_COUNTER("flutter", "AllocatorVK",
                    reinterpret_cast<int64_t>(this),  // Trace Counter ID
                    "MemoryBudgetUsageMB",
                    DebugGetHeapUsage().ConvertTo<MebiBytes>().GetSize());
#endif  // IMPELLER_DEBUG

#ifdef FML_OS_WIN
  // On Windows with Resizable BAR (AMD RDNA, Intel Arc), the GPU driver maps
  // all VRAM into the process address space, inflating the working set far
  // beyond actual CPU-side usage. Periodically trim the working set when RSS
  // is disproportionately large relative to actual VMA allocations.
  //
  // The trim is rate-limited to once every ~5 seconds (300 frames at 60 fps)
  // to avoid thrashing. It only acts when:
  //   1. VMA allocations are small (< 256 MB): the driver BAR mapping is
  //      responsible for the bloat, not actual GPU memory pressure.
  //   2. RSS exceeds 1 GB and is > 4x VMA usage: confirms the working set
  //      is dominated by driver-mapped pages, not application data.
  //
  // EmptyWorkingSet moves pages to the standby list without freeing them;
  // they are faulted back in on next access, so the cost is minimal for
  // pages that are actively used.
  {
    static constexpr size_t kTrimCooldownFrames = 300;  // ~5 s at 60 fps.
    static constexpr size_t kMinRssMB = 1024;
    static constexpr size_t kMaxVmaMB = 256;
    static constexpr size_t kRssToVmaRatio = 4;
    static constexpr size_t kBytesPerMB = 1024u * 1024u;

    // EmptyWorkingSet trims the whole process, so the cooldown is shared by
    // all threads; a per-thread cooldown would let multiple raster threads
    // (one per engine instance in the process) each trim on their own clock.
    // Races on the counter are benign: a lost decrement only delays the next
    // trim check by a frame.
    static std::atomic<int> trim_cooldown = 0;
    int cooldown = trim_cooldown.load(std::memory_order_relaxed);
    if (cooldown > 0) {
      trim_cooldown.store(cooldown - 1, std::memory_order_relaxed);
    }

    if (cooldown == 0) {
      size_t vma_mb = DebugGetHeapUsage().ConvertTo<MebiBytes>().GetSize();
      if (vma_mb < kMaxVmaMB) {
        PROCESS_MEMORY_COUNTERS pmc = {};
        pmc.cb = sizeof(pmc);
        if (::GetProcessMemoryInfo(::GetCurrentProcess(), &pmc, sizeof(pmc))) {
          size_t rss_mb = pmc.WorkingSetSize / kBytesPerMB;
          if (rss_mb > kMinRssMB && rss_mb > vma_mb * kRssToVmaRatio) {
            trim_cooldown.store(kTrimCooldownFrames, std::memory_order_relaxed);
            ::EmptyWorkingSet(::GetCurrentProcess());
            FML_DLOG(INFO) << "Working set trimmed: " << rss_mb << " MB";
          }
        }
      }
    }
  }
#endif  // FML_OS_WIN
}

}  // namespace impeller
