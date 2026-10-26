// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_vulkan_external_texture.h"

#include <cstddef>
#include <cstring>
#include <utility>

#include "flutter/fml/build_config.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

#if FML_OS_ANDROID
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#endif

namespace flutter {
namespace android {

namespace {

// Number of RGBA channels per pixel (4 bytes per pixel).
constexpr size_t kRgbaBytesPerPixel = 4;

// Minimum fallback byte buffer allocation size for simulated 0-dimension
// images.
constexpr size_t kFallbackMockImageSizeBytes = 64;

// Vulkan structure type constants (from vulkan_core.h and vulkan_android.h).
// VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO = 14
constexpr uint32_t kVkStructureTypeImageCreateInfo = 14;
// VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO = 5
constexpr uint32_t kVkStructureTypeMemoryAllocateInfo = 5;
// VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO = 1000072001
constexpr uint32_t kVkStructureTypeExternalMemoryImageCreateInfo = 1000072001;
// VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO = 1000127001
constexpr uint32_t kVkStructureTypeMemoryDedicatedAllocateInfo = 1000127001;
// VK_STRUCTURE_TYPE_IMPORT_ANDROID_HARDWARE_BUFFER_INFO_ANDROID = 1000129003
constexpr uint32_t kVkStructureTypeImportAndroidHardwareBufferInfoANDROID =
    1000129003;
// VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_PROPERTIES_ANDROID = 1000129001
constexpr uint32_t kVkStructureTypeAndroidHardwareBufferPropertiesANDROID =
    1000129001;
// VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_FORMAT_PROPERTIES_ANDROID =
// 1000129002
constexpr uint32_t
    kVkStructureTypeAndroidHardwareBufferFormatPropertiesANDROID = 1000129002;
// VK_STRUCTURE_TYPE_EXTERNAL_FORMAT_ANDROID = 1000129005
constexpr uint32_t kVkStructureTypeExternalFormatANDROID = 1000129005;

// VK_EXTERNAL_MEMORY_HANDLE_TYPE_ANDROID_HARDWARE_BUFFER_BIT_ANDROID =
// 0x00000400
constexpr uint32_t kVkExternalMemoryHandleTypeAndroidHardwareBufferBit = 0x0400;
// VK_IMAGE_TYPE_2D = 1
constexpr uint32_t kVkImageType2D = 1;
// VK_SAMPLE_COUNT_1_BIT = 1
constexpr uint32_t kVkSampleCount1Bit = 1;
// VK_IMAGE_TILING_OPTIMAL = 0
constexpr uint32_t kVkImageTilingOptimal = 0;
// VK_IMAGE_USAGE_SAMPLED_BIT = 0x00000004
constexpr uint32_t kVkImageUsageSampledBit = 0x00000004;
// VK_SHARING_MODE_EXCLUSIVE = 0
constexpr uint32_t kVkSharingModeExclusive = 0;

// 4x4 column-major matrix indices for 2D UV coordinate transformation:
// u' = m[0]*u + m[4]*v + m[12]
// v' = m[1]*u + m[5]*v + m[13]
constexpr size_t kUvMatCol0Row0 = 0;
constexpr size_t kUvMatCol0Row1 = 1;
constexpr size_t kUvMatCol1Row0 = 4;
constexpr size_t kUvMatCol1Row1 = 5;
constexpr size_t kUvMatCol2Row2 = 10;
constexpr size_t kUvMatCol3Row0 = 12;
constexpr size_t kUvMatCol3Row1 = 13;
constexpr size_t kUvMatCol3Row3 = 15;

struct VkExternalFormatANDROIDCompat {
  uint32_t sType;
  const void* pNext;
  uint64_t externalFormat;
};

struct VkExternalMemoryImageCreateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t handleTypes;
};

struct VkImageCreateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint32_t flags;
  uint32_t imageType;
  uint32_t format;
  struct {
    uint32_t width;
    uint32_t height;
    uint32_t depth;
  } extent;
  uint32_t mipLevels;
  uint32_t arrayLayers;
  uint32_t samples;
  uint32_t tiling;
  uint32_t usage;
  uint32_t sharingMode;
  uint32_t queueFamilyIndexCount;
  const uint32_t* pQueueFamilyIndices;
  uint32_t initialLayout;
};

struct VkImportAndroidHardwareBufferInfoANDROIDCompat {
  uint32_t sType;
  const void* pNext;
  void* buffer;
};

struct VkMemoryDedicatedAllocateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint64_t image;
  uint64_t buffer;
};

struct VkMemoryAllocateInfoCompat {
  uint32_t sType;
  const void* pNext;
  uint64_t allocationSize;
  uint32_t memoryTypeIndex;
};

uint32_t FindFirstSetBitIndex(uint32_t mask) {
  if (mask == 0) {
    return 0;
  }
  uint32_t index = 0;
  while ((mask & 1u) == 0u) {
    mask >>= 1u;
    ++index;
  }
  return index;
}

}  // namespace

// Vulkan C function pointer signatures for dynamic virtualization.
typedef void* (*VkGetInstanceProcAddr_fn)(void* instance, const char* pName);
typedef int (*VkCreateImage_fn)(void* device,
                                const void* pCreateInfo,
                                const void* pAllocator,
                                uint64_t* pImage);
typedef void (*VkDestroyImage_fn)(void* device,
                                  uint64_t image,
                                  const void* pAllocator);
typedef void (*VkGetImageMemoryRequirements_fn)(void* device,
                                                uint64_t image,
                                                void* pMemoryRequirements);
typedef int (*VkAllocateMemory_fn)(void* device,
                                   const void* pAllocateInfo,
                                   const void* pAllocator,
                                   void** pMemory);
typedef void (*VkFreeMemory_fn)(void* device,
                                void* memory,
                                const void* pAllocator);
typedef int (*VkBindImageMemory_fn)(void* device,
                                    uint64_t image,
                                    void* memory,
                                    uint64_t memoryOffset);
typedef int (*VkCreateSamplerYcbcrConversion_fn)(void* device,
                                                 const void* pCreateInfo,
                                                 const void* pAllocator,
                                                 uint64_t* pYcbcrConversion);
typedef void (*VkDestroySamplerYcbcrConversion_fn)(void* device,
                                                   uint64_t ycbcrConversion,
                                                   const void* pAllocator);
typedef int (*VkGetAndroidHardwareBufferPropertiesANDROID_fn)(
    void* device,
    const void* buffer,
    void* pProperties);

// =============================================================================
// DefaultAndroidVulkanExternalTexture Implementation
// =============================================================================

DefaultAndroidVulkanExternalTexture::DefaultAndroidVulkanExternalTexture(
    AndroidVulkanImageDesc desc,
    uint64_t image_handle,
    void* device_memory,
    bool owns_handle,
    std::shared_ptr<DefaultAndroidVulkanTextureProvider> provider)
    : desc_(desc),
      image_handle_(image_handle),
      device_memory_(device_memory),
      owns_handle_(owns_handle),
      provider_(std::move(provider)) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::"
               "DefaultAndroidVulkanExternalTexture");
  if (desc_.ycbcr_conversion.has_value()) {
    cached_c_ycbcr_conversion_info_ =
        desc_.ycbcr_conversion.value().ToFlutterYcbcrConversionInfo();
    has_cached_c_ycbcr_conversion_info_ = true;
  }
}

DefaultAndroidVulkanExternalTexture::~DefaultAndroidVulkanExternalTexture() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::"
               "~DefaultAndroidVulkanExternalTexture");
  if (owns_handle_ && image_handle_ != 0) {
    if (provider_) {
      provider_->Release(image_handle_);
    }
    image_handle_ = 0;
  }
}

const AndroidVulkanImageDesc&
DefaultAndroidVulkanExternalTexture::GetDescription() const {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::GetDescription");
  return desc_;
}

uint64_t DefaultAndroidVulkanExternalTexture::GetImageHandle() const {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::GetImageHandle");
  return image_handle_;
}

