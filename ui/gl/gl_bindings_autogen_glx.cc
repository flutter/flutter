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
#include "ui/gl/gl_enums.h"
#include "ui/gl/gl_glx_api_implementation.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_version_info.h"

namespace gfx {

static bool g_debugBindingsInitialized;
DriverGLX g_driver_glx;

void DriverGLX::InitializeStaticBindings() {
  fn.glXBindTexImageEXTFn = 0;
  fn.glXChooseFBConfigFn = reinterpret_cast<glXChooseFBConfigProc>(
      GetGLProcAddress("glXChooseFBConfig"));
  fn.glXChooseVisualFn = reinterpret_cast<glXChooseVisualProc>(
      GetGLProcAddress("glXChooseVisual"));
  fn.glXCopyContextFn =
      reinterpret_cast<glXCopyContextProc>(GetGLProcAddress("glXCopyContext"));
  fn.glXCopySubBufferMESAFn = 0;
  fn.glXCreateContextFn = reinterpret_cast<glXCreateContextProc>(
      GetGLProcAddress("glXCreateContext"));
  fn.glXCreateContextAttribsARBFn = 0;
  fn.glXCreateGLXPixmapFn = reinterpret_cast<glXCreateGLXPixmapProc>(
      GetGLProcAddress("glXCreateGLXPixmap"));
  fn.glXCreateNewContextFn = reinterpret_cast<glXCreateNewContextProc>(
      GetGLProcAddress("glXCreateNewContext"));
  fn.glXCreatePbufferFn = reinterpret_cast<glXCreatePbufferProc>(
      GetGLProcAddress("glXCreatePbuffer"));
  fn.glXCreatePixmapFn = reinterpret_cast<glXCreatePixmapProc>(
      GetGLProcAddress("glXCreatePixmap"));
  fn.glXCreateWindowFn = reinterpret_cast<glXCreateWindowProc>(
      GetGLProcAddress("glXCreateWindow"));
  fn.glXDestroyContextFn = reinterpret_cast<glXDestroyContextProc>(
      GetGLProcAddress("glXDestroyContext"));
  fn.glXDestroyGLXPixmapFn = reinterpret_cast<glXDestroyGLXPixmapProc>(
      GetGLProcAddress("glXDestroyGLXPixmap"));
  fn.glXDestroyPbufferFn = reinterpret_cast<glXDestroyPbufferProc>(
      GetGLProcAddress("glXDestroyPbuffer"));
  fn.glXDestroyPixmapFn = reinterpret_cast<glXDestroyPixmapProc>(
      GetGLProcAddress("glXDestroyPixmap"));
  fn.glXDestroyWindowFn = reinterpret_cast<glXDestroyWindowProc>(
      GetGLProcAddress("glXDestroyWindow"));
  fn.glXGetClientStringFn = reinterpret_cast<glXGetClientStringProc>(
      GetGLProcAddress("glXGetClientString"));
  fn.glXGetConfigFn =
      reinterpret_cast<glXGetConfigProc>(GetGLProcAddress("glXGetConfig"));
  fn.glXGetCurrentContextFn = reinterpret_cast<glXGetCurrentContextProc>(
      GetGLProcAddress("glXGetCurrentContext"));
  fn.glXGetCurrentDisplayFn = reinterpret_cast<glXGetCurrentDisplayProc>(
      GetGLProcAddress("glXGetCurrentDisplay"));
  fn.glXGetCurrentDrawableFn = reinterpret_cast<glXGetCurrentDrawableProc>(
      GetGLProcAddress("glXGetCurrentDrawable"));
  fn.glXGetCurrentReadDrawableFn =
      reinterpret_cast<glXGetCurrentReadDrawableProc>(
          GetGLProcAddress("glXGetCurrentReadDrawable"));
  fn.glXGetFBConfigAttribFn = reinterpret_cast<glXGetFBConfigAttribProc>(
      GetGLProcAddress("glXGetFBConfigAttrib"));
  fn.glXGetFBConfigFromVisualSGIXFn = 0;
  fn.glXGetFBConfigsFn = reinterpret_cast<glXGetFBConfigsProc>(
      GetGLProcAddress("glXGetFBConfigs"));
  fn.glXGetMscRateOMLFn = 0;
  fn.glXGetSelectedEventFn = reinterpret_cast<glXGetSelectedEventProc>(
      GetGLProcAddress("glXGetSelectedEvent"));
  fn.glXGetSyncValuesOMLFn = 0;
  fn.glXGetVisualFromFBConfigFn =
      reinterpret_cast<glXGetVisualFromFBConfigProc>(
          GetGLProcAddress("glXGetVisualFromFBConfig"));
  fn.glXIsDirectFn =
      reinterpret_cast<glXIsDirectProc>(GetGLProcAddress("glXIsDirect"));
  fn.glXMakeContextCurrentFn = reinterpret_cast<glXMakeContextCurrentProc>(
      GetGLProcAddress("glXMakeContextCurrent"));
  fn.glXMakeCurrentFn =
      reinterpret_cast<glXMakeCurrentProc>(GetGLProcAddress("glXMakeCurrent"));
  fn.glXQueryContextFn = reinterpret_cast<glXQueryContextProc>(
      GetGLProcAddress("glXQueryContext"));
  fn.glXQueryDrawableFn = reinterpret_cast<glXQueryDrawableProc>(
      GetGLProcAddress("glXQueryDrawable"));
  fn.glXQueryExtensionFn = reinterpret_cast<glXQueryExtensionProc>(
      GetGLProcAddress("glXQueryExtension"));
  fn.glXQueryExtensionsStringFn =
      reinterpret_cast<glXQueryExtensionsStringProc>(
          GetGLProcAddress("glXQueryExtensionsString"));
  fn.glXQueryServerStringFn = reinterpret_cast<glXQueryServerStringProc>(
      GetGLProcAddress("glXQueryServerString"));
  fn.glXQueryVersionFn = reinterpret_cast<glXQueryVersionProc>(
      GetGLProcAddress("glXQueryVersion"));
  fn.glXReleaseTexImageEXTFn = 0;
  fn.glXSelectEventFn =
      reinterpret_cast<glXSelectEventProc>(GetGLProcAddress("glXSelectEvent"));
  fn.glXSwapBuffersFn =
      reinterpret_cast<glXSwapBuffersProc>(GetGLProcAddress("glXSwapBuffers"));
  fn.glXSwapIntervalEXTFn = 0;
  fn.glXSwapIntervalMESAFn = 0;
  fn.glXUseXFontFn =
      reinterpret_cast<glXUseXFontProc>(GetGLProcAddress("glXUseXFont"));
  fn.glXWaitGLFn =
      reinterpret_cast<glXWaitGLProc>(GetGLProcAddress("glXWaitGL"));
  fn.glXWaitVideoSyncSGIFn = 0;
  fn.glXWaitXFn = reinterpret_cast<glXWaitXProc>(GetGLProcAddress("glXWaitX"));
  std::string extensions(GetPlatformExtensions());
  extensions += " ";
  ALLOW_UNUSED_LOCAL(extensions);

  ext.b_GLX_ARB_create_context =
      extensions.find("GLX_ARB_create_context ") != std::string::npos;
  ext.b_GLX_EXT_swap_control =
      extensions.find("GLX_EXT_swap_control ") != std::string::npos;
  ext.b_GLX_EXT_texture_from_pixmap =
      extensions.find("GLX_EXT_texture_from_pixmap ") != std::string::npos;
  ext.b_GLX_MESA_copy_sub_buffer =
      extensions.find("GLX_MESA_copy_sub_buffer ") != std::string::npos;
  ext.b_GLX_MESA_swap_control =
      extensions.find("GLX_MESA_swap_control ") != std::string::npos;
  ext.b_GLX_OML_sync_control =
      extensions.find("GLX_OML_sync_control ") != std::string::npos;
  ext.b_GLX_SGIX_fbconfig =
      extensions.find("GLX_SGIX_fbconfig ") != std::string::npos;
  ext.b_GLX_SGI_video_sync =
      extensions.find("GLX_SGI_video_sync ") != std::string::npos;

  debug_fn.glXBindTexImageEXTFn = 0;
  if (ext.b_GLX_EXT_texture_from_pixmap) {
    fn.glXBindTexImageEXTFn = reinterpret_cast<glXBindTexImageEXTProc>(
        GetGLProcAddress("glXBindTexImageEXT"));
    DCHECK(fn.glXBindTexImageEXTFn);
  }

  debug_fn.glXCopySubBufferMESAFn = 0;
  if (ext.b_GLX_MESA_copy_sub_buffer) {
    fn.glXCopySubBufferMESAFn = reinterpret_cast<glXCopySubBufferMESAProc>(
        GetGLProcAddress("glXCopySubBufferMESA"));
    DCHECK(fn.glXCopySubBufferMESAFn);
  }

  debug_fn.glXCreateContextAttribsARBFn = 0;
  if (ext.b_GLX_ARB_create_context) {
    fn.glXCreateContextAttribsARBFn =
        reinterpret_cast<glXCreateContextAttribsARBProc>(
            GetGLProcAddress("glXCreateContextAttribsARB"));
    DCHECK(fn.glXCreateContextAttribsARBFn);
  }

  debug_fn.glXGetFBConfigFromVisualSGIXFn = 0;
  if (ext.b_GLX_SGIX_fbconfig) {
    fn.glXGetFBConfigFromVisualSGIXFn =
        reinterpret_cast<glXGetFBConfigFromVisualSGIXProc>(
            GetGLProcAddress("glXGetFBConfigFromVisualSGIX"));
    DCHECK(fn.glXGetFBConfigFromVisualSGIXFn);
  }

  debug_fn.glXGetMscRateOMLFn = 0;
  if (ext.b_GLX_OML_sync_control) {
    fn.glXGetMscRateOMLFn = reinterpret_cast<glXGetMscRateOMLProc>(
        GetGLProcAddress("glXGetMscRateOML"));
    DCHECK(fn.glXGetMscRateOMLFn);
  }

  debug_fn.glXGetSyncValuesOMLFn = 0;
  if (ext.b_GLX_OML_sync_control) {
    fn.glXGetSyncValuesOMLFn = reinterpret_cast<glXGetSyncValuesOMLProc>(
        GetGLProcAddress("glXGetSyncValuesOML"));
    DCHECK(fn.glXGetSyncValuesOMLFn);
  }

  debug_fn.glXReleaseTexImageEXTFn = 0;
  if (ext.b_GLX_EXT_texture_from_pixmap) {
    fn.glXReleaseTexImageEXTFn = reinterpret_cast<glXReleaseTexImageEXTProc>(
        GetGLProcAddress("glXReleaseTexImageEXT"));
    DCHECK(fn.glXReleaseTexImageEXTFn);
  }

  debug_fn.glXSwapIntervalEXTFn = 0;
  if (ext.b_GLX_EXT_swap_control) {
    fn.glXSwapIntervalEXTFn = reinterpret_cast<glXSwapIntervalEXTProc>(
        GetGLProcAddress("glXSwapIntervalEXT"));
    DCHECK(fn.glXSwapIntervalEXTFn);
  }

  debug_fn.glXSwapIntervalMESAFn = 0;
  if (ext.b_GLX_MESA_swap_control) {
    fn.glXSwapIntervalMESAFn = reinterpret_cast<glXSwapIntervalMESAProc>(
        GetGLProcAddress("glXSwapIntervalMESA"));
    DCHECK(fn.glXSwapIntervalMESAFn);
  }

  debug_fn.glXWaitVideoSyncSGIFn = 0;
  if (ext.b_GLX_SGI_video_sync) {
    fn.glXWaitVideoSyncSGIFn = reinterpret_cast<glXWaitVideoSyncSGIProc>(
        GetGLProcAddress("glXWaitVideoSyncSGI"));
    DCHECK(fn.glXWaitVideoSyncSGIFn);
  }

  if (g_debugBindingsInitialized)
    InitializeDebugBindings();
}

extern "C" {

static void GL_BINDING_CALL Debug_glXBindTexImageEXT(Display* dpy,
                                                     GLXDrawable drawable,
                                                     int buffer,
                                                     int* attribList) {
  GL_SERVICE_LOG("glXBindTexImageEXT"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ", " << buffer << ", "
                 << static_cast<const void*>(attribList) << ")");
  g_driver_glx.debug_fn.glXBindTexImageEXTFn(dpy, drawable, buffer, attribList);
}

static GLXFBConfig* GL_BINDING_CALL
Debug_glXChooseFBConfig(Display* dpy,
                        int screen,
                        const int* attribList,
                        int* nitems) {
  GL_SERVICE_LOG("glXChooseFBConfig"
                 << "(" << static_cast<const void*>(dpy) << ", " << screen
                 << ", " << static_cast<const void*>(attribList) << ", "
                 << static_cast<const void*>(nitems) << ")");
  GLXFBConfig* result = g_driver_glx.debug_fn.glXChooseFBConfigFn(
      dpy, screen, attribList, nitems);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static XVisualInfo* GL_BINDING_CALL
Debug_glXChooseVisual(Display* dpy, int screen, int* attribList) {
  GL_SERVICE_LOG("glXChooseVisual"
                 << "(" << static_cast<const void*>(dpy) << ", " << screen
                 << ", " << static_cast<const void*>(attribList) << ")");
  XVisualInfo* result =
      g_driver_glx.debug_fn.glXChooseVisualFn(dpy, screen, attribList);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static void GL_BINDING_CALL Debug_glXCopyContext(Display* dpy,
                                                 GLXContext src,
                                                 GLXContext dst,
                                                 unsigned long mask) {
  GL_SERVICE_LOG("glXCopyContext"
                 << "(" << static_cast<const void*>(dpy) << ", " << src << ", "
                 << dst << ", " << mask << ")");
  g_driver_glx.debug_fn.glXCopyContextFn(dpy, src, dst, mask);
}

static void GL_BINDING_CALL Debug_glXCopySubBufferMESA(Display* dpy,
                                                       GLXDrawable drawable,
                                                       int x,
                                                       int y,
                                                       int width,
                                                       int height) {
  GL_SERVICE_LOG("glXCopySubBufferMESA"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ", " << x << ", " << y << ", " << width << ", " << height
                 << ")");
  g_driver_glx.debug_fn.glXCopySubBufferMESAFn(dpy, drawable, x, y, width,
                                               height);
}

static GLXContext GL_BINDING_CALL Debug_glXCreateContext(Display* dpy,
                                                         XVisualInfo* vis,
                                                         GLXContext shareList,
                                                         int direct) {
  GL_SERVICE_LOG("glXCreateContext"
                 << "(" << static_cast<const void*>(dpy) << ", "
                 << static_cast<const void*>(vis) << ", " << shareList << ", "
                 << direct << ")");
  GLXContext result =
      g_driver_glx.debug_fn.glXCreateContextFn(dpy, vis, shareList, direct);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXContext GL_BINDING_CALL
Debug_glXCreateContextAttribsARB(Display* dpy,
                                 GLXFBConfig config,
                                 GLXContext share_context,
                                 int direct,
                                 const int* attrib_list) {
  GL_SERVICE_LOG("glXCreateContextAttribsARB"
                 << "(" << static_cast<const void*>(dpy) << ", " << config
                 << ", " << share_context << ", " << direct << ", "
                 << static_cast<const void*>(attrib_list) << ")");
  GLXContext result = g_driver_glx.debug_fn.glXCreateContextAttribsARBFn(
      dpy, config, share_context, direct, attrib_list);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXPixmap GL_BINDING_CALL
Debug_glXCreateGLXPixmap(Display* dpy, XVisualInfo* visual, Pixmap pixmap) {
  GL_SERVICE_LOG("glXCreateGLXPixmap"
                 << "(" << static_cast<const void*>(dpy) << ", "
                 << static_cast<const void*>(visual) << ", " << pixmap << ")");
  GLXPixmap result =
      g_driver_glx.debug_fn.glXCreateGLXPixmapFn(dpy, visual, pixmap);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXContext GL_BINDING_CALL
Debug_glXCreateNewContext(Display* dpy,
                          GLXFBConfig config,
                          int renderType,
                          GLXContext shareList,
                          int direct) {
  GL_SERVICE_LOG("glXCreateNewContext"
                 << "(" << static_cast<const void*>(dpy) << ", " << config
                 << ", " << renderType << ", " << shareList << ", " << direct
                 << ")");
  GLXContext result = g_driver_glx.debug_fn.glXCreateNewContextFn(
      dpy, config, renderType, shareList, direct);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXPbuffer GL_BINDING_CALL
Debug_glXCreatePbuffer(Display* dpy,
                       GLXFBConfig config,
                       const int* attribList) {
  GL_SERVICE_LOG("glXCreatePbuffer"
                 << "(" << static_cast<const void*>(dpy) << ", " << config
                 << ", " << static_cast<const void*>(attribList) << ")");
  GLXPbuffer result =
      g_driver_glx.debug_fn.glXCreatePbufferFn(dpy, config, attribList);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXPixmap GL_BINDING_CALL Debug_glXCreatePixmap(Display* dpy,
                                                       GLXFBConfig config,
                                                       Pixmap pixmap,
                                                       const int* attribList) {
  GL_SERVICE_LOG("glXCreatePixmap"
                 << "(" << static_cast<const void*>(dpy) << ", " << config
                 << ", " << pixmap << ", "
                 << static_cast<const void*>(attribList) << ")");
  GLXPixmap result =
      g_driver_glx.debug_fn.glXCreatePixmapFn(dpy, config, pixmap, attribList);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXWindow GL_BINDING_CALL Debug_glXCreateWindow(Display* dpy,
                                                       GLXFBConfig config,
                                                       Window win,
                                                       const int* attribList) {
  GL_SERVICE_LOG("glXCreateWindow"
                 << "(" << static_cast<const void*>(dpy) << ", " << config
                 << ", " << win << ", " << static_cast<const void*>(attribList)
                 << ")");
  GLXWindow result =
      g_driver_glx.debug_fn.glXCreateWindowFn(dpy, config, win, attribList);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static void GL_BINDING_CALL
Debug_glXDestroyContext(Display* dpy, GLXContext ctx) {
  GL_SERVICE_LOG("glXDestroyContext"
                 << "(" << static_cast<const void*>(dpy) << ", " << ctx << ")");
  g_driver_glx.debug_fn.glXDestroyContextFn(dpy, ctx);
}

static void GL_BINDING_CALL
Debug_glXDestroyGLXPixmap(Display* dpy, GLXPixmap pixmap) {
  GL_SERVICE_LOG("glXDestroyGLXPixmap"
                 << "(" << static_cast<const void*>(dpy) << ", " << pixmap
                 << ")");
  g_driver_glx.debug_fn.glXDestroyGLXPixmapFn(dpy, pixmap);
}

static void GL_BINDING_CALL
Debug_glXDestroyPbuffer(Display* dpy, GLXPbuffer pbuf) {
  GL_SERVICE_LOG("glXDestroyPbuffer"
                 << "(" << static_cast<const void*>(dpy) << ", " << pbuf
                 << ")");
  g_driver_glx.debug_fn.glXDestroyPbufferFn(dpy, pbuf);
}

static void GL_BINDING_CALL
Debug_glXDestroyPixmap(Display* dpy, GLXPixmap pixmap) {
  GL_SERVICE_LOG("glXDestroyPixmap"
                 << "(" << static_cast<const void*>(dpy) << ", " << pixmap
                 << ")");
  g_driver_glx.debug_fn.glXDestroyPixmapFn(dpy, pixmap);
}

static void GL_BINDING_CALL
Debug_glXDestroyWindow(Display* dpy, GLXWindow window) {
  GL_SERVICE_LOG("glXDestroyWindow"
                 << "(" << static_cast<const void*>(dpy) << ", " << window
                 << ")");
  g_driver_glx.debug_fn.glXDestroyWindowFn(dpy, window);
}

static const char* GL_BINDING_CALL
Debug_glXGetClientString(Display* dpy, int name) {
  GL_SERVICE_LOG("glXGetClientString"
                 << "(" << static_cast<const void*>(dpy) << ", " << name
                 << ")");
  const char* result = g_driver_glx.debug_fn.glXGetClientStringFn(dpy, name);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static int GL_BINDING_CALL
Debug_glXGetConfig(Display* dpy, XVisualInfo* visual, int attrib, int* value) {
  GL_SERVICE_LOG("glXGetConfig"
                 << "(" << static_cast<const void*>(dpy) << ", "
                 << static_cast<const void*>(visual) << ", " << attrib << ", "
                 << static_cast<const void*>(value) << ")");
  int result = g_driver_glx.debug_fn.glXGetConfigFn(dpy, visual, attrib, value);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXContext GL_BINDING_CALL Debug_glXGetCurrentContext(void) {
  GL_SERVICE_LOG("glXGetCurrentContext"
                 << "("
                 << ")");
  GLXContext result = g_driver_glx.debug_fn.glXGetCurrentContextFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static Display* GL_BINDING_CALL Debug_glXGetCurrentDisplay(void) {
  GL_SERVICE_LOG("glXGetCurrentDisplay"
                 << "("
                 << ")");
  Display* result = g_driver_glx.debug_fn.glXGetCurrentDisplayFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXDrawable GL_BINDING_CALL Debug_glXGetCurrentDrawable(void) {
  GL_SERVICE_LOG("glXGetCurrentDrawable"
                 << "("
                 << ")");
  GLXDrawable result = g_driver_glx.debug_fn.glXGetCurrentDrawableFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXDrawable GL_BINDING_CALL Debug_glXGetCurrentReadDrawable(void) {
  GL_SERVICE_LOG("glXGetCurrentReadDrawable"
                 << "("
                 << ")");
  GLXDrawable result = g_driver_glx.debug_fn.glXGetCurrentReadDrawableFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static int GL_BINDING_CALL Debug_glXGetFBConfigAttrib(Display* dpy,
                                                      GLXFBConfig config,
                                                      int attribute,
                                                      int* value) {
  GL_SERVICE_LOG("glXGetFBConfigAttrib"
                 << "(" << static_cast<const void*>(dpy) << ", " << config
                 << ", " << attribute << ", " << static_cast<const void*>(value)
                 << ")");
  int result = g_driver_glx.debug_fn.glXGetFBConfigAttribFn(dpy, config,
                                                            attribute, value);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXFBConfig GL_BINDING_CALL
Debug_glXGetFBConfigFromVisualSGIX(Display* dpy, XVisualInfo* visualInfo) {
  GL_SERVICE_LOG("glXGetFBConfigFromVisualSGIX"
                 << "(" << static_cast<const void*>(dpy) << ", "
                 << static_cast<const void*>(visualInfo) << ")");
  GLXFBConfig result =
      g_driver_glx.debug_fn.glXGetFBConfigFromVisualSGIXFn(dpy, visualInfo);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLXFBConfig* GL_BINDING_CALL
Debug_glXGetFBConfigs(Display* dpy, int screen, int* nelements) {
  GL_SERVICE_LOG("glXGetFBConfigs"
                 << "(" << static_cast<const void*>(dpy) << ", " << screen
                 << ", " << static_cast<const void*>(nelements) << ")");
  GLXFBConfig* result =
      g_driver_glx.debug_fn.glXGetFBConfigsFn(dpy, screen, nelements);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static bool GL_BINDING_CALL Debug_glXGetMscRateOML(Display* dpy,
                                                   GLXDrawable drawable,
                                                   int32* numerator,
                                                   int32* denominator) {
  GL_SERVICE_LOG("glXGetMscRateOML"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ", " << static_cast<const void*>(numerator) << ", "
                 << static_cast<const void*>(denominator) << ")");
  bool result = g_driver_glx.debug_fn.glXGetMscRateOMLFn(
      dpy, drawable, numerator, denominator);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static void GL_BINDING_CALL Debug_glXGetSelectedEvent(Display* dpy,
                                                      GLXDrawable drawable,
                                                      unsigned long* mask) {
  GL_SERVICE_LOG("glXGetSelectedEvent"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ", " << static_cast<const void*>(mask) << ")");
  g_driver_glx.debug_fn.glXGetSelectedEventFn(dpy, drawable, mask);
}

static bool GL_BINDING_CALL Debug_glXGetSyncValuesOML(Display* dpy,
                                                      GLXDrawable drawable,
                                                      int64* ust,
                                                      int64* msc,
                                                      int64* sbc) {
  GL_SERVICE_LOG("glXGetSyncValuesOML"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ", " << static_cast<const void*>(ust) << ", "
                 << static_cast<const void*>(msc) << ", "
                 << static_cast<const void*>(sbc) << ")");
  bool result =
      g_driver_glx.debug_fn.glXGetSyncValuesOMLFn(dpy, drawable, ust, msc, sbc);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static XVisualInfo* GL_BINDING_CALL
Debug_glXGetVisualFromFBConfig(Display* dpy, GLXFBConfig config) {
  GL_SERVICE_LOG("glXGetVisualFromFBConfig"
                 << "(" << static_cast<const void*>(dpy) << ", " << config
                 << ")");
  XVisualInfo* result =
      g_driver_glx.debug_fn.glXGetVisualFromFBConfigFn(dpy, config);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static int GL_BINDING_CALL Debug_glXIsDirect(Display* dpy, GLXContext ctx) {
  GL_SERVICE_LOG("glXIsDirect"
                 << "(" << static_cast<const void*>(dpy) << ", " << ctx << ")");
  int result = g_driver_glx.debug_fn.glXIsDirectFn(dpy, ctx);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static int GL_BINDING_CALL Debug_glXMakeContextCurrent(Display* dpy,
                                                       GLXDrawable draw,
                                                       GLXDrawable read,
                                                       GLXContext ctx) {
  GL_SERVICE_LOG("glXMakeContextCurrent"
                 << "(" << static_cast<const void*>(dpy) << ", " << draw << ", "
                 << read << ", " << ctx << ")");
  int result =
      g_driver_glx.debug_fn.glXMakeContextCurrentFn(dpy, draw, read, ctx);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static int GL_BINDING_CALL
Debug_glXMakeCurrent(Display* dpy, GLXDrawable drawable, GLXContext ctx) {
  GL_SERVICE_LOG("glXMakeCurrent"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ", " << ctx << ")");
  int result = g_driver_glx.debug_fn.glXMakeCurrentFn(dpy, drawable, ctx);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static int GL_BINDING_CALL
Debug_glXQueryContext(Display* dpy, GLXContext ctx, int attribute, int* value) {
  GL_SERVICE_LOG("glXQueryContext"
                 << "(" << static_cast<const void*>(dpy) << ", " << ctx << ", "
                 << attribute << ", " << static_cast<const void*>(value)
                 << ")");
  int result =
      g_driver_glx.debug_fn.glXQueryContextFn(dpy, ctx, attribute, value);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static void GL_BINDING_CALL Debug_glXQueryDrawable(Display* dpy,
                                                   GLXDrawable draw,
                                                   int attribute,
                                                   unsigned int* value) {
  GL_SERVICE_LOG("glXQueryDrawable"
                 << "(" << static_cast<const void*>(dpy) << ", " << draw << ", "
                 << attribute << ", " << static_cast<const void*>(value)
                 << ")");
  g_driver_glx.debug_fn.glXQueryDrawableFn(dpy, draw, attribute, value);
}

static int GL_BINDING_CALL
Debug_glXQueryExtension(Display* dpy, int* errorb, int* event) {
  GL_SERVICE_LOG("glXQueryExtension"
                 << "(" << static_cast<const void*>(dpy) << ", "
                 << static_cast<const void*>(errorb) << ", "
                 << static_cast<const void*>(event) << ")");
  int result = g_driver_glx.debug_fn.glXQueryExtensionFn(dpy, errorb, event);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static const char* GL_BINDING_CALL
Debug_glXQueryExtensionsString(Display* dpy, int screen) {
  GL_SERVICE_LOG("glXQueryExtensionsString"
                 << "(" << static_cast<const void*>(dpy) << ", " << screen
                 << ")");
  const char* result =
      g_driver_glx.debug_fn.glXQueryExtensionsStringFn(dpy, screen);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static const char* GL_BINDING_CALL
Debug_glXQueryServerString(Display* dpy, int screen, int name) {
  GL_SERVICE_LOG("glXQueryServerString"
                 << "(" << static_cast<const void*>(dpy) << ", " << screen
                 << ", " << name << ")");
  const char* result =
      g_driver_glx.debug_fn.glXQueryServerStringFn(dpy, screen, name);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static int GL_BINDING_CALL
Debug_glXQueryVersion(Display* dpy, int* maj, int* min) {
  GL_SERVICE_LOG("glXQueryVersion"
                 << "(" << static_cast<const void*>(dpy) << ", "
                 << static_cast<const void*>(maj) << ", "
                 << static_cast<const void*>(min) << ")");
  int result = g_driver_glx.debug_fn.glXQueryVersionFn(dpy, maj, min);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static void GL_BINDING_CALL
Debug_glXReleaseTexImageEXT(Display* dpy, GLXDrawable drawable, int buffer) {
  GL_SERVICE_LOG("glXReleaseTexImageEXT"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ", " << buffer << ")");
  g_driver_glx.debug_fn.glXReleaseTexImageEXTFn(dpy, drawable, buffer);
}

static void GL_BINDING_CALL
Debug_glXSelectEvent(Display* dpy, GLXDrawable drawable, unsigned long mask) {
  GL_SERVICE_LOG("glXSelectEvent"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ", " << mask << ")");
  g_driver_glx.debug_fn.glXSelectEventFn(dpy, drawable, mask);
}

static void GL_BINDING_CALL
Debug_glXSwapBuffers(Display* dpy, GLXDrawable drawable) {
  GL_SERVICE_LOG("glXSwapBuffers"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ")");
  g_driver_glx.debug_fn.glXSwapBuffersFn(dpy, drawable);
}

static void GL_BINDING_CALL
Debug_glXSwapIntervalEXT(Display* dpy, GLXDrawable drawable, int interval) {
  GL_SERVICE_LOG("glXSwapIntervalEXT"
                 << "(" << static_cast<const void*>(dpy) << ", " << drawable
                 << ", " << interval << ")");
  g_driver_glx.debug_fn.glXSwapIntervalEXTFn(dpy, drawable, interval);
}

static void GL_BINDING_CALL Debug_glXSwapIntervalMESA(unsigned int interval) {
  GL_SERVICE_LOG("glXSwapIntervalMESA"
                 << "(" << interval << ")");
  g_driver_glx.debug_fn.glXSwapIntervalMESAFn(interval);
}

static void GL_BINDING_CALL
Debug_glXUseXFont(Font font, int first, int count, int list) {
  GL_SERVICE_LOG("glXUseXFont"
                 << "(" << font << ", " << first << ", " << count << ", "
                 << list << ")");
  g_driver_glx.debug_fn.glXUseXFontFn(font, first, count, list);
}

static void GL_BINDING_CALL Debug_glXWaitGL(void) {
  GL_SERVICE_LOG("glXWaitGL"
                 << "("
                 << ")");
  g_driver_glx.debug_fn.glXWaitGLFn();
}

static int GL_BINDING_CALL
Debug_glXWaitVideoSyncSGI(int divisor, int remainder, unsigned int* count) {
  GL_SERVICE_LOG("glXWaitVideoSyncSGI"
                 << "(" << divisor << ", " << remainder << ", "
                 << static_cast<const void*>(count) << ")");
  int result =
      g_driver_glx.debug_fn.glXWaitVideoSyncSGIFn(divisor, remainder, count);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static void GL_BINDING_CALL Debug_glXWaitX(void) {
  GL_SERVICE_LOG("glXWaitX"
                 << "("
                 << ")");
  g_driver_glx.debug_fn.glXWaitXFn();
}
}  // extern "C"

void DriverGLX::InitializeDebugBindings() {
  if (!debug_fn.glXBindTexImageEXTFn) {
    debug_fn.glXBindTexImageEXTFn = fn.glXBindTexImageEXTFn;
    fn.glXBindTexImageEXTFn = Debug_glXBindTexImageEXT;
  }
  if (!debug_fn.glXChooseFBConfigFn) {
    debug_fn.glXChooseFBConfigFn = fn.glXChooseFBConfigFn;
    fn.glXChooseFBConfigFn = Debug_glXChooseFBConfig;
  }
  if (!debug_fn.glXChooseVisualFn) {
    debug_fn.glXChooseVisualFn = fn.glXChooseVisualFn;
    fn.glXChooseVisualFn = Debug_glXChooseVisual;
  }
  if (!debug_fn.glXCopyContextFn) {
    debug_fn.glXCopyContextFn = fn.glXCopyContextFn;
    fn.glXCopyContextFn = Debug_glXCopyContext;
  }
  if (!debug_fn.glXCopySubBufferMESAFn) {
    debug_fn.glXCopySubBufferMESAFn = fn.glXCopySubBufferMESAFn;
    fn.glXCopySubBufferMESAFn = Debug_glXCopySubBufferMESA;
  }
  if (!debug_fn.glXCreateContextFn) {
    debug_fn.glXCreateContextFn = fn.glXCreateContextFn;
    fn.glXCreateContextFn = Debug_glXCreateContext;
  }
  if (!debug_fn.glXCreateContextAttribsARBFn) {
    debug_fn.glXCreateContextAttribsARBFn = fn.glXCreateContextAttribsARBFn;
    fn.glXCreateContextAttribsARBFn = Debug_glXCreateContextAttribsARB;
  }
  if (!debug_fn.glXCreateGLXPixmapFn) {
    debug_fn.glXCreateGLXPixmapFn = fn.glXCreateGLXPixmapFn;
    fn.glXCreateGLXPixmapFn = Debug_glXCreateGLXPixmap;
  }
  if (!debug_fn.glXCreateNewContextFn) {
    debug_fn.glXCreateNewContextFn = fn.glXCreateNewContextFn;
    fn.glXCreateNewContextFn = Debug_glXCreateNewContext;
  }
  if (!debug_fn.glXCreatePbufferFn) {
    debug_fn.glXCreatePbufferFn = fn.glXCreatePbufferFn;
    fn.glXCreatePbufferFn = Debug_glXCreatePbuffer;
  }
  if (!debug_fn.glXCreatePixmapFn) {
    debug_fn.glXCreatePixmapFn = fn.glXCreatePixmapFn;
    fn.glXCreatePixmapFn = Debug_glXCreatePixmap;
  }
  if (!debug_fn.glXCreateWindowFn) {
    debug_fn.glXCreateWindowFn = fn.glXCreateWindowFn;
    fn.glXCreateWindowFn = Debug_glXCreateWindow;
  }
  if (!debug_fn.glXDestroyContextFn) {
    debug_fn.glXDestroyContextFn = fn.glXDestroyContextFn;
    fn.glXDestroyContextFn = Debug_glXDestroyContext;
  }
  if (!debug_fn.glXDestroyGLXPixmapFn) {
    debug_fn.glXDestroyGLXPixmapFn = fn.glXDestroyGLXPixmapFn;
    fn.glXDestroyGLXPixmapFn = Debug_glXDestroyGLXPixmap;
  }
  if (!debug_fn.glXDestroyPbufferFn) {
    debug_fn.glXDestroyPbufferFn = fn.glXDestroyPbufferFn;
    fn.glXDestroyPbufferFn = Debug_glXDestroyPbuffer;
  }
  if (!debug_fn.glXDestroyPixmapFn) {
    debug_fn.glXDestroyPixmapFn = fn.glXDestroyPixmapFn;
    fn.glXDestroyPixmapFn = Debug_glXDestroyPixmap;
  }
  if (!debug_fn.glXDestroyWindowFn) {
    debug_fn.glXDestroyWindowFn = fn.glXDestroyWindowFn;
    fn.glXDestroyWindowFn = Debug_glXDestroyWindow;
  }
  if (!debug_fn.glXGetClientStringFn) {
    debug_fn.glXGetClientStringFn = fn.glXGetClientStringFn;
    fn.glXGetClientStringFn = Debug_glXGetClientString;
  }
  if (!debug_fn.glXGetConfigFn) {
    debug_fn.glXGetConfigFn = fn.glXGetConfigFn;
    fn.glXGetConfigFn = Debug_glXGetConfig;
  }
  if (!debug_fn.glXGetCurrentContextFn) {
    debug_fn.glXGetCurrentContextFn = fn.glXGetCurrentContextFn;
    fn.glXGetCurrentContextFn = Debug_glXGetCurrentContext;
  }
  if (!debug_fn.glXGetCurrentDisplayFn) {
    debug_fn.glXGetCurrentDisplayFn = fn.glXGetCurrentDisplayFn;
    fn.glXGetCurrentDisplayFn = Debug_glXGetCurrentDisplay;
  }
  if (!debug_fn.glXGetCurrentDrawableFn) {
    debug_fn.glXGetCurrentDrawableFn = fn.glXGetCurrentDrawableFn;
    fn.glXGetCurrentDrawableFn = Debug_glXGetCurrentDrawable;
  }
  if (!debug_fn.glXGetCurrentReadDrawableFn) {
    debug_fn.glXGetCurrentReadDrawableFn = fn.glXGetCurrentReadDrawableFn;
    fn.glXGetCurrentReadDrawableFn = Debug_glXGetCurrentReadDrawable;
  }
  if (!debug_fn.glXGetFBConfigAttribFn) {
    debug_fn.glXGetFBConfigAttribFn = fn.glXGetFBConfigAttribFn;
    fn.glXGetFBConfigAttribFn = Debug_glXGetFBConfigAttrib;
  }
  if (!debug_fn.glXGetFBConfigFromVisualSGIXFn) {
    debug_fn.glXGetFBConfigFromVisualSGIXFn = fn.glXGetFBConfigFromVisualSGIXFn;
    fn.glXGetFBConfigFromVisualSGIXFn = Debug_glXGetFBConfigFromVisualSGIX;
  }
  if (!debug_fn.glXGetFBConfigsFn) {
    debug_fn.glXGetFBConfigsFn = fn.glXGetFBConfigsFn;
    fn.glXGetFBConfigsFn = Debug_glXGetFBConfigs;
  }
  if (!debug_fn.glXGetMscRateOMLFn) {
    debug_fn.glXGetMscRateOMLFn = fn.glXGetMscRateOMLFn;
    fn.glXGetMscRateOMLFn = Debug_glXGetMscRateOML;
  }
  if (!debug_fn.glXGetSelectedEventFn) {
    debug_fn.glXGetSelectedEventFn = fn.glXGetSelectedEventFn;
    fn.glXGetSelectedEventFn = Debug_glXGetSelectedEvent;
  }
  if (!debug_fn.glXGetSyncValuesOMLFn) {
    debug_fn.glXGetSyncValuesOMLFn = fn.glXGetSyncValuesOMLFn;
    fn.glXGetSyncValuesOMLFn = Debug_glXGetSyncValuesOML;
  }
  if (!debug_fn.glXGetVisualFromFBConfigFn) {
    debug_fn.glXGetVisualFromFBConfigFn = fn.glXGetVisualFromFBConfigFn;
    fn.glXGetVisualFromFBConfigFn = Debug_glXGetVisualFromFBConfig;
  }
  if (!debug_fn.glXIsDirectFn) {
    debug_fn.glXIsDirectFn = fn.glXIsDirectFn;
    fn.glXIsDirectFn = Debug_glXIsDirect;
  }
  if (!debug_fn.glXMakeContextCurrentFn) {
    debug_fn.glXMakeContextCurrentFn = fn.glXMakeContextCurrentFn;
    fn.glXMakeContextCurrentFn = Debug_glXMakeContextCurrent;
  }
  if (!debug_fn.glXMakeCurrentFn) {
    debug_fn.glXMakeCurrentFn = fn.glXMakeCurrentFn;
    fn.glXMakeCurrentFn = Debug_glXMakeCurrent;
  }
  if (!debug_fn.glXQueryContextFn) {
    debug_fn.glXQueryContextFn = fn.glXQueryContextFn;
    fn.glXQueryContextFn = Debug_glXQueryContext;
  }
  if (!debug_fn.glXQueryDrawableFn) {
    debug_fn.glXQueryDrawableFn = fn.glXQueryDrawableFn;
    fn.glXQueryDrawableFn = Debug_glXQueryDrawable;
  }
  if (!debug_fn.glXQueryExtensionFn) {
    debug_fn.glXQueryExtensionFn = fn.glXQueryExtensionFn;
    fn.glXQueryExtensionFn = Debug_glXQueryExtension;
  }
  if (!debug_fn.glXQueryExtensionsStringFn) {
    debug_fn.glXQueryExtensionsStringFn = fn.glXQueryExtensionsStringFn;
    fn.glXQueryExtensionsStringFn = Debug_glXQueryExtensionsString;
  }
  if (!debug_fn.glXQueryServerStringFn) {
    debug_fn.glXQueryServerStringFn = fn.glXQueryServerStringFn;
    fn.glXQueryServerStringFn = Debug_glXQueryServerString;
  }
  if (!debug_fn.glXQueryVersionFn) {
    debug_fn.glXQueryVersionFn = fn.glXQueryVersionFn;
    fn.glXQueryVersionFn = Debug_glXQueryVersion;
  }
  if (!debug_fn.glXReleaseTexImageEXTFn) {
    debug_fn.glXReleaseTexImageEXTFn = fn.glXReleaseTexImageEXTFn;
    fn.glXReleaseTexImageEXTFn = Debug_glXReleaseTexImageEXT;
  }
  if (!debug_fn.glXSelectEventFn) {
    debug_fn.glXSelectEventFn = fn.glXSelectEventFn;
    fn.glXSelectEventFn = Debug_glXSelectEvent;
  }
  if (!debug_fn.glXSwapBuffersFn) {
    debug_fn.glXSwapBuffersFn = fn.glXSwapBuffersFn;
    fn.glXSwapBuffersFn = Debug_glXSwapBuffers;
  }
  if (!debug_fn.glXSwapIntervalEXTFn) {
    debug_fn.glXSwapIntervalEXTFn = fn.glXSwapIntervalEXTFn;
    fn.glXSwapIntervalEXTFn = Debug_glXSwapIntervalEXT;
  }
  if (!debug_fn.glXSwapIntervalMESAFn) {
    debug_fn.glXSwapIntervalMESAFn = fn.glXSwapIntervalMESAFn;
    fn.glXSwapIntervalMESAFn = Debug_glXSwapIntervalMESA;
  }
  if (!debug_fn.glXUseXFontFn) {
    debug_fn.glXUseXFontFn = fn.glXUseXFontFn;
    fn.glXUseXFontFn = Debug_glXUseXFont;
  }
  if (!debug_fn.glXWaitGLFn) {
    debug_fn.glXWaitGLFn = fn.glXWaitGLFn;
    fn.glXWaitGLFn = Debug_glXWaitGL;
  }
  if (!debug_fn.glXWaitVideoSyncSGIFn) {
    debug_fn.glXWaitVideoSyncSGIFn = fn.glXWaitVideoSyncSGIFn;
    fn.glXWaitVideoSyncSGIFn = Debug_glXWaitVideoSyncSGI;
  }
  if (!debug_fn.glXWaitXFn) {
    debug_fn.glXWaitXFn = fn.glXWaitXFn;
    fn.glXWaitXFn = Debug_glXWaitX;
  }
  g_debugBindingsInitialized = true;
}

void DriverGLX::ClearBindings() {
  memset(this, 0, sizeof(*this));
}

void GLXApiBase::glXBindTexImageEXTFn(Display* dpy,
                                      GLXDrawable drawable,
                                      int buffer,
                                      int* attribList) {
  driver_->fn.glXBindTexImageEXTFn(dpy, drawable, buffer, attribList);
}

GLXFBConfig* GLXApiBase::glXChooseFBConfigFn(Display* dpy,
                                             int screen,
                                             const int* attribList,
                                             int* nitems) {
  return driver_->fn.glXChooseFBConfigFn(dpy, screen, attribList, nitems);
}

XVisualInfo* GLXApiBase::glXChooseVisualFn(Display* dpy,
                                           int screen,
                                           int* attribList) {
  return driver_->fn.glXChooseVisualFn(dpy, screen, attribList);
}

void GLXApiBase::glXCopyContextFn(Display* dpy,
                                  GLXContext src,
                                  GLXContext dst,
                                  unsigned long mask) {
  driver_->fn.glXCopyContextFn(dpy, src, dst, mask);
}

void GLXApiBase::glXCopySubBufferMESAFn(Display* dpy,
                                        GLXDrawable drawable,
                                        int x,
                                        int y,
                                        int width,
                                        int height) {
  driver_->fn.glXCopySubBufferMESAFn(dpy, drawable, x, y, width, height);
}

GLXContext GLXApiBase::glXCreateContextFn(Display* dpy,
                                          XVisualInfo* vis,
                                          GLXContext shareList,
                                          int direct) {
  return driver_->fn.glXCreateContextFn(dpy, vis, shareList, direct);
}

GLXContext GLXApiBase::glXCreateContextAttribsARBFn(Display* dpy,
                                                    GLXFBConfig config,
                                                    GLXContext share_context,
                                                    int direct,
                                                    const int* attrib_list) {
  return driver_->fn.glXCreateContextAttribsARBFn(dpy, config, share_context,
                                                  direct, attrib_list);
}

GLXPixmap GLXApiBase::glXCreateGLXPixmapFn(Display* dpy,
                                           XVisualInfo* visual,
                                           Pixmap pixmap) {
  return driver_->fn.glXCreateGLXPixmapFn(dpy, visual, pixmap);
}

GLXContext GLXApiBase::glXCreateNewContextFn(Display* dpy,
                                             GLXFBConfig config,
                                             int renderType,
                                             GLXContext shareList,
                                             int direct) {
  return driver_->fn.glXCreateNewContextFn(dpy, config, renderType, shareList,
                                           direct);
}

GLXPbuffer GLXApiBase::glXCreatePbufferFn(Display* dpy,
                                          GLXFBConfig config,
                                          const int* attribList) {
  return driver_->fn.glXCreatePbufferFn(dpy, config, attribList);
}

GLXPixmap GLXApiBase::glXCreatePixmapFn(Display* dpy,
                                        GLXFBConfig config,
                                        Pixmap pixmap,
                                        const int* attribList) {
  return driver_->fn.glXCreatePixmapFn(dpy, config, pixmap, attribList);
}

GLXWindow GLXApiBase::glXCreateWindowFn(Display* dpy,
                                        GLXFBConfig config,
                                        Window win,
                                        const int* attribList) {
  return driver_->fn.glXCreateWindowFn(dpy, config, win, attribList);
}

void GLXApiBase::glXDestroyContextFn(Display* dpy, GLXContext ctx) {
  driver_->fn.glXDestroyContextFn(dpy, ctx);
}

void GLXApiBase::glXDestroyGLXPixmapFn(Display* dpy, GLXPixmap pixmap) {
  driver_->fn.glXDestroyGLXPixmapFn(dpy, pixmap);
}

void GLXApiBase::glXDestroyPbufferFn(Display* dpy, GLXPbuffer pbuf) {
  driver_->fn.glXDestroyPbufferFn(dpy, pbuf);
}

void GLXApiBase::glXDestroyPixmapFn(Display* dpy, GLXPixmap pixmap) {
  driver_->fn.glXDestroyPixmapFn(dpy, pixmap);
}

void GLXApiBase::glXDestroyWindowFn(Display* dpy, GLXWindow window) {
  driver_->fn.glXDestroyWindowFn(dpy, window);
}

const char* GLXApiBase::glXGetClientStringFn(Display* dpy, int name) {
  return driver_->fn.glXGetClientStringFn(dpy, name);
}

int GLXApiBase::glXGetConfigFn(Display* dpy,
                               XVisualInfo* visual,
                               int attrib,
                               int* value) {
  return driver_->fn.glXGetConfigFn(dpy, visual, attrib, value);
}

GLXContext GLXApiBase::glXGetCurrentContextFn(void) {
  return driver_->fn.glXGetCurrentContextFn();
}

Display* GLXApiBase::glXGetCurrentDisplayFn(void) {
  return driver_->fn.glXGetCurrentDisplayFn();
}

GLXDrawable GLXApiBase::glXGetCurrentDrawableFn(void) {
  return driver_->fn.glXGetCurrentDrawableFn();
}

GLXDrawable GLXApiBase::glXGetCurrentReadDrawableFn(void) {
  return driver_->fn.glXGetCurrentReadDrawableFn();
}

int GLXApiBase::glXGetFBConfigAttribFn(Display* dpy,
                                       GLXFBConfig config,
                                       int attribute,
                                       int* value) {
  return driver_->fn.glXGetFBConfigAttribFn(dpy, config, attribute, value);
}

GLXFBConfig GLXApiBase::glXGetFBConfigFromVisualSGIXFn(
    Display* dpy,
    XVisualInfo* visualInfo) {
  return driver_->fn.glXGetFBConfigFromVisualSGIXFn(dpy, visualInfo);
}

GLXFBConfig* GLXApiBase::glXGetFBConfigsFn(Display* dpy,
                                           int screen,
                                           int* nelements) {
  return driver_->fn.glXGetFBConfigsFn(dpy, screen, nelements);
}

bool GLXApiBase::glXGetMscRateOMLFn(Display* dpy,
                                    GLXDrawable drawable,
                                    int32* numerator,
                                    int32* denominator) {
  return driver_->fn.glXGetMscRateOMLFn(dpy, drawable, numerator, denominator);
}

void GLXApiBase::glXGetSelectedEventFn(Display* dpy,
                                       GLXDrawable drawable,
                                       unsigned long* mask) {
  driver_->fn.glXGetSelectedEventFn(dpy, drawable, mask);
}

bool GLXApiBase::glXGetSyncValuesOMLFn(Display* dpy,
                                       GLXDrawable drawable,
                                       int64* ust,
                                       int64* msc,
                                       int64* sbc) {
  return driver_->fn.glXGetSyncValuesOMLFn(dpy, drawable, ust, msc, sbc);
}

XVisualInfo* GLXApiBase::glXGetVisualFromFBConfigFn(Display* dpy,
                                                    GLXFBConfig config) {
  return driver_->fn.glXGetVisualFromFBConfigFn(dpy, config);
}

int GLXApiBase::glXIsDirectFn(Display* dpy, GLXContext ctx) {
  return driver_->fn.glXIsDirectFn(dpy, ctx);
}

int GLXApiBase::glXMakeContextCurrentFn(Display* dpy,
                                        GLXDrawable draw,
                                        GLXDrawable read,
                                        GLXContext ctx) {
  return driver_->fn.glXMakeContextCurrentFn(dpy, draw, read, ctx);
}

int GLXApiBase::glXMakeCurrentFn(Display* dpy,
                                 GLXDrawable drawable,
                                 GLXContext ctx) {
  return driver_->fn.glXMakeCurrentFn(dpy, drawable, ctx);
}

int GLXApiBase::glXQueryContextFn(Display* dpy,
                                  GLXContext ctx,
                                  int attribute,
                                  int* value) {
  return driver_->fn.glXQueryContextFn(dpy, ctx, attribute, value);
}

void GLXApiBase::glXQueryDrawableFn(Display* dpy,
                                    GLXDrawable draw,
                                    int attribute,
                                    unsigned int* value) {
  driver_->fn.glXQueryDrawableFn(dpy, draw, attribute, value);
}

int GLXApiBase::glXQueryExtensionFn(Display* dpy, int* errorb, int* event) {
  return driver_->fn.glXQueryExtensionFn(dpy, errorb, event);
}

const char* GLXApiBase::glXQueryExtensionsStringFn(Display* dpy, int screen) {
  return driver_->fn.glXQueryExtensionsStringFn(dpy, screen);
}

const char* GLXApiBase::glXQueryServerStringFn(Display* dpy,
                                               int screen,
                                               int name) {
  return driver_->fn.glXQueryServerStringFn(dpy, screen, name);
}

int GLXApiBase::glXQueryVersionFn(Display* dpy, int* maj, int* min) {
  return driver_->fn.glXQueryVersionFn(dpy, maj, min);
}

void GLXApiBase::glXReleaseTexImageEXTFn(Display* dpy,
                                         GLXDrawable drawable,
                                         int buffer) {
  driver_->fn.glXReleaseTexImageEXTFn(dpy, drawable, buffer);
}

void GLXApiBase::glXSelectEventFn(Display* dpy,
                                  GLXDrawable drawable,
                                  unsigned long mask) {
  driver_->fn.glXSelectEventFn(dpy, drawable, mask);
}

void GLXApiBase::glXSwapBuffersFn(Display* dpy, GLXDrawable drawable) {
  driver_->fn.glXSwapBuffersFn(dpy, drawable);
}

void GLXApiBase::glXSwapIntervalEXTFn(Display* dpy,
                                      GLXDrawable drawable,
                                      int interval) {
  driver_->fn.glXSwapIntervalEXTFn(dpy, drawable, interval);
}

void GLXApiBase::glXSwapIntervalMESAFn(unsigned int interval) {
  driver_->fn.glXSwapIntervalMESAFn(interval);
}

void GLXApiBase::glXUseXFontFn(Font font, int first, int count, int list) {
  driver_->fn.glXUseXFontFn(font, first, count, list);
}

void GLXApiBase::glXWaitGLFn(void) {
  driver_->fn.glXWaitGLFn();
}

int GLXApiBase::glXWaitVideoSyncSGIFn(int divisor,
                                      int remainder,
                                      unsigned int* count) {
  return driver_->fn.glXWaitVideoSyncSGIFn(divisor, remainder, count);
}

void GLXApiBase::glXWaitXFn(void) {
  driver_->fn.glXWaitXFn();
}

void TraceGLXApi::glXBindTexImageEXTFn(Display* dpy,
                                       GLXDrawable drawable,
                                       int buffer,
                                       int* attribList) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXBindTexImageEXT")
  glx_api_->glXBindTexImageEXTFn(dpy, drawable, buffer, attribList);
}

GLXFBConfig* TraceGLXApi::glXChooseFBConfigFn(Display* dpy,
                                              int screen,
                                              const int* attribList,
                                              int* nitems) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXChooseFBConfig")
  return glx_api_->glXChooseFBConfigFn(dpy, screen, attribList, nitems);
}

XVisualInfo* TraceGLXApi::glXChooseVisualFn(Display* dpy,
                                            int screen,
                                            int* attribList) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXChooseVisual")
  return glx_api_->glXChooseVisualFn(dpy, screen, attribList);
}

void TraceGLXApi::glXCopyContextFn(Display* dpy,
                                   GLXContext src,
                                   GLXContext dst,
                                   unsigned long mask) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXCopyContext")
  glx_api_->glXCopyContextFn(dpy, src, dst, mask);
}

void TraceGLXApi::glXCopySubBufferMESAFn(Display* dpy,
                                         GLXDrawable drawable,
                                         int x,
                                         int y,
                                         int width,
                                         int height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXCopySubBufferMESA")
  glx_api_->glXCopySubBufferMESAFn(dpy, drawable, x, y, width, height);
}

GLXContext TraceGLXApi::glXCreateContextFn(Display* dpy,
                                           XVisualInfo* vis,
                                           GLXContext shareList,
                                           int direct) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXCreateContext")
  return glx_api_->glXCreateContextFn(dpy, vis, shareList, direct);
}

GLXContext TraceGLXApi::glXCreateContextAttribsARBFn(Display* dpy,
                                                     GLXFBConfig config,
                                                     GLXContext share_context,
                                                     int direct,
                                                     const int* attrib_list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXCreateContextAttribsARB")
  return glx_api_->glXCreateContextAttribsARBFn(dpy, config, share_context,
                                                direct, attrib_list);
}

GLXPixmap TraceGLXApi::glXCreateGLXPixmapFn(Display* dpy,
                                            XVisualInfo* visual,
                                            Pixmap pixmap) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXCreateGLXPixmap")
  return glx_api_->glXCreateGLXPixmapFn(dpy, visual, pixmap);
}

GLXContext TraceGLXApi::glXCreateNewContextFn(Display* dpy,
                                              GLXFBConfig config,
                                              int renderType,
                                              GLXContext shareList,
                                              int direct) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXCreateNewContext")
  return glx_api_->glXCreateNewContextFn(dpy, config, renderType, shareList,
                                         direct);
}

GLXPbuffer TraceGLXApi::glXCreatePbufferFn(Display* dpy,
                                           GLXFBConfig config,
                                           const int* attribList) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXCreatePbuffer")
  return glx_api_->glXCreatePbufferFn(dpy, config, attribList);
}

GLXPixmap TraceGLXApi::glXCreatePixmapFn(Display* dpy,
                                         GLXFBConfig config,
                                         Pixmap pixmap,
                                         const int* attribList) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXCreatePixmap")
  return glx_api_->glXCreatePixmapFn(dpy, config, pixmap, attribList);
}

GLXWindow TraceGLXApi::glXCreateWindowFn(Display* dpy,
                                         GLXFBConfig config,
                                         Window win,
                                         const int* attribList) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXCreateWindow")
  return glx_api_->glXCreateWindowFn(dpy, config, win, attribList);
}

void TraceGLXApi::glXDestroyContextFn(Display* dpy, GLXContext ctx) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXDestroyContext")
  glx_api_->glXDestroyContextFn(dpy, ctx);
}

void TraceGLXApi::glXDestroyGLXPixmapFn(Display* dpy, GLXPixmap pixmap) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXDestroyGLXPixmap")
  glx_api_->glXDestroyGLXPixmapFn(dpy, pixmap);
}

void TraceGLXApi::glXDestroyPbufferFn(Display* dpy, GLXPbuffer pbuf) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXDestroyPbuffer")
  glx_api_->glXDestroyPbufferFn(dpy, pbuf);
}

void TraceGLXApi::glXDestroyPixmapFn(Display* dpy, GLXPixmap pixmap) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXDestroyPixmap")
  glx_api_->glXDestroyPixmapFn(dpy, pixmap);
}

void TraceGLXApi::glXDestroyWindowFn(Display* dpy, GLXWindow window) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXDestroyWindow")
  glx_api_->glXDestroyWindowFn(dpy, window);
}

const char* TraceGLXApi::glXGetClientStringFn(Display* dpy, int name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetClientString")
  return glx_api_->glXGetClientStringFn(dpy, name);
}

int TraceGLXApi::glXGetConfigFn(Display* dpy,
                                XVisualInfo* visual,
                                int attrib,
                                int* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetConfig")
  return glx_api_->glXGetConfigFn(dpy, visual, attrib, value);
}

GLXContext TraceGLXApi::glXGetCurrentContextFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetCurrentContext")
  return glx_api_->glXGetCurrentContextFn();
}

Display* TraceGLXApi::glXGetCurrentDisplayFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetCurrentDisplay")
  return glx_api_->glXGetCurrentDisplayFn();
}

GLXDrawable TraceGLXApi::glXGetCurrentDrawableFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetCurrentDrawable")
  return glx_api_->glXGetCurrentDrawableFn();
}

GLXDrawable TraceGLXApi::glXGetCurrentReadDrawableFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetCurrentReadDrawable")
  return glx_api_->glXGetCurrentReadDrawableFn();
}

int TraceGLXApi::glXGetFBConfigAttribFn(Display* dpy,
                                        GLXFBConfig config,
                                        int attribute,
                                        int* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetFBConfigAttrib")
  return glx_api_->glXGetFBConfigAttribFn(dpy, config, attribute, value);
}

GLXFBConfig TraceGLXApi::glXGetFBConfigFromVisualSGIXFn(
    Display* dpy,
    XVisualInfo* visualInfo) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu",
                                "TraceGLAPI::glXGetFBConfigFromVisualSGIX")
  return glx_api_->glXGetFBConfigFromVisualSGIXFn(dpy, visualInfo);
}

GLXFBConfig* TraceGLXApi::glXGetFBConfigsFn(Display* dpy,
                                            int screen,
                                            int* nelements) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetFBConfigs")
  return glx_api_->glXGetFBConfigsFn(dpy, screen, nelements);
}

bool TraceGLXApi::glXGetMscRateOMLFn(Display* dpy,
                                     GLXDrawable drawable,
                                     int32* numerator,
                                     int32* denominator) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetMscRateOML")
  return glx_api_->glXGetMscRateOMLFn(dpy, drawable, numerator, denominator);
}

void TraceGLXApi::glXGetSelectedEventFn(Display* dpy,
                                        GLXDrawable drawable,
                                        unsigned long* mask) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetSelectedEvent")
  glx_api_->glXGetSelectedEventFn(dpy, drawable, mask);
}

bool TraceGLXApi::glXGetSyncValuesOMLFn(Display* dpy,
                                        GLXDrawable drawable,
                                        int64* ust,
                                        int64* msc,
                                        int64* sbc) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetSyncValuesOML")
  return glx_api_->glXGetSyncValuesOMLFn(dpy, drawable, ust, msc, sbc);
}

XVisualInfo* TraceGLXApi::glXGetVisualFromFBConfigFn(Display* dpy,
                                                     GLXFBConfig config) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXGetVisualFromFBConfig")
  return glx_api_->glXGetVisualFromFBConfigFn(dpy, config);
}

int TraceGLXApi::glXIsDirectFn(Display* dpy, GLXContext ctx) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXIsDirect")
  return glx_api_->glXIsDirectFn(dpy, ctx);
}

int TraceGLXApi::glXMakeContextCurrentFn(Display* dpy,
                                         GLXDrawable draw,
                                         GLXDrawable read,
                                         GLXContext ctx) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXMakeContextCurrent")
  return glx_api_->glXMakeContextCurrentFn(dpy, draw, read, ctx);
}

int TraceGLXApi::glXMakeCurrentFn(Display* dpy,
                                  GLXDrawable drawable,
                                  GLXContext ctx) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXMakeCurrent")
  return glx_api_->glXMakeCurrentFn(dpy, drawable, ctx);
}

int TraceGLXApi::glXQueryContextFn(Display* dpy,
                                   GLXContext ctx,
                                   int attribute,
                                   int* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXQueryContext")
  return glx_api_->glXQueryContextFn(dpy, ctx, attribute, value);
}

void TraceGLXApi::glXQueryDrawableFn(Display* dpy,
                                     GLXDrawable draw,
                                     int attribute,
                                     unsigned int* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXQueryDrawable")
  glx_api_->glXQueryDrawableFn(dpy, draw, attribute, value);
}

int TraceGLXApi::glXQueryExtensionFn(Display* dpy, int* errorb, int* event) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXQueryExtension")
  return glx_api_->glXQueryExtensionFn(dpy, errorb, event);
}

const char* TraceGLXApi::glXQueryExtensionsStringFn(Display* dpy, int screen) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXQueryExtensionsString")
  return glx_api_->glXQueryExtensionsStringFn(dpy, screen);
}

