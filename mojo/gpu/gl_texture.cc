// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gpu/gl_texture.h"

#include <GLES2/gl2.h>

namespace mojo {

GLTexture::GLTexture(const GLContext::Scope& gl_scope, const mojo::Size& size)
    : gl_context_(gl_scope.gl_context()), size_(size), texture_id_(0u) {
  glGenTextures(1, &texture_id_);
  glBindTexture(GL_TEXTURE_2D, texture_id_);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size_.width, size_.height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, 0);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glBindTexture(GL_TEXTURE_2D, 0);
}

GLTexture::~GLTexture() {
  if (gl_context_->is_lost())
    return;

  GLContext::Scope gl_scope(gl_context_);
  glDeleteTextures(1, &texture_id_);
}

}  // namespace mojo