void* DefaultAndroidVulkanExternalTexture::GetDeviceMemory() const {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::GetDeviceMemory");
  return device_memory_;
}

uint32_t DefaultAndroidVulkanExternalTexture::GetImageLayout() const {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::GetImageLayout");
  std::lock_guard<std::mutex> lock(mutex_);
  return desc_.image_layout;
}

void DefaultAndroidVulkanExternalTexture::SetImageLayout(uint32_t layout) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::SetImageLayout");
  std::lock_guard<std::mutex> lock(mutex_);
  desc_.image_layout = layout;
}

const AndroidVulkanYcbcrConversionDesc*
DefaultAndroidVulkanExternalTexture::GetYcbcrConversionDesc() const {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::GetYcbcrConversionDesc");
  if (desc_.ycbcr_conversion.has_value()) {
    return &desc_.ycbcr_conversion.value();
  }
  return nullptr;
}

bool DefaultAndroidVulkanExternalTexture::HasYcbcrConversion() const {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::HasYcbcrConversion");
  return desc_.ycbcr_conversion.has_value();
}

bool DefaultAndroidVulkanExternalTexture::IsValid() const {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanExternalTexture::IsValid");
  return image_handle_ != 0 && desc_.IsValid();
}

void DefaultAndroidVulkanExternalTexture::Acquire() {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanExternalTexture::Acquire");
  if (image_handle_ != 0 && provider_) {
    provider_->Acquire(image_handle_);
  }
}

void DefaultAndroidVulkanExternalTexture::Release() {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanExternalTexture::Release");
  if (image_handle_ != 0 && provider_) {
    provider_->Release(image_handle_);
  }
}

FlutterVulkanExternalTexture
DefaultAndroidVulkanExternalTexture::ToExternalTexture(
    void* user_data,
    VoidCallback destruction_callback) const {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::ToExternalTexture");
  FlutterVulkanExternalTexture ext_texture = {};
  PopulateExternalTexture(&ext_texture, user_data, destruction_callback);
  return ext_texture;
}

bool DefaultAndroidVulkanExternalTexture::PopulateExternalTexture(
    FlutterVulkanExternalTexture* texture_out,
    void* user_data,
    VoidCallback destruction_callback) const {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::PopulateExternalTexture");
  if (!texture_out || !IsValid()) {
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  std::memset(texture_out, 0, sizeof(FlutterVulkanExternalTexture));
  texture_out->struct_size = sizeof(FlutterVulkanExternalTexture);
  texture_out->width = desc_.width;
  texture_out->height = desc_.height;
  texture_out->image = image_handle_;
  texture_out->format = desc_.format;
  if (has_cached_c_ycbcr_conversion_info_) {
    texture_out->ycbcr_conversion_info = &cached_c_ycbcr_conversion_info_;
  } else {
    texture_out->ycbcr_conversion_info = nullptr;
  }
  texture_out->user_data = user_data;
  texture_out->destruction_callback = destruction_callback;
  return true;
}

FlutterVulkanImage DefaultAndroidVulkanExternalTexture::ToFlutterVulkanImage()
    const {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::ToFlutterVulkanImage");
  FlutterVulkanImage vk_image = {};
  vk_image.struct_size = sizeof(FlutterVulkanImage);
  vk_image.image = image_handle_;
  vk_image.format = desc_.format;
  return vk_image;
}

// =============================================================================
// DefaultAndroidVulkanTextureProvider Implementation
// =============================================================================

DefaultAndroidVulkanTextureProvider::DefaultAndroidVulkanTextureProvider(
    std::shared_ptr<OSLibraryLoader> library_loader,
    void* vk_device)
    : library_loader_(library_loader
                          ? std::move(library_loader)
                          : std::make_shared<DefaultOSLibraryLoader>()),
      vk_device_(vk_device) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanTextureProvider::"
               "DefaultAndroidVulkanTextureProvider");
}

DefaultAndroidVulkanTextureProvider::~DefaultAndroidVulkanTextureProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanTextureProvider::"
               "~DefaultAndroidVulkanTextureProvider");
}

void DefaultAndroidVulkanTextureProvider::SetVulkanDevice(void* vk_device) {
  std::lock_guard<std::mutex> lock(mutex_);
  vk_device_ = vk_device;
  if (loaded_) {
    ResolveDeviceSymbolsLocked();
  }
}

void* DefaultAndroidVulkanTextureProvider::GetVulkanDevice() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return vk_device_;
}

void DefaultAndroidVulkanTextureProvider::ResolveDeviceSymbolsLocked() const {
  using PFN_vkGetInstanceProcAddr = void* (*)(void* instance, const char* name);
  using PFN_vkGetDeviceProcAddr = void* (*)(void* device, const char* name);

  auto get_instance_proc = reinterpret_cast<PFN_vkGetInstanceProcAddr>(
      vk_get_instance_proc_addr_fn_);
  if (vk_get_device_proc_addr_fn_ == nullptr) {
    if (libvulkan_) {
      vk_get_device_proc_addr_fn_ =
          libvulkan_->ResolveSymbol("vkGetDeviceProcAddr");
    }
    if (vk_get_device_proc_addr_fn_ == nullptr &&
        get_instance_proc != nullptr) {
      vk_get_device_proc_addr_fn_ =
          get_instance_proc(nullptr, "vkGetDeviceProcAddr");
    }
  }
  auto get_device_proc =
      reinterpret_cast<PFN_vkGetDeviceProcAddr>(vk_get_device_proc_addr_fn_);

  auto resolve_sym = [&](void*& slot, const char* name) {
    if (slot != nullptr) {
      return;
    }
    if (libvulkan_) {
      slot = libvulkan_->ResolveSymbol(name);
    }
    if (slot == nullptr && vk_device_ != nullptr &&
        get_device_proc != nullptr) {
      slot = get_device_proc(vk_device_, name);
    }
    if (slot == nullptr && get_instance_proc != nullptr) {
      slot = get_instance_proc(nullptr, name);
    }
  };

  resolve_sym(vk_create_image_fn_, "vkCreateImage");
  resolve_sym(vk_destroy_image_fn_, "vkDestroyImage");
  resolve_sym(vk_get_image_memory_requirements_fn_,
              "vkGetImageMemoryRequirements");
  resolve_sym(vk_allocate_memory_fn_, "vkAllocateMemory");
  resolve_sym(vk_free_memory_fn_, "vkFreeMemory");
  resolve_sym(vk_bind_image_memory_fn_, "vkBindImageMemory");
  resolve_sym(vk_create_sampler_ycbcr_conversion_fn_,
              "vkCreateSamplerYcbcrConversion");
  resolve_sym(vk_destroy_sampler_ycbcr_conversion_fn_,
              "vkDestroySamplerYcbcrConversion");
  resolve_sym(vk_get_android_hardware_buffer_properties_android_fn_,
              "vkGetAndroidHardwareBufferPropertiesANDROID");
}

void DefaultAndroidVulkanTextureProvider::EnsureLoaded() const {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanTextureProvider::EnsureLoaded");
  std::lock_guard<std::mutex> lock(mutex_);
  if (loaded_) {
    return;
  }
  if (!library_loader_) {
    library_loader_ = std::make_shared<DefaultOSLibraryLoader>();
  }

  libvulkan_ = library_loader_->Load("libvulkan.so");
  if (libvulkan_) {
    vk_get_instance_proc_addr_fn_ =
        libvulkan_->ResolveSymbol("vkGetInstanceProcAddr");
    ResolveDeviceSymbolsLocked();

    if (vk_get_instance_proc_addr_fn_ != nullptr) {
      is_available_ = true;
    }
  }

  loaded_ = true;
}

bool DefaultAndroidVulkanTextureProvider::IsAvailable() const {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanTextureProvider::IsAvailable");
  EnsureLoaded();
  return is_available_;
}

bool DefaultAndroidVulkanTextureProvider::IsSupported(
    const AndroidVulkanImageDesc& desc) const {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanTextureProvider::IsSupported");
  EnsureLoaded();
  return is_available_ && desc.IsValid();
}

