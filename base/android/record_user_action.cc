// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/record_user_action.h"

#include "base/android/jni_string.h"
#include "base/metrics/user_metrics.h"
#include "jni/RecordUserAction_jni.h"

namespace base {
namespace android {

static void RecordUserAction(JNIEnv* env, jclass clazz, jstring j_action) {
  RecordComputedAction(ConvertJavaStringToUTF8(env, j_action));
}

// Register native methods
bool RegisterRecordUserAction(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace base
