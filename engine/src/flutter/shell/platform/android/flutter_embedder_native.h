// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_

#include <jni.h>
#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/thread.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {
class AndroidEngineGroup;
class AndroidHardwareBuffer;
class AndroidHardwareBufferProvider;
class AndroidSurfaceControl;
class AndroidVsyncWaiter;
class AndroidVulkanExternalTexture;
class DefaultAndroidVulkanTextureProvider;
class SurfaceTextureGlToAhbBlitter;
}  // namespace android

using android::AndroidEngineGroup;
using android::AndroidHardwareBuffer;
using android::AndroidHardwareBufferProvider;
using android::AndroidSurfaceControl;
using android::AndroidVsyncWaiter;
using android::AndroidVulkanExternalTexture;
using android::DefaultAndroidVulkanTextureProvider;
using android::SurfaceTextureGlToAhbBlitter;
class AndroidPlatformViewsController;
class APKAssetProvider;

// Minimum Android API level for the NDK AImageDecoder (Android 9 Pie / API 28).
constexpr int kMinApiLevelForNdkImageDecoder = 28;
// Priority for the Android SDK/NDK fallback image decoder (runs after built-in
// decoders which have priority 0).
constexpr int32_t kAndroidSdkImageDecoderPriority = -1;
// Default display pixel ratio prior to receiving viewport metrics.
constexpr double kDefaultInitialPixelRatio = 1.0;
// Unset display corner radius sentinel value.
constexpr int32_t kUnsetCornerRadiusSentinel = -1;

// Manages the C-API FlutterCustomTaskRunners for the Android embedder.
class AndroidTaskRunners {
 public:
  AndroidTaskRunners();
  explicit AndroidTaskRunners(
      fml::RefPtr<fml::TaskRunner> platform_task_runner,
      bool use_engine_owned_platform_and_render_runners = false);
  ~AndroidTaskRunners();

  const FlutterCustomTaskRunners* GetCustomTaskRunners() const {
    return &custom_task_runners_;
  }

  fml::RefPtr<fml::TaskRunner> GetPlatformTaskRunner() const {
    return platform_task_runner_;
  }

  bool UsesEngineOwnedPlatformAndRenderRunners() const {
    return use_engine_owned_platform_and_render_runners_;
  }

  static bool RunsTasksOnCurrentThreadCallback(void* user_data);
  static void PostTaskCallback(FlutterTask task,
                               uint64_t target_time_nanos,
                               void* user_data);

  void SetTaskExecutionCallback(
      std::function<void(FlutterTask)> execute_callback) {
    std::lock_guard<std::mutex> lock(callback_mutex_);
    execute_callback_ = std::move(execute_callback);
  }

 private:
  void InitializeRunnerStructs();
  void PostTask(FlutterTask task, uint64_t target_time_nanos);
  bool RunsTasksOnCurrentThread() const;

  fml::RefPtr<fml::TaskRunner> platform_task_runner_;
  std::unique_ptr<fml::Thread> fallback_thread_;
  bool use_engine_owned_platform_and_render_runners_ = false;
  FlutterTaskRunnerDescription platform_runner_description_{};
  FlutterCustomTaskRunners custom_task_runners_{};

  mutable std::mutex callback_mutex_;
  std::function<void(FlutterTask)> execute_callback_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidTaskRunners);
};

// Delegate interface for platform view composition callbacks during
// FlutterCompositor frames.
class AndroidCompositorPlatformViewDelegate {
 public:
  virtual ~AndroidCompositorPlatformViewDelegate() = default;

  virtual void OnBeginFrame() = 0;
  virtual void OnDisplayPlatformView(int64_t view_id,
                                     double x,
                                     double y,
                                     double width,
                                     double height,
                                     const FlutterPlatformView* view) = 0;
  virtual void OnEndFrame() = 0;
};

// Implements the FlutterCompositor C-API callbacks for the Android embedder.
class AndroidCompositor {
 public:
  struct BackingStoreData {
    int64_t id = 0;
    size_t width = 0;
    size_t height = 0;
    std::vector<uint8_t> pixels;
  };

  explicit AndroidCompositor(
      AndroidCompositorPlatformViewDelegate* delegate = nullptr,
      bool enable_surface_control = false,
      int api_level = 0);
  ~AndroidCompositor();

  const FlutterCompositor* GetEmbedderCompositor() const {
    return &compositor_;
  }

