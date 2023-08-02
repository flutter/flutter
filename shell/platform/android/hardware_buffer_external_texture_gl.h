// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_HARDWARE_BUFFER_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_HARDWARE_BUFFER_EXTERNAL_TEXTURE_GL_H_

#include <mutex>

#include "flutter/impeller/toolkit/egl/egl.h"
#include "flutter/impeller/toolkit/egl/image.h"
#include "flutter/impeller/toolkit/gles/texture.h"

#include <android/hardware_buffer.h>
#include <android/hardware_buffer_jni.h>

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/platform/android/android_context_gl_skia.h"
#include "flutter/shell/platform/android/platform_view_android_jni_impl.h"

namespace flutter {

class HardwareBufferExternalTextureGL : public flutter::Texture {
 public:
  explicit HardwareBufferExternalTextureGL(
      const std::shared_ptr<AndroidContextGLSkia>& context,
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>&
          hardware_buffer_texture_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);
  ~HardwareBufferExternalTextureGL() override;

  // |flutter::Texture|.
  void Paint(PaintContext& context,
             const SkRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override;

  // |flutter::Texture|.
  void MarkNewFrameAvailable() override;

  // |flutter::Texture|
  void OnTextureUnregistered() override;

  // |flutter::ContextListener|
  void OnGrContextCreated() override;

  // |flutter::ContextListener|
  void OnGrContextDestroyed() override;

 private:
  AHardwareBuffer* GetLatestHardwareBuffer();
  void Update();

  const std::shared_ptr<AndroidContextGLSkia> context_;
  fml::jni::ScopedJavaGlobalRef<jobject> image_texture_entry_;
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;

  enum class AttachmentState { kUninitialized, kAttached, kDetached };
  AttachmentState state_ = AttachmentState::kUninitialized;
  bool new_frame_ready_ = false;
  impeller::UniqueEGLImageKHR image_;
  impeller::UniqueGLTexture texture_;

  FML_DISALLOW_COPY_AND_ASSIGN(HardwareBufferExternalTextureGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_TEXTURE_GL_H_
