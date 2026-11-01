// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VSYNC_WAITER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VSYNC_WAITER_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/fml/native_library.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

// Forward declaration of AChoreographer opaque struct.
struct AChoreographer;

// 64-bit frame callback signature (Android API 29+).
typedef void (*AChoreographer_frameCallback64)(int64_t frameTimeNanos,
                                               void* data);

// 32-bit / legacy frame callback signature (Android API 24-28).
// NOLINTNEXTLINE(google-runtime-int)
typedef void (*AChoreographer_frameCallback)(long frameTimeNanos, void* data);

// Function pointer types resolved from libandroid.so via fml::NativeLibrary.
typedef AChoreographer* (*AChoreographer_getInstance_fn)();
typedef void (*AChoreographer_postFrameCallback64_fn)(
    AChoreographer* choreographer,
    AChoreographer_frameCallback64 callback,
    void* data);
typedef void (*AChoreographer_postFrameCallback_fn)(
    AChoreographer* choreographer,
    AChoreographer_frameCallback callback,
    void* data);
typedef void (*AChoreographer_postFrameCallbackDelayed64_fn)(
    AChoreographer* choreographer,
    AChoreographer_frameCallback64 callback,
    void* data,
    uint32_t delayMillis);
typedef void (*AChoreographer_postFrameCallbackDelayed_fn)(
    AChoreographer* choreographer,
    AChoreographer_frameCallback callback,
    void* data,
    long delayMillis);  // NOLINT(google-runtime-int)

// Default display refresh rate in Hz for standard mobile panels.
constexpr double kDefaultDisplayRefreshRateHz = 60.0;
// Minimum supported refresh rate in Hz.
constexpr double kMinDisplayRefreshRateHz = 1.0;
// Maximum supported refresh rate in Hz.
constexpr double kMaxDisplayRefreshRateHz = 1000.0;
// Number of nanoseconds in one second.
constexpr double kNanosecondsPerSecond = 1000000000.0;

/// @brief Calculated frame timing information for VSync frame pacing.
struct AndroidVsyncFrameInfo {
  int64_t frame_start_time_nanos = 0;
  int64_t frame_target_time_nanos = 0;
  int64_t refresh_period_nanos = 0;
  double refresh_rate_hz = kDefaultDisplayRefreshRateHz;

  bool operator==(const AndroidVsyncFrameInfo& other) const {
    return frame_start_time_nanos == other.frame_start_time_nanos &&
           frame_target_time_nanos == other.frame_target_time_nanos &&
           refresh_period_nanos == other.refresh_period_nanos &&
           refresh_rate_hz == other.refresh_rate_hz;
  }
};

/// @brief Abstract interface for posting frame callbacks to Android's
/// AChoreographer.
class AndroidChoreographerProvider {
 public:
  using FrameCallback = std::function<void(int64_t frame_time_nanos)>;

  virtual ~AndroidChoreographerProvider() = default;

  virtual bool IsAvailable() const = 0;
  virtual bool Has64BitSupport() const = 0;
  virtual bool PostFrameCallback(FrameCallback callback) = 0;
  virtual bool PostFrameCallbackDelayed(FrameCallback callback,
                                        uint32_t delay_ms) = 0;
};

/// @brief Default production implementation of AndroidChoreographerProvider
/// that resolves native AChoreographer symbols dynamically via
/// fml::NativeLibrary.
class DefaultAndroidChoreographerProvider
    : public AndroidChoreographerProvider {
 public:
  DefaultAndroidChoreographerProvider();
  ~DefaultAndroidChoreographerProvider() override;

  bool IsAvailable() const override;
  bool Has64BitSupport() const override;
  bool PostFrameCallback(FrameCallback callback) override;
  bool PostFrameCallbackDelayed(FrameCallback callback,
                                uint32_t delay_ms) override;

 private:
  void EnsureLoaded() const;

  mutable fml::RefPtr<fml::NativeLibrary> library_;
  mutable std::mutex mutex_;
  mutable bool loaded_ = false;
  mutable bool is_available_ = false;
  mutable bool has_64bit_support_ = false;

  mutable AChoreographer_getInstance_fn get_instance_fn_ = nullptr;
  mutable AChoreographer_postFrameCallback64_fn post_frame_callback64_fn_ =
      nullptr;
  mutable AChoreographer_postFrameCallback_fn post_frame_callback_fn_ = nullptr;
  mutable AChoreographer_postFrameCallbackDelayed64_fn
      post_frame_callback_delayed64_fn_ = nullptr;
  mutable AChoreographer_postFrameCallbackDelayed_fn
      post_frame_callback_delayed_fn_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultAndroidChoreographerProvider);
};

