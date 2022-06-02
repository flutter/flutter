// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/surface/android_surface_mock.h"

namespace flutter {

AndroidSurfaceMock::AndroidSurfaceMock(
    const std::shared_ptr<AndroidContext>& android_context)
    : AndroidSurface(android_context) {}

std::unique_ptr<GLContextResult> AndroidSurfaceMock::GLContextMakeCurrent() {
  return std::make_unique<GLContextDefaultResult>(/*static_result=*/true);
}

bool AndroidSurfaceMock::GLContextClearCurrent() {
  return true;
}

bool AndroidSurfaceMock::GLContextPresent(const GLPresentInfo& present_info) {
  return true;
}

intptr_t AndroidSurfaceMock::GLContextFBO(GLFrameInfo frame_info) const {
  return 0;
}

}  // namespace flutter
