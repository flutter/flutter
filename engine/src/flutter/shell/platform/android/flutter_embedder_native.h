// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_

#include <cstddef>
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "flutter/shell/platform/embedder/embedder.h"

#if defined(__ANDROID__)
#include <android/native_window.h>
#else
// Opaque forward declaration for non-Android unit test builds.
typedef struct ANativeWindow ANativeWindow;
#endif

namespace flutter {
namespace android {

/// @brief Default JNI/C-API backed ImageDecoderProvider that dispatches to JVM
/// decodeImage.
class DefaultImageDecoderProvider : public ImageDecoderProvider {
 public:
  explicit DefaultImageDecoderProvider(
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr);
  ~DefaultImageDecoderProvider() override;

  bool DecodeImage(const uint8_t* data,
                   size_t size,
                   int64_t generator_handle) override;

  void OnImageHeader(int64_t generator_handle,
                     int32_t width,
                     int32_t height) override;

  std::optional<ImageHeaderInfo> GetImageHeader(
      int64_t generator_handle) override;

  void RemoveImageHeader(int64_t generator_handle) override;

 private:
  static constexpr size_t kMaxHeaderCount = 128u;
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  mutable std::mutex mutex_;
  std::map<int64_t, ImageHeaderInfo> headers_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultImageDecoderProvider);
};

/// @brief In-memory mock image decoder provider for unit testing without JVM
/// or Android SDK dependencies.
class InMemoryImageDecoderProvider : public ImageDecoderProvider {
 public:
  InMemoryImageDecoderProvider();
  ~InMemoryImageDecoderProvider() override;

  void SetDecodeResult(bool success);
  void SetHeaderInfo(int64_t generator_handle, int32_t width, int32_t height);
  size_t GetDecodeCount() const;
  size_t GetLastDecodedSize() const;
  void Clear();

  bool DecodeImage(const uint8_t* data,
                   size_t size,
                   int64_t generator_handle) override;

  void OnImageHeader(int64_t generator_handle,
                     int32_t width,
                     int32_t height) override;

  std::optional<ImageHeaderInfo> GetImageHeader(
      int64_t generator_handle) override;

  void RemoveImageHeader(int64_t generator_handle) override;

 private:
  mutable std::mutex mutex_;
  bool decode_result_ = true;
  size_t decode_count_ = 0;
  size_t last_decoded_size_ = 0;
  std::map<int64_t, ImageHeaderInfo> headers_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryImageDecoderProvider);
};

/// @brief Decoupled, C-ABI quarantined LRU cache for platform texture and
/// image handles.
class EmbedderImageLRU {
 public:
  static constexpr size_t kDefaultCapacity = 6u;

  explicit EmbedderImageLRU(size_t capacity = kDefaultCapacity);
  ~EmbedderImageLRU();

  /// @brief Finds the handle associated with [key], or 0 if absent.
  uint64_t FindImage(uint64_t key);

  /// @brief Adds an image handle to the cache, returning the evicted key (or 0
  /// if none evicted).
  uint64_t AddImage(uint64_t image_handle, uint64_t key);

  /// @brief Clears all entries from the LRU cache.
  void Clear();

  /// @brief Returns the current number of cached items.
  size_t GetSize() const;

 private:
  void UpdateKey(uint64_t image_handle, uint64_t key);

  struct Entry {
    uint64_t key = 0u;
    uint64_t image_handle = 0u;
  };

  mutable std::mutex mutex_;
  size_t capacity_;
  std::vector<Entry> entries_;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderImageLRU);
};

/// @brief Quarantined native entry point and manager for the Android C-API
/// Embedder.
///
/// This class enforces strict GN and C-ABI isolation from legacy Skia /
/// internal UI headers, serving as the foundational shield for Phase 1 & 2 of
/// the Android embedder migration.
class FlutterEmbedderNative {
 public:
  FlutterEmbedderNative();
  explicit FlutterEmbedderNative(
      std::shared_ptr<JvmInvoker> jvm_invoker,
      const std::shared_ptr<LegacyJniDelegate>& legacy_delegate = nullptr,
      std::shared_ptr<OSLibraryLoader> library_loader = nullptr,
      std::shared_ptr<APKAssetProvider> asset_provider = nullptr,
      std::shared_ptr<CallbackCacheProvider> callback_cache = nullptr,
      std::shared_ptr<ImageDecoderProvider> image_decoder = nullptr,
      std::shared_ptr<EmbedderImageLRU> image_lru = nullptr);
  virtual ~FlutterEmbedderNative();

