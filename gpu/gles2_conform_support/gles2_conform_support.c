// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A small sample just to make sure we can actually compile and link
// our OpenGL ES 2.0 conformance test support code.

#include <EGL/egl.h>
#include "gpu/gles2_conform_support/gtf/gtf_stubs.h"

// Note: This code is not intended to run, only compile and link.
int GTFMain(int argc, char** argv) {
  EGLint major, minor;
  EGLDisplay eglDisplay;
  EGLNativeDisplayType nativeDisplay = EGL_DEFAULT_DISPLAY;

  eglDisplay = eglGetDisplay(nativeDisplay);
  eglInitialize(eglDisplay, &major, &minor);

  return 0;
}


