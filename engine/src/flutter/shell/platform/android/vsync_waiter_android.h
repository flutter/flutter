// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_VSYNC_WAITER_ANDROID_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_VSYNC_WAITER_ANDROID_H_

#include <jni.h>

#include <atomic>
#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/vsync_waiter.h"

namespace flutter {

class AndroidChoreographer;

class VsyncWaiterAndroid final : public VsyncWaiter {
 public:
  static bool Register(JNIEnv* env);

  // |yield_next_vsync| is shared with the PlatformViewAndroid of the same
  // engine, which sets it each time that engine renders the first frame into a
  // new surface. When this waiter's next NDK AChoreographer vsync callback
  // arrives it clears the flag and, if the callback is running on the platform
  // thread, delivers it through a main-looper message instead of directly, so
  // that a pending Android ViewRootImpl traversal (such as the first window
  // draw) can run ahead of Flutter's next frame.
  VsyncWaiterAndroid(const flutter::TaskRunners& task_runners,
                     std::shared_ptr<std::atomic<bool>> yield_next_vsync);

  ~VsyncWaiterAndroid() override;

 private:
  // |VsyncWaiter|
  void AwaitVSync() override;

  static void OnVsyncFromNDK(int64_t frame_nanos, void* data);

  // Returns whether the vsync callback of |weak_waiter| should be delivered
  // through a main-looper message rather than directly. Always clears the
  // waiter's yield flag, so this returns true at most once each time the flag
  // is set.
  static bool ShouldYieldVsync(const std::weak_ptr<VsyncWaiter>& weak_waiter);

  static void OnVsyncFromJava(JNIEnv* env,
                              jclass jcaller,
                              jlong frameDelayNanos,
                              jlong refreshPeriodNanos,
                              jlong java_baton);

  static void ConsumePendingCallback(std::weak_ptr<VsyncWaiter>* weak_this,
                                     fml::TimePoint frame_start_time,
                                     fml::TimePoint frame_target_time);

  static void OnUpdateRefreshRate(JNIEnv* env,
                                  jclass jcaller,
                                  jfloat refresh_rate);

  static void RunDeferredVsync(JNIEnv* env, jclass jcaller, jlong callback_ptr);

  const std::shared_ptr<std::atomic<bool>> yield_next_vsync_;

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterAndroid);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_VSYNC_WAITER_ANDROID_H_
