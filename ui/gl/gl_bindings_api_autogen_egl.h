// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

EGLBoolean eglBindAPIFn(EGLenum api) override;
EGLBoolean eglBindTexImageFn(EGLDisplay dpy,
                             EGLSurface surface,
                             EGLint buffer) override;
EGLBoolean eglChooseConfigFn(EGLDisplay dpy,
                             const EGLint* attrib_list,
                             EGLConfig* configs,
                             EGLint config_size,
                             EGLint* num_config) override;
EGLint eglClientWaitSyncKHRFn(EGLDisplay dpy,
                              EGLSyncKHR sync,
                              EGLint flags,
                              EGLTimeKHR timeout) override;
EGLBoolean eglCopyBuffersFn(EGLDisplay dpy,
                            EGLSurface surface,
                            EGLNativePixmapType target) override;
EGLContext eglCreateContextFn(EGLDisplay dpy,
                              EGLConfig config,
                              EGLContext share_context,
                              const EGLint* attrib_list) override;
EGLImageKHR eglCreateImageKHRFn(EGLDisplay dpy,
                                EGLContext ctx,
                                EGLenum target,
                                EGLClientBuffer buffer,
                                const EGLint* attrib_list) override;
EGLSurface eglCreatePbufferFromClientBufferFn(
    EGLDisplay dpy,
    EGLenum buftype,
    void* buffer,
    EGLConfig config,
    const EGLint* attrib_list) override;
EGLSurface eglCreatePbufferSurfaceFn(EGLDisplay dpy,
                                     EGLConfig config,
                                     const EGLint* attrib_list) override;
EGLSurface eglCreatePixmapSurfaceFn(EGLDisplay dpy,
                                    EGLConfig config,
                                    EGLNativePixmapType pixmap,
                                    const EGLint* attrib_list) override;
EGLSyncKHR eglCreateSyncKHRFn(EGLDisplay dpy,
                              EGLenum type,
                              const EGLint* attrib_list) override;
EGLSurface eglCreateWindowSurfaceFn(EGLDisplay dpy,
                                    EGLConfig config,
                                    EGLNativeWindowType win,
                                    const EGLint* attrib_list) override;
EGLBoolean eglDestroyContextFn(EGLDisplay dpy, EGLContext ctx) override;
EGLBoolean eglDestroyImageKHRFn(EGLDisplay dpy, EGLImageKHR image) override;
EGLBoolean eglDestroySurfaceFn(EGLDisplay dpy, EGLSurface surface) override;
EGLBoolean eglDestroySyncKHRFn(EGLDisplay dpy, EGLSyncKHR sync) override;
EGLBoolean eglGetConfigAttribFn(EGLDisplay dpy,
                                EGLConfig config,
                                EGLint attribute,
                                EGLint* value) override;
EGLBoolean eglGetConfigsFn(EGLDisplay dpy,
                           EGLConfig* configs,
                           EGLint config_size,
                           EGLint* num_config) override;
EGLContext eglGetCurrentContextFn(void) override;
EGLDisplay eglGetCurrentDisplayFn(void) override;
EGLSurface eglGetCurrentSurfaceFn(EGLint readdraw) override;
EGLDisplay eglGetDisplayFn(EGLNativeDisplayType display_id) override;
EGLint eglGetErrorFn(void) override;
EGLDisplay eglGetPlatformDisplayEXTFn(EGLenum platform,
                                      void* native_display,
                                      const EGLint* attrib_list) override;
__eglMustCastToProperFunctionPointerType eglGetProcAddressFn(
    const char* procname) override;
EGLBoolean eglGetSyncAttribKHRFn(EGLDisplay dpy,
                                 EGLSyncKHR sync,
                                 EGLint attribute,
                                 EGLint* value) override;
EGLBoolean eglGetSyncValuesCHROMIUMFn(EGLDisplay dpy,
                                      EGLSurface surface,
                                      EGLuint64CHROMIUM* ust,
                                      EGLuint64CHROMIUM* msc,
                                      EGLuint64CHROMIUM* sbc) override;
EGLBoolean eglInitializeFn(EGLDisplay dpy,
                           EGLint* major,
                           EGLint* minor) override;
EGLBoolean eglMakeCurrentFn(EGLDisplay dpy,
                            EGLSurface draw,
                            EGLSurface read,
                            EGLContext ctx) override;
EGLBoolean eglPostSubBufferNVFn(EGLDisplay dpy,
                                EGLSurface surface,
                                EGLint x,
                                EGLint y,
                                EGLint width,
                                EGLint height) override;
EGLenum eglQueryAPIFn(void) override;
EGLBoolean eglQueryContextFn(EGLDisplay dpy,
                             EGLContext ctx,
                             EGLint attribute,
                             EGLint* value) override;
const char* eglQueryStringFn(EGLDisplay dpy, EGLint name) override;
EGLBoolean eglQuerySurfaceFn(EGLDisplay dpy,
                             EGLSurface surface,
                             EGLint attribute,
                             EGLint* value) override;
EGLBoolean eglQuerySurfacePointerANGLEFn(EGLDisplay dpy,
                                         EGLSurface surface,
                                         EGLint attribute,
                                         void** value) override;
EGLBoolean eglReleaseTexImageFn(EGLDisplay dpy,
                                EGLSurface surface,
                                EGLint buffer) override;
EGLBoolean eglReleaseThreadFn(void) override;
EGLBoolean eglSurfaceAttribFn(EGLDisplay dpy,
                              EGLSurface surface,
                              EGLint attribute,
                              EGLint value) override;
EGLBoolean eglSwapBuffersFn(EGLDisplay dpy, EGLSurface surface) override;
EGLBoolean eglSwapIntervalFn(EGLDisplay dpy, EGLint interval) override;
EGLBoolean eglTerminateFn(EGLDisplay dpy) override;
EGLBoolean eglWaitClientFn(void) override;
EGLBoolean eglWaitGLFn(void) override;
EGLBoolean eglWaitNativeFn(EGLint engine) override;
EGLint eglWaitSyncKHRFn(EGLDisplay dpy, EGLSyncKHR sync, EGLint flags) override;
