// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fml/platform/android/ndk_helpers.h"

#include "fml/logging.h"
#include "fml/native_library.h"

#include <android/hardware_buffer.h>
#include <dlfcn.h>

namespace flutter {

namespace {

#define DECLARE_TYPES(ret, name, args) \
  typedef ret(*fp_##name) args;        \
  ret(*_##name) args = nullptr

DECLARE_TYPES(int,
              AHardwareBuffer_allocate,
              (const AHardwareBuffer_Desc* desc, AHardwareBuffer** outBuffer));
DECLARE_TYPES(int,
              AHardwareBuffer_isSupported,
              (const AHardwareBuffer_Desc* desc));
DECLARE_TYPES(AHardwareBuffer*,
              AHardwareBuffer_fromHardwareBuffer,
              (JNIEnv * env, jobject hardwareBufferObj));
DECLARE_TYPES(void, AHardwareBuffer_release, (AHardwareBuffer * buffer));
DECLARE_TYPES(void,
              AHardwareBuffer_describe,
              (AHardwareBuffer * buffer, AHardwareBuffer_Desc* desc));
DECLARE_TYPES(int,
              AHardwareBuffer_getId,
              (AHardwareBuffer * buffer, uint64_t* outId));

DECLARE_TYPES(bool, ATrace_isEnabled, (void));

DECLARE_TYPES(ASurfaceControl*,
              ASurfaceControl_createFromWindow,
              (ANativeWindow * parent, const char* debug_name));
DECLARE_TYPES(void,
              ASurfaceControl_release,
              (ASurfaceControl * surface_control));
DECLARE_TYPES(ASurfaceTransaction*, ASurfaceTransaction_create, (void));
DECLARE_TYPES(void,
              ASurfaceTransaction_delete,
              (ASurfaceTransaction * surface_transaction));
DECLARE_TYPES(void,
              ASurfaceTransaction_apply,
              (ASurfaceTransaction * surface_transaction));
DECLARE_TYPES(void,
              ASurfaceTransaction_setBuffer,
              (ASurfaceTransaction * transaction,
               ASurfaceControl* surface_control,
               AHardwareBuffer* buffer,
               int acquire_fence_fd));

DECLARE_TYPES(AChoreographer*, AChoreographer_getInstance, (void));
DECLARE_TYPES(void,
              AChoreographer_postFrameCallback,
              (AChoreographer * choreographer,
               AChoreographer_frameCallback callbackk,
               void* data));
DECLARE_TYPES(void,
              AChoreographer_postFrameCallback64,
              (AChoreographer * choreographer,
               AChoreographer_frameCallback64 callbackk,
               void* data));

DECLARE_TYPES(EGLClientBuffer,
              eglGetNativeClientBufferANDROID,
              (AHardwareBuffer * buffer));

#undef DECLARE_TYPES

std::once_flag init_once;

void InitOnceCallback() {
  static fml::RefPtr<fml::NativeLibrary> android =
      fml::NativeLibrary::Create("libandroid.so");
  FML_CHECK(android.get() != nullptr);
  static fml::RefPtr<fml::NativeLibrary> egl =
      fml::NativeLibrary::Create("libEGL.so");
  FML_CHECK(egl.get() != nullptr);

#define LOOKUP(lib, func) \
  _##func = lib->ResolveFunction<fp_##func>(#func).value_or(nullptr)

  LOOKUP(egl, eglGetNativeClientBufferANDROID);

  LOOKUP(android, AHardwareBuffer_fromHardwareBuffer);
  LOOKUP(android, AHardwareBuffer_release);
  LOOKUP(android, AHardwareBuffer_getId);
  LOOKUP(android, AHardwareBuffer_describe);
  LOOKUP(android, AHardwareBuffer_allocate);
  LOOKUP(android, AHardwareBuffer_isSupported);
  LOOKUP(android, ATrace_isEnabled);
  LOOKUP(android, AChoreographer_getInstance);
  if (_AChoreographer_getInstance) {
    LOOKUP(android, AChoreographer_postFrameCallback64);
// See discussion at
// https://github.com/flutter/engine/pull/31859#discussion_r822072987
// This method is not suitable for Flutter's use cases on 32 bit architectures,
// and we should fall back to the Java based Choreographer.
#if FML_ARCH_CPU_64_BITS
    if (!_AChoreographer_postFrameCallback64) {
      LOOKUP(android, AChoreographer_postFrameCallback);
    }
#endif
  }

  LOOKUP(android, ASurfaceControl_createFromWindow);
  LOOKUP(android, ASurfaceControl_release);
  LOOKUP(android, ASurfaceTransaction_apply);
  LOOKUP(android, ASurfaceTransaction_create);
  LOOKUP(android, ASurfaceTransaction_delete);
  LOOKUP(android, ASurfaceTransaction_setBuffer);
#undef LOOKUP
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
  int result = _AHardwareBuffer_getId(buffer, &outId);
  if (result == 0) {
    return outId;
  }
  return std::nullopt;
}

EGLClientBuffer NDKHelpers::eglGetNativeClientBufferANDROID(
    AHardwareBuffer* buffer) {
  FML_CHECK(_eglGetNativeClientBufferANDROID != nullptr);
  return _eglGetNativeClientBufferANDROID(buffer);
}

bool NDKHelpers::SurfaceControlAndTransactionSupported() {
  return _ASurfaceControl_createFromWindow && _ASurfaceControl_release &&
         _ASurfaceTransaction_create && _ASurfaceTransaction_apply &&
         _ASurfaceTransaction_delete && _ASurfaceTransaction_setBuffer;
}

ASurfaceControl* NDKHelpers::ASurfaceControl_createFromWindow(
    ANativeWindow* parent,
    const char* debug_name) {
  FML_CHECK(_ASurfaceControl_createFromWindow);
  return _ASurfaceControl_createFromWindow(parent, debug_name);
}

void NDKHelpers::ASurfaceControl_release(ASurfaceControl* surface_control) {
  FML_CHECK(_ASurfaceControl_release);
  return _ASurfaceControl_release(surface_control);
}

ASurfaceTransaction* NDKHelpers::ASurfaceTransaction_create() {
  FML_CHECK(_ASurfaceTransaction_create);
  return _ASurfaceTransaction_create();
}

void NDKHelpers::ASurfaceTransaction_delete(
    ASurfaceTransaction* surface_transaction) {
  FML_CHECK(_ASurfaceTransaction_delete);
  _ASurfaceTransaction_delete(surface_transaction);
}

void NDKHelpers::ASurfaceTransaction_apply(
    ASurfaceTransaction* surface_transaction) {
  FML_CHECK(_ASurfaceTransaction_apply);
  _ASurfaceTransaction_apply(surface_transaction);
}

void NDKHelpers::ASurfaceTransaction_setBuffer(ASurfaceTransaction* transaction,
                                               ASurfaceControl* surface_control,
                                               AHardwareBuffer* buffer,
                                               int acquire_fence_fd) {
  FML_CHECK(_ASurfaceTransaction_setBuffer);
  _ASurfaceTransaction_setBuffer(transaction, surface_control, buffer,
                                 acquire_fence_fd);
}

int NDKHelpers::AHardwareBuffer_isSupported(const AHardwareBuffer_Desc* desc) {
  FML_CHECK(_AHardwareBuffer_isSupported);
  return _AHardwareBuffer_isSupported(desc);
}

int NDKHelpers::AHardwareBuffer_allocate(const AHardwareBuffer_Desc* desc,
                                         AHardwareBuffer** outBuffer) {
  FML_CHECK(_AHardwareBuffer_allocate);
  return _AHardwareBuffer_allocate(desc, outBuffer);
}

}  // namespace flutter
