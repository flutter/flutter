// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_FLUTTER_EMBEDDER_NATIVE_H_

#include <atomic>
#include <cstdint>
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
#include "flutter/shell/platform/android/embedder/android_surface_control.h"
#include "flutter/shell/platform/android/embedder/jni_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"

#if defined(__ANDROID__)
#include <jni.h>
#include "flutter/fml/platform/android/scoped_java_ref.h"
#endif

namespace flutter {

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
              int64_t engine_id);

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
#endif

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_FLUTTER_EMBEDDER_NATIVE_H_
