// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/gl_proc_table.h"

#include <EGL/egl.h>

namespace flutter {

std::shared_ptr<GlProcTable> GlProcTable::Create() {
  auto gl = std::shared_ptr<GlProcTable>(new GlProcTable());

  gl->gen_textures_ =
      reinterpret_cast<GenTexturesProc>(::eglGetProcAddress("glGenTextures"));
  gl->delete_textures_ = reinterpret_cast<DeleteTexturesProc>(
      ::eglGetProcAddress("glDeleteTextures"));
  gl->bind_texture_ =
      reinterpret_cast<BindTextureProc>(::eglGetProcAddress("glBindTexture"));
  gl->tex_parameteri_ = reinterpret_cast<TexParameteriProc>(
      ::eglGetProcAddress("glTexParameteri"));
  gl->tex_image_2d_ =
      reinterpret_cast<TexImage2DProc>(::eglGetProcAddress("glTexImage2D"));

  if (!gl->gen_textures_ || !gl->delete_textures_ || !gl->bind_texture_ ||
      !gl->tex_parameteri_ || !gl->tex_image_2d_) {
    return nullptr;
  }

  return gl;
}

GlProcTable::GlProcTable() = default;

GlProcTable::~GlProcTable() = default;

void GlProcTable::GenTextures(GLsizei n, GLuint* textures) const {
  gen_textures_(n, textures);
}

void GlProcTable::DeleteTextures(GLsizei n, const GLuint* textures) const {
  delete_textures_(n, textures);
}

void GlProcTable::BindTexture(GLenum target, GLuint texture) const {
  bind_texture_(target, texture);
}

void GlProcTable::TexParameteri(GLenum target,
                                GLenum pname,
                                GLint param) const {
  tex_parameteri_(target, pname, param);
}

void GlProcTable::TexImage2D(GLenum target,
                             GLint level,
                             GLint internalformat,
                             GLsizei width,
                             GLsizei height,
                             GLint border,
                             GLenum format,
                             GLenum type,
                             const void* data) const {
  tex_image_2d_(target, level, internalformat, width, height, border, format,
                type, data);
}

}  // namespace flutter
