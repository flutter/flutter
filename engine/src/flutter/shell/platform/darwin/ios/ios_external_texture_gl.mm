// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_external_texture_gl.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"

namespace flutter {

IOSExternalTextureGL::IOSExternalTextureGL(int64_t textureId,
                                           NSObject<FlutterTexture>* externalTexture)
    : Texture(textureId), external_texture_(externalTexture) {
  FML_DCHECK(external_texture_);
}

IOSExternalTextureGL::~IOSExternalTextureGL() = default;

void IOSExternalTextureGL::EnsureTextureCacheExists() {
  if (!cache_ref_) {
    CVOpenGLESTextureCacheRef cache;
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL,
                                                [EAGLContext currentContext], NULL, &cache);
    if (err == noErr) {
      cache_ref_.Reset(cache);
    } else {
      FML_LOG(WARNING) << "Failed to create GLES texture cache: " << err;
      return;
    }
  }
}

void IOSExternalTextureGL::CreateTextureFromPixelBuffer() {
  if (buffer_ref_ == nullptr) {
    return;
  }
  CVOpenGLESTextureRef texture;
  CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault, cache_ref_, buffer_ref_, nullptr, GL_TEXTURE_2D, GL_RGBA,
      static_cast<int>(CVPixelBufferGetWidth(buffer_ref_)),
      static_cast<int>(CVPixelBufferGetHeight(buffer_ref_)), GL_BGRA, GL_UNSIGNED_BYTE, 0,
      &texture);
  if (err != noErr) {
    FML_LOG(WARNING) << "Could not create texture from pixel buffer: " << err;
  } else {
    texture_ref_.Reset(texture);
  }
}

bool IOSExternalTextureGL::NeedUpdateTexture(bool freeze) {
  // Update texture if `texture_ref_` is reset to `nullptr` when GrContext
  // is destroied or new frame is ready.
  return (!freeze && new_frame_ready_) || !texture_ref_;
}

void IOSExternalTextureGL::Paint(SkCanvas& canvas,
                                 const SkRect& bounds,
                                 bool freeze,
                                 GrContext* context) {
  EnsureTextureCacheExists();
  if (NeedUpdateTexture(freeze)) {
    auto pixelBuffer = [external_texture_ copyPixelBuffer];
    if (pixelBuffer) {
      buffer_ref_.Reset(pixelBuffer);
    }
    CreateTextureFromPixelBuffer();
    new_frame_ready_ = false;
  }
  if (!texture_ref_) {
    return;
  }
  GrGLTextureInfo textureInfo = {CVOpenGLESTextureGetTarget(texture_ref_),
                                 CVOpenGLESTextureGetName(texture_ref_), GL_RGBA8_OES};
  GrBackendTexture backendTexture(bounds.width(), bounds.height(), GrMipMapped::kNo, textureInfo);
  sk_sp<SkImage> image =
      SkImage::MakeFromTexture(context, backendTexture, kTopLeft_GrSurfaceOrigin,
                               kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr);
  FML_DCHECK(image) << "Failed to create SkImage from Texture.";
  if (image) {
    canvas.drawImage(image, bounds.x(), bounds.y());
  }
}

void IOSExternalTextureGL::OnGrContextCreated() {
  // Re-create texture from pixel buffer that was saved before
  // OnGrContextDestroyed gets called.
  // https://github.com/flutter/flutter/issues/30491
  EnsureTextureCacheExists();
  CreateTextureFromPixelBuffer();
}

void IOSExternalTextureGL::OnGrContextDestroyed() {
  texture_ref_.Reset(nullptr);
  cache_ref_.Reset(nullptr);
}

void IOSExternalTextureGL::MarkNewFrameAvailable() {
  new_frame_ready_ = true;
}

}  // namespace flutter
