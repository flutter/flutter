// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/field_trial_list.h"

#include <jni.h>

#include "base/android/jni_string.h"
#include "base/metrics/field_trial.h"
#include "jni/FieldTrialList_jni.h"

using base::android::ConvertJavaStringToUTF8;
using base::android::ConvertUTF8ToJavaString;

static jstring FindFullName(JNIEnv* env,
                            jclass clazz,
                            jstring jtrial_name) {
  std::string trial_name(ConvertJavaStringToUTF8(env, jtrial_name));
  return ConvertUTF8ToJavaString(
      env,
      base::FieldTrialList::FindFullName(trial_name)).Release();
}

static jboolean TrialExists(JNIEnv* env, jclass clazz, jstring jtrial_name) {
  std::string trial_name(ConvertJavaStringToUTF8(env, jtrial_name));
  return base::FieldTrialList::TrialExists(trial_name);
}

namespace base {
namespace android {

bool RegisterFieldTrialList(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace base
