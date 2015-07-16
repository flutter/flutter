// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

#ifndef UI_GFX_GL_GL_BINDINGS_AUTOGEN_EGL_H_
#define UI_GFX_GL_GL_BINDINGS_AUTOGEN_EGL_H_

namespace gfx {

class GLContext;

typedef EGLBoolean(GL_BINDING_CALL* eglBindAPIProc)(EGLenum api);
typedef EGLBoolean(GL_BINDING_CALL* eglBindTexImageProc)(EGLDisplay dpy,
                                                         EGLSurface surface,
                                                         EGLint buffer);
typedef EGLBoolean(GL_BINDING_CALL* eglChooseConfigProc)(
    EGLDisplay dpy,
    const EGLint* attrib_list,
    EGLConfig* configs,
    EGLint config_size,
    EGLint* num_config);
typedef EGLint(GL_BINDING_CALL* eglClientWaitSyncKHRProc)(EGLDisplay dpy,
                                                          EGLSyncKHR sync,
                                                          EGLint flags,
                                                          EGLTimeKHR timeout);
typedef EGLBoolean(GL_BINDING_CALL* eglCopyBuffersProc)(
    EGLDisplay dpy,
    EGLSurface surface,
    EGLNativePixmapType target);
typedef EGLContext(GL_BINDING_CALL* eglCreateContextProc)(
    EGLDisplay dpy,
    EGLConfig config,
    EGLContext share_context,
    const EGLint* attrib_list);
typedef EGLImageKHR(GL_BINDING_CALL* eglCreateImageKHRProc)(
    EGLDisplay dpy,
    EGLContext ctx,
    EGLenum target,
    EGLClientBuffer buffer,
    const EGLint* attrib_list);
typedef EGLSurface(GL_BINDING_CALL* eglCreatePbufferFromClientBufferProc)(
    EGLDisplay dpy,
    EGLenum buftype,
    void* buffer,
    EGLConfig config,
    const EGLint* attrib_list);
typedef EGLSurface(GL_BINDING_CALL* eglCreatePbufferSurfaceProc)(
    EGLDisplay dpy,
    EGLConfig config,
    const EGLint* attrib_list);
typedef EGLSurface(GL_BINDING_CALL* eglCreatePixmapSurfaceProc)(
    EGLDisplay dpy,
    EGLConfig config,
    EGLNativePixmapType pixmap,
    const EGLint* attrib_list);
typedef EGLSyncKHR(GL_BINDING_CALL* eglCreateSyncKHRProc)(
    EGLDisplay dpy,
    EGLenum type,
    const EGLint* attrib_list);
typedef EGLSurface(GL_BINDING_CALL* eglCreateWindowSurfaceProc)(
    EGLDisplay dpy,
    EGLConfig config,
    EGLNativeWindowType win,
    const EGLint* attrib_list);
typedef EGLBoolean(GL_BINDING_CALL* eglDestroyContextProc)(EGLDisplay dpy,
                                                           EGLContext ctx);
typedef EGLBoolean(GL_BINDING_CALL* eglDestroyImageKHRProc)(EGLDisplay dpy,
                                                            EGLImageKHR image);
typedef EGLBoolean(GL_BINDING_CALL* eglDestroySurfaceProc)(EGLDisplay dpy,
                                                           EGLSurface surface);
typedef EGLBoolean(GL_BINDING_CALL* eglDestroySyncKHRProc)(EGLDisplay dpy,
                                                           EGLSyncKHR sync);
typedef EGLBoolean(GL_BINDING_CALL* eglGetConfigAttribProc)(EGLDisplay dpy,
                                                            EGLConfig config,
                                                            EGLint attribute,
                                                            EGLint* value);
typedef EGLBoolean(GL_BINDING_CALL* eglGetConfigsProc)(EGLDisplay dpy,
                                                       EGLConfig* configs,
                                                       EGLint config_size,
                                                       EGLint* num_config);
typedef EGLContext(GL_BINDING_CALL* eglGetCurrentContextProc)(void);
typedef EGLDisplay(GL_BINDING_CALL* eglGetCurrentDisplayProc)(void);
typedef EGLSurface(GL_BINDING_CALL* eglGetCurrentSurfaceProc)(EGLint readdraw);
typedef EGLDisplay(GL_BINDING_CALL* eglGetDisplayProc)(
    EGLNativeDisplayType display_id);
typedef EGLint(GL_BINDING_CALL* eglGetErrorProc)(void);
typedef EGLDisplay(GL_BINDING_CALL* eglGetPlatformDisplayEXTProc)(
    EGLenum platform,
    void* native_display,
    const EGLint* attrib_list);
typedef __eglMustCastToProperFunctionPointerType(
    GL_BINDING_CALL* eglGetProcAddressProc)(const char* procname);
typedef EGLBoolean(GL_BINDING_CALL* eglGetSyncAttribKHRProc)(EGLDisplay dpy,
                                                             EGLSyncKHR sync,
                                                             EGLint attribute,
                                                             EGLint* value);
typedef EGLBoolean(GL_BINDING_CALL* eglGetSyncValuesCHROMIUMProc)(
    EGLDisplay dpy,
    EGLSurface surface,
    EGLuint64CHROMIUM* ust,
    EGLuint64CHROMIUM* msc,
    EGLuint64CHROMIUM* sbc);
typedef EGLBoolean(GL_BINDING_CALL* eglInitializeProc)(EGLDisplay dpy,
                                                       EGLint* major,
                                                       EGLint* minor);
typedef EGLBoolean(GL_BINDING_CALL* eglMakeCurrentProc)(EGLDisplay dpy,
                                                        EGLSurface draw,
                                                        EGLSurface read,
                                                        EGLContext ctx);
typedef EGLBoolean(GL_BINDING_CALL* eglPostSubBufferNVProc)(EGLDisplay dpy,
                                                            EGLSurface surface,
                                                            EGLint x,
                                                            EGLint y,
                                                            EGLint width,
                                                            EGLint height);
typedef EGLenum(GL_BINDING_CALL* eglQueryAPIProc)(void);
typedef EGLBoolean(GL_BINDING_CALL* eglQueryContextProc)(EGLDisplay dpy,
                                                         EGLContext ctx,
                                                         EGLint attribute,
                                                         EGLint* value);
typedef const char*(GL_BINDING_CALL* eglQueryStringProc)(EGLDisplay dpy,
                                                         EGLint name);
typedef EGLBoolean(GL_BINDING_CALL* eglQuerySurfaceProc)(EGLDisplay dpy,
                                                         EGLSurface surface,
                                                         EGLint attribute,
                                                         EGLint* value);
typedef EGLBoolean(GL_BINDING_CALL* eglQuerySurfacePointerANGLEProc)(
    EGLDisplay dpy,
    EGLSurface surface,
    EGLint attribute,
    void** value);
typedef EGLBoolean(GL_BINDING_CALL* eglReleaseTexImageProc)(EGLDisplay dpy,
                                                            EGLSurface surface,
                                                            EGLint buffer);
typedef EGLBoolean(GL_BINDING_CALL* eglReleaseThreadProc)(void);
typedef EGLBoolean(GL_BINDING_CALL* eglSurfaceAttribProc)(EGLDisplay dpy,
                                                          EGLSurface surface,
                                                          EGLint attribute,
                                                          EGLint value);
typedef EGLBoolean(GL_BINDING_CALL* eglSwapBuffersProc)(EGLDisplay dpy,
                                                        EGLSurface surface);
typedef EGLBoolean(GL_BINDING_CALL* eglSwapIntervalProc)(EGLDisplay dpy,
                                                         EGLint interval);
typedef EGLBoolean(GL_BINDING_CALL* eglTerminateProc)(EGLDisplay dpy);
typedef EGLBoolean(GL_BINDING_CALL* eglWaitClientProc)(void);
typedef EGLBoolean(GL_BINDING_CALL* eglWaitGLProc)(void);
typedef EGLBoolean(GL_BINDING_CALL* eglWaitNativeProc)(EGLint engine);
typedef EGLint(GL_BINDING_CALL* eglWaitSyncKHRProc)(EGLDisplay dpy,
                                                    EGLSyncKHR sync,
                                                    EGLint flags);

struct ExtensionsEGL {
  bool b_EGL_ANGLE_d3d_share_handle_client_buffer;
  bool b_EGL_ANGLE_platform_angle;
  bool b_EGL_ANGLE_query_surface_pointer;
  bool b_EGL_ANGLE_surface_d3d_texture_2d_share_handle;
  bool b_EGL_CHROMIUM_sync_control;
  bool b_EGL_KHR_fence_sync;
  bool b_EGL_KHR_gl_texture_2D_image;
  bool b_EGL_KHR_image;
  bool b_EGL_KHR_image_base;
  bool b_EGL_KHR_reusable_sync;
  bool b_EGL_KHR_wait_sync;
  bool b_EGL_NV_post_sub_buffer;
};

struct ProcsEGL {
  eglBindAPIProc eglBindAPIFn;
  eglBindTexImageProc eglBindTexImageFn;
  eglChooseConfigProc eglChooseConfigFn;
  eglClientWaitSyncKHRProc eglClientWaitSyncKHRFn;
  eglCopyBuffersProc eglCopyBuffersFn;
  eglCreateContextProc eglCreateContextFn;
  eglCreateImageKHRProc eglCreateImageKHRFn;
  eglCreatePbufferFromClientBufferProc eglCreatePbufferFromClientBufferFn;
  eglCreatePbufferSurfaceProc eglCreatePbufferSurfaceFn;
  eglCreatePixmapSurfaceProc eglCreatePixmapSurfaceFn;
  eglCreateSyncKHRProc eglCreateSyncKHRFn;
  eglCreateWindowSurfaceProc eglCreateWindowSurfaceFn;
  eglDestroyContextProc eglDestroyContextFn;
  eglDestroyImageKHRProc eglDestroyImageKHRFn;
  eglDestroySurfaceProc eglDestroySurfaceFn;
  eglDestroySyncKHRProc eglDestroySyncKHRFn;
  eglGetConfigAttribProc eglGetConfigAttribFn;
  eglGetConfigsProc eglGetConfigsFn;
  eglGetCurrentContextProc eglGetCurrentContextFn;
  eglGetCurrentDisplayProc eglGetCurrentDisplayFn;
  eglGetCurrentSurfaceProc eglGetCurrentSurfaceFn;
  eglGetDisplayProc eglGetDisplayFn;
  eglGetErrorProc eglGetErrorFn;
  eglGetPlatformDisplayEXTProc eglGetPlatformDisplayEXTFn;
  eglGetProcAddressProc eglGetProcAddressFn;
  eglGetSyncAttribKHRProc eglGetSyncAttribKHRFn;
  eglGetSyncValuesCHROMIUMProc eglGetSyncValuesCHROMIUMFn;
  eglInitializeProc eglInitializeFn;
  eglMakeCurrentProc eglMakeCurrentFn;
  eglPostSubBufferNVProc eglPostSubBufferNVFn;
  eglQueryAPIProc eglQueryAPIFn;
  eglQueryContextProc eglQueryContextFn;
  eglQueryStringProc eglQueryStringFn;
  eglQuerySurfaceProc eglQuerySurfaceFn;
  eglQuerySurfacePointerANGLEProc eglQuerySurfacePointerANGLEFn;
  eglReleaseTexImageProc eglReleaseTexImageFn;
  eglReleaseThreadProc eglReleaseThreadFn;
  eglSurfaceAttribProc eglSurfaceAttribFn;
  eglSwapBuffersProc eglSwapBuffersFn;
  eglSwapIntervalProc eglSwapIntervalFn;
  eglTerminateProc eglTerminateFn;
  eglWaitClientProc eglWaitClientFn;
  eglWaitGLProc eglWaitGLFn;
  eglWaitNativeProc eglWaitNativeFn;
  eglWaitSyncKHRProc eglWaitSyncKHRFn;
};

class GL_EXPORT EGLApi {
 public:
  EGLApi();
  virtual ~EGLApi();

