// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VULKAN_TEXTURE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VULKAN_TEXTURE_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_hardware_buffer.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Vulkan format constants matching standard VkFormat.
enum class AndroidVulkanFormat : uint32_t {
  kUndefined = 0,
  kR8G8B8A8Unorm = 37,
  kR8G8B8A8Srgb = 43,
  kB8G8R8A8Unorm = 44,
  kB8G8R8A8Srgb = 50,
  kR16G16B16A16Sfloat = 97,
  kG8B8R83Plane420Unorm = 1000156000,
  kG8B8R82Plane420Unorm = 1000156001,
};

/// @brief Vulkan image layout constants matching standard VkImageLayout.
enum class AndroidVulkanImageLayout : uint32_t {
  kUndefined = 0,
  kGeneral = 1,
  kColorAttachmentOptimal = 2,
  kShaderReadOnlyOptimal = 5,
  kTransferSrcOptimal = 6,
  kTransferDstOptimal = 7,
  kPreinitialized = 8,
};

/// @brief Vulkan component swizzle matching FlutterVulkanComponentSwizzle.
enum class AndroidVulkanComponentSwizzle : uint32_t {
  kIdentity = 0,
  kZero = 1,
  kOne = 2,
  kR = 3,
  kG = 4,
  kB = 5,
  kA = 6,
};

/// @brief Vulkan YCbCr model conversion matching VkSamplerYcbcrModelConversion.
enum class AndroidVulkanYcbcrModel : uint32_t {
  kRgbIdentity = 0,
  kYcbcrIdentity = 1,
  kYcbcr709 = 2,
  kYcbcr601 = 3,
  kYcbcr2020 = 4,
};

/// @brief Vulkan YCbCr range matching VkSamplerYcbcrRange.
enum class AndroidVulkanYcbcrRange : uint32_t {
  kItuFull = 0,
  kItuNarrow = 1,
};

/// @brief Vulkan chroma location matching VkChromaLocation.
enum class AndroidVulkanChromaLocation : uint32_t {
  kCositedEven = 0,
  kMidpoint = 1,
};

/// @brief Vulkan filter mode matching VkFilter.
enum class AndroidVulkanFilter : uint32_t {
  kNearest = 0,
  kLinear = 1,
};

/// @brief Component mapping for Vulkan texture or YCbCr conversion swizzling.
struct AndroidVulkanComponentMapping {
  AndroidVulkanComponentSwizzle r = AndroidVulkanComponentSwizzle::kIdentity;
  AndroidVulkanComponentSwizzle g = AndroidVulkanComponentSwizzle::kIdentity;
  AndroidVulkanComponentSwizzle b = AndroidVulkanComponentSwizzle::kIdentity;
  AndroidVulkanComponentSwizzle a = AndroidVulkanComponentSwizzle::kIdentity;

  static AndroidVulkanComponentMapping MakeIdentity() {
    return AndroidVulkanComponentMapping{
        AndroidVulkanComponentSwizzle::kIdentity,
        AndroidVulkanComponentSwizzle::kIdentity,
        AndroidVulkanComponentSwizzle::kIdentity,
        AndroidVulkanComponentSwizzle::kIdentity};
  }

  FlutterVulkanComponentMapping ToFlutterComponentMapping() const {
    FlutterVulkanComponentMapping mapping = {};
    mapping.struct_size = sizeof(FlutterVulkanComponentMapping);
    mapping.r = static_cast<FlutterVulkanComponentSwizzle>(r);
    mapping.g = static_cast<FlutterVulkanComponentSwizzle>(g);
    mapping.b = static_cast<FlutterVulkanComponentSwizzle>(b);
    mapping.a = static_cast<FlutterVulkanComponentSwizzle>(a);
    return mapping;
  }

