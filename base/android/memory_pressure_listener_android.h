// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_ANDROID_MEMORY_PRESSURE_LISTENER_ANDROID_H_
#define BASE_ANDROID_MEMORY_PRESSURE_LISTENER_ANDROID_H_

#include "base/android/jni_android.h"

namespace base {
namespace android {

// Implements the C++ counter part of MemoryPressureListener.java
class BASE_EXPORT MemoryPressureListenerAndroid {
 public:
  static bool Register(JNIEnv* env);

  static void RegisterSystemCallback(JNIEnv* env);

  // Called by JNI.
  static void OnMemoryPressure(int memory_pressure_type);

 private:
  DISALLOW_COPY_AND_ASSIGN(MemoryPressureListenerAndroid);
};

}  // namespace android
}  // namespace base

#endif  // BASE_ANDROID_MEMORY_PRESSURE_LISTENER_ANDROID_H_
