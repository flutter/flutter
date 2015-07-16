// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_context_stub.h"

namespace gfx {

GLContextStub::GLContextStub() : GLContextReal(NULL) {}

bool GLContextStub::Initialize(
    GLSurface* compatible_surface, GpuPreference gpu_preference) {
  return true;
}

void GLContextStub::Destroy() {}

bool GLContextStub::MakeCurrent(GLSurface* surface) {
  SetCurrent(surface);
  SetRealGLApi();
  return true;
}

void GLContextStub::ReleaseCurrent(GLSurface* surface) {
  SetCurrent(NULL);
}

bool GLContextStub::IsCurrent(GLSurface* surface) {
  return true;
}

void* GLContextStub::GetHandle() {
  return NULL;
}

void GLContextStub::OnSetSwapInterval(int interval) {
}

std::string GLContextStub::GetExtensions() {
  return std::string();
}

std::string GLContextStub::GetGLRenderer() {
  return std::string("CHROMIUM");
}

GLContextStub::~GLContextStub() {}

}  // namespace gfx