  void ConfigureForPlatform(bool enable_surface_control, int api_level);

  size_t GetAllocatedStoreCount() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return allocated_stores_.size();
  }

  size_t GetPresentCount() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return present_count_;
  }

 private:
  static bool CreateBackingStoreCallback(
      const FlutterBackingStoreConfig* config,
      FlutterBackingStore* backing_store_out,
      void* user_data);

  static bool CollectBackingStoreCallback(const FlutterBackingStore* renderer,
                                          void* user_data);

  static bool PresentLayersCallback(const FlutterLayer** layers,
                                    size_t layers_count,
                                    void* user_data);

  bool OnCreateBackingStore(const FlutterBackingStoreConfig* config,
                            FlutterBackingStore* backing_store_out);
  bool OnCollectBackingStore(const FlutterBackingStore* renderer);
  bool OnPresentLayers(const FlutterLayer** layers, size_t layers_count);

  AndroidCompositorPlatformViewDelegate* delegate_ = nullptr;
  FlutterCompositor compositor_{};

  mutable std::mutex mutex_;
  int64_t next_store_id_ = 1;
  std::unordered_map<int64_t, std::unique_ptr<BackingStoreData>>
      allocated_stores_;
  size_t present_count_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidCompositor);
};

// Surface lifecycle state machine for Android ANativeWindow surfaces.
class AndroidSurfaceManager {
 public:
  enum class State {
    kUninitialized,
    kCreated,
    kDestroyed,
  };

  struct Callbacks {
    std::function<void(void* native_window)> on_window_created;
    std::function<void(void* native_window)> on_window_changed;
    std::function<void()> on_window_destroyed;
    std::function<void(size_t width, size_t height)> on_metrics_changed;
  };

  explicit AndroidSurfaceManager(Callbacks callbacks)
      : callbacks_(std::move(callbacks)) {}
  ~AndroidSurfaceManager() = default;

  void SurfaceCreated(void* native_window, size_t width, size_t height) {
    if (state_ == State::kCreated) {
      SurfaceDestroyed();
    }
    native_window_ = native_window;
    width_ = width;
    height_ = height;
    state_ = State::kCreated;
    if (callbacks_.on_window_created) {
      callbacks_.on_window_created(native_window_);
    }
    if (width_ > 0 && height_ > 0 && callbacks_.on_metrics_changed) {
      callbacks_.on_metrics_changed(width_, height_);
    }
  }

  void SurfaceChanged(size_t width, size_t height) {
    if (state_ != State::kCreated) {
      return;
    }
    if (width_ == width && height_ == height) {
      return;
    }
    width_ = width;
    height_ = height;
    if (callbacks_.on_metrics_changed) {
      callbacks_.on_metrics_changed(width_, height_);
    }
  }

  void SurfaceWindowChanged(void* new_native_window) {
    if (state_ == State::kCreated && callbacks_.on_window_changed) {
      native_window_ = new_native_window;
      callbacks_.on_window_changed(native_window_);
      if (width_ > 0 && height_ > 0 && callbacks_.on_metrics_changed) {
        callbacks_.on_metrics_changed(width_, height_);
      }
      return;
    }
    if (state_ == State::kCreated) {
      if (callbacks_.on_window_destroyed) {
        callbacks_.on_window_destroyed();
      }
    }
    native_window_ = new_native_window;
    state_ = State::kCreated;
    if (callbacks_.on_window_created) {
      callbacks_.on_window_created(native_window_);
    }
    if (width_ > 0 && height_ > 0 && callbacks_.on_metrics_changed) {
      callbacks_.on_metrics_changed(width_, height_);
    }
  }

  void SurfaceDestroyed() {
    if (state_ != State::kCreated) {
      return;
    }
    if (callbacks_.on_window_destroyed) {
      callbacks_.on_window_destroyed();
    }
    native_window_ = nullptr;
    state_ = State::kDestroyed;
  }

  State GetState() const { return state_; }
  void* GetNativeWindow() const { return native_window_; }
  size_t GetWidth() const { return width_; }
  size_t GetHeight() const { return height_; }

 private:
  Callbacks callbacks_;
  State state_ = State::kUninitialized;
  void* native_window_ = nullptr;
  size_t width_ = 0;
  size_t height_ = 0;
};

class FlutterEmbedderNative {
 public:
  struct ResponsePayload {
    std::vector<uint8_t> data;
    std::function<void(const uint8_t* data, size_t size)> callback;
  };

