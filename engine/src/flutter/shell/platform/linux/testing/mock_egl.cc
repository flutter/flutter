// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <EGL/egl.h>

EGLBoolean eglBindAPI(EGLenum api) {
  return EGL_TRUE;
}

EGLBoolean eglChooseConfig(EGLDisplay dpy,
                           const EGLint* attrib_list,
                           EGLConfig* configs,
                           EGLint config_size,
                           EGLint* num_config) {
  return EGL_TRUE;
}

EGLContext eglCreateContext(EGLDisplay dpy,
                            EGLConfig config,
                            EGLContext share_context,
                            const EGLint* attrib_list) {
  return nullptr;
}

EGLSurface eglCreatePbufferSurface(EGLDisplay dpy,
                                   EGLConfig config,
                                   const EGLint* attrib_list) {
  return nullptr;
}

EGLSurface eglCreateWindowSurface(EGLDisplay dpy,
                                  EGLConfig config,
                                  EGLNativeWindowType win,
                                  const EGLint* attrib_list) {
  return nullptr;
}

EGLDisplay eglGetDisplay(EGLNativeDisplayType display_id) {
  return nullptr;
}

EGLint eglGetError() {
  return EGL_SUCCESS;
}

void (*eglGetProcAddress(const char* procname))(void) {
  return nullptr;
}

EGLBoolean eglInitialize(EGLDisplay dpy, EGLint* major, EGLint* minor) {
  if (major != nullptr)
    *major = 1;
  if (minor != nullptr)
    *major = 5;
  return EGL_TRUE;
}

EGLBoolean eglMakeCurrent(EGLDisplay dpy,
                          EGLSurface draw,
                          EGLSurface read,
                          EGLContext ctx) {
  return EGL_TRUE;
}

EGLBoolean eglQueryContext(EGLDisplay dpy,
                           EGLContext ctx,
                           EGLint attribute,
                           EGLint* value) {
  return EGL_TRUE;
}

EGLBoolean eglSwapBuffers(EGLDisplay dpy, EGLSurface surface) {
  return EGL_TRUE;
}
