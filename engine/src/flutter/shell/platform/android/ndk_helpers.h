// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_NDK_HELPERS_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_NDK_HELPERS_H_

#include "flutter/fml/native_library.h"
#include "flutter/fml/platform/android/jni_util.h"

#include "flutter/impeller/toolkit/egl/egl.h"

#include <android/hardware_buffer.h>

namespace flutter {

// A collection of NDK functions that are available depending on the version of
// the Android SDK we are linked with at runtime.
class NDKHelpers {
 public:
  // API Version 26
  static bool HardwareBufferSupported();
  static AHardwareBuffer* AHardwareBuffer_fromHardwareBuffer(
      JNIEnv* env,
      jobject hardwareBufferObj);
  static void AHardwareBuffer_acquire(AHardwareBuffer* buffer);
  static void AHardwareBuffer_release(AHardwareBuffer* buffer);
  static void AHardwareBuffer_describe(AHardwareBuffer* buffer,
                                       AHardwareBuffer_Desc* desc);
  static EGLClientBuffer eglGetNativeClientBufferANDROID(
      AHardwareBuffer* buffer);

 private:
  static void Init();
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_NDK_HELPERS_H_