  explicit FlutterEmbedderNative(
      const FlutterEngineProcTable* proc_table = nullptr,
      bool use_engine_owned_task_runners = true);
  ~FlutterEmbedderNative();

  static bool RegisterJni(JNIEnv* env);
  static void SetGlobalProcTableForTesting(
      const FlutterEngineProcTable* proc_table);
  static FlutterEmbedderNative* GetActiveInstance();

  bool IsValid() const;
  bool IsSurfaceControlEnabled() const { return enable_surface_control_; }

  // JNI Lifecycle
  bool Attach(JNIEnv* env, jobject flutter_jni);
  void Detach();

  // Engine startup & Spawning
  bool RunBundleAndSnapshotFromLibrary(
      JNIEnv* env,
      const std::string& bundle_path,
      const std::string& entrypoint,
      const std::string& library_url,
      jobject asset_manager,
      const std::vector<std::string>& entrypoint_args,
      int64_t engine_id = 0);

  std::unique_ptr<FlutterEmbedderNative> Spawn(
      JNIEnv* env,
      jobject flutter_jni,
      const std::string& entrypoint,
      const std::string& library_url,
      const std::string& initial_route,
      const std::vector<std::string>& entrypoint_args,
      int64_t engine_id);

  // Asset Manager Hot-Reload / Multi-Engine update
  void UpdateJavaAssetManager(JNIEnv* env,
                              jobject asset_manager,
                              const std::string& asset_bundle_path);

  // Surface Lifecycle
  void SurfaceCreated(JNIEnv* env, jobject jsurface);
  void SurfaceWindowChanged(JNIEnv* env, jobject jsurface);
  void SurfaceChanged(size_t width, size_t height);
  void SurfaceDestroyed();

  // Window & Display Metrics
  void SetViewportMetrics(float device_pixel_ratio,
                          int32_t physical_width,
                          int32_t physical_height,
                          int32_t physical_padding_top,
                          int32_t physical_padding_right,
                          int32_t physical_padding_bottom,
                          int32_t physical_padding_left,
                          int32_t physical_view_inset_top,
                          int32_t physical_view_inset_right,
                          int32_t physical_view_inset_bottom,
                          int32_t physical_view_inset_left,
                          int32_t system_gesture_inset_top,
                          int32_t system_gesture_inset_right,
                          int32_t system_gesture_inset_bottom,
                          int32_t system_gesture_inset_left,
                          int32_t physical_touch_slop,
                          const std::vector<int32_t>& display_features_bounds,
                          const std::vector<int32_t>& display_features_type,
                          const std::vector<int32_t>& display_features_state,
                          int32_t display_id,
                          int32_t min_width = 0,
                          int32_t max_width = 0,
                          int32_t min_height = 0,
                          int32_t max_height = 0,
                          int32_t physical_display_corner_radius_top_left =
                              kUnsetCornerRadiusSentinel,
                          int32_t physical_display_corner_radius_top_right =
                              kUnsetCornerRadiusSentinel,
                          int32_t physical_display_corner_radius_bottom_right =
                              kUnsetCornerRadiusSentinel,
                          int32_t physical_display_corner_radius_bottom_left =
                              kUnsetCornerRadiusSentinel);

  void UpdateDisplayMetrics(JNIEnv* env);

  // Platform Messages (Java -> Dart)
  bool DispatchEmptyPlatformMessage(const std::string& channel,
                                    int32_t response_id);
  bool DispatchPlatformMessage(const std::string& channel,
                               const uint8_t* message_data,
                               size_t message_size,
                               int32_t response_id);
  bool InvokePlatformMessageEmptyResponseCallback(int32_t response_id);
  bool InvokePlatformMessageResponseCallback(int32_t response_id,
                                             const uint8_t* response_data,
                                             size_t response_size);

  // Pointer & Input Events
  bool DispatchPointerDataPacket(const uint8_t* packet_data,
                                 size_t packet_size);

  // Semantics & Accessibility
  bool DispatchSemanticsAction(int32_t node_id,
                               int32_t action,
                               const uint8_t* args_data,
                               size_t args_size);
  bool SetSemanticsEnabled(bool enabled);
  bool SetAccessibilityFeatures(int32_t flags);

