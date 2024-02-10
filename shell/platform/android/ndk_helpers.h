// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_NDK_HELPERS_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_NDK_HELPERS_H_

#include "flutter/fml/native_library.h"
#include "flutter/fml/platform/android/jni_util.h"

#include "flutter/impeller/toolkit/egl/egl.h"

#include <android/choreographer.h>
#include <android/hardware_buffer.h>
#include <android/surface_control.h>
#include <android/trace.h>

namespace flutter {

using HardwareBufferKey = uint64_t;

enum class ChoreographerSupportStatus {
  // Unavailable, API level < 24.
  kUnsupported,
  // Available, but only with postFrameCallback.
  kSupported32,
  // Available, but only with postFrameCallback64.
  kSupported64,
};

// A collection of NDK functions that are available depending on the version of
// the Android SDK we are linked with at runtime.
class NDKHelpers {
 public:
  // Safe to call multiple times.
  // Normally called from JNI_OnLoad.
  static void Init();

  // API Version 23
  static bool ATrace_isEnabled();

  // API Version 24
  static ChoreographerSupportStatus ChoreographerSupported();
  static AChoreographer* AChoreographer_getInstance();
  // Deprecated in 29, available since 24.
  static void AChoreographer_postFrameCallback(
      AChoreographer* choreographer,
      AChoreographer_frameCallback callback,
      void* data);

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

  // API Version 29
  static void AChoreographer_postFrameCallback64(
      AChoreographer* choreographer,
      AChoreographer_frameCallback64 callback,
      void* data);

  // API Version 31

  // Returns std::nullopt on API version 26 - 30.
  static std::optional<HardwareBufferKey> AHardwareBuffer_getId(
      AHardwareBuffer* buffer);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_NDK_HELPERS_H_
