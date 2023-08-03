// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/hardware_buffer_external_texture_gl.h"

#include <android/hardware_buffer_jni.h>
#include <android/sensor.h>
#include "impeller/toolkit/egl/image.h"
#include "impeller/toolkit/gles/texture.h"
#include "shell/platform/android/ndk_helpers.h"

#include "flutter/display_list/effects/dl_color_source.h"
#include "third_party/skia/include/core/SkAlphaType.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkColorType.h"
#include "third_party/skia/include/core/SkImage.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/gl/GrGLTypes.h"

namespace flutter {

HardwareBufferExternalTextureGL::HardwareBufferExternalTextureGL(
    const std::shared_ptr<AndroidContextGLSkia>& context,
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : Texture(id),
      context_(context),
      image_texture_entry_(image_texture_entry),
      jni_facade_(jni_facade) {}

HardwareBufferExternalTextureGL::~HardwareBufferExternalTextureGL() {}

// Implementing flutter::Texture.
void HardwareBufferExternalTextureGL::Paint(PaintContext& context,
                                            const SkRect& bounds,
                                            bool freeze,
                                            const DlImageSampling sampling) {
  if (state_ == AttachmentState::kDetached) {
    return;
  }
  if (state_ == AttachmentState::kUninitialized) {
    GLuint texture_name;
    glGenTextures(1, &texture_name);
    texture_.reset(impeller::GLTexture{texture_name});
    state_ = AttachmentState::kAttached;
  }
  glBindTexture(GL_TEXTURE_EXTERNAL_OES, texture_.get().texture_name);
  if (!freeze && new_frame_ready_) {
    new_frame_ready_ = false;
    Update();
  }
  GrGLTextureInfo textureInfo = {GL_TEXTURE_EXTERNAL_OES,
                                 texture_.get().texture_name, GL_RGBA8_OES};
  auto backendTexture =
      GrBackendTextures::MakeGL(1, 1, skgpu::Mipmapped::kNo, textureInfo);
  sk_sp<SkImage> image = SkImages::BorrowTextureFrom(
      context.gr_context, backendTexture, kTopLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr);
  if (image) {
    DlAutoCanvasRestore autoRestore(context.canvas, true);
    context.canvas->Translate(bounds.x(), bounds.y());
    context.canvas->Scale(bounds.width(), bounds.height());
    auto dl_image = DlImage::Make(image);
    context.canvas->DrawImage(dl_image, {0, 0}, sampling, context.paint);
  } else {
    FML_LOG(ERROR) << "Skia could not borrow texture";
  }
}

// Implementing flutter::Texture.
void HardwareBufferExternalTextureGL::MarkNewFrameAvailable() {
  new_frame_ready_ = true;
}

// Implementing flutter::Texture.
void HardwareBufferExternalTextureGL::OnTextureUnregistered() {}

// Implementing flutter::ContextListener.
void HardwareBufferExternalTextureGL::OnGrContextCreated() {
  state_ = AttachmentState::kUninitialized;
}

AHardwareBuffer* HardwareBufferExternalTextureGL::GetLatestHardwareBuffer() {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  FML_CHECK(env != nullptr);

  // ImageTextureEntry.acquireLatestImage.
  JavaLocalRef image_java = jni_facade_->ImageTextureEntryAcquireLatestImage(
      JavaLocalRef(image_texture_entry_));
  if (image_java.obj() == nullptr) {
    return nullptr;
  }

  // Image.getHardwareBuffer.
  JavaLocalRef hardware_buffer_java =
      jni_facade_->ImageGetHardwareBuffer(image_java);
  if (hardware_buffer_java.obj() == nullptr) {
    jni_facade_->ImageClose(image_java);
    return nullptr;
  }

  // Convert into NDK HardwareBuffer.
  AHardwareBuffer* latest_hardware_buffer =
      NDKHelpers::AHardwareBuffer_fromHardwareBuffer(
          env, hardware_buffer_java.obj());
  if (latest_hardware_buffer == nullptr) {
    return nullptr;
  }

  // Keep hardware buffer alive.
  NDKHelpers::AHardwareBuffer_acquire(latest_hardware_buffer);

  // Now that we have referenced the native hardware buffer, close the Java
  // Image and HardwareBuffer objects.
  jni_facade_->HardwareBufferClose(hardware_buffer_java);
  jni_facade_->ImageClose(image_java);

  return latest_hardware_buffer;
}

void HardwareBufferExternalTextureGL::Update() {
  EGLDisplay display = eglGetCurrentDisplay();
  FML_CHECK(display != EGL_NO_DISPLAY);

  image_.reset();

  AHardwareBuffer* latest_hardware_buffer = GetLatestHardwareBuffer();
  if (latest_hardware_buffer == nullptr) {
    FML_LOG(WARNING) << "GetLatestHardwareBuffer returned null.";
    return;
  }

  EGLClientBuffer client_buffer =
      NDKHelpers::eglGetNativeClientBufferANDROID(latest_hardware_buffer);
  if (client_buffer == nullptr) {
    FML_LOG(WARNING) << "eglGetNativeClientBufferAndroid returned null.";
    return;
  }
  FML_CHECK(client_buffer != nullptr);
  image_.reset(impeller::EGLImageKHRWithDisplay{
      eglCreateImageKHR(display, EGL_NO_CONTEXT, EGL_NATIVE_BUFFER_ANDROID,
                        client_buffer, 0),
      display});
  FML_CHECK(image_.get().image != EGL_NO_IMAGE_KHR);
  glEGLImageTargetTexture2DOES(GL_TEXTURE_EXTERNAL_OES,
                               (GLeglImageOES)image_.get().image);

  // Drop our temporary reference to the hardware buffer as the call to
  // eglCreateImageKHR now has the reference.
  NDKHelpers::AHardwareBuffer_release(latest_hardware_buffer);
}

// Implementing flutter::ContextListener.
void HardwareBufferExternalTextureGL::OnGrContextDestroyed() {
  if (state_ == AttachmentState::kAttached) {
    image_.reset();
    texture_.reset();
  }
  state_ = AttachmentState::kDetached;
}

}  // namespace flutter
