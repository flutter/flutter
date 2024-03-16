// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_IMAGE_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_IMAGE_EXTERNAL_TEXTURE_GL_H_

#include <unordered_map>

#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/platform/android/image_external_texture.h"

#include "flutter/impeller/renderer/backend/gles/context_gles.h"
#include "flutter/impeller/renderer/backend/gles/gles.h"
#include "flutter/impeller/renderer/backend/gles/texture_gles.h"
#include "flutter/impeller/toolkit/egl/egl.h"
#include "flutter/impeller/toolkit/egl/image.h"
#include "flutter/impeller/toolkit/gles/texture.h"
#include "flutter/shell/platform/android/android_context_gl_skia.h"

namespace flutter {

class ImageExternalTextureGL : public ImageExternalTexture {
 public:
  ImageExternalTextureGL(
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_textury_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

 protected:
  void Attach(PaintContext& context) override;
  void Detach() override;
  void ProcessFrame(PaintContext& context, const SkRect& bounds) override;
  void UpdateImage(JavaLocalRef& hardware_buffer,
                   const SkRect& bounds,
                   PaintContext& context);

  virtual sk_sp<flutter::DlImage> CreateDlImage(
      PaintContext& context,
      const SkRect& bounds,
      std::optional<HardwareBufferKey> id,
      impeller::UniqueEGLImageKHR&& egl_image) = 0;

  impeller::UniqueEGLImageKHR CreateEGLImage(AHardwareBuffer* buffer);

  struct GlEntry {
    impeller::UniqueEGLImageKHR egl_image;
    impeller::UniqueGLTexture texture;
  };

  // Each GL entry is keyed off of the currently active
  // hardware buffers and evicted when the hardware buffer
  // is removed from the LRU cache.
  std::unordered_map<HardwareBufferKey, GlEntry> gl_entries_;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageExternalTextureGL);
};

class ImageExternalTextureGLSkia : public ImageExternalTextureGL {
 public:
  ImageExternalTextureGLSkia(
      const std::shared_ptr<AndroidContextGLSkia>& context,
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_textury_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

 private:
  void Attach(PaintContext& context) override;
  void Detach() override;

  void BindImageToTexture(const impeller::UniqueEGLImageKHR& image, GLuint tex);

  sk_sp<flutter::DlImage> CreateDlImage(
      PaintContext& context,
      const SkRect& bounds,
      std::optional<HardwareBufferKey> id,
      impeller::UniqueEGLImageKHR&& egl_image) override;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageExternalTextureGLSkia);
};

class ImageExternalTextureGLImpeller : public ImageExternalTextureGL {
 public:
  ImageExternalTextureGLImpeller(
      const std::shared_ptr<impeller::ContextGLES>& context,
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>&
          hardware_buffer_texture_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

 private:
  void Attach(PaintContext& context) override;
  void Detach() override;

  sk_sp<flutter::DlImage> CreateDlImage(
      PaintContext& context,
      const SkRect& bounds,
      std::optional<HardwareBufferKey> id,
      impeller::UniqueEGLImageKHR&& egl_image) override;

  const std::shared_ptr<impeller::ContextGLES> impeller_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(ImageExternalTextureGLImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_IMAGE_EXTERNAL_TEXTURE_GL_H_
