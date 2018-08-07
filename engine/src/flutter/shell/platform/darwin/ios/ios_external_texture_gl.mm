// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_external_texture_gl.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"
#include "third_party/skia/include/core/SkSurface.h"
#include "third_party/skia/include/gpu/GrBackendSurface.h"
#include "third_party/skia/include/gpu/GrTexture.h"
#include "third_party/skia/include/gpu/GrTypes.h"

namespace shell {

IOSExternalTextureGL::IOSExternalTextureGL(int64_t textureId,
                                           NSObject<FlutterTexture>* externalTexture)
    : Texture(textureId), external_texture_(externalTexture) {
  FML_DCHECK(external_texture_);
}

IOSExternalTextureGL::~IOSExternalTextureGL() = default;

void IOSExternalTextureGL::Paint(SkCanvas& canvas, const SkRect& bounds, bool freeze) {
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
  fml::CFRef<CVPixelBufferRef> bufferRef;
  if (!freeze) {
    bufferRef.Reset([external_texture_ copyPixelBuffer]);
    if (bufferRef != nullptr) {
      CVOpenGLESTextureRef texture;
      CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(
          kCFAllocatorDefault, cache_ref_, bufferRef, nullptr, GL_TEXTURE_2D, GL_RGBA,
          static_cast<int>(CVPixelBufferGetWidth(bufferRef)),
          static_cast<int>(CVPixelBufferGetHeight(bufferRef)), GL_BGRA, GL_UNSIGNED_BYTE, 0,
          &texture);
      texture_ref_.Reset(texture);
      if (err != noErr) {
        FML_LOG(WARNING) << "Could not create texture from pixel buffer: " << err;
        return;
      }
    }
  }
  if (!texture_ref_) {
    return;
  }
  GrGLTextureInfo textureInfo = {CVOpenGLESTextureGetTarget(texture_ref_),
                                 CVOpenGLESTextureGetName(texture_ref_), GL_RGBA8_OES};
  GrBackendTexture backendTexture(bounds.width(), bounds.height(), GrMipMapped::kNo, textureInfo);
  sk_sp<SkImage> image =
      SkImage::MakeFromTexture(canvas.getGrContext(), backendTexture, kTopLeft_GrSurfaceOrigin,
                               kRGBA_8888_SkColorType, kPremul_SkAlphaType, nullptr);
  if (image) {
    canvas.drawImage(image, bounds.x(), bounds.y());
  }
}

void IOSExternalTextureGL::OnGrContextCreated() {}

void IOSExternalTextureGL::OnGrContextDestroyed() {
  texture_ref_.Reset(nullptr);
  cache_ref_.Reset(nullptr);
}

void IOSExternalTextureGL::MarkNewFrameAvailable() {}

}  // namespace shell
