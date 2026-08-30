// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_

#include <cstddef>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_mutators_mapper.h"
#include "flutter/shell/platform/android/android_platform_views_controller.h"
#include "flutter/shell/platform/android/android_semantics_mapper.h"
#include "flutter/shell/platform/android/android_window_metrics_mapper.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

/// @brief Default C-API backed callback cache provider that calls
/// FlutterEngineGetCallbackInformation.
class DefaultCallbackCacheProvider : public CallbackCacheProvider {
 public:
  DefaultCallbackCacheProvider();
  ~DefaultCallbackCacheProvider() override;

  std::optional<DartCallbackInfo> GetCallbackInformation(
      int64_t handle) override;
};

/// @brief In-memory mock callback cache provider for unit testing without
/// Dart VM or disk cache dependencies.
class InMemoryCallbackCacheProvider : public CallbackCacheProvider {
 public:
  InMemoryCallbackCacheProvider();
  ~InMemoryCallbackCacheProvider() override;

  void AddCallback(int64_t handle,
                   const std::string& name,
                   const std::string& class_name,
                   const std::string& library_path);

  void RemoveCallback(int64_t handle);

  void Clear();

  size_t GetSize() const;

  std::optional<DartCallbackInfo> GetCallbackInformation(
      int64_t handle) override;

