// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_HARDWARE_BUFFER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_HARDWARE_BUFFER_H_

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
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// Opaque native handle to an Android AHardwareBuffer instance.
using AndroidHardwareBufferHandle = void*;

/// @brief Buffer pixel formats matching Android NDK AHardwareBuffer_Format.
enum class AndroidHardwareBufferFormat : uint32_t {
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM (1).
  kR8G8B8A8Unorm = 1,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R8G8B8X8_UNORM (2).
  kR8G8B8X8Unorm = 2,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R8G8B8_UNORM (3).
  kR8G8B8Unorm = 3,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R5G6B5_UNORM (4).
  kR5G6B5Unorm = 4,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R16G16B16A16_FLOAT (0x16).
  kR16G16B16A16Float = 0x16,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R10G10B10A2_UNORM (0x2b).
  kR10G10B10A2Unorm = 0x2b,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_BLOB (0x21).
  kBlob = 0x21,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_D16_UNORM (0x30).
  kD16Unorm = 0x30,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_D24_UNORM (0x31).
  kD24Unorm = 0x31,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_D24_UNORM_S8_UINT (0x32).
  kD24UnormS8Uint = 0x32,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_D32_FLOAT (0x33).
  kD32Float = 0x33,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_D32_FLOAT_S8_UINT (0x34).
  kD32FloatS8Uint = 0x34,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_S8_UINT (0x35).
  kS8Uint = 0x35,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_Y8Cb8Cr8_420 (0x23).
  kY8Cb8Cr8420 = 0x23,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_YCBCR_P010 (0x36).
  kYCbCrP010 = 0x36,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_YCBCR_P210 (0x3c).
  kYCbCrP210 = 0x3c,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R8_UNORM (0x38).
  kR8Unorm = 0x38,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R16_UINT (0x39).
  kR16Uint = 0x39,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R16G16_UINT (0x3a).
  kR16G16Uint = 0x3a,
  /// Corresponding to AHARDWAREBUFFER_FORMAT_R10G10B10A10_UNORM (0x3b).
  kR10G10B10A10Unorm = 0x3b,
};

/// @brief Returns the estimated bytes per pixel for a given format.
size_t AndroidHardwareBufferBytesPerPixel(uint32_t format);

/// @brief Buffer usage flags matching Android NDK AHardwareBuffer_UsageFlags.
namespace AndroidHardwareBufferUsage {
// Bit offset for CPU write usage flags in AHardwareBuffer_UsageFlags.
constexpr uint32_t kCpuWriteBitShift = 4;
// Bit offset for GPU sampled image flag
// (AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE).
constexpr uint32_t kGpuSampledImageBitShift = 8;
// Bit offset for GPU framebuffer/color output flag
// (AHARDWAREBUFFER_USAGE_GPU_FRAMEBUFFER).
constexpr uint32_t kGpuFramebufferBitShift = 9;
// Bit offset for composer overlay flag
// (AHARDWAREBUFFER_USAGE_COMPOSER_OVERLAY).
constexpr uint32_t kComposerOverlayBitShift = 11;
// Bit offset for protected content flag
// (AHARDWAREBUFFER_USAGE_PROTECTED_CONTENT).
constexpr uint32_t kProtectedContentBitShift = 14;
// Bit offset for video encode flag (AHARDWAREBUFFER_USAGE_VIDEO_ENCODE).
constexpr uint32_t kVideoEncodeBitShift = 16;
// Bit offset for sensor direct data flag
// (AHARDWAREBUFFER_USAGE_SENSOR_DIRECT_DATA).
constexpr uint32_t kSensorDirectDataBitShift = 23;
// Bit offset for GPU data buffer flag (AHARDWAREBUFFER_USAGE_GPU_DATA_BUFFER).
constexpr uint32_t kGpuDataBufferBitShift = 24;
// Bit offset for GPU cube map flag (AHARDWAREBUFFER_USAGE_GPU_CUBE_MAP).
constexpr uint32_t kGpuCubeMapBitShift = 25;
// Bit offset for GPU mipmap complete flag
// (AHARDWAREBUFFER_USAGE_GPU_MIPMAP_COMPLETE).
constexpr uint32_t kGpuMipmapCompleteBitShift = 26;
// Bit offset for front buffer usage flag (AHARDWAREBUFFER_USAGE_FRONT_BUFFER).
constexpr uint32_t kFrontBufferBitShift = 32;

constexpr uint64_t kCpuReadNever = 0ULL;
constexpr uint64_t kCpuReadRarely = 2ULL;
constexpr uint64_t kCpuReadOften = 3ULL;
constexpr uint64_t kCpuReadMask = 0xFULL;
constexpr uint64_t kCpuWriteNever = 0ULL << kCpuWriteBitShift;
constexpr uint64_t kCpuWriteRarely = 2ULL << kCpuWriteBitShift;
constexpr uint64_t kCpuWriteOften = 3ULL << kCpuWriteBitShift;
constexpr uint64_t kCpuWriteMask = 0xFULL << kCpuWriteBitShift;
constexpr uint64_t kGpuSampledImage = 1ULL << kGpuSampledImageBitShift;
constexpr uint64_t kGpuFramebuffer = 1ULL << kGpuFramebufferBitShift;
constexpr uint64_t kGpuColorOutput = 1ULL << kGpuFramebufferBitShift;
constexpr uint64_t kComposerOverlay = 1ULL << kComposerOverlayBitShift;
constexpr uint64_t kProtectedContent = 1ULL << kProtectedContentBitShift;
constexpr uint64_t kVideoEncode = 1ULL << kVideoEncodeBitShift;
constexpr uint64_t kSensorDirectData = 1ULL << kSensorDirectDataBitShift;
constexpr uint64_t kGpuDataBuffer = 1ULL << kGpuDataBufferBitShift;
constexpr uint64_t kGpuCubeMap = 1ULL << kGpuCubeMapBitShift;
constexpr uint64_t kGpuMipmapComplete = 1ULL << kGpuMipmapCompleteBitShift;
constexpr uint64_t kFrontBuffer = 1ULL << kFrontBufferBitShift;
}  // namespace AndroidHardwareBufferUsage

