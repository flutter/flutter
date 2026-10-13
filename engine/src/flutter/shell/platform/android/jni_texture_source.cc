// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/jni_texture_source.h"

#include <algorithm>
#include <array>
#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/android/ndk/ndk_proc_table.h"

namespace flutter {

namespace {

// The Java SurfaceTextureWrapper behind a SurfaceTextureSource.
struct JavaSurfaceTexture {
  JavaSurfaceTexture(
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture)
      : jni_facade(std::move(jni_facade)), surface_texture(surface_texture) {}

  std::shared_ptr<PlatformViewAndroidJNI> jni_facade;
  fml::jni::ScopedJavaGlobalRef<jobject> surface_texture;
};

JavaSurfaceTexture& SurfaceTextureFrom(void* user_data) {
  return *static_cast<JavaSurfaceTexture*>(user_data);
}

void AttachSurfaceTexture(void* user_data, uint32_t texture_name) {
  TRACE_EVENT0("flutter", "SurfaceTextureAttachToGLContext");
  JavaSurfaceTexture& source = SurfaceTextureFrom(user_data);
  source.jni_facade->SurfaceTextureAttachToGLContext(
      JavaLocalRef(source.surface_texture), static_cast<int>(texture_name));
}

void UpdateSurfaceTexture(void* user_data, float transformation_out[16]) {
  TRACE_EVENT0("flutter", "SurfaceTextureUpdateTexImage");
  JavaSurfaceTexture& source = SurfaceTextureFrom(user_data);
  source.jni_facade->SurfaceTextureUpdateTexImage(
      JavaLocalRef(source.surface_texture));
  const std::array<float, 16> transformation =
      source.jni_facade->SurfaceTextureGetTransformMatrix(
          JavaLocalRef(source.surface_texture));
  std::copy(transformation.begin(), transformation.end(), transformation_out);
}

void DetachSurfaceTexture(void* user_data) {
  TRACE_EVENT0("flutter", "SurfaceTextureDetachFromGLContext");
  JavaSurfaceTexture& source = SurfaceTextureFrom(user_data);
  source.jni_facade->SurfaceTextureDetachFromGLContext(
      JavaLocalRef(source.surface_texture));
}

bool SurfaceTextureHasPendingFrame(void* user_data) {
  JavaSurfaceTexture& source = SurfaceTextureFrom(user_data);
  return source.jni_facade->SurfaceTextureShouldUpdate(
      JavaLocalRef(source.surface_texture));
}

void DestroySurfaceTexture(void* user_data) {
  delete static_cast<JavaSurfaceTexture*>(user_data);
}

// The Java ImageTextureEntry behind a HardwareBufferSource.
struct JavaImageTexture {
  JavaImageTexture(
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry)
      : jni_facade(std::move(jni_facade)),
        image_texture_entry(image_texture_entry) {}

  std::shared_ptr<PlatformViewAndroidJNI> jni_facade;
  fml::jni::ScopedJavaGlobalRef<jobject> image_texture_entry;
};

// A Java HardwareBuffer that a frame keeps open until the texture releases it.
struct JavaHardwareBuffer {
  JavaHardwareBuffer(std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
                     JNIEnv* env,
                     jobject hardware_buffer)
      : jni_facade(std::move(jni_facade)),
        hardware_buffer(env, hardware_buffer) {}

  std::shared_ptr<PlatformViewAndroidJNI> jni_facade;
  fml::jni::ScopedJavaGlobalRef<jobject> hardware_buffer;
};

void ReleaseHardwareBuffer(void* user_data) {
  auto* hardware_buffer = static_cast<JavaHardwareBuffer*>(user_data);
  hardware_buffer->jni_facade->HardwareBufferClose(
      JavaLocalRef(hardware_buffer->hardware_buffer));
  delete hardware_buffer;
}

bool AcquireImageFrame(void* user_data, HardwareBufferFrame* frame_out) {
  TRACE_EVENT0("flutter", "ImageTextureAcquireFrame");
  auto& source = *static_cast<JavaImageTexture*>(user_data);
  JNIEnv* env = fml::jni::AttachCurrentThread();
  FML_CHECK(env != nullptr);

  // ImageTextureEntry.acquireLatestImage.
  JavaLocalRef image =
      source.jni_facade->ImageProducerTextureEntryAcquireLatestImage(
          JavaLocalRef(source.image_texture_entry));
  if (image.is_null()) {
    return false;
  }
  // Image.getHardwareBuffer.
  JavaLocalRef hardware_buffer =
      source.jni_facade->ImageGetHardwareBuffer(JavaLocalRef(image));
  if (hardware_buffer.is_null()) {
    return false;
  }

  const NDKProcTable& ndk = GetNDKProcTable();
  // Null where the NDK cannot convert it (API levels below 26); the textures
  // then keep or clear their frame as they did before this source existed.
  AHardwareBuffer* buffer =
      ndk.AHardwareBuffer_fromHardwareBuffer
          ? ndk.AHardwareBuffer_fromHardwareBuffer(env, hardware_buffer.obj())
          : nullptr;
  *frame_out = {
      .buffer = buffer,
      .release_user_data =
          new JavaHardwareBuffer(source.jni_facade, env, hardware_buffer.obj()),
      .release = &ReleaseHardwareBuffer,
  };
  return true;
}

void DestroyImageTexture(void* user_data) {
  delete static_cast<JavaImageTexture*>(user_data);
}

}  // namespace

SurfaceTextureSource MakeJavaSurfaceTextureSource(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const fml::jni::ScopedJavaGlobalRef<jobject>& surface_texture) {
  return {
      .user_data =
          new JavaSurfaceTexture(std::move(jni_facade), surface_texture),
      .attach = &AttachSurfaceTexture,
      .update = &UpdateSurfaceTexture,
      .detach = &DetachSurfaceTexture,
      .has_pending_frame = &SurfaceTextureHasPendingFrame,
      .destruction = &DestroySurfaceTexture,
  };
}

HardwareBufferSource MakeJavaImageTextureSource(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    bool drop_frames_on_context_destroyed) {
  return {
      .user_data =
          new JavaImageTexture(std::move(jni_facade), image_texture_entry),
      .acquire_frame = &AcquireImageFrame,
      .drop_frames_on_context_destroyed = drop_frames_on_context_destroyed,
      .destruction = &DestroyImageTexture,
  };
}

}  // namespace flutter
