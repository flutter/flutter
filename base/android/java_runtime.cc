// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/java_runtime.h"

#include "jni/Runtime_jni.h"

namespace base {
namespace android {

bool JavaRuntime::Register(JNIEnv* env) {
  return JNI_Runtime::RegisterNativesImpl(env);
}

void JavaRuntime::GetMemoryUsage(long* total_memory, long* free_memory) {
  JNIEnv* env = base::android::AttachCurrentThread();
  base::android::ScopedJavaLocalRef<jobject> runtime =
      JNI_Runtime::Java_Runtime_getRuntime(env);
  *total_memory = JNI_Runtime::Java_Runtime_totalMemory(env, runtime.obj());
  *free_memory = JNI_Runtime::Java_Runtime_freeMemory(env, runtime.obj());
}

}  // namespace android
}  // namespace base
