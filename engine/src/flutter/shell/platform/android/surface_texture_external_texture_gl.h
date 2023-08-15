// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_SURFACE_TEXTURE_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_SURFACE_TEXTURE_EXTERNAL_TEXTURE_GL_H_

#include "flutter/shell/platform/android/surface_texture_external_texture.h"

#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/impeller/renderer/backend/gles/gles.h"
#include "flutter/impeller/renderer/backend/gles/texture_gles.h"
#include "flutter/impeller/toolkit/egl/egl.h"
#include "flutter/impeller/toolkit/egl/image.h"
#include "flutter/impeller/toolkit/gles/texture.h"

#include "flutter/impeller/renderer/backend/gles/context_gles.h"

namespace flutter {

class SurfaceTextureExternalTextureGL : public SurfaceTextureExternalTexture {
 public:
  SurfaceTextureExternalTextureGL(
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  ~SurfaceTextureExternalTextureGL() override;

 private:
  virtual void ProcessFrame(PaintContext& context,
                            const SkRect& bounds) override;
  virtual void Detach() override;

  GLuint texture_name_ = 0;

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceTextureExternalTextureGL);
};

class SurfaceTextureExternalTextureImpellerGL
    : public SurfaceTextureExternalTexture {
 public:
  SurfaceTextureExternalTextureImpellerGL(
      const std::shared_ptr<impeller::ContextGLES>& context,
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  ~SurfaceTextureExternalTextureImpellerGL() override;

 private:
  virtual void ProcessFrame(PaintContext& context,
                            const SkRect& bounds) override;
  virtual void Detach() override;

  const std::shared_ptr<impeller::ContextGLES> impeller_context_;
  std::shared_ptr<impeller::TextureGLES> texture_;

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceTextureExternalTextureImpellerGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_SURFACE_TEXTURE_EXTERNAL_TEXTURE_GL_H_
