// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/backend/gles/playground_impl_gles.h"
#include "impeller/renderer/backend/gles/context_gles.h"

namespace impeller {

PlaygroundImplGLES::PlaygroundImplGLES() = default;

PlaygroundImplGLES::~PlaygroundImplGLES() = default;

// |PlaygroundImpl|
std::shared_ptr<Context> PlaygroundImplGLES::CreateContext() const {
  return std::make_shared<ContextGLES>();
}

// |PlaygroundImpl|
bool PlaygroundImplGLES::SetupWindow(WindowHandle handle,
                                     std::shared_ptr<Context> context) {
  return true;
}

// |PlaygroundImpl|
bool PlaygroundImplGLES::TeardownWindow(WindowHandle handle,
                                        std::shared_ptr<Context> context) {
  return true;
}

// |PlaygroundImpl|
std::unique_ptr<Surface> PlaygroundImplGLES::AcquireSurfaceFrame(
    std::shared_ptr<Context> context) {
  return nullptr;
}

}  // namespace impeller