  static AndroidVulkanComponentMapping FromFlutterComponentMapping(
      const FlutterVulkanComponentMapping& mapping) {
    return AndroidVulkanComponentMapping{
        static_cast<AndroidVulkanComponentSwizzle>(mapping.r),
        static_cast<AndroidVulkanComponentSwizzle>(mapping.g),
        static_cast<AndroidVulkanComponentSwizzle>(mapping.b),
        static_cast<AndroidVulkanComponentSwizzle>(mapping.a)};
  }

  bool operator==(const AndroidVulkanComponentMapping& other) const {
    return r == other.r && g == other.g && b == other.b && a == other.a;
  }

  bool operator!=(const AndroidVulkanComponentMapping& other) const {
    return !(*this == other);
  }
};

/// @brief Descriptor for Vulkan YCbCr conversion configuration.
struct AndroidVulkanYcbcrConversionDesc {
  uint32_t format = 0;
  uint32_t ycbcr_model =
      static_cast<uint32_t>(AndroidVulkanYcbcrModel::kYcbcr601);
  uint32_t ycbcr_range =
      static_cast<uint32_t>(AndroidVulkanYcbcrRange::kItuNarrow);
  AndroidVulkanComponentMapping components =
      AndroidVulkanComponentMapping::MakeIdentity();
  uint32_t x_chroma_offset =
      static_cast<uint32_t>(AndroidVulkanChromaLocation::kMidpoint);
  uint32_t y_chroma_offset =
      static_cast<uint32_t>(AndroidVulkanChromaLocation::kMidpoint);
  uint32_t chroma_filter = static_cast<uint32_t>(AndroidVulkanFilter::kLinear);
  uint32_t force_explicit_reconstruction = 0;
  uint64_t external_format = 0;

  static AndroidVulkanYcbcrConversionDesc MakeExternal(
      uint64_t external_format_id,
      AndroidVulkanYcbcrModel model = AndroidVulkanYcbcrModel::kYcbcr601,
      AndroidVulkanYcbcrRange range = AndroidVulkanYcbcrRange::kItuNarrow,
      AndroidVulkanChromaLocation chroma_offset =
          AndroidVulkanChromaLocation::kMidpoint,
      AndroidVulkanFilter filter = AndroidVulkanFilter::kLinear) {
    AndroidVulkanYcbcrConversionDesc desc;
    desc.format = 0;
    desc.ycbcr_model = static_cast<uint32_t>(model);
    desc.ycbcr_range = static_cast<uint32_t>(range);
    desc.components = AndroidVulkanComponentMapping::MakeIdentity();
    desc.x_chroma_offset = static_cast<uint32_t>(chroma_offset);
    desc.y_chroma_offset = static_cast<uint32_t>(chroma_offset);
    desc.chroma_filter = static_cast<uint32_t>(filter);
    desc.force_explicit_reconstruction = 0;
    desc.external_format = external_format_id;
    return desc;
  }

  static AndroidVulkanYcbcrConversionDesc MakeExternal(
      uint64_t external_format_id,
      AndroidVulkanYcbcrModel model,
      AndroidVulkanYcbcrRange range,
      AndroidVulkanChromaLocation x_chroma_offset,
      AndroidVulkanChromaLocation y_chroma_offset,
      AndroidVulkanFilter filter) {
    AndroidVulkanYcbcrConversionDesc desc;
    desc.format = 0;
    desc.ycbcr_model = static_cast<uint32_t>(model);
    desc.ycbcr_range = static_cast<uint32_t>(range);
    desc.components = AndroidVulkanComponentMapping::MakeIdentity();
    desc.x_chroma_offset = static_cast<uint32_t>(x_chroma_offset);
    desc.y_chroma_offset = static_cast<uint32_t>(y_chroma_offset);
    desc.chroma_filter = static_cast<uint32_t>(filter);
    desc.force_explicit_reconstruction = 0;
    desc.external_format = external_format_id;
    return desc;
  }

