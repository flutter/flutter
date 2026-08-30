// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_vulkan_texture.h"

#include <cstring>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"

namespace flutter {
namespace android {

// Vulkan C function pointer signatures for dynamic virtualization
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
  return desc_.image_layout;
}

void DefaultAndroidVulkanExternalTexture::SetImageLayout(uint32_t layout) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanExternalTexture::SetImageLayout");
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
  ext_texture.struct_size = sizeof(FlutterVulkanExternalTexture);
  ext_texture.width = desc_.width;
  ext_texture.height = desc_.height;
  ext_texture.image = image_handle_;
  ext_texture.format = desc_.format;
  ext_texture.image_layout = desc_.image_layout;
  if (has_cached_c_ycbcr_conversion_info_) {
    ext_texture.ycbcr_conversion_info = &cached_c_ycbcr_conversion_info_;
  } else {
    ext_texture.ycbcr_conversion_info = nullptr;
  }
  ext_texture.user_data = user_data;
  ext_texture.destruction_callback = destruction_callback;
  return ext_texture;
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
    std::shared_ptr<OSLibraryLoader> library_loader)
    : library_loader_(library_loader
                          ? std::move(library_loader)
                          : FlutterEmbedderNative::GetDefaultLibraryLoader()) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanTextureProvider::"
               "DefaultAndroidVulkanTextureProvider");
}

DefaultAndroidVulkanTextureProvider::~DefaultAndroidVulkanTextureProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanTextureProvider::"
               "~DefaultAndroidVulkanTextureProvider");
}

void DefaultAndroidVulkanTextureProvider::EnsureLoaded() const {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanTextureProvider::EnsureLoaded");
  std::lock_guard<std::mutex> lock(mutex_);
  if (loaded_) {
    return;
  }
  if (!library_loader_) {
    library_loader_ = FlutterEmbedderNative::GetDefaultLibraryLoader();
  }
  if (!library_loader_) {
    loaded_ = true;
    return;
  }

  libvulkan_ = library_loader_->LoadDynamicLibrary("libvulkan.so");
  if (libvulkan_ && libvulkan_->IsValid()) {
    get_instance_proc_addr_fn_ =
        libvulkan_->ResolveSymbol("vkGetInstanceProcAddr");
    create_image_fn_ = libvulkan_->ResolveSymbol("vkCreateImage");
    destroy_image_fn_ = libvulkan_->ResolveSymbol("vkDestroyImage");
    get_image_memory_requirements_fn_ =
        libvulkan_->ResolveSymbol("vkGetImageMemoryRequirements");
    allocate_memory_fn_ = libvulkan_->ResolveSymbol("vkAllocateMemory");
    free_memory_fn_ = libvulkan_->ResolveSymbol("vkFreeMemory");
    bind_image_memory_fn_ = libvulkan_->ResolveSymbol("vkBindImageMemory");
    create_sampler_ycbcr_conversion_fn_ =
        libvulkan_->ResolveSymbol("vkCreateSamplerYcbcrConversion");
    destroy_sampler_ycbcr_conversion_fn_ =
        libvulkan_->ResolveSymbol("vkDestroySamplerYcbcrConversion");
    get_ahb_properties_fn_ = libvulkan_->ResolveSymbol(
        "vkGetAndroidHardwareBufferPropertiesANDROID");

    if (get_instance_proc_addr_fn_ != nullptr) {
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
  if (!is_available_ || !desc.IsValid()) {
    return nullptr;
  }
  // In native Android, this would invoke vkCreateImage and vkAllocateMemory.
  // When dynamically loaded without a full VkDevice context, returns null
  // or a managed instance if mock is present.
  return nullptr;
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
    vk_desc.format = 0;  // external format
    vk_desc.ycbcr_conversion = AndroidVulkanYcbcrConversionDesc::MakeExternal(
        hardware_buffer->GetId());
  } else {
    vk_desc.format = static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm);
  }

  uint64_t simulated_image = static_cast<uint64_t>(
      reinterpret_cast<uintptr_t>(hardware_buffer->GetHandle()));
  if (simulated_image == 0) {
    simulated_image = hardware_buffer->GetId();
  }

  return std::make_unique<DefaultAndroidVulkanExternalTexture>(
      vk_desc, simulated_image, nullptr, /*owns_handle=*/false,
      shared_from_this());
}

void DefaultAndroidVulkanTextureProvider::Acquire(uint64_t image_handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanTextureProvider::Acquire");
}

void DefaultAndroidVulkanTextureProvider::Release(uint64_t image_handle) {
  TRACE_EVENT0("flutter", "DefaultAndroidVulkanTextureProvider::Release");
}

void* DefaultAndroidVulkanTextureProvider::ResolveVulkanSymbol(
    const char* name) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidVulkanTextureProvider::ResolveVulkanSymbol");
  EnsureLoaded();
  if (libvulkan_) {
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
  size_t total_size = static_cast<size_t>(desc_.width) * desc_.height * 4;
  if (total_size == 0) {
    total_size = 64;
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
  return desc_.image_layout;
}

void InMemoryAndroidVulkanExternalTexture::SetImageLayout(uint32_t layout) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidVulkanExternalTexture::SetImageLayout");
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
  ext_texture.struct_size = sizeof(FlutterVulkanExternalTexture);
  ext_texture.width = desc_.width;
  ext_texture.height = desc_.height;
  ext_texture.image = image_handle_;
  ext_texture.format = desc_.format;
  ext_texture.image_layout = desc_.image_layout;
  if (has_cached_c_ycbcr_conversion_info_) {
    ext_texture.ycbcr_conversion_info = &cached_c_ycbcr_conversion_info_;
  } else {
    ext_texture.ycbcr_conversion_info = nullptr;
  }
  ext_texture.user_data = user_data;
  ext_texture.destruction_callback = destruction_callback;
  return ext_texture;
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
  size_t size = static_cast<size_t>(desc.width) * desc.height * 4;
  entry.data.resize(size > 0 ? size : 64, 0);
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
    size_t size = static_cast<size_t>(desc.width) * desc.height * 4;
    entry.data.resize(size > 0 ? size : 64, 0);
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
    vk_desc.format = 0;  // external format
    vk_desc.ycbcr_conversion = AndroidVulkanYcbcrConversionDesc::MakeExternal(
        hardware_buffer->GetId());
  } else {
    vk_desc.format = static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm);
  }

  std::lock_guard<std::mutex> lock(mutex_);
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
  size_t size = static_cast<size_t>(desc.width) * desc.height * 4;
  entry.data.resize(size > 0 ? size : 64, 0);
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

}  // namespace android
}  // namespace flutter
