// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GPU_GL_TEXTURE_H_
#define MOJO_GPU_GL_TEXTURE_H_

#include "mojo/gpu/gl_context.h"
#include "mojo/services/geometry/interfaces/geometry.mojom.h"

namespace mojo {

// Manages a GL texture.
//
// Instances of this object are not thread-safe and must be used on the same
// thread as the GL context was created on.
class GLTexture {
 public:
  GLTexture(const GLContext::Scope& gl_scope, const mojo::Size& size);
  ~GLTexture();

  const scoped_refptr<GLContext>& gl_context() const { return gl_context_; }
  const mojo::Size& size() const { return size_; }
  uint32_t texture_id() const { return texture_id_; }

 private:
  scoped_refptr<GLContext> gl_context_;
  mojo::Size size_;
  uint32_t texture_id_;

  DISALLOW_COPY_AND_ASSIGN(GLTexture);
};

}  // namespace mojo

#endif  // MOJO_GPU_GL_TEXTURE_H_