  FlutterVulkanYcbcrConversionInfo ToFlutterYcbcrConversionInfo() const {
    FlutterVulkanYcbcrConversionInfo info = {};
    info.struct_size = sizeof(FlutterVulkanYcbcrConversionInfo);
    info.format = format;
    info.ycbcr_model = ycbcr_model;
    info.ycbcr_range = ycbcr_range;
    info.components = components.ToFlutterComponentMapping();
    info.x_chroma_offset = x_chroma_offset;
    info.y_chroma_offset = y_chroma_offset;
    info.chroma_filter = chroma_filter;
    info.force_explicit_reconstruction = force_explicit_reconstruction;
    info.external_format = external_format;
    return info;
  }

  static AndroidVulkanYcbcrConversionDesc FromFlutterYcbcrConversionInfo(
      const FlutterVulkanYcbcrConversionInfo& info) {
    AndroidVulkanYcbcrConversionDesc desc;
    desc.format = info.format;
    desc.ycbcr_model = info.ycbcr_model;
    desc.ycbcr_range = info.ycbcr_range;
    desc.components =
        AndroidVulkanComponentMapping::FromFlutterComponentMapping(
            info.components);
    desc.x_chroma_offset = info.x_chroma_offset;
    desc.y_chroma_offset = info.y_chroma_offset;
    desc.chroma_filter = info.chroma_filter;
    desc.force_explicit_reconstruction = info.force_explicit_reconstruction;
    desc.external_format = info.external_format;
    return desc;
  }

  bool operator==(const AndroidVulkanYcbcrConversionDesc& other) const {
    return format == other.format && ycbcr_model == other.ycbcr_model &&
           ycbcr_range == other.ycbcr_range && components == other.components &&
           x_chroma_offset == other.x_chroma_offset &&
           y_chroma_offset == other.y_chroma_offset &&
           chroma_filter == other.chroma_filter &&
           force_explicit_reconstruction ==
               other.force_explicit_reconstruction &&
           external_format == other.external_format;
  }

  bool operator!=(const AndroidVulkanYcbcrConversionDesc& other) const {
    return !(*this == other);
  }
};

/// @brief Description struct for a Vulkan external image.
struct AndroidVulkanImageDesc {
  uint32_t width = 0;
  uint32_t height = 0;
  uint32_t format = static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm);
  uint32_t image_layout =
      static_cast<uint32_t>(AndroidVulkanImageLayout::kShaderReadOnlyOptimal);
  uint32_t usage = 0;
  uint32_t tiling = 0;
  std::optional<AndroidVulkanYcbcrConversionDesc> ycbcr_conversion;

  static AndroidVulkanImageDesc MakeRGBA8(
      uint32_t width,
      uint32_t height,
      uint32_t layout = static_cast<uint32_t>(
          AndroidVulkanImageLayout::kShaderReadOnlyOptimal)) {
    AndroidVulkanImageDesc desc;
    desc.width = width;
    desc.height = height;
    desc.format = static_cast<uint32_t>(AndroidVulkanFormat::kR8G8B8A8Unorm);
    desc.image_layout = layout;
    return desc;
  }

  static AndroidVulkanImageDesc MakeYcbcr(
      uint32_t width,
      uint32_t height,
      const AndroidVulkanYcbcrConversionDesc& ycbcr_desc,
      uint32_t layout = static_cast<uint32_t>(
          AndroidVulkanImageLayout::kShaderReadOnlyOptimal)) {
    AndroidVulkanImageDesc desc;
    desc.width = width;
    desc.height = height;
    desc.format = ycbcr_desc.format;
    desc.image_layout = layout;
    desc.ycbcr_conversion = ycbcr_desc;
    return desc;
  }

  bool IsValid() const { return width > 0 && height > 0; }

  bool operator==(const AndroidVulkanImageDesc& other) const {
    return width == other.width && height == other.height &&
           format == other.format && image_layout == other.image_layout &&
           usage == other.usage && tiling == other.tiling &&
           ycbcr_conversion == other.ycbcr_conversion;
  }

  bool operator!=(const AndroidVulkanImageDesc& other) const {
    return !(*this == other);
  }
};

class DefaultAndroidVulkanTextureProvider;
class InMemoryAndroidVulkanTextureProvider;

