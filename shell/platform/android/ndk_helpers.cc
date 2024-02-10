// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/ndk_helpers.h"

#include "fml/native_library.h"

#include "flutter/fml/logging.h"

#include <android/hardware_buffer.h>
#include <dlfcn.h>

namespace flutter {

namespace {

typedef AHardwareBuffer* (*fp_AHardwareBuffer_fromHardwareBuffer)(
    JNIEnv* env,
    jobject hardwareBufferObj);
typedef void (*fp_AHardwareBuffer_acquire)(AHardwareBuffer* buffer);
typedef void (*fp_AHardwareBuffer_release)(AHardwareBuffer* buffer);
typedef void (*fp_AHardwareBuffer_describe)(AHardwareBuffer* buffer,
                                            AHardwareBuffer_Desc* desc);
typedef void (*fp_AHardwareBuffer_getId)(AHardwareBuffer* buffer,
                                         uint64_t* outId);

typedef bool (*fp_ATrace_isEnabled)(void);

typedef AChoreographer* (*fp_AChoreographer_getInstance)(void);
typedef void (*fp_AChoreographer_postFrameCallback)(
    AChoreographer* choreographer,
    AChoreographer_frameCallback callbackk,
    void* data);
typedef void (*fp_AChoreographer_postFrameCallback64)(
    AChoreographer* choreographer,
    AChoreographer_frameCallback64 callbackk,
    void* data);

typedef EGLClientBuffer (*fp_eglGetNativeClientBufferANDROID)(
    AHardwareBuffer* buffer);

AHardwareBuffer* (*_AHardwareBuffer_fromHardwareBuffer)(
    JNIEnv* env,
    jobject hardwareBufferObj) = nullptr;
void (*_AHardwareBuffer_acquire)(AHardwareBuffer* buffer) = nullptr;
void (*_AHardwareBuffer_release)(AHardwareBuffer* buffer) = nullptr;
void (*_AHardwareBuffer_describe)(AHardwareBuffer* buffer,
                                  AHardwareBuffer_Desc* desc) = nullptr;
void (*_AHardwareBuffer_getId)(AHardwareBuffer* buffer,
                               uint64_t* outId) = nullptr;
bool (*_ATrace_isEnabled)() = nullptr;
AChoreographer* (*_AChoreographer_getInstance)() = nullptr;
void (*_AChoreographer_postFrameCallback)(
    AChoreographer* choreographer,
    AChoreographer_frameCallback callbackk,
    void* data) = nullptr;
void (*_AChoreographer_postFrameCallback64)(
    AChoreographer* choreographer,
    AChoreographer_frameCallback64 callbackk,
    void* data) = nullptr;

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
  _AHardwareBuffer_getId =
      android
          ->ResolveFunction<fp_AHardwareBuffer_getId>("AHardwareBuffer_getId")
          .value_or(nullptr);
  _AHardwareBuffer_describe =
      android
          ->ResolveFunction<fp_AHardwareBuffer_describe>(
              "AHardwareBuffer_describe")
          .value_or(nullptr);

  _ATrace_isEnabled =
      android->ResolveFunction<fp_ATrace_isEnabled>("ATrace_isEnabled")
          .value_or(nullptr);

  _AChoreographer_getInstance =
      android
          ->ResolveFunction<fp_AChoreographer_getInstance>(
              "AChoreographer_getInstance")
          .value_or(nullptr);
  if (_AChoreographer_getInstance) {
    _AChoreographer_postFrameCallback64 =
        android
            ->ResolveFunction<fp_AChoreographer_postFrameCallback64>(
                "AChoreographer_postFrameCallback64")
            .value_or(nullptr);
#if FML_ARCH_CPU_64_BITS
    if (!_AChoreographer_postFrameCallback64) {
      _AChoreographer_postFrameCallback =
          android
              ->ResolveFunction<fp_AChoreographer_postFrameCallback>(
                  "AChoreographer_postFrameCallback")
              .value_or(nullptr);
    }
#endif
  }
}

}  // namespace

void NDKHelpers::Init() {
  std::call_once(init_once, InitOnceCallback);
}

bool NDKHelpers::ATrace_isEnabled() {
  if (_ATrace_isEnabled) {
    return _ATrace_isEnabled();
  }
  return false;
}

ChoreographerSupportStatus NDKHelpers::ChoreographerSupported() {
  if (_AChoreographer_postFrameCallback64) {
    return ChoreographerSupportStatus::kSupported64;
  }
  if (_AChoreographer_postFrameCallback) {
    return ChoreographerSupportStatus::kSupported32;
  }
  return ChoreographerSupportStatus::kUnsupported;
}

AChoreographer* NDKHelpers::AChoreographer_getInstance() {
  FML_CHECK(_AChoreographer_getInstance);
  return _AChoreographer_getInstance();
}

void NDKHelpers::AChoreographer_postFrameCallback(
    AChoreographer* choreographer,
    AChoreographer_frameCallback callback,
    void* data) {
  FML_CHECK(_AChoreographer_postFrameCallback);
  return _AChoreographer_postFrameCallback(choreographer, callback, data);
}

void NDKHelpers::AChoreographer_postFrameCallback64(
    AChoreographer* choreographer,
    AChoreographer_frameCallback64 callback,
    void* data) {
  FML_CHECK(_AChoreographer_postFrameCallback64);
  return _AChoreographer_postFrameCallback64(choreographer, callback, data);
}

bool NDKHelpers::HardwareBufferSupported() {
  const bool r = _AHardwareBuffer_fromHardwareBuffer != nullptr;
  return r;
}

AHardwareBuffer* NDKHelpers::AHardwareBuffer_fromHardwareBuffer(
    JNIEnv* env,
    jobject hardwareBufferObj) {
  FML_CHECK(_AHardwareBuffer_fromHardwareBuffer != nullptr);
  return _AHardwareBuffer_fromHardwareBuffer(env, hardwareBufferObj);
}

void NDKHelpers::AHardwareBuffer_acquire(AHardwareBuffer* buffer) {
  FML_CHECK(_AHardwareBuffer_acquire != nullptr);
  _AHardwareBuffer_acquire(buffer);
}

void NDKHelpers::AHardwareBuffer_release(AHardwareBuffer* buffer) {
  FML_CHECK(_AHardwareBuffer_release != nullptr);
  _AHardwareBuffer_release(buffer);
}

void NDKHelpers::AHardwareBuffer_describe(AHardwareBuffer* buffer,
                                          AHardwareBuffer_Desc* desc) {
  FML_CHECK(_AHardwareBuffer_describe != nullptr);
  _AHardwareBuffer_describe(buffer, desc);
}

std::optional<HardwareBufferKey> NDKHelpers::AHardwareBuffer_getId(
    AHardwareBuffer* buffer) {
  if (_AHardwareBuffer_getId == nullptr) {
    return std::nullopt;
  }
  HardwareBufferKey outId;
  _AHardwareBuffer_getId(buffer, &outId);
  return outId;
}

EGLClientBuffer NDKHelpers::eglGetNativeClientBufferANDROID(
    AHardwareBuffer* buffer) {
  FML_CHECK(_eglGetNativeClientBufferANDROID != nullptr);
  return _eglGetNativeClientBufferANDROID(buffer);
}

}  // namespace flutter
