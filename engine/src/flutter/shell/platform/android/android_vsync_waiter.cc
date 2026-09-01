// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_vsync_waiter.h"

#include <cstring>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/flutter_embedder_native.h"

namespace flutter {
namespace android {

// =============================================================================
// DefaultAndroidChoreographerProvider Implementation
// =============================================================================

DefaultAndroidChoreographerProvider::DefaultAndroidChoreographerProvider(
    std::shared_ptr<OSLibraryLoader> library_loader)
    : library_loader_(library_loader
                          ? std::move(library_loader)
                          : FlutterEmbedderNative::GetDefaultLibraryLoader()) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidChoreographerProvider::"
               "DefaultAndroidChoreographerProvider");
}

DefaultAndroidChoreographerProvider::~DefaultAndroidChoreographerProvider() {
  TRACE_EVENT0("flutter",
               "DefaultAndroidChoreographerProvider::"
               "~DefaultAndroidChoreographerProvider");
}

void DefaultAndroidChoreographerProvider::EnsureLoaded() const {
  if (loaded_) {
    return;
  }
  if (!library_loader_) {
    library_loader_ = FlutterEmbedderNative::GetDefaultLibraryLoader();
  }
  if (!library_loader_) {
    loaded_ = true;
    return;
  }

  auto lib = library_loader_->LoadDynamicLibrary("libandroid.so");
  if (lib && lib->IsValid()) {
    get_instance_fn_ = lib->ResolveFunction<AChoreographer_getInstance_fn>(
        "AChoreographer_getInstance");
    post_frame_callback64_fn_ =
        lib->ResolveFunction<AChoreographer_postFrameCallback64_fn>(
            "AChoreographer_postFrameCallback64");
    post_frame_callback_fn_ =
        lib->ResolveFunction<AChoreographer_postFrameCallback_fn>(
            "AChoreographer_postFrameCallback");
    post_frame_callback_delayed64_fn_ =
        lib->ResolveFunction<AChoreographer_postFrameCallbackDelayed64_fn>(
            "AChoreographer_postFrameCallbackDelayed64");
    post_frame_callback_delayed_fn_ =
        lib->ResolveFunction<AChoreographer_postFrameCallbackDelayed_fn>(
            "AChoreographer_postFrameCallbackDelayed");

    if (get_instance_fn_ &&
        (post_frame_callback64_fn_ || post_frame_callback_fn_)) {
      is_available_ = true;
      has_64bit_support_ = (post_frame_callback64_fn_ != nullptr);
    }
  }

  loaded_ = true;
}

bool DefaultAndroidChoreographerProvider::IsAvailable() const {
  std::scoped_lock lock(mutex_);
  EnsureLoaded();
  return is_available_;
}

bool DefaultAndroidChoreographerProvider::Has64BitSupport() const {
  std::scoped_lock lock(mutex_);
  EnsureLoaded();
  return has_64bit_support_;
}

static void NativeTrampoline64(int64_t frameTimeNanos, void* data) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidChoreographerProvider::NativeTrampoline64");
  std::unique_ptr<AndroidChoreographerProvider::FrameCallback> holder(
      static_cast<AndroidChoreographerProvider::FrameCallback*>(data));
  if (holder && *holder) {
    (*holder)(frameTimeNanos);
  }
}

static void NativeTrampoline32(int64_t frameTimeNanos, void* data) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidChoreographerProvider::NativeTrampoline32");
  std::unique_ptr<AndroidChoreographerProvider::FrameCallback> holder(
      static_cast<AndroidChoreographerProvider::FrameCallback*>(data));
  if (holder && *holder) {
    (*holder)(static_cast<int64_t>(frameTimeNanos));
  }
}

bool DefaultAndroidChoreographerProvider::PostFrameCallback(
    FrameCallback callback) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidChoreographerProvider::PostFrameCallback");
  std::scoped_lock lock(mutex_);
  EnsureLoaded();

  if (!is_available_ || !get_instance_fn_) {
    return false;
  }

  AChoreographer* choreographer = get_instance_fn_();
  if (!choreographer) {
    return false;
  }

  auto* holder = new FrameCallback(std::move(callback));

  if (has_64bit_support_ && post_frame_callback64_fn_) {
    post_frame_callback64_fn_(choreographer, &NativeTrampoline64, holder);
    return true;
  }

  if (post_frame_callback_fn_) {
    post_frame_callback_fn_(choreographer, &NativeTrampoline32, holder);
    return true;
  }

  delete holder;
  return false;
}