  // External Textures
  bool RegisterTexture(int64_t texture_id,
                       JNIEnv* env,
                       jobject surface_texture_wrapper);
  bool RegisterImageTexture(int64_t texture_id,
                            JNIEnv* env,
                            jobject image_texture_entry,
                            bool reset_on_background = false);
  bool MarkTextureFrameAvailable(int64_t texture_id);
  bool UnregisterTexture(int64_t texture_id);

  // Frame Scheduling & Memory
  bool ScheduleFrame();
  bool NotifyLowMemoryWarning();

  // Deferred Components
  bool LoadDartDeferredLibrary(int32_t loading_unit_id,
                               const std::vector<std::string>& search_paths);
  bool NotifyDartDeferredLibraryLoadError(int32_t loading_unit_id,
                                          const std::string& error_message,
                                          bool is_transient);

  // C-API Callbacks (Dart -> Java)
  static bool OnResolveRendererConfigCallback(
      void* user_data,
      FlutterRendererConfig* config_out);
  static void OnPlatformMessageCallback(const FlutterPlatformMessage* message,
                                        void* user_data);
  static void OnUpdateSemanticsCallback(const FlutterSemanticsUpdate2* update,
                                        void* user_data);
  static void OnVsyncCallback(void* user_data, intptr_t baton);
  static void OnRequestDartDeferredLibraryCallback(intptr_t loading_unit_id,
                                                   void* user_data);
  static bool OnScaleFontSizeCallback(const FlutterScaleFontSizeInfo* info,
                                      double* scaled_font_size_out,
                                      void* user_data);
  static const FlutterLocale* OnComputePlatformResolvedLocaleCallback(
      const FlutterLocale** supported_locales,
      size_t number_of_locales);
  static void OnPreEngineRestartCallback(void* user_data);
  static void OnLogMessageCallback(const char* tag,
                                   const char* message,
                                   void* user_data);
  static bool OnCreateImageDecoderCallback(void* user_data,
                                           const uint8_t* data,
                                           size_t data_size,
                                           FlutterImageDecoder* decoder_out);
  static bool OnExternalTextureFrameCallback(
      void* user_data,
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterOpenGLExternalTexture* texture_out);
  static bool OnVulkanExternalTextureFrameCallback(
      void* user_data,
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterVulkanExternalTexture* texture_out);

  // Accessors for testing
  FLUTTER_API_SYMBOL(FlutterEngine) GetEngine() const { return engine_; }
  void SetEngineForTesting(FLUTTER_API_SYMBOL(FlutterEngine) engine);
  const FlutterEngineProcTable& GetProcTable() const { return proc_table_; }
  JvmInvoker* GetJvmInvoker() const { return jvm_invoker_.get(); }
  AndroidTaskRunners* GetTaskRunners() const { return task_runners_.get(); }
  AndroidVsyncWaiter* GetVsyncWaiter() const { return vsync_waiter_.get(); }
  AndroidCompositor* GetCompositor() const { return compositor_.get(); }
  AndroidPlatformViewsController* GetPlatformViewsController() const {
    return platform_views_controller_.get();
  }
  APKAssetProvider* GetAssetProvider() const { return asset_provider_.get(); }
  AndroidEngineGroup* GetEngineGroup() const { return engine_group_.get(); }
  AndroidSurfaceManager* GetSurfaceManager() const {
    return surface_manager_.get();
  }
  int64_t GetEngineId() const { return engine_id_; }

 private:
  struct PendingPlatformMessage {
    std::string channel;
    std::vector<uint8_t> data;
    bool has_data = false;
    int32_t response_id = 0;
  };

  void HandlePlatformMessageFromEngine(const FlutterPlatformMessage* message);
  void HandleSemanticsUpdateFromEngine(const FlutterSemanticsUpdate2* update);
  bool ResolveRendererConfig(FlutterRendererConfig* config_out);
  bool InitializeAndroidEGL();
  void TeardownAndroidEGL();
  bool CreateOrUpdateAndroidWindowSurface(void* native_window);
  void DestroyAndroidWindowSurface();
  bool MakeAndroidEGLCurrent();
  bool ClearAndroidEGLCurrent();
  bool PresentAndroidEGL();
  bool ClearAndPresentAndroidEGL();
  bool MakeAndroidEGLResourceCurrent();
  bool BindAndroidOverlayEGLSurface(int32_t overlay_surface_id,
                                    void* native_window,
                                    FlutterBackingStore* backing_store_out);
  bool MakeAndroidOverlayEGLCurrent(int32_t overlay_surface_id);
  bool PresentAndroidOverlayEGL(int32_t overlay_surface_id);
  void DestroyAndroidOverlayEGLSurfaces();
  bool AcquireOpenGLExternalTextureFrame(
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterOpenGLExternalTexture* texture_out);
  bool AcquireVulkanExternalTextureFrame(
      int64_t texture_id,
      size_t width,
      size_t height,
      FlutterVulkanExternalTexture* texture_out);
  void ReleaseAllTextures();
  bool PresentAndroidSoftware(const void* allocation,
                              size_t row_bytes,
                              size_t height);
  void NotifyFirstFramePresented();
  void FlushPendingStartupState();