  virtual EGLBoolean eglBindAPIFn(EGLenum api) = 0;
  virtual EGLBoolean eglBindTexImageFn(EGLDisplay dpy,
                                       EGLSurface surface,
                                       EGLint buffer) = 0;
  virtual EGLBoolean eglChooseConfigFn(EGLDisplay dpy,
                                       const EGLint* attrib_list,
                                       EGLConfig* configs,
                                       EGLint config_size,
                                       EGLint* num_config) = 0;
  virtual EGLint eglClientWaitSyncKHRFn(EGLDisplay dpy,
                                        EGLSyncKHR sync,
                                        EGLint flags,
                                        EGLTimeKHR timeout) = 0;
  virtual EGLBoolean eglCopyBuffersFn(EGLDisplay dpy,
                                      EGLSurface surface,
                                      EGLNativePixmapType target) = 0;
  virtual EGLContext eglCreateContextFn(EGLDisplay dpy,
                                        EGLConfig config,
                                        EGLContext share_context,
                                        const EGLint* attrib_list) = 0;
  virtual EGLImageKHR eglCreateImageKHRFn(EGLDisplay dpy,
                                          EGLContext ctx,
                                          EGLenum target,
                                          EGLClientBuffer buffer,
                                          const EGLint* attrib_list) = 0;
  virtual EGLSurface eglCreatePbufferFromClientBufferFn(
      EGLDisplay dpy,
      EGLenum buftype,
      void* buffer,
      EGLConfig config,
      const EGLint* attrib_list) = 0;
  virtual EGLSurface eglCreatePbufferSurfaceFn(EGLDisplay dpy,
                                               EGLConfig config,
                                               const EGLint* attrib_list) = 0;
  virtual EGLSurface eglCreatePixmapSurfaceFn(EGLDisplay dpy,
                                              EGLConfig config,
                                              EGLNativePixmapType pixmap,
                                              const EGLint* attrib_list) = 0;
  virtual EGLSyncKHR eglCreateSyncKHRFn(EGLDisplay dpy,
                                        EGLenum type,
                                        const EGLint* attrib_list) = 0;
  virtual EGLSurface eglCreateWindowSurfaceFn(EGLDisplay dpy,
                                              EGLConfig config,
                                              EGLNativeWindowType win,
                                              const EGLint* attrib_list) = 0;
  virtual EGLBoolean eglDestroyContextFn(EGLDisplay dpy, EGLContext ctx) = 0;
  virtual EGLBoolean eglDestroyImageKHRFn(EGLDisplay dpy,
                                          EGLImageKHR image) = 0;
  virtual EGLBoolean eglDestroySurfaceFn(EGLDisplay dpy,
                                         EGLSurface surface) = 0;
  virtual EGLBoolean eglDestroySyncKHRFn(EGLDisplay dpy, EGLSyncKHR sync) = 0;
  virtual EGLBoolean eglGetConfigAttribFn(EGLDisplay dpy,
                                          EGLConfig config,
                                          EGLint attribute,
                                          EGLint* value) = 0;
  virtual EGLBoolean eglGetConfigsFn(EGLDisplay dpy,
                                     EGLConfig* configs,
                                     EGLint config_size,
                                     EGLint* num_config) = 0;
  virtual EGLContext eglGetCurrentContextFn(void) = 0;
  virtual EGLDisplay eglGetCurrentDisplayFn(void) = 0;
  virtual EGLSurface eglGetCurrentSurfaceFn(EGLint readdraw) = 0;
  virtual EGLDisplay eglGetDisplayFn(EGLNativeDisplayType display_id) = 0;
  virtual EGLint eglGetErrorFn(void) = 0;
  virtual EGLDisplay eglGetPlatformDisplayEXTFn(EGLenum platform,
                                                void* native_display,
                                                const EGLint* attrib_list) = 0;
  virtual __eglMustCastToProperFunctionPointerType eglGetProcAddressFn(
      const char* procname) = 0;
  virtual EGLBoolean eglGetSyncAttribKHRFn(EGLDisplay dpy,
                                           EGLSyncKHR sync,
                                           EGLint attribute,
                                           EGLint* value) = 0;
  virtual EGLBoolean eglGetSyncValuesCHROMIUMFn(EGLDisplay dpy,
                                                EGLSurface surface,
                                                EGLuint64CHROMIUM* ust,
                                                EGLuint64CHROMIUM* msc,
                                                EGLuint64CHROMIUM* sbc) = 0;
  virtual EGLBoolean eglInitializeFn(EGLDisplay dpy,
                                     EGLint* major,
                                     EGLint* minor) = 0;
  virtual EGLBoolean eglMakeCurrentFn(EGLDisplay dpy,
                                      EGLSurface draw,
                                      EGLSurface read,
                                      EGLContext ctx) = 0;
  virtual EGLBoolean eglPostSubBufferNVFn(EGLDisplay dpy,
                                          EGLSurface surface,
                                          EGLint x,
                                          EGLint y,
                                          EGLint width,
                                          EGLint height) = 0;
  virtual EGLenum eglQueryAPIFn(void) = 0;
  virtual EGLBoolean eglQueryContextFn(EGLDisplay dpy,
                                       EGLContext ctx,
                                       EGLint attribute,
                                       EGLint* value) = 0;
  virtual const char* eglQueryStringFn(EGLDisplay dpy, EGLint name) = 0;
  virtual EGLBoolean eglQuerySurfaceFn(EGLDisplay dpy,
                                       EGLSurface surface,
                                       EGLint attribute,
                                       EGLint* value) = 0;
  virtual EGLBoolean eglQuerySurfacePointerANGLEFn(EGLDisplay dpy,
                                                   EGLSurface surface,
                                                   EGLint attribute,
                                                   void** value) = 0;
  virtual EGLBoolean eglReleaseTexImageFn(EGLDisplay dpy,
                                          EGLSurface surface,
                                          EGLint buffer) = 0;
  virtual EGLBoolean eglReleaseThreadFn(void) = 0;
  virtual EGLBoolean eglSurfaceAttribFn(EGLDisplay dpy,
                                        EGLSurface surface,
                                        EGLint attribute,
                                        EGLint value) = 0;
  virtual EGLBoolean eglSwapBuffersFn(EGLDisplay dpy, EGLSurface surface) = 0;
  virtual EGLBoolean eglSwapIntervalFn(EGLDisplay dpy, EGLint interval) = 0;
  virtual EGLBoolean eglTerminateFn(EGLDisplay dpy) = 0;
  virtual EGLBoolean eglWaitClientFn(void) = 0;
  virtual EGLBoolean eglWaitGLFn(void) = 0;
  virtual EGLBoolean eglWaitNativeFn(EGLint engine) = 0;
  virtual EGLint eglWaitSyncKHRFn(EGLDisplay dpy,
                                  EGLSyncKHR sync,
                                  EGLint flags) = 0;
};

}  // namespace gfx

