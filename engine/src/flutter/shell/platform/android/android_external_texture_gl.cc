// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_external_texture_gl.h"

#include <GLES/glext.h>

#include "flutter/shell/platform/android/platform_view_android_jni.h"
#include "third_party/skia/include/gpu/GrTexture.h"

namespace shell {

AndroidExternalTextureGL::AndroidExternalTextureGL(
    int64_t id,
    const fml::jni::JavaObjectWeakGlobalRef& surfaceTexture)
    : Texture(id), surface_texture_(surfaceTexture), transform(SkMatrix::I()) {}

AndroidExternalTextureGL::~AndroidExternalTextureGL() = default;

void AndroidExternalTextureGL::OnGrContextCreated() {
  state_ = AttachmentState::uninitialized;
}

void AndroidExternalTextureGL::MarkNewFrameAvailable() {
  new_frame_ready_ = true;
}

void AndroidExternalTextureGL::Paint(SkCanvas& canvas,
                                     const SkRect& bounds,
                                     bool freeze) {
  if (state_ == AttachmentState::detached) {
    return;
  }
  if (state_ == AttachmentState::uninitialized) {
    glGenTextures(1, &texture_name_);
    Attach(static_cast<jint>(texture_name_));
    state_ = AttachmentState::attached;
  }
  if (!freeze && new_frame_ready_) {
    Update();
    new_frame_ready_ = false;
  }
  GrGLTextureInfo textureInfo = {GL_TEXTURE_EXTERNAL_OES, texture_name_,
                                 GL_RGBA8_OES};
  GrBackendTexture backendTexture(1, 1, GrMipMapped::kNo, textureInfo);
  sk_sp<SkImage> image = SkImage::MakeFromTexture(
      canvas.getGrContext(), backendTexture, kTopLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr);
  if (image) {
    SkAutoCanvasRestore autoRestore(&canvas, true);
    canvas.translate(bounds.x(), bounds.y());
    canvas.scale(bounds.width(), bounds.height());
    if (!transform.isIdentity()) {
      SkMatrix transformAroundCenter(transform);

      transformAroundCenter.preTranslate(-0.5, -0.5);
      transformAroundCenter.postScale(1, -1);
      transformAroundCenter.postTranslate(0.5, 0.5);
      canvas.concat(transformAroundCenter);
    }
    canvas.drawImage(image, 0, 0);
  }
}

void AndroidExternalTextureGL::UpdateTransform() {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  fml::jni::ScopedJavaLocalRef<jobject> surfaceTexture =
      surface_texture_.get(env);
  fml::jni::ScopedJavaLocalRef<jfloatArray> transformMatrix(
      env, env->NewFloatArray(16));
  SurfaceTextureGetTransformMatrix(env, surfaceTexture.obj(),
                                   transformMatrix.obj());
  float* m = env->GetFloatArrayElements(transformMatrix.obj(), nullptr);
  SkScalar matrix3[] = {
      m[0], m[1], m[2],   //
      m[4], m[5], m[6],   //
      m[8], m[9], m[10],  //
  };
  env->ReleaseFloatArrayElements(transformMatrix.obj(), m, JNI_ABORT);
  transform.set9(matrix3);
}

void AndroidExternalTextureGL::OnGrContextDestroyed() {
  if (state_ == AttachmentState::attached) {
    Detach();
  }
  state_ = AttachmentState::detached;
}

void AndroidExternalTextureGL::Attach(jint textureName) {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  fml::jni::ScopedJavaLocalRef<jobject> surfaceTexture =
      surface_texture_.get(env);
  if (!surfaceTexture.is_null()) {
    SurfaceTextureAttachToGLContext(env, surfaceTexture.obj(), textureName);
  }
}

void AndroidExternalTextureGL::Update() {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  fml::jni::ScopedJavaLocalRef<jobject> surfaceTexture =
      surface_texture_.get(env);
  if (!surfaceTexture.is_null()) {
    SurfaceTextureUpdateTexImage(env, surfaceTexture.obj());
    UpdateTransform();
  }
}

void AndroidExternalTextureGL::Detach() {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  fml::jni::ScopedJavaLocalRef<jobject> surfaceTexture =
      surface_texture_.get(env);
  if (!surfaceTexture.is_null()) {
    SurfaceTextureDetachFromGLContext(env, surfaceTexture.obj());
  }
}

}  // namespace shell
