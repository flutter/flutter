// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains Chromium-specific EGL extensions declarations.

#ifndef GPU_EGL_EGLEXTCHROMIUM_H_
#define GPU_EGL_EGLEXTCHROMIUM_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <EGL/eglplatform.h>

/* EGLSyncControlCHROMIUM requires 64-bit uint support */
#if KHRONOS_SUPPORT_INT64
#ifndef EGL_CHROMIUM_sync_control
#define EGL_CHROMIUM_sync_control 1
typedef khronos_uint64_t EGLuint64CHROMIUM;
#ifdef EGL_EGLEXT_PROTOTYPES
EGLAPI EGLBoolean EGLAPIENTRY eglGetSyncValuesCHROMIUM(
    EGLDisplay dpy, EGLSurface surface, EGLuint64CHROMIUM *ust,
    EGLuint64CHROMIUM *msc, EGLuint64CHROMIUM *sbc);
#endif /* EGL_EGLEXT_PROTOTYPES */
typedef EGLBoolean (EGLAPIENTRYP PFNEGLGETSYNCVALUESCHROMIUMPROC)
    (EGLDisplay dpy, EGLSurface surface, EGLuint64CHROMIUM *ust,
     EGLuint64CHROMIUM *msc, EGLuint64CHROMIUM *sbc);
#endif
#endif

#ifdef __cplusplus
}
#endif

#define  // GPU_EGL_EGLEXTCHROMIUM_H_
