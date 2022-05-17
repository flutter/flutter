// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "impeller/toolkit/egl/egl.h"

namespace impeller {
namespace egl {

class Surface;

class Context {
 public:
  Context(EGLDisplay display, EGLContext context);

  ~Context();

  bool IsValid() const;

  const EGLContext& GetHandle() const;

  bool MakeCurrent(const Surface& surface) const;

  bool ClearCurrent() const;

 private:
  EGLDisplay display_ = EGL_NO_DISPLAY;
  EGLContext context_ = EGL_NO_CONTEXT;

  FML_DISALLOW_COPY_AND_ASSIGN(Context);
};

}  // namespace egl
}  // namespace impeller
