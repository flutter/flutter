// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_surface_stub.h"

namespace gfx {

GLSurfaceStub::GLSurfaceStub(
  const gfx::SurfaceConfiguration requested_configuration)
    : GLSurface(requested_configuration) {
}

void GLSurfaceStub::Destroy() {
}

bool GLSurfaceStub::IsOffscreen() {
  return false;
}

bool GLSurfaceStub::SwapBuffers() {
  return true;
}

gfx::Size GLSurfaceStub::GetSize() {
  return size_;
}

void* GLSurfaceStub::GetHandle() {
  return NULL;
}

GLSurfaceStub::~GLSurfaceStub() {}

}  // namespace gfx