bool DefaultAndroidChoreographerProvider::PostFrameCallbackDelayed(
    FrameCallback callback,
    uint32_t delay_ms) {
  TRACE_EVENT1("flutter",
               "DefaultAndroidChoreographerProvider::PostFrameCallbackDelayed",
               "delay_ms", std::to_string(delay_ms).c_str());
  std::scoped_lock lock(mutex_);
  EnsureLoaded();

  if (!is_available_ || !get_instance_fn_) {
    return false;
  }

  AChoreographer* choreographer = get_instance_fn_();
  if (!choreographer) {
    return false;
  }

  auto* holder = new FrameCallback(std::move(callback));

  if (has_64bit_support_ && post_frame_callback_delayed64_fn_) {
    post_frame_callback_delayed64_fn_(choreographer, &NativeTrampoline64,
                                      holder, delay_ms);
    return true;
  }

  if (post_frame_callback_delayed_fn_) {
    post_frame_callback_delayed_fn_(choreographer, &NativeTrampoline32, holder,
                                    static_cast<int64_t>(delay_ms));
    return true;
  }

  delete holder;
  return false;
}

// =============================================================================
// InMemoryAndroidChoreographerProvider Implementation
// =============================================================================

InMemoryAndroidChoreographerProvider::InMemoryAndroidChoreographerProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidChoreographerProvider::"
               "InMemoryAndroidChoreographerProvider");
}

InMemoryAndroidChoreographerProvider::~InMemoryAndroidChoreographerProvider() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidChoreographerProvider::"
               "~InMemoryAndroidChoreographerProvider");
}

bool InMemoryAndroidChoreographerProvider::IsAvailable() const {
  std::scoped_lock lock(mutex_);
  return is_available_;
}

bool InMemoryAndroidChoreographerProvider::Has64BitSupport() const {
  std::scoped_lock lock(mutex_);
  return has_64bit_support_;
}

void InMemoryAndroidChoreographerProvider::SetAvailable(bool available) {
  TRACE_EVENT1("flutter", "InMemoryAndroidChoreographerProvider::SetAvailable",
               "available", available ? "true" : "false");
  std::scoped_lock lock(mutex_);
  is_available_ = available;
}

void InMemoryAndroidChoreographerProvider::Set64BitSupport(bool has_64bit) {
  TRACE_EVENT1("flutter",
               "InMemoryAndroidChoreographerProvider::Set64BitSupport",
               "has_64bit", has_64bit ? "true" : "false");
  std::scoped_lock lock(mutex_);
  has_64bit_support_ = has_64bit;
}

bool InMemoryAndroidChoreographerProvider::PostFrameCallback(
    FrameCallback callback) {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidChoreographerProvider::PostFrameCallback");
  std::scoped_lock lock(mutex_);
  if (!is_available_) {
    return false;
  }
  pending_callbacks_.push_back(std::move(callback));
  return true;
}

bool InMemoryAndroidChoreographerProvider::PostFrameCallbackDelayed(
    FrameCallback callback,
    uint32_t delay_ms) {
  TRACE_EVENT1("flutter",
               "InMemoryAndroidChoreographerProvider::PostFrameCallbackDelayed",
               "delay_ms", std::to_string(delay_ms).c_str());
  std::scoped_lock lock(mutex_);
  if (!is_available_) {
    return false;
  }
  pending_callbacks_.push_back(std::move(callback));
  return true;
}

size_t InMemoryAndroidChoreographerProvider::GetPendingCallbackCount() const {
  std::scoped_lock lock(mutex_);
  return pending_callbacks_.size();
}

bool InMemoryAndroidChoreographerProvider::HasPendingCallbacks() const {
  std::scoped_lock lock(mutex_);
  return !pending_callbacks_.empty();
}

void InMemoryAndroidChoreographerProvider::FireFrame(int64_t frame_time_nanos) {
  TriggerPendingCallbacks(frame_time_nanos);
}

void InMemoryAndroidChoreographerProvider::TriggerPendingCallbacks(
    int64_t frame_time_nanos) {
  TRACE_EVENT1("flutter",
               "InMemoryAndroidChoreographerProvider::TriggerPendingCallbacks",
               "frame_time_nanos", std::to_string(frame_time_nanos).c_str());
  std::vector<FrameCallback> callbacks;
  {
    std::scoped_lock lock(mutex_);
    callbacks = std::move(pending_callbacks_);
    pending_callbacks_.clear();
  }

  for (const auto& cb : callbacks) {
    if (cb) {
      cb(frame_time_nanos);
    }
  }
}