 private:
  mutable std::mutex mutex_;
  std::map<int64_t, DartCallbackInfo> cache_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryCallbackCacheProvider);
};

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

 private:
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
      std::shared_ptr<EmbedderImageLRU> image_lru = nullptr,
      std::shared_ptr<PlatformViewsProvider> platform_views_provider = nullptr,
      std::shared_ptr<WindowMetricsProvider> window_metrics_provider = nullptr);
  ~FlutterEmbedderNative();

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
      const std::shared_ptr<LegacyJniDelegate>& legacy_delegate = nullptr,
      std::shared_ptr<PlatformViewsProvider> platform_views_provider = nullptr,
      std::shared_ptr<WindowMetricsProvider> window_metrics_provider = nullptr);

  /// @brief Returns the JniRouter managed by this native instance.
  std::shared_ptr<JniRouter> GetRouter() const;

  /// @brief Returns the JniDelegate managed by this native instance.
  std::shared_ptr<JniDelegate> GetJniDelegate() const;

  /// @brief Returns the JvmInvoker managed by this native instance.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

  /// @brief Returns the OSLibraryLoader managed by this native instance.
  std::shared_ptr<OSLibraryLoader> GetLibraryLoader() const;

  /// @brief Returns the APKAssetProvider managed by this native instance.
  std::shared_ptr<APKAssetProvider> GetAssetProvider() const;

  /// @brief Sets or replaces the APKAssetProvider managed by this native
  /// instance.
  void SetAssetProvider(std::shared_ptr<APKAssetProvider> provider);

  /// @brief Resolves an asset by name using the managed asset provider.
  std::unique_ptr<fml::Mapping> ResolveAsset(
      const std::string& asset_name) const;

  /// @brief Resolves asset mappings by pattern and optional subdirectory.
  std::vector<std::unique_ptr<fml::Mapping>> ResolveAssetMappings(
      const std::string& asset_pattern,
      const std::optional<std::string>& subdir = std::nullopt) const;

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

  /// @brief Registers this instance's image decoder with the engine.
  FlutterEngineResult RegisterImageDecoder(FLUTTER_API_SYMBOL(FlutterEngine)
                                               engine,
                                           int32_t priority = -1);

  /// @brief Returns the EmbedderImageLRU cache managed by this instance.
  std::shared_ptr<EmbedderImageLRU> GetImageLRU() const;

  /// @brief Sets or replaces the EmbedderImageLRU cache.
  void SetImageLRU(std::shared_ptr<EmbedderImageLRU> lru);

  /// @brief Returns the PlatformViewsProvider managed by this native instance.
  std::shared_ptr<PlatformViewsProvider> GetPlatformViewsProvider() const;

  /// @brief Sets or replaces the PlatformViewsProvider.
  void SetPlatformViewsProvider(
      std::shared_ptr<PlatformViewsProvider> provider);

  /// @brief Returns the AndroidPlatformViewsController managed by this
  /// instance.
  std::shared_ptr<AndroidPlatformViewsController> GetPlatformViewsController()
      const;

  /// @brief Creates a platform view in the JVM.
  int64_t CreatePlatformView(
      const PlatformViewCreationParams& params,
      PlatformViewCompositionType composition_type) const;

  /// @brief Disposes a platform view by ID.
  bool DisposePlatformView(int64_t view_id) const;

  /// @brief Resizes a platform view.
  bool ResizePlatformView(const PlatformViewResizeRequest& request) const;

  /// @brief Sets top-left offset for a platform view.
  bool OffsetPlatformView(int64_t view_id, double top, double left) const;

  /// @brief Sets layout direction for a platform view.
  bool SetPlatformViewDirection(int64_t view_id, int32_t direction) const;

  /// @brief Clears focus from a platform view.
  bool ClearPlatformViewFocus(int64_t view_id) const;

  /// @brief Dispatches a touch event to a platform view.
  bool DispatchPlatformViewTouch(const PlatformViewTouch& touch) const;

  /// @brief Positions and displays a platform view with geometry.
  bool OnDisplayPlatformView(const PlatformViewGeometry& geometry) const;

  /// @brief Positions and displays a platform view with FlutterPlatformView.
  bool OnDisplayPlatformView(const FlutterPlatformView& platform_view,
                             int32_t x,
                             int32_t y,
                             int32_t width,
                             int32_t height,
                             int32_t view_width,
                             int32_t view_height) const;

  /// @brief Hides a platform view.
  bool HidePlatformView(int64_t view_id) const;

  /// @brief Synchronizes rendering surface to native view hierarchy.
  bool SynchronizeToNativeViewHierarchy(bool synchronize) const;

  /// @brief Signals start of a frame for hybrid composition.
  bool OnBeginFrame() const;

  /// @brief Signals end of a frame for hybrid composition.
  bool OnEndFrame() const;

  /// @brief Instantiates an overlay surface in hybrid composition.
  std::optional<int32_t> CreateOverlaySurface() const;

  /// @brief Destroys all active overlay surfaces.
  bool DestroyOverlaySurfaces() const;

  /// @brief Positions and sizes an overlay surface.
  bool OnDisplayOverlaySurface(const PlatformViewOverlay& overlay) const;

  /// @brief Shows an overlay surface.
  bool ShowOverlaySurface(int32_t surface_id) const;

  /// @brief Hides an overlay surface.
  bool HideOverlaySurface(int32_t surface_id) const;

  /// @brief Creates a SurfaceControl transaction for HC++.
  bool CreatePlatformViewTransaction() const;

  /// @brief Swaps active SurfaceControl transactions for HC++.
  bool SwapPlatformViewTransactions() const;

  /// @brief Applies pending SurfaceControl transactions for HC++.
  bool ApplyPlatformViewTransactions() const;

  /// @brief Checks whether HC++ presentation is supported and enabled.
  bool IsHcppEnabled() const;

  /// @brief Maps raw platform view mutations into an AndroidMutatorsStack.
  AndroidMutatorsStack MapPlatformViewMutations(
      const FlutterPlatformViewMutation** mutations,
      size_t count) const;

  /// @brief Maps a FlutterPlatformView into an AndroidMutatorsStack.
  AndroidMutatorsStack MapPlatformView(
      const FlutterPlatformView& platform_view) const;

  /// @brief Dispatches platform view mutator stack through JniRouter.
  bool PushPlatformViewMutators(
      int64_t view_id,
      int32_t x,
      int32_t y,
      int32_t width,
      int32_t height,
      const AndroidMutatorsStack& mutators_stack) const;

  /// @brief Dispatches platform view mutations through JniRouter.
  bool PushPlatformViewMutators(const FlutterPlatformView& platform_view,
                                int32_t x,
                                int32_t y,
                                int32_t width,
                                int32_t height) const;

  /// @brief Maps semantics updates and dispatches them through JniRouter.
  bool UpdateSemantics(const FlutterSemanticsUpdate2& update) const;

  /// @brief Dispatches semantics node updates buffer through JniRouter.
  bool UpdateSemantics(const std::vector<uint8_t>& buffer,
                       const std::vector<std::string>& strings,
                       const std::vector<std::vector<uint8_t>>&
                           string_attribute_args = {}) const;

  /// @brief Dispatches custom accessibility action updates through JniRouter.
  bool UpdateCustomAccessibilityActions(
      const std::vector<uint8_t>& buffer,
      const std::vector<std::string>& strings) const;

  /// @brief Dispatches semantics enabled state change through JniRouter.
  bool SetSemanticsEnabled(bool enabled) const;

  /// @brief Dispatches a semantics action through JniRouter.
  bool DispatchSemanticsAction(int32_t node_id,
                               FlutterSemanticsAction action,
                               const std::vector<uint8_t>& data = {},
                               int64_t view_id = 0) const;

  /// @brief Dispatches accessibility features change through JniRouter.
  bool SetAccessibilityFeatures(int32_t flags) const;

  /// @brief Updates semantics enabled state on the FlutterEngine instance.
  FlutterEngineResult UpdateSemanticsEnabled(FLUTTER_API_SYMBOL(FlutterEngine)
                                                 engine,
                                             bool enabled) const;

  /// @brief Updates accessibility features on the FlutterEngine instance.
  FlutterEngineResult UpdateAccessibilityFeatures(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      FlutterAccessibilityFeature features) const;

  /// @brief Sends a semantics action info struct to the FlutterEngine instance.
  FlutterEngineResult SendSemanticsAction(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      const FlutterSendSemanticsActionInfo* info) const;

  /// @brief Dispatches a semantics action to the FlutterEngine instance.
  FlutterEngineResult DispatchSemanticsActionToEngine(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      uint64_t node_id,
      FlutterSemanticsAction action,
      const uint8_t* data = nullptr,
      size_t data_length = 0) const;

  /// @brief Static C-API callback entry point for
  /// FlutterUpdateSemanticsCallback2.
  static void OnUpdateSemantics2(const FlutterSemanticsUpdate2* update,
                                 void* user_data);

  /// @brief Returns the WindowMetricsProvider managed by this native instance.
  std::shared_ptr<WindowMetricsProvider> GetWindowMetricsProvider() const;

  /// @brief Sets or replaces the WindowMetricsProvider.
  void SetWindowMetricsProvider(
      std::shared_ptr<WindowMetricsProvider> provider);

  /// @brief Sends viewport metrics via JniRouter.
  bool SetViewportMetrics(const AndroidViewportMetrics& metrics) const;

  /// @brief Updates display metrics via JniRouter.
  bool UpdateDisplayMetrics(const AndroidDisplayMetrics& metrics) const;

  /// @brief Updates display metrics with parameters via JniRouter.
  bool UpdateDisplayMetrics(uint64_t display_id,
                            double refresh_rate,
                            double width,
                            double height,
                            double device_pixel_ratio) const;

  /// @brief Translates AndroidViewportMetrics to a C-API
  /// FlutterWindowMetricsEvent.
  FlutterWindowMetricsEvent TranslateViewportMetrics(
      const AndroidViewportMetrics& metrics) const;

  /// @brief Translates AndroidDisplayMetrics to a C-API FlutterEngineDisplay.
  FlutterEngineDisplay TranslateDisplayMetrics(
      const AndroidDisplayMetrics& metrics) const;

  /// @brief Sends a FlutterWindowMetricsEvent struct to the engine via C-API.
  FlutterEngineResult SendWindowMetricsEvent(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      const FlutterWindowMetricsEvent* event) const;

  /// @brief Translates and sends AndroidViewportMetrics to the engine via
  /// C-API.
  FlutterEngineResult SendWindowMetricsEvent(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      const AndroidViewportMetrics& metrics) const;

  /// @brief Notifies engine of display updates via C-API.
  FlutterEngineResult NotifyDisplayUpdate(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      FlutterEngineDisplaysUpdateType update_type,
      const FlutterEngineDisplay* displays,
      size_t display_count) const;

  /// @brief Translates and notifies engine of display update via C-API.
  FlutterEngineResult NotifyDisplayUpdate(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      const AndroidDisplayMetrics& display) const;

 private:
  static std::shared_ptr<OSLibraryLoader> default_library_loader_;

  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<CallbackCacheProvider> callback_cache_;
  std::shared_ptr<ImageDecoderProvider> image_decoder_;
  std::shared_ptr<EmbedderImageLRU> image_lru_;
  std::shared_ptr<PlatformViewsProvider> platform_views_provider_;
  std::shared_ptr<WindowMetricsProvider> window_metrics_provider_;
  std::shared_ptr<AndroidPlatformViewsController> platform_views_controller_;
  std::shared_ptr<JniDelegate> jni_delegate_;
  std::shared_ptr<JniRouter> jni_router_;
  std::shared_ptr<OSLibraryLoader> library_loader_;
  std::shared_ptr<APKAssetProvider> asset_provider_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
