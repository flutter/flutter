// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gpu/gl_context_owner.h"

#include "mojo/gpu/gl_context.h"

namespace mojo {

GLContextOwner::GLContextOwner(mojo::Shell* shell)
    : context_(mojo::GLContext::Create(shell)) {
}

GLContextOwner::~GLContextOwner() {
  context_->Destroy();
}

}  // namespace mojo