std::unique_ptr<AndroidVulkanExternalTexture>
DefaultAndroidVulkanTextureProvider::AllocateTexture(
    const AndroidVulkanImageDesc& desc) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanTextureProvider::AllocateTexture");
  EnsureLoaded();
  if (!is_available_ || !desc.IsValid() || !vk_create_image_fn_ ||
      !vk_allocate_memory_fn_ || !vk_bind_image_memory_fn_) {
    return nullptr;
  }

  std::lock_guard<std::mutex> lock(mutex_);
  if (!vk_device_) {
    return nullptr;
  }

  VkImageCreateInfoCompat image_info = {};
  image_info.sType = kVkStructureTypeImageCreateInfo;
  image_info.pNext = nullptr;
  image_info.flags = 0;
  image_info.imageType = kVkImageType2D;
  image_info.format = desc.format;
  image_info.extent = {desc.width, desc.height, 1};
  image_info.mipLevels = 1;
  image_info.arrayLayers = 1;
  image_info.samples = kVkSampleCount1Bit;
  image_info.tiling = desc.tiling;
  image_info.usage = desc.usage != 0 ? desc.usage : kVkImageUsageSampledBit;
  image_info.sharingMode = kVkSharingModeExclusive;
  image_info.initialLayout = desc.image_layout;

  auto create_image = reinterpret_cast<VkCreateImage_fn>(vk_create_image_fn_);
  uint64_t image_handle = 0;
  if (create_image(vk_device_, &image_info, nullptr, &image_handle) != 0 ||
      image_handle == 0) {
    return nullptr;
  }

  size_t byte_size =
      static_cast<size_t>(desc.width) * desc.height * kRgbaBytesPerPixel;
  VkMemoryAllocateInfoCompat alloc_info = {};
  alloc_info.sType = kVkStructureTypeMemoryAllocateInfo;
  alloc_info.pNext = nullptr;
  alloc_info.allocationSize = byte_size;
  alloc_info.memoryTypeIndex = 0;

  auto allocate_memory =
      reinterpret_cast<VkAllocateMemory_fn>(vk_allocate_memory_fn_);
  void* device_memory = nullptr;
  if (allocate_memory(vk_device_, &alloc_info, nullptr, &device_memory) != 0) {
    if (vk_destroy_image_fn_) {
      auto destroy_image =
          reinterpret_cast<VkDestroyImage_fn>(vk_destroy_image_fn_);
      destroy_image(vk_device_, image_handle, nullptr);
    }
    return nullptr;
  }

  auto bind_memory =
      reinterpret_cast<VkBindImageMemory_fn>(vk_bind_image_memory_fn_);
  if (bind_memory(vk_device_, image_handle, device_memory, 0) != 0) {
    if (vk_free_memory_fn_ && device_memory) {
      auto free_memory = reinterpret_cast<VkFreeMemory_fn>(vk_free_memory_fn_);
      free_memory(vk_device_, device_memory, nullptr);
    }
    if (vk_destroy_image_fn_) {
      auto destroy_image =
          reinterpret_cast<VkDestroyImage_fn>(vk_destroy_image_fn_);
      destroy_image(vk_device_, image_handle, nullptr);
    }
    return nullptr;
  }

  imported_allocations_[image_handle] =
      ImportedAllocation{image_handle, device_memory, 1};
  return std::make_unique<DefaultAndroidVulkanExternalTexture>(
      desc, image_handle, device_memory, /*owns_handle=*/true,
      shared_from_this());
}

std::unique_ptr<AndroidVulkanExternalTexture>
DefaultAndroidVulkanTextureProvider::CreateFromNativeImage(
    uint64_t image_handle,
    const AndroidVulkanImageDesc& desc,
    bool take_ownership) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanTextureProvider::CreateFromNativeImage");
  EnsureLoaded();
  if (!is_available_ || image_handle == 0 || !desc.IsValid()) {
    return nullptr;
  }
  if (take_ownership) {
    std::lock_guard<std::mutex> lock(mutex_);
    imported_allocations_[image_handle] =
        ImportedAllocation{image_handle, nullptr, 1};
  }
  return std::make_unique<DefaultAndroidVulkanExternalTexture>(
      desc, image_handle, nullptr, take_ownership, shared_from_this());
}

