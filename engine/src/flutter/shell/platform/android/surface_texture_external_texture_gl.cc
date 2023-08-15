// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/surface_texture_external_texture_gl.h"

#include <utility>

#include "flutter/display_list/effects/dl_color_source.h"
#include "impeller/display_list/dl_image_impeller.h"
#include "shell/platform/android/surface_texture_external_texture.h"
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

SurfaceTextureExternalTextureGL::SurfaceTextureExternalTextureGL(
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : SurfaceTextureExternalTexture(id, surface_texture, jni_facade) {}

SurfaceTextureExternalTextureGL::~SurfaceTextureExternalTextureGL() {
  if (texture_name_ != 0) {
    glDeleteTextures(1, &texture_name_);
  }
}

void SurfaceTextureExternalTextureGL::ProcessFrame(PaintContext& context,
                                                   const SkRect& bounds) {
  if (state_ == AttachmentState::kUninitialized) {
    // Generate the texture handle.
    glGenTextures(1, &texture_name_);
    Attach(texture_name_);
  }
  FML_CHECK(state_ == AttachmentState::kAttached);

  // Updates the texture contents and transformation matrix.
  Update();

  // Create a
  GrGLTextureInfo textureInfo = {GL_TEXTURE_EXTERNAL_OES, texture_name_,
                                 GL_RGBA8_OES};
  auto backendTexture =
      GrBackendTextures::MakeGL(1, 1, skgpu::Mipmapped::kNo, textureInfo);
  dl_image_ = DlImage::Make(SkImages::BorrowTextureFrom(
      context.gr_context, backendTexture, kTopLeft_GrSurfaceOrigin,
      kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr));
}

void SurfaceTextureExternalTextureGL::Detach() {
  SurfaceTextureExternalTexture::Detach();
  if (texture_name_ != 0) {
    glDeleteTextures(1, &texture_name_);
    texture_name_ = 0;
  }
}

SurfaceTextureExternalTextureImpellerGL::
    SurfaceTextureExternalTextureImpellerGL(
        const std::shared_ptr<impeller::ContextGLES>& context,
        int64_t id,
        const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture,
        const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : SurfaceTextureExternalTexture(id, surface_texture, jni_facade),
      impeller_context_(context) {}

SurfaceTextureExternalTextureImpellerGL::
    ~SurfaceTextureExternalTextureImpellerGL() {}

void SurfaceTextureExternalTextureImpellerGL::ProcessFrame(
    PaintContext& context,
    const SkRect& bounds) {
  if (state_ == AttachmentState::kUninitialized) {
    // Generate the texture handle.
    impeller::TextureDescriptor desc;
    desc.type = impeller::TextureType::kTextureExternalOES;
    desc.storage_mode = impeller::StorageMode::kDevicePrivate;
    desc.format = impeller::PixelFormat::kR8G8B8A8UNormInt;
    desc.size = {static_cast<int>(bounds.width()),
                 static_cast<int>(bounds.height())};
    desc.mip_count = 1;
    texture_ = std::make_shared<impeller::TextureGLES>(
        impeller_context_->GetReactor(), desc,
        impeller::TextureGLES::IsWrapped::kWrapped);
    texture_->SetCoordinateSystem(
        impeller::TextureCoordinateSystem::kUploadFromHost);
    auto maybe_handle = texture_->GetGLHandle();
    if (!maybe_handle.has_value()) {
      FML_LOG(ERROR) << "Could not get GL handle from impeller::TextureGLES!";
      return;
    }
    Attach(maybe_handle.value());
  }
  FML_CHECK(state_ == AttachmentState::kAttached);

  // Updates the texture contents and transformation matrix.
  Update();

  dl_image_ = impeller::DlImageImpeller::Make(texture_);
}

void SurfaceTextureExternalTextureImpellerGL::Detach() {
  SurfaceTextureExternalTexture::Detach();
  texture_.reset();
}

}  // namespace flutter
