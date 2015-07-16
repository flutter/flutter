// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MESSAGE_LOOP_MESSAGE_PUMP_ANDROID_H_
#define BASE_MESSAGE_LOOP_MESSAGE_PUMP_ANDROID_H_

#include <jni.h>

#include "base/android/scoped_java_ref.h"
#include "base/base_export.h"
#include "base/compiler_specific.h"
#include "base/message_loop/message_pump.h"

namespace base {

class RunLoop;
class TimeTicks;

// This class implements a MessagePump needed for TYPE_UI MessageLoops on
// OS_ANDROID platform.
class BASE_EXPORT MessagePumpForUI : public MessagePump {
 public:
  MessagePumpForUI();
  ~MessagePumpForUI() override;

  void Run(Delegate* delegate) override;
  void Quit() override;
  void ScheduleWork() override;
  void ScheduleDelayedWork(const TimeTicks& delayed_work_time) override;

  virtual void Start(Delegate* delegate);

  static bool RegisterBindings(JNIEnv* env);

 private:
  RunLoop* run_loop_;
  base::android::ScopedJavaGlobalRef<jobject> system_message_handler_obj_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpForUI);
};

}  // namespace base

#endif  // BASE_MESSAGE_LOOP_MESSAGE_PUMP_ANDROID_H_
