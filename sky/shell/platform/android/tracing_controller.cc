// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/android/tracing_controller.h"

#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/files/file_path.h"
#include "base/macros.h"
#include "jni/TracingController_jni.h"
#include "sky/shell/shell.h"
#include "sky/shell/tracing_controller.h"

namespace sky {
namespace shell {

static void StartTracing(JNIEnv* env, jclass clazz) {
  Shell::Shared().tracing_controller().StartTracing();
}

static void StopTracing(JNIEnv* env, jclass clazz) {
  Shell::Shared().tracing_controller().StopTracing();
}

bool RegisterTracingController(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace shell
}  // namespace sky