std::unique_ptr<AndroidVulkanExternalTexture>
DefaultAndroidVulkanTextureProvider::CreateFromAHardwareBuffer(
    const AndroidHardwareBuffer* hardware_buffer,
    const AndroidVulkanYcbcrConversionDesc* ycbcr_desc) {
  TRACE_EVENT0(
      "flutter",
      "DefaultAndroidVulkanTextureProvider::CreateFromAHardwareBuffer");
  EnsureLoaded();
  if (!is_available_ || !hardware_buffer || !hardware_buffer->IsValid()) {
    return nullptr;
  }
  if (!vk_get_android_hardware_buffer_properties_android_fn_ ||
      !vk_create_image_fn_ || !vk_allocate_memory_fn_ ||
      !vk_bind_image_memory_fn_) {
    return nullptr;
  }

  std::lock_guard<std::mutex> lock(mutex_);
  if (!vk_device_) {
    return nullptr;
  }

  VkAndroidHardwareBufferFormatPropertiesANDROIDCompat format_props = {};
  format_props.sType =
      kVkStructureTypeAndroidHardwareBufferFormatPropertiesANDROID;
  format_props.pNext = nullptr;

  VkAndroidHardwareBufferPropertiesANDROIDCompat ahb_props = {};
  ahb_props.sType = kVkStructureTypeAndroidHardwareBufferPropertiesANDROID;
  ahb_props.pNext = &format_props;

  auto get_ahb_props =
      reinterpret_cast<VkGetAndroidHardwareBufferPropertiesANDROID_fn>(
          vk_get_android_hardware_buffer_properties_android_fn_);
  if (get_ahb_props(vk_device_, hardware_buffer->GetHandle(), &ahb_props) !=
      0) {
    return nullptr;
  }

  const auto& ahb_desc = hardware_buffer->GetDescription();
  AndroidVulkanImageDesc vk_desc;
  vk_desc.width = ahb_desc.width;
  vk_desc.height = ahb_desc.height;
  vk_desc.image_layout =
      static_cast<uint32_t>(AndroidVulkanImageLayout::kShaderReadOnlyOptimal);
  vk_desc.usage = kVkImageUsageSampledBit;
  vk_desc.tiling = kVkImageTilingOptimal;

  if (ycbcr_desc != nullptr) {
    vk_desc.format = ycbcr_desc->format;
    vk_desc.ycbcr_conversion = *ycbcr_desc;
  } else if (format_props.format ==
                 static_cast<uint32_t>(AndroidVulkanFormat::kUndefined) &&
             format_props.externalFormat != 0) {
    vk_desc.format = static_cast<uint32_t>(AndroidVulkanFormat::kUndefined);
    AndroidVulkanYcbcrConversionDesc conv =
        AndroidVulkanYcbcrConversionDesc::MakeExternal(
            format_props.externalFormat,
            static_cast<AndroidVulkanYcbcrModel>(
                format_props.suggestedYcbcrModel),
            static_cast<AndroidVulkanYcbcrRange>(
                format_props.suggestedYcbcrRange),
            static_cast<AndroidVulkanChromaLocation>(
                format_props.suggestedXChromaOffset),
            static_cast<AndroidVulkanChromaLocation>(
                format_props.suggestedYChromaOffset),
            AndroidVulkanFilter::kLinear, format_props.formatFeatures);
    conv.components = AndroidVulkanComponentMapping{
        static_cast<AndroidVulkanComponentSwizzle>(
            format_props.samplerYcbcrConversionComponents.r),
        static_cast<AndroidVulkanComponentSwizzle>(
            format_props.samplerYcbcrConversionComponents.g),
        static_cast<AndroidVulkanComponentSwizzle>(
            format_props.samplerYcbcrConversionComponents.b),
        static_cast<AndroidVulkanComponentSwizzle>(
            format_props.samplerYcbcrConversionComponents.a)};
    vk_desc.ycbcr_conversion = conv;
  } else {
    vk_desc.format =
        format_props.format != 0
            ? format_props.format
            : static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm);
  }

  VkExternalFormatANDROIDCompat ext_format = {};
  ext_format.sType = kVkStructureTypeExternalFormatANDROID;
  ext_format.pNext = nullptr;
  ext_format.externalFormat =
      (vk_desc.format ==
           static_cast<uint32_t>(AndroidVulkanFormat::kUndefined) &&
       vk_desc.ycbcr_conversion.has_value())
          ? vk_desc.ycbcr_conversion->external_format
          : 0;

  VkExternalMemoryImageCreateInfoCompat ext_mem_image_info = {};
  ext_mem_image_info.sType = kVkStructureTypeExternalMemoryImageCreateInfo;
  ext_mem_image_info.pNext =
      (vk_desc.format ==
           static_cast<uint32_t>(AndroidVulkanFormat::kUndefined) &&
       ext_format.externalFormat != 0)
          ? &ext_format
          : nullptr;
  ext_mem_image_info.handleTypes =
      kVkExternalMemoryHandleTypeAndroidHardwareBufferBit;

  VkImageCreateInfoCompat image_info = {};
  image_info.sType = kVkStructureTypeImageCreateInfo;
  image_info.pNext = &ext_mem_image_info;
  image_info.flags = 0;
  image_info.imageType = kVkImageType2D;
  image_info.format = vk_desc.format;
  image_info.extent = {vk_desc.width, vk_desc.height, 1};
  image_info.mipLevels = 1;
  image_info.arrayLayers = 1;
  image_info.samples = kVkSampleCount1Bit;
  image_info.tiling = kVkImageTilingOptimal;
  image_info.usage = kVkImageUsageSampledBit;
  image_info.sharingMode = kVkSharingModeExclusive;
  image_info.initialLayout =
      static_cast<uint32_t>(AndroidVulkanImageLayout::kUndefined);

  auto create_image = reinterpret_cast<VkCreateImage_fn>(vk_create_image_fn_);
  uint64_t image_handle = 0;
  if (create_image(vk_device_, &image_info, nullptr, &image_handle) != 0 ||
      image_handle == 0) {
    return nullptr;
  }

  VkMemoryDedicatedAllocateInfoCompat dedicated_info = {};
  dedicated_info.sType = kVkStructureTypeMemoryDedicatedAllocateInfo;
  dedicated_info.pNext = nullptr;
  dedicated_info.image = image_handle;
  dedicated_info.buffer = 0;

  VkImportAndroidHardwareBufferInfoANDROIDCompat import_ahb_info = {};
  import_ahb_info.sType =
      kVkStructureTypeImportAndroidHardwareBufferInfoANDROID;
  import_ahb_info.pNext = &dedicated_info;
  import_ahb_info.buffer = hardware_buffer->GetHandle();

  VkMemoryAllocateInfoCompat alloc_info = {};
  alloc_info.sType = kVkStructureTypeMemoryAllocateInfo;
  alloc_info.pNext = &import_ahb_info;
  alloc_info.allocationSize = ahb_props.allocationSize;
  alloc_info.memoryTypeIndex = FindFirstSetBitIndex(ahb_props.memoryTypeBits);

  auto allocate_memory =
      reinterpret_cast<VkAllocateMemory_fn>(vk_allocate_memory_fn_);
  void* device_memory = nullptr;
  if (allocate_memory(vk_device_, &alloc_info, nullptr, &device_memory) != 0) {
    if (vk_destroy_image_fn_) {
      auto destroy_image =
          reinterpret_cast<VkDestroyImage_fn>(vk_destroy_image_fn_);
      destroy_image(vk_device_, image_handle, nullptr);
    }
    return nullptr;
  }

  auto bind_memory =
      reinterpret_cast<VkBindImageMemory_fn>(vk_bind_image_memory_fn_);
  if (bind_memory(vk_device_, image_handle, device_memory, 0) != 0) {
    if (vk_free_memory_fn_ && device_memory) {
      auto free_memory = reinterpret_cast<VkFreeMemory_fn>(vk_free_memory_fn_);
      free_memory(vk_device_, device_memory, nullptr);
    }
    if (vk_destroy_image_fn_) {
      auto destroy_image =
          reinterpret_cast<VkDestroyImage_fn>(vk_destroy_image_fn_);
      destroy_image(vk_device_, image_handle, nullptr);
    }
    return nullptr;
  }

  imported_allocations_[image_handle] =
      ImportedAllocation{image_handle, device_memory, 1};
  return std::make_unique<DefaultAndroidVulkanExternalTexture>(
      vk_desc, image_handle, device_memory, /*owns_handle=*/true,
      shared_from_this());
}

void DefaultAndroidVulkanTextureProvider::Acquire(uint64_t image_handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanTextureProvider::Acquire");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = imported_allocations_.find(image_handle);
  if (it != imported_allocations_.end()) {
    it->second.ref_count++;
  }
}

void DefaultAndroidVulkanTextureProvider::Release(uint64_t image_handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanTextureProvider::Release");
  EnsureLoaded();
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = imported_allocations_.find(image_handle);
  if (it != imported_allocations_.end()) {
    it->second.ref_count--;
    if (it->second.ref_count <= 0) {
      if (vk_device_ && vk_destroy_image_fn_ && it->second.image != 0) {
        auto destroy_image =
            reinterpret_cast<VkDestroyImage_fn>(vk_destroy_image_fn_);
        destroy_image(vk_device_, it->second.image, nullptr);
      }
      if (vk_device_ && vk_free_memory_fn_ &&
          it->second.device_memory != nullptr) {
        auto free_memory =
            reinterpret_cast<VkFreeMemory_fn>(vk_free_memory_fn_);
        free_memory(vk_device_, it->second.device_memory, nullptr);
      }
      imported_allocations_.erase(it);
    }
  }
}

void* DefaultAndroidVulkanTextureProvider::ResolveVulkanSymbol(
    const char* name) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanTextureProvider::ResolveVulkanSymbol");
  EnsureLoaded();
  if (libvulkan_ && name) {
    return libvulkan_->ResolveSymbol(name);
  }
  return nullptr;
}

// =============================================================================
// InMemoryAndroidVulkanExternalTexture Implementation
// =============================================================================

InMemoryAndroidVulkanExternalTexture::InMemoryAndroidVulkanExternalTexture(
    AndroidVulkanImageDesc desc,
    uint64_t image_handle,
    void* device_memory,
    bool owns_handle,
    std::shared_ptr<InMemoryAndroidVulkanTextureProvider> provider)
    : desc_(desc),
      image_handle_(image_handle),
      device_memory_(device_memory),
      owns_handle_(owns_handle),
      provider_(std::move(provider)) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::"
               "InMemoryAndroidVulkanExternalTexture");
  if (desc_.ycbcr_conversion.has_value()) {
    cached_c_ycbcr_conversion_info_ =
        desc_.ycbcr_conversion.value().ToFlutterYcbcrConversionInfo();
    has_cached_c_ycbcr_conversion_info_ = true;
  }
  size_t total_size =
      static_cast<size_t>(desc_.width) * desc_.height * kRgbaBytesPerPixel;
  if (total_size == 0) {
    total_size = kFallbackMockImageSizeBytes;
  }
  backing_data_.resize(total_size, 0);
}

InMemoryAndroidVulkanExternalTexture::~InMemoryAndroidVulkanExternalTexture() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::"
               "~InMemoryAndroidVulkanExternalTexture");
  if (owns_handle_ && provider_ && image_handle_ != 0) {
    provider_->Release(image_handle_);
  }
}

const AndroidVulkanImageDesc&
InMemoryAndroidVulkanExternalTexture::GetDescription() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::GetDescription");
  return desc_;
}

uint64_t InMemoryAndroidVulkanExternalTexture::GetImageHandle() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::GetImageHandle");
  return image_handle_;
}