/// @brief Buffer description struct matching NDK AHardwareBuffer_Desc ABI.
struct AndroidHardwareBufferDesc {
  uint32_t width = 0;
  uint32_t height = 0;
  uint32_t layers = 1;
  uint32_t format =
      static_cast<uint32_t>(AndroidHardwareBufferFormat::kR8G8B8A8Unorm);
  uint64_t usage = 0;
  uint32_t stride = 0;
  uint32_t rfu0 = 0;
  uint64_t rfu1 = 0;

  /// @brief Helper to create a standard RGBA8 descriptor.
  static AndroidHardwareBufferDesc MakeRGBA8(
      uint32_t width,
      uint32_t height,
      uint64_t usage = AndroidHardwareBufferUsage::kGpuSampledImage |
                       AndroidHardwareBufferUsage::kGpuColorOutput);

  /// Maximum valid 2D hardware buffer dimension in pixels (64K).
  static constexpr uint32_t kMaxBufferDimension = 65536;
  /// Maximum valid layer count for an AHardwareBuffer array.
  static constexpr uint32_t kMaxBufferLayers = 2048;

  bool IsValid() const {
    return width > 0 && width <= kMaxBufferDimension && height > 0 &&
           height <= kMaxBufferDimension && layers > 0 &&
           layers <= kMaxBufferLayers;
  }

  bool operator==(const AndroidHardwareBufferDesc& other) const {
    return width == other.width && height == other.height &&
           layers == other.layers && format == other.format &&
           usage == other.usage && stride == other.stride;
  }

  bool operator!=(const AndroidHardwareBufferDesc& other) const {
    return !(*this == other);
  }
};

// Size in bytes of the Android NDK AHardwareBuffer_Desc C struct (40 bytes).
constexpr size_t kExpectedAHardwareBufferDescSizeBytes = 40;
static_assert(sizeof(AndroidHardwareBufferDesc) ==
                  kExpectedAHardwareBufferDescSizeBytes,
              "AndroidHardwareBufferDesc must match AHardwareBuffer_Desc size");

/// @brief Rectangle used for buffer locking, matching Android NDK ARect ABI.
struct AndroidHardwareBufferRect {
  int32_t left = 0;
  int32_t top = 0;
  int32_t right = 0;
  int32_t bottom = 0;

  bool operator==(const AndroidHardwareBufferRect& other) const {
    return left == other.left && top == other.top && right == other.right &&
           bottom == other.bottom;
  }

  bool operator!=(const AndroidHardwareBufferRect& other) const {
    return !(*this == other);
  }
};

// Size in bytes of the Android NDK ARect C struct (4 x int32_t = 16 bytes).
constexpr size_t kExpectedARectSizeBytes = 16;
static_assert(sizeof(AndroidHardwareBufferRect) == kExpectedARectSizeBytes,
              "AndroidHardwareBufferRect must match ARect size");

class DefaultAndroidHardwareBufferProvider;
class InMemoryAndroidHardwareBufferProvider;

