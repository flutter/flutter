// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_IOS_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_IOS_EXTERNAL_TEXTURE_GL_H_

#include "flutter/flow/texture.h"
#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterTexture.h"

namespace shell {

class IOSExternalTextureGL : public flow::Texture {
 public:
  IOSExternalTextureGL(int64_t textureId, NSObject<FlutterTexture>* externalTexture);

  ~IOSExternalTextureGL() override;

  // Called from GPU thread.
  virtual void Paint(SkCanvas& canvas, const SkRect& bounds, bool freeze) override;

  virtual void OnGrContextCreated() override;

  virtual void OnGrContextDestroyed() override;

  virtual void MarkNewFrameAvailable() override;

 private:
  NSObject<FlutterTexture>* external_texture_;
  fml::CFRef<CVOpenGLESTextureCacheRef> cache_ref_;
  fml::CFRef<CVOpenGLESTextureRef> texture_ref_;
  FML_DISALLOW_COPY_AND_ASSIGN(IOSExternalTextureGL);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_IOS_EXTERNAL_TEXTURE_GL_H_