/// @brief Abstract C++ wrapper for an external Vulkan image texture.
class AndroidVulkanExternalTexture {
 public:
  virtual ~AndroidVulkanExternalTexture() = default;

  /// @brief Returns the descriptor of this Vulkan texture.
  virtual const AndroidVulkanImageDesc& GetDescription() const = 0;

  /// @brief Returns the native VkImage handle (as uint64_t).
  virtual uint64_t GetImageHandle() const = 0;

  /// @brief Returns the native VkDeviceMemory handle (or nullptr if unmanaged).
  virtual void* GetDeviceMemory() const = 0;

  /// @brief Returns the current image layout.
  virtual uint32_t GetImageLayout() const = 0;

  /// @brief Updates the image layout.
  virtual void SetImageLayout(uint32_t layout) = 0;

  /// @brief Returns the optional YCbCr conversion descriptor.
  virtual const AndroidVulkanYcbcrConversionDesc* GetYcbcrConversionDesc()
      const = 0;

  /// @brief Returns true if this texture uses YCbCr sampler conversion.
  virtual bool HasYcbcrConversion() const = 0;

  /// @brief Returns whether this texture is valid.
  virtual bool IsValid() const = 0;

  /// @brief Increments reference count.
  virtual void Acquire() = 0;

  /// @brief Decrements reference count.
  virtual void Release() = 0;

  /// @brief Converts this texture into a C-API FlutterVulkanExternalTexture.
  virtual FlutterVulkanExternalTexture ToExternalTexture(
      void* user_data = nullptr,
      VoidCallback destruction_callback = nullptr) const = 0;

  /// @brief Converts this texture into a C-API FlutterVulkanImage.
  virtual FlutterVulkanImage ToFlutterVulkanImage() const = 0;
};

/// @brief Abstract provider interface for Vulkan texture allocation and
/// virtualization.
class AndroidVulkanTextureProvider {
 public:
  virtual ~AndroidVulkanTextureProvider() = default;

  /// @brief Returns true if native Vulkan APIs are available on this platform.
  virtual bool IsAvailable() const = 0;

  /// @brief Tests whether the given descriptor configuration is supported.
  virtual bool IsSupported(const AndroidVulkanImageDesc& desc) const = 0;

  /// @brief Allocates a new Vulkan external texture with the given descriptor.
  virtual std::unique_ptr<AndroidVulkanExternalTexture> AllocateTexture(
      const AndroidVulkanImageDesc& desc) = 0;

  /// @brief Wraps an existing native VkImage handle.
  virtual std::unique_ptr<AndroidVulkanExternalTexture> CreateFromNativeImage(
      uint64_t image_handle,
      const AndroidVulkanImageDesc& desc,
      bool take_ownership = false) = 0;

  /// @brief Creates an AndroidVulkanExternalTexture backed by an
  /// AndroidHardwareBuffer.
  virtual std::unique_ptr<AndroidVulkanExternalTexture>
  CreateFromAHardwareBuffer(
      const AndroidHardwareBuffer* hardware_buffer,
      const AndroidVulkanYcbcrConversionDesc* ycbcr_desc = nullptr) = 0;

  /// @brief Acquires a reference on a native VkImage handle.
  virtual void Acquire(uint64_t image_handle) = 0;

  /// @brief Releases a reference on a native VkImage handle.
  virtual void Release(uint64_t image_handle) = 0;

  /// @brief Resolves a Vulkan function pointer dynamically.
  virtual void* ResolveVulkanSymbol(const char* name) = 0;
};