void* InMemoryAndroidVulkanExternalTexture::GetDeviceMemory() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::GetDeviceMemory");
  return device_memory_;
}

uint32_t InMemoryAndroidVulkanExternalTexture::GetImageLayout() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::GetImageLayout");
  std::lock_guard<std::mutex> lock(mutex_);
  return desc_.image_layout;
}

void InMemoryAndroidVulkanExternalTexture::SetImageLayout(uint32_t layout) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::SetImageLayout");
  std::lock_guard<std::mutex> lock(mutex_);
  desc_.image_layout = layout;
}

const AndroidVulkanYcbcrConversionDesc*
InMemoryAndroidVulkanExternalTexture::GetYcbcrConversionDesc() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::GetYcbcrConversionDesc");
  if (desc_.ycbcr_conversion.has_value()) {
    return &desc_.ycbcr_conversion.value();
  }
  return nullptr;
}

bool InMemoryAndroidVulkanExternalTexture::HasYcbcrConversion() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::HasYcbcrConversion");
  return desc_.ycbcr_conversion.has_value();
}

bool InMemoryAndroidVulkanExternalTexture::IsValid() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanExternalTexture::IsValid");
  return desc_.IsValid() && image_handle_ != 0;
}

void InMemoryAndroidVulkanExternalTexture::Acquire() {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanExternalTexture::Acquire");
  std::lock_guard<std::mutex> lock(mutex_);
  ref_count_++;
}

void InMemoryAndroidVulkanExternalTexture::Release() {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanExternalTexture::Release");
  std::lock_guard<std::mutex> lock(mutex_);
  if (ref_count_ > 0) {
    ref_count_--;
  }
}

FlutterVulkanExternalTexture
InMemoryAndroidVulkanExternalTexture::ToExternalTexture(
    void* user_data,
    VoidCallback destruction_callback) const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::ToExternalTexture");
  FlutterVulkanExternalTexture ext_texture = {};
  PopulateExternalTexture(&ext_texture, user_data, destruction_callback);
  return ext_texture;
}

bool InMemoryAndroidVulkanExternalTexture::PopulateExternalTexture(
    FlutterVulkanExternalTexture* texture_out,
    void* user_data,
    VoidCallback destruction_callback) const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::PopulateExternalTexture");
  if (!texture_out || !IsValid()) {
    return false;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  std::memset(texture_out, 0, sizeof(FlutterVulkanExternalTexture));
  texture_out->struct_size = sizeof(FlutterVulkanExternalTexture);
  texture_out->width = desc_.width;
  texture_out->height = desc_.height;
  texture_out->image = image_handle_;
  texture_out->format = desc_.format;
  if (has_cached_c_ycbcr_conversion_info_) {
    texture_out->ycbcr_conversion_info = &cached_c_ycbcr_conversion_info_;
  } else {
    texture_out->ycbcr_conversion_info = nullptr;
  }
  texture_out->user_data = user_data;
  texture_out->destruction_callback = destruction_callback;
  return true;
}

FlutterVulkanImage InMemoryAndroidVulkanExternalTexture::ToFlutterVulkanImage()
    const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::ToFlutterVulkanImage");
  FlutterVulkanImage vk_image = {};
  vk_image.struct_size = sizeof(FlutterVulkanImage);
  vk_image.image = image_handle_;
  vk_image.format = desc_.format;
  return vk_image;
}

uint8_t* InMemoryAndroidVulkanExternalTexture::GetBackingData() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::GetBackingData");
  std::lock_guard<std::mutex> lock(mutex_);
  return backing_data_.data();
}

size_t InMemoryAndroidVulkanExternalTexture::GetBackingDataSize() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::GetBackingDataSize");
  std::lock_guard<std::mutex> lock(mutex_);
  return backing_data_.size();
}

int32_t InMemoryAndroidVulkanExternalTexture::GetRefCount() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanExternalTexture::GetRefCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return ref_count_;
}

// =============================================================================
// InMemoryAndroidVulkanTextureProvider Implementation
// =============================================================================

InMemoryAndroidVulkanTextureProvider::InMemoryAndroidVulkanTextureProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::"
               "InMemoryAndroidVulkanTextureProvider");
}

InMemoryAndroidVulkanTextureProvider::~InMemoryAndroidVulkanTextureProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::"
               "~InMemoryAndroidVulkanTextureProvider");
}

bool InMemoryAndroidVulkanTextureProvider::IsAvailable() const {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanTextureProvider::IsAvailable");
  std::lock_guard<std::mutex> lock(mutex_);
  return is_available_;
}

bool InMemoryAndroidVulkanTextureProvider::IsSupported(
    const AndroidVulkanImageDesc& desc) const {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanTextureProvider::IsSupported");
  std::lock_guard<std::mutex> lock(mutex_);
  return is_available_ && desc.IsValid();
}

std::unique_ptr<AndroidVulkanExternalTexture>
InMemoryAndroidVulkanTextureProvider::AllocateTexture(
    const AndroidVulkanImageDesc& desc) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::AllocateTexture");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_available_ || allocation_failure_ || !desc.IsValid()) {
    return nullptr;
  }

  uint64_t handle = next_image_handle_++;
  allocation_count_++;

  MockEntry entry;
  entry.desc = desc;
  entry.ref_count = 1;
  size_t size =
      static_cast<size_t>(desc.width) * desc.height * kRgbaBytesPerPixel;
  entry.data.resize(size > 0 ? size : kFallbackMockImageSizeBytes, 0);
  mock_entries_[handle] = std::move(entry);

  return std::make_unique<InMemoryAndroidVulkanExternalTexture>(
      desc, handle, nullptr, /*owns_handle=*/true, shared_from_this());
}

std::unique_ptr<AndroidVulkanExternalTexture>
InMemoryAndroidVulkanTextureProvider::CreateFromNativeImage(
    uint64_t image_handle,
    const AndroidVulkanImageDesc& desc,
    bool take_ownership) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::CreateFromNativeImage");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_available_ || image_handle == 0 || !desc.IsValid()) {
    return nullptr;
  }

  if (mock_entries_.find(image_handle) == mock_entries_.end()) {
    MockEntry entry;
    entry.desc = desc;
    entry.ref_count = 1;
    size_t size =
        static_cast<size_t>(desc.width) * desc.height * kRgbaBytesPerPixel;
    entry.data.resize(size > 0 ? size : kFallbackMockImageSizeBytes, 0);
    mock_entries_[image_handle] = std::move(entry);
  }

  return std::make_unique<InMemoryAndroidVulkanExternalTexture>(
      desc, image_handle, nullptr, take_ownership, shared_from_this());
}

std::unique_ptr<AndroidVulkanExternalTexture>
InMemoryAndroidVulkanTextureProvider::CreateFromAHardwareBuffer(
    const AndroidHardwareBuffer* hardware_buffer,
    const AndroidVulkanYcbcrConversionDesc* ycbcr_desc) {
  TRACE_EVENT0(
      "flutter",
      "InMemoryAndroidVulkanTextureProvider::CreateFromAHardwareBuffer");
  if (!hardware_buffer || !hardware_buffer->IsValid()) {
    return nullptr;
  }

  const auto& ahb_desc = hardware_buffer->GetDescription();
  AndroidVulkanImageDesc vk_desc;
  vk_desc.width = ahb_desc.width;
  vk_desc.height = ahb_desc.height;
  vk_desc.image_layout =
      static_cast<uint32_t>(AndroidVulkanImageLayout::kShaderReadOnlyOptimal);

  if (ycbcr_desc != nullptr) {
    vk_desc.format = ycbcr_desc->format;
    vk_desc.ycbcr_conversion = *ycbcr_desc;
  } else if (ahb_desc.format ==
                 static_cast<uint32_t>(
                     AndroidHardwareBufferFormat::kY8Cb8Cr8420) ||
             ahb_desc.format == static_cast<uint32_t>(
                                    AndroidHardwareBufferFormat::kYCbCrP010) ||
             ahb_desc.format == static_cast<uint32_t>(
                                    AndroidHardwareBufferFormat::kYCbCrP210)) {
    vk_desc.format = static_cast<uint32_t>(AndroidVulkanFormat::kUndefined);
    vk_desc.ycbcr_conversion = AndroidVulkanYcbcrConversionDesc::MakeExternal(
        hardware_buffer->GetId());
  } else {
    vk_desc.format = static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm);
  }

  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_available_ || allocation_failure_) {
    return nullptr;
  }
  uint64_t handle = next_image_handle_++;
  allocation_count_++;

  MockEntry entry;
  entry.desc = vk_desc;
  entry.ref_count = 1;
  mock_entries_[handle] = std::move(entry);

  return std::make_unique<InMemoryAndroidVulkanExternalTexture>(
      vk_desc, handle, nullptr, /*owns_handle=*/true, shared_from_this());
}

