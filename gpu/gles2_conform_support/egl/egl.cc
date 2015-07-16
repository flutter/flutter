// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <EGL/egl.h>

#include "base/command_line.h"
#include "gpu/command_buffer/client/gles2_lib.h"
#include "gpu/gles2_conform_support/egl/display.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_surface.h"

#if REGAL_STATIC_EGL
extern "C" {

typedef EGLContext RegalSystemContext;
#define REGAL_DECL
REGAL_DECL void RegalMakeCurrent( RegalSystemContext ctx );

}  // extern "C"
#endif

namespace {
void SetCurrentError(EGLint error_code) {
}

template<typename T>
T EglError(EGLint error_code, T return_value) {
  SetCurrentError(error_code);
  return return_value;
}

template<typename T>
T EglSuccess(T return_value) {
  SetCurrentError(EGL_SUCCESS);
  return return_value;
}

EGLint ValidateDisplay(EGLDisplay dpy) {
  if (dpy == EGL_NO_DISPLAY)
    return EGL_BAD_DISPLAY;

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->is_initialized())
    return EGL_NOT_INITIALIZED;

  return EGL_SUCCESS;
}

EGLint ValidateDisplayConfig(EGLDisplay dpy, EGLConfig config) {
  EGLint error_code = ValidateDisplay(dpy);
  if (error_code != EGL_SUCCESS)
    return error_code;

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->IsValidConfig(config))
    return EGL_BAD_CONFIG;

  return EGL_SUCCESS;
}

EGLint ValidateDisplaySurface(EGLDisplay dpy, EGLSurface surface) {
  EGLint error_code = ValidateDisplay(dpy);
  if (error_code != EGL_SUCCESS)
    return error_code;

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->IsValidSurface(surface))
    return EGL_BAD_SURFACE;

  return EGL_SUCCESS;
}

EGLint ValidateDisplayContext(EGLDisplay dpy, EGLContext context) {
  EGLint error_code = ValidateDisplay(dpy);
  if (error_code != EGL_SUCCESS)
    return error_code;

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->IsValidContext(context))
    return EGL_BAD_CONTEXT;

  return EGL_SUCCESS;
}
}  // namespace

extern "C" {
EGLint eglGetError() {
  // TODO(alokp): Fix me.
  return EGL_SUCCESS;
}

EGLDisplay eglGetDisplay(EGLNativeDisplayType display_id) {
  return new egl::Display(display_id);
}

EGLBoolean eglInitialize(EGLDisplay dpy, EGLint *major, EGLint *minor) {
  if (dpy == EGL_NO_DISPLAY)
    return EglError(EGL_BAD_DISPLAY, EGL_FALSE);

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->Initialize())
    return EglError(EGL_NOT_INITIALIZED, EGL_FALSE);

  int argc = 1;
  const char* const argv[] = {
    "dummy"
  };
  base::CommandLine::Init(argc, argv);
  gfx::GLSurface::InitializeOneOff();

  *major = 1;
  *minor = 4;
  return EglSuccess(EGL_TRUE);
}

EGLBoolean eglTerminate(EGLDisplay dpy) {
  EGLint error_code = ValidateDisplay(dpy);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, EGL_FALSE);

  egl::Display* display = static_cast<egl::Display*>(dpy);
  delete display;

  return EglSuccess(EGL_TRUE);
}

const char* eglQueryString(EGLDisplay dpy, EGLint name) {
  EGLint error_code = ValidateDisplay(dpy);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, static_cast<const char*>(NULL));

  switch (name) {
    case EGL_CLIENT_APIS:
      return EglSuccess("OpenGL_ES");
    case EGL_EXTENSIONS:
      return EglSuccess("");
    case EGL_VENDOR:
      return EglSuccess("Google Inc.");
    case EGL_VERSION:
      return EglSuccess("1.4");
    default:
      return EglError(EGL_BAD_PARAMETER, static_cast<const char*>(NULL));
  }
}

