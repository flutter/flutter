// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_external_texture_gl.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/core/SkYUVAIndex.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrDirectContext.h"
#include "third_party/skia/src/gpu/gl/GrGLDefines.h"

namespace flutter {

IOSExternalTextureGL::IOSExternalTextureGL(int64_t textureId,
                                           NSObject<FlutterTexture>* externalTexture)
    : Texture(textureId),
      external_texture_(fml::scoped_nsobject<NSObject<FlutterTexture>>([externalTexture retain])) {
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
  GrGLTextureInfo yTextureInfo = {CVOpenGLESTextureGetTarget(y_texture_ref_),
                                  CVOpenGLESTextureGetName(y_texture_ref_), GR_GL_LUMINANCE8};
  GrBackendTexture yBackendTexture(bounds.width(), bounds.height(), GrMipMapped::kNo, yTextureInfo);
  GrGLTextureInfo uvTextureInfo = {CVOpenGLESTextureGetTarget(uv_texture_ref_),
                                   CVOpenGLESTextureGetName(uv_texture_ref_), GR_GL_RGBA8};
  GrBackendTexture uvBackendTexture(bounds.width(), bounds.height(), GrMipMapped::kNo,
                                    uvTextureInfo);
  GrBackendTexture nv12TextureHandles[] = {yBackendTexture, uvBackendTexture};
  SkYUVAIndex yuvaIndices[4] = {
      SkYUVAIndex{0, SkColorChannel::kR},  // Read Y data from the red channel of the first texture
      SkYUVAIndex{1, SkColorChannel::kR},  // Read U data from the red channel of the second texture
      SkYUVAIndex{
          1, SkColorChannel::kA},  // Read V data from the alpha channel of the second texture,
                                   // normal NV12 data V should be taken from the green channel, but
                                   // currently only the uv texture created by GL_LUMINANCE_ALPHA
                                   // can be used, so the V value is taken from the alpha channel
      SkYUVAIndex{-1, SkColorChannel::kA}};  //-1 means to omit the alpha data of YUVA
  SkISize size{yBackendTexture.width(), yBackendTexture.height()};
  sk_sp<SkImage> image = SkImage::MakeFromYUVATextures(
      context, kRec601_SkYUVColorSpace, nv12TextureHandles, yuvaIndices, size,
      kTopLeft_GrSurfaceOrigin, /*imageColorSpace=*/nullptr);
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
                                 SkFilterQuality filter_quality) {
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
    SkPaint paint;
    paint.setFilterQuality(filter_quality);
    canvas.drawImage(image, bounds.x(), bounds.y(), &paint);
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
