// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_FLUTTER_EMBEDDER_NATIVE_H_

#include <atomic>
#include <cstdint>
#if defined(__ANDROID__)
#include <jni.h>
#include "flutter/fml/platform/android/scoped_java_ref.h"
#else
struct _JNIEnv;
typedef struct _JNIEnv JNIEnv;
#endif
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/embedder/android_choreographer_vsync.h"
#include "flutter/shell/platform/android/embedder/android_hardware_buffer_external_texture.h"
#include "flutter/shell/platform/android/embedder/android_platform_views_controller.h"
#include "flutter/shell/platform/android/embedder/android_semantics_and_assets.h"
#include "flutter/shell/platform/android/embedder/android_surface_control.h"
#include "flutter/shell/platform/android/embedder/jni_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"

#if defined(__ANDROID__)
#include <jni.h>
#include "flutter/fml/platform/android/scoped_java_ref.h"
#endif

namespace flutter {

struct alignas(8) RawAndroidPointerData {
  enum class Change : int64_t {
    kCancel,
    kAdd,
    kRemove,
    kHover,
    kDown,
    kMove,
    kUp,
    kPanZoomStart,
    kPanZoomUpdate,
    kPanZoomEnd,
  };

  enum class DeviceKind : int64_t {
    kTouch,
    kMouse,
    kStylus,
    kInvertedStylus,
    kTrackpad,
  };

  int64_t embedder_id;
  int64_t time_stamp;
  Change change;
  DeviceKind kind;
  int64_t signal_kind;
  int64_t device;
  int64_t pointer_identifier;
  double physical_x;
  double physical_y;
  double physical_delta_x;
  double physical_delta_y;
  int64_t buttons;
  int64_t obscured;
  int64_t synthesized;
  double pressure;
  double pressure_min;
  double pressure_max;
  double distance;
  double distance_max;
  double size;
  double radius_major;
  double radius_minor;
  double radius_min;
  double radius_max;
  double orientation;
  double tilt;
  int64_t platformData;
  double scroll_delta_x;
  double scroll_delta_y;
  double pan_x;
  double pan_y;
  double pan_delta_x;
  double pan_delta_y;
  double scale;
  double rotation;
  int64_t view_id;
};

//------------------------------------------------------------------------------
/// @brief      Pure C Embedder API coordinator for the Android Embedder
///             (RFC 410.0000, ADR-0001, ADR-0002, ADR-0011).
///
///             Compiles under `FLUTTER_ENGINE_NO_PROTOTYPES` and
///             `check_includes = true`. Never references `flutter::Shell` or
///             `AndroidShellHolder`. All engine operations dispatch strictly
///             through the dynamic `FlutterEngineProcTable` (`embedder_api_`).
///
class FlutterEmbedderNative {
 public:
  /// Populates `FlutterEngineProcTable` via `FlutterEngineGetProcAddresses`.
  static bool ResolveDefaultProcTable(FlutterEngineProcTable* out_table);

  /// Looks up a live `FlutterEmbedderNative` instance from a JNI `jlong`
  /// handle. Returns `nullptr` if `handle` is not a registered
  /// `FlutterEmbedderNative` instance.
  static FlutterEmbedderNative* FromHandle(int64_t handle);

  /// Registers all `io.flutter.embedding.engine.FlutterJNI` native JNI method
  /// bindings directly to `FlutterEmbedderNative` (RFC 410.0000 Phase 4).
  static bool RegisterJni(JNIEnv* env);

  FlutterEmbedderNative(const Settings& settings,
                        std::shared_ptr<JniDelegate> jni_delegate);

  FlutterEmbedderNative(const Settings& settings,
                        std::shared_ptr<JniDelegate> jni_delegate,
                        const FlutterEngineProcTable& proc_table);

  ~FlutterEmbedderNative();

  bool IsValid() const { return is_valid_; }

  bool IsRunning() const { return engine_ != nullptr; }

  int64_t ToHandle() const { return reinterpret_cast<int64_t>(this); }

  const FlutterEngineProcTable& GetProcTable() const { return embedder_api_; }

  FLUTTER_API_SYMBOL(FlutterEngine) GetEngineHandle() const { return engine_; }

