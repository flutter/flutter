// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_ANDROID_NDK_HELPERS_H_
#define FLUTTER_FML_PLATFORM_ANDROID_NDK_HELPERS_H_

#include <EGL/egl.h>
#include <android/choreographer.h>
#include <android/hardware_buffer.h>
#include <android/surface_control.h>
#include <android/trace.h>
#include <jni.h>
#include <optional>

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
  static AChoreographer* _Nullable AChoreographer_getInstance();
  // Deprecated in 29, available since 24.
  static void AChoreographer_postFrameCallback(
      AChoreographer* _Nonnull choreographer,
      AChoreographer_frameCallback _Nonnull callback,
      void* _Nullable data);

  // API Version 26
  static bool HardwareBufferSupported();
  static AHardwareBuffer* _Nonnull AHardwareBuffer_fromHardwareBuffer(
      JNIEnv* _Nonnull env,
      jobject _Nonnull hardwareBufferObj);
  static void AHardwareBuffer_release(AHardwareBuffer* _Nonnull buffer);
  static void AHardwareBuffer_describe(AHardwareBuffer* _Nonnull buffer,
                                       AHardwareBuffer_Desc* _Nullable desc);
  static int AHardwareBuffer_allocate(
      const AHardwareBuffer_Desc* _Nonnull desc,
      AHardwareBuffer* _Nullable* _Nullable outBuffer);
  static EGLClientBuffer _Nonnull eglGetNativeClientBufferANDROID(
      AHardwareBuffer* _Nonnull buffer);

  // API Version 29
  static int AHardwareBuffer_isSupported(
      const AHardwareBuffer_Desc* _Nonnull desc);

  static void AChoreographer_postFrameCallback64(
      AChoreographer* _Nonnull choreographer,
      AChoreographer_frameCallback64 _Nonnull callback,
      void* _Nullable data);

  static bool SurfaceControlAndTransactionSupported();

  static ASurfaceControl* _Nonnull ASurfaceControl_createFromWindow(
      ANativeWindow* _Nonnull parent,
      const char* _Nullable debug_name);
  static void ASurfaceControl_release(
      ASurfaceControl* _Nonnull surface_control);

  static ASurfaceTransaction* _Nonnull ASurfaceTransaction_create();
  static void ASurfaceTransaction_delete(
      ASurfaceTransaction* _Nonnull surface_transaction);
  static void ASurfaceTransaction_apply(
      ASurfaceTransaction* _Nonnull surface_transaction);
  static void ASurfaceTransaction_setBuffer(
      ASurfaceTransaction* _Nonnull transaction,
      ASurfaceControl* _Nonnull surface_control,
      AHardwareBuffer* _Nonnull buffer,
      int acquire_fence_fd);

  // API Version 31

  // Returns std::nullopt on API version 26 - 30.
  static std::optional<HardwareBufferKey> AHardwareBuffer_getId(
      AHardwareBuffer* _Nonnull buffer);
};

}  // namespace flutter

#endif  // FLUTTER_FML_PLATFORM_ANDROID_NDK_HELPERS_H_
