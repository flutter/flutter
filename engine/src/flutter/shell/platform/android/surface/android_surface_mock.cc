// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/surface/android_surface_mock.h"

namespace flutter {

std::unique_ptr<GLContextResult> AndroidSurfaceMock::GLContextMakeCurrent() {
  return std::make_unique<GLContextDefaultResult>(/*static_result=*/true);
}

bool AndroidSurfaceMock::GLContextClearCurrent() {
  return true;
}

bool AndroidSurfaceMock::GLContextPresent(uint32_t fbo_id) {
  return true;
}

intptr_t AndroidSurfaceMock::GLContextFBO(GLFrameInfo frame_info) const {
  return 0;
}

}  // namespace flutter
