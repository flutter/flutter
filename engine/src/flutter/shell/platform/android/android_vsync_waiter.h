// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VSYNC_WAITER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VSYNC_WAITER_H_

#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <vector>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/jvm_invoker.h"
#include "flutter/shell/platform/android/os_library_loader.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {
namespace android {

// Forward declaration of AChoreographer opaque struct.
struct AChoreographer;

// 64-bit frame callback signature (Android API 29+).
typedef void (*AChoreographer_frameCallback64)(int64_t frameTimeNanos,
                                               void* data);

// 32-bit / legacy frame callback signature (Android API 24-28).
typedef void (*AChoreographer_frameCallback)(int64_t frameTimeNanos,
                                             void* data);

// Function pointer types resolved from libandroid.so via OSLibraryLoader.
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
    int64_t delayMillis);

/// @brief Calculated frame timing information for VSync frame pacing.
struct AndroidVsyncFrameInfo {
  int64_t frame_start_time_nanos = 0;
  int64_t frame_target_time_nanos = 0;
  int64_t refresh_period_nanos = 0;
  double refresh_rate_hz = 60.0;

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

  /// @brief Returns true if AChoreographer is supported and resolved.
  virtual bool IsAvailable() const = 0;

  /// @brief Returns true if 64-bit frame callbacks are supported (API 29+).
  virtual bool Has64BitSupport() const = 0;

  /// @brief Posts a frame callback to be invoked on the next VSync signal.
  virtual bool PostFrameCallback(FrameCallback callback) = 0;

  /// @brief Posts a frame callback with delay in milliseconds.
  virtual bool PostFrameCallbackDelayed(FrameCallback callback,
                                        uint32_t delay_ms) = 0;
};

/// @brief Default production implementation of AndroidChoreographerProvider
/// that resolves native AChoreographer symbols dynamically via OSLibraryLoader.
class DefaultAndroidChoreographerProvider
    : public AndroidChoreographerProvider {
 public:
  explicit DefaultAndroidChoreographerProvider(
      std::shared_ptr<OSLibraryLoader> library_loader = nullptr);
  ~DefaultAndroidChoreographerProvider() override;

  bool IsAvailable() const override;
  bool Has64BitSupport() const override;
  bool PostFrameCallback(FrameCallback callback) override;
  bool PostFrameCallbackDelayed(FrameCallback callback,
                                uint32_t delay_ms) override;

 private:
  void EnsureLoaded() const;

  mutable std::shared_ptr<OSLibraryLoader> library_loader_;
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

  // Test control methods:
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

/// @brief VSync Waiter and Frame Pacer for Android embedder.
///
/// Bridges AChoreographer frame events to FlutterProjectArgs::vsync_callback
/// and FlutterEngineOnVsync with accurate 120Hz/variable refresh rate pacing.
class AndroidVsyncWaiter
    : public std::enable_shared_from_this<AndroidVsyncWaiter> {
 public:
  using VsyncResultCallback =
      std::function<void(intptr_t baton,
                         int64_t frame_start_time_nanos,
                         int64_t frame_target_time_nanos)>;

  explicit AndroidVsyncWaiter(
      std::shared_ptr<AndroidChoreographerProvider> choreographer_provider =
          nullptr,
      std::shared_ptr<JvmInvoker> jvm_invoker = nullptr);
  virtual ~AndroidVsyncWaiter();

  /// @brief Static C-API compatible vsync callback function matching
  /// FlutterProjectArgs::vsync_callback.
  static void OnVsyncCallback(void* user_data, intptr_t baton);

  /// @brief Asynchronously requests a VSync signal for the given baton.
  virtual bool AsyncWaitForVsync(intptr_t baton);

  /// @brief Consumes a pending VSync event with the given start and target
  /// times.
  virtual void ConsumePendingVsync(intptr_t baton, int64_t frame_time_nanos);

  /// @brief Computes frame pacing timestamps for a given frame start time and
  /// refresh rate.
  static AndroidVsyncFrameInfo ComputeFramePacing(int64_t frame_time_nanos,
                                                  double refresh_rate_hz);

  /// @brief Sets the active display refresh rate in Hz (e.g. 60.0, 90.0,
  /// 120.0).
  void UpdateRefreshRate(double refresh_rate_hz);

  /// @brief Returns the current display refresh rate in Hz.
  double GetRefreshRate() const;

  /// @brief Returns the calculated refresh period in nanoseconds.
  int64_t GetRefreshPeriodNanos() const;

  /// @brief Sets the FlutterEngine handle for direct FlutterEngineOnVsync
  /// dispatch.
  void SetEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine);

  /// @brief Returns the associated FlutterEngine handle.
  FLUTTER_API_SYMBOL(FlutterEngine) GetEngine() const;

  /// @brief Sets a callback listener invoked on each VSync completion.
  void SetVsyncResultCallback(VsyncResultCallback callback);

  /// @brief Returns the associated AndroidChoreographerProvider.
  std::shared_ptr<AndroidChoreographerProvider> GetChoreographerProvider()
      const;

  /// @brief Sets or replaces the AndroidChoreographerProvider.
  void SetChoreographerProvider(
      std::shared_ptr<AndroidChoreographerProvider> provider);

  /// @brief Returns the associated JvmInvoker.
  std::shared_ptr<JvmInvoker> GetJvmInvoker() const;

  /// @brief Sets or replaces the JvmInvoker.
  void SetJvmInvoker(std::shared_ptr<JvmInvoker> invoker);

  /// @brief Returns the number of VSync requests served.
  size_t GetVsyncRequestCount() const;

  /// @brief Returns the number of VSync frames delivered.
  size_t GetVsyncDeliveredCount() const;

 private:
  mutable std::mutex mutex_;
  std::shared_ptr<AndroidChoreographerProvider> choreographer_provider_;
  std::shared_ptr<JvmInvoker> jvm_invoker_;
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;
  double refresh_rate_hz_ = 60.0;
  size_t vsync_request_count_ = 0;
  size_t vsync_delivered_count_ = 0;
  VsyncResultCallback vsync_result_callback_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidVsyncWaiter);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_VSYNC_WAITER_H_