  /// Initializes and launches the Flutter engine strictly via
  /// `embedder_api_.Initialize` and `embedder_api_.RunInitialized`.
  bool Launch(const std::string& assets_path,
              const std::string& icu_data_path,
              const std::string& entrypoint,
              const std::string& library_url,
              const std::vector<std::string>& entrypoint_args,
              int64_t engine_id,
              AAssetManager* asset_manager = nullptr);

#if defined(__ANDROID__)
  /// Retains the Java AssetManager via a global reference to prevent GC while
  /// native code reads APK assets (ADR-0002).
  void SetJavaAssetManager(JNIEnv* env, jobject jasset_manager);
#endif

  /// Updates or re-registers the asset resolver dynamically via
  /// `embedder_api_.UpdateAssetResolver`.
  bool UpdateAssetManager(AAssetManager* asset_manager,
                          const std::string& asset_bundle_path = "");

  /// Spawns a child `FlutterEmbedderNative` sharing the parent's Dart VM and
  /// isolate group via `embedder_api_.Spawn` (ADR-0008).
  std::unique_ptr<FlutterEmbedderNative> Spawn(
      std::shared_ptr<JniDelegate> child_jni_delegate,
      const std::string& entrypoint,
      const std::string& library_url,
      const std::string& initial_route,
      const std::vector<std::string>& entrypoint_args,
      int64_t engine_id) const;

  /// Notifies the engine that a rendering surface has been created (ADR-0007).
  bool NotifySurfaceCreated(uintptr_t native_window_handle = 1);

  /// Synchronously notifies the engine that the rendering surface has been
  /// destroyed before returning to Android OS (ADR-0007, Invariant 5).
  bool NotifySurfaceDestroyed();

  /// Updates the engine GPU availability state during background/foreground
  /// transitions (ADR-0007).
  bool SetGpuAvailability(FlutterGpuAvailability availability);

  /// Sends updated window viewport metrics to the engine.
  bool SendWindowMetrics(size_t width,
                         size_t height,
                         double pixel_ratio,
                         int64_t view_id = 0);

  /// Sends a fully populated FlutterWindowMetricsEvent to the engine.
  bool SendWindowMetricsEvent(const FlutterWindowMetricsEvent& event);

  /// Sends a platform message from Android to Dart via `embedder_api_`.
  bool SendPlatformMessage(const std::string& channel,
                           const uint8_t* bytes,
                           size_t length,
                           int32_t response_id);

  /// Responds to a Dart-to-Android platform message via `embedder_api_`.
  bool RespondToPlatformMessage(int32_t response_id,
                                const uint8_t* bytes,
                                size_t length);

  /// Delivers a memory-mapped Dart deferred library to the engine (ADR-0009).
  bool LoadDartDeferredLibrary(const FlutterDartDeferredLibrary* library);

  /// Notifies the engine of an Android low-memory warning.
  bool NotifyLowMemoryWarning();

  /// Signals a vsync frame window to the engine via `embedder_api_.OnVsync`.
  bool OnVsync(intptr_t baton,
               uint64_t frame_start_time_nanos,
               uint64_t frame_target_time_nanos);

  AndroidSurfaceControl* GetSurfaceControl() const {
    return surface_control_.get();
  }

  AndroidChoreographerVsync* GetVsyncWaiter() const {
    return vsync_waiter_.get();
  }

  AndroidHardwareBufferExternalTexture* GetExternalTextureManager() const {
    return external_texture_manager_.get();
  }

  AndroidPlatformViewsController* GetPlatformViewsController() const {
    return platform_views_controller_.get();
  }

  AndroidSemanticsBridge* GetSemanticsBridge() const {
    return semantics_bridge_.get();
  }

  AndroidDeferredLibraryLoader* GetDeferredLibraryLoader() const {
    return deferred_library_loader_.get();
  }

  bool RegisterExternalTexture(int64_t texture_id);
  bool UnregisterExternalTexture(int64_t texture_id);
  bool MarkExternalTextureFrameAvailable(int64_t texture_id);

#if defined(__ANDROID__)
  void RegisterJavaTexture(JNIEnv* env,
                           int64_t texture_id,
                           jobject texture_obj);
  void UnregisterJavaTexture(int64_t texture_id);
  void UpdateJavaTexture(JNIEnv* env, int64_t texture_id);
  void UpdateAllJavaTextures();
#endif