/// @brief Abstract C++ wrapper for an AHardwareBuffer or simulated hardware
/// buffer.
class AndroidHardwareBuffer {
 public:
  virtual ~AndroidHardwareBuffer() = default;

  /// @brief Returns the description of this buffer.
  virtual const AndroidHardwareBufferDesc& GetDescription() const = 0;

  /// @brief Returns the native handle (e.g. AHardwareBuffer*).
  virtual void* GetHandle() const = 0;

  /// @brief Returns the system-wide unique ID for this buffer (API 31+ or
  /// simulated).
  virtual uint64_t GetId() const = 0;

  /// @brief Returns whether this buffer is valid and non-null.
  virtual bool IsValid() const = 0;

  /// @brief Locks the buffer for CPU read/write access.
  virtual int Lock(uint64_t usage,
                   int32_t fence,
                   const AndroidHardwareBufferRect* rect,
                   void** out_address) = 0;

  /// @brief Unlocks the buffer after CPU read/write access.
  virtual int Unlock(int32_t* fence = nullptr) = 0;

  /// @brief Increments reference count.
  virtual void Acquire() = 0;

  /// @brief Decrements reference count.
  virtual void Release() = 0;

  /// @brief Returns the opaque handle for C-API interop.
  virtual AndroidHardwareBufferHandle ToHandle() const = 0;
};

/// @brief Abstract provider interface for hardware buffer allocation and
/// virtualization.
class AndroidHardwareBufferProvider {
 public:
  virtual ~AndroidHardwareBufferProvider() = default;

  /// @brief Returns true if native AHardwareBuffer APIs are available on this
  /// platform.
  virtual bool IsAvailable() const = 0;

  /// @brief Tests whether the given format and usage combination is
  /// allocatable.
  virtual bool IsSupported(const AndroidHardwareBufferDesc& desc) const = 0;

  /// @brief Allocates a new hardware buffer with the specified descriptor.
  virtual std::unique_ptr<AndroidHardwareBuffer> Allocate(
      const AndroidHardwareBufferDesc& desc) = 0;

  /// @brief Wraps an existing native AHardwareBuffer handle.
  virtual std::unique_ptr<AndroidHardwareBuffer> CreateFromNativeHandle(
      void* handle,
      bool take_ownership = false) = 0;

  /// @brief Resolves an AHardwareBuffer from a Java
  /// android.hardware.HardwareBuffer object.
  virtual std::unique_ptr<AndroidHardwareBuffer> CreateFromJavaHardwareBuffer(
      void* env,
      void* java_hardware_buffer) = 0;

  /// @brief Exports an AHardwareBuffer to a Java
  /// android.hardware.HardwareBuffer object.
  virtual void* ToJavaHardwareBuffer(void* env, void* handle) = 0;

  /// @brief Queries the descriptor of a native buffer handle.
  virtual bool Describe(void* handle, AndroidHardwareBufferDesc* out_desc) = 0;

  /// @brief Acquires a reference on a native buffer handle.
  virtual void Acquire(void* handle) = 0;

  /// @brief Releases a reference on a native buffer handle.
  virtual void Release(void* handle) = 0;

  /// @brief Locks a native buffer handle for CPU access.
  virtual int Lock(void* handle,
                   uint64_t usage,
                   int32_t fence,
                   const AndroidHardwareBufferRect* rect,
                   void** out_address) = 0;

  /// @brief Unlocks a native buffer handle from CPU access.
  virtual int Unlock(void* handle, int32_t* fence = nullptr) = 0;

  /// @brief Gets the system unique ID for a native buffer handle.
  virtual uint64_t GetId(void* handle) = 0;
};

/// @brief Default production implementation of AndroidHardwareBuffer wrapping
/// AHardwareBuffer*.
class DefaultAndroidHardwareBuffer : public AndroidHardwareBuffer {
 public:
  DefaultAndroidHardwareBuffer(
      AndroidHardwareBufferDesc desc,
      void* handle,
      uint64_t id,
      bool owns_handle,
      std::shared_ptr<DefaultAndroidHardwareBufferProvider> provider);
  ~DefaultAndroidHardwareBuffer() override;

  const AndroidHardwareBufferDesc& GetDescription() const override;
  void* GetHandle() const override;
  uint64_t GetId() const override;
  bool IsValid() const override;

  int Lock(uint64_t usage,
           int32_t fence,
           const AndroidHardwareBufferRect* rect,
           void** out_address) override;
  int Unlock(int32_t* fence = nullptr) override;