EGLBoolean eglChooseConfig(EGLDisplay dpy,
                           const EGLint* attrib_list,
                           EGLConfig* configs,
                           EGLint config_size,
                           EGLint* num_config) {
  EGLint error_code = ValidateDisplay(dpy);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, EGL_FALSE);

  if (num_config == NULL)
    return EglError(EGL_BAD_PARAMETER, EGL_FALSE);

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->ChooseConfigs(configs, config_size, num_config))
    return EglError(EGL_BAD_ATTRIBUTE, EGL_FALSE);

  return EglSuccess(EGL_TRUE);
}

EGLBoolean eglGetConfigs(EGLDisplay dpy,
                         EGLConfig* configs,
                         EGLint config_size,
                         EGLint* num_config) {
  EGLint error_code = ValidateDisplay(dpy);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, EGL_FALSE);

  if (num_config == NULL)
    return EglError(EGL_BAD_PARAMETER, EGL_FALSE);

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->GetConfigs(configs, config_size, num_config))
    return EglError(EGL_BAD_ATTRIBUTE, EGL_FALSE);

  return EglSuccess(EGL_TRUE);
}

EGLBoolean eglGetConfigAttrib(EGLDisplay dpy,
                              EGLConfig config,
                              EGLint attribute,
                              EGLint* value) {
  EGLint error_code = ValidateDisplayConfig(dpy, config);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, EGL_FALSE);

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->GetConfigAttrib(config, attribute, value))
    return EglError(EGL_BAD_ATTRIBUTE, EGL_FALSE);

  return EglSuccess(EGL_TRUE);
}

EGLSurface eglCreateWindowSurface(EGLDisplay dpy,
                                  EGLConfig config,
                                  EGLNativeWindowType win,
                                  const EGLint* attrib_list) {
  EGLint error_code = ValidateDisplayConfig(dpy, config);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, EGL_NO_SURFACE);

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->IsValidNativeWindow(win))
    return EglError(EGL_BAD_NATIVE_WINDOW, EGL_NO_SURFACE);

  EGLSurface surface = display->CreateWindowSurface(config, win, attrib_list);
  if (surface == EGL_NO_SURFACE)
    return EglError(EGL_BAD_ALLOC, EGL_NO_SURFACE);

  return EglSuccess(surface);
}

EGLSurface eglCreatePbufferSurface(EGLDisplay dpy,
                                   EGLConfig config,
                                   const EGLint* attrib_list) {
  return EGL_NO_SURFACE;
}

EGLSurface eglCreatePixmapSurface(EGLDisplay dpy,
                                  EGLConfig config,
                                  EGLNativePixmapType pixmap,
                                  const EGLint* attrib_list) {
  return EGL_NO_SURFACE;
}

EGLBoolean eglDestroySurface(EGLDisplay dpy,
                             EGLSurface surface) {
  EGLint error_code = ValidateDisplaySurface(dpy, surface);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, EGL_FALSE);

  egl::Display* display = static_cast<egl::Display*>(dpy);
  display->DestroySurface(surface);
  return EglSuccess(EGL_TRUE);
}

EGLBoolean eglQuerySurface(EGLDisplay dpy,
                           EGLSurface surface,
                           EGLint attribute,
                           EGLint* value) {
  return EGL_FALSE;
}

EGLBoolean eglBindAPI(EGLenum api) {
  return EGL_FALSE;
}

EGLenum eglQueryAPI() {
  return EGL_OPENGL_ES_API;
}

EGLBoolean eglWaitClient(void) {
  return EGL_FALSE;
}

EGLBoolean eglReleaseThread(void) {
  return EGL_FALSE;
}

EGLSurface eglCreatePbufferFromClientBuffer(EGLDisplay dpy,
                                            EGLenum buftype,
                                            EGLClientBuffer buffer,
                                            EGLConfig config,
                                            const EGLint* attrib_list) {
  return EGL_NO_SURFACE;
}

EGLBoolean eglSurfaceAttrib(EGLDisplay dpy,
                            EGLSurface surface,
                            EGLint attribute,
                            EGLint value) {
  return EGL_FALSE;
}

EGLBoolean eglBindTexImage(EGLDisplay dpy,
                           EGLSurface surface,
                           EGLint buffer) {
  return EGL_FALSE;
}