/// @brief Default production implementation of AndroidVulkanExternalTexture.
class DefaultAndroidVulkanExternalTexture
    : public AndroidVulkanExternalTexture {
 public:
  DefaultAndroidVulkanExternalTexture(
      AndroidVulkanImageDesc desc,
      uint64_t image_handle,
      void* device_memory,
      bool owns_handle,
      std::shared_ptr<DefaultAndroidVulkanTextureProvider> provider);
  ~DefaultAndroidVulkanExternalTexture() override;

  const AndroidVulkanImageDesc& GetDescription() const override;
  uint64_t GetImageHandle() const override;
  void* GetDeviceMemory() const override;
  uint32_t GetImageLayout() const override;
  void SetImageLayout(uint32_t layout) override;

  const AndroidVulkanYcbcrConversionDesc* GetYcbcrConversionDesc()
      const override;
  bool HasYcbcrConversion() const override;
  bool IsValid() const override;

  void Acquire() override;
  void Release() override;

  FlutterVulkanExternalTexture ToExternalTexture(
      void* user_data = nullptr,
      VoidCallback destruction_callback = nullptr) const override;

  FlutterVulkanImage ToFlutterVulkanImage() const override;

 private:
  AndroidVulkanImageDesc desc_;
  uint64_t image_handle_ = 0;
  void* device_memory_ = nullptr;
  bool owns_handle_ = true;
  std::shared_ptr<DefaultAndroidVulkanTextureProvider> provider_;
  bool has_cached_c_ycbcr_conversion_info_ = false;
  FlutterVulkanYcbcrConversionInfo cached_c_ycbcr_conversion_info_ = {};

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidVulkanExternalTexture);
};

/// @brief Default production provider that dynamically loads libvulkan.so via
/// OSLibraryLoader.
class DefaultAndroidVulkanTextureProvider
    : public AndroidVulkanTextureProvider,
      public std::enable_shared_from_this<DefaultAndroidVulkanTextureProvider> {
 public:
  explicit DefaultAndroidVulkanTextureProvider(
      std::shared_ptr<OSLibraryLoader> library_loader = nullptr);
  ~DefaultAndroidVulkanTextureProvider() override;

  bool IsAvailable() const override;
  bool IsSupported(const AndroidVulkanImageDesc& desc) const override;

  std::unique_ptr<AndroidVulkanExternalTexture> AllocateTexture(
      const AndroidVulkanImageDesc& desc) override;

  std::unique_ptr<AndroidVulkanExternalTexture> CreateFromNativeImage(
      uint64_t image_handle,
      const AndroidVulkanImageDesc& desc,
      bool take_ownership = false) override;

  std::unique_ptr<AndroidVulkanExternalTexture> CreateFromAHardwareBuffer(
      const AndroidHardwareBuffer* hardware_buffer,
      const AndroidVulkanYcbcrConversionDesc* ycbcr_desc = nullptr) override;

  void Acquire(uint64_t image_handle) override;
  void Release(uint64_t image_handle) override;
  void* ResolveVulkanSymbol(const char* name) override;

 private:
  void EnsureLoaded() const;

  mutable std::shared_ptr<OSLibraryLoader> library_loader_;
  mutable std::shared_ptr<OSLibrary> libvulkan_;
  mutable std::mutex mutex_;
  mutable bool loaded_ = false;
  mutable bool is_available_ = false;

  mutable void* get_instance_proc_addr_fn_ = nullptr;
  mutable void* create_image_fn_ = nullptr;
  mutable void* destroy_image_fn_ = nullptr;
  mutable void* get_image_memory_requirements_fn_ = nullptr;
  mutable void* allocate_memory_fn_ = nullptr;
  mutable void* free_memory_fn_ = nullptr;
  mutable void* bind_image_memory_fn_ = nullptr;
  mutable void* create_sampler_ycbcr_conversion_fn_ = nullptr;
  mutable void* destroy_sampler_ycbcr_conversion_fn_ = nullptr;
  mutable void* get_ahb_properties_fn_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidVulkanTextureProvider);
};

