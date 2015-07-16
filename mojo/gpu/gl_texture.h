// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GPU_GL_TEXTURE_H_
#define MOJO_GPU_GL_TEXTURE_H_

#include "base/basictypes.h"
#include "mojo/gpu/gl_context.h"
#include "mojo/services/geometry/public/interfaces/geometry.mojom.h"

namespace mojo {

class GLTexture {
 public:
  GLTexture(base::WeakPtr<GLContext> context, mojo::Size size);
  ~GLTexture();

  const mojo::Size& size() const { return size_; }
  uint32_t texture_id() const { return texture_id_; }

 private:
  base::WeakPtr<GLContext> context_;
  mojo::Size size_;
  uint32_t texture_id_;

  DISALLOW_COPY_AND_ASSIGN(GLTexture);
};

}  // namespace mojo

#endif  // MOJO_GPU_GL_TEXTURE_H_
