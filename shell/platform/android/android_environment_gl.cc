// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_environment_gl.h"

namespace flutter {

AndroidEnvironmentGL::AndroidEnvironmentGL()
    : display_(EGL_NO_DISPLAY), valid_(false) {
  // Get the display.
  display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);

  if (display_ == EGL_NO_DISPLAY) {
    return;
  }

  // Initialize the display connection.
  if (eglInitialize(display_, nullptr, nullptr) != EGL_TRUE) {
    return;
  }

  valid_ = true;
}

AndroidEnvironmentGL::~AndroidEnvironmentGL() {
  // Diconnect the display if valid.
  if (display_ != EGL_NO_CONTEXT) {
    eglTerminate(display_);
  }
}

bool AndroidEnvironmentGL::IsValid() const {
  return valid_;
}

EGLDisplay AndroidEnvironmentGL::Display() const {
  return display_;
}

}  // namespace flutter
