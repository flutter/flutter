// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_external_texture_ahb_gl.h"

#include <android/hardware_buffer.h>

#include "flutter/impeller/toolkit/android/hardware_buffer.h"

namespace flutter {

EmbedderExternalTextureAHBGL::EmbedderExternalTextureAHBGL(
    int64_t id,
    EmbedderAndroidHardwareBufferSource source)
    : EmbedderExternalTextureAHB(id, source) {}

void EmbedderExternalTextureAHBGL::Attach(PaintContext& context) {
  if (state_ == AttachmentState::kUninitialized) {
    // TODO(johnmccurtchan): We currently display the first frame after an
    // attach-detach cycle as blank. There seems to be an issue on some
    // devices where ImageReaders/Images from before the detach aren't
    // valid after the attach. According to Android folks this doesn't
    // match the spec. Revisit this in the future.
    // See https://github.com/flutter/flutter/issues/142978 and
    // https://github.com/flutter/flutter/issues/139039.
    state_ = AttachmentState::kAttached;
  }
}

void EmbedderExternalTextureAHBGL::UpdateImage(
    AHardwareBuffer* latest_hardware_buffer,
    const SkRect& bounds,
    PaintContext& context) {
  std::optional<HardwareBufferKey> key =
      impeller::android::HardwareBuffer::GetSystemUniqueID(
          latest_hardware_buffer);
  auto existing_image = image_lru_.FindImage(key);
  if (existing_image != nullptr) {
    dl_image_ = existing_image;
    return;
  }

  auto egl_image = CreateEGLImage(latest_hardware_buffer);
  if (!egl_image.is_valid()) {
    return;
  }

  dl_image_ = CreateDlImage(context, bounds, key, std::move(egl_image));
  if (key.has_value()) {
    gl_entries_.erase(image_lru_.AddImage(dl_image_, key.value()));
  }
}

void EmbedderExternalTextureAHBGL::ProcessFrame(PaintContext& context,
                                                const SkRect& bounds) {
  std::unique_ptr<AcquiredFrame> frame = AcquireFrame();
  if (!frame) {
    return;
  }
  UpdateImage(static_cast<AHardwareBuffer*>(frame->buffer()), bounds, context);
  // `frame` releases the buffer here.
}

void EmbedderExternalTextureAHBGL::Detach() {
  image_lru_.Clear();
  gl_entries_.clear();
}

impeller::UniqueEGLImageKHR EmbedderExternalTextureAHBGL::CreateEGLImage(
    AHardwareBuffer* hardware_buffer) {
  if (hardware_buffer == nullptr) {
    return impeller::UniqueEGLImageKHR();
  }

  EGLDisplay display = eglGetCurrentDisplay();
  if (display == EGL_NO_DISPLAY) {
    // This could happen when running in a deferred task that executes after
    // the thread has lost its EGL state.
    return impeller::UniqueEGLImageKHR();
  }

  EGLClientBuffer client_buffer =
      impeller::android::GetProcTable().eglGetNativeClientBufferANDROID(
          hardware_buffer);
  FML_DCHECK(client_buffer != nullptr);
  if (client_buffer == nullptr) {
    FML_LOG(ERROR) << "eglGetNativeClientBufferAndroid returned null.";
    return impeller::UniqueEGLImageKHR();
  }

  impeller::EGLImageKHRWithDisplay maybe_image =
      impeller::EGLImageKHRWithDisplay{
          eglCreateImageKHR(display, EGL_NO_CONTEXT, EGL_NATIVE_BUFFER_ANDROID,
                            client_buffer, 0),
          display};

  return impeller::UniqueEGLImageKHR(maybe_image);
}

}  // namespace flutter
