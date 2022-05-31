// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/playground/playground_impl.h"

#define GLFW_INCLUDE_NONE
#include "third_party/glfw/include/GLFW/glfw3.h"

#if IMPELLER_ENABLE_METAL
#include "impeller/playground/backend/metal/playground_impl_mtl.h"
#endif  // IMPELLER_ENABLE_METAL

#if IMPELLER_ENABLE_OPENGLES
#include "impeller/playground/backend/gles/playground_impl_gles.h"
#endif  // IMPELLER_ENABLE_OPENGLES

namespace impeller {

std::unique_ptr<PlaygroundImpl> PlaygroundImpl::Create(
    PlaygroundBackend backend) {
  switch (backend) {
#if IMPELLER_ENABLE_METAL
    case PlaygroundBackend::kMetal:
      return std::make_unique<PlaygroundImplMTL>();
#endif  // IMPELLER_ENABLE_METAL
#if IMPELLER_ENABLE_OPENGLES
    case PlaygroundBackend::kOpenGLES:
      return std::make_unique<PlaygroundImplGLES>();
#endif  // IMPELLER_ENABLE_OPENGLES
    default:
      FML_CHECK(false) << "Attempted to create playground with backend that "
                          "isn't available or was disabled on this platform: "
                       << PlaygroundBackendToString(backend);
  }
  FML_UNREACHABLE();
}

PlaygroundImpl::PlaygroundImpl() = default;

PlaygroundImpl::~PlaygroundImpl() = default;

Vector2 PlaygroundImpl::GetContentScale() const {
  auto window = reinterpret_cast<GLFWwindow*>(GetWindowHandle());

  Vector2 scale(1, 1);
  ::glfwGetWindowContentScale(window, &scale.x, &scale.y);

  return scale;
}

}  // namespace impeller
