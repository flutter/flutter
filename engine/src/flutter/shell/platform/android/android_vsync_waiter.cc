// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_vsync_waiter.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstring>
#include <unordered_map>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/fml/trace_event.h"

#if FML_OS_ANDROID
#include <android/looper.h>
#endif

extern "C" __attribute__((weak)) FlutterEngineResult
FlutterEngineGetProcAddresses(FlutterEngineProcTable* table);

namespace flutter {
namespace android {

namespace {

using GetProcAddressesFn = FlutterEngineResult (*)(FlutterEngineProcTable*);

FlutterEngineProcTable ResolveDefaultProcTable() {
  FlutterEngineProcTable table{};
  table.struct_size = sizeof(FlutterEngineProcTable);
  if (&FlutterEngineGetProcAddresses != nullptr) {
    FlutterEngineGetProcAddresses(&table);
    return table;
  }
  auto self_lib = fml::NativeLibrary::CreateForCurrentProcess();
  if (self_lib) {
    auto get_procs = self_lib->ResolveFunction<GetProcAddressesFn>(
        "FlutterEngineGetProcAddresses");
    if (get_procs.has_value() && get_procs.value()) {
      get_procs.value()(&table);
    }
  }
  return table;
}

// Conversion factor from nanoseconds to microseconds for trace event counters.
constexpr int64_t kNanosecondsPerMicrosecond = 1000;

std::atomic<double> g_global_refresh_rate{kDefaultDisplayRefreshRateHz};
std::mutex g_pending_batons_mutex;
std::unordered_map<intptr_t, std::weak_ptr<AndroidVsyncWaiter>>
    g_pending_batons;
std::unordered_map<intptr_t, AndroidVsyncWaiter*> g_pending_raw_batons;

void RemoveRawBatonsForWaiter(AndroidVsyncWaiter* waiter) {
  std::scoped_lock lock(g_pending_batons_mutex);
  for (auto it = g_pending_raw_batons.begin();
       it != g_pending_raw_batons.end();) {
    if (it->second == waiter) {
      it = g_pending_raw_batons.erase(it);
    } else {
      ++it;
    }
  }
}

}  // namespace

// =============================================================================
// DefaultAndroidChoreographerProvider Implementation
// =============================================================================

DefaultAndroidChoreographerProvider::DefaultAndroidChoreographerProvider() {
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
#if FML_OS_ANDROID
  library_ = fml::NativeLibrary::Create("libandroid.so");
  if (library_) {
    auto get_inst = library_->ResolveFunction<AChoreographer_getInstance_fn>(
        "AChoreographer_getInstance");
    auto post64 =
        library_->ResolveFunction<AChoreographer_postFrameCallback64_fn>(
            "AChoreographer_postFrameCallback64");
    auto post32 =
        library_->ResolveFunction<AChoreographer_postFrameCallback_fn>(
            "AChoreographer_postFrameCallback");
    auto post_delayed64 =
        library_->ResolveFunction<AChoreographer_postFrameCallbackDelayed64_fn>(
            "AChoreographer_postFrameCallbackDelayed64");
    auto post_delayed32 =
        library_->ResolveFunction<AChoreographer_postFrameCallbackDelayed_fn>(
            "AChoreographer_postFrameCallbackDelayed");

    get_instance_fn_ = get_inst.value_or(nullptr);
    post_frame_callback64_fn_ = post64.value_or(nullptr);
    post_frame_callback_fn_ = post32.value_or(nullptr);
    post_frame_callback_delayed64_fn_ = post_delayed64.value_or(nullptr);
    post_frame_callback_delayed_fn_ = post_delayed32.value_or(nullptr);

    if (get_instance_fn_ &&
        (post_frame_callback64_fn_ || post_frame_callback_fn_)) {
      is_available_ = true;
      has_64bit_support_ = (post_frame_callback64_fn_ != nullptr);
    }
  }
#endif
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

// NOLINTNEXTLINE(google-runtime-int)
static void NativeTrampoline32(long frameTimeNanos, void* data) {
  TRACE_EVENT0("flutter",
               "DefaultAndroidChoreographerProvider::NativeTrampoline32");
  std::unique_ptr<AndroidChoreographerProvider::FrameCallback> holder(
      static_cast<AndroidChoreographerProvider::FrameCallback*>(data));
  if (holder && *holder) {
#if INTPTR_MAX == INT32_MAX
    (*holder)(fml::TimePoint::Now().ToEpochDelta().ToNanoseconds());
#else
    (*holder)(static_cast<int64_t>(frameTimeNanos));
#endif
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

#if FML_OS_ANDROID
  if (ALooper_forThread() == nullptr) {
    ALooper_prepare(0);
  }
#endif

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

#if FML_OS_ANDROID
  if (ALooper_forThread() == nullptr) {
    ALooper_prepare(0);
  }
#endif

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
    post_frame_callback_delayed_fn_(
        choreographer, &NativeTrampoline32, holder,
        static_cast<long>(delay_ms));  // NOLINT(google-runtime-int)
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
  std::scoped_lock lock(mutex_);
  is_available_ = available;
}

void InMemoryAndroidChoreographerProvider::Set64BitSupport(bool has_64bit) {
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
  (void)delay_ms;
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
  std::scoped_lock lock(mutex_);
  pending_callbacks_.clear();
}

// =============================================================================
// AndroidVsyncWaiter Implementation
// =============================================================================

void AndroidVsyncWaiter::SetGlobalRefreshRate(double refresh_rate_hz) {
  if (!std::isfinite(refresh_rate_hz) || refresh_rate_hz <= 0.0) {
    refresh_rate_hz = kDefaultDisplayRefreshRateHz;
  } else {
    refresh_rate_hz = std::clamp(refresh_rate_hz, kMinDisplayRefreshRateHz,
                                 kMaxDisplayRefreshRateHz);
  }
  g_global_refresh_rate.store(refresh_rate_hz);
}

void AndroidVsyncWaiter::UpdateRefreshRate(float refresh_rate_fps) {
  SetGlobalRefreshRate(static_cast<double>(refresh_rate_fps));
}

double AndroidVsyncWaiter::GetGlobalRefreshRate() {
  return g_global_refresh_rate.load();
}

void AndroidVsyncWaiter::RegisterPendingJavaBaton(
    intptr_t baton,
    std::weak_ptr<AndroidVsyncWaiter> waiter) {
  std::scoped_lock lock(g_pending_batons_mutex);
  g_pending_batons[baton] = std::move(waiter);
}

void AndroidVsyncWaiter::RegisterPendingRawBaton(intptr_t baton,
                                                 AndroidVsyncWaiter* waiter) {
  std::scoped_lock lock(g_pending_batons_mutex);
  g_pending_raw_batons[baton] = waiter;
}

void AndroidVsyncWaiter::UnregisterPendingJavaBaton(intptr_t baton) {
  std::scoped_lock lock(g_pending_batons_mutex);
  g_pending_batons.erase(baton);
  g_pending_raw_batons.erase(baton);
}

void AndroidVsyncWaiter::OnNativeVsync(int64_t frame_delay_nanos,
                                       int64_t refresh_period_nanos,
                                       intptr_t java_baton) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::OnNativeVsync");
  std::shared_ptr<AndroidVsyncWaiter> shared_waiter;
  AndroidVsyncWaiter* raw_waiter = nullptr;
  {
    std::scoped_lock lock(g_pending_batons_mutex);
    auto it = g_pending_batons.find(java_baton);
    if (it != g_pending_batons.end()) {
      shared_waiter = it->second.lock();
      g_pending_batons.erase(it);
    }
    auto raw_it = g_pending_raw_batons.find(java_baton);
    if (raw_it != g_pending_raw_batons.end()) {
      raw_waiter = raw_it->second;
      g_pending_raw_batons.erase(raw_it);
    }
  }

  int64_t now_nanos = fml::TimePoint::Now().ToEpochDelta().ToNanoseconds();
  int64_t frame_time_nanos = now_nanos - frame_delay_nanos;

  if (shared_waiter) {
    shared_waiter->ConsumePendingVsync(java_baton, frame_time_nanos,
                                       refresh_period_nanos);
  } else if (raw_waiter) {
    raw_waiter->ConsumePendingVsync(java_baton, frame_time_nanos,
                                    refresh_period_nanos);
  }
}

void AndroidVsyncWaiter::OnJavaVsync(int64_t frame_delay_nanos,
                                     int64_t refresh_period_nanos,
                                     intptr_t baton) {
  OnNativeVsync(frame_delay_nanos, refresh_period_nanos, baton);
}

AndroidVsyncWaiter::AndroidVsyncWaiter(
    std::shared_ptr<AndroidChoreographerProvider> choreographer_provider,
    std::shared_ptr<JvmInvoker> jvm_invoker,
    const FlutterEngineProcTable* proc_table)
    : proc_table_(proc_table ? *proc_table : ResolveDefaultProcTable()),
      choreographer_provider_(
          choreographer_provider
              ? std::move(choreographer_provider)
              : std::make_shared<DefaultAndroidChoreographerProvider>()),
      jvm_invoker_(std::move(jvm_invoker)),
      refresh_rate_hz_(GetGlobalRefreshRate()) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::AndroidVsyncWaiter");
}

AndroidVsyncWaiter::~AndroidVsyncWaiter() {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::~AndroidVsyncWaiter");
  Detach();
  RemoveRawBatonsForWaiter(this);
}

void AndroidVsyncWaiter::Detach() {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::Detach");
  {
    std::scoped_lock lock(mutex_);
    detached_ = true;
    engine_ = nullptr;
  }
  RemoveRawBatonsForWaiter(this);
}

bool AndroidVsyncWaiter::IsDetached() const {
  std::scoped_lock lock(mutex_);
  return detached_;
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
    if (detached_) {
      return false;
    }
    vsync_request_count_++;
    choreographer = choreographer_provider_;
    invoker = jvm_invoker_;
  }

