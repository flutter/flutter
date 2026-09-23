// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_JNI_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_JNI_DELEGATE_H_

#include <cstdint>
#include <string>
#include <vector>

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Host-testable outbound JNI provider for platform messages,
///             engine lifecycle notifications, and deferred component requests
///             (ADR-0003).
///
///             Implementations on Android acquire a thread-local `JNIEnv*` via
///             `fml::jni::AttachCurrentThread()` and immediately check
///             exceptions via `fml::jni::CheckException(env)`. Host unit tests
///             provide deterministic in-memory mocks without requiring a JVM.
///
class FlutterJniProvider {
 public:
  virtual ~FlutterJniProvider() = default;

  virtual void HandlePlatformMessage(const std::string& channel,
                                     const uint8_t* message,
                                     size_t message_size,
                                     int32_t response_id,
                                     int64_t message_data) = 0;

  virtual void HandlePlatformMessageResponse(int32_t response_id,
                                             const uint8_t* response,
                                             size_t response_size) = 0;

  virtual void OnFirstFrame() = 0;

  virtual void OnEngineRestart() = 0;

  virtual void RequestDartDeferredLibrary(intptr_t loading_unit_id) = 0;
};

//------------------------------------------------------------------------------
/// @brief      Host-testable provider for Android SurfaceControl creation and
///             hierarchy management (ADR-0003, ADR-0005).
///
class SurfaceControlProvider {
 public:
  virtual ~SurfaceControlProvider() = default;

  virtual uintptr_t CreateSurfaceControl(const std::string& debug_name,
                                         int32_t width,
                                         int32_t height) = 0;

  virtual void ReleaseSurfaceControl(uintptr_t surface_control_handle) = 0;
};

//------------------------------------------------------------------------------
/// @brief      Host-testable provider for atomic SurfaceControl.Transaction
///             buffer and sync-fence handoff (ADR-0003, ADR-0005).
///
class SurfaceTransactionProvider {
 public:
  virtual ~SurfaceTransactionProvider() = default;

  /// Transfers ownership of `fence_fd` to Android's SurfaceControl transaction
  /// or closes it if unsupported. Once called, the caller must reset its local
  /// descriptor to `-1`.
  virtual bool SetBufferWithFence(uintptr_t surface_control_handle,
                                  uintptr_t hardware_buffer_handle,
                                  int fence_fd) = 0;

  virtual bool ApplyTransaction() = 0;
};

//------------------------------------------------------------------------------
/// @brief      Host-testable provider for AHardwareBuffer zero-copy queries
///             (ADR-0003, ADR-0006).
///
class HardwareBufferProvider {
 public:
  virtual ~HardwareBufferProvider() = default;

  virtual uintptr_t AcquireLatestHardwareBuffer(int64_t texture_id,
                                                uint32_t* out_width,
                                                uint32_t* out_height) = 0;

  virtual void ReleaseHardwareBuffer(uintptr_t hardware_buffer_handle) = 0;
};

//------------------------------------------------------------------------------
/// @brief      Host-testable provider for Choreographer vsync frame pacing
///             (ADR-0003, ADR-0004).
///
class ChoreographerProvider {
 public:
  virtual ~ChoreographerProvider() = default;

  virtual void RequestVsync(intptr_t baton) = 0;
};

//------------------------------------------------------------------------------
/// @brief      Composite outbound JNI delegate injected into
///             `FlutterEmbedderNative` and modular Android subsystem classes
///             (ADR-0003).
///
class JniDelegate : public FlutterJniProvider,
                    public SurfaceControlProvider,
                    public SurfaceTransactionProvider,
                    public HardwareBufferProvider,
                    public ChoreographerProvider {
 public:
  ~JniDelegate() override = default;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EMBEDDER_JNI_DELEGATE_H_