/// @brief In-memory mock Vulkan external texture for unit tests and host
/// desktop CI simulation.
class InMemoryAndroidVulkanExternalTexture
    : public AndroidVulkanExternalTexture {
 public:
  InMemoryAndroidVulkanExternalTexture(
      AndroidVulkanImageDesc desc,
      uint64_t image_handle,
      void* device_memory = nullptr,
      bool owns_handle = true,
      std::shared_ptr<InMemoryAndroidVulkanTextureProvider> provider = nullptr);
  ~InMemoryAndroidVulkanExternalTexture() override;

  const AndroidVulkanImageDesc& GetDescription() const override;
  uint64_t GetImageHandle() const override;
  void* GetDeviceMemory() const override;
  uint32_t GetImageLayout() const override;
  void SetImageLayout(uint32_t layout) override;

  const AndroidVulkanYcbcrConversionDesc* GetYcbcrConversionDesc()
      const override;
  bool HasYcbcrConversion() const override;
  bool IsValid() const override;

  void Acquire() override;
  void Release() override;

  FlutterVulkanExternalTexture ToExternalTexture(
      void* user_data = nullptr,
      VoidCallback destruction_callback = nullptr) const override;

  FlutterVulkanImage ToFlutterVulkanImage() const override;

  // Test inspection methods:
  uint8_t* GetBackingData();
  size_t GetBackingDataSize() const;
  int32_t GetRefCount() const;

 private:
  AndroidVulkanImageDesc desc_;
  uint64_t image_handle_ = 0;
  void* device_memory_ = nullptr;
  bool owns_handle_ = true;
  std::shared_ptr<InMemoryAndroidVulkanTextureProvider> provider_;

  mutable std::mutex mutex_;
  std::vector<uint8_t> backing_data_;
  int32_t ref_count_ = 1;
  bool has_cached_c_ycbcr_conversion_info_ = false;
  FlutterVulkanYcbcrConversionInfo cached_c_ycbcr_conversion_info_ = {};

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidVulkanExternalTexture);
};

/// @brief In-memory mock provider for unit tests on host platforms without
/// libvulkan.so.
class InMemoryAndroidVulkanTextureProvider
    : public AndroidVulkanTextureProvider,
      public std::enable_shared_from_this<
          InMemoryAndroidVulkanTextureProvider> {
 public:
  InMemoryAndroidVulkanTextureProvider();
  ~InMemoryAndroidVulkanTextureProvider() override;

  bool IsAvailable() const override;
  bool IsSupported(const AndroidVulkanImageDesc& desc) const override;

  std::unique_ptr<AndroidVulkanExternalTexture> AllocateTexture(
      const AndroidVulkanImageDesc& desc) override;

  std::unique_ptr<AndroidVulkanExternalTexture> CreateFromNativeImage(
      uint64_t image_handle,
      const AndroidVulkanImageDesc& desc,
      bool take_ownership = false) override;

  std::unique_ptr<AndroidVulkanExternalTexture> CreateFromAHardwareBuffer(
      const AndroidHardwareBuffer* hardware_buffer,
      const AndroidVulkanYcbcrConversionDesc* ycbcr_desc = nullptr) override;

  void Acquire(uint64_t image_handle) override;
  void Release(uint64_t image_handle) override;
  void* ResolveVulkanSymbol(const char* name) override;

  // Test controls & inspection:
  void SetAvailable(bool available);
  void SetAllocationFailure(bool fail);
  size_t GetAllocationCount() const;
  size_t GetReleaseCount() const;
  size_t GetActiveTextureCount() const;
  void RegisterMockImage(uint64_t image_handle,
                         const AndroidVulkanImageDesc& desc);
  void SetSymbol(const std::string& name, void* symbol_ptr);
  void Clear();

 private:
  mutable std::mutex mutex_;
  bool is_available_ = true;
  bool allocation_failure_ = false;
  uint64_t next_image_handle_ = 0x1000;
  size_t allocation_count_ = 0;
  size_t release_count_ = 0;

  struct MockEntry {
    AndroidVulkanImageDesc desc;
    int32_t ref_count = 1;
    std::vector<uint8_t> data;
  };
  std::unordered_map<uint64_t, MockEntry> mock_entries_;
  std::unordered_map<std::string, void*> mock_symbols_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidVulkanTextureProvider);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VULKAN_TEXTURE_H_
