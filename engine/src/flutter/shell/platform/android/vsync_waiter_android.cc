// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/vsync_waiter_android.h"

#include <atomic>
#include <chrono>
#include <cmath>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/fml/task_runner.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/ndk/choreographer.h"

namespace flutter {

static fml::jni::ScopedJavaGlobalRef<jclass>* g_vsync_waiter_class = nullptr;
static jmethodID g_async_wait_for_vsync_method_ = nullptr;
static std::atomic_uint g_refresh_rate_ = 60;

namespace {

// Nanoseconds per second, to turn the refresh rate into a frame interval.
constexpr double kNanosecondsPerSecond = 1000000000.0;

// The cookie of the Java fallback, passed through
// FlutterJNI.asyncWaitForVsync. OnVsyncFromJava deletes it.
struct JavaVsyncRequest {
  std::weak_ptr<VsyncWaiterAndroid> waiter;
  intptr_t baton;
};

fml::TimeDelta FrameInterval() {
  return fml::TimeDelta::FromNanoseconds(kNanosecondsPerSecond /
                                         g_refresh_rate_);
}

uint64_t ToEmbedderNanos(fml::TimePoint time) {
  return static_cast<uint64_t>(time.ToEpochDelta().ToNanoseconds());
}

}  // namespace

VsyncWaiterAndroid::VsyncWaiterAndroid(
    fml::RefPtr<fml::TaskRunner> platform_task_runner)
    : platform_task_runner_(std::move(platform_task_runner)) {}

VsyncWaiterAndroid::~VsyncWaiterAndroid() = default;

void VsyncWaiterAndroid::Attach(FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                const FlutterEngineProcTable* embedder_api) {
  FML_DCHECK(engine != nullptr && embedder_api != nullptr);
  std::scoped_lock lock(mutex_);
  FML_DCHECK(state_ == State::kWaitingForEngine);
  engine_ = engine;
  embedder_api_ = embedder_api;
  state_ = State::kAttached;
}

void VsyncWaiterAndroid::Detach() {
  std::scoped_lock lock(mutex_);
  if (state_ == State::kAttached) {
    const fml::TimePoint now = fml::TimePoint::Now();
    for (intptr_t baton : outstanding_batons_) {
      ReturnBatonLocked(baton, now, now + FrameInterval());
    }
  } else if (!outstanding_batons_.empty()) {
    FML_LOG(WARNING) << outstanding_batons_.size()
                     << " vsync batons leak: the engine never got a handle.";
  }
  outstanding_batons_.clear();
  state_ = State::kDetached;
  engine_ = nullptr;
  embedder_api_ = nullptr;
}

void VsyncWaiterAndroid::AwaitVSync(intptr_t baton) {
  {
    std::scoped_lock lock(mutex_);
    if (state_ == State::kDetached) {
      // The engine is being destroyed on the platform thread, and only a call
      // that returns before that starts is allowed.
      FML_DLOG(WARNING) << "Vsync requested during engine shutdown; its baton "
                           "leaks.";
      return;
    }
    if (!ui_task_runner_) {
      fml::MessageLoop::EnsureInitializedForCurrentThread();
      ui_task_runner_ = fml::MessageLoop::GetCurrent().GetTaskRunner();
    }
    outstanding_batons_.insert(baton);
  }
  RequestFrame(baton);
}

void VsyncWaiterAndroid::RequestFrame(intptr_t baton) {
  const static bool use_choreographer = Choreographer::IsAvailableOnPlatform();
  if (use_choreographer) {
    fml::RefPtr<fml::TaskRunner> ui_task_runner;
    {
      std::scoped_lock lock(mutex_);
      ui_task_runner = ui_task_runner_;
    }
    fml::TaskRunner::RunNowOrPostTask(
        ui_task_runner, [weak_this = weak_from_this(), baton]() {
          const auto& choreographer = Choreographer::GetInstance();
          bool posted =
              choreographer.PostFrameCallback([weak_this, baton](auto time) {
                auto time_ns =
                    std::chrono::time_point_cast<std::chrono::nanoseconds>(time)
                        .time_since_epoch()
                        .count();
                OnVsyncFromNDK(time_ns, weak_this, baton);
              });
          if (!posted) {
            FML_LOG(ERROR) << "Could not post a Choreographer frame callback.";
          }
        });
  } else {
    // TODO(99798): Remove it when we drop support for API level < 29 and 32-bit
    // devices.
    auto* request = new JavaVsyncRequest{weak_from_this(), baton};
    jlong java_baton = reinterpret_cast<jlong>(request);
    // NOLINTNEXTLINE(clang-analyzer-cplusplus.NewDeleteLeaks)
    platform_task_runner_->PostTask([java_baton]() {
      JNIEnv* env = fml::jni::AttachCurrentThread();
      env->CallStaticVoidMethod(g_vsync_waiter_class->obj(),     //
                                g_async_wait_for_vsync_method_,  //
                                java_baton                       //
      );
    });
  }
}

// static
void VsyncWaiterAndroid::OnVsyncFromNDK(
    int64_t frame_nanos,
    const std::weak_ptr<VsyncWaiterAndroid>& weak_this,
    intptr_t baton) {
  auto frame_time = fml::TimePoint::FromEpochDelta(
      fml::TimeDelta::FromNanoseconds(frame_nanos));
  auto now = fml::TimePoint::Now();
  if (frame_time > now) {
    frame_time = now;
  }
  auto target_time = frame_time + FrameInterval();

  TRACE_EVENT2_INT("flutter", "PlatformVsync", "frame_start_time",
                   frame_time.ToEpochDelta().ToMicroseconds(),
                   "frame_target_time",
                   target_time.ToEpochDelta().ToMicroseconds());

  if (std::shared_ptr<VsyncWaiterAndroid> shared_this = weak_this.lock()) {
    shared_this->OnFrame(baton, frame_time, target_time);
  }
}

// static
void VsyncWaiterAndroid::OnVsyncFromJava(JNIEnv* env,
                                         jclass jcaller,
                                         jlong frameDelayNanos,
                                         jlong refreshPeriodNanos,
                                         jlong java_baton) {
  auto frame_time =
      fml::TimePoint::Now() - fml::TimeDelta::FromNanoseconds(frameDelayNanos);
  auto target_time =
      frame_time + fml::TimeDelta::FromNanoseconds(refreshPeriodNanos);

  TRACE_EVENT2_INT("flutter", "PlatformVsync", "frame_start_time",
                   frame_time.ToEpochDelta().ToMicroseconds(),
                   "frame_target_time",
                   target_time.ToEpochDelta().ToMicroseconds());

  std::unique_ptr<JavaVsyncRequest> request(
      reinterpret_cast<JavaVsyncRequest*>(java_baton));
  if (std::shared_ptr<VsyncWaiterAndroid> waiter = request->waiter.lock()) {
    waiter->OnFrame(request->baton, frame_time, target_time);
  }
}

void VsyncWaiterAndroid::OnFrame(intptr_t baton,
                                 fml::TimePoint frame_start_time,
                                 fml::TimePoint frame_target_time) {
  {
    std::scoped_lock lock(mutex_);
    switch (state_) {
      case State::kAttached:
        if (outstanding_batons_.erase(baton) == 0) {
          FML_LOG(ERROR) << "Vsync frame for a baton that was not outstanding.";
          return;
        }
        ReturnBatonLocked(baton, frame_start_time, frame_target_time);
        return;
      case State::kDetached:
        // Detach() returned the baton.
        return;
      case State::kWaitingForEngine:
        break;
    }
  }
  // A spawned engine asked before its holder attached the handle.
  RequestFrame(baton);
}

void VsyncWaiterAndroid::ReturnBatonLocked(intptr_t baton,
                                           fml::TimePoint frame_start_time,
                                           fml::TimePoint frame_target_time) {
  FlutterEngineResult result =
      embedder_api_->OnVsync(engine_, baton, ToEmbedderNanos(frame_start_time),
                             ToEmbedderNanos(frame_target_time));
  if (result != kSuccess) {
    FML_LOG(ERROR) << "FlutterEngineOnVsync failed: " << result;
  }
}

// static
void VsyncWaiterAndroid::OnUpdateRefreshRate(JNIEnv* env,
                                             jclass jcaller,
                                             jfloat refresh_rate) {
  FML_DCHECK(refresh_rate > 0);
  g_refresh_rate_ = static_cast<uint>(refresh_rate);
}

// static
bool VsyncWaiterAndroid::Register(JNIEnv* env) {
  static const JNINativeMethod methods[] = {
      {
          .name = "nativeOnVsync",
          .signature = "(JJJ)V",
          .fnPtr = reinterpret_cast<void*>(&OnVsyncFromJava),
      },
      {
          .name = "nativeUpdateRefreshRate",
          .signature = "(F)V",
          .fnPtr = reinterpret_cast<void*>(&OnUpdateRefreshRate),
      }};

  jclass clazz = env->FindClass("io/flutter/embedding/engine/FlutterJNI");

  if (clazz == nullptr) {
    return false;
  }

  g_vsync_waiter_class = new fml::jni::ScopedJavaGlobalRef<jclass>(env, clazz);
  FML_CHECK(!g_vsync_waiter_class->is_null());

  g_async_wait_for_vsync_method_ = env->GetStaticMethodID(
      g_vsync_waiter_class->obj(), "asyncWaitForVsync", "(J)V");
  FML_CHECK(g_async_wait_for_vsync_method_ != nullptr);

  return env->RegisterNatives(clazz, methods, std::size(methods)) == 0;
}

}  // namespace flutter