  FlutterEngineProcTable proc_table_{};
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;
  int64_t engine_id_ = 0;
  bool use_engine_owned_task_runners_ = true;
  bool is_using_mock_proc_table_ = false;
  bool enable_surface_control_ = false;
  std::atomic<bool> first_frame_presented_{false};
  std::shared_ptr<std::atomic<bool>> alive_flag_ =
      std::make_shared<std::atomic<bool>>(true);

  std::shared_ptr<JvmInvoker> jvm_invoker_;
  std::unique_ptr<AndroidTaskRunners> task_runners_;
  std::unique_ptr<AndroidVsyncWaiter> vsync_waiter_;
  std::unique_ptr<AndroidCompositor> compositor_;
  std::unique_ptr<AndroidPlatformViewsController> platform_views_controller_;
  std::unique_ptr<AndroidSurfaceControl> surface_control_;
  std::unique_ptr<APKAssetProvider> asset_provider_;
  std::unique_ptr<AndroidEngineGroup> engine_group_;
  std::unique_ptr<AndroidSurfaceManager> surface_manager_;

  FlutterCustomAssetResolver custom_asset_resolver_{};
  FlutterImageDecoderRegistration image_decoder_registration_{};

  void* native_window_ = nullptr;
  size_t surface_width_ = 0;
  size_t surface_height_ = 0;
  double last_pixel_ratio_ = kDefaultInitialPixelRatio;
  int32_t last_display_id_ = 0;

  mutable std::mutex egl_mutex_;
  void* egl_display_ = nullptr;
  void* egl_config_ = nullptr;
  void* egl_context_ = nullptr;
  void* egl_resource_context_ = nullptr;
  void* egl_pbuffer_surface_ = nullptr;
  void* egl_resource_pbuffer_surface_ = nullptr;
  void* egl_window_surface_ = nullptr;

  struct OverlayEglSurfaceEntry {
    void* native_window = nullptr;
    void* egl_surface = nullptr;
  };
  std::unordered_map<int32_t, OverlayEglSurfaceEntry> egl_overlay_surfaces_;

  struct SurfaceTextureEntry {
    jobject wrapper_global_ref = nullptr;
    uint32_t gl_texture_id = 0;
    bool attached = false;
    std::shared_ptr<AndroidVulkanExternalTexture> last_vulkan_texture;
  };

  struct ImageTextureEntry {
    jobject entry_global_ref = nullptr;
    bool reset_on_background = false;
    uint32_t gl_texture_id = 0;
    void* egl_image = nullptr;
    std::shared_ptr<AndroidHardwareBuffer> last_ahb;
    std::shared_ptr<AndroidVulkanExternalTexture> last_vulkan_texture;
  };

  mutable std::mutex textures_mutex_;
  std::unordered_map<int64_t, SurfaceTextureEntry> surface_textures_;
  std::unordered_map<int64_t, ImageTextureEntry> image_textures_;
  std::shared_ptr<AndroidHardwareBufferProvider> ahb_provider_;
  std::shared_ptr<DefaultAndroidVulkanTextureProvider> vk_texture_provider_;
  std::unique_ptr<SurfaceTextureGlToAhbBlitter> surface_texture_blitter_;

  std::mutex pending_startup_mutex_;
  std::vector<PendingPlatformMessage> pending_platform_messages_;
  std::function<void()> pending_viewport_metrics_callback_;
  std::optional<bool> pending_semantics_enabled_;
  std::optional<int32_t> pending_accessibility_features_;
  std::string initial_route_;

  std::mutex response_mutex_;
  int32_t next_engine_response_id_ = 1;
  std::unordered_map<int32_t, const FlutterPlatformMessageResponseHandle*>
      pending_engine_responses_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_FLUTTER_EMBEDDER_NATIVE_H_
