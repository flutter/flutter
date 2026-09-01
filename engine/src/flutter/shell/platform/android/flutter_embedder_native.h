// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_

#include <jni.h>
#include <atomic>
#include <cstddef>
#include <map>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/platform/android/android_engine_group.h"
#include "flutter/shell/platform/android/android_hardware_buffer.h"
#include "flutter/shell/platform/android/android_mutators_mapper.h"
#include "flutter/shell/platform/android/android_platform_views_controller.h"
#include "flutter/shell/platform/android/android_semantics_mapper.h"
#include "flutter/shell/platform/android/android_surface_control.h"
#include "flutter/shell/platform/android/android_vm_init.h"
#include "flutter/shell/platform/android/android_vsync_waiter.h"
#include "flutter/shell/platform/android/android_vulkan_texture.h"
#include "flutter/shell/platform/android/android_window_metrics_mapper.h"
#include "flutter/shell/platform/android/apk_asset_provider.h"
#include "flutter/shell/platform/android/jni_delegate.h"
#include "flutter/shell/platform/android/jni_router.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "flutter/shell/platform/embedder/embedder.h"

#if defined(__ANDROID__)
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <android/native_window.h>
#endif

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
      std::shared_ptr<WindowMetricsProvider> window_metrics_provider = nullptr,
      std::shared_ptr<AndroidChoreographerProvider> choreographer_provider =
          nullptr,
      std::shared_ptr<AndroidVsyncWaiter> vsync_waiter = nullptr,
      std::shared_ptr<FontCollectionProvider> font_provider = nullptr,
      std::shared_ptr<AndroidAOTProvider> aot_provider = nullptr,
      std::shared_ptr<AndroidVMInit> vm_init = nullptr,
      std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider =
          nullptr,
      std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider =
          nullptr,
      std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider =
          nullptr,
      std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider =
          nullptr,
      std::shared_ptr<AndroidEngineGroup> engine_group = nullptr);
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

  /// @brief Registers all JNI native methods for
  /// io.flutter.embedding.engine.FlutterJNI directly with FlutterEmbedderNative
  /// and JniRouter.
  /// @param env JNIEnv pointer.
  /// @return True if JNI native registration succeeded.
  static bool RegisterJni(JNIEnv* env);

  /// @brief Sets the default global OSLibraryLoader instance.
  static void SetDefaultLibraryLoader(std::shared_ptr<OSLibraryLoader> loader);

  /// @brief Returns the default global OSLibraryLoader instance.
  static std::shared_ptr<OSLibraryLoader> GetDefaultLibraryLoader();

  /// @brief Sets the default global AndroidVsyncWaiter instance.
  static void SetDefaultVsyncWaiter(std::shared_ptr<AndroidVsyncWaiter> waiter);

  /// @brief Returns the default global AndroidVsyncWaiter instance.
  static std::shared_ptr<AndroidVsyncWaiter> GetDefaultVsyncWaiter();

  /// @brief Creates a default JniRouter instance with an injected JvmInvoker.
  static std::shared_ptr<JniRouter> CreateDefaultRouter(
      std::shared_ptr<JvmInvoker> invoker,
      const std::shared_ptr<LegacyJniDelegate>& legacy_delegate = nullptr,
      std::shared_ptr<PlatformViewsProvider> platform_views_provider = nullptr,
      std::shared_ptr<WindowMetricsProvider> window_metrics_provider = nullptr,
      std::shared_ptr<AndroidVsyncWaiter> vsync_waiter = nullptr,
      std::shared_ptr<AndroidVMInit> vm_init = nullptr,
      std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider =
          nullptr,
      std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider =
          nullptr,
      std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider =
          nullptr,
      std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider =
          nullptr,
      std::shared_ptr<AndroidEngineGroup> engine_group = nullptr);

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

  /// @brief Updates the APKAssetProvider from Java JNI parameters and notifies
  /// the running engine.
  void UpdateAssetManager(JNIEnv* env,
                          jobject jasset_manager,
                          const std::string& bundle_path);

  /// @brief Creates a FlutterCustomAssetResolver referencing this instance.
  FlutterCustomAssetResolver CreateCustomAssetResolver();

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

  /// @brief Sets whether HC++ presentation is supported and enabled.
  bool SetHcppEnabled(bool enabled) const;

  /// @brief Checks whether HC++ presentation is supported and enabled.
  bool IsHcppEnabled() const;

  /// @brief Creates a SurfaceControl transaction for HC++.
  bool CreatePlatformViewTransaction() const;

  /// @brief Swaps active SurfaceControl transactions for HC++.
  bool SwapPlatformViewTransactions() const;

  /// @brief Applies pending SurfaceControl transactions for HC++.
  bool ApplyPlatformViewTransactions() const;

  /// @brief Creates a native SurfaceControl node.
  bool CreateSurfaceControl(int64_t surface_id,
                            const std::string& debug_name = "") const;

  /// @brief Destroys a native SurfaceControl node.
  bool DestroySurfaceControl(int64_t surface_id) const;

  /// @brief Reparents a native SurfaceControl node.
  bool ReparentSurfaceControl(int64_t surface_id, int64_t new_parent_id) const;

  /// @brief Sets geometry on a native SurfaceControl node.
  bool SetSurfaceControlGeometry(int64_t surface_id,
                                 const AndroidSurfaceControlRect& source,
                                 const AndroidSurfaceControlRect& destination,
                                 int32_t transform = 0) const;

  /// @brief Sets visibility on a native SurfaceControl node.
  bool SetSurfaceControlVisibility(int64_t surface_id, bool visible) const;

  /// @brief Sets z-order on a native SurfaceControl node.
  bool SetSurfaceControlZOrder(int64_t surface_id, int32_t z_order) const;

  /// @brief Sets damage region on a native SurfaceControl node.
  bool SetSurfaceControlDamageRegion(
      int64_t surface_id,
      const std::vector<AndroidSurfaceControlRect>& rects) const;

  /// @brief Sets buffer and fence on a native SurfaceControl node.
  bool SetSurfaceControlBuffer(int64_t surface_id,
                               void* buffer,
                               int fence_fd = -1) const;

  /// @brief Sets buffer alpha on a native SurfaceControl node.
  bool SetSurfaceControlBufferAlpha(int64_t surface_id, float alpha) const;

  /// @brief Sets color on a native SurfaceControl node.
  bool SetSurfaceControlColor(int64_t surface_id,
                              float r,
                              float g,
                              float b,
                              float alpha) const;

  /// @brief Returns the state snapshot of a SurfaceControl node.
  std::optional<AndroidSurfaceControlState> GetSurfaceControlState(
      int64_t surface_id) const;

  /// @brief Returns the managed AndroidSurfaceControl instance by surface ID.
  std::shared_ptr<AndroidSurfaceControl> GetSurfaceControl(
      int64_t surface_id) const;

  /// @brief Returns the AndroidSurfaceControlProvider managed by this instance.
  std::shared_ptr<AndroidSurfaceControlProvider> GetSurfaceControlProvider()
      const;

  /// @brief Sets or replaces the AndroidSurfaceControlProvider.
  void SetSurfaceControlProvider(
      std::shared_ptr<AndroidSurfaceControlProvider> provider);

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

  /// @brief Returns the AndroidChoreographerProvider managed by this instance.
  std::shared_ptr<AndroidChoreographerProvider> GetChoreographerProvider()
      const;

  /// @brief Sets or replaces the AndroidChoreographerProvider.
  void SetChoreographerProvider(
      std::shared_ptr<AndroidChoreographerProvider> provider);

  /// @brief Returns the AndroidVsyncWaiter managed by this instance.
  std::shared_ptr<AndroidVsyncWaiter> GetVsyncWaiter() const;

  /// @brief Sets or replaces the AndroidVsyncWaiter.
  void SetVsyncWaiter(std::shared_ptr<AndroidVsyncWaiter> waiter);

  /// @brief Static C-API compatible vsync callback function matching
  /// FlutterProjectArgs::vsync_callback.
  static void OnVsyncCallback(void* user_data, intptr_t baton);

  /// @brief Asynchronously requests a VSync signal for the given baton.
  bool AsyncWaitForVsync(intptr_t baton) const;

  /// @brief Sets the active display refresh rate in Hz.
  void UpdateRefreshRate(double refresh_rate_hz) const;

  /// @brief Returns the current display refresh rate in Hz.
  double GetRefreshRate() const;

  /// @brief Returns the calculated refresh period in nanoseconds.
  int64_t GetRefreshPeriodNanos() const;

  /// @brief Computes frame pacing timestamps for a given frame start time and
  /// refresh rate.
  AndroidVsyncFrameInfo ComputeFramePacing(int64_t frame_time_nanos,
                                           double refresh_rate_hz) const;

  /// @brief Directly notifies the running engine instance of a VSync event
  /// via FlutterEngineOnVsync.
  FlutterEngineResult NotifyVsync(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                  intptr_t baton,
                                  int64_t frame_start_time_nanos,
                                  int64_t frame_target_time_nanos) const;

  /// @brief Initializes the Android VM with the specified arguments.
  bool InitVM(const AndroidVMArgs& args) const;

  /// @brief Prefetches the default font collection.
  bool PrefetchDefaultFontManager() const;

  /// @brief Sets the Dart VM service URI and updates JVM.
  bool SetVmServiceUri(const std::string& uri) const;

  /// @brief Returns the last recorded VM service URI.
  std::string GetVmServiceUri() const;

  /// @brief Returns whether VM initialization has completed.
  bool IsVMInitialized() const;

  /// @brief Returns the VM arguments if initialized.
  std::optional<AndroidVMArgs> GetVMArgs() const;

  /// @brief Returns the selected AndroidRenderingAPI.
  AndroidRenderingAPI GetSelectedRenderingAPI() const;

  /// @brief Returns populated FlutterProjectArgs pointer (valid after InitVM).
  const FlutterProjectArgs* GetProjectArgs() const;

  /// @brief Initializes a FlutterEngine instance via C-API
  /// FlutterEngineInitialize.
  FlutterEngineResult InitializeEngine(const FlutterRendererConfig* config,
                                       const FlutterProjectArgs* args,
                                       void* user_data,
                                       FLUTTER_API_SYMBOL(FlutterEngine) *
                                           engine_out) const;

  /// @brief Deinitializes a FlutterEngine instance via C-API
  /// FlutterEngineDeinitialize.
  FlutterEngineResult DeinitializeEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                             engine) const;

  /// @brief Creates AOT data structure via C-API FlutterEngineCreateAOTData.
  FlutterEngineResult CreateAOTData(const FlutterEngineAOTDataSource* source,
                                    FlutterEngineAOTData* data_out) const;

  /// @brief Collects AOT data structure via C-API FlutterEngineCollectAOTData.
  FlutterEngineResult CollectAOTData(FlutterEngineAOTData data) const;

  /// @brief Returns the AndroidVMInit instance managed by this native instance.
  std::shared_ptr<AndroidVMInit> GetVMInit() const;

  /// @brief Sets or replaces the AndroidVMInit instance.
  void SetVMInit(std::shared_ptr<AndroidVMInit> vm_init);

  /// @brief Returns the FontCollectionProvider managed by this native instance.
  std::shared_ptr<FontCollectionProvider> GetFontCollectionProvider() const;

  /// @brief Sets or replaces the FontCollectionProvider.
  void SetFontCollectionProvider(
      std::shared_ptr<FontCollectionProvider> provider);

  /// @brief Returns the AndroidAOTProvider managed by this native instance.
  std::shared_ptr<AndroidAOTProvider> GetAOTProvider() const;

  /// @brief Sets or replaces the AndroidAOTProvider.
  void SetAOTProvider(std::shared_ptr<AndroidAOTProvider> provider);

  /// @brief Returns the AndroidHardwareBufferProvider managed by this instance.
  std::shared_ptr<AndroidHardwareBufferProvider> GetHardwareBufferProvider()
      const;

  /// @brief Sets or replaces the AndroidHardwareBufferProvider.
  void SetHardwareBufferProvider(
      std::shared_ptr<AndroidHardwareBufferProvider> provider);

  /// @brief Registers a hardware buffer texture by ID.
  bool RegisterHardwareBufferTexture(
      int64_t texture_id,
      const std::shared_ptr<AndroidHardwareBuffer>& initial_buffer =
          nullptr) const;

  /// @brief Unregisters a hardware buffer texture by ID.
  bool UnregisterHardwareBufferTexture(int64_t texture_id) const;

  /// @brief Sets the next hardware buffer frame for a texture.
  bool SetHardwareBufferFrame(
      int64_t texture_id,
      const std::shared_ptr<AndroidHardwareBuffer>& buffer) const;

  /// @brief Sets the next hardware buffer frame from a C-API struct.
  bool SetHardwareBufferFrame(
      int64_t texture_id,
      const FlutterHardwareBufferExternalTexture& texture) const;

  /// @brief Retrieves the latest hardware buffer frame for a texture.
  bool GetHardwareBufferTextureFrame(
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterHardwareBufferExternalTexture* texture_out) const;

  /// @brief Notifies that a hardware buffer frame is available for texture_id.
  bool OnHardwareBufferFrameAvailable(int64_t texture_id) const;

  /// @brief Static C-API callback entry point for
  /// FlutterHardwareBufferExternalTextureFrameCallback.
  static bool OnHardwareBufferExternalTextureFrameCallback(
      void* user_data,
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterHardwareBufferExternalTexture* texture_out);

  /// @brief Returns a function pointer to the C-API frame callback.
  static FlutterHardwareBufferExternalTextureFrameCallback
  GetHardwareBufferFrameCallback();

  /// @brief Signals the engine that a texture has a new frame ready via
  /// FlutterEngineMarkExternalTextureFrameAvailable.
  FlutterEngineResult MarkExternalTextureFrameAvailable(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      int64_t texture_id) const;

  /// @brief Schedules a frame to be rendered by the engine via
  /// FlutterEngineScheduleFrame.
  FlutterEngineResult ScheduleFrame(FLUTTER_API_SYMBOL(FlutterEngine)
                                        engine) const;

  /// @brief Registers a surface texture with the weak reference.
  void RegisterSurfaceTexture(JNIEnv* env,
                              int64_t texture_id,
                              jobject surface_texture);

  /// @brief Unregisters a surface texture by ID.
  void UnregisterSurfaceTexture(JNIEnv* env, int64_t texture_id);

  /// @brief Retrieves the latest GL external texture frame for a texture.
  bool GetGlExternalTextureFrame(int64_t texture_id,
                                 size_t width,
                                 size_t height,
                                 FlutterOpenGLTexture* texture_out) const;

  /// @brief Static C-API callback entry point for
  /// FlutterOpenGLRendererConfig::gl_external_texture_frame_callback.
  static bool OnGlExternalTextureFrameCallback(
      void* user_data,
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterOpenGLTexture* texture_out);

  /// @brief Marks all registered surface textures as having a frame available.
  void MarkAllTexturesFrameAvailable() const;

  /// @brief Registers an external texture on the engine via
  /// FlutterEngineRegisterExternalTexture.
  FlutterEngineResult RegisterExternalTexture(FLUTTER_API_SYMBOL(FlutterEngine)
                                                  engine,
                                              int64_t texture_id) const;

  /// @brief Unregisters an external texture on the engine via
  /// FlutterEngineUnregisterExternalTexture.
  FlutterEngineResult UnregisterExternalTexture(
      FLUTTER_API_SYMBOL(FlutterEngine) engine,
      int64_t texture_id) const;

  /// @brief Returns the AndroidVulkanTextureProvider managed by this instance.
  std::shared_ptr<AndroidVulkanTextureProvider> GetVulkanTextureProvider()
      const;

  /// @brief Sets or replaces the AndroidVulkanTextureProvider.
  void SetVulkanTextureProvider(
      std::shared_ptr<AndroidVulkanTextureProvider> provider);

  /// @brief Registers a Vulkan external texture by ID.
  bool RegisterVulkanTexture(
      int64_t texture_id,
      const std::shared_ptr<AndroidVulkanExternalTexture>& initial_texture =
          nullptr) const;

  /// @brief Unregisters a Vulkan external texture by ID.
  bool UnregisterVulkanTexture(int64_t texture_id) const;

  /// @brief Sets the next Vulkan texture frame for a texture.
  bool SetVulkanTextureFrame(
      int64_t texture_id,
      const std::shared_ptr<AndroidVulkanExternalTexture>& texture) const;

  /// @brief Sets the next Vulkan texture frame from a C-API struct.
  bool SetVulkanTextureFrame(int64_t texture_id,
                             const FlutterVulkanExternalTexture& texture) const;

  /// @brief Retrieves the latest Vulkan texture frame for a texture.
  bool GetVulkanTextureFrame(int64_t texture_id,
                             size_t width,
                             size_t height,
                             FlutterVulkanExternalTexture* texture_out) const;

  /// @brief Notifies that a Vulkan frame is available for texture_id.
  bool OnVulkanTextureFrameAvailable(int64_t texture_id) const;

  /// @brief Static C-API callback entry point for
  /// FlutterVulkanExternalTextureFrameCallback.
  static bool OnVulkanExternalTextureFrameCallback(
      void* user_data,
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterVulkanExternalTexture* texture_out);

  /// @brief Returns a function pointer to the C-API Vulkan frame callback.
  static FlutterVulkanExternalTextureFrameCallback
  GetVulkanExternalTextureFrameCallback();

  /// @brief Returns the AndroidEngineGroup managed by this native instance.
  std::shared_ptr<AndroidEngineGroup> GetEngineGroup() const;

  /// @brief Sets or replaces the AndroidEngineGroup.
  void SetEngineGroup(std::shared_ptr<AndroidEngineGroup> group);

  /// @brief Returns the AndroidEngineGroupProvider managed by this native
  /// instance.
  std::shared_ptr<AndroidEngineGroupProvider> GetEngineGroupProvider() const;

  /// @brief Sets or replaces the AndroidEngineGroupProvider.
  void SetEngineGroupProvider(
      std::shared_ptr<AndroidEngineGroupProvider> provider);

  /// @brief Spawns a new FlutterEngine from parent with spawn args via C-API.
  FLUTTER_API_SYMBOL(FlutterEngine)
  SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
              const AndroidEngineSpawnArgs& args) const;

  /// @brief Spawns a new FlutterEngine from parent with raw config via C-API.
  FLUTTER_API_SYMBOL(FlutterEngine)
  SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine) parent_engine,
              const FlutterEngineSpawnConfig* config,
              int64_t engine_id = 0) const;

  /// @brief Spawns a new FlutterEngine instance via direct C-API
  /// FlutterEngineSpawn.
  FlutterEngineResult SpawnEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                      parent_engine,
                                  const FlutterEngineSpawnConfig* config,
                                  FLUTTER_API_SYMBOL(FlutterEngine) *
                                      engine_out) const;

  /// @brief Shuts down a FlutterEngine instance via direct C-API
  /// FlutterEngineShutdown.
  FlutterEngineResult ShutdownEngine(FLUTTER_API_SYMBOL(FlutterEngine)
                                         engine) const;

  /// @brief Shuts down a spawned engine by engine ID.
  bool ShutdownSpawnedEngine(int64_t engine_id) const;

  /// @brief Handles JVM GC cleaner callback for an engine ID.
  bool OnEngineGarbageCollected(int64_t engine_id) const;

  /// @brief Returns active engine count in the group.
  size_t GetActiveEngineCount() const;

  /// @brief Returns the underlying C-API FlutterEngine instance.
  FLUTTER_API_SYMBOL(FlutterEngine) GetEngine() const;

  /// @brief Runs the FlutterEngine with the given bundle path and entrypoint.
  FlutterEngineResult RunEngineWithBundle(
      const std::string& bundle_path,
      const std::string& entrypoint,
      const std::vector<std::string>& entrypoint_args,
      int64_t engine_id);

  /// @brief Sends a platform message to the FlutterEngine.
  FlutterEngineResult SendPlatformMessage(const std::string& channel,
                                          const uint8_t* message_data,
                                          size_t message_size,
                                          int32_t response_id = 0) const;

  /// @brief Sends a platform message to the FlutterEngine.
  FlutterEngineResult SendPlatformMessage(const std::string& channel,
                                          const std::vector<uint8_t>& message,
                                          int32_t response_id) const;

  /// @brief Sends a platform message response to the FlutterEngine.
  FlutterEngineResult SendPlatformMessageResponse(int32_t response_id,
                                                  const uint8_t* data,
                                                  size_t data_length) const;

  /// @brief Sends a platform message response to the FlutterEngine.
  FlutterEngineResult SendPlatformMessageResponse(
      int32_t response_id,
      const std::vector<uint8_t>& data) const;

  /// @brief Sends pointer events to the FlutterEngine.
  FlutterEngineResult SendPointerEvents(FLUTTER_API_SYMBOL(FlutterEngine)
                                            engine,
                                        const FlutterPointerEvent* events,
                                        size_t events_count) const;

  /// @brief Dispatches a raw pointer data packet buffer to the engine.
  void DispatchPointerDataPacket(const uint8_t* buffer, size_t size);

  /// @brief Initializes EGL display, config, context, and surfaces.
  bool EnsureEGLInitialized();

  /// @brief Tears down EGL context and surface state.
  void TeardownEGL();

  /// @brief OpenGL make_current callback.
  bool MakeCurrent();

  /// @brief OpenGL clear_current callback.
  bool ClearCurrent();

  /// @brief OpenGL make_resource_current callback.
  bool MakeResourceCurrent();

  /// @brief OpenGL present callback.
  bool Present();

  /// @brief OpenGL fbo_callback.
  uint32_t FboCallback() const;

  /// @brief OpenGL gl_proc_resolver callback.
  void* GlProcResolver(const char* name) const;

  /// @brief Android SurfaceCreated handler.
  void SurfaceCreated(JNIEnv* env, jobject jsurface);

  /// @brief Android SurfaceWindowChanged handler.
  void SurfaceWindowChanged(JNIEnv* env, jobject jsurface);

  /// @brief Android SurfaceChanged handler.
  void SurfaceChanged(int32_t width, int32_t height);

  /// @brief Android SurfaceDestroyed handler.
  void SurfaceDestroyed();

  /// @brief Static C-API callback entry point for
  /// FlutterPlatformMessageCallback.
  static void OnPlatformMessageCallback(const FlutterPlatformMessage* message,
                                        void* user_data);

 private:
  static std::shared_ptr<OSLibraryLoader> default_library_loader_;

  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;
  mutable std::mutex response_mutex_;
  mutable std::atomic<int32_t> next_response_id_{1};
  mutable std::map<int32_t, const FlutterPlatformMessageResponseHandle*>
      pending_responses_;
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::shared_ptr<CallbackCacheProvider> callback_cache_;
  std::shared_ptr<ImageDecoderProvider> image_decoder_;
  std::shared_ptr<EmbedderImageLRU> image_lru_;
  std::shared_ptr<PlatformViewsProvider> platform_views_provider_;
  std::shared_ptr<WindowMetricsProvider> window_metrics_provider_;
  std::shared_ptr<OSLibraryLoader> library_loader_;
  std::shared_ptr<AndroidChoreographerProvider> choreographer_provider_;
  std::shared_ptr<AndroidVsyncWaiter> vsync_waiter_;
  std::shared_ptr<FontCollectionProvider> font_provider_;
  std::shared_ptr<AndroidAOTProvider> aot_provider_;
  std::shared_ptr<AndroidVMInit> vm_init_;
  std::shared_ptr<AndroidHardwareBufferProvider> hardware_buffer_provider_;
  std::shared_ptr<AndroidVulkanTextureProvider> vulkan_texture_provider_;
  std::shared_ptr<AndroidSurfaceControlProvider> surface_control_provider_;
  std::shared_ptr<AndroidEngineGroupProvider> engine_group_provider_;
  std::shared_ptr<AndroidEngineGroup> engine_group_;
  std::shared_ptr<AndroidPlatformViewsController> platform_views_controller_;
  std::shared_ptr<JniDelegate> jni_delegate_;
  std::shared_ptr<JniRouter> jni_router_;
  std::shared_ptr<APKAssetProvider> asset_provider_;

  struct SurfaceTextureEntry {
    fml::jni::ScopedJavaGlobalRef<jobject> weak_surface_texture;
    uint32_t gl_texture_id = 0;
    bool attached = false;
  };
  mutable std::mutex surface_textures_mutex_;
  mutable std::map<int64_t, std::unique_ptr<SurfaceTextureEntry>>
      surface_textures_;

#if defined(__ANDROID__)
  EGLDisplay display_ = EGL_NO_DISPLAY;
  EGLConfig config_ = nullptr;
  EGLContext render_context_ = EGL_NO_CONTEXT;
  EGLContext resource_context_ = EGL_NO_CONTEXT;
  EGLSurface pbuffer_surface_ = EGL_NO_SURFACE;
  EGLSurface window_surface_ = EGL_NO_SURFACE;
  ANativeWindow* native_window_ = nullptr;
  bool egl_initialized_ = false;
  mutable std::mutex surface_mutex_;
#endif

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
