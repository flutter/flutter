// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_GL_H_

#include "flutter/shell/platform/android/hardware_buffer_external_texture.h"

#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/impeller/renderer/backend/gles/gles.h"
#include "flutter/impeller/renderer/backend/gles/texture_gles.h"
#include "flutter/impeller/toolkit/egl/egl.h"
#include "flutter/impeller/toolkit/egl/image.h"
#include "flutter/impeller/toolkit/gles/texture.h"

#include "flutter/shell/platform/android/android_context_gl_skia.h"

namespace flutter {

class HardwareBufferExternalTextureGL : public HardwareBufferExternalTexture {
 public:
  HardwareBufferExternalTextureGL(
      const std::shared_ptr<AndroidContextGLSkia>& context,
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>&
          hardware_buffer_texture_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  ~HardwareBufferExternalTextureGL() override;

 private:
  void ProcessFrame(PaintContext& context, const SkRect& bounds) override;
  void Detach() override;

  impeller::UniqueEGLImageKHR image_;
  impeller::UniqueGLTexture texture_;

  FML_DISALLOW_COPY_AND_ASSIGN(HardwareBufferExternalTextureGL);
};

class HardwareBufferExternalTextureImpellerGL
    : public HardwareBufferExternalTexture {
 public:
  HardwareBufferExternalTextureImpellerGL(
      const std::shared_ptr<impeller::ContextGLES>& context,
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>&
          hardware_buffer_texture_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  ~HardwareBufferExternalTextureImpellerGL() override;

 private:
  void ProcessFrame(PaintContext& context, const SkRect& bounds) override;
  void Detach() override;

  const std::shared_ptr<impeller::ContextGLES> impeller_context_;

  impeller::UniqueEGLImageKHR egl_image_;

  FML_DISALLOW_COPY_AND_ASSIGN(HardwareBufferExternalTextureImpellerGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_GL_H_
