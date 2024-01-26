// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_SURFACE_TEXTURE_EXTERNAL_TEXTURE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_SURFACE_TEXTURE_EXTERNAL_TEXTURE_H_

#include <GLES/gl.h>

#include "flutter/common/graphics/texture.h"
#include "flutter/shell/platform/android/platform_view_android_jni_impl.h"

namespace flutter {

// External texture peered to an android.graphics.SurfaceTexture.
class SurfaceTextureExternalTexture : public flutter::Texture {
 public:
  SurfaceTextureExternalTexture(
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  ~SurfaceTextureExternalTexture() override;

  void Paint(PaintContext& context,
             const SkRect& bounds,
             bool freeze,
             const DlImageSampling sampling) override;

  void OnGrContextCreated() override;

  void OnGrContextDestroyed() override;

  void MarkNewFrameAvailable() override;

  void OnTextureUnregistered() override;

 protected:
  virtual void ProcessFrame(PaintContext& context, const SkRect& bounds) = 0;
  virtual void Detach();

  void Attach(int gl_tex_id);
  bool ShouldUpdate();
  void Update();

  enum class AttachmentState { kUninitialized, kAttached, kDetached };

  std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  fml::jni::ScopedJavaGlobalRef<jobject> surface_texture_;
  AttachmentState state_ = AttachmentState::kUninitialized;
  SkMatrix transform_;
  sk_sp<flutter::DlImage> dl_image_;

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceTextureExternalTexture);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_SURFACE_TEXTURE_EXTERNAL_TEXTURE_H_
