// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_fence_egl.h"

#include "ui/gl/egl_util.h"
#include "ui/gl/gl_bindings.h"

namespace gfx {

namespace {

bool g_ignore_egl_sync_failures = false;

}  // namespace

// static
void GLFenceEGL::SetIgnoreFailures() {
  g_ignore_egl_sync_failures = true;
}

GLFenceEGL::GLFenceEGL() {
  display_ = eglGetCurrentDisplay();
  sync_ = eglCreateSyncKHR(display_, EGL_SYNC_FENCE_KHR, NULL);
  DCHECK(sync_ != EGL_NO_SYNC_KHR);
  glFlush();
}

bool GLFenceEGL::HasCompleted() {
  EGLint value = 0;
  if (eglGetSyncAttribKHR(display_, sync_, EGL_SYNC_STATUS_KHR, &value) !=
      EGL_TRUE) {
    LOG(ERROR) << "Failed to get EGLSync attribute. error code:"
               << eglGetError();
    return true;
  }

  DCHECK(value == EGL_SIGNALED_KHR || value == EGL_UNSIGNALED_KHR);
  return !value || value == EGL_SIGNALED_KHR;
}

void GLFenceEGL::ClientWait() {
  EGLint flags = 0;
  EGLTimeKHR time = EGL_FOREVER_KHR;
  EGLint result = eglClientWaitSyncKHR(display_, sync_, flags, time);
  DCHECK_IMPLIES(!g_ignore_egl_sync_failures,
                 EGL_TIMEOUT_EXPIRED_KHR != result);
  if (result == EGL_FALSE) {
    LOG(ERROR) << "Failed to wait for EGLSync. error:"
               << ui::GetLastEGLErrorString();
    CHECK(g_ignore_egl_sync_failures);
  }
}

void GLFenceEGL::ServerWait() {
  if (!gfx::g_driver_egl.ext.b_EGL_KHR_wait_sync) {
    ClientWait();
    return;
  }
  EGLint flags = 0;
  if (eglWaitSyncKHR(display_, sync_, flags) == EGL_FALSE) {
    LOG(ERROR) << "Failed to wait for EGLSync. error:"
               << ui::GetLastEGLErrorString();
    CHECK(g_ignore_egl_sync_failures);
  }
}

GLFenceEGL::~GLFenceEGL() {
  eglDestroySyncKHR(display_, sync_);
}

}  // namespace gfx
