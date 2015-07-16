// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_context_stub_with_extensions.h"

namespace gfx {

void GLContextStubWithExtensions::AddExtensionsString(const char* extensions) {
  if (extensions == NULL)
    return;

  if (extensions_.size() != 0)
    extensions_ += ' ';
  extensions_ += extensions;
}

std::string GLContextStubWithExtensions::GetExtensions() {
  return extensions_;
}

void GLContextStubWithExtensions::SetGLVersionString(const char* version_str) {
  version_str_ = std::string(version_str ? version_str : "");
}

std::string GLContextStubWithExtensions::GetGLVersion() {
  return version_str_;
}

bool GLContextStubWithExtensions::WasAllocatedUsingRobustnessExtension() {
  return HasExtension("GL_ARB_robustness") ||
         HasExtension("GL_KHR_robustness") ||
         HasExtension("GL_EXT_robustness");
}

}  // namespace gfx
