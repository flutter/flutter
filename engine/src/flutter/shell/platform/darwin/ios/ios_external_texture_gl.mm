// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_external_texture_gl.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"
#include "third_party/skia/include/core/SkColorSpace.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkYUVAInfo.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/include/gpu/GrYUVABackendTextures.h"

namespace flutter {

IOSExternalTextureGL::IOSExternalTextureGL(int64_t textureId,
                                           NSObject<FlutterTexture>* externalTexture,
                                           fml::scoped_nsobject<EAGLContext> context)
    : Texture(textureId),
      external_texture_(fml::scoped_nsobject<NSObject<FlutterTexture>>([externalTexture retain])),
      context_(context) {
  FML_DCHECK(external_texture_);
}

IOSExternalTextureGL::~IOSExternalTextureGL() = default;

void IOSExternalTextureGL::EnsureTextureCacheExists() {
  if (!cache_ref_) {
    CVOpenGLESTextureCacheRef cache;
    CVReturn err =
        CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context_.get(), NULL, &cache);
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
  if (pixel_format_ == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
      pixel_format_ == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
    CreateYUVTexturesFromPixelBuffer();
  } else {
    CreateRGBATextureFromPixelBuffer();
  }
}

void IOSExternalTextureGL::CreateRGBATextureFromPixelBuffer() {
  CVOpenGLESTextureRef texture;
  CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault, cache_ref_, buffer_ref_, /*textureAttributes=*/nullptr, GL_TEXTURE_2D,
      GL_RGBA, static_cast<int>(CVPixelBufferGetWidth(buffer_ref_)),
      static_cast<int>(CVPixelBufferGetHeight(buffer_ref_)), GL_BGRA, GL_UNSIGNED_BYTE, 0,
      &texture);
  if (err != noErr) {
    FML_LOG(WARNING) << "Could not create texture from pixel buffer: " << err;
  } else {
    texture_ref_.Reset(texture);
  }
}

void IOSExternalTextureGL::CreateYUVTexturesFromPixelBuffer() {
  size_t width = CVPixelBufferGetWidth(buffer_ref_);
  size_t height = CVPixelBufferGetHeight(buffer_ref_);
  {
    CVOpenGLESTextureRef yTexture;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
        kCFAllocatorDefault, cache_ref_, buffer_ref_, /*textureAttributes=*/nullptr, GL_TEXTURE_2D,
        GL_LUMINANCE, width, height, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &yTexture);
    if (err != noErr) {
      FML_DCHECK(yTexture) << "Could not create texture from pixel buffer: " << err;
    } else {
      y_texture_ref_.Reset(yTexture);
    }
  }

  {
    CVOpenGLESTextureRef uvTexture;
    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
        kCFAllocatorDefault, cache_ref_, buffer_ref_, /*textureAttributes=*/nullptr, GL_TEXTURE_2D,
        GL_LUMINANCE_ALPHA, width / 2, height / 2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1,
        &uvTexture);
    if (err != noErr) {
      FML_DCHECK(uvTexture) << "Could not create texture from pixel buffer: " << err;
    } else {
      uv_texture_ref_.Reset(uvTexture);
    }
  }
}

sk_sp<SkImage> IOSExternalTextureGL::CreateImageFromRGBATexture(GrDirectContext* context,
                                                                const SkRect& bounds) {
  GrGLTextureInfo textureInfo = {CVOpenGLESTextureGetTarget(texture_ref_),
                                 CVOpenGLESTextureGetName(texture_ref_), GL_RGBA8_OES};
  GrBackendTexture backendTexture(bounds.width(), bounds.height(), GrMipMapped::kNo, textureInfo);
  sk_sp<SkImage> image = SkImage::MakeFromTexture(context, backendTexture, kTopLeft_GrSurfaceOrigin,
                                                  kRGBA_8888_SkColorType, kPremul_SkAlphaType,
                                                  /*imageColorSpace=*/nullptr);
  return image;
}

sk_sp<SkImage> IOSExternalTextureGL::CreateImageFromYUVTextures(GrDirectContext* context,
                                                                const SkRect& bounds) {
  GrBackendTexture textures[2];
  GrGLTextureInfo yTextureInfo = {CVOpenGLESTextureGetTarget(y_texture_ref_),
                                  CVOpenGLESTextureGetName(y_texture_ref_), GL_LUMINANCE8_EXT};
  textures[0] = GrBackendTexture(bounds.width(), bounds.height(), GrMipMapped::kNo, yTextureInfo);
  GrGLTextureInfo uvTextureInfo = {CVOpenGLESTextureGetTarget(uv_texture_ref_),
                                   CVOpenGLESTextureGetName(uv_texture_ref_),
                                   GL_LUMINANCE8_ALPHA8_EXT};
  textures[1] = GrBackendTexture(bounds.width(), bounds.height(), GrMipMapped::kNo, uvTextureInfo);

  SkYUVAInfo yuvaInfo(textures[0].dimensions(), SkYUVAInfo::PlaneConfig::kY_UV,
                      SkYUVAInfo::Subsampling::k444, kRec601_SkYUVColorSpace);
  GrYUVABackendTextures yuvaBackendTextures(yuvaInfo, textures, kTopLeft_GrSurfaceOrigin);
  sk_sp<SkImage> image = SkImage::MakeFromYUVATextures(context, yuvaBackendTextures,
                                                       /*imageColorSpace=*/nullptr);
  return image;
}

bool IOSExternalTextureGL::IsTexturesAvailable() const {
  return ((pixel_format_ == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
           pixel_format_ == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) &&
          (y_texture_ref_ && uv_texture_ref_)) ||
         (pixel_format_ == kCVPixelFormatType_32BGRA && texture_ref_);
}

bool IOSExternalTextureGL::NeedUpdateTexture(bool freeze) {
  // Update texture if `texture_ref_` is reset to `nullptr` when GrContext
  // is destroyed or new frame is ready.
  return (!freeze && new_frame_ready_) || !IsTexturesAvailable();
}

void IOSExternalTextureGL::Paint(SkCanvas& canvas,
                                 const SkRect& bounds,
                                 bool freeze,
                                 GrDirectContext* context,
                                 const SkSamplingOptions& sampling,
                                 const SkPaint* paint) {
  EnsureTextureCacheExists();
  if (NeedUpdateTexture(freeze)) {
    auto pixelBuffer = [external_texture_.get() copyPixelBuffer];
    if (pixelBuffer) {
      buffer_ref_.Reset(pixelBuffer);
      pixel_format_ = CVPixelBufferGetPixelFormatType(buffer_ref_);
    }
    CreateTextureFromPixelBuffer();
    new_frame_ready_ = false;
  }
  if (!IsTexturesAvailable()) {
    return;
  }

  sk_sp<SkImage> image = nullptr;
  if (pixel_format_ == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange ||
      pixel_format_ == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
    image = CreateImageFromYUVTextures(context, bounds);
  } else {
    image = CreateImageFromRGBATexture(context, bounds);
  }

  FML_DCHECK(image) << "Failed to create SkImage from Texture.";
  if (image) {
    canvas.drawImage(image, bounds.x(), bounds.y(), sampling, paint);
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

void IOSExternalTextureGL::OnTextureUnregistered() {
  if ([external_texture_ respondsToSelector:@selector(onTextureUnregistered:)]) {
    [external_texture_ onTextureUnregistered:external_texture_];
  }
}

}  // namespace flutter
