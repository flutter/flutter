// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_GLES2_CONFORM_TEST_SURFACE_H_
#define GPU_GLES2_CONFORM_TEST_SURFACE_H_

#include <EGL/egl.h>

#include "base/basictypes.h"

namespace egl {

class Surface {
 public:
  explicit Surface(EGLNativeWindowType win);
  ~Surface();

  EGLNativeWindowType window() { return window_; }

 private:
  EGLNativeWindowType window_;

  DISALLOW_COPY_AND_ASSIGN(Surface);
};

}  // namespace egl

#endif  // GPU_GLES2_CONFORM_TEST_SURFACE_H_