void InMemoryAndroidChoreographerProvider::ClearPendingCallbacks() {
  TRACE_EVENT0("flutter",
               "InMemoryAndroidChoreographerProvider::ClearPendingCallbacks");
  std::scoped_lock lock(mutex_);
  pending_callbacks_.clear();
}

// =============================================================================
// AndroidVsyncWaiter Implementation
// =============================================================================

AndroidVsyncWaiter::AndroidVsyncWaiter(
    std::shared_ptr<AndroidChoreographerProvider> choreographer_provider,
    std::shared_ptr<JvmInvoker> jvm_invoker)
    : choreographer_provider_(
          choreographer_provider
              ? std::move(choreographer_provider)
              : std::make_shared<DefaultAndroidChoreographerProvider>()),
      jvm_invoker_(std::move(jvm_invoker)) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::AndroidVsyncWaiter");
}

AndroidVsyncWaiter::~AndroidVsyncWaiter() {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::~AndroidVsyncWaiter");
}

void AndroidVsyncWaiter::OnVsyncCallback(void* user_data, intptr_t baton) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::OnVsyncCallback");
  if (!user_data) {
    return;
  }
  auto* waiter = reinterpret_cast<AndroidVsyncWaiter*>(user_data);
  waiter->AsyncWaitForVsync(baton);
}

bool AndroidVsyncWaiter::AsyncWaitForVsync(intptr_t baton) {
  TRACE_EVENT1("flutter", "AndroidVsyncWaiter::AsyncWaitForVsync", "baton",
               std::to_string(baton).c_str());

  std::shared_ptr<AndroidChoreographerProvider> choreographer;
  std::shared_ptr<JvmInvoker> invoker;
  {
    std::scoped_lock lock(mutex_);
    vsync_request_count_++;
    choreographer = choreographer_provider_;
    invoker = jvm_invoker_;
  }

  if (choreographer && choreographer->IsAvailable()) {
    std::weak_ptr<AndroidVsyncWaiter> weak_this = shared_from_this();
    bool posted = choreographer->PostFrameCallback(
        [weak_this, baton](int64_t frame_time_nanos) {
          auto shared_this = weak_this.lock();
          if (shared_this) {
            shared_this->ConsumePendingVsync(baton, frame_time_nanos);
          }
        });
    if (posted) {
      return true;
    }
  }

  if (invoker) {
    std::vector<uint8_t> payload(sizeof(intptr_t));
    std::memcpy(payload.data(), &baton, sizeof(intptr_t));
    return invoker->InvokeVoidMethod("asyncWaitForVsync", "(J)V", payload);
  }

  // Self-contained fallback for simulation / test environments
  ConsumePendingVsync(baton,
                      fml::TimePoint::Now().ToEpochDelta().ToNanoseconds());
  return true;
}

AndroidVsyncFrameInfo AndroidVsyncWaiter::ComputeFramePacing(
    int64_t frame_time_nanos,
    double refresh_rate_hz) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::ComputeFramePacing");
  if (refresh_rate_hz <= 0.0) {
    refresh_rate_hz = 60.0;
  }

  int64_t refresh_period_nanos =
      static_cast<int64_t>(1000000000.0 / refresh_rate_hz);
  int64_t now_nanos = fml::TimePoint::Now().ToEpochDelta().ToNanoseconds();

  int64_t start_time = frame_time_nanos;
  if (start_time <= 0 || start_time > now_nanos) {
    start_time = now_nanos;
  }

  int64_t target_time = start_time + refresh_period_nanos;

  return AndroidVsyncFrameInfo{
      .frame_start_time_nanos = start_time,
      .frame_target_time_nanos = target_time,
      .refresh_period_nanos = refresh_period_nanos,
      .refresh_rate_hz = refresh_rate_hz,
  };
}

