// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_performance_hint_manager.h"

#include <android/api-level.h>
#include <dlfcn.h>
#include <cerrno>
#include <mutex>
#include <optional>

#include "flutter/fml/logging.h"
#include "flutter/fml/native_library.h"

namespace flutter {

// Opaque handles matching NDK <android/performance_hint.h>
struct APerformanceHintManager;
struct APerformanceHintSession;
struct AWorkDuration;

using APerformanceHint_getManager_fn = APerformanceHintManager* (*)();
using APerformanceHint_createSession_fn =
    APerformanceHintSession* (*)(APerformanceHintManager*,
                                 const int32_t*,
                                 size_t,
                                 int64_t);
using APerformanceHint_reportActualWorkDuration2_fn =
    int (*)(APerformanceHintSession*, AWorkDuration*);
using APerformanceHint_updateTargetWorkDuration_fn =
    int (*)(APerformanceHintSession*, int64_t);
using APerformanceHint_closeSession_fn = void (*)(APerformanceHintSession*);

using AWorkDuration_create_fn = AWorkDuration* (*)();
using AWorkDuration_release_fn = void (*)(AWorkDuration*);
using AWorkDuration_setWorkPeriodStartTimestampNanos_fn =
    void (*)(AWorkDuration*, int64_t);
using AWorkDuration_setActualTotalDurationNanos_fn = void (*)(AWorkDuration*,
                                                              int64_t);
using AWorkDuration_setActualCpuDurationNanos_fn = void (*)(AWorkDuration*,
                                                            int64_t);
using AWorkDuration_setActualGpuDurationNanos_fn = void (*)(AWorkDuration*,
                                                            int64_t);

struct AndroidPerformanceHintManager::Impl {
  mutable std::mutex mutex;
  fml::RefPtr<fml::NativeLibrary> lib_android;
  APerformanceHintSession* session = nullptr;
  AWorkDuration* work_duration = nullptr;
  int64_t applied_target_duration_ns = 0;

  APerformanceHint_reportActualWorkDuration2_fn report_actual_work_duration2 =
      nullptr;
  APerformanceHint_updateTargetWorkDuration_fn update_target_work_duration =
      nullptr;
  APerformanceHint_closeSession_fn close_session = nullptr;

  AWorkDuration_release_fn release_work_duration = nullptr;
  AWorkDuration_setWorkPeriodStartTimestampNanos_fn set_work_period_start =
      nullptr;
  AWorkDuration_setActualTotalDurationNanos_fn set_actual_total_duration =
      nullptr;
  AWorkDuration_setActualCpuDurationNanos_fn set_actual_cpu_duration = nullptr;
  AWorkDuration_setActualGpuDurationNanos_fn set_actual_gpu_duration = nullptr;

  ~Impl() {
    std::lock_guard<std::mutex> lock(mutex);
    CloseSessionLocked();
  }

