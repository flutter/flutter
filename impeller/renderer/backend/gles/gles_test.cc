// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/gles_test.h"

#include "EGL/egl.h"
#include "impeller/renderer/backend/gles/gles.h"

namespace impeller {

GLESTest::GLESTest() = default;

GLESTest::~GLESTest() = default;

ProcTableGLES::Resolver GLESTest::GetResolver() const {
  return [](const char* name) {
    return reinterpret_cast<void*>(::eglGetProcAddress(name));
  };
}

}  // namespace impeller
