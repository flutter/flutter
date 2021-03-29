// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/external_texture_gl.h"

#include <EGL/egl.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

namespace {

typedef void (*glGenTexturesProc)(GLsizei n, GLuint* textures);
typedef void (*glDeleteTexturesProc)(GLsizei n, const GLuint* textures);
typedef void (*glBindTextureProc)(GLenum target, GLuint texture);
typedef void (*glTexParameteriProc)(GLenum target, GLenum pname, GLint param);
typedef void (*glTexImage2DProc)(GLenum target,
                                 GLint level,
                                 GLint internalformat,
                                 GLsizei width,
                                 GLsizei height,
                                 GLint border,
                                 GLenum format,
                                 GLenum type,
                                 const void* data);

// A struct containing pointers to resolved gl* functions.
struct GlProcs {
  glGenTexturesProc glGenTextures;
  glDeleteTexturesProc glDeleteTextures;
  glBindTextureProc glBindTexture;
  glTexParameteriProc glTexParameteri;
  glTexImage2DProc glTexImage2D;
  bool valid;
};

static const GlProcs& GlProcs() {
  static struct GlProcs procs = {};
  static bool initialized = false;
  if (!initialized) {
    procs.glGenTextures =
        reinterpret_cast<glGenTexturesProc>(eglGetProcAddress("glGenTextures"));
    procs.glDeleteTextures = reinterpret_cast<glDeleteTexturesProc>(
        eglGetProcAddress("glDeleteTextures"));
    procs.glBindTexture =
        reinterpret_cast<glBindTextureProc>(eglGetProcAddress("glBindTexture"));
    procs.glTexParameteri = reinterpret_cast<glTexParameteriProc>(
        eglGetProcAddress("glTexParameteri"));
    procs.glTexImage2D =
        reinterpret_cast<glTexImage2DProc>(eglGetProcAddress("glTexImage2D"));

    procs.valid = procs.glGenTextures && procs.glDeleteTextures &&
                  procs.glBindTexture && procs.glTexParameteri &&
                  procs.glTexImage2D;
    initialized = true;
  }
  return procs;
}

}  // namespace

namespace flutter {

struct ExternalTextureGLState {
  GLuint gl_texture = 0;
};

ExternalTextureGL::ExternalTextureGL(
    FlutterDesktopPixelBufferTextureCallback texture_callback,
    void* user_data)
    : state_(std::make_unique<ExternalTextureGLState>()),
      texture_callback_(texture_callback),
      user_data_(user_data) {}

ExternalTextureGL::~ExternalTextureGL() {
  const auto& gl = GlProcs();
  if (gl.valid && state_->gl_texture != 0) {
    gl.glDeleteTextures(1, &state_->gl_texture);
  }
}

bool ExternalTextureGL::PopulateTexture(size_t width,
                                        size_t height,
                                        FlutterOpenGLTexture* opengl_texture) {
  if (!CopyPixelBuffer(width, height)) {
    return false;
  }

  // Populate the texture object used by the engine.
  opengl_texture->target = GL_TEXTURE_2D;
  opengl_texture->name = state_->gl_texture;
  opengl_texture->format = GL_RGBA8;
  opengl_texture->destruction_callback = nullptr;
  opengl_texture->user_data = nullptr;
  opengl_texture->width = width;
  opengl_texture->height = height;

  return true;
}

bool ExternalTextureGL::CopyPixelBuffer(size_t& width, size_t& height) {
  const FlutterDesktopPixelBuffer* pixel_buffer =
      texture_callback_(width, height, user_data_);
  const auto& gl = GlProcs();
  if (!gl.valid || !pixel_buffer || !pixel_buffer->buffer) {
    return false;
  }
  width = pixel_buffer->width;
  height = pixel_buffer->height;

  if (state_->gl_texture == 0) {
    gl.glGenTextures(1, &state_->gl_texture);

    gl.glBindTexture(GL_TEXTURE_2D, state_->gl_texture);

    gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

    gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    gl.glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  } else {
    gl.glBindTexture(GL_TEXTURE_2D, state_->gl_texture);
  }
  gl.glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pixel_buffer->width,
                  pixel_buffer->height, 0, GL_RGBA, GL_UNSIGNED_BYTE,
                  pixel_buffer->buffer);
  return true;
}

}  // namespace flutter
