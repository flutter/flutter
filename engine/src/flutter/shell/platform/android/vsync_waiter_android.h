// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_VSYNC_WAITER_ANDROID_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_VSYNC_WAITER_ANDROID_H_

#include <jni.h>

#include <cstdint>
#include <memory>
#include <mutex>
#include <unordered_set>

#include "flutter/common/task_runners.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Answers the embedder API vsync callback with Choreographer
///             frames.
///
/// @details    The engine asks for a vsync by passing a baton to the vsync
///             callback on its UI thread. AwaitVSync() waits for the next
///             AChoreographer frame on that thread and returns the baton there
///             with FlutterEngineOnVsync. Without the NDK Choreographer it
///             asks the Java one, which answers on the platform thread.
///
///             Batons go back only while an engine handle is attached. A
///             spawned engine can ask before its holder attaches the handle;
///             such a request waits for later frames. Detach() returns the
///             batons that are still outstanding, as embedder.h requires before
///             shutdown, and turns later frames into no-ops.
///
class VsyncWaiterAndroid final
    : public std::enable_shared_from_this<VsyncWaiterAndroid> {
 public:
  static bool Register(JNIEnv* env);

  explicit VsyncWaiterAndroid(const flutter::TaskRunners& task_runners);

  ~VsyncWaiterAndroid();

  //----------------------------------------------------------------------------
  /// @brief      Starts returning batons to |engine| through
  ///             |embedder_api|->OnVsync, which is read at every call. Both
  ///             must stay valid until Detach().
  ///
  void Attach(FLUTTER_API_SYMBOL(FlutterEngine) engine,
              const FlutterEngineProcTable* embedder_api);

  //----------------------------------------------------------------------------
  /// @brief      Returns the outstanding batons with the current time and
  ///             stops using the engine. Call it on the platform thread before
  ///             the engine is destroyed. A baton the engine passes after this
  ///             cannot be returned and leaks, as a pending vsync did when the
  ///             UI thread exited before this class used the embedder API.
  ///
  void Detach();

  //----------------------------------------------------------------------------
  /// @brief      The embedder API vsync callback. Returns |baton| at the next
  ///             frame.
  ///
  void AwaitVSync(intptr_t baton);

 private:
  enum class State { kWaitingForEngine, kAttached, kDetached };

  const flutter::TaskRunners task_runners_;
  std::mutex mutex_;
  State state_ = State::kWaitingForEngine;
  FLUTTER_API_SYMBOL(FlutterEngine) engine_ = nullptr;
  const FlutterEngineProcTable* embedder_api_ = nullptr;
  // Batons from AwaitVSync() that have not been returned yet.
  std::unordered_set<intptr_t> outstanding_batons_;

  void RequestFrame(intptr_t baton);

  void OnFrame(intptr_t baton,
               fml::TimePoint frame_start_time,
               fml::TimePoint frame_target_time);

  // Needs |mutex_| held and |state_| == State::kAttached. Holding the lock
  // across the call lets Detach() wait for a call on the UI thread to return.
  void ReturnBatonLocked(intptr_t baton,
                         fml::TimePoint frame_start_time,
                         fml::TimePoint frame_target_time);

  static void OnVsyncFromNDK(int64_t frame_nanos,
                             const std::weak_ptr<VsyncWaiterAndroid>& weak_this,
                             intptr_t baton);

  static void OnVsyncFromJava(JNIEnv* env,
                              jclass jcaller,
                              jlong frameDelayNanos,
                              jlong refreshPeriodNanos,
                              jlong java_baton);

  static void OnUpdateRefreshRate(JNIEnv* env,
                                  jclass jcaller,
                                  jfloat refresh_rate);

  FML_DISALLOW_COPY_AND_ASSIGN(VsyncWaiterAndroid);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_VSYNC_WAITER_ANDROID_H_
