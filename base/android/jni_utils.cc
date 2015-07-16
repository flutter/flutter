// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/jni_utils.h"

#include "base/android/jni_android.h"
#include "base/android/scoped_java_ref.h"

#include "jni/JNIUtils_jni.h"

namespace base {
namespace android {

ScopedJavaLocalRef<jobject> GetClassLoader(JNIEnv* env) {
  return Java_JNIUtils_getClassLoader(env);
}

bool RegisterJNIUtils(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace android
}  // namespace base

