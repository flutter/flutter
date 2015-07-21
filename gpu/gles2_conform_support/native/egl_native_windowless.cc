// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/gles2_conform_support/egl/display.h"

extern "C" {
#if defined(GLES2_CONFORM_SUPPORT_ONLY)
#include "gpu/gles2_conform_support/gtf/gtf_stubs.h"
#else
#include "third_party/gles2_conform/GTF_ES/glsl/GTF/Source/eglNative.h"
#endif

GTFbool GTFNativeCreateDisplay(EGLNativeDisplayType *pNativeDisplay) {
  *pNativeDisplay = EGL_DEFAULT_DISPLAY;
  return GTFtrue;
}

void GTFNativeDestroyDisplay(EGLNativeDisplayType nativeDisplay) {
  // Nothing to destroy since we are using EGL_DEFAULT_DISPLAY
}

GTFbool GTFNativeCreateWindow(EGLNativeDisplayType nativeDisplay,
                              EGLDisplay eglDisplay, EGLConfig eglConfig,
                              const char* title, int width, int height,
                              EGLNativeWindowType *pNativeWindow) {
  egl::Display* display = static_cast<egl::Display*>(eglDisplay);
  display->SetCreateOffscreen(width, height);
  return GTFtrue;
}

void GTFNativeDestroyWindow(EGLNativeDisplayType nativeDisplay,
                            EGLNativeWindowType nativeWindow) {
}

EGLImageKHR GTFCreateEGLImage(int width, int height,
                              GLenum format, GLenum type) {
  return (EGLImageKHR)NULL;
}

void GTFDestroyEGLImage(EGLImageKHR image) {
}

}  // extern "C"