  void Acquire() override;
  void Release() override;

  AndroidHardwareBufferHandle ToHandle() const override;

 private:
  AndroidHardwareBufferDesc desc_;
  void* handle_ = nullptr;
  uint64_t id_ = 0;
  bool owns_handle_ = true;
  std::shared_ptr<DefaultAndroidHardwareBufferProvider> provider_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidHardwareBuffer);
};

/// @brief Default dynamic provider that resolves AHardwareBuffer symbols
/// dynamically via OSLibraryLoader from libandroid.so.
class DefaultAndroidHardwareBufferProvider
    : public AndroidHardwareBufferProvider,
      public std::enable_shared_from_this<
          DefaultAndroidHardwareBufferProvider> {
 public:
  explicit DefaultAndroidHardwareBufferProvider(
      std::shared_ptr<OSLibraryLoader> library_loader = nullptr);
  ~DefaultAndroidHardwareBufferProvider() override;

  bool IsAvailable() const override;
  bool IsSupported(const AndroidHardwareBufferDesc& desc) const override;

  std::unique_ptr<AndroidHardwareBuffer> Allocate(
      const AndroidHardwareBufferDesc& desc) override;

  std::unique_ptr<AndroidHardwareBuffer> CreateFromNativeHandle(
      void* handle,
      bool take_ownership = false) override;

  std::unique_ptr<AndroidHardwareBuffer> CreateFromJavaHardwareBuffer(
      void* env,
      void* java_hardware_buffer) override;

  void* ToJavaHardwareBuffer(void* env, void* handle) override;

  bool Describe(void* handle, AndroidHardwareBufferDesc* out_desc) override;
  void Acquire(void* handle) override;
  void Release(void* handle) override;
  int Lock(void* handle,
           uint64_t usage,
           int32_t fence,
           const AndroidHardwareBufferRect* rect,
           void** out_address) override;
  int Unlock(void* handle, int32_t* fence = nullptr) override;
  uint64_t GetId(void* handle) override;

 private:
  void EnsureLoaded() const;

  mutable std::shared_ptr<OSLibraryLoader> library_loader_;
  mutable std::unique_ptr<OSLibrary> libandroid_;
  mutable std::unique_ptr<OSLibrary> libjnigraphics_;
  mutable std::mutex mutex_;
  mutable bool loaded_ = false;
  mutable bool is_available_ = false;

  mutable void* allocate_fn_ = nullptr;
  mutable void* release_fn_ = nullptr;
  mutable void* describe_fn_ = nullptr;
  mutable void* acquire_fn_ = nullptr;
  mutable void* from_hardware_buffer_fn_ = nullptr;
  mutable void* to_hardware_buffer_fn_ = nullptr;
  mutable void* get_id_fn_ = nullptr;
  mutable void* lock_fn_ = nullptr;
  mutable void* unlock_fn_ = nullptr;
  mutable void* is_supported_fn_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidHardwareBufferProvider);
};

/// @brief In-memory mock hardware buffer backed by a memory byte buffer for
/// host tests.
class InMemoryAndroidHardwareBuffer : public AndroidHardwareBuffer {
 public:
  InMemoryAndroidHardwareBuffer(
      AndroidHardwareBufferDesc desc,
      uint64_t id,
      void* handle = nullptr,
      bool owns_handle = true,
      std::shared_ptr<InMemoryAndroidHardwareBufferProvider> provider =
          nullptr);
  ~InMemoryAndroidHardwareBuffer() override;

  const AndroidHardwareBufferDesc& GetDescription() const override;
  void* GetHandle() const override;
  uint64_t GetId() const override;
  bool IsValid() const override;

  int Lock(uint64_t usage,
           int32_t fence,
           const AndroidHardwareBufferRect* rect,
           void** out_address) override;
  int Unlock(int32_t* fence = nullptr) override;

  void Acquire() override;
  void Release() override;

  AndroidHardwareBufferHandle ToHandle() const override;

  // Test inspection methods:
  uint8_t* GetBackingData();
  size_t GetBackingDataSize() const;
  int32_t GetLockCount() const;
  int32_t GetRefCount() const;

 private:
  AndroidHardwareBufferDesc desc_;
  uint64_t id_ = 0;
  void* handle_ = nullptr;
  bool owns_handle_ = true;
  std::shared_ptr<InMemoryAndroidHardwareBufferProvider> provider_;
  mutable std::mutex mutex_;
  std::vector<uint8_t> backing_data_;
  int32_t ref_count_ = 1;
  int32_t lock_count_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidHardwareBuffer);
};

