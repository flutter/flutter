// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_TEXTURE_READBACK_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_TEXTURE_READBACK_H_

#include <epoxy/egl.h>
#include <epoxy/gl.h>

#include "flutter/shell/platform/embedder/embedder.h"

// Reads an OpenGL plugin texture as tightly packed RGBA8. External EGL image
// textures are sampled in a dedicated context sharing the raster context.
class FlGlTextureReadback {
 public:
  FlGlTextureReadback() = default;
  ~FlGlTextureReadback();

  FlGlTextureReadback(const FlGlTextureReadback&) = delete;
  FlGlTextureReadback& operator=(const FlGlTextureReadback&) = delete;

  bool Read(const FlutterOpenGLTexture& source, void* pixels);

 private:
  bool InitializeExternalContext(EGLDisplay display, EGLContext shared);
  bool DrawExternal(const FlutterOpenGLTexture& source);

  EGLDisplay display_ = EGL_NO_DISPLAY;
  EGLContext context_ = EGL_NO_CONTEXT;
  GLuint program_ = 0;
  GLuint vertex_buffer_ = 0;
  GLuint framebuffer_ = 0;
  GLuint color_texture_ = 0;
  size_t width_ = 0;
  size_t height_ = 0;
};

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GL_TEXTURE_READBACK_H_