  /// @brief Checks whether the embedder C-API quarantine is active.
  /// @return True if quarantined and running strictly on top of embedder.h.
  static bool IsQuarantineEnforced();

  /// @brief Verifies that the embedder engine version is compatible with the
  /// current build.
  /// @return True if version verification succeeds.
  static bool VerifyEmbedderVersion();

  /// @brief Returns the version number of the Embedder C-API.
  static size_t GetEmbedderVersion();

  /// @brief Checks whether the Embedder C-API rollout flag is active.
  static bool IsEmbedderEnabled();

  /// @brief Sets the Embedder C-API rollout flag.
  static void SetEmbedderEnabled(bool enabled);

  /// @brief Sets the default global OSLibraryLoader instance.
  static void SetDefaultLibraryLoader(std::shared_ptr<OSLibraryLoader> loader);

  /// @brief Returns the default global OSLibraryLoader instance.
  static std::shared_ptr<OSLibraryLoader> GetDefaultLibraryLoader();

  /// @brief Creates a default JniRouter instance with an injected JvmInvoker.
  static std::shared_ptr<JniRouter> CreateDefaultRouter(
      std::shared_ptr<JvmInvoker> invoker,
      const std::shared_ptr<LegacyJniDelegate>& legacy_delegate = nullptr);

  /// @brief Returns the JniRouter managed by this native instance.
  std::shared_ptr<JniRouter> GetRouter() const;

  /// @brief Returns the JniDelegate managed by this native instance.
  std::shared_ptr<JniDelegate> GetJniDelegate() const;

  /// @brief Returns the JvmInvoker managed by this native instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

  /// @brief Returns the OSLibraryLoader managed by this native instance.
  std::shared_ptr<OSLibraryLoader> GetLibraryLoader() const;

  /// @brief Associates or clears the underlying ANativeWindow surface.
  /// Thread-safe and synchronizes against in-flight presentation.
  void SetNativeWindow(ANativeWindow* window);

  /// @brief Returns the current ANativeWindow surface pointer.
  /// @warning Unsafe raw pointer return susceptible to concurrent lifecycle
  /// races. Prefer AcquireNativeWindow() which increments reference count.
  [[deprecated("Use AcquireNativeWindow() to prevent dangling pointer races")]]
  ANativeWindow* GetNativeWindow();

  /// @brief Acquires and returns a reference-counted ANativeWindow pointer.
  /// The caller takes ownership of the acquired reference and must call
  /// ANativeWindow_release when done on Android. Thread-safe.
  ANativeWindow* AcquireNativeWindow();

  /// @brief Raw buffer descriptor for software presentation blitting.
  struct SoftwareBuffer {
    void* bits = nullptr;
    int32_t width = 0;
    int32_t height = 0;
    int32_t stride = 0;
    int32_t format = 0;
  };

#if defined(__ANDROID__)
  static constexpr int32_t kFormatRgba8888 = WINDOW_FORMAT_RGBA_8888;
  static constexpr int32_t kFormatRgbx8888 = WINDOW_FORMAT_RGBX_8888;
  static constexpr int32_t kFormatRgb565 = WINDOW_FORMAT_RGB_565;
#else
  static constexpr int32_t kFormatRgba8888 = 1;
  static constexpr int32_t kFormatRgbx8888 = 2;
  static constexpr int32_t kFormatRgb565 = 4;
#endif

  /// @brief Pure software raster blitter decoupled from OS handles for
  /// multi-platform testability and verification.
  ///
  /// Blits and formats premultiplied RGBA pixels from allocation to dst_buffer
  /// handling row strides, margin zeroing, bottom-row clearing, and RGB565
  /// un-premultiplication with clamping.
  static bool BlitSoftwareRaster(const void* allocation,
                                 size_t row_bytes,
                                 size_t height,
                                 const SoftwareBuffer& dst_buffer);

  /// @brief Blits software raster pixels directly to the ANativeWindow buffer
  /// using pure Android NDK APIs with zero Skia or engine internal
  /// dependencies.
  ///
  /// Thread-safe: Serializes with other presentation calls and synchronizes
  /// with SetNativeWindow teardown.
  ///
  /// @param allocation Pointer to the raw software pixel buffer (RGBA_8888,
  ///        premultiplied).
  /// @param row_bytes Byte stride per row in the allocation buffer.
  /// @param height Height of the allocation buffer in pixels.
  /// @return True if presentation succeeded, false otherwise.
  bool PresentSoftware(const void* allocation, size_t row_bytes, size_t height);