void InMemoryAndroidVulkanTextureProvider::Acquire(uint64_t image_handle) {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanTextureProvider::Acquire");
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = mock_entries_.find(image_handle);
  if (it != mock_entries_.end()) {
    it->second.ref_count++;
  }
}

void InMemoryAndroidVulkanTextureProvider::Release(uint64_t image_handle) {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanTextureProvider::Release");
  std::lock_guard<std::mutex> lock(mutex_);
  release_count_++;
  auto it = mock_entries_.find(image_handle);
  if (it != mock_entries_.end()) {
    it->second.ref_count--;
    if (it->second.ref_count <= 0) {
      mock_entries_.erase(it);
    }
  }
}

void* InMemoryAndroidVulkanTextureProvider::ResolveVulkanSymbol(
    const char* name) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::ResolveVulkanSymbol");
  if (!name) {
    return nullptr;
  }
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = mock_symbols_.find(name);
  if (it != mock_symbols_.end()) {
    return it->second;
  }
  return nullptr;
}

void InMemoryAndroidVulkanTextureProvider::SetAvailable(bool available) {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanTextureProvider::SetAvailable");
  std::lock_guard<std::mutex> lock(mutex_);
  is_available_ = available;
}

void InMemoryAndroidVulkanTextureProvider::SetAllocationFailure(bool fail) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::SetAllocationFailure");
  std::lock_guard<std::mutex> lock(mutex_);
  allocation_failure_ = fail;
}

size_t InMemoryAndroidVulkanTextureProvider::GetAllocationCount() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::GetAllocationCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return allocation_count_;
}

size_t InMemoryAndroidVulkanTextureProvider::GetReleaseCount() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::GetReleaseCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return release_count_;
}

size_t InMemoryAndroidVulkanTextureProvider::GetActiveTextureCount() const {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::GetActiveTextureCount");
  std::lock_guard<std::mutex> lock(mutex_);
  return mock_entries_.size();
}

void InMemoryAndroidVulkanTextureProvider::RegisterMockImage(
    uint64_t image_handle,
    const AndroidVulkanImageDesc& desc) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanTextureProvider::RegisterMockImage");
  std::lock_guard<std::mutex> lock(mutex_);
  MockEntry entry;
  entry.desc = desc;
  entry.ref_count = 1;
  size_t size =
      static_cast<size_t>(desc.width) * desc.height * kRgbaBytesPerPixel;
  entry.data.resize(size > 0 ? size : kFallbackMockImageSizeBytes, 0);
  mock_entries_[image_handle] = std::move(entry);
}

void InMemoryAndroidVulkanTextureProvider::SetSymbol(const std::string& name,
                                                     void* symbol_ptr) {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanTextureProvider::SetSymbol");
  std::lock_guard<std::mutex> lock(mutex_);
  mock_symbols_[name] = symbol_ptr;
}

void InMemoryAndroidVulkanTextureProvider::Clear() {
  TRACE_EVENT0("flutter", "InMemoryAndroidVulkanTextureProvider::Clear");
  std::lock_guard<std::mutex> lock(mutex_);
  mock_entries_.clear();
  mock_symbols_.clear();
  allocation_count_ = 0;
  release_count_ = 0;
}

// =============================================================================
// SurfaceTexture GL-to-AHB Blitter Implementation
// =============================================================================

void TransformSurfaceTextureUv(const float* uv_transform,
                               float u,
                               float v,
                               float* out_u,
                               float* out_v) {
  if (!out_u || !out_v) {
    return;
  }
  if (!uv_transform) {
    *out_u = u;
    *out_v = v;
    return;
  }
  *out_u = uv_transform[kUvMatCol0Row0] * u + uv_transform[kUvMatCol1Row0] * v +
           uv_transform[kUvMatCol3Row0];
  *out_v = uv_transform[kUvMatCol0Row1] * u + uv_transform[kUvMatCol1Row1] * v +
           uv_transform[kUvMatCol3Row1];
}

SurfaceTextureGlToAhbBlitter::SurfaceTextureGlToAhbBlitter(
    std::shared_ptr<AndroidHardwareBufferProvider> ahb_provider,
    std::shared_ptr<AndroidVulkanTextureProvider> vk_provider)
    : ahb_provider_(std::move(ahb_provider)),
      vk_provider_(std::move(vk_provider)) {}

SurfaceTextureGlToAhbBlitter::~SurfaceTextureGlToAhbBlitter() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(mutex_);
  if (egl_display_ != nullptr && egl_display_ != EGL_NO_DISPLAY) {
    if (egl_context_ != nullptr && egl_context_ != EGL_NO_CONTEXT) {
      if (gl_program_ != 0 && eglGetCurrentContext() == egl_context_) {
        glDeleteProgram(gl_program_);
        gl_program_ = 0;
      }
      eglDestroyContext(egl_display_, egl_context_);
      egl_context_ = nullptr;
    }
    if (egl_surface_ != nullptr && egl_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(egl_display_, egl_surface_);
      egl_surface_ = nullptr;
    }
  }
#else
  (void)egl_display_;
  (void)egl_surface_;
  (void)egl_context_;
  (void)program_context_;
  (void)gl_program_;
  (void)texture_uniform_location_;
  (void)uv_transform_uniform_location_;
#endif
}

bool SurfaceTextureGlToAhbBlitter::EnsureEglContextLocked() {
#if FML_OS_ANDROID
  if (egl_display_ != nullptr && egl_display_ != EGL_NO_DISPLAY &&
      egl_surface_ != nullptr && egl_surface_ != EGL_NO_SURFACE &&
      egl_context_ != nullptr && egl_context_ != EGL_NO_CONTEXT) {
    return true;
  }

  EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (display == EGL_NO_DISPLAY) {
    return false;
  }
  EGLint major = 0;
  EGLint minor = 0;
  if (!eglInitialize(display, &major, &minor)) {
    return false;
  }

  // 8 bits per RGBA channel for offscreen 1x1 Pbuffer configuration.
  constexpr EGLint kColorBits = 8;
  const EGLint config_attribs[] = {
      EGL_RENDERABLE_TYPE,
      EGL_OPENGL_ES2_BIT,
      EGL_SURFACE_TYPE,
      EGL_PBUFFER_BIT,
      EGL_RED_SIZE,
      kColorBits,
      EGL_GREEN_SIZE,
      kColorBits,
      EGL_BLUE_SIZE,
      kColorBits,
      EGL_ALPHA_SIZE,
      kColorBits,
      EGL_DEPTH_SIZE,
      0,
      EGL_STENCIL_SIZE,
      0,
      EGL_NONE,
  };
  EGLConfig config = nullptr;
  EGLint num_configs = 0;
  if (!eglChooseConfig(display, config_attribs, &config, 1, &num_configs) ||
      num_configs < 1) {
    return false;
  }

  constexpr EGLint kPbufferSize = 1;
  const EGLint pbuffer_attribs[] = {
      EGL_WIDTH, kPbufferSize, EGL_HEIGHT, kPbufferSize, EGL_NONE,
  };
  EGLSurface surface =
      eglCreatePbufferSurface(display, config, pbuffer_attribs);
  if (surface == EGL_NO_SURFACE) {
    return false;
  }

  constexpr EGLint kGlesClientVersion = 2;
  const EGLint context_attribs[] = {
      EGL_CONTEXT_CLIENT_VERSION,
      kGlesClientVersion,
      EGL_NONE,
  };
  EGLContext context =
      eglCreateContext(display, config, EGL_NO_CONTEXT, context_attribs);
  if (context == EGL_NO_CONTEXT) {
    eglDestroySurface(display, surface);
    return false;
  }

  egl_display_ = display;
  egl_surface_ = surface;
  egl_context_ = context;
  return true;
#else
  return false;
#endif
}