static FlutterEngineResult EngineNotifyVsync(FLUTTER_API_SYMBOL(FlutterEngine)
                                                 engine,
                                             intptr_t baton,
                                             uint64_t frame_start_time_nanos,
                                             uint64_t frame_target_time_nanos) {
  static FlutterEngineProcTable s_procs = []() {
    FlutterEngineProcTable procs = {};
    procs.struct_size = sizeof(FlutterEngineProcTable);
    FlutterEngineGetProcAddresses(&procs);
    return procs;
  }();
  if (s_procs.OnVsync) {
    return s_procs.OnVsync(engine, baton, frame_start_time_nanos,
                           frame_target_time_nanos);
  }
  return kInternalInconsistency;
}

void AndroidVsyncWaiter::ConsumePendingVsync(intptr_t baton,
                                             int64_t frame_time_nanos) {
  TRACE_EVENT1("flutter", "AndroidVsyncWaiter::ConsumePendingVsync", "baton",
               std::to_string(baton).c_str());

  double refresh_rate;
  FLUTTER_API_SYMBOL(FlutterEngine) engine;
  VsyncResultCallback result_cb;
  {
    std::scoped_lock lock(mutex_);
    vsync_delivered_count_++;
    refresh_rate = refresh_rate_hz_;
    engine = engine_;
    result_cb = vsync_result_callback_;
  }

  AndroidVsyncFrameInfo info =
      ComputeFramePacing(frame_time_nanos, refresh_rate);

  TRACE_EVENT2_INT("flutter", "PlatformVsync", "frame_start_time",
                   info.frame_start_time_nanos / 1000, "frame_target_time",
                   info.frame_target_time_nanos / 1000);

  if (engine) {
    EngineNotifyVsync(engine, baton, info.frame_start_time_nanos,
                      info.frame_target_time_nanos);
  }

  if (result_cb) {
    result_cb(baton, info.frame_start_time_nanos, info.frame_target_time_nanos);
  }
}

void AndroidVsyncWaiter::UpdateRefreshRate(double refresh_rate_hz) {
  TRACE_EVENT1("flutter", "AndroidVsyncWaiter::UpdateRefreshRate",
               "refresh_rate", std::to_string(refresh_rate_hz).c_str());
  std::scoped_lock lock(mutex_);
  if (refresh_rate_hz > 0.0) {
    refresh_rate_hz_ = refresh_rate_hz;
  }
}

double AndroidVsyncWaiter::GetRefreshRate() const {
  std::scoped_lock lock(mutex_);
  return refresh_rate_hz_;
}

int64_t AndroidVsyncWaiter::GetRefreshPeriodNanos() const {
  std::scoped_lock lock(mutex_);
  return static_cast<int64_t>(1000000000.0 / refresh_rate_hz_);
}

void AndroidVsyncWaiter::SetEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::SetEngine");
  std::scoped_lock lock(mutex_);
  engine_ = engine;
}

FLUTTER_API_SYMBOL(FlutterEngine) AndroidVsyncWaiter::GetEngine() const {
  std::scoped_lock lock(mutex_);
  return engine_;
}

void AndroidVsyncWaiter::SetVsyncResultCallback(VsyncResultCallback callback) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::SetVsyncResultCallback");
  std::scoped_lock lock(mutex_);
  vsync_result_callback_ = std::move(callback);
}

std::shared_ptr<AndroidChoreographerProvider>
AndroidVsyncWaiter::GetChoreographerProvider() const {
  std::scoped_lock lock(mutex_);
  return choreographer_provider_;
}

void AndroidVsyncWaiter::SetChoreographerProvider(
    std::shared_ptr<AndroidChoreographerProvider> provider) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::SetChoreographerProvider");
  std::scoped_lock lock(mutex_);
  choreographer_provider_ =
      provider ? std::move(provider)
               : std::make_shared<DefaultAndroidChoreographerProvider>();
}

std::shared_ptr<JvmInvoker> AndroidVsyncWaiter::GetJvmInvoker() const {
  std::scoped_lock lock(mutex_);
  return jvm_invoker_;
}

void AndroidVsyncWaiter::SetJvmInvoker(std::shared_ptr<JvmInvoker> invoker) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::SetJvmInvoker");
  std::scoped_lock lock(mutex_);
  jvm_invoker_ = std::move(invoker);
}

size_t AndroidVsyncWaiter::GetVsyncRequestCount() const {
  std::scoped_lock lock(mutex_);
  return vsync_request_count_;
}

size_t AndroidVsyncWaiter::GetVsyncDeliveredCount() const {
  std::scoped_lock lock(mutex_);
  return vsync_delivered_count_;
}

}  // namespace android
}  // namespace flutter
