// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

#include <string>

#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_egl_api_implementation.h"
#include "ui/gl/gl_enums.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_version_info.h"

namespace gfx {

static bool g_debugBindingsInitialized;
DriverEGL g_driver_egl;

void DriverEGL::InitializeStaticBindings() {
  fn.eglBindAPIFn =
      reinterpret_cast<eglBindAPIProc>(GetGLProcAddress("eglBindAPI"));
  fn.eglBindTexImageFn = reinterpret_cast<eglBindTexImageProc>(
      GetGLProcAddress("eglBindTexImage"));
  fn.eglChooseConfigFn = reinterpret_cast<eglChooseConfigProc>(
      GetGLProcAddress("eglChooseConfig"));
  fn.eglClientWaitSyncKHRFn = 0;
  fn.eglCopyBuffersFn =
      reinterpret_cast<eglCopyBuffersProc>(GetGLProcAddress("eglCopyBuffers"));
  fn.eglCreateContextFn = reinterpret_cast<eglCreateContextProc>(
      GetGLProcAddress("eglCreateContext"));
  fn.eglCreateImageKHRFn = 0;
  fn.eglCreatePbufferFromClientBufferFn =
      reinterpret_cast<eglCreatePbufferFromClientBufferProc>(
          GetGLProcAddress("eglCreatePbufferFromClientBuffer"));
  fn.eglCreatePbufferSurfaceFn = reinterpret_cast<eglCreatePbufferSurfaceProc>(
      GetGLProcAddress("eglCreatePbufferSurface"));
  fn.eglCreatePixmapSurfaceFn = reinterpret_cast<eglCreatePixmapSurfaceProc>(
      GetGLProcAddress("eglCreatePixmapSurface"));
  fn.eglCreateSyncKHRFn = 0;
  fn.eglCreateWindowSurfaceFn = reinterpret_cast<eglCreateWindowSurfaceProc>(
      GetGLProcAddress("eglCreateWindowSurface"));
  fn.eglDestroyContextFn = reinterpret_cast<eglDestroyContextProc>(
      GetGLProcAddress("eglDestroyContext"));
  fn.eglDestroyImageKHRFn = 0;
  fn.eglDestroySurfaceFn = reinterpret_cast<eglDestroySurfaceProc>(
      GetGLProcAddress("eglDestroySurface"));
  fn.eglDestroySyncKHRFn = 0;
  fn.eglGetConfigAttribFn = reinterpret_cast<eglGetConfigAttribProc>(
      GetGLProcAddress("eglGetConfigAttrib"));
  fn.eglGetConfigsFn =
      reinterpret_cast<eglGetConfigsProc>(GetGLProcAddress("eglGetConfigs"));
  fn.eglGetCurrentContextFn = reinterpret_cast<eglGetCurrentContextProc>(
      GetGLProcAddress("eglGetCurrentContext"));
  fn.eglGetCurrentDisplayFn = reinterpret_cast<eglGetCurrentDisplayProc>(
      GetGLProcAddress("eglGetCurrentDisplay"));
  fn.eglGetCurrentSurfaceFn = reinterpret_cast<eglGetCurrentSurfaceProc>(
      GetGLProcAddress("eglGetCurrentSurface"));
  fn.eglGetDisplayFn =
      reinterpret_cast<eglGetDisplayProc>(GetGLProcAddress("eglGetDisplay"));
  fn.eglGetErrorFn =
      reinterpret_cast<eglGetErrorProc>(GetGLProcAddress("eglGetError"));
  fn.eglGetPlatformDisplayEXTFn = 0;
  fn.eglGetProcAddressFn = reinterpret_cast<eglGetProcAddressProc>(
      GetGLProcAddress("eglGetProcAddress"));
  fn.eglGetSyncAttribKHRFn = 0;
  fn.eglGetSyncValuesCHROMIUMFn = 0;
  fn.eglInitializeFn =
      reinterpret_cast<eglInitializeProc>(GetGLProcAddress("eglInitialize"));
  fn.eglMakeCurrentFn =
      reinterpret_cast<eglMakeCurrentProc>(GetGLProcAddress("eglMakeCurrent"));
  fn.eglPostSubBufferNVFn = 0;
  fn.eglQueryAPIFn =
      reinterpret_cast<eglQueryAPIProc>(GetGLProcAddress("eglQueryAPI"));
  fn.eglQueryContextFn = reinterpret_cast<eglQueryContextProc>(
      GetGLProcAddress("eglQueryContext"));
  fn.eglQueryStringFn =
      reinterpret_cast<eglQueryStringProc>(GetGLProcAddress("eglQueryString"));
  fn.eglQuerySurfaceFn = reinterpret_cast<eglQuerySurfaceProc>(
      GetGLProcAddress("eglQuerySurface"));
  fn.eglQuerySurfacePointerANGLEFn = 0;
  fn.eglReleaseTexImageFn = reinterpret_cast<eglReleaseTexImageProc>(
      GetGLProcAddress("eglReleaseTexImage"));
  fn.eglReleaseThreadFn = reinterpret_cast<eglReleaseThreadProc>(
      GetGLProcAddress("eglReleaseThread"));
  fn.eglSurfaceAttribFn = reinterpret_cast<eglSurfaceAttribProc>(
      GetGLProcAddress("eglSurfaceAttrib"));
  fn.eglSwapBuffersFn =
      reinterpret_cast<eglSwapBuffersProc>(GetGLProcAddress("eglSwapBuffers"));
  fn.eglSwapIntervalFn = reinterpret_cast<eglSwapIntervalProc>(
      GetGLProcAddress("eglSwapInterval"));
  fn.eglTerminateFn =
      reinterpret_cast<eglTerminateProc>(GetGLProcAddress("eglTerminate"));
  fn.eglWaitClientFn =
      reinterpret_cast<eglWaitClientProc>(GetGLProcAddress("eglWaitClient"));
  fn.eglWaitGLFn =
      reinterpret_cast<eglWaitGLProc>(GetGLProcAddress("eglWaitGL"));
  fn.eglWaitNativeFn =
      reinterpret_cast<eglWaitNativeProc>(GetGLProcAddress("eglWaitNative"));
  fn.eglWaitSyncKHRFn = 0;
  std::string extensions(GetPlatformExtensions());
  extensions += " ";
  ALLOW_UNUSED_LOCAL(extensions);

  ext.b_EGL_ANGLE_d3d_share_handle_client_buffer =
      extensions.find("EGL_ANGLE_d3d_share_handle_client_buffer ") !=
      std::string::npos;
  ext.b_EGL_ANGLE_platform_angle =
      extensions.find("EGL_ANGLE_platform_angle ") != std::string::npos;
  ext.b_EGL_ANGLE_query_surface_pointer =
      extensions.find("EGL_ANGLE_query_surface_pointer ") != std::string::npos;
  ext.b_EGL_ANGLE_surface_d3d_texture_2d_share_handle =
      extensions.find("EGL_ANGLE_surface_d3d_texture_2d_share_handle ") !=
      std::string::npos;
  ext.b_EGL_CHROMIUM_sync_control =
      extensions.find("EGL_CHROMIUM_sync_control ") != std::string::npos;
  ext.b_EGL_KHR_fence_sync =
      extensions.find("EGL_KHR_fence_sync ") != std::string::npos;
  ext.b_EGL_KHR_gl_texture_2D_image =
      extensions.find("EGL_KHR_gl_texture_2D_image ") != std::string::npos;
  ext.b_EGL_KHR_image = extensions.find("EGL_KHR_image ") != std::string::npos;
  ext.b_EGL_KHR_image_base =
      extensions.find("EGL_KHR_image_base ") != std::string::npos;
  ext.b_EGL_KHR_reusable_sync =
      extensions.find("EGL_KHR_reusable_sync ") != std::string::npos;
  ext.b_EGL_KHR_wait_sync =
      extensions.find("EGL_KHR_wait_sync ") != std::string::npos;
  ext.b_EGL_NV_post_sub_buffer =
      extensions.find("EGL_NV_post_sub_buffer ") != std::string::npos;

  debug_fn.eglClientWaitSyncKHRFn = 0;
  if (ext.b_EGL_KHR_fence_sync || ext.b_EGL_KHR_reusable_sync) {
    fn.eglClientWaitSyncKHRFn = reinterpret_cast<eglClientWaitSyncKHRProc>(
        GetGLProcAddress("eglClientWaitSyncKHR"));
    DCHECK(fn.eglClientWaitSyncKHRFn);
  }

  debug_fn.eglCreateImageKHRFn = 0;
  if (ext.b_EGL_KHR_image || ext.b_EGL_KHR_image_base ||
      ext.b_EGL_KHR_gl_texture_2D_image) {
    fn.eglCreateImageKHRFn = reinterpret_cast<eglCreateImageKHRProc>(
        GetGLProcAddress("eglCreateImageKHR"));
    DCHECK(fn.eglCreateImageKHRFn);
  }

  debug_fn.eglCreateSyncKHRFn = 0;
  if (ext.b_EGL_KHR_fence_sync || ext.b_EGL_KHR_reusable_sync) {
    fn.eglCreateSyncKHRFn = reinterpret_cast<eglCreateSyncKHRProc>(
        GetGLProcAddress("eglCreateSyncKHR"));
    DCHECK(fn.eglCreateSyncKHRFn);
  }

  debug_fn.eglDestroyImageKHRFn = 0;
  if (ext.b_EGL_KHR_image || ext.b_EGL_KHR_image_base) {
    fn.eglDestroyImageKHRFn = reinterpret_cast<eglDestroyImageKHRProc>(
        GetGLProcAddress("eglDestroyImageKHR"));
    DCHECK(fn.eglDestroyImageKHRFn);
  }

  debug_fn.eglDestroySyncKHRFn = 0;
  if (ext.b_EGL_KHR_fence_sync || ext.b_EGL_KHR_reusable_sync) {
    fn.eglDestroySyncKHRFn = reinterpret_cast<eglDestroySyncKHRProc>(
        GetGLProcAddress("eglDestroySyncKHR"));
    DCHECK(fn.eglDestroySyncKHRFn);
  }

  debug_fn.eglGetPlatformDisplayEXTFn = 0;
  if (ext.b_EGL_ANGLE_platform_angle) {
    fn.eglGetPlatformDisplayEXTFn =
        reinterpret_cast<eglGetPlatformDisplayEXTProc>(
            GetGLProcAddress("eglGetPlatformDisplayEXT"));
    DCHECK(fn.eglGetPlatformDisplayEXTFn);
  }

  debug_fn.eglGetSyncAttribKHRFn = 0;
  if (ext.b_EGL_KHR_fence_sync || ext.b_EGL_KHR_reusable_sync) {
    fn.eglGetSyncAttribKHRFn = reinterpret_cast<eglGetSyncAttribKHRProc>(
        GetGLProcAddress("eglGetSyncAttribKHR"));
    DCHECK(fn.eglGetSyncAttribKHRFn);
  }

  debug_fn.eglGetSyncValuesCHROMIUMFn = 0;
  if (ext.b_EGL_CHROMIUM_sync_control) {
    fn.eglGetSyncValuesCHROMIUMFn =
        reinterpret_cast<eglGetSyncValuesCHROMIUMProc>(
            GetGLProcAddress("eglGetSyncValuesCHROMIUM"));
    DCHECK(fn.eglGetSyncValuesCHROMIUMFn);
  }

  debug_fn.eglPostSubBufferNVFn = 0;
  if (ext.b_EGL_NV_post_sub_buffer) {
    fn.eglPostSubBufferNVFn = reinterpret_cast<eglPostSubBufferNVProc>(
        GetGLProcAddress("eglPostSubBufferNV"));
    DCHECK(fn.eglPostSubBufferNVFn);
  }

  debug_fn.eglQuerySurfacePointerANGLEFn = 0;
  if (ext.b_EGL_ANGLE_query_surface_pointer) {
    fn.eglQuerySurfacePointerANGLEFn =
        reinterpret_cast<eglQuerySurfacePointerANGLEProc>(
            GetGLProcAddress("eglQuerySurfacePointerANGLE"));
    DCHECK(fn.eglQuerySurfacePointerANGLEFn);
  }

  debug_fn.eglWaitSyncKHRFn = 0;
  if (ext.b_EGL_KHR_wait_sync) {
    fn.eglWaitSyncKHRFn = reinterpret_cast<eglWaitSyncKHRProc>(
        GetGLProcAddress("eglWaitSyncKHR"));
    DCHECK(fn.eglWaitSyncKHRFn);
  }

  if (g_debugBindingsInitialized)
    InitializeDebugBindings();
}

extern "C" {

static EGLBoolean GL_BINDING_CALL Debug_eglBindAPI(EGLenum api) {
  GL_SERVICE_LOG("eglBindAPI"
                 << "(" << api << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglBindAPIFn(api);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglBindTexImage(EGLDisplay dpy, EGLSurface surface, EGLint buffer) {
  GL_SERVICE_LOG("eglBindTexImage"
                 << "(" << dpy << ", " << surface << ", " << buffer << ")");
  EGLBoolean result =
      g_driver_egl.debug_fn.eglBindTexImageFn(dpy, surface, buffer);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglChooseConfig(EGLDisplay dpy,
                      const EGLint* attrib_list,
                      EGLConfig* configs,
                      EGLint config_size,
                      EGLint* num_config) {
  GL_SERVICE_LOG("eglChooseConfig"
                 << "(" << dpy << ", " << static_cast<const void*>(attrib_list)
                 << ", " << static_cast<const void*>(configs) << ", "
                 << config_size << ", " << static_cast<const void*>(num_config)
                 << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglChooseConfigFn(
      dpy, attrib_list, configs, config_size, num_config);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLint GL_BINDING_CALL Debug_eglClientWaitSyncKHR(EGLDisplay dpy,
                                                         EGLSyncKHR sync,
                                                         EGLint flags,
                                                         EGLTimeKHR timeout) {
  GL_SERVICE_LOG("eglClientWaitSyncKHR"
                 << "(" << dpy << ", " << sync << ", " << flags << ", "
                 << timeout << ")");
  EGLint result =
      g_driver_egl.debug_fn.eglClientWaitSyncKHRFn(dpy, sync, flags, timeout);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglCopyBuffers(EGLDisplay dpy,
                     EGLSurface surface,
                     EGLNativePixmapType target) {
  GL_SERVICE_LOG("eglCopyBuffers"
                 << "(" << dpy << ", " << surface << ", " << target << ")");
  EGLBoolean result =
      g_driver_egl.debug_fn.eglCopyBuffersFn(dpy, surface, target);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLContext GL_BINDING_CALL
Debug_eglCreateContext(EGLDisplay dpy,
                       EGLConfig config,
                       EGLContext share_context,
                       const EGLint* attrib_list) {
  GL_SERVICE_LOG("eglCreateContext"
                 << "(" << dpy << ", " << config << ", " << share_context
                 << ", " << static_cast<const void*>(attrib_list) << ")");
  EGLContext result = g_driver_egl.debug_fn.eglCreateContextFn(
      dpy, config, share_context, attrib_list);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLImageKHR GL_BINDING_CALL
Debug_eglCreateImageKHR(EGLDisplay dpy,
                        EGLContext ctx,
                        EGLenum target,
                        EGLClientBuffer buffer,
                        const EGLint* attrib_list) {
  GL_SERVICE_LOG("eglCreateImageKHR"
                 << "(" << dpy << ", " << ctx << ", " << target << ", "
                 << buffer << ", " << static_cast<const void*>(attrib_list)
                 << ")");
  EGLImageKHR result = g_driver_egl.debug_fn.eglCreateImageKHRFn(
      dpy, ctx, target, buffer, attrib_list);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLSurface GL_BINDING_CALL
Debug_eglCreatePbufferFromClientBuffer(EGLDisplay dpy,
                                       EGLenum buftype,
                                       void* buffer,
                                       EGLConfig config,
                                       const EGLint* attrib_list) {
  GL_SERVICE_LOG("eglCreatePbufferFromClientBuffer"
                 << "(" << dpy << ", " << buftype << ", "
                 << static_cast<const void*>(buffer) << ", " << config << ", "
                 << static_cast<const void*>(attrib_list) << ")");
  EGLSurface result = g_driver_egl.debug_fn.eglCreatePbufferFromClientBufferFn(
      dpy, buftype, buffer, config, attrib_list);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLSurface GL_BINDING_CALL
Debug_eglCreatePbufferSurface(EGLDisplay dpy,
                              EGLConfig config,
                              const EGLint* attrib_list) {
  GL_SERVICE_LOG("eglCreatePbufferSurface"
                 << "(" << dpy << ", " << config << ", "
                 << static_cast<const void*>(attrib_list) << ")");
  EGLSurface result =
      g_driver_egl.debug_fn.eglCreatePbufferSurfaceFn(dpy, config, attrib_list);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLSurface GL_BINDING_CALL
Debug_eglCreatePixmapSurface(EGLDisplay dpy,
                             EGLConfig config,
                             EGLNativePixmapType pixmap,
                             const EGLint* attrib_list) {
  GL_SERVICE_LOG("eglCreatePixmapSurface"
                 << "(" << dpy << ", " << config << ", " << pixmap << ", "
                 << static_cast<const void*>(attrib_list) << ")");
  EGLSurface result = g_driver_egl.debug_fn.eglCreatePixmapSurfaceFn(
      dpy, config, pixmap, attrib_list);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLSyncKHR GL_BINDING_CALL
Debug_eglCreateSyncKHR(EGLDisplay dpy,
                       EGLenum type,
                       const EGLint* attrib_list) {
  GL_SERVICE_LOG("eglCreateSyncKHR"
                 << "(" << dpy << ", " << type << ", "
                 << static_cast<const void*>(attrib_list) << ")");
  EGLSyncKHR result =
      g_driver_egl.debug_fn.eglCreateSyncKHRFn(dpy, type, attrib_list);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLSurface GL_BINDING_CALL
Debug_eglCreateWindowSurface(EGLDisplay dpy,
                             EGLConfig config,
                             EGLNativeWindowType win,
                             const EGLint* attrib_list) {
  GL_SERVICE_LOG("eglCreateWindowSurface"
                 << "(" << dpy << ", " << config << ", " << win << ", "
                 << static_cast<const void*>(attrib_list) << ")");
  EGLSurface result = g_driver_egl.debug_fn.eglCreateWindowSurfaceFn(
      dpy, config, win, attrib_list);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglDestroyContext(EGLDisplay dpy, EGLContext ctx) {
  GL_SERVICE_LOG("eglDestroyContext"
                 << "(" << dpy << ", " << ctx << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglDestroyContextFn(dpy, ctx);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglDestroyImageKHR(EGLDisplay dpy, EGLImageKHR image) {
  GL_SERVICE_LOG("eglDestroyImageKHR"
                 << "(" << dpy << ", " << image << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglDestroyImageKHRFn(dpy, image);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglDestroySurface(EGLDisplay dpy, EGLSurface surface) {
  GL_SERVICE_LOG("eglDestroySurface"
                 << "(" << dpy << ", " << surface << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglDestroySurfaceFn(dpy, surface);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglDestroySyncKHR(EGLDisplay dpy, EGLSyncKHR sync) {
  GL_SERVICE_LOG("eglDestroySyncKHR"
                 << "(" << dpy << ", " << sync << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglDestroySyncKHRFn(dpy, sync);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglGetConfigAttrib(EGLDisplay dpy,
                                                           EGLConfig config,
                                                           EGLint attribute,
                                                           EGLint* value) {
  GL_SERVICE_LOG("eglGetConfigAttrib"
                 << "(" << dpy << ", " << config << ", " << attribute << ", "
                 << static_cast<const void*>(value) << ")");
  EGLBoolean result =
      g_driver_egl.debug_fn.eglGetConfigAttribFn(dpy, config, attribute, value);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglGetConfigs(EGLDisplay dpy,
                                                      EGLConfig* configs,
                                                      EGLint config_size,
                                                      EGLint* num_config) {
  GL_SERVICE_LOG("eglGetConfigs"
                 << "(" << dpy << ", " << static_cast<const void*>(configs)
                 << ", " << config_size << ", "
                 << static_cast<const void*>(num_config) << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglGetConfigsFn(
      dpy, configs, config_size, num_config);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLContext GL_BINDING_CALL Debug_eglGetCurrentContext(void) {
  GL_SERVICE_LOG("eglGetCurrentContext"
                 << "("
                 << ")");
  EGLContext result = g_driver_egl.debug_fn.eglGetCurrentContextFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLDisplay GL_BINDING_CALL Debug_eglGetCurrentDisplay(void) {
  GL_SERVICE_LOG("eglGetCurrentDisplay"
                 << "("
                 << ")");
  EGLDisplay result = g_driver_egl.debug_fn.eglGetCurrentDisplayFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLSurface GL_BINDING_CALL Debug_eglGetCurrentSurface(EGLint readdraw) {
  GL_SERVICE_LOG("eglGetCurrentSurface"
                 << "(" << readdraw << ")");
  EGLSurface result = g_driver_egl.debug_fn.eglGetCurrentSurfaceFn(readdraw);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLDisplay GL_BINDING_CALL
Debug_eglGetDisplay(EGLNativeDisplayType display_id) {
  GL_SERVICE_LOG("eglGetDisplay"
                 << "(" << display_id << ")");
  EGLDisplay result = g_driver_egl.debug_fn.eglGetDisplayFn(display_id);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLint GL_BINDING_CALL Debug_eglGetError(void) {
  GL_SERVICE_LOG("eglGetError"
                 << "("
                 << ")");
  EGLint result = g_driver_egl.debug_fn.eglGetErrorFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLDisplay GL_BINDING_CALL
Debug_eglGetPlatformDisplayEXT(EGLenum platform,
                               void* native_display,
                               const EGLint* attrib_list) {
  GL_SERVICE_LOG("eglGetPlatformDisplayEXT"
                 << "(" << platform << ", "
                 << static_cast<const void*>(native_display) << ", "
                 << static_cast<const void*>(attrib_list) << ")");
  EGLDisplay result = g_driver_egl.debug_fn.eglGetPlatformDisplayEXTFn(
      platform, native_display, attrib_list);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static __eglMustCastToProperFunctionPointerType GL_BINDING_CALL
Debug_eglGetProcAddress(const char* procname) {
  GL_SERVICE_LOG("eglGetProcAddress"
                 << "(" << procname << ")");
  __eglMustCastToProperFunctionPointerType result =
      g_driver_egl.debug_fn.eglGetProcAddressFn(procname);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglGetSyncAttribKHR(EGLDisplay dpy,
                                                            EGLSyncKHR sync,
                                                            EGLint attribute,
                                                            EGLint* value) {
  GL_SERVICE_LOG("eglGetSyncAttribKHR"
                 << "(" << dpy << ", " << sync << ", " << attribute << ", "
                 << static_cast<const void*>(value) << ")");
  EGLBoolean result =
      g_driver_egl.debug_fn.eglGetSyncAttribKHRFn(dpy, sync, attribute, value);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglGetSyncValuesCHROMIUM(EGLDisplay dpy,
                               EGLSurface surface,
                               EGLuint64CHROMIUM* ust,
                               EGLuint64CHROMIUM* msc,
                               EGLuint64CHROMIUM* sbc) {
  GL_SERVICE_LOG("eglGetSyncValuesCHROMIUM"
                 << "(" << dpy << ", " << surface << ", "
                 << static_cast<const void*>(ust) << ", "
                 << static_cast<const void*>(msc) << ", "
                 << static_cast<const void*>(sbc) << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglGetSyncValuesCHROMIUMFn(
      dpy, surface, ust, msc, sbc);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglInitialize(EGLDisplay dpy, EGLint* major, EGLint* minor) {
  GL_SERVICE_LOG("eglInitialize"
                 << "(" << dpy << ", " << static_cast<const void*>(major)
                 << ", " << static_cast<const void*>(minor) << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglInitializeFn(dpy, major, minor);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglMakeCurrent(EGLDisplay dpy,
                                                       EGLSurface draw,
                                                       EGLSurface read,
                                                       EGLContext ctx) {
  GL_SERVICE_LOG("eglMakeCurrent"
                 << "(" << dpy << ", " << draw << ", " << read << ", " << ctx
                 << ")");
  EGLBoolean result =
      g_driver_egl.debug_fn.eglMakeCurrentFn(dpy, draw, read, ctx);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglPostSubBufferNV(EGLDisplay dpy,
                                                           EGLSurface surface,
                                                           EGLint x,
                                                           EGLint y,
                                                           EGLint width,
                                                           EGLint height) {
  GL_SERVICE_LOG("eglPostSubBufferNV"
                 << "(" << dpy << ", " << surface << ", " << x << ", " << y
                 << ", " << width << ", " << height << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglPostSubBufferNVFn(
      dpy, surface, x, y, width, height);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLenum GL_BINDING_CALL Debug_eglQueryAPI(void) {
  GL_SERVICE_LOG("eglQueryAPI"
                 << "("
                 << ")");
  EGLenum result = g_driver_egl.debug_fn.eglQueryAPIFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglQueryContext(EGLDisplay dpy,
                                                        EGLContext ctx,
                                                        EGLint attribute,
                                                        EGLint* value) {
  GL_SERVICE_LOG("eglQueryContext"
                 << "(" << dpy << ", " << ctx << ", " << attribute << ", "
                 << static_cast<const void*>(value) << ")");
  EGLBoolean result =
      g_driver_egl.debug_fn.eglQueryContextFn(dpy, ctx, attribute, value);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static const char* GL_BINDING_CALL
Debug_eglQueryString(EGLDisplay dpy, EGLint name) {
  GL_SERVICE_LOG("eglQueryString"
                 << "(" << dpy << ", " << name << ")");
  const char* result = g_driver_egl.debug_fn.eglQueryStringFn(dpy, name);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglQuerySurface(EGLDisplay dpy,
                                                        EGLSurface surface,
                                                        EGLint attribute,
                                                        EGLint* value) {
  GL_SERVICE_LOG("eglQuerySurface"
                 << "(" << dpy << ", " << surface << ", " << attribute << ", "
                 << static_cast<const void*>(value) << ")");
  EGLBoolean result =
      g_driver_egl.debug_fn.eglQuerySurfaceFn(dpy, surface, attribute, value);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglQuerySurfacePointerANGLE(EGLDisplay dpy,
                                  EGLSurface surface,
                                  EGLint attribute,
                                  void** value) {
  GL_SERVICE_LOG("eglQuerySurfacePointerANGLE"
                 << "(" << dpy << ", " << surface << ", " << attribute << ", "
                 << value << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglQuerySurfacePointerANGLEFn(
      dpy, surface, attribute, value);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglReleaseTexImage(EGLDisplay dpy, EGLSurface surface, EGLint buffer) {
  GL_SERVICE_LOG("eglReleaseTexImage"
                 << "(" << dpy << ", " << surface << ", " << buffer << ")");
  EGLBoolean result =
      g_driver_egl.debug_fn.eglReleaseTexImageFn(dpy, surface, buffer);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglReleaseThread(void) {
  GL_SERVICE_LOG("eglReleaseThread"
                 << "("
                 << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglReleaseThreadFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglSurfaceAttrib(EGLDisplay dpy,
                                                         EGLSurface surface,
                                                         EGLint attribute,
                                                         EGLint value) {
  GL_SERVICE_LOG("eglSurfaceAttrib"
                 << "(" << dpy << ", " << surface << ", " << attribute << ", "
                 << value << ")");
  EGLBoolean result =
      g_driver_egl.debug_fn.eglSurfaceAttribFn(dpy, surface, attribute, value);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglSwapBuffers(EGLDisplay dpy, EGLSurface surface) {
  GL_SERVICE_LOG("eglSwapBuffers"
                 << "(" << dpy << ", " << surface << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglSwapBuffersFn(dpy, surface);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL
Debug_eglSwapInterval(EGLDisplay dpy, EGLint interval) {
  GL_SERVICE_LOG("eglSwapInterval"
                 << "(" << dpy << ", " << interval << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglSwapIntervalFn(dpy, interval);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglTerminate(EGLDisplay dpy) {
  GL_SERVICE_LOG("eglTerminate"
                 << "(" << dpy << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglTerminateFn(dpy);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglWaitClient(void) {
  GL_SERVICE_LOG("eglWaitClient"
                 << "("
                 << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglWaitClientFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglWaitGL(void) {
  GL_SERVICE_LOG("eglWaitGL"
                 << "("
                 << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglWaitGLFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLBoolean GL_BINDING_CALL Debug_eglWaitNative(EGLint engine) {
  GL_SERVICE_LOG("eglWaitNative"
                 << "(" << engine << ")");
  EGLBoolean result = g_driver_egl.debug_fn.eglWaitNativeFn(engine);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static EGLint GL_BINDING_CALL
Debug_eglWaitSyncKHR(EGLDisplay dpy, EGLSyncKHR sync, EGLint flags) {
  GL_SERVICE_LOG("eglWaitSyncKHR"
                 << "(" << dpy << ", " << sync << ", " << flags << ")");
  EGLint result = g_driver_egl.debug_fn.eglWaitSyncKHRFn(dpy, sync, flags);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}
}  // extern "C"

void DriverEGL::InitializeDebugBindings() {
  if (!debug_fn.eglBindAPIFn) {
    debug_fn.eglBindAPIFn = fn.eglBindAPIFn;
    fn.eglBindAPIFn = Debug_eglBindAPI;
  }
  if (!debug_fn.eglBindTexImageFn) {
    debug_fn.eglBindTexImageFn = fn.eglBindTexImageFn;
    fn.eglBindTexImageFn = Debug_eglBindTexImage;
  }
  if (!debug_fn.eglChooseConfigFn) {
    debug_fn.eglChooseConfigFn = fn.eglChooseConfigFn;
    fn.eglChooseConfigFn = Debug_eglChooseConfig;
  }
  if (!debug_fn.eglClientWaitSyncKHRFn) {
    debug_fn.eglClientWaitSyncKHRFn = fn.eglClientWaitSyncKHRFn;
    fn.eglClientWaitSyncKHRFn = Debug_eglClientWaitSyncKHR;
  }
  if (!debug_fn.eglCopyBuffersFn) {
    debug_fn.eglCopyBuffersFn = fn.eglCopyBuffersFn;
    fn.eglCopyBuffersFn = Debug_eglCopyBuffers;
  }
  if (!debug_fn.eglCreateContextFn) {
    debug_fn.eglCreateContextFn = fn.eglCreateContextFn;
    fn.eglCreateContextFn = Debug_eglCreateContext;
  }
  if (!debug_fn.eglCreateImageKHRFn) {
    debug_fn.eglCreateImageKHRFn = fn.eglCreateImageKHRFn;
    fn.eglCreateImageKHRFn = Debug_eglCreateImageKHR;
  }
  if (!debug_fn.eglCreatePbufferFromClientBufferFn) {
    debug_fn.eglCreatePbufferFromClientBufferFn =
        fn.eglCreatePbufferFromClientBufferFn;
    fn.eglCreatePbufferFromClientBufferFn =
        Debug_eglCreatePbufferFromClientBuffer;
  }
  if (!debug_fn.eglCreatePbufferSurfaceFn) {
    debug_fn.eglCreatePbufferSurfaceFn = fn.eglCreatePbufferSurfaceFn;
    fn.eglCreatePbufferSurfaceFn = Debug_eglCreatePbufferSurface;
  }
  if (!debug_fn.eglCreatePixmapSurfaceFn) {
    debug_fn.eglCreatePixmapSurfaceFn = fn.eglCreatePixmapSurfaceFn;
    fn.eglCreatePixmapSurfaceFn = Debug_eglCreatePixmapSurface;
  }
  if (!debug_fn.eglCreateSyncKHRFn) {
    debug_fn.eglCreateSyncKHRFn = fn.eglCreateSyncKHRFn;
    fn.eglCreateSyncKHRFn = Debug_eglCreateSyncKHR;
  }
  if (!debug_fn.eglCreateWindowSurfaceFn) {
    debug_fn.eglCreateWindowSurfaceFn = fn.eglCreateWindowSurfaceFn;
    fn.eglCreateWindowSurfaceFn = Debug_eglCreateWindowSurface;
  }
  if (!debug_fn.eglDestroyContextFn) {
    debug_fn.eglDestroyContextFn = fn.eglDestroyContextFn;
    fn.eglDestroyContextFn = Debug_eglDestroyContext;
  }
  if (!debug_fn.eglDestroyImageKHRFn) {
    debug_fn.eglDestroyImageKHRFn = fn.eglDestroyImageKHRFn;
    fn.eglDestroyImageKHRFn = Debug_eglDestroyImageKHR;
  }
  if (!debug_fn.eglDestroySurfaceFn) {
    debug_fn.eglDestroySurfaceFn = fn.eglDestroySurfaceFn;
    fn.eglDestroySurfaceFn = Debug_eglDestroySurface;
  }
  if (!debug_fn.eglDestroySyncKHRFn) {
    debug_fn.eglDestroySyncKHRFn = fn.eglDestroySyncKHRFn;
    fn.eglDestroySyncKHRFn = Debug_eglDestroySyncKHR;
  }
  if (!debug_fn.eglGetConfigAttribFn) {
    debug_fn.eglGetConfigAttribFn = fn.eglGetConfigAttribFn;
    fn.eglGetConfigAttribFn = Debug_eglGetConfigAttrib;
  }
  if (!debug_fn.eglGetConfigsFn) {
    debug_fn.eglGetConfigsFn = fn.eglGetConfigsFn;
    fn.eglGetConfigsFn = Debug_eglGetConfigs;
  }
  if (!debug_fn.eglGetCurrentContextFn) {
    debug_fn.eglGetCurrentContextFn = fn.eglGetCurrentContextFn;
    fn.eglGetCurrentContextFn = Debug_eglGetCurrentContext;
  }
  if (!debug_fn.eglGetCurrentDisplayFn) {
    debug_fn.eglGetCurrentDisplayFn = fn.eglGetCurrentDisplayFn;
    fn.eglGetCurrentDisplayFn = Debug_eglGetCurrentDisplay;
  }
  if (!debug_fn.eglGetCurrentSurfaceFn) {
    debug_fn.eglGetCurrentSurfaceFn = fn.eglGetCurrentSurfaceFn;
    fn.eglGetCurrentSurfaceFn = Debug_eglGetCurrentSurface;
  }
  if (!debug_fn.eglGetDisplayFn) {
    debug_fn.eglGetDisplayFn = fn.eglGetDisplayFn;
    fn.eglGetDisplayFn = Debug_eglGetDisplay;
  }
  if (!debug_fn.eglGetErrorFn) {
    debug_fn.eglGetErrorFn = fn.eglGetErrorFn;
    fn.eglGetErrorFn = Debug_eglGetError;
  }
  if (!debug_fn.eglGetPlatformDisplayEXTFn) {
    debug_fn.eglGetPlatformDisplayEXTFn = fn.eglGetPlatformDisplayEXTFn;
    fn.eglGetPlatformDisplayEXTFn = Debug_eglGetPlatformDisplayEXT;
  }
  if (!debug_fn.eglGetProcAddressFn) {
    debug_fn.eglGetProcAddressFn = fn.eglGetProcAddressFn;
    fn.eglGetProcAddressFn = Debug_eglGetProcAddress;
  }
  if (!debug_fn.eglGetSyncAttribKHRFn) {
    debug_fn.eglGetSyncAttribKHRFn = fn.eglGetSyncAttribKHRFn;
    fn.eglGetSyncAttribKHRFn = Debug_eglGetSyncAttribKHR;
  }
  if (!debug_fn.eglGetSyncValuesCHROMIUMFn) {
    debug_fn.eglGetSyncValuesCHROMIUMFn = fn.eglGetSyncValuesCHROMIUMFn;
    fn.eglGetSyncValuesCHROMIUMFn = Debug_eglGetSyncValuesCHROMIUM;
  }
  if (!debug_fn.eglInitializeFn) {
    debug_fn.eglInitializeFn = fn.eglInitializeFn;
    fn.eglInitializeFn = Debug_eglInitialize;
  }
  if (!debug_fn.eglMakeCurrentFn) {
    debug_fn.eglMakeCurrentFn = fn.eglMakeCurrentFn;
    fn.eglMakeCurrentFn = Debug_eglMakeCurrent;
  }
  if (!debug_fn.eglPostSubBufferNVFn) {
    debug_fn.eglPostSubBufferNVFn = fn.eglPostSubBufferNVFn;
    fn.eglPostSubBufferNVFn = Debug_eglPostSubBufferNV;
  }
  if (!debug_fn.eglQueryAPIFn) {
    debug_fn.eglQueryAPIFn = fn.eglQueryAPIFn;
    fn.eglQueryAPIFn = Debug_eglQueryAPI;
  }
  if (!debug_fn.eglQueryContextFn) {
    debug_fn.eglQueryContextFn = fn.eglQueryContextFn;
    fn.eglQueryContextFn = Debug_eglQueryContext;
  }
  if (!debug_fn.eglQueryStringFn) {
    debug_fn.eglQueryStringFn = fn.eglQueryStringFn;
    fn.eglQueryStringFn = Debug_eglQueryString;
  }
  if (!debug_fn.eglQuerySurfaceFn) {
    debug_fn.eglQuerySurfaceFn = fn.eglQuerySurfaceFn;
    fn.eglQuerySurfaceFn = Debug_eglQuerySurface;
  }
  if (!debug_fn.eglQuerySurfacePointerANGLEFn) {
    debug_fn.eglQuerySurfacePointerANGLEFn = fn.eglQuerySurfacePointerANGLEFn;
    fn.eglQuerySurfacePointerANGLEFn = Debug_eglQuerySurfacePointerANGLE;
  }
  if (!debug_fn.eglReleaseTexImageFn) {
    debug_fn.eglReleaseTexImageFn = fn.eglReleaseTexImageFn;
    fn.eglReleaseTexImageFn = Debug_eglReleaseTexImage;
  }
  if (!debug_fn.eglReleaseThreadFn) {
    debug_fn.eglReleaseThreadFn = fn.eglReleaseThreadFn;
    fn.eglReleaseThreadFn = Debug_eglReleaseThread;
  }
  if (!debug_fn.eglSurfaceAttribFn) {
    debug_fn.eglSurfaceAttribFn = fn.eglSurfaceAttribFn;
    fn.eglSurfaceAttribFn = Debug_eglSurfaceAttrib;
  }
  if (!debug_fn.eglSwapBuffersFn) {
    debug_fn.eglSwapBuffersFn = fn.eglSwapBuffersFn;
    fn.eglSwapBuffersFn = Debug_eglSwapBuffers;
  }
  if (!debug_fn.eglSwapIntervalFn) {
    debug_fn.eglSwapIntervalFn = fn.eglSwapIntervalFn;
    fn.eglSwapIntervalFn = Debug_eglSwapInterval;
  }
  if (!debug_fn.eglTerminateFn) {
    debug_fn.eglTerminateFn = fn.eglTerminateFn;
    fn.eglTerminateFn = Debug_eglTerminate;
  }
  if (!debug_fn.eglWaitClientFn) {
    debug_fn.eglWaitClientFn = fn.eglWaitClientFn;
    fn.eglWaitClientFn = Debug_eglWaitClient;
  }
  if (!debug_fn.eglWaitGLFn) {
    debug_fn.eglWaitGLFn = fn.eglWaitGLFn;
    fn.eglWaitGLFn = Debug_eglWaitGL;
  }
  if (!debug_fn.eglWaitNativeFn) {
    debug_fn.eglWaitNativeFn = fn.eglWaitNativeFn;
    fn.eglWaitNativeFn = Debug_eglWaitNative;
  }
  if (!debug_fn.eglWaitSyncKHRFn) {
    debug_fn.eglWaitSyncKHRFn = fn.eglWaitSyncKHRFn;
    fn.eglWaitSyncKHRFn = Debug_eglWaitSyncKHR;
  }
  g_debugBindingsInitialized = true;
}

void DriverEGL::ClearBindings() {
  memset(this, 0, sizeof(*this));
}

EGLBoolean EGLApiBase::eglBindAPIFn(EGLenum api) {
  return driver_->fn.eglBindAPIFn(api);
}

EGLBoolean EGLApiBase::eglBindTexImageFn(EGLDisplay dpy,
                                         EGLSurface surface,
                                         EGLint buffer) {
  return driver_->fn.eglBindTexImageFn(dpy, surface, buffer);
}

EGLBoolean EGLApiBase::eglChooseConfigFn(EGLDisplay dpy,
                                         const EGLint* attrib_list,
                                         EGLConfig* configs,
                                         EGLint config_size,
                                         EGLint* num_config) {
  return driver_->fn.eglChooseConfigFn(dpy, attrib_list, configs, config_size,
                                       num_config);
}

EGLint EGLApiBase::eglClientWaitSyncKHRFn(EGLDisplay dpy,
                                          EGLSyncKHR sync,
                                          EGLint flags,
                                          EGLTimeKHR timeout) {
  return driver_->fn.eglClientWaitSyncKHRFn(dpy, sync, flags, timeout);
}

EGLBoolean EGLApiBase::eglCopyBuffersFn(EGLDisplay dpy,
                                        EGLSurface surface,
                                        EGLNativePixmapType target) {
  return driver_->fn.eglCopyBuffersFn(dpy, surface, target);
}

EGLContext EGLApiBase::eglCreateContextFn(EGLDisplay dpy,
                                          EGLConfig config,
                                          EGLContext share_context,
                                          const EGLint* attrib_list) {
  return driver_->fn.eglCreateContextFn(dpy, config, share_context,
                                        attrib_list);
}

EGLImageKHR EGLApiBase::eglCreateImageKHRFn(EGLDisplay dpy,
                                            EGLContext ctx,
                                            EGLenum target,
                                            EGLClientBuffer buffer,
                                            const EGLint* attrib_list) {
  return driver_->fn.eglCreateImageKHRFn(dpy, ctx, target, buffer, attrib_list);
}

EGLSurface EGLApiBase::eglCreatePbufferFromClientBufferFn(
    EGLDisplay dpy,
    EGLenum buftype,
    void* buffer,
    EGLConfig config,
    const EGLint* attrib_list) {
  return driver_->fn.eglCreatePbufferFromClientBufferFn(dpy, buftype, buffer,
                                                        config, attrib_list);
}

EGLSurface EGLApiBase::eglCreatePbufferSurfaceFn(EGLDisplay dpy,
                                                 EGLConfig config,
                                                 const EGLint* attrib_list) {
  return driver_->fn.eglCreatePbufferSurfaceFn(dpy, config, attrib_list);
}

EGLSurface EGLApiBase::eglCreatePixmapSurfaceFn(EGLDisplay dpy,
                                                EGLConfig config,
                                                EGLNativePixmapType pixmap,
                                                const EGLint* attrib_list) {
  return driver_->fn.eglCreatePixmapSurfaceFn(dpy, config, pixmap, attrib_list);
}

EGLSyncKHR EGLApiBase::eglCreateSyncKHRFn(EGLDisplay dpy,
                                          EGLenum type,
                                          const EGLint* attrib_list) {
  return driver_->fn.eglCreateSyncKHRFn(dpy, type, attrib_list);
}

EGLSurface EGLApiBase::eglCreateWindowSurfaceFn(EGLDisplay dpy,
                                                EGLConfig config,
                                                EGLNativeWindowType win,
                                                const EGLint* attrib_list) {
  return driver_->fn.eglCreateWindowSurfaceFn(dpy, config, win, attrib_list);
}

EGLBoolean EGLApiBase::eglDestroyContextFn(EGLDisplay dpy, EGLContext ctx) {
  return driver_->fn.eglDestroyContextFn(dpy, ctx);
}

EGLBoolean EGLApiBase::eglDestroyImageKHRFn(EGLDisplay dpy, EGLImageKHR image) {
  return driver_->fn.eglDestroyImageKHRFn(dpy, image);
}

EGLBoolean EGLApiBase::eglDestroySurfaceFn(EGLDisplay dpy, EGLSurface surface) {
  return driver_->fn.eglDestroySurfaceFn(dpy, surface);
}

EGLBoolean EGLApiBase::eglDestroySyncKHRFn(EGLDisplay dpy, EGLSyncKHR sync) {
  return driver_->fn.eglDestroySyncKHRFn(dpy, sync);
}

EGLBoolean EGLApiBase::eglGetConfigAttribFn(EGLDisplay dpy,
                                            EGLConfig config,
                                            EGLint attribute,
                                            EGLint* value) {
  return driver_->fn.eglGetConfigAttribFn(dpy, config, attribute, value);
}

EGLBoolean EGLApiBase::eglGetConfigsFn(EGLDisplay dpy,
                                       EGLConfig* configs,
                                       EGLint config_size,
                                       EGLint* num_config) {
  return driver_->fn.eglGetConfigsFn(dpy, configs, config_size, num_config);
}

EGLContext EGLApiBase::eglGetCurrentContextFn(void) {
  return driver_->fn.eglGetCurrentContextFn();
}

EGLDisplay EGLApiBase::eglGetCurrentDisplayFn(void) {
  return driver_->fn.eglGetCurrentDisplayFn();
}

EGLSurface EGLApiBase::eglGetCurrentSurfaceFn(EGLint readdraw) {
  return driver_->fn.eglGetCurrentSurfaceFn(readdraw);
}

EGLDisplay EGLApiBase::eglGetDisplayFn(EGLNativeDisplayType display_id) {
  return driver_->fn.eglGetDisplayFn(display_id);
}

EGLint EGLApiBase::eglGetErrorFn(void) {
  return driver_->fn.eglGetErrorFn();
}

EGLDisplay EGLApiBase::eglGetPlatformDisplayEXTFn(EGLenum platform,
                                                  void* native_display,
                                                  const EGLint* attrib_list) {
  return driver_->fn.eglGetPlatformDisplayEXTFn(platform, native_display,
                                                attrib_list);
}

__eglMustCastToProperFunctionPointerType EGLApiBase::eglGetProcAddressFn(
    const char* procname) {
  return driver_->fn.eglGetProcAddressFn(procname);
}

EGLBoolean EGLApiBase::eglGetSyncAttribKHRFn(EGLDisplay dpy,
                                             EGLSyncKHR sync,
                                             EGLint attribute,
                                             EGLint* value) {
  return driver_->fn.eglGetSyncAttribKHRFn(dpy, sync, attribute, value);
}

EGLBoolean EGLApiBase::eglGetSyncValuesCHROMIUMFn(EGLDisplay dpy,
                                                  EGLSurface surface,
                                                  EGLuint64CHROMIUM* ust,
                                                  EGLuint64CHROMIUM* msc,
                                                  EGLuint64CHROMIUM* sbc) {
  return driver_->fn.eglGetSyncValuesCHROMIUMFn(dpy, surface, ust, msc, sbc);
}

EGLBoolean EGLApiBase::eglInitializeFn(EGLDisplay dpy,
                                       EGLint* major,
                                       EGLint* minor) {
  return driver_->fn.eglInitializeFn(dpy, major, minor);
}

EGLBoolean EGLApiBase::eglMakeCurrentFn(EGLDisplay dpy,
                                        EGLSurface draw,
                                        EGLSurface read,
                                        EGLContext ctx) {
  return driver_->fn.eglMakeCurrentFn(dpy, draw, read, ctx);
}

EGLBoolean EGLApiBase::eglPostSubBufferNVFn(EGLDisplay dpy,
                                            EGLSurface surface,
                                            EGLint x,
                                            EGLint y,
                                            EGLint width,
                                            EGLint height) {
  return driver_->fn.eglPostSubBufferNVFn(dpy, surface, x, y, width, height);
}

EGLenum EGLApiBase::eglQueryAPIFn(void) {
  return driver_->fn.eglQueryAPIFn();
}

EGLBoolean EGLApiBase::eglQueryContextFn(EGLDisplay dpy,
                                         EGLContext ctx,
                                         EGLint attribute,
                                         EGLint* value) {
  return driver_->fn.eglQueryContextFn(dpy, ctx, attribute, value);
}

const char* EGLApiBase::eglQueryStringFn(EGLDisplay dpy, EGLint name) {
  return driver_->fn.eglQueryStringFn(dpy, name);
}

EGLBoolean EGLApiBase::eglQuerySurfaceFn(EGLDisplay dpy,
                                         EGLSurface surface,
                                         EGLint attribute,
                                         EGLint* value) {
  return driver_->fn.eglQuerySurfaceFn(dpy, surface, attribute, value);
}

EGLBoolean EGLApiBase::eglQuerySurfacePointerANGLEFn(EGLDisplay dpy,
                                                     EGLSurface surface,
                                                     EGLint attribute,
                                                     void** value) {
  return driver_->fn.eglQuerySurfacePointerANGLEFn(dpy, surface, attribute,
                                                   value);
}

EGLBoolean EGLApiBase::eglReleaseTexImageFn(EGLDisplay dpy,
                                            EGLSurface surface,
                                            EGLint buffer) {
  return driver_->fn.eglReleaseTexImageFn(dpy, surface, buffer);
}

EGLBoolean EGLApiBase::eglReleaseThreadFn(void) {
  return driver_->fn.eglReleaseThreadFn();
}

EGLBoolean EGLApiBase::eglSurfaceAttribFn(EGLDisplay dpy,
                                          EGLSurface surface,
                                          EGLint attribute,
                                          EGLint value) {
  return driver_->fn.eglSurfaceAttribFn(dpy, surface, attribute, value);
}

EGLBoolean EGLApiBase::eglSwapBuffersFn(EGLDisplay dpy, EGLSurface surface) {
  return driver_->fn.eglSwapBuffersFn(dpy, surface);
}

EGLBoolean EGLApiBase::eglSwapIntervalFn(EGLDisplay dpy, EGLint interval) {
  return driver_->fn.eglSwapIntervalFn(dpy, interval);
}

EGLBoolean EGLApiBase::eglTerminateFn(EGLDisplay dpy) {
  return driver_->fn.eglTerminateFn(dpy);
}

EGLBoolean EGLApiBase::eglWaitClientFn(void) {
  return driver_->fn.eglWaitClientFn();
}

EGLBoolean EGLApiBase::eglWaitGLFn(void) {
  return driver_->fn.eglWaitGLFn();
}

EGLBoolean EGLApiBase::eglWaitNativeFn(EGLint engine) {
  return driver_->fn.eglWaitNativeFn(engine);
}

EGLint EGLApiBase::eglWaitSyncKHRFn(EGLDisplay dpy,
                                    EGLSyncKHR sync,
                                    EGLint flags) {
  return driver_->fn.eglWaitSyncKHRFn(dpy, sync, flags);
}

EGLBoolean TraceEGLApi::eglBindAPIFn(EGLenum api) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglBindAPI")
  return egl_api_->eglBindAPIFn(api);
}

EGLBoolean TraceEGLApi::eglBindTexImageFn(EGLDisplay dpy,
                                          EGLSurface surface,
                                          EGLint buffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglBindTexImage")
  return egl_api_->eglBindTexImageFn(dpy, surface, buffer);
}

EGLBoolean TraceEGLApi::eglChooseConfigFn(EGLDisplay dpy,
                                          const EGLint* attrib_list,
                                          EGLConfig* configs,
                                          EGLint config_size,
                                          EGLint* num_config) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglChooseConfig")
  return egl_api_->eglChooseConfigFn(dpy, attrib_list, configs, config_size,
                                     num_config);
}

EGLint TraceEGLApi::eglClientWaitSyncKHRFn(EGLDisplay dpy,
                                           EGLSyncKHR sync,
                                           EGLint flags,
                                           EGLTimeKHR timeout) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglClientWaitSyncKHR")
  return egl_api_->eglClientWaitSyncKHRFn(dpy, sync, flags, timeout);
}

EGLBoolean TraceEGLApi::eglCopyBuffersFn(EGLDisplay dpy,
                                         EGLSurface surface,
                                         EGLNativePixmapType target) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglCopyBuffers")
  return egl_api_->eglCopyBuffersFn(dpy, surface, target);
}

EGLContext TraceEGLApi::eglCreateContextFn(EGLDisplay dpy,
                                           EGLConfig config,
                                           EGLContext share_context,
                                           const EGLint* attrib_list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglCreateContext")
  return egl_api_->eglCreateContextFn(dpy, config, share_context, attrib_list);
}

EGLImageKHR TraceEGLApi::eglCreateImageKHRFn(EGLDisplay dpy,
                                             EGLContext ctx,
                                             EGLenum target,
                                             EGLClientBuffer buffer,
                                             const EGLint* attrib_list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglCreateImageKHR")
  return egl_api_->eglCreateImageKHRFn(dpy, ctx, target, buffer, attrib_list);
}

EGLSurface TraceEGLApi::eglCreatePbufferFromClientBufferFn(
    EGLDisplay dpy,
    EGLenum buftype,
    void* buffer,
    EGLConfig config,
    const EGLint* attrib_list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "TraceGLAPI::eglCreatePbufferFromClientBuffer")
  return egl_api_->eglCreatePbufferFromClientBufferFn(dpy, buftype, buffer,
                                                      config, attrib_list);
}

EGLSurface TraceEGLApi::eglCreatePbufferSurfaceFn(EGLDisplay dpy,
                                                  EGLConfig config,
                                                  const EGLint* attrib_list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglCreatePbufferSurface")
  return egl_api_->eglCreatePbufferSurfaceFn(dpy, config, attrib_list);
}

EGLSurface TraceEGLApi::eglCreatePixmapSurfaceFn(EGLDisplay dpy,
                                                 EGLConfig config,
                                                 EGLNativePixmapType pixmap,
                                                 const EGLint* attrib_list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglCreatePixmapSurface")
  return egl_api_->eglCreatePixmapSurfaceFn(dpy, config, pixmap, attrib_list);
}

EGLSyncKHR TraceEGLApi::eglCreateSyncKHRFn(EGLDisplay dpy,
                                           EGLenum type,
                                           const EGLint* attrib_list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglCreateSyncKHR")
  return egl_api_->eglCreateSyncKHRFn(dpy, type, attrib_list);
}

EGLSurface TraceEGLApi::eglCreateWindowSurfaceFn(EGLDisplay dpy,
                                                 EGLConfig config,
                                                 EGLNativeWindowType win,
                                                 const EGLint* attrib_list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglCreateWindowSurface")
  return egl_api_->eglCreateWindowSurfaceFn(dpy, config, win, attrib_list);
}

EGLBoolean TraceEGLApi::eglDestroyContextFn(EGLDisplay dpy, EGLContext ctx) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglDestroyContext")
  return egl_api_->eglDestroyContextFn(dpy, ctx);
}

EGLBoolean TraceEGLApi::eglDestroyImageKHRFn(EGLDisplay dpy,
                                             EGLImageKHR image) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglDestroyImageKHR")
  return egl_api_->eglDestroyImageKHRFn(dpy, image);
}

EGLBoolean TraceEGLApi::eglDestroySurfaceFn(EGLDisplay dpy,
                                            EGLSurface surface) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglDestroySurface")
  return egl_api_->eglDestroySurfaceFn(dpy, surface);
}

EGLBoolean TraceEGLApi::eglDestroySyncKHRFn(EGLDisplay dpy, EGLSyncKHR sync) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglDestroySyncKHR")
  return egl_api_->eglDestroySyncKHRFn(dpy, sync);
}

EGLBoolean TraceEGLApi::eglGetConfigAttribFn(EGLDisplay dpy,
                                             EGLConfig config,
                                             EGLint attribute,
                                             EGLint* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetConfigAttrib")
  return egl_api_->eglGetConfigAttribFn(dpy, config, attribute, value);
}

EGLBoolean TraceEGLApi::eglGetConfigsFn(EGLDisplay dpy,
                                        EGLConfig* configs,
                                        EGLint config_size,
                                        EGLint* num_config) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetConfigs")
  return egl_api_->eglGetConfigsFn(dpy, configs, config_size, num_config);
}

EGLContext TraceEGLApi::eglGetCurrentContextFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetCurrentContext")
  return egl_api_->eglGetCurrentContextFn();
}

EGLDisplay TraceEGLApi::eglGetCurrentDisplayFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetCurrentDisplay")
  return egl_api_->eglGetCurrentDisplayFn();
}

EGLSurface TraceEGLApi::eglGetCurrentSurfaceFn(EGLint readdraw) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetCurrentSurface")
  return egl_api_->eglGetCurrentSurfaceFn(readdraw);
}

EGLDisplay TraceEGLApi::eglGetDisplayFn(EGLNativeDisplayType display_id) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetDisplay")
  return egl_api_->eglGetDisplayFn(display_id);
}

EGLint TraceEGLApi::eglGetErrorFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetError")
  return egl_api_->eglGetErrorFn();
}

EGLDisplay TraceEGLApi::eglGetPlatformDisplayEXTFn(EGLenum platform,
                                                   void* native_display,
                                                   const EGLint* attrib_list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetPlatformDisplayEXT")
  return egl_api_->eglGetPlatformDisplayEXTFn(platform, native_display,
                                              attrib_list);
}

__eglMustCastToProperFunctionPointerType TraceEGLApi::eglGetProcAddressFn(
    const char* procname) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetProcAddress")
  return egl_api_->eglGetProcAddressFn(procname);
}

EGLBoolean TraceEGLApi::eglGetSyncAttribKHRFn(EGLDisplay dpy,
                                              EGLSyncKHR sync,
                                              EGLint attribute,
                                              EGLint* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetSyncAttribKHR")
  return egl_api_->eglGetSyncAttribKHRFn(dpy, sync, attribute, value);
}

EGLBoolean TraceEGLApi::eglGetSyncValuesCHROMIUMFn(EGLDisplay dpy,
                                                   EGLSurface surface,
                                                   EGLuint64CHROMIUM* ust,
                                                   EGLuint64CHROMIUM* msc,
                                                   EGLuint64CHROMIUM* sbc) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglGetSyncValuesCHROMIUM")
  return egl_api_->eglGetSyncValuesCHROMIUMFn(dpy, surface, ust, msc, sbc);
}

EGLBoolean TraceEGLApi::eglInitializeFn(EGLDisplay dpy,
                                        EGLint* major,
                                        EGLint* minor) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglInitialize")
  return egl_api_->eglInitializeFn(dpy, major, minor);
}

EGLBoolean TraceEGLApi::eglMakeCurrentFn(EGLDisplay dpy,
                                         EGLSurface draw,
                                         EGLSurface read,
                                         EGLContext ctx) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglMakeCurrent")
  return egl_api_->eglMakeCurrentFn(dpy, draw, read, ctx);
}

EGLBoolean TraceEGLApi::eglPostSubBufferNVFn(EGLDisplay dpy,
                                             EGLSurface surface,
                                             EGLint x,
                                             EGLint y,
                                             EGLint width,
                                             EGLint height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglPostSubBufferNV")
  return egl_api_->eglPostSubBufferNVFn(dpy, surface, x, y, width, height);
}

EGLenum TraceEGLApi::eglQueryAPIFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglQueryAPI")
  return egl_api_->eglQueryAPIFn();
}

EGLBoolean TraceEGLApi::eglQueryContextFn(EGLDisplay dpy,
                                          EGLContext ctx,
                                          EGLint attribute,
                                          EGLint* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglQueryContext")
  return egl_api_->eglQueryContextFn(dpy, ctx, attribute, value);
}

const char* TraceEGLApi::eglQueryStringFn(EGLDisplay dpy, EGLint name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglQueryString")
  return egl_api_->eglQueryStringFn(dpy, name);
}

EGLBoolean TraceEGLApi::eglQuerySurfaceFn(EGLDisplay dpy,
                                          EGLSurface surface,
                                          EGLint attribute,
                                          EGLint* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglQuerySurface")
  return egl_api_->eglQuerySurfaceFn(dpy, surface, attribute, value);
}

EGLBoolean TraceEGLApi::eglQuerySurfacePointerANGLEFn(EGLDisplay dpy,
                                                      EGLSurface surface,
                                                      EGLint attribute,
                                                      void** value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "TraceGLAPI::eglQuerySurfacePointerANGLE")
  return egl_api_->eglQuerySurfacePointerANGLEFn(dpy, surface, attribute,
                                                 value);
}

EGLBoolean TraceEGLApi::eglReleaseTexImageFn(EGLDisplay dpy,
                                             EGLSurface surface,
                                             EGLint buffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglReleaseTexImage")
  return egl_api_->eglReleaseTexImageFn(dpy, surface, buffer);
}

EGLBoolean TraceEGLApi::eglReleaseThreadFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglReleaseThread")
  return egl_api_->eglReleaseThreadFn();
}

EGLBoolean TraceEGLApi::eglSurfaceAttribFn(EGLDisplay dpy,
                                           EGLSurface surface,
                                           EGLint attribute,
                                           EGLint value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglSurfaceAttrib")
  return egl_api_->eglSurfaceAttribFn(dpy, surface, attribute, value);
}

EGLBoolean TraceEGLApi::eglSwapBuffersFn(EGLDisplay dpy, EGLSurface surface) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglSwapBuffers")
  return egl_api_->eglSwapBuffersFn(dpy, surface);
}

EGLBoolean TraceEGLApi::eglSwapIntervalFn(EGLDisplay dpy, EGLint interval) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglSwapInterval")
  return egl_api_->eglSwapIntervalFn(dpy, interval);
}

EGLBoolean TraceEGLApi::eglTerminateFn(EGLDisplay dpy) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglTerminate")
  return egl_api_->eglTerminateFn(dpy);
}

EGLBoolean TraceEGLApi::eglWaitClientFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglWaitClient")
  return egl_api_->eglWaitClientFn();
}

EGLBoolean TraceEGLApi::eglWaitGLFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglWaitGL")
  return egl_api_->eglWaitGLFn();
}

EGLBoolean TraceEGLApi::eglWaitNativeFn(EGLint engine) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglWaitNative")
  return egl_api_->eglWaitNativeFn(engine);
}

EGLint TraceEGLApi::eglWaitSyncKHRFn(EGLDisplay dpy,
                                     EGLSyncKHR sync,
                                     EGLint flags) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::eglWaitSyncKHR")
  return egl_api_->eglWaitSyncKHRFn(dpy, sync, flags);
}

}  // namespace gfx
