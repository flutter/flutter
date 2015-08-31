// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "build/build_config.h"

#if !defined(OS_ANDROID)
#error EGL should only be used on Android.
#endif
#include <EGL/egl.h>

#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_surface_egl.h"

namespace gfx {

std::string DriverOSMESA::GetPlatformExtensions() {
  return "";
}

std::string DriverEGL::GetPlatformExtensions() {
  EGLDisplay display =
    g_driver_egl.fn.eglGetDisplayFn(GetPlatformDefaultEGLNativeDisplay());

  DCHECK(g_driver_egl.fn.eglInitializeFn);
  g_driver_egl.fn.eglInitializeFn(display, NULL, NULL);
  DCHECK(g_driver_egl.fn.eglQueryStringFn);
  const char* str = g_driver_egl.fn.eglQueryStringFn(display, EGL_EXTENSIONS);
  return str ? std::string(str) : "";
}

}  // namespace gfx