#define eglBindAPI ::gfx::g_current_egl_context->eglBindAPIFn
#define eglBindTexImage ::gfx::g_current_egl_context->eglBindTexImageFn
#define eglChooseConfig ::gfx::g_current_egl_context->eglChooseConfigFn
#define eglClientWaitSyncKHR \
  ::gfx::g_current_egl_context->eglClientWaitSyncKHRFn
#define eglCopyBuffers ::gfx::g_current_egl_context->eglCopyBuffersFn
#define eglCreateContext ::gfx::g_current_egl_context->eglCreateContextFn
#define eglCreateImageKHR ::gfx::g_current_egl_context->eglCreateImageKHRFn
#define eglCreatePbufferFromClientBuffer \
  ::gfx::g_current_egl_context->eglCreatePbufferFromClientBufferFn
#define eglCreatePbufferSurface \
  ::gfx::g_current_egl_context->eglCreatePbufferSurfaceFn
#define eglCreatePixmapSurface \
  ::gfx::g_current_egl_context->eglCreatePixmapSurfaceFn
#define eglCreateSyncKHR ::gfx::g_current_egl_context->eglCreateSyncKHRFn
#define eglCreateWindowSurface \
  ::gfx::g_current_egl_context->eglCreateWindowSurfaceFn
#define eglDestroyContext ::gfx::g_current_egl_context->eglDestroyContextFn
#define eglDestroyImageKHR ::gfx::g_current_egl_context->eglDestroyImageKHRFn
#define eglDestroySurface ::gfx::g_current_egl_context->eglDestroySurfaceFn
#define eglDestroySyncKHR ::gfx::g_current_egl_context->eglDestroySyncKHRFn
#define eglGetConfigAttrib ::gfx::g_current_egl_context->eglGetConfigAttribFn
#define eglGetConfigs ::gfx::g_current_egl_context->eglGetConfigsFn
#define eglGetCurrentContext \
  ::gfx::g_current_egl_context->eglGetCurrentContextFn
