// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_GL_H_

#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/platform/android/hardware_buffer_external_texture.h"

#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/impeller/renderer/backend/gles/gles.h"
#include "flutter/impeller/renderer/backend/gles/texture_gles.h"
#include "flutter/impeller/toolkit/egl/egl.h"
#include "flutter/impeller/toolkit/egl/image.h"
#include "flutter/impeller/toolkit/gles/texture.h"

#include "flutter/shell/platform/android/android_context_gl_skia.h"
#include "flutter/shell/platform/android/ndk_helpers.h"

namespace flutter {

class HardwareBufferExternalTextureGL : public HardwareBufferExternalTexture {
 public:
  HardwareBufferExternalTextureGL(
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_textury_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

 protected:
  void Attach(PaintContext& context) override;
  void Detach() override;

  // Returns true if a new image was acquired and android_image_ and egl_image_
  // were updated.
  bool MaybeSwapImages();
  impeller::UniqueEGLImageKHR CreateEGLImage(AHardwareBuffer* buffer);

  fml::jni::ScopedJavaGlobalRef<jobject> android_image_;
  impeller::UniqueEGLImageKHR egl_image_;

  FML_DISALLOW_COPY_AND_ASSIGN(HardwareBufferExternalTextureGL);
};

class HardwareBufferExternalTextureGLSkia
    : public HardwareBufferExternalTextureGL {
 public:
  HardwareBufferExternalTextureGLSkia(
      const std::shared_ptr<AndroidContextGLSkia>& context,
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_textury_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

 private:
  void Attach(PaintContext& context) override;
  void Detach() override;
  void ProcessFrame(PaintContext& context, const SkRect& bounds) override;

  void BindImageToTexture(const impeller::UniqueEGLImageKHR& image, GLuint tex);
  sk_sp<flutter::DlImage> CreateDlImage(PaintContext& context,
                                        const SkRect& bounds);

  impeller::UniqueGLTexture texture_;

  FML_DISALLOW_COPY_AND_ASSIGN(HardwareBufferExternalTextureGLSkia);
};

class HardwareBufferExternalTextureGLImpeller
    : public HardwareBufferExternalTextureGL {
 public:
  HardwareBufferExternalTextureGLImpeller(
      const std::shared_ptr<impeller::ContextGLES>& context,
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>&
          hardware_buffer_texture_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

 private:
  void Attach(PaintContext& context) override;
  void ProcessFrame(PaintContext& context, const SkRect& bounds) override;
  void Detach() override;

  sk_sp<flutter::DlImage> CreateDlImage(PaintContext& context,
                                        const SkRect& bounds);

  const std::shared_ptr<impeller::ContextGLES> impeller_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(HardwareBufferExternalTextureGLImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_GL_H_
