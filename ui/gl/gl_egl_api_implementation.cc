// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_egl_api_implementation.h"
#include "ui/gl/gl_implementation.h"

namespace gfx {

RealEGLApi* g_real_egl;

void InitializeStaticGLBindingsEGL() {
  if (!g_real_egl) {
    g_real_egl = new RealEGLApi();
  }
  g_real_egl->Initialize(&g_driver_egl);
  g_current_egl_context = g_real_egl;
  g_driver_egl.InitializeStaticBindings();
}

void InitializeDebugGLBindingsEGL() {
  g_driver_egl.InitializeDebugBindings();
}

void ClearGLBindingsEGL() {
  if (g_real_egl) {
    delete g_real_egl;
    g_real_egl = NULL;
  }
  g_current_egl_context = NULL;
  g_driver_egl.ClearBindings();
}

EGLApi::EGLApi() {
}

EGLApi::~EGLApi() {
}

EGLApiBase::EGLApiBase()
    : driver_(NULL) {
}

EGLApiBase::~EGLApiBase() {
}

void EGLApiBase::InitializeBase(DriverEGL* driver) {
  driver_ = driver;
}

RealEGLApi::RealEGLApi() {
}

RealEGLApi::~RealEGLApi() {
}

void RealEGLApi::Initialize(DriverEGL* driver) {
  InitializeBase(driver);
}

TraceEGLApi::~TraceEGLApi() {
}

bool GetGLWindowSystemBindingInfoEGL(GLWindowSystemBindingInfo* info) {
  EGLDisplay display = eglGetCurrentDisplay();
  const char* vendor = eglQueryString(display, EGL_VENDOR);
  const char* version = eglQueryString(display, EGL_VERSION);
  const char* extensions = eglQueryString(display, EGL_EXTENSIONS);
  *info = GLWindowSystemBindingInfo();
  if (vendor)
    info->vendor = vendor;
  if (version)
    info->version = version;
  if (extensions)
    info->extensions = extensions;
  return true;
}

}  // namespace gfx


