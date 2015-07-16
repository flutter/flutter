// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if defined(USE_X11) || defined(OS_ANDROID) || defined(USE_OZONE)
#include <EGL/egl.h>
#endif

#include "ui/gl/gl_bindings.h"

#if defined(USE_X11)
#include "ui/gfx/x/x11_types.h"
#endif

#if defined(USE_X11) || defined(OS_ANDROID) || defined(USE_OZONE)
#include "ui/gl/gl_surface_egl.h"
#endif

namespace gfx {

std::string DriverOSMESA::GetPlatformExtensions() {
  return "";
}

#if defined(USE_X11) || defined(OS_ANDROID) || defined(USE_OZONE)
std::string DriverEGL::GetPlatformExtensions() {
  EGLDisplay display =
    g_driver_egl.fn.eglGetDisplayFn(GetPlatformDefaultEGLNativeDisplay());

  DCHECK(g_driver_egl.fn.eglInitializeFn);
  g_driver_egl.fn.eglInitializeFn(display, NULL, NULL);
  DCHECK(g_driver_egl.fn.eglQueryStringFn);
  const char* str = g_driver_egl.fn.eglQueryStringFn(display, EGL_EXTENSIONS);
  return str ? std::string(str) : "";
}
#endif

#if defined(USE_X11)
std::string DriverGLX::GetPlatformExtensions() {
  DCHECK(g_driver_glx.fn.glXQueryExtensionsStringFn);
  const char* str =
      g_driver_glx.fn.glXQueryExtensionsStringFn(gfx::GetXDisplay(), 0);
  return str ? std::string(str) : "";
}
#endif

}  // namespace gfx
