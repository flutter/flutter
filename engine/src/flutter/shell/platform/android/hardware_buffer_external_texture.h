// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_H_

#include "flutter/common/graphics/texture.h"
#include "flutter/fml/logging.h"
#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/platform_view_android_jni_impl.h"

#include <android/hardware_buffer.h>
#include <android/hardware_buffer_jni.h>

namespace flutter {

// External texture peered to a sequence of android.hardware.HardwareBuffers.
//
class HardwareBufferExternalTexture : public flutter::Texture {
 public:
  explicit HardwareBufferExternalTexture(
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade);

  virtual ~HardwareBufferExternalTexture() = default;

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

 protected:
  virtual void Attach(PaintContext& context) = 0;
  virtual void Detach() = 0;
  virtual void ProcessFrame(PaintContext& context, const SkRect& bounds) = 0;

  JavaLocalRef AcquireLatestImage();
  void CloseImage(const fml::jni::JavaRef<jobject>& image);
  JavaLocalRef HardwareBufferFor(const fml::jni::JavaRef<jobject>& image);
  void CloseHardwareBuffer(const fml::jni::JavaRef<jobject>& hardware_buffer);
  AHardwareBuffer* AHardwareBufferFor(
      const fml::jni::JavaRef<jobject>& hardware_buffer);

  fml::jni::ScopedJavaGlobalRef<jobject> image_texture_entry_;
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;

  enum class AttachmentState { kUninitialized, kAttached, kDetached };
  AttachmentState state_ = AttachmentState::kUninitialized;
  bool new_frame_ready_ = false;

  sk_sp<flutter::DlImage> dl_image_;

  FML_DISALLOW_COPY_AND_ASSIGN(HardwareBufferExternalTexture);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_HARDWARE_BUFFER_EXTERNAL_TEXTURE_H_