#define eglGetCurrentDisplay \
  ::gfx::g_current_egl_context->eglGetCurrentDisplayFn
#define eglGetCurrentSurface \
  ::gfx::g_current_egl_context->eglGetCurrentSurfaceFn
#define eglGetDisplay ::gfx::g_current_egl_context->eglGetDisplayFn
#define eglGetError ::gfx::g_current_egl_context->eglGetErrorFn
#define eglGetPlatformDisplayEXT \
  ::gfx::g_current_egl_context->eglGetPlatformDisplayEXTFn
#define eglGetProcAddress ::gfx::g_current_egl_context->eglGetProcAddressFn
#define eglGetSyncAttribKHR ::gfx::g_current_egl_context->eglGetSyncAttribKHRFn
#define eglGetSyncValuesCHROMIUM \
  ::gfx::g_current_egl_context->eglGetSyncValuesCHROMIUMFn
#define eglInitialize ::gfx::g_current_egl_context->eglInitializeFn
#define eglMakeCurrent ::gfx::g_current_egl_context->eglMakeCurrentFn
#define eglPostSubBufferNV ::gfx::g_current_egl_context->eglPostSubBufferNVFn
#define eglQueryAPI ::gfx::g_current_egl_context->eglQueryAPIFn
#define eglQueryContext ::gfx::g_current_egl_context->eglQueryContextFn
#define eglQueryString ::gfx::g_current_egl_context->eglQueryStringFn
#define eglQuerySurface ::gfx::g_current_egl_context->eglQuerySurfaceFn
#define eglQuerySurfacePointerANGLE \
  ::gfx::g_current_egl_context->eglQuerySurfacePointerANGLEFn
#define eglReleaseTexImage ::gfx::g_current_egl_context->eglReleaseTexImageFn
#define eglReleaseThread ::gfx::g_current_egl_context->eglReleaseThreadFn
#define eglSurfaceAttrib ::gfx::g_current_egl_context->eglSurfaceAttribFn
#define eglSwapBuffers ::gfx::g_current_egl_context->eglSwapBuffersFn
#define eglSwapInterval ::gfx::g_current_egl_context->eglSwapIntervalFn
#define eglTerminate ::gfx::g_current_egl_context->eglTerminateFn
#define eglWaitClient ::gfx::g_current_egl_context->eglWaitClientFn
#define eglWaitGL ::gfx::g_current_egl_context->eglWaitGLFn
#define eglWaitNative ::gfx::g_current_egl_context->eglWaitNativeFn
#define eglWaitSyncKHR ::gfx::g_current_egl_context->eglWaitSyncKHRFn

#endif  //  UI_GFX_GL_GL_BINDINGS_AUTOGEN_EGL_H_