  void CloseSessionLocked() {
    if (session && close_session) {
      close_session(session);
      session = nullptr;
    }
    if (work_duration && release_work_duration) {
      release_work_duration(work_duration);
      work_duration = nullptr;
    }
  }
};

std::unique_ptr<AndroidPerformanceHintManager>
AndroidPerformanceHintManager::Create(const std::vector<int32_t>& tids,
                                      int64_t target_duration_ns) {
  if (tids.empty() || target_duration_ns <= 0) {
    return nullptr;
  }

  // Gate to Android 15+ (API 35+), where AWorkDuration and
  // APerformanceHint_reportActualWorkDuration2 were introduced to accurately
  // report decomposed CPU work durations and total frame turnaround time
  // without relying on heuristics for multi-threaded thread groups.
  if (android_get_device_api_level() < 35) {
    return nullptr;
  }

  fml::RefPtr<fml::NativeLibrary> lib_android =
      fml::NativeLibrary::Create("libandroid.so");
  if (!lib_android) {
    return nullptr;
  }

  const std::optional<APerformanceHint_getManager_fn> get_manager =
      lib_android->ResolveFunction<APerformanceHint_getManager_fn>(
          "APerformanceHint_getManager");
  const std::optional<APerformanceHint_createSession_fn> create_session =
      lib_android->ResolveFunction<APerformanceHint_createSession_fn>(
          "APerformanceHint_createSession");
  const std::optional<APerformanceHint_reportActualWorkDuration2_fn>
      report_actual2 =
          lib_android
              ->ResolveFunction<APerformanceHint_reportActualWorkDuration2_fn>(
                  "APerformanceHint_reportActualWorkDuration2");
  const std::optional<APerformanceHint_updateTargetWorkDuration_fn>
      update_target =
          lib_android
              ->ResolveFunction<APerformanceHint_updateTargetWorkDuration_fn>(
                  "APerformanceHint_updateTargetWorkDuration");
  const std::optional<APerformanceHint_closeSession_fn> close_session =
      lib_android->ResolveFunction<APerformanceHint_closeSession_fn>(
          "APerformanceHint_closeSession");

  const std::optional<AWorkDuration_create_fn> work_duration_create =
      lib_android->ResolveFunction<AWorkDuration_create_fn>(
          "AWorkDuration_create");
  const std::optional<AWorkDuration_release_fn> work_duration_release =
      lib_android->ResolveFunction<AWorkDuration_release_fn>(
          "AWorkDuration_release");
  const std::optional<AWorkDuration_setWorkPeriodStartTimestampNanos_fn>
      set_work_period_start = lib_android->ResolveFunction<
          AWorkDuration_setWorkPeriodStartTimestampNanos_fn>(
          "AWorkDuration_setWorkPeriodStartTimestampNanos");
  const std::optional<AWorkDuration_setActualTotalDurationNanos_fn>
      set_actual_total_duration =
          lib_android
              ->ResolveFunction<AWorkDuration_setActualTotalDurationNanos_fn>(
                  "AWorkDuration_setActualTotalDurationNanos");
  const std::optional<AWorkDuration_setActualCpuDurationNanos_fn>
      set_actual_cpu_duration =
          lib_android
              ->ResolveFunction<AWorkDuration_setActualCpuDurationNanos_fn>(
                  "AWorkDuration_setActualCpuDurationNanos");
  const std::optional<AWorkDuration_setActualGpuDurationNanos_fn>
      set_actual_gpu_duration =
          lib_android
              ->ResolveFunction<AWorkDuration_setActualGpuDurationNanos_fn>(
                  "AWorkDuration_setActualGpuDurationNanos");

  if (!get_manager.has_value() || !create_session.has_value() ||
      !report_actual2.has_value() || !update_target.has_value() ||
      !close_session.has_value() || !work_duration_create.has_value() ||
      !work_duration_release.has_value() ||
      !set_work_period_start.has_value() ||
      !set_actual_total_duration.has_value() ||
      !set_actual_cpu_duration.has_value() ||
      !set_actual_gpu_duration.has_value()) {
    FML_LOG(WARNING)
        << "ADPF PerformanceHint APIs not available in libandroid.so";
    return nullptr;
  }

  APerformanceHintManager* manager = get_manager.value()();
  if (!manager) {
    FML_LOG(WARNING) << "APerformanceHint_getManager returned nullptr";
    return nullptr;
  }

  APerformanceHintSession* session = create_session.value()(
      manager, tids.data(), tids.size(), target_duration_ns);
  if (!session) {
    FML_LOG(WARNING) << "Failed to create APerformanceHintSession for "
                     << tids.size() << " threads";
    return nullptr;
  }

  AWorkDuration* work_duration = work_duration_create.value()();
  if (!work_duration) {
    FML_LOG(WARNING) << "Failed to allocate AWorkDuration";
    close_session.value()(session);
    return nullptr;
  }

  std::unique_ptr<Impl> impl = std::make_unique<Impl>();
  impl->lib_android = std::move(lib_android);
  impl->session = session;
  impl->work_duration = work_duration;
  impl->applied_target_duration_ns = target_duration_ns;
  impl->report_actual_work_duration2 = report_actual2.value();
  impl->update_target_work_duration = update_target.value();
  impl->close_session = close_session.value();
  impl->release_work_duration = work_duration_release.value();
  impl->set_work_period_start = set_work_period_start.value();
  impl->set_actual_total_duration = set_actual_total_duration.value();
  impl->set_actual_cpu_duration = set_actual_cpu_duration.value();
  impl->set_actual_gpu_duration = set_actual_gpu_duration.value();

  FML_DLOG(INFO) << "Created ADPF PerformanceHintSession with target "
                 << target_duration_ns << " ns (" << (1e9 / target_duration_ns)
                 << " Hz) for " << tids.size() << " threads";

  return std::unique_ptr<AndroidPerformanceHintManager>(
      new AndroidPerformanceHintManager(std::move(impl)));
}

AndroidPerformanceHintManager::AndroidPerformanceHintManager(
    std::unique_ptr<Impl> impl)
    : impl_(std::move(impl)) {}

AndroidPerformanceHintManager::~AndroidPerformanceHintManager() = default;

void AndroidPerformanceHintManager::ReportActualWorkDuration(
    int64_t work_period_start_ns,
    int64_t actual_total_duration_ns,
    int64_t actual_cpu_duration_ns,
    int64_t actual_gpu_duration_ns) {
  if (!impl_ || work_period_start_ns <= 0 || actual_total_duration_ns <= 0 ||
      actual_cpu_duration_ns < 0 || actual_gpu_duration_ns < 0 ||
      (actual_cpu_duration_ns == 0 && actual_gpu_duration_ns == 0)) {
    return;
  }
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (impl_->session && impl_->work_duration &&
      impl_->report_actual_work_duration2) {
    impl_->set_work_period_start(impl_->work_duration, work_period_start_ns);
    impl_->set_actual_total_duration(impl_->work_duration,
                                     actual_total_duration_ns);
    impl_->set_actual_cpu_duration(impl_->work_duration,
                                   actual_cpu_duration_ns);
    impl_->set_actual_gpu_duration(impl_->work_duration,
                                   actual_gpu_duration_ns);

    int result = impl_->report_actual_work_duration2(impl_->session,
                                                     impl_->work_duration);
    if (result != 0) {
      if (result == EPIPE) {
        FML_LOG(WARNING)
            << "ADPF session disconnected (EPIPE). Closing session.";
        impl_->CloseSessionLocked();
      } else {
        FML_DLOG(WARNING)
            << "APerformanceHint_reportActualWorkDuration2 returned " << result;
      }
    }
  }
}

void AndroidPerformanceHintManager::UpdateTargetWorkDuration(
    int64_t target_duration_ns) {
  if (!impl_ || target_duration_ns <= 0) {
    return;
  }
  std::lock_guard<std::mutex> lock(impl_->mutex);
  if (impl_->applied_target_duration_ns == target_duration_ns) {
    return;
  }
  if (impl_->session && impl_->update_target_work_duration) {
    int result =
        impl_->update_target_work_duration(impl_->session, target_duration_ns);
    if (result != 0) {
      if (result == EPIPE) {
        FML_LOG(WARNING)
            << "ADPF session disconnected (EPIPE). Closing session.";
        impl_->CloseSessionLocked();
      } else {
        FML_DLOG(WARNING)
            << "APerformanceHint_updateTargetWorkDuration returned " << result;
      }
    } else {
      impl_->applied_target_duration_ns = target_duration_ns;
    }
  }
}

int64_t AndroidPerformanceHintManager::GetTargetWorkDuration() const {
  if (!impl_) {
    return 0;
  }
  std::lock_guard<std::mutex> lock(impl_->mutex);
  return impl_->applied_target_duration_ns;
}

}  // namespace flutter
