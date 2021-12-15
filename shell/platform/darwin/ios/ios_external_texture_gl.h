// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_IOS_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_IOS_EXTERNAL_TEXTURE_GL_H_

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterTexture.h"

namespace flutter {

class IOSExternalTextureGL final : public Texture {
 public:
  IOSExternalTextureGL(int64_t textureId,
                       NSObject<FlutterTexture>* externalTexture,
                       fml::scoped_nsobject<EAGLContext> context);

  // |Texture|
  ~IOSExternalTextureGL() override;

 private:
  bool new_frame_ready_ = false;
  fml::scoped_nsobject<NSObject<FlutterTexture>> external_texture_;
  fml::CFRef<CVOpenGLESTextureCacheRef> cache_ref_;
  fml::CFRef<CVOpenGLESTextureRef> texture_ref_;
  fml::CFRef<CVPixelBufferRef> buffer_ref_;
  OSType pixel_format_ = 0;
  fml::CFRef<CVOpenGLESTextureRef> y_texture_ref_;
  fml::CFRef<CVOpenGLESTextureRef> uv_texture_ref_;
  fml::scoped_nsobject<EAGLContext> context_;

  // |Texture|
  void Paint(SkCanvas& canvas,
             const SkRect& bounds,
             bool freeze,
             GrDirectContext* context,
             const SkSamplingOptions& sampling,
             const SkPaint* paint) override;

  // |Texture|
  void OnGrContextCreated() override;

  // |Texture|
  void OnGrContextDestroyed() override;

  // |Texture|
  void MarkNewFrameAvailable() override;

  // |Texture|
  void OnTextureUnregistered() override;

  void CreateTextureFromPixelBuffer();

  void EnsureTextureCacheExists();

  bool NeedUpdateTexture(bool freeze);

  bool IsTexturesAvailable() const;

  void CreateYUVTexturesFromPixelBuffer();

  void CreateRGBATextureFromPixelBuffer();

  sk_sp<SkImage> CreateImageFromYUVTextures(GrDirectContext* context, const SkRect& bounds);

  sk_sp<SkImage> CreateImageFromRGBATexture(GrDirectContext* context, const SkRect& bounds);

  FML_DISALLOW_COPY_AND_ASSIGN(IOSExternalTextureGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_IOS_EXTERNAL_TEXTURE_GL_H_
