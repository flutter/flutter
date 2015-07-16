// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/android/surface_texture.h"

#include <android/native_window_jni.h>

// TODO(boliu): Remove this include when we move off ICS.
#include "base/android/build_info.h"
#include "base/android/jni_android.h"
#include "base/logging.h"
#include "jni/SurfaceTexturePlatformWrapper_jni.h"
#include "ui/gl/android/scoped_java_surface.h"
#include "ui/gl/android/surface_texture_listener.h"
#include "ui/gl/gl_bindings.h"

// TODO(boliu): Remove this method when Chromium stops supporting ICS.
bool GlContextMethodsAvailable() {
  bool available = base::android::BuildInfo::GetInstance()->sdk_int() >= 16;
  if (!available)
    LOG(WARNING) << "Running on unsupported device: rendering may not work";
  return available;
}

namespace gfx {

scoped_refptr<SurfaceTexture> SurfaceTexture::Create(int texture_id) {
  JNIEnv* env = base::android::AttachCurrentThread();
  return new SurfaceTexture(
      Java_SurfaceTexturePlatformWrapper_create(env, texture_id));
}

scoped_refptr<SurfaceTexture> SurfaceTexture::CreateSingleBuffered(
    int texture_id) {
  DCHECK(IsSingleBufferModeSupported());
  JNIEnv* env = base::android::AttachCurrentThread();
  return new SurfaceTexture(
      Java_SurfaceTexturePlatformWrapper_createSingleBuffered(env, texture_id));
}

SurfaceTexture::SurfaceTexture(
    const base::android::ScopedJavaLocalRef<jobject>& j_surface_texture) {
  j_surface_texture_.Reset(j_surface_texture);
}

SurfaceTexture::~SurfaceTexture() {
  JNIEnv* env = base::android::AttachCurrentThread();
  Java_SurfaceTexturePlatformWrapper_destroy(env, j_surface_texture_.obj());
}

void SurfaceTexture::SetFrameAvailableCallback(
    const base::Closure& callback) {
  JNIEnv* env = base::android::AttachCurrentThread();
  Java_SurfaceTexturePlatformWrapper_setFrameAvailableCallback(
      env,
      j_surface_texture_.obj(),
      reinterpret_cast<intptr_t>(new SurfaceTextureListener(callback)));
}

void SurfaceTexture::UpdateTexImage() {
  JNIEnv* env = base::android::AttachCurrentThread();
  Java_SurfaceTexturePlatformWrapper_updateTexImage(env,
                                                    j_surface_texture_.obj());
}

void SurfaceTexture::ReleaseTexImage() {
  DCHECK(IsSingleBufferModeSupported());
  JNIEnv* env = base::android::AttachCurrentThread();
  Java_SurfaceTexturePlatformWrapper_releaseTexImage(env,
                                                     j_surface_texture_.obj());
}

void SurfaceTexture::GetTransformMatrix(float mtx[16]) {
  JNIEnv* env = base::android::AttachCurrentThread();

  base::android::ScopedJavaLocalRef<jfloatArray> jmatrix(
      env, env->NewFloatArray(16));
  Java_SurfaceTexturePlatformWrapper_getTransformMatrix(
      env, j_surface_texture_.obj(), jmatrix.obj());

  jboolean is_copy;
  jfloat* elements = env->GetFloatArrayElements(jmatrix.obj(), &is_copy);
  for (int i = 0; i < 16; ++i) {
    mtx[i] = static_cast<float>(elements[i]);
  }
  env->ReleaseFloatArrayElements(jmatrix.obj(), elements, JNI_ABORT);
}

void SurfaceTexture::AttachToGLContext() {
  if (GlContextMethodsAvailable()) {
    int texture_id;
    glGetIntegerv(GL_TEXTURE_BINDING_EXTERNAL_OES, &texture_id);
    DCHECK(texture_id);
    JNIEnv* env = base::android::AttachCurrentThread();
    Java_SurfaceTexturePlatformWrapper_attachToGLContext(
        env, j_surface_texture_.obj(), texture_id);
  }
}

void SurfaceTexture::DetachFromGLContext() {
  if (GlContextMethodsAvailable()) {
    JNIEnv* env = base::android::AttachCurrentThread();
    Java_SurfaceTexturePlatformWrapper_detachFromGLContext(
        env, j_surface_texture_.obj());
  }
}

ANativeWindow* SurfaceTexture::CreateSurface() {
  JNIEnv* env = base::android::AttachCurrentThread();
  ScopedJavaSurface surface(this);
  // Note: This ensures that any local references used by
  // ANativeWindow_fromSurface are released immediately. This is needed as a
  // workaround for https://code.google.com/p/android/issues/detail?id=68174
  base::android::ScopedJavaLocalFrame scoped_local_reference_frame(env);
  ANativeWindow* native_window = ANativeWindow_fromSurface(
      env, surface.j_surface().obj());
  return native_window;
}

// static
bool SurfaceTexture::IsSingleBufferModeSupported() {
  return base::android::BuildInfo::GetInstance()->sdk_int() >= 19;
}

bool SurfaceTexture::RegisterSurfaceTexture(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

}  // namespace gfx