const char* TraceGLXApi::glXQueryServerStringFn(Display* dpy,
                                                int screen,
                                                int name) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXQueryServerString")
  return glx_api_->glXQueryServerStringFn(dpy, screen, name);
}

int TraceGLXApi::glXQueryVersionFn(Display* dpy, int* maj, int* min) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXQueryVersion")
  return glx_api_->glXQueryVersionFn(dpy, maj, min);
}

void TraceGLXApi::glXReleaseTexImageEXTFn(Display* dpy,
                                          GLXDrawable drawable,
                                          int buffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXReleaseTexImageEXT")
  glx_api_->glXReleaseTexImageEXTFn(dpy, drawable, buffer);
}

void TraceGLXApi::glXSelectEventFn(Display* dpy,
                                   GLXDrawable drawable,
                                   unsigned long mask) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXSelectEvent")
  glx_api_->glXSelectEventFn(dpy, drawable, mask);
}

void TraceGLXApi::glXSwapBuffersFn(Display* dpy, GLXDrawable drawable) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXSwapBuffers")
  glx_api_->glXSwapBuffersFn(dpy, drawable);
}

void TraceGLXApi::glXSwapIntervalEXTFn(Display* dpy,
                                       GLXDrawable drawable,
                                       int interval) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXSwapIntervalEXT")
  glx_api_->glXSwapIntervalEXTFn(dpy, drawable, interval);
}

void TraceGLXApi::glXSwapIntervalMESAFn(unsigned int interval) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXSwapIntervalMESA")
  glx_api_->glXSwapIntervalMESAFn(interval);
}

void TraceGLXApi::glXUseXFontFn(Font font, int first, int count, int list) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXUseXFont")
  glx_api_->glXUseXFontFn(font, first, count, list);
}

void TraceGLXApi::glXWaitGLFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXWaitGL")
  glx_api_->glXWaitGLFn();
}

int TraceGLXApi::glXWaitVideoSyncSGIFn(int divisor,
                                       int remainder,
                                       unsigned int* count) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXWaitVideoSyncSGI")
  return glx_api_->glXWaitVideoSyncSGIFn(divisor, remainder, count);
}

void TraceGLXApi::glXWaitXFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::glXWaitX")
  glx_api_->glXWaitXFn();
}

}  // namespace gfx