  if (choreographer && choreographer->IsAvailable()) {
    std::weak_ptr<AndroidVsyncWaiter> weak_this = weak_from_this();
    if (!weak_this.expired()) {
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
    } else {
      RegisterPendingRawBaton(baton, this);
      bool posted =
          choreographer->PostFrameCallback([baton](int64_t frame_time_nanos) {
            AndroidVsyncWaiter* waiter = nullptr;
            {
              std::scoped_lock lock(g_pending_batons_mutex);
              auto it = g_pending_raw_batons.find(baton);
              if (it != g_pending_raw_batons.end()) {
                waiter = it->second;
                g_pending_raw_batons.erase(it);
              }
            }
            if (waiter) {
              waiter->ConsumePendingVsync(baton, frame_time_nanos);
            }
          });
      if (posted) {
        return true;
      }
      UnregisterPendingJavaBaton(baton);
    }
  }

  if (invoker && invoker->IsAttached()) {
    std::weak_ptr<AndroidVsyncWaiter> weak_this = weak_from_this();
    if (!weak_this.expired()) {
      RegisterPendingJavaBaton(baton, weak_this);
    } else {
      RegisterPendingRawBaton(baton, this);
    }
    invoker->AsyncWaitForVsync(static_cast<int64_t>(baton));
    return true;
  }

