// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gl_texture_readback.h"

namespace {

class ScopedEglContext {
 public:
  bool Bind(EGLDisplay display, EGLContext context) {
    if (eglBindAPI(EGL_OPENGL_ES_API) != EGL_TRUE) {
      return false;
    }
    if (eglMakeCurrent(display, EGL_NO_SURFACE, EGL_NO_SURFACE, context) !=
        EGL_TRUE) {
      eglBindAPI(previous_api_);
      return false;
    }
    display_ = display;
    return true;
  }

  ~ScopedEglContext() {
    if (display_ != EGL_NO_DISPLAY) {
      eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
      eglBindAPI(previous_api_);
      if (previous_context_ != EGL_NO_CONTEXT) {
        eglMakeCurrent(previous_display_, previous_draw_, previous_read_,
                       previous_context_);
      }
    }
  }

 private:
  EGLDisplay previous_display_ = eglGetCurrentDisplay();
  EGLContext previous_context_ = eglGetCurrentContext();
  EGLSurface previous_draw_ = eglGetCurrentSurface(EGL_DRAW);
  EGLSurface previous_read_ = eglGetCurrentSurface(EGL_READ);
  EGLenum previous_api_ = eglQueryAPI();
  EGLDisplay display_ = EGL_NO_DISPLAY;
};

bool ReadPixels(const FlutterOpenGLTexture& source, void* pixels) {
  const int version = epoxy_gl_version();
  const bool desktop = epoxy_is_desktop_gl();
  const bool separate_framebuffers = version >= 30;
  const bool extended_pack =
      desktop || version >= 30 || epoxy_has_gl_extension("GL_NV_pack_subimage");
  const bool pack_buffer = version >= (desktop ? 21 : 30) ||
                           epoxy_has_gl_extension("GL_NV_pixel_buffer_object");
  const bool pack_invert = epoxy_has_gl_extension("GL_MESA_pack_invert");
  const GLenum target =
      separate_framebuffers ? GL_READ_FRAMEBUFFER : GL_FRAMEBUFFER;
  GLint framebuffer, alignment;
  glGetIntegerv(separate_framebuffers ? GL_READ_FRAMEBUFFER_BINDING
                                      : GL_FRAMEBUFFER_BINDING,
                &framebuffer);
  glGetIntegerv(GL_PACK_ALIGNMENT, &alignment);
  GLuint read_framebuffer = 0;
  glGenFramebuffers(1, &read_framebuffer);
  glBindFramebuffer(target, read_framebuffer);
  glFramebufferTexture2D(target, GL_COLOR_ATTACHMENT0, source.target,
                         source.name, 0);
  bool success = false;
  if (glCheckFramebufferStatus(target) == GL_FRAMEBUFFER_COMPLETE) {
    // A plugin can leave a pack buffer bound or configure a non-tight layout.
    // Restore its state after reading into our tightly packed CPU buffer.
    GLint buffer, row_length, skip_rows, skip_pixels, invert;
    if (pack_buffer) {
      glGetIntegerv(GL_PIXEL_PACK_BUFFER_BINDING, &buffer);
      glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
    }
    if (extended_pack) {
      glGetIntegerv(GL_PACK_ROW_LENGTH, &row_length);
      glGetIntegerv(GL_PACK_SKIP_ROWS, &skip_rows);
      glGetIntegerv(GL_PACK_SKIP_PIXELS, &skip_pixels);
      glPixelStorei(GL_PACK_ROW_LENGTH, 0);
      glPixelStorei(GL_PACK_SKIP_ROWS, 0);
      glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
    }
    if (pack_invert) {
      glGetIntegerv(GL_PACK_INVERT_MESA, &invert);
      glPixelStorei(GL_PACK_INVERT_MESA, GL_FALSE);
    }
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glReadPixels(0, 0, source.width, source.height, GL_RGBA, GL_UNSIGNED_BYTE,
                 pixels);
    success = glGetError() == GL_NO_ERROR;
    glPixelStorei(GL_PACK_ALIGNMENT, alignment);
    if (pack_invert)
      glPixelStorei(GL_PACK_INVERT_MESA, invert);
    if (extended_pack) {
      glPixelStorei(GL_PACK_ROW_LENGTH, row_length);
      glPixelStorei(GL_PACK_SKIP_ROWS, skip_rows);
      glPixelStorei(GL_PACK_SKIP_PIXELS, skip_pixels);
    }
    if (pack_buffer)
      glBindBuffer(GL_PIXEL_PACK_BUFFER, buffer);
  }
  glBindFramebuffer(target, framebuffer);
  glDeleteFramebuffers(1, &read_framebuffer);
  return success;
}

GLuint CompileShader(GLenum type, const char* source) {
  GLuint shader = glCreateShader(type);
  glShaderSource(shader, 1, &source, nullptr);
  glCompileShader(shader);
  GLint compiled = GL_FALSE;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
  if (compiled == GL_FALSE) {
    glDeleteShader(shader);
    return 0;
  }
  return shader;
}

GLuint CreateExternalTextureProgram() {
  constexpr char vertex[] = R"glsl(
    attribute vec2 position;
    varying vec2 uv;
    void main() {
      uv = position * 0.5 + 0.5;
      gl_Position = vec4(position, 0.0, 1.0);
    }
  )glsl";
  constexpr char fragment[] = R"glsl(
    #extension GL_OES_EGL_image_external : require
    #ifdef GL_FRAGMENT_PRECISION_HIGH
    precision highp float;
    #else
    precision mediump float;
    #endif
    varying vec2 uv;
    uniform samplerExternalOES image;
    void main() {
      gl_FragColor = texture2D(image, uv);
    }
  )glsl";
  GLuint vs = CompileShader(GL_VERTEX_SHADER, vertex);
  GLuint fs = CompileShader(GL_FRAGMENT_SHADER, fragment);
  GLuint program = 0;
  if (vs != 0 && fs != 0) {
    program = glCreateProgram();
    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glBindAttribLocation(program, 0, "position");
    glLinkProgram(program);
    GLint linked = GL_FALSE;
    glGetProgramiv(program, GL_LINK_STATUS, &linked);
    if (linked == GL_FALSE) {
      glDeleteProgram(program);
      program = 0;
    }
  }
  glDeleteShader(vs);
  glDeleteShader(fs);
  return program;
}

}  // namespace

