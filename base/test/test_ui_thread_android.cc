// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "base/test/test_ui_thread_android.h"

#include "jni/TestUiThread_jni.h"

namespace base {

void StartTestUiThreadLooper() {
  Java_TestUiThread_loop(base::android::AttachCurrentThread());
}

bool RegisterTestUiThreadAndroid(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace base