  struct SoftwareBufferView {
    void* bits = nullptr;
    int32_t format = 1;  // 1: RGBA_8888, 4: RGB_565
    int32_t stride = 0;
    int32_t height = 0;
  };

  /// Decoupled pixel copy routine for software presentations, validating
  /// format pitch, row bounds, and destination gralloc memory limits.
  static bool CopySoftwarePixels(const void* src,
                                 size_t row_bytes,
                                 size_t height,
                                 const SoftwareBufferView& dst);

  /// Presents a software-rendered pixel buffer to the primary ANativeWindow
  /// surface, invoking `jni_delegate_->OnFirstFrame()` upon first presentation.
  bool PresentSoftware(const void* allocation, size_t row_bytes, size_t height);

  /// Dispatches pointer data packet bytes from Java to the engine via
  /// `embedder_api_.SendPointerEvent`.
  bool DispatchPointerDataPacket(const uint8_t* data, size_t size);

  /// Dispatches a semantics action to the engine via
  /// `embedder_api_.DispatchSemanticsAction`.
  bool DispatchSemanticsAction(int32_t id,
                               int32_t action,
                               const uint8_t* args_data,
                               size_t args_size);

  /// Updates whether semantics are enabled via
  /// `embedder_api_.UpdateSemanticsEnabled`.
  bool SetSemanticsEnabled(bool enabled);

  /// Updates accessibility feature flags via
  /// `embedder_api_.UpdateAccessibilityFeatures`.
  bool SetAccessibilityFeatures(int32_t flags);

  /// Schedules a frame to be rendered via `embedder_api_.ScheduleFrame`.
  bool ScheduleFrame();

 private:
  FlutterEmbedderNative(const Settings& settings,
                        std::shared_ptr<JniDelegate> jni_delegate,
                        const FlutterEngineProcTable& proc_table,
                        FLUTTER_API_SYMBOL(FlutterEngine) spawned_engine);

  static void OnPlatformMessageCallback(const FlutterPlatformMessage* message,
                                        void* user_data);

  static void OnPlatformMessageResponseCallback(const uint8_t* data,
                                                size_t size,
                                                void* user_data);

  static void OnRequestDartDeferredLibraryCallback(intptr_t loading_unit_id,
                                                   void* user_data);

  static void OnVsyncRequestCallback(void* user_data, intptr_t baton);

  static void OnSemanticsUpdate2Callback(const FlutterSemanticsUpdate2* update,
                                         void* user_data);

  void HandleEnginePlatformMessage(const FlutterPlatformMessage* message);

  Settings settings_;
  std::shared_ptr<JniDelegate> jni_delegate_;
  FlutterEngineProcTable embedder_api_ = {};
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;
  FlutterEngineAOTData aot_data_ = nullptr;
  std::unique_ptr<AndroidSurfaceControl> surface_control_;
  std::unique_ptr<AndroidChoreographerVsync> vsync_waiter_;
  std::unique_ptr<AndroidHardwareBufferExternalTexture>
      external_texture_manager_;
  std::unique_ptr<AndroidPlatformViewsController> platform_views_controller_;
  std::unique_ptr<AndroidSemanticsBridge> semantics_bridge_;
  std::unique_ptr<AndroidDeferredLibraryLoader> deferred_library_loader_;
  bool is_valid_ = false;
  std::atomic<bool> first_frame_dispatched_{false};

  mutable std::mutex response_mutex_;
  int32_t next_response_id_ = 1;
  std::unordered_map<int32_t, const FlutterPlatformMessageResponseHandle*>
      pending_responses_;

#if defined(__ANDROID__)
  mutable std::mutex java_textures_mutex_;
  std::unordered_map<int64_t, fml::jni::ScopedJavaGlobalRef<jobject>>
      java_textures_;
  std::unordered_set<int64_t> attached_java_textures_;
  fml::jni::ScopedJavaGlobalRef<jobject> java_asset_manager_;
#endif
  AAssetManager* asset_manager_ = nullptr;
  std::string asset_bundle_path_;
  FlutterAssetResolver asset_resolver_ = {};
  const FlutterAssetResolver* asset_resolvers_array_[1] = {nullptr};

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_FLUTTER_EMBEDDER_NATIVE_H_
