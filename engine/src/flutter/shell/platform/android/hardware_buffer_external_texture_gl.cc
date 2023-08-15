// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/hardware_buffer_external_texture_gl.h"

#include <android/hardware_buffer_jni.h>
#include <android/sensor.h>
#include "flutter/common/graphics/texture.h"
#include "flutter/shell/platform/android/ndk_helpers.h"
#include "impeller/core/formats.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "impeller/renderer/backend/gles/texture_gles.h"
#include "impeller/toolkit/egl/image.h"
#include "impeller/toolkit/gles/texture.h"

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

void HardwareBufferExternalTextureGL::Detach() {
  image_.reset();
  texture_.reset();
}

void HardwareBufferExternalTextureGL::ProcessFrame(PaintContext& context,
                                                   const SkRect& bounds) {
  if (state_ == AttachmentState::kUninitialized) {
    GLuint texture_name;
    glGenTextures(1, &texture_name);
    texture_.reset(impeller::GLTexture{texture_name});
    state_ = AttachmentState::kAttached;
  }
  glBindTexture(GL_TEXTURE_EXTERNAL_OES, texture_.get().texture_name);

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
    NDKHelpers::AHardwareBuffer_release(latest_hardware_buffer);
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

  GrGLTextureInfo textureInfo = {GL_TEXTURE_EXTERNAL_OES,
                                 texture_.get().texture_name, GL_RGBA8_OES};
  auto backendTexture =
      GrBackendTextures::MakeGL(1, 1, skgpu::Mipmapped::kNo, textureInfo);
  dl_image_ = DlImage::Make(SkImages::BorrowTextureFrom(
      context.gr_context, backendTexture, kTopLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr));
}

HardwareBufferExternalTextureGL::HardwareBufferExternalTextureGL(
    const std::shared_ptr<AndroidContextGLSkia>& context,
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : HardwareBufferExternalTexture(id, image_texture_entry, jni_facade) {}

HardwareBufferExternalTextureGL::~HardwareBufferExternalTextureGL() {}

HardwareBufferExternalTextureImpellerGL::
    HardwareBufferExternalTextureImpellerGL(
        const std::shared_ptr<impeller::ContextGLES>& context,
        int64_t id,
        const fml::jni::ScopedJavaGlobalRef<jobject>&
            hardware_buffer_texture_entry,
        const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : HardwareBufferExternalTexture(id,
                                    hardware_buffer_texture_entry,
                                    jni_facade),
      impeller_context_(context) {}

HardwareBufferExternalTextureImpellerGL::
    ~HardwareBufferExternalTextureImpellerGL() {}

void HardwareBufferExternalTextureImpellerGL::Detach() {
  egl_image_.reset();
}

void HardwareBufferExternalTextureImpellerGL::ProcessFrame(
    PaintContext& context,
    const SkRect& bounds) {
  EGLDisplay display = eglGetCurrentDisplay();
  FML_CHECK(display != EGL_NO_DISPLAY);

  if (state_ == AttachmentState::kUninitialized) {
    // First processed frame we are attached.
    state_ = AttachmentState::kAttached;
  }

  AHardwareBuffer* latest_hardware_buffer = GetLatestHardwareBuffer();
  if (latest_hardware_buffer == nullptr) {
    FML_LOG(ERROR) << "GetLatestHardwareBuffer returned null.";
    return;
  }

  EGLClientBuffer client_buffer =
      NDKHelpers::eglGetNativeClientBufferANDROID(latest_hardware_buffer);
  if (client_buffer == nullptr) {
    FML_LOG(ERROR) << "eglGetNativeClientBufferAndroid returned null.";
    NDKHelpers::AHardwareBuffer_release(latest_hardware_buffer);
    return;
  }

  FML_CHECK(client_buffer != nullptr);
  egl_image_.reset(impeller::EGLImageKHRWithDisplay{
      eglCreateImageKHR(display, EGL_NO_CONTEXT, EGL_NATIVE_BUFFER_ANDROID,
                        client_buffer, 0),
      display});
  FML_CHECK(egl_image_.get().image != EGL_NO_IMAGE_KHR);

  // Create the texture.
  impeller::TextureDescriptor desc;
  desc.type = impeller::TextureType::kTextureExternalOES;
  desc.storage_mode = impeller::StorageMode::kDevicePrivate;
  desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
  desc.size = {static_cast<int>(bounds.width()),
               static_cast<int>(bounds.height())};
  desc.mip_count = 1;
  auto texture = std::make_shared<impeller::TextureGLES>(
      impeller_context_->GetReactor(), desc,
      impeller::TextureGLES::IsWrapped::kWrapped);
  texture->SetCoordinateSystem(
      impeller::TextureCoordinateSystem::kUploadFromHost);
  if (!texture->Bind()) {
    FML_LOG(ERROR) << "Could not bind texture.";
    NDKHelpers::AHardwareBuffer_release(latest_hardware_buffer);
    return;
  }
  // Associate the hardware buffer image with the texture.
  glEGLImageTargetTexture2DOES(GL_TEXTURE_EXTERNAL_OES,
                               (GLeglImageOES)egl_image_.get().image);

  dl_image_ = impeller::DlImageImpeller::Make(texture);

  // Release the reference acquired by GetLatestHardwareBuffer.
  NDKHelpers::AHardwareBuffer_release(latest_hardware_buffer);
}

}  // namespace flutter
