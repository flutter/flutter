// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GPU_GL_CONTEXT_OWNER_H_
#define MOJO_GPU_GL_CONTEXT_OWNER_H_

#include "base/memory/weak_ptr.h"

namespace mojo {
class GLContext;
class Shell;

class GLContextOwner {
 public:
  explicit GLContextOwner(mojo::Shell* shell);
  ~GLContextOwner();

  const base::WeakPtr<mojo::GLContext>& context() const { return context_; }

 private:
  base::WeakPtr<mojo::GLContext> context_;

  DISALLOW_COPY_AND_ASSIGN(GLContextOwner);
};

}  // namespace mojo

#endif  // MOJO_GPU_GL_CONTEXT_OWNER_H_
