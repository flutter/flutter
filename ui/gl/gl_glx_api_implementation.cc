// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_glx_api_implementation.h"
#include "ui/gl/gl_implementation.h"

namespace gfx {

RealGLXApi* g_real_glx;

void InitializeStaticGLBindingsGLX() {
  g_driver_glx.InitializeStaticBindings();
  if (!g_real_glx) {
    g_real_glx = new RealGLXApi();
  }
  g_real_glx->Initialize(&g_driver_glx);
  g_current_glx_context = g_real_glx;
}

void InitializeDebugGLBindingsGLX() {
  g_driver_glx.InitializeDebugBindings();
}

void ClearGLBindingsGLX() {
  if (g_real_glx) {
    delete g_real_glx;
    g_real_glx = NULL;
  }
  g_current_glx_context = NULL;
  g_driver_glx.ClearBindings();
}

GLXApi::GLXApi() {
}

GLXApi::~GLXApi() {
}

GLXApiBase::GLXApiBase()
    : driver_(NULL) {
}

GLXApiBase::~GLXApiBase() {
}

void GLXApiBase::InitializeBase(DriverGLX* driver) {
  driver_ = driver;
}

RealGLXApi::RealGLXApi() {
}

RealGLXApi::~RealGLXApi() {
}

void RealGLXApi::Initialize(DriverGLX* driver) {
  InitializeBase(driver);
}

TraceGLXApi::~TraceGLXApi() {
}

bool GetGLWindowSystemBindingInfoGLX(GLWindowSystemBindingInfo* info) {
  Display* display = glXGetCurrentDisplay();
  const int kDefaultScreen = 0;
  const char* vendor =
      glXQueryServerString(display, kDefaultScreen, GLX_VENDOR);
  const char* version =
      glXQueryServerString(display, kDefaultScreen, GLX_VERSION);
  const char* extensions =
      glXQueryServerString(display, kDefaultScreen, GLX_EXTENSIONS);
  *info = GLWindowSystemBindingInfo();
  if (vendor)
    info->vendor = vendor;
  if (version)
    info->version = version;
  if (extensions)
    info->extensions = extensions;
  info->direct_rendering = !!glXIsDirect(display, glXGetCurrentContext());
  return true;
}

}  // namespace gfx


