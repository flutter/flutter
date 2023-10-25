// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/toolkit/egl/egl.h"

namespace impeller {
namespace egl {

class Surface {
 public:
  Surface(EGLDisplay display, EGLSurface surface);

  ~Surface();

  bool IsValid() const;

  const EGLSurface& GetHandle() const;

  bool Present() const;

 private:
  EGLDisplay display_ = EGL_NO_DISPLAY;
  EGLSurface surface_ = EGL_NO_SURFACE;

  Surface(const Surface&) = delete;

  Surface& operator=(const Surface&) = delete;
};

}  // namespace egl
}  // namespace impeller
