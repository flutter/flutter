// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_MESSAGE_RESPONSE_ANDROID_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_MESSAGE_RESPONSE_ANDROID_H_

#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/window/platform_message_response.h"
#include "lib/fxl/macros.h"

namespace shell {

class PlatformMessageResponseAndroid : public blink::PlatformMessageResponse {
 public:
  // |blink::PlatformMessageResponse|
  void Complete(std::vector<uint8_t> data) override;

  // |blink::PlatformMessageResponse|
  void CompleteEmpty() override;

 private:
  PlatformMessageResponseAndroid(
      int response_id,
      fml::jni::JavaObjectWeakGlobalRef weak_java_object,
      fxl::RefPtr<fxl::TaskRunner> platform_task_runner);

  int response_id_;
  fml::jni::JavaObjectWeakGlobalRef weak_java_object_;
  fxl::RefPtr<fxl::TaskRunner> platform_task_runner_;

  FRIEND_MAKE_REF_COUNTED(PlatformMessageResponseAndroid);
  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformMessageResponseAndroid);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_PLATFORM_MESSAGE_RESPONSE_ANDROID_H_
