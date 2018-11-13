// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_TEXTURE_GL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_TEXTURE_GL_H_

#include <GLES/gl.h>
#include "flutter/flow/texture.h"
#include "flutter/fml/platform/android/jni_weak_ref.h"

namespace shell {

class AndroidExternalTextureGL : public flow::Texture {
 public:
  AndroidExternalTextureGL(
      int64_t id,
      const fml::jni::JavaObjectWeakGlobalRef& surfaceTexture);

  ~AndroidExternalTextureGL() override;

  void Paint(SkCanvas& canvas, const SkRect& bounds, bool freeze) override;

  void OnGrContextCreated() override;

  void OnGrContextDestroyed() override;

  void MarkNewFrameAvailable() override;

 private:
  void Attach(jint textureName);

  void Update();

  void Detach();

  void UpdateTransform();

  enum class AttachmentState { uninitialized, attached, detached };

  fml::jni::JavaObjectWeakGlobalRef surface_texture_;

  AttachmentState state_ = AttachmentState::uninitialized;

  bool new_frame_ready_ = false;

  GLuint texture_name_ = 0;

  SkMatrix transform;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidExternalTextureGL);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_TEXTURE_GL_H_
