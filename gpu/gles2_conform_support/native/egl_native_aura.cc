// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is just a compile fix. If this is really needed when using aura, the
// methods below should be filled out.

#include <EGL/egl.h>
#include <EGL/eglext.h>

#include "base/logging.h"

extern "C" {
#if defined(GLES2_CONFORM_SUPPORT_ONLY)
#include "gpu/gles2_conform_support/gtf/gtf_stubs.h"
#else
#include "third_party/gles2_conform/GTF_ES/glsl/GTF/Source/eglNative.h"
#endif

GTFbool GTFNativeCreateDisplay(EGLNativeDisplayType *pNativeDisplay) {
  NOTIMPLEMENTED();
  return GTFfalse;
}

void GTFNativeDestroyDisplay(EGLNativeDisplayType nativeDisplay) {
  NOTIMPLEMENTED();
}

void GTFNativeDestroyWindow(EGLNativeDisplayType nativeDisplay,
                            EGLNativeWindowType nativeWindow) {
  NOTIMPLEMENTED();
}

GTFbool GTFNativeCreateWindow(EGLNativeDisplayType nativeDisplay,
                              EGLDisplay eglDisplay, EGLConfig eglConfig,
                              const char* title, int width, int height,
                              EGLNativeWindowType *pNativeWindow) {
  NOTIMPLEMENTED();
  return GTFfalse;
}

}  // extern "C"
