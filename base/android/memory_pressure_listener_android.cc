// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/memory_pressure_listener_android.h"

#include "base/memory/memory_pressure_listener.h"
#include "jni/MemoryPressureListener_jni.h"

// Defined and called by JNI.
static void OnMemoryPressure(
    JNIEnv* env, jclass clazz, jint memory_pressure_level) {
  base::MemoryPressureListener::NotifyMemoryPressure(
      static_cast<base::MemoryPressureListener::MemoryPressureLevel>(
          memory_pressure_level));
}

namespace base {
namespace android {

bool MemoryPressureListenerAndroid::Register(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

void MemoryPressureListenerAndroid::RegisterSystemCallback(JNIEnv* env) {
  Java_MemoryPressureListener_registerSystemCallback(
      env, GetApplicationContext());
}

}  // namespace android
}  // namespace base
