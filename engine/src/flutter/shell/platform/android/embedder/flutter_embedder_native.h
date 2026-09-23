// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_FLUTTER_EMBEDDER_NATIVE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_FLUTTER_EMBEDDER_NATIVE_H_

#include <cstdint>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/embedder/jni_delegate.h"
#include "flutter/shell/platform/embedder/embedder.h"

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
  bool NotifySurfaceCreated();

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

  void HandleEnginePlatformMessage(const FlutterPlatformMessage* message);

  Settings settings_;
  std::shared_ptr<JniDelegate> jni_delegate_;
  FlutterEngineProcTable embedder_api_ = {};
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;
  FlutterEngineAOTData aot_data_ = nullptr;
  bool is_valid_ = false;

  mutable std::mutex response_mutex_;
  int32_t next_response_id_ = 1;
  std::unordered_map<int32_t, const FlutterPlatformMessageResponseHandle*>
      pending_responses_;

  FML_DISALLOW_COPY_AND_ASSIGN(FlutterEmbedderNative);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_FLUTTER_EMBEDDER_NATIVE_H_
