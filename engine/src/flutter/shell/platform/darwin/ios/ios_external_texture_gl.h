// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_IOS_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_IOS_EXTERNAL_TEXTURE_GL_H_

#include "flutter/flow/texture.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterTexture.h"

namespace flutter {

class IOSExternalTextureGL : public flutter::Texture {
 public:
  IOSExternalTextureGL(int64_t textureId, NSObject<FlutterTexture>* externalTexture);

  ~IOSExternalTextureGL() override;

  // Called from GPU thread.
  void Paint(SkCanvas& canvas, const SkRect& bounds, bool freeze, GrContext* context) override;

  void OnGrContextCreated() override;

  void OnGrContextDestroyed() override;

  void MarkNewFrameAvailable() override;

 private:
  void CreateTextureFromPixelBuffer();

  void EnsureTextureCacheExists();
  bool NeedUpdateTexture(bool freeze);

  bool new_frame_ready_ = false;
  NSObject<FlutterTexture>* external_texture_;
  fml::CFRef<CVOpenGLESTextureCacheRef> cache_ref_;
  fml::CFRef<CVOpenGLESTextureRef> texture_ref_;
  fml::CFRef<CVPixelBufferRef> buffer_ref_;
  FML_DISALLOW_COPY_AND_ASSIGN(IOSExternalTextureGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_IOS_EXTERNAL_TEXTURE_GL_H_