  // Self-contained fallback for host simulation / unit test environments.
  ConsumePendingVsync(baton,
                      fml::TimePoint::Now().ToEpochDelta().ToNanoseconds());
  return true;
}

AndroidVsyncFrameInfo AndroidVsyncWaiter::ComputeFramePacing(
    int64_t frame_time_nanos,
    double refresh_rate_hz) {
  TRACE_EVENT0("flutter", "AndroidVsyncWaiter::ComputeFramePacing");
  if (!std::isfinite(refresh_rate_hz) || refresh_rate_hz <= 0.0) {
    refresh_rate_hz = kDefaultDisplayRefreshRateHz;
  } else {
    refresh_rate_hz = std::clamp(refresh_rate_hz, kMinDisplayRefreshRateHz,
                                 kMaxDisplayRefreshRateHz);
  }

  int64_t refresh_period_nanos =
      static_cast<int64_t>(kNanosecondsPerSecond / refresh_rate_hz);
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

void AndroidVsyncWaiter::ConsumePendingVsync(intptr_t baton,
                                             int64_t frame_time_nanos,
                                             int64_t refresh_period_nanos) {
  TRACE_EVENT1("flutter", "AndroidVsyncWaiter::ConsumePendingVsync", "baton",
               std::to_string(baton).c_str());

  VsyncResultCallback result_cb;
  AndroidVsyncFrameInfo info;
  {
    std::scoped_lock lock(mutex_);
    if (detached_) {
      return;
    }
    vsync_delivered_count_++;
    double refresh_rate = refresh_rate_hz_;
    if (refresh_rate <= 0.0) {
      refresh_rate = GetGlobalRefreshRate();
    }
    if (refresh_period_nanos > 0) {
      info.frame_start_time_nanos = frame_time_nanos;
      info.frame_target_time_nanos = frame_time_nanos + refresh_period_nanos;
      info.refresh_period_nanos = refresh_period_nanos;
      info.refresh_rate_hz =
          kNanosecondsPerSecond / static_cast<double>(refresh_period_nanos);
    } else {
      info = ComputeFramePacing(frame_time_nanos, refresh_rate);
    }

    TRACE_EVENT2_INT("flutter", "PlatformVsync", "frame_start_time",
                     info.frame_start_time_nanos / kNanosecondsPerMicrosecond,
                     "frame_target_time",
                     info.frame_target_time_nanos / kNanosecondsPerMicrosecond);

    if (notify_vsync_fn_) {
      notify_vsync_fn_(engine_, baton,
                       static_cast<uint64_t>(info.frame_start_time_nanos),
                       static_cast<uint64_t>(info.frame_target_time_nanos));
    } else if (engine_ != nullptr && proc_table_.OnVsync != nullptr) {
      proc_table_.OnVsync(engine_, baton,
                          static_cast<uint64_t>(info.frame_start_time_nanos),
                          static_cast<uint64_t>(info.frame_target_time_nanos));
    }
    result_cb = vsync_result_callback_;
  }

  if (result_cb) {
    result_cb(baton, info.frame_start_time_nanos, info.frame_target_time_nanos);
  }
}

void AndroidVsyncWaiter::SetNotifyVsyncFnForTesting(NotifyVsyncFn fn) {
  std::scoped_lock lock(mutex_);
  notify_vsync_fn_ = std::move(fn);
}

void AndroidVsyncWaiter::SetRefreshRate(double refresh_rate_hz) {
  if (!std::isfinite(refresh_rate_hz) || refresh_rate_hz <= 0.0) {
    refresh_rate_hz = kDefaultDisplayRefreshRateHz;
  } else {
    refresh_rate_hz = std::clamp(refresh_rate_hz, kMinDisplayRefreshRateHz,
                                 kMaxDisplayRefreshRateHz);
  }
  std::scoped_lock lock(mutex_);
  refresh_rate_hz_ = refresh_rate_hz;
}

double AndroidVsyncWaiter::GetRefreshRate() const {
  std::scoped_lock lock(mutex_);
  return refresh_rate_hz_;
}

int64_t AndroidVsyncWaiter::GetRefreshPeriodNanos() const {
  std::scoped_lock lock(mutex_);
  double rate = refresh_rate_hz_;
  if (!std::isfinite(rate) || rate <= 0.0) {
    rate = kDefaultDisplayRefreshRateHz;
  } else {
    rate = std::clamp(rate, kMinDisplayRefreshRateHz, kMaxDisplayRefreshRateHz);
  }
  return static_cast<int64_t>(kNanosecondsPerSecond / rate);
}

void AndroidVsyncWaiter::SetEngine(FLUTTER_API_SYMBOL(FlutterEngine) engine) {
  std::scoped_lock lock(mutex_);
  engine_ = engine;
  detached_ = (engine == nullptr);
}

FLUTTER_API_SYMBOL(FlutterEngine) AndroidVsyncWaiter::GetEngine() const {
  std::scoped_lock lock(mutex_);
  return engine_;
}

void AndroidVsyncWaiter::SetProcTable(
    const FlutterEngineProcTable& proc_table) {
  std::scoped_lock lock(mutex_);
  proc_table_ = proc_table;
}

void AndroidVsyncWaiter::SetVsyncResultCallback(VsyncResultCallback callback) {
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