FlGlTextureReadback::~FlGlTextureReadback() {
  if (context_ == EGL_NO_CONTEXT) {
    return;
  }
  {
    ScopedEglContext binding;
    if (binding.Bind(display_, context_)) {
      glDeleteProgram(program_);
      glDeleteTextures(1, &color_texture_);
      glDeleteBuffers(1, &vertex_buffer_);
      glDeleteFramebuffers(1, &framebuffer_);
    }
  }
  eglDestroyContext(display_, context_);
}

bool FlGlTextureReadback::InitializeExternalContext(EGLDisplay display,
                                                    EGLContext shared) {
  EGLint config_id = 0;
  if (!eglQueryContext(display, shared, EGL_CONFIG_ID, &config_id)) {
    return false;
  }
  const EGLint match[] = {EGL_CONFIG_ID, config_id, EGL_NONE};
  EGLConfig config = nullptr;
  EGLint count = 0;
  if (!eglChooseConfig(display, match, &config, 1, &count) || count != 1) {
    return false;
  }
  const EGLenum api = eglQueryAPI();
  if (!eglBindAPI(EGL_OPENGL_ES_API)) {
    return false;
  }
  const EGLint attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  context_ = eglCreateContext(display, config, shared, attributes);
  eglBindAPI(api);
  display_ = display;
  return context_ != EGL_NO_CONTEXT;
}

bool FlGlTextureReadback::DrawExternal(const FlutterOpenGLTexture& source) {
  if (program_ == 0) {
    program_ = CreateExternalTextureProgram();
    if (program_ == 0) {
      return false;
    }
    glUseProgram(program_);
    glUniform1i(glGetUniformLocation(program_, "image"), 0);
    glDisable(GL_DITHER);
    constexpr GLfloat vertices[] = {-1, -1, 3, -1, -1, 3};
    glGenBuffers(1, &vertex_buffer_);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer_);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, nullptr);
    glGenFramebuffers(1, &framebuffer_);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);
    glGenTextures(1, &color_texture_);
    glBindTexture(GL_TEXTURE_2D, color_texture_);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           color_texture_, 0);
  }
  if (width_ != source.width || height_ != source.height) {
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, source.width, source.height, 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE ||
        glGetError() != GL_NO_ERROR) {
      return false;
    }
    width_ = source.width;
    height_ = source.height;
    glViewport(0, 0, width_, height_);
  }
  glBindTexture(GL_TEXTURE_EXTERNAL_OES, source.name);
  glDrawArrays(GL_TRIANGLES, 0, 3);
  return glGetError() == GL_NO_ERROR;
}

bool FlGlTextureReadback::Read(const FlutterOpenGLTexture& source,
                               void* pixels) {
  if (source.target != GL_TEXTURE_EXTERNAL_OES) {
    return ReadPixels(source, pixels);
  }

  // External textures can only be sampled. A shared context isolates the
  // conversion draw from the plugin's shaders, bindings and framebuffer state.
  EGLDisplay display = eglGetCurrentDisplay();
  if (context_ == EGL_NO_CONTEXT &&
      (!epoxy_has_gl_extension("GL_OES_EGL_image_external") ||
       !InitializeExternalContext(display, eglGetCurrentContext()))) {
    return false;
  }
  // Commands from the producer must finish before the other context samples
  // the shared texture. The readback then synchronizes the conversion draw.
  glFinish();
  ScopedEglContext binding;
  if (!binding.Bind(display, context_) || !DrawExternal(source)) {
    return false;
  }
  glReadPixels(0, 0, source.width, source.height, GL_RGBA, GL_UNSIGNED_BYTE,
               pixels);
  return glGetError() == GL_NO_ERROR;
}
