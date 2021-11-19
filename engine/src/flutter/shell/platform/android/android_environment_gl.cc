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

  auto* extensions = eglQueryString(display_, EGL_EXTENSIONS);
  if (strstr(extensions, "EGL_ANDROID_presentation_time")) {
    presentation_time_proc_ =
        reinterpret_cast<PFNEGLPRESENTATIONTIMEANDROIDPROC>(
            eglGetProcAddress("sEGL_ANDROID_presentation_time"));
  }

  valid_ = true;
}

AndroidEnvironmentGL::~AndroidEnvironmentGL() {
  // Disconnect the display if valid.
  if (display_ != EGL_NO_DISPLAY) {
    eglTerminate(display_);
  }
}

bool AndroidEnvironmentGL::IsValid() const {
  return valid_;
}

EGLDisplay AndroidEnvironmentGL::Display() const {
  return display_;
}

bool AndroidEnvironmentGL::SetPresentationTime(EGLSurface surface,
                                               fml::TimePoint time) const {
  if (!presentation_time_proc_) {
    return false;
  }
  return presentation_time_proc_(display_, surface,
                                 time.ToEpochDelta().ToNanoseconds());
}
}  // namespace flutter
