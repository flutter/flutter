// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/external_texture_pixelbuffer.h"

namespace flutter {

struct ExternalTexturePixelBufferState {
  GLuint gl_texture = 0;
};

ExternalTexturePixelBuffer::ExternalTexturePixelBuffer(
    FlutterDesktopPixelBufferTextureCallback texture_callback,
    void* user_data,
    const GlProcs& gl_procs)
    : state_(std::make_unique<ExternalTexturePixelBufferState>()),
      texture_callback_(texture_callback),
      user_data_(user_data),
      gl_(gl_procs) {}

ExternalTexturePixelBuffer::~ExternalTexturePixelBuffer() {
  if (state_->gl_texture != 0) {
    gl_.glDeleteTextures(1, &state_->gl_texture);
  }
}

bool ExternalTexturePixelBuffer::PopulateTexture(
    size_t width,
    size_t height,
    FlutterOpenGLTexture* opengl_texture) {
  if (!CopyPixelBuffer(width, height)) {
    return false;
  }

  // Populate the texture object used by the engine.
  opengl_texture->target = GL_TEXTURE_2D;
  opengl_texture->name = state_->gl_texture;
  opengl_texture->format = GL_RGBA8_OES;
  opengl_texture->destruction_callback = nullptr;
  opengl_texture->user_data = nullptr;
  opengl_texture->width = width;
  opengl_texture->height = height;

  return true;
}

bool ExternalTexturePixelBuffer::CopyPixelBuffer(size_t& width,
                                                 size_t& height) {
  const FlutterDesktopPixelBuffer* pixel_buffer =
      texture_callback_(width, height, user_data_);
  if (!pixel_buffer || !pixel_buffer->buffer) {
    return false;
  }
  width = pixel_buffer->width;
  height = pixel_buffer->height;

  if (state_->gl_texture == 0) {
    gl_.glGenTextures(1, &state_->gl_texture);

    gl_.glBindTexture(GL_TEXTURE_2D, state_->gl_texture);
    gl_.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    gl_.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    gl_.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    gl_.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  } else {
    gl_.glBindTexture(GL_TEXTURE_2D, state_->gl_texture);
  }
  gl_.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pixel_buffer->width,
                   pixel_buffer->height, 0, GL_RGBA, GL_UNSIGNED_BYTE,
                   pixel_buffer->buffer);
  if (pixel_buffer->release_callback) {
    pixel_buffer->release_callback(pixel_buffer->release_context);
  }
  return true;
}

}  // namespace flutter
