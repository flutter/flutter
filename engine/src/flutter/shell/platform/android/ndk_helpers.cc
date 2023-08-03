// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/ndk_helpers.h"

#include "fml/native_library.h"
#include "shell/platform/android/ndk_helpers.h"

#include "flutter/fml/logging.h"

#include <dlfcn.h>

namespace flutter {

namespace {

typedef AHardwareBuffer* (*fp_AHardwareBuffer_fromHardwareBuffer)(
    JNIEnv* env,
    jobject hardwareBufferObj);
typedef void (*fp_AHardwareBuffer_acquire)(AHardwareBuffer* buffer);
typedef void (*fp_AHardwareBuffer_release)(AHardwareBuffer* buffer);
typedef EGLClientBuffer (*fp_eglGetNativeClientBufferANDROID)(
    AHardwareBuffer* buffer);

AHardwareBuffer* (*_AHardwareBuffer_fromHardwareBuffer)(
    JNIEnv* env,
    jobject hardwareBufferObj) = nullptr;
void (*_AHardwareBuffer_acquire)(AHardwareBuffer* buffer) = nullptr;
void (*_AHardwareBuffer_release)(AHardwareBuffer* buffer) = nullptr;
EGLClientBuffer (*_eglGetNativeClientBufferANDROID)(AHardwareBuffer* buffer) =
    nullptr;

std::once_flag init_once;

void InitOnceCallback() {
  static fml::RefPtr<fml::NativeLibrary> android =
      fml::NativeLibrary::Create("libandroid.so");
  FML_CHECK(android.get() != nullptr);
  static fml::RefPtr<fml::NativeLibrary> egl =
      fml::NativeLibrary::Create("libEGL.so");
  FML_CHECK(egl.get() != nullptr);
  _eglGetNativeClientBufferANDROID =
      egl->ResolveFunction<fp_eglGetNativeClientBufferANDROID>(
             "eglGetNativeClientBufferANDROID")
          .value_or(nullptr);
  _AHardwareBuffer_fromHardwareBuffer =
      android
          ->ResolveFunction<fp_AHardwareBuffer_fromHardwareBuffer>(
              "AHardwareBuffer_fromHardwareBuffer")
          .value_or(nullptr);
  _AHardwareBuffer_acquire = android
                                 ->ResolveFunction<fp_AHardwareBuffer_acquire>(
                                     "AHardwareBuffer_acquire")
                                 .value_or(nullptr);
  _AHardwareBuffer_release = android
                                 ->ResolveFunction<fp_AHardwareBuffer_release>(
                                     "AHardwareBuffer_release")
                                 .value_or(nullptr);
}

}  // namespace

void NDKHelpers::Init() {
  std::call_once(init_once, InitOnceCallback);
}

bool NDKHelpers::HardwareBufferSupported() {
  NDKHelpers::Init();
  const bool r = _AHardwareBuffer_fromHardwareBuffer != nullptr;
  return r;
}

AHardwareBuffer* NDKHelpers::AHardwareBuffer_fromHardwareBuffer(
    JNIEnv* env,
    jobject hardwareBufferObj) {
  NDKHelpers::Init();
  FML_CHECK(_AHardwareBuffer_fromHardwareBuffer != nullptr);
  return _AHardwareBuffer_fromHardwareBuffer(env, hardwareBufferObj);
}

void NDKHelpers::AHardwareBuffer_acquire(AHardwareBuffer* buffer) {
  NDKHelpers::Init();
  FML_CHECK(_AHardwareBuffer_acquire != nullptr);
  _AHardwareBuffer_acquire(buffer);
}

void NDKHelpers::AHardwareBuffer_release(AHardwareBuffer* buffer) {
  NDKHelpers::Init();
  FML_CHECK(_AHardwareBuffer_release != nullptr);
  _AHardwareBuffer_release(buffer);
}

EGLClientBuffer NDKHelpers::eglGetNativeClientBufferANDROID(
    AHardwareBuffer* buffer) {
  NDKHelpers::Init();
  FML_CHECK(_eglGetNativeClientBufferANDROID != nullptr);
  return _eglGetNativeClientBufferANDROID(buffer);
}

}  // namespace flutter