EGLBoolean eglReleaseTexImage(EGLDisplay dpy,
                              EGLSurface surface,
                              EGLint buffer) {
  return EGL_FALSE;
}

EGLBoolean eglSwapInterval(EGLDisplay dpy, EGLint interval) {
  return EGL_FALSE;
}

EGLContext eglCreateContext(EGLDisplay dpy,
                            EGLConfig config,
                            EGLContext share_context,
                            const EGLint* attrib_list) {
  EGLint error_code = ValidateDisplayConfig(dpy, config);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, EGL_NO_CONTEXT);

  if (share_context != EGL_NO_CONTEXT) {
    error_code = ValidateDisplayContext(dpy, share_context);
    if (error_code != EGL_SUCCESS)
      return EglError(error_code, EGL_NO_CONTEXT);
  }

  egl::Display* display = static_cast<egl::Display*>(dpy);
  EGLContext context = display->CreateContext(
      config, share_context, attrib_list);
  if (context == EGL_NO_CONTEXT)
    return EglError(EGL_BAD_ALLOC, EGL_NO_CONTEXT);

  return EglSuccess(context);
}

EGLBoolean eglDestroyContext(EGLDisplay dpy, EGLContext ctx) {
  EGLint error_code = ValidateDisplayContext(dpy, ctx);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, EGL_FALSE);

  egl::Display* display = static_cast<egl::Display*>(dpy);
  display->DestroyContext(ctx);
  return EGL_TRUE;
}

EGLBoolean eglMakeCurrent(EGLDisplay dpy,
                          EGLSurface draw,
                          EGLSurface read,
                          EGLContext ctx) {
  if (ctx != EGL_NO_CONTEXT) {
    EGLint error_code = ValidateDisplaySurface(dpy, draw);
    if (error_code != EGL_SUCCESS)
      return EglError(error_code, EGL_FALSE);
    error_code = ValidateDisplaySurface(dpy, read);
    if (error_code != EGL_SUCCESS)
      return EglError(error_code, EGL_FALSE);
    error_code = ValidateDisplayContext(dpy, ctx);
    if (error_code != EGL_SUCCESS)
      return EglError(error_code, EGL_FALSE);
  }

  egl::Display* display = static_cast<egl::Display*>(dpy);
  if (!display->MakeCurrent(draw, read, ctx))
    return EglError(EGL_CONTEXT_LOST, EGL_FALSE);

#if REGAL_STATIC_EGL
  RegalMakeCurrent(ctx);
#endif

  return EGL_TRUE;
}

EGLContext eglGetCurrentContext() {
  return EGL_NO_CONTEXT;
}

EGLSurface eglGetCurrentSurface(EGLint readdraw) {
  return EGL_NO_SURFACE;
}

EGLDisplay eglGetCurrentDisplay() {
  return EGL_NO_DISPLAY;
}

EGLBoolean eglQueryContext(EGLDisplay dpy,
                           EGLContext ctx,
                           EGLint attribute,
                           EGLint* value) {
  return EGL_FALSE;
}

EGLBoolean eglWaitGL() {
  return EGL_FALSE;
}

EGLBoolean eglWaitNative(EGLint engine) {
  return EGL_FALSE;
}

EGLBoolean eglSwapBuffers(EGLDisplay dpy, EGLSurface surface) {
  EGLint error_code = ValidateDisplaySurface(dpy, surface);
  if (error_code != EGL_SUCCESS)
    return EglError(error_code, EGL_FALSE);

  egl::Display* display = static_cast<egl::Display*>(dpy);
  display->SwapBuffers(surface);
  return EglSuccess(EGL_TRUE);
}

EGLBoolean eglCopyBuffers(EGLDisplay dpy,
                          EGLSurface surface,
                          EGLNativePixmapType target) {
  return EGL_FALSE;
}

/* Now, define eglGetProcAddress using the generic function ptr. type */
__eglMustCastToProperFunctionPointerType
eglGetProcAddress(const char* procname) {
  return gles2::GetGLFunctionPointer(procname);
}
}  // extern "C"