/// @brief In-memory mock provider for unit tests on host platforms without
/// libandroid.so.
class InMemoryAndroidHardwareBufferProvider
    : public AndroidHardwareBufferProvider,
      public std::enable_shared_from_this<
          InMemoryAndroidHardwareBufferProvider> {
 public:
  InMemoryAndroidHardwareBufferProvider();
  ~InMemoryAndroidHardwareBufferProvider() override;

  bool IsAvailable() const override;
  bool IsSupported(const AndroidHardwareBufferDesc& desc) const override;

  std::unique_ptr<AndroidHardwareBuffer> Allocate(
      const AndroidHardwareBufferDesc& desc) override;

  std::unique_ptr<AndroidHardwareBuffer> CreateFromNativeHandle(
      void* handle,
      bool take_ownership = false) override;

  std::unique_ptr<AndroidHardwareBuffer> CreateFromJavaHardwareBuffer(
      void* env,
      void* java_hardware_buffer) override;

  void* ToJavaHardwareBuffer(void* env, void* handle) override;

  bool Describe(void* handle, AndroidHardwareBufferDesc* out_desc) override;
  void Acquire(void* handle) override;
  void Release(void* handle) override;
  int Lock(void* handle,
           uint64_t usage,
           int32_t fence,
           const AndroidHardwareBufferRect* rect,
           void** out_address) override;
  int Unlock(void* handle, int32_t* fence = nullptr) override;
  uint64_t GetId(void* handle) override;

  // Test controls & inspection:
  void SetAvailable(bool available);
  void SetAllocationFailure(bool fail);
  size_t GetAllocationCount() const;
  size_t GetReleaseCount() const;
  size_t GetActiveBufferCount() const;
  void RegisterMockBuffer(void* handle,
                          const AndroidHardwareBufferDesc& desc,
                          uint64_t id);
  void Clear();

 private:
  mutable std::mutex mutex_;
  bool is_available_ = true;
  bool allocation_failure_ = false;
  uint64_t next_id_ = 1;
  size_t allocation_count_ = 0;
  size_t release_count_ = 0;

  struct MockEntry {
    AndroidHardwareBufferDesc desc;
    uint64_t id = 0;
    int32_t ref_count = 1;
    std::vector<uint8_t> data;
    int32_t lock_count = 0;
  };
  std::unordered_map<void*, MockEntry> mock_entries_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidHardwareBufferProvider);
};

// Number of floats in a 4x4 column-major UV transformation matrix.
constexpr size_t kOpenGLUvTransformMatrixElementCount = 16;

/// @brief Populates a C-API `FlutterOpenGLExternalTexture` from an
/// `AndroidHardwareBuffer` imported as an `EGLImageKHR` bound to
/// `GL_TEXTURE_2D`
/// (`SurfaceProducer` / `ImageTextureEntry` path on OpenGL ES).
bool PopulateFlutterOpenGLExternalTextureFromHardwareBuffer(
    const AndroidHardwareBuffer* buffer,
    uint32_t gl_texture_id,
    FlutterOpenGLExternalTexture* texture_out,
    void* user_data = nullptr,
    VoidCallback destruction_callback = nullptr);

/// @brief Populates a C-API `FlutterOpenGLExternalTexture` for a
/// `SurfaceTexture` (`GL_TEXTURE_EXTERNAL_OES`) along with its 4x4 column-major
/// `uv_transform[16]` from `SurfaceTexture.getTransformMatrix(float[16])`.
bool PopulateFlutterOpenGLExternalTextureFromSurfaceTexture(
    uint32_t gl_texture_id,
    size_t width,
    size_t height,
    const float* uv_transform,
    FlutterOpenGLExternalTexture* texture_out,
    void* user_data = nullptr,
    VoidCallback destruction_callback = nullptr);

}  // namespace android

using android::AndroidHardwareBuffer;
using android::AndroidHardwareBufferBytesPerPixel;
using android::AndroidHardwareBufferDesc;
using android::AndroidHardwareBufferFormat;
using android::AndroidHardwareBufferHandle;
using android::AndroidHardwareBufferProvider;
using android::AndroidHardwareBufferRect;
using android::DefaultAndroidHardwareBuffer;
using android::DefaultAndroidHardwareBufferProvider;
using android::InMemoryAndroidHardwareBuffer;
using android::InMemoryAndroidHardwareBufferProvider;
using android::PopulateFlutterOpenGLExternalTextureFromHardwareBuffer;
using android::PopulateFlutterOpenGLExternalTextureFromSurfaceTexture;

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_HARDWARE_BUFFER_H_