/// @brief In-memory mock implementation of AndroidChoreographerProvider
/// for unit tests and host CI simulation without native Android dependencies.
class InMemoryAndroidChoreographerProvider
    : public AndroidChoreographerProvider {
 public:
  InMemoryAndroidChoreographerProvider();
  ~InMemoryAndroidChoreographerProvider() override;

  bool IsAvailable() const override;
  bool Has64BitSupport() const override;
  bool PostFrameCallback(FrameCallback callback) override;
  bool PostFrameCallbackDelayed(FrameCallback callback,
                                uint32_t delay_ms) override;

  void SetAvailable(bool available);
  void Set64BitSupport(bool has_64bit);
  size_t GetPendingCallbackCount() const;
  bool HasPendingCallbacks() const;
  void FireFrame(int64_t frame_time_nanos);
  void TriggerPendingCallbacks(int64_t frame_time_nanos);
  void ClearPendingCallbacks();

 private:
  mutable std::mutex mutex_;
  bool is_available_ = true;
  bool has_64bit_support_ = true;
  std::vector<FrameCallback> pending_callbacks_;

  FML_DISALLOW_COPY_AND_ASSIGN(InMemoryAndroidChoreographerProvider);
};

/// @brief VSync Waiter and Frame Pacer for the Android C-API embedder.
///
/// Bridges AChoreographer and Java Choreographer frame events to
/// FlutterProjectArgs::vsync_callback and FlutterEngineProcTable::OnVsync.
class AndroidVsyncWaiter
    : public std::enable_shared_from_this<AndroidVsyncWaiter> {
 public:
  using VsyncResultCallback =
      std::function<void(intptr_t baton,
                         int64_t frame_start_time_nanos,
                         int64_t frame_target_time_nanos)>;

  using NotifyVsyncFn =
      std::function<FlutterEngineResult(FLUTTER_API_SYMBOL(FlutterEngine),
                                        intptr_t,
                                        uint64_t,
                                        uint64_t)>;

  explicit AndroidVsyncWaiter(
      std::shared_ptr<AndroidChoreographerProvider> choreographer_provider =
          nullptr,
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr,
      const FlutterEngineProcTable* proc_table = nullptr);
  virtual ~AndroidVsyncWaiter();

  /// @brief Static C-API compatible vsync callback function matching
  /// FlutterProjectArgs::vsync_callback.
  static void OnVsyncCallback(void* user_data, intptr_t baton);

  /// @brief Asynchronously requests a VSync signal for the given baton.
  virtual bool AsyncWaitForVsync(intptr_t baton);

  /// @brief Consumes a pending VSync event with the given start and target
  /// times, returning the baton to the engine via proc_table_.OnVsync under
  /// mutex if not detached.
  virtual void ConsumePendingVsync(intptr_t baton,
                                   int64_t frame_time_nanos,
                                   int64_t refresh_period_nanos = 0);

  /// @brief Detaches the waiter before engine shutdown so in-flight
  /// choreographer or Java callbacks never call OnVsync on a destroyed engine.
  void Detach();

  /// @brief Returns true if Detach() has been called.
  bool IsDetached() const;

  /// @brief Computes frame pacing timestamps for a given frame start time and
  /// refresh rate.
  static AndroidVsyncFrameInfo ComputeFramePacing(int64_t frame_time_nanos,
                                                  double refresh_rate_hz);

  /// @brief Sets the global default display refresh rate in Hz.
  static void SetGlobalRefreshRate(double refresh_rate_hz);

  /// @brief Static entry point invoked by FlutterJNI.nativeUpdateRefreshRate.
  static void UpdateRefreshRate(float refresh_rate_fps);

  /// @brief Returns the global default display refresh rate in Hz.
  static double GetGlobalRefreshRate();

  /// @brief Registers a pending baton associated with a waiter instance for
  /// asynchronous Java VSync notifications.
  static void RegisterPendingJavaBaton(
      intptr_t baton,
      std::weak_ptr<AndroidVsyncWaiter> waiter);

  /// @brief Registers a pending baton associated with a raw waiter pointer.
  static void RegisterPendingRawBaton(intptr_t baton,
                                      AndroidVsyncWaiter* waiter);

  /// @brief Unregisters a pending baton.
  static void UnregisterPendingJavaBaton(intptr_t baton);

  /// @brief Static entry point invoked by FlutterJNI.nativeOnVsync via
  /// JniDelegate::OnVsync.
  static void OnNativeVsync(int64_t frame_delay_nanos,
                            int64_t refresh_period_nanos,
                            intptr_t java_baton);

  /// @brief Alias for OnNativeVsync.
  static void OnJavaVsync(int64_t frame_delay_nanos,
                          int64_t refresh_period_nanos,
                          intptr_t baton);

  /// @brief Sets the active display refresh rate in Hz on this instance.
  void SetRefreshRate(double refresh_rate_hz);

  /// @brief Returns the current display refresh rate in Hz.
  double GetRefreshRate() const;

  /// @brief Returns the calculated refresh period in nanoseconds.
  int64_t GetRefreshPeriodNanos() const;

  /// @brief Sets the FlutterEngine handle for OnVsync dispatch.
  void SetEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine);

  /// @brief Returns the associated FlutterEngine handle.
  FLUTTER_API_SYMBOL(FlutterEngine) GetEngine() const;

  /// @brief Updates the FlutterEngineProcTable used for OnVsync dispatch.
  void SetProcTable(const FlutterEngineProcTable& proc_table);

  /// @brief Sets a callback listener invoked on each VSync completion.
  void SetVsyncResultCallback(VsyncResultCallback callback);

  std::shared_ptr<AndroidChoreographerProvider> GetChoreographerProvider()
      const;
  void SetChoreographerProvider(
      std::shared_ptr<AndroidChoreographerProvider> provider);

  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;
  void SetJvmInvoker(std::shared_ptr<JvmInvoker> invoker);

  void SetNotifyVsyncFnForTesting(NotifyVsyncFn fn);

  size_t GetVsyncRequestCount() const;
  size_t GetVsyncDeliveredCount() const;

 private:
  mutable std::mutex mutex_;
  FlutterEngineProcTable proc_table_{};
  std::shared_ptr<AndroidChoreographerProvider> choreographer_provider_;
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;
  bool detached_ = false;
  double refresh_rate_hz_ = kDefaultDisplayRefreshRateHz;
  size_t vsync_request_count_ = 0;
  size_t vsync_delivered_count_ = 0;
  VsyncResultCallback vsync_result_callback_;
  NotifyVsyncFn notify_vsync_fn_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidVsyncWaiter);
};

}  // namespace android

using AndroidVsyncFrameInfo = android::AndroidVsyncFrameInfo;
using AndroidChoreographerProvider = android::AndroidChoreographerProvider;
using DefaultAndroidChoreographerProvider =
    android::DefaultAndroidChoreographerProvider;
using InMemoryAndroidChoreographerProvider =
    android::InMemoryAndroidChoreographerProvider;
using AndroidVsyncWaiter = android::AndroidVsyncWaiter;

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VSYNC_WAITER_H_