bool SurfaceTextureGlToAhbBlitter::MakeEglContextCurrent() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(mutex_);
  if (!EnsureEglContextLocked()) {
    return false;
  }
  return eglMakeCurrent(egl_display_, egl_surface_, egl_surface_,
                        egl_context_) == EGL_TRUE;
#else
  return false;
#endif
}

void SurfaceTextureGlToAhbBlitter::ClearEglContextCurrent() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(mutex_);
  if (egl_display_ != nullptr && egl_display_ != EGL_NO_DISPLAY) {
    eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                   EGL_NO_CONTEXT);
  }
#endif
}

bool SurfaceTextureGlToAhbBlitter::EnsureGlProgramLocked() {
#if FML_OS_ANDROID
  EGLContext current_ctx = eglGetCurrentContext();
  if (current_ctx == EGL_NO_CONTEXT) {
    return false;
  }
  if (gl_program_ != 0 && program_context_ == current_ctx) {
    return true;
  }

  static constexpr const char* kVertShaderSource = R"(#version 100
precision mediump float;
attribute vec2 aPosition;
attribute vec2 aTexCoord;
varying vec2 vTexCoord;
void main() {
  gl_Position = vec4(aPosition, 0.0, 1.0);
  vTexCoord = aTexCoord;
}
)";
  static constexpr const char* kFragShaderSource = R"(#version 100
#extension GL_OES_EGL_image_external : require
precision mediump float;
uniform samplerExternalOES uTexture;
uniform mat4 uUVTransformation;
varying vec2 vTexCoord;
void main() {
  vec2 texture_coords = (uUVTransformation * vec4(vTexCoord, 0.0, 1.0)).xy;
  gl_FragColor = texture2D(uTexture, texture_coords);
}
)";

  GLuint vert = glCreateShader(GL_VERTEX_SHADER);
  GLuint frag = glCreateShader(GL_FRAGMENT_SHADER);
  glShaderSource(vert, 1, &kVertShaderSource, nullptr);
  glShaderSource(frag, 1, &kFragShaderSource, nullptr);
  glCompileShader(vert);
  glCompileShader(frag);

  GLint vert_ok = GL_FALSE;
  GLint frag_ok = GL_FALSE;
  glGetShaderiv(vert, GL_COMPILE_STATUS, &vert_ok);
  glGetShaderiv(frag, GL_COMPILE_STATUS, &frag_ok);

  GLuint program = 0;
  if (vert_ok == GL_TRUE && frag_ok == GL_TRUE) {
    program = glCreateProgram();
    glAttachShader(program, vert);
    glAttachShader(program, frag);
    glBindAttribLocation(program, 0, "aPosition");
    glBindAttribLocation(program, 1, "aTexCoord");
    glLinkProgram(program);
    GLint link_ok = GL_FALSE;
    glGetProgramiv(program, GL_LINK_STATUS, &link_ok);
    if (link_ok == GL_TRUE) {
      texture_uniform_location_ = glGetUniformLocation(program, "uTexture");
      uv_transform_uniform_location_ =
          glGetUniformLocation(program, "uUVTransformation");
    } else {
      glDeleteProgram(program);
      program = 0;
    }
  }
  glDeleteShader(vert);
  glDeleteShader(frag);

  if (program == 0) {
    return false;
  }
  gl_program_ = program;
  program_context_ = current_ctx;
  return true;
#else
  return false;
#endif
}

