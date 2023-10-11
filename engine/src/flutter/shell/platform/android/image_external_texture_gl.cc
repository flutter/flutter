// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/image_external_texture_gl.h"

#include <android/hardware_buffer_jni.h>
#include <android/sensor.h>

#include "flutter/common/graphics/texture.h"
#include "flutter/display_list/effects/dl_color_source.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/impeller/core/formats.h"
#include "flutter/impeller/display_list/dl_image_impeller.h"
#include "flutter/impeller/renderer/backend/gles/texture_gles.h"
#include "flutter/impeller/toolkit/egl/image.h"
#include "flutter/impeller/toolkit/gles/texture.h"
#include "flutter/shell/platform/android/ndk_helpers.h"
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

ImageExternalTextureGL::ImageExternalTextureGL(
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : ImageExternalTexture(id, image_texture_entry, jni_facade) {}

void ImageExternalTextureGL::Attach(PaintContext& context) {
  if (state_ == AttachmentState::kUninitialized) {
    if (!android_image_.is_null()) {
      JavaLocalRef hardware_buffer = HardwareBufferFor(android_image_);
      AHardwareBuffer* hardware_buffer_ahw =
          AHardwareBufferFor(hardware_buffer);
      egl_image_ = CreateEGLImage(hardware_buffer_ahw);
      CloseHardwareBuffer(hardware_buffer);
    }
    state_ = AttachmentState::kAttached;
  }
}

void ImageExternalTextureGL::Detach() {
  egl_image_.reset();
}

bool ImageExternalTextureGL::MaybeSwapImages() {
  JavaLocalRef image = AcquireLatestImage();
  if (image.is_null()) {
    return false;
  }
  // NOTE: In the following code it is important that old_android_image is
  // not closed until after the update of egl_image_ otherwise the image might
  // be closed before the old EGLImage referencing it has been deleted. After
  // an image is closed the underlying HardwareBuffer may be recycled and used
  // for a future frame.
  JavaLocalRef old_android_image(android_image_);
  android_image_.Reset(image);
  JavaLocalRef hardware_buffer = HardwareBufferFor(image);
  egl_image_ = CreateEGLImage(AHardwareBufferFor(hardware_buffer));
  CloseHardwareBuffer(hardware_buffer);
  // IMPORTANT: We only close the old image after egl_image_ stops referencing
  // it.
  CloseImage(old_android_image);
  return true;
}

impeller::UniqueEGLImageKHR ImageExternalTextureGL::CreateEGLImage(
    AHardwareBuffer* hardware_buffer) {
  if (hardware_buffer == nullptr) {
    return impeller::UniqueEGLImageKHR();
  }

  EGLDisplay display = eglGetCurrentDisplay();
  FML_CHECK(display != EGL_NO_DISPLAY);

  EGLClientBuffer client_buffer =
      NDKHelpers::eglGetNativeClientBufferANDROID(hardware_buffer);
  FML_DCHECK(client_buffer != nullptr);
  if (client_buffer == nullptr) {
    FML_LOG(ERROR) << "eglGetNativeClientBufferAndroid returned null.";
    return impeller::UniqueEGLImageKHR();
  }

  impeller::EGLImageKHRWithDisplay maybe_image =
      impeller::EGLImageKHRWithDisplay{
          eglCreateImageKHR(display, EGL_NO_CONTEXT, EGL_NATIVE_BUFFER_ANDROID,
                            client_buffer, 0),
          display};

  return impeller::UniqueEGLImageKHR(maybe_image);
}

ImageExternalTextureGLSkia::ImageExternalTextureGLSkia(
    const std::shared_ptr<AndroidContextGLSkia>& context,
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : ImageExternalTextureGL(id, image_texture_entry, jni_facade) {}

void ImageExternalTextureGLSkia::Attach(PaintContext& context) {
  if (state_ == AttachmentState::kUninitialized) {
    // After this call state_ will be AttachmentState::kAttached and egl_image_
    // will have been created if we still have an Image associated with us.
    ImageExternalTextureGL::Attach(context);
    GLuint texture_name;
    glGenTextures(1, &texture_name);
    texture_.reset(impeller::GLTexture{texture_name});
  }
}

void ImageExternalTextureGLSkia::Detach() {
  ImageExternalTextureGL::Detach();
  texture_.reset();
}

void ImageExternalTextureGLSkia::ProcessFrame(PaintContext& context,
                                              const SkRect& bounds) {
  const bool swapped = MaybeSwapImages();
  if (!swapped && !egl_image_.is_valid()) {
    // Nothing to do.
    return;
  }
  BindImageToTexture(egl_image_, texture_.get().texture_name);
  dl_image_ = CreateDlImage(context, bounds);
}

void ImageExternalTextureGLSkia::BindImageToTexture(
    const impeller::UniqueEGLImageKHR& image,
    GLuint tex) {
  if (!image.is_valid() || tex == 0) {
    return;
  }
  glBindTexture(GL_TEXTURE_EXTERNAL_OES, tex);
  glEGLImageTargetTexture2DOES(GL_TEXTURE_EXTERNAL_OES,
                               (GLeglImageOES)image.get().image);
}

sk_sp<flutter::DlImage> ImageExternalTextureGLSkia::CreateDlImage(
    PaintContext& context,
    const SkRect& bounds) {
  GrGLTextureInfo textureInfo = {GL_TEXTURE_EXTERNAL_OES,
                                 texture_.get().texture_name, GL_RGBA8_OES};
  auto backendTexture =
      GrBackendTextures::MakeGL(1, 1, skgpu::Mipmapped::kNo, textureInfo);
  return DlImage::Make(SkImages::BorrowTextureFrom(
      context.gr_context, backendTexture, kTopLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr));
}

ImageExternalTextureGLImpeller::ImageExternalTextureGLImpeller(
    const std::shared_ptr<impeller::ContextGLES>& context,
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_textury_entry,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : ImageExternalTextureGL(id, image_textury_entry, jni_facade),
      impeller_context_(context) {}

void ImageExternalTextureGLImpeller::Detach() {}

void ImageExternalTextureGLImpeller::Attach(PaintContext& context) {
  if (state_ == AttachmentState::kUninitialized) {
    ImageExternalTextureGL::Attach(context);
  }
}

void ImageExternalTextureGLImpeller::ProcessFrame(PaintContext& context,
                                                  const SkRect& bounds) {
  const bool swapped = MaybeSwapImages();
  if (!swapped && !egl_image_.is_valid()) {
    // Nothing to do.
    return;
  }
  dl_image_ = CreateDlImage(context, bounds);
}

sk_sp<flutter::DlImage> ImageExternalTextureGLImpeller::CreateDlImage(
    PaintContext& context,
    const SkRect& bounds) {
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
    return nullptr;
  }
  // Associate the hardware buffer image with the texture.
  glEGLImageTargetTexture2DOES(GL_TEXTURE_EXTERNAL_OES,
                               (GLeglImageOES)egl_image_.get().image);
  return impeller::DlImageImpeller::Make(texture);
}

}  // namespace flutter
