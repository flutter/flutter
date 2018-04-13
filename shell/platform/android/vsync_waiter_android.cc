// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/vsync_waiter_android.h"

#include <cmath>
#include <utility>

#include "flutter/common/task_runners.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/fml/trace_event.h"
#include "lib/fxl/arraysize.h"
#include "lib/fxl/logging.h"

namespace shell {

static jlong CreatePendingCallback(VsyncWaiter::Callback callback);

static void ConsumePendingCallback(jlong java_baton,
                                   fxl::TimePoint frame_start_time,
                                   fxl::TimePoint frame_target_time);

static fml::jni::ScopedJavaGlobalRef<jclass>* g_vsync_waiter_class = nullptr;
static jmethodID g_async_wait_for_vsync_method_ = nullptr;

VsyncWaiterAndroid::VsyncWaiterAndroid(blink::TaskRunners task_runners)
    : VsyncWaiter(std::move(task_runners)) {}

VsyncWaiterAndroid::~VsyncWaiterAndroid() = default;

// |shell::VsyncWaiter|
void VsyncWaiterAndroid::AwaitVSync() {
  auto java_baton =
      CreatePendingCallback(std::bind(&VsyncWaiterAndroid::FireCallback,  //
                                      this,                               //
                                      std::placeholders::_1,              //
                                      std::placeholders::_2               //
                                      ));

  task_runners_.GetPlatformTaskRunner()->PostTask([java_baton]() {
    JNIEnv* env = fml::jni::AttachCurrentThread();
    env->CallStaticVoidMethod(g_vsync_waiter_class->obj(),     //
                              g_async_wait_for_vsync_method_,  //
                              java_baton                       //
    );
  });
}

static void OnNativeVsync(JNIEnv* env,
                          jclass jcaller,
                          jlong frameTimeNanos,
                          jlong frameTargetTimeNanos,
                          jlong java_baton) {
  auto frame_time = fxl::TimePoint::FromEpochDelta(
      fxl::TimeDelta::FromNanoseconds(frameTimeNanos));
  auto target_time = fxl::TimePoint::FromEpochDelta(
      fxl::TimeDelta::FromNanoseconds(frameTargetTimeNanos));

  ConsumePendingCallback(java_baton, frame_time, target_time);
}

bool VsyncWaiterAndroid::Register(JNIEnv* env) {
  static const JNINativeMethod methods[] = {{
      .name = "nativeOnVsync",
      .signature = "(JJJ)V",
      .fnPtr = reinterpret_cast<void*>(&OnNativeVsync),
  }};

  jclass clazz = env->FindClass("io/flutter/view/VsyncWaiter");

  if (clazz == nullptr) {
    return false;
  }

  g_vsync_waiter_class = new fml::jni::ScopedJavaGlobalRef<jclass>(env, clazz);

  FXL_CHECK(!g_vsync_waiter_class->is_null());

  g_async_wait_for_vsync_method_ = env->GetStaticMethodID(
      g_vsync_waiter_class->obj(), "asyncWaitForVsync", "(J)V");

  FXL_CHECK(g_async_wait_for_vsync_method_ != nullptr);

  return env->RegisterNatives(clazz, methods, arraysize(methods)) == 0;
}

struct PendingCallbackData {
  VsyncWaiter::Callback callback;

  PendingCallbackData(VsyncWaiter::Callback p_callback)
      : callback(std::move(p_callback)) {
    FXL_DCHECK(callback);
  }
};

static jlong CreatePendingCallback(VsyncWaiter::Callback callback) {
  // This delete for this new is balanced in the consume call.
  auto data = new PendingCallbackData(std::move(callback));
  return reinterpret_cast<jlong>(data);
}

static void ConsumePendingCallback(jlong java_baton,
                                   fxl::TimePoint frame_start_time,
                                   fxl::TimePoint frame_target_time) {
  auto data = reinterpret_cast<PendingCallbackData*>(java_baton);
  data->callback(frame_start_time, frame_target_time);
  delete data;
}

}  // namespace shell