bool SurfaceTextureGlToAhbBlitter::PerformGlBlitToAhbLocked(
    uint32_t oes_texture_id,
    void* ahb_handle,
    size_t width,
    size_t height,
    const float* uv_matrix) {
#if FML_OS_ANDROID
  if (oes_texture_id == 0 || ahb_handle == nullptr || width == 0 ||
      height == 0 || uv_matrix == nullptr) {
    return false;
  }

  using PFN_eglGetNativeClientBufferANDROID =
      EGLClientBuffer (*)(const struct AHardwareBuffer*);
  using PFN_eglCreateImageKHR = EGLImageKHR (*)(EGLDisplay, EGLContext, EGLenum,
                                                EGLClientBuffer, const EGLint*);
  using PFN_eglDestroyImageKHR = EGLBoolean (*)(EGLDisplay, EGLImageKHR);
  using PFN_glEGLImageTargetTexture2DOES = void (*)(GLenum, GLeglImageOES);

  static auto egl_get_native_client_buffer_fn =
      reinterpret_cast<PFN_eglGetNativeClientBufferANDROID>(
          eglGetProcAddress("eglGetNativeClientBufferANDROID"));
  static auto egl_create_image_khr_fn = reinterpret_cast<PFN_eglCreateImageKHR>(
      eglGetProcAddress("eglCreateImageKHR"));
  static auto egl_destroy_image_khr_fn =
      reinterpret_cast<PFN_eglDestroyImageKHR>(
          eglGetProcAddress("eglDestroyImageKHR"));
  static auto gl_egl_image_target_texture_2d_oes_fn =
      reinterpret_cast<PFN_glEGLImageTargetTexture2DOES>(
          eglGetProcAddress("glEGLImageTargetTexture2DOES"));

  if (!egl_get_native_client_buffer_fn || !egl_create_image_khr_fn ||
      !egl_destroy_image_khr_fn || !gl_egl_image_target_texture_2d_oes_fn) {
    return false;
  }

  EGLDisplay active_display = eglGetCurrentDisplay();
  EGLContext active_context = eglGetCurrentContext();
  bool made_internal_context_current = false;
  if (active_context == EGL_NO_CONTEXT || active_display == EGL_NO_DISPLAY) {
    if (!EnsureEglContextLocked()) {
      return false;
    }
    if (!eglMakeCurrent(egl_display_, egl_surface_, egl_surface_,
                        egl_context_)) {
      return false;
    }
    active_display = egl_display_;
    made_internal_context_current = true;
  }

  auto restore_egl = [&]() {
    if (made_internal_context_current && egl_display_ != nullptr &&
        egl_display_ != EGL_NO_DISPLAY) {
      eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                     EGL_NO_CONTEXT);
    }
  };

  EGLClientBuffer client_buf = egl_get_native_client_buffer_fn(
      static_cast<const struct AHardwareBuffer*>(ahb_handle));
  if (client_buf == nullptr) {
    restore_egl();
    return false;
  }

  // EGL_NATIVE_BUFFER_ANDROID = 0x3140.
  constexpr EGLenum kEglNativeBufferAndroid = 0x3140;
  EGLImageKHR dst_egl_image =
      egl_create_image_khr_fn(active_display, EGL_NO_CONTEXT,
                              kEglNativeBufferAndroid, client_buf, nullptr);
  if (dst_egl_image == EGL_NO_IMAGE_KHR) {
    restore_egl();
    return false;
  }

  if (!EnsureGlProgramLocked()) {
    egl_destroy_image_khr_fn(active_display, dst_egl_image);
    restore_egl();
    return false;
  }

  // Save current GL state before blitting.
  GLint prev_fbo = 0;
  GLint prev_program = 0;
  GLint prev_active_tex = GL_TEXTURE0;
  GLint prev_tex_2d = 0;
  GLint prev_tex_oes = 0;
  GLint prev_array_buf = 0;
  GLint prev_viewport[4] = {0, 0, 0, 0};
  const GLboolean prev_blend = glIsEnabled(GL_BLEND);
  const GLboolean prev_scissor = glIsEnabled(GL_SCISSOR_TEST);
  const GLboolean prev_dither = glIsEnabled(GL_DITHER);
  const GLboolean prev_cull = glIsEnabled(GL_CULL_FACE);

  constexpr GLenum kGlTextureExternalOes = 0x8D65;
  constexpr GLenum kGlTextureBindingExternalOes = 0x8D67;

  glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prev_fbo);
  glGetIntegerv(GL_CURRENT_PROGRAM, &prev_program);
  glGetIntegerv(GL_ACTIVE_TEXTURE, &prev_active_tex);
  glGetIntegerv(GL_TEXTURE_BINDING_2D, &prev_tex_2d);
  glGetIntegerv(kGlTextureBindingExternalOes, &prev_tex_oes);
  glGetIntegerv(GL_ARRAY_BUFFER_BINDING, &prev_array_buf);
  glGetIntegerv(GL_VIEWPORT, prev_viewport);

  GLuint dst_gl_tex = 0;
  glGenTextures(1, &dst_gl_tex);
  glBindTexture(GL_TEXTURE_2D, dst_gl_tex);
  gl_egl_image_target_texture_2d_oes_fn(
      GL_TEXTURE_2D, static_cast<GLeglImageOES>(dst_egl_image));

  GLuint fbo = 0;
  glGenFramebuffers(1, &fbo);
  glBindFramebuffer(GL_FRAMEBUFFER, fbo);
  glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                         dst_gl_tex, 0);

  const bool fbo_complete =
      (glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
  if (fbo_complete) {
    glDisable(GL_BLEND);
    glDisable(GL_SCISSOR_TEST);
    glDisable(GL_DITHER);
    glDisable(GL_CULL_FACE);
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
    glViewport(0, 0, static_cast<GLsizei>(width), static_cast<GLsizei>(height));

    glUseProgram(gl_program_);

    struct QuadVertex {
      float x;
      float y;
      float u;
      float v;
    };
    static constexpr QuadVertex kVertices[] = {
        {-1.0f, -1.0f, 0.0f, 1.0f},
        {-1.0f, +1.0f, 0.0f, 0.0f},
        {+1.0f, +1.0f, 1.0f, 0.0f},
        {+1.0f, -1.0f, 1.0f, 1.0f},
    };
    GLuint vbo = 0;
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(kVertices), kVertices, GL_STATIC_DRAW);

    constexpr GLint kVec2Components = 2;
    glEnableVertexAttribArray(0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(0, kVec2Components, GL_FLOAT, GL_FALSE,
                          sizeof(QuadVertex),
                          reinterpret_cast<void*>(offsetof(QuadVertex, x)));
    glVertexAttribPointer(1, kVec2Components, GL_FLOAT, GL_FALSE,
                          sizeof(QuadVertex),
                          reinterpret_cast<void*>(offsetof(QuadVertex, u)));

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(kGlTextureExternalOes, oes_texture_id);
    glTexParameteri(kGlTextureExternalOes, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(kGlTextureExternalOes, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(kGlTextureExternalOes, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(kGlTextureExternalOes, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(texture_uniform_location_, 0);
    glUniformMatrix4fv(uv_transform_uniform_location_, 1, GL_FALSE, uv_matrix);

    constexpr GLsizei kQuadVertexCount = 4;
    glDrawArrays(GL_TRIANGLE_FAN, 0, kQuadVertexCount);
    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glFlush();
    glFinish();

    glDeleteBuffers(1, &vbo);
  }

  // Restore saved GL state.
  glBindFramebuffer(GL_FRAMEBUFFER, static_cast<GLuint>(prev_fbo));
  glDeleteFramebuffers(1, &fbo);
  glBindTexture(GL_TEXTURE_2D, static_cast<GLuint>(prev_tex_2d));
  glDeleteTextures(1, &dst_gl_tex);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(kGlTextureExternalOes, static_cast<GLuint>(prev_tex_oes));
  glActiveTexture(static_cast<GLenum>(prev_active_tex));
  glBindBuffer(GL_ARRAY_BUFFER, static_cast<GLuint>(prev_array_buf));
  glUseProgram(static_cast<GLuint>(prev_program));
  glViewport(prev_viewport[0], prev_viewport[1], prev_viewport[2],
             prev_viewport[3]);
  if (prev_blend) {
    glEnable(GL_BLEND);
  }
  if (prev_scissor) {
    glEnable(GL_SCISSOR_TEST);
  }
  if (prev_dither) {
    glEnable(GL_DITHER);
  }
  if (prev_cull) {
    glEnable(GL_CULL_FACE);
  }

  egl_destroy_image_khr_fn(active_display, dst_egl_image);
  restore_egl();
  return fbo_complete;
#else
  (void)oes_texture_id;
  (void)ahb_handle;
  (void)width;
  (void)height;
  (void)uv_matrix;
  return false;
#endif
}

std::unique_ptr<AndroidVulkanExternalTexture>
SurfaceTextureGlToAhbBlitter::BlitAndImport(int64_t texture_id,
                                            uint32_t oes_texture_id,
                                            size_t width,
                                            size_t height,
                                            const float* uv_transform) {
  TRACE_EVENT0("flutter", "SurfaceTextureGlToAhbBlitter::BlitAndImport");
  if (!ahb_provider_ || !vk_provider_ || oes_texture_id == 0 || width == 0 ||
      height == 0) {
    return nullptr;
  }

  std::lock_guard<std::mutex> lock(mutex_);
  auto& cached_buf = cached_buffers_[texture_id];
  if (!cached_buf ||
      cached_buf->GetDescription().width != static_cast<uint32_t>(width) ||
      cached_buf->GetDescription().height != static_cast<uint32_t>(height)) {
    AndroidHardwareBufferDesc desc = AndroidHardwareBufferDesc::MakeRGBA8(
        static_cast<uint32_t>(width), static_cast<uint32_t>(height),
        AndroidHardwareBufferUsage::kGpuSampledImage |
            AndroidHardwareBufferUsage::kGpuFramebuffer);
    cached_buf = ahb_provider_->Allocate(desc);
  }
  if (!cached_buf || !cached_buf->IsValid()) {
    return nullptr;
  }

  std::array<float, kOpenGLUvTransformMatrixElementCount> matrix = {};
  if (uv_transform != nullptr) {
    std::memcpy(matrix.data(), uv_transform,
                sizeof(float) * kOpenGLUvTransformMatrixElementCount);
  } else {
    matrix[kUvMatCol0Row0] = 1.0f;
    matrix[kUvMatCol1Row1] = 1.0f;
    matrix[kUvMatCol2Row2] = 1.0f;
    matrix[kUvMatCol3Row3] = 1.0f;
  }
  last_uv_transforms_[texture_id] = matrix;

  PerformGlBlitToAhbLocked(oes_texture_id, cached_buf->GetHandle(), width,
                           height, matrix.data());

  return vk_provider_->CreateFromAHardwareBuffer(cached_buf.get(), nullptr);
}

void SurfaceTextureGlToAhbBlitter::ReleaseTexture(int64_t texture_id) {
  std::lock_guard<std::mutex> lock(mutex_);
  cached_buffers_.erase(texture_id);
  last_uv_transforms_.erase(texture_id);
}

std::optional<std::array<float, kOpenGLUvTransformMatrixElementCount>>
SurfaceTextureGlToAhbBlitter::GetLastBakedUvTransform(
    int64_t texture_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = last_uv_transforms_.find(texture_id);
  if (it != last_uv_transforms_.end()) {
    return it->second;
  }
  return std::nullopt;
}

const AndroidHardwareBuffer*
SurfaceTextureGlToAhbBlitter::GetCachedHardwareBuffer(
    int64_t texture_id) const {
  std::lock_guard<std::mutex> lock(mutex_);
  auto it = cached_buffers_.find(texture_id);
  if (it != cached_buffers_.end()) {
    return it->second.get();
  }
  return nullptr;
}

}  // namespace android
}  // namespace flutter
