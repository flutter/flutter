// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gpu/gl_texture.h"

#include "mojo/public/c/gles2/gles2.h"

namespace mojo {

GLTexture::GLTexture(base::WeakPtr<GLContext> context, mojo::Size size)
    : context_(context), size_(size), texture_id_(0u) {
  DCHECK(context_);
  context_->MakeCurrent();
  glGenTextures(1, &texture_id_);
  glBindTexture(GL_TEXTURE_2D, texture_id_);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size_.width, size_.height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, 0);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
}

GLTexture::~GLTexture() {
  if (context_) {
    context_->MakeCurrent();
    glDeleteTextures(1, &texture_id_);
  }
}

}  // namespace mojo