  /// @brief Returns the APKAssetProvider managed by this native instance.
  std::shared_ptr<APKAssetProvider> GetAssetProvider() const;

  /// @brief Sets or replaces the APKAssetProvider managed by this native
  /// instance.
  void SetAssetProvider(std::shared_ptr<APKAssetProvider> provider);

  /// @brief Updates the asset manager from Java JNI.
  void UpdateJavaAssetManager(JNIEnv* env,
                              jobject jasset_manager,
                              const std::string& asset_bundle_path);

  /// @brief Resolves an asset by name using the managed asset provider.
  std::unique_ptr<fml::Mapping> ResolveAsset(
      const std::string& asset_name) const;

  /// @brief Resolves asset mappings by pattern and optional subdirectory.
  std::vector<std::unique_ptr<fml::Mapping>> ResolveAssetMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir = std::nullopt) const;

  /// @brief Creates a FlutterCustomAssetResolver bridge structure compatible
  /// with the embedder C-API.
  FlutterCustomAssetResolver CreateCustomAssetResolver() const;

  /// @brief Creates a cloned AssetResolver for engine initialization.
  std::unique_ptr<AssetResolver> CreateAssetResolver() const;

  /// @brief Returns the CallbackCacheProvider managed by this native instance.
  std::shared_ptr<CallbackCacheProvider> GetCallbackCache() const;

  /// @brief Sets or replaces the CallbackCacheProvider managed by this native
  /// instance.
  void SetCallbackCache(std::shared_ptr<CallbackCacheProvider> provider);

  /// @brief Looks up Dart callback information for a given callback handle.
  std::optional<DartCallbackInfo> LookupCallbackInformation(
      int64_t handle) const;

  /// @brief Returns the ImageDecoderProvider managed by this native instance.
  std::shared_ptr<ImageDecoderProvider> GetImageDecoderProvider() const;

  /// @brief Sets or replaces the ImageDecoderProvider.
  void SetImageDecoderProvider(std::shared_ptr<ImageDecoderProvider> provider);

  /// @brief Decodes an image using the managed image decoder provider.
  bool DecodeImage(const uint8_t* data,
                   size_t size,
                   int64_t generator_handle) const;

  /// @brief Notifies that image header dimensions are parsed.
  void OnNativeImageHeader(int64_t generator_handle,
                           int32_t width,
                           int32_t height) const;

  /// @brief Gets parsed image header info for a generator handle.
  std::optional<ImageHeaderInfo> GetImageHeader(int64_t generator_handle) const;

  /// @brief Removes parsed image header info for a generator handle.
  void RemoveImageHeader(int64_t generator_handle) const;

  /// @brief Registers this instance's image decoder with the engine.
  FlutterEngineResult RegisterImageDecoder(FLUTTER_API_SYMBOL(FlutterEngine)
                                               engine,
                                           int32_t priority = -1);

  /// @brief Unregisters this instance's image decoder from the engine.
  FlutterEngineResult UnregisterImageDecoder();

  /// @brief Returns the EmbedderImageLRU cache managed by this instance.
  std::shared_ptr<EmbedderImageLRU> GetImageLRU() const;

  /// @brief Sets or replaces the EmbedderImageLRU cache.
  void SetImageLRU(std::shared_ptr<EmbedderImageLRU> lru);

 private:
  static std::mutex default_library_loader_mutex_;
  static std::shared_ptr<OSLibraryLoader> default_library_loader_;

  std::mutex surface_mutex_;
  std::mutex presentation_mutex_;
  mutable std::mutex asset_provider_mutex_;
  mutable std::mutex image_lru_mutex_;
  ANativeWindow* native_window_ = nullptr;

  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<EmbedderImageLRU> image_lru_;
  std::shared_ptr<JniDelegate> jni_delegate_;
  std::shared_ptr<JniRouter> jni_router_;
  std::shared_ptr<OSLibraryLoader> library_loader_;
  std::shared_ptr<APKAssetProvider> asset_provider_;

  mutable std::mutex decoder_registration_mutex_;
  FLUTTER_API_SYMBOL(FlutterEngine) registered_engine_ = nullptr;
  FlutterImageDecoderRegistration decoder_registration_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
