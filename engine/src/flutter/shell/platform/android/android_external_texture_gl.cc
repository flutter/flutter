// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_external_texture_gl.h"

// #include <GLES/gl.h>
#include <GLES/glext.h>
#include "flutter/common/threads.h"
#include "flutter/shell/platform/android/platform_view_android_jni.h"
#include "third_party/skia/include/gpu/GrTexture.h"

namespace shell {

AndroidExternalTextureGL::AndroidExternalTextureGL(
    int64_t id,
    const fml::jni::JavaObjectWeakGlobalRef& surfaceTexture)
    : Texture(id), surface_texture_(surfaceTexture) {}

AndroidExternalTextureGL::~AndroidExternalTextureGL() = default;

void AndroidExternalTextureGL::OnGrContextCreated() {
  ASSERT_IS_GPU_THREAD;
  state_ = AttachmentState::uninitialized;
}

void AndroidExternalTextureGL::MarkNewFrameAvailable() {
  ASSERT_IS_GPU_THREAD;
  new_frame_ready_ = true;
}

void AndroidExternalTextureGL::Paint(SkCanvas& canvas, const SkRect& bounds) {
  ASSERT_IS_GPU_THREAD;
  if (state_ == AttachmentState::detached) {
    return;
  }
  if (state_ == AttachmentState::uninitialized) {
    glGenTextures(1, &texture_name_);
    Attach(static_cast<jint>(texture_name_));
    state_ = AttachmentState::attached;
  }
  if (new_frame_ready_) {
    Update();
    new_frame_ready_ = false;
  }
  GrGLTextureInfo textureInfo = {GL_TEXTURE_EXTERNAL_OES, texture_name_};
  GrBackendTexture backendTexture(bounds.width(), bounds.height(),
                                  kRGBA_8888_GrPixelConfig, textureInfo);
  sk_sp<SkImage> image = SkImage::MakeFromTexture(
      canvas.getGrContext(), backendTexture, kTopLeft_GrSurfaceOrigin,
      SkAlphaType::kPremul_SkAlphaType, nullptr);
  if (image) {
    canvas.drawImage(image, bounds.x(), bounds.y());
  }
}

void AndroidExternalTextureGL::OnGrContextDestroyed() {
  ASSERT_IS_GPU_THREAD;
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
