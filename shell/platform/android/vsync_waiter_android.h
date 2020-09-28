// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_ANDROID_VSYNC_WAITER_ANDROID_H_
#define SHELL_PLATFORM_ANDROID_VSYNC_WAITER_ANDROID_H_

#include <jni.h>

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/vsync_waiter.h"

namespace flutter {

class VsyncWaiterAndroid final : public VsyncWaiter {
 public:
  static bool Register(JNIEnv* env);

  VsyncWaiterAndroid(flutter::TaskRunners task_runners);

  ~VsyncWaiterAndroid() override;

 private:
  // |VsyncWaiter|
  void AwaitVSync() override;

  static void OnNativeVsync(JNIEnv* env,
                            jclass jcaller,
                            jlong frameTimeNanos,
                            jlong frameTargetTimeNanos,
                            jlong java_baton);

  static void ConsumePendingCallback(jlong java_baton,
                                     fml::TimePoint frame_start_time,
                                     fml::TimePoint frame_target_time);

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterAndroid);
};

}  // namespace flutter

#endif  // SHELL_PLATFORM_ANDROID_ASYNC_WAITER_ANDROID_H_
