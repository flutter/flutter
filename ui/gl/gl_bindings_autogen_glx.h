// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

#ifndef UI_GFX_GL_GL_BINDINGS_AUTOGEN_GLX_H_
#define UI_GFX_GL_GL_BINDINGS_AUTOGEN_GLX_H_

namespace gfx {

class GLContext;

typedef void(GL_BINDING_CALL* glXBindTexImageEXTProc)(Display* dpy,
                                                      GLXDrawable drawable,
                                                      int buffer,
                                                      int* attribList);
typedef GLXFBConfig*(GL_BINDING_CALL* glXChooseFBConfigProc)(
    Display* dpy,
    int screen,
    const int* attribList,
    int* nitems);
typedef XVisualInfo*(GL_BINDING_CALL* glXChooseVisualProc)(Display* dpy,
                                                           int screen,
                                                           int* attribList);
typedef void(GL_BINDING_CALL* glXCopyContextProc)(Display* dpy,
                                                  GLXContext src,
                                                  GLXContext dst,
                                                  unsigned long mask);
typedef void(GL_BINDING_CALL* glXCopySubBufferMESAProc)(Display* dpy,
                                                        GLXDrawable drawable,
                                                        int x,
                                                        int y,
                                                        int width,
                                                        int height);
typedef GLXContext(GL_BINDING_CALL* glXCreateContextProc)(Display* dpy,
                                                          XVisualInfo* vis,
                                                          GLXContext shareList,
                                                          int direct);
typedef GLXContext(GL_BINDING_CALL* glXCreateContextAttribsARBProc)(
    Display* dpy,
    GLXFBConfig config,
    GLXContext share_context,
    int direct,
    const int* attrib_list);
typedef GLXPixmap(GL_BINDING_CALL* glXCreateGLXPixmapProc)(Display* dpy,
                                                           XVisualInfo* visual,
                                                           Pixmap pixmap);
typedef GLXContext(GL_BINDING_CALL* glXCreateNewContextProc)(
    Display* dpy,
    GLXFBConfig config,
    int renderType,
    GLXContext shareList,
    int direct);
typedef GLXPbuffer(GL_BINDING_CALL* glXCreatePbufferProc)(
    Display* dpy,
    GLXFBConfig config,
    const int* attribList);
typedef GLXPixmap(GL_BINDING_CALL* glXCreatePixmapProc)(Display* dpy,
                                                        GLXFBConfig config,
                                                        Pixmap pixmap,
                                                        const int* attribList);
typedef GLXWindow(GL_BINDING_CALL* glXCreateWindowProc)(Display* dpy,
                                                        GLXFBConfig config,
                                                        Window win,
                                                        const int* attribList);
typedef void(GL_BINDING_CALL* glXDestroyContextProc)(Display* dpy,
                                                     GLXContext ctx);
typedef void(GL_BINDING_CALL* glXDestroyGLXPixmapProc)(Display* dpy,
                                                       GLXPixmap pixmap);
typedef void(GL_BINDING_CALL* glXDestroyPbufferProc)(Display* dpy,
                                                     GLXPbuffer pbuf);
typedef void(GL_BINDING_CALL* glXDestroyPixmapProc)(Display* dpy,
                                                    GLXPixmap pixmap);
typedef void(GL_BINDING_CALL* glXDestroyWindowProc)(Display* dpy,
                                                    GLXWindow window);
typedef const char*(GL_BINDING_CALL* glXGetClientStringProc)(Display* dpy,
                                                             int name);
typedef int(GL_BINDING_CALL* glXGetConfigProc)(Display* dpy,
                                               XVisualInfo* visual,
                                               int attrib,
                                               int* value);
typedef GLXContext(GL_BINDING_CALL* glXGetCurrentContextProc)(void);
typedef Display*(GL_BINDING_CALL* glXGetCurrentDisplayProc)(void);
typedef GLXDrawable(GL_BINDING_CALL* glXGetCurrentDrawableProc)(void);
typedef GLXDrawable(GL_BINDING_CALL* glXGetCurrentReadDrawableProc)(void);
typedef int(GL_BINDING_CALL* glXGetFBConfigAttribProc)(Display* dpy,
                                                       GLXFBConfig config,
                                                       int attribute,
                                                       int* value);
typedef GLXFBConfig(GL_BINDING_CALL* glXGetFBConfigFromVisualSGIXProc)(
    Display* dpy,
    XVisualInfo* visualInfo);
typedef GLXFBConfig*(GL_BINDING_CALL* glXGetFBConfigsProc)(Display* dpy,
                                                           int screen,
                                                           int* nelements);
typedef bool(GL_BINDING_CALL* glXGetMscRateOMLProc)(Display* dpy,
                                                    GLXDrawable drawable,
                                                    int32* numerator,
                                                    int32* denominator);
typedef void(GL_BINDING_CALL* glXGetSelectedEventProc)(Display* dpy,
                                                       GLXDrawable drawable,
                                                       unsigned long* mask);
typedef bool(GL_BINDING_CALL* glXGetSyncValuesOMLProc)(Display* dpy,
                                                       GLXDrawable drawable,
                                                       int64* ust,
                                                       int64* msc,
                                                       int64* sbc);
typedef XVisualInfo*(GL_BINDING_CALL* glXGetVisualFromFBConfigProc)(
    Display* dpy,
    GLXFBConfig config);
typedef int(GL_BINDING_CALL* glXIsDirectProc)(Display* dpy, GLXContext ctx);
typedef int(GL_BINDING_CALL* glXMakeContextCurrentProc)(Display* dpy,
                                                        GLXDrawable draw,
                                                        GLXDrawable read,
                                                        GLXContext ctx);
typedef int(GL_BINDING_CALL* glXMakeCurrentProc)(Display* dpy,
                                                 GLXDrawable drawable,
                                                 GLXContext ctx);
typedef int(GL_BINDING_CALL* glXQueryContextProc)(Display* dpy,
                                                  GLXContext ctx,
                                                  int attribute,
                                                  int* value);
typedef void(GL_BINDING_CALL* glXQueryDrawableProc)(Display* dpy,
                                                    GLXDrawable draw,
                                                    int attribute,
                                                    unsigned int* value);
typedef int(GL_BINDING_CALL* glXQueryExtensionProc)(Display* dpy,
                                                    int* errorb,
                                                    int* event);
typedef const char*(GL_BINDING_CALL* glXQueryExtensionsStringProc)(Display* dpy,
                                                                   int screen);
typedef const char*(GL_BINDING_CALL* glXQueryServerStringProc)(Display* dpy,
                                                               int screen,
                                                               int name);
typedef int(GL_BINDING_CALL* glXQueryVersionProc)(Display* dpy,
                                                  int* maj,
                                                  int* min);
typedef void(GL_BINDING_CALL* glXReleaseTexImageEXTProc)(Display* dpy,
                                                         GLXDrawable drawable,
                                                         int buffer);
typedef void(GL_BINDING_CALL* glXSelectEventProc)(Display* dpy,
                                                  GLXDrawable drawable,
                                                  unsigned long mask);
typedef void(GL_BINDING_CALL* glXSwapBuffersProc)(Display* dpy,
                                                  GLXDrawable drawable);
typedef void(GL_BINDING_CALL* glXSwapIntervalEXTProc)(Display* dpy,
                                                      GLXDrawable drawable,
                                                      int interval);
typedef void(GL_BINDING_CALL* glXSwapIntervalMESAProc)(unsigned int interval);
typedef void(GL_BINDING_CALL* glXUseXFontProc)(Font font,
                                               int first,
                                               int count,
                                               int list);
typedef void(GL_BINDING_CALL* glXWaitGLProc)(void);
typedef int(GL_BINDING_CALL* glXWaitVideoSyncSGIProc)(int divisor,
                                                      int remainder,
                                                      unsigned int* count);
typedef void(GL_BINDING_CALL* glXWaitXProc)(void);

struct ExtensionsGLX {
  bool b_GLX_ARB_create_context;
  bool b_GLX_EXT_swap_control;
  bool b_GLX_EXT_texture_from_pixmap;
  bool b_GLX_MESA_copy_sub_buffer;
  bool b_GLX_MESA_swap_control;
  bool b_GLX_OML_sync_control;
  bool b_GLX_SGIX_fbconfig;
  bool b_GLX_SGI_video_sync;
};

struct ProcsGLX {
  glXBindTexImageEXTProc glXBindTexImageEXTFn;
  glXChooseFBConfigProc glXChooseFBConfigFn;
  glXChooseVisualProc glXChooseVisualFn;
  glXCopyContextProc glXCopyContextFn;
  glXCopySubBufferMESAProc glXCopySubBufferMESAFn;
  glXCreateContextProc glXCreateContextFn;
  glXCreateContextAttribsARBProc glXCreateContextAttribsARBFn;
  glXCreateGLXPixmapProc glXCreateGLXPixmapFn;
  glXCreateNewContextProc glXCreateNewContextFn;
  glXCreatePbufferProc glXCreatePbufferFn;
  glXCreatePixmapProc glXCreatePixmapFn;
  glXCreateWindowProc glXCreateWindowFn;
  glXDestroyContextProc glXDestroyContextFn;
  glXDestroyGLXPixmapProc glXDestroyGLXPixmapFn;
  glXDestroyPbufferProc glXDestroyPbufferFn;
  glXDestroyPixmapProc glXDestroyPixmapFn;
  glXDestroyWindowProc glXDestroyWindowFn;
  glXGetClientStringProc glXGetClientStringFn;
  glXGetConfigProc glXGetConfigFn;
  glXGetCurrentContextProc glXGetCurrentContextFn;
  glXGetCurrentDisplayProc glXGetCurrentDisplayFn;
  glXGetCurrentDrawableProc glXGetCurrentDrawableFn;
  glXGetCurrentReadDrawableProc glXGetCurrentReadDrawableFn;
  glXGetFBConfigAttribProc glXGetFBConfigAttribFn;
  glXGetFBConfigFromVisualSGIXProc glXGetFBConfigFromVisualSGIXFn;
  glXGetFBConfigsProc glXGetFBConfigsFn;
  glXGetMscRateOMLProc glXGetMscRateOMLFn;
  glXGetSelectedEventProc glXGetSelectedEventFn;
  glXGetSyncValuesOMLProc glXGetSyncValuesOMLFn;
  glXGetVisualFromFBConfigProc glXGetVisualFromFBConfigFn;
  glXIsDirectProc glXIsDirectFn;
  glXMakeContextCurrentProc glXMakeContextCurrentFn;
  glXMakeCurrentProc glXMakeCurrentFn;
  glXQueryContextProc glXQueryContextFn;
  glXQueryDrawableProc glXQueryDrawableFn;
  glXQueryExtensionProc glXQueryExtensionFn;
  glXQueryExtensionsStringProc glXQueryExtensionsStringFn;
  glXQueryServerStringProc glXQueryServerStringFn;
  glXQueryVersionProc glXQueryVersionFn;
  glXReleaseTexImageEXTProc glXReleaseTexImageEXTFn;
  glXSelectEventProc glXSelectEventFn;
  glXSwapBuffersProc glXSwapBuffersFn;
  glXSwapIntervalEXTProc glXSwapIntervalEXTFn;
  glXSwapIntervalMESAProc glXSwapIntervalMESAFn;
  glXUseXFontProc glXUseXFontFn;
  glXWaitGLProc glXWaitGLFn;
  glXWaitVideoSyncSGIProc glXWaitVideoSyncSGIFn;
  glXWaitXProc glXWaitXFn;
};

class GL_EXPORT GLXApi {
 public:
  GLXApi();
  virtual ~GLXApi();

  virtual void glXBindTexImageEXTFn(Display* dpy,
                                    GLXDrawable drawable,
                                    int buffer,
                                    int* attribList) = 0;
  virtual GLXFBConfig* glXChooseFBConfigFn(Display* dpy,
                                           int screen,
                                           const int* attribList,
                                           int* nitems) = 0;
  virtual XVisualInfo* glXChooseVisualFn(Display* dpy,
                                         int screen,
                                         int* attribList) = 0;
  virtual void glXCopyContextFn(Display* dpy,
                                GLXContext src,
                                GLXContext dst,
                                unsigned long mask) = 0;
  virtual void glXCopySubBufferMESAFn(Display* dpy,
                                      GLXDrawable drawable,
                                      int x,
                                      int y,
                                      int width,
                                      int height) = 0;
  virtual GLXContext glXCreateContextFn(Display* dpy,
                                        XVisualInfo* vis,
                                        GLXContext shareList,
                                        int direct) = 0;
  virtual GLXContext glXCreateContextAttribsARBFn(Display* dpy,
                                                  GLXFBConfig config,
                                                  GLXContext share_context,
                                                  int direct,
                                                  const int* attrib_list) = 0;
  virtual GLXPixmap glXCreateGLXPixmapFn(Display* dpy,
                                         XVisualInfo* visual,
                                         Pixmap pixmap) = 0;
  virtual GLXContext glXCreateNewContextFn(Display* dpy,
                                           GLXFBConfig config,
                                           int renderType,
                                           GLXContext shareList,
                                           int direct) = 0;
  virtual GLXPbuffer glXCreatePbufferFn(Display* dpy,
                                        GLXFBConfig config,
                                        const int* attribList) = 0;
  virtual GLXPixmap glXCreatePixmapFn(Display* dpy,
                                      GLXFBConfig config,
                                      Pixmap pixmap,
                                      const int* attribList) = 0;
  virtual GLXWindow glXCreateWindowFn(Display* dpy,
                                      GLXFBConfig config,
                                      Window win,
                                      const int* attribList) = 0;
  virtual void glXDestroyContextFn(Display* dpy, GLXContext ctx) = 0;
  virtual void glXDestroyGLXPixmapFn(Display* dpy, GLXPixmap pixmap) = 0;
  virtual void glXDestroyPbufferFn(Display* dpy, GLXPbuffer pbuf) = 0;
  virtual void glXDestroyPixmapFn(Display* dpy, GLXPixmap pixmap) = 0;
  virtual void glXDestroyWindowFn(Display* dpy, GLXWindow window) = 0;
  virtual const char* glXGetClientStringFn(Display* dpy, int name) = 0;
  virtual int glXGetConfigFn(Display* dpy,
                             XVisualInfo* visual,
                             int attrib,
                             int* value) = 0;
  virtual GLXContext glXGetCurrentContextFn(void) = 0;
  virtual Display* glXGetCurrentDisplayFn(void) = 0;
  virtual GLXDrawable glXGetCurrentDrawableFn(void) = 0;
  virtual GLXDrawable glXGetCurrentReadDrawableFn(void) = 0;
  virtual int glXGetFBConfigAttribFn(Display* dpy,
                                     GLXFBConfig config,
                                     int attribute,
                                     int* value) = 0;
  virtual GLXFBConfig glXGetFBConfigFromVisualSGIXFn(
      Display* dpy,
      XVisualInfo* visualInfo) = 0;
  virtual GLXFBConfig* glXGetFBConfigsFn(Display* dpy,
                                         int screen,
                                         int* nelements) = 0;
  virtual bool glXGetMscRateOMLFn(Display* dpy,
                                  GLXDrawable drawable,
                                  int32* numerator,
                                  int32* denominator) = 0;
  virtual void glXGetSelectedEventFn(Display* dpy,
                                     GLXDrawable drawable,
                                     unsigned long* mask) = 0;
  virtual bool glXGetSyncValuesOMLFn(Display* dpy,
                                     GLXDrawable drawable,
                                     int64* ust,
                                     int64* msc,
                                     int64* sbc) = 0;
  virtual XVisualInfo* glXGetVisualFromFBConfigFn(Display* dpy,
                                                  GLXFBConfig config) = 0;
  virtual int glXIsDirectFn(Display* dpy, GLXContext ctx) = 0;
  virtual int glXMakeContextCurrentFn(Display* dpy,
                                      GLXDrawable draw,
                                      GLXDrawable read,
                                      GLXContext ctx) = 0;
  virtual int glXMakeCurrentFn(Display* dpy,
                               GLXDrawable drawable,
                               GLXContext ctx) = 0;
  virtual int glXQueryContextFn(Display* dpy,
                                GLXContext ctx,
                                int attribute,
                                int* value) = 0;
  virtual void glXQueryDrawableFn(Display* dpy,
                                  GLXDrawable draw,
                                  int attribute,
                                  unsigned int* value) = 0;
  virtual int glXQueryExtensionFn(Display* dpy, int* errorb, int* event) = 0;
  virtual const char* glXQueryExtensionsStringFn(Display* dpy, int screen) = 0;
  virtual const char* glXQueryServerStringFn(Display* dpy,
                                             int screen,
                                             int name) = 0;
  virtual int glXQueryVersionFn(Display* dpy, int* maj, int* min) = 0;
  virtual void glXReleaseTexImageEXTFn(Display* dpy,
                                       GLXDrawable drawable,
                                       int buffer) = 0;
  virtual void glXSelectEventFn(Display* dpy,
                                GLXDrawable drawable,
                                unsigned long mask) = 0;
  virtual void glXSwapBuffersFn(Display* dpy, GLXDrawable drawable) = 0;
  virtual void glXSwapIntervalEXTFn(Display* dpy,
                                    GLXDrawable drawable,
                                    int interval) = 0;
  virtual void glXSwapIntervalMESAFn(unsigned int interval) = 0;
  virtual void glXUseXFontFn(Font font, int first, int count, int list) = 0;
  virtual void glXWaitGLFn(void) = 0;
  virtual int glXWaitVideoSyncSGIFn(int divisor,
                                    int remainder,
                                    unsigned int* count) = 0;
  virtual void glXWaitXFn(void) = 0;
};

}  // namespace gfx

#define glXBindTexImageEXT ::gfx::g_current_glx_context->glXBindTexImageEXTFn
#define glXChooseFBConfig ::gfx::g_current_glx_context->glXChooseFBConfigFn
#define glXChooseVisual ::gfx::g_current_glx_context->glXChooseVisualFn
#define glXCopyContext ::gfx::g_current_glx_context->glXCopyContextFn
#define glXCopySubBufferMESA \
  ::gfx::g_current_glx_context->glXCopySubBufferMESAFn
#define glXCreateContext ::gfx::g_current_glx_context->glXCreateContextFn
#define glXCreateContextAttribsARB \
  ::gfx::g_current_glx_context->glXCreateContextAttribsARBFn
#define glXCreateGLXPixmap ::gfx::g_current_glx_context->glXCreateGLXPixmapFn
#define glXCreateNewContext ::gfx::g_current_glx_context->glXCreateNewContextFn
#define glXCreatePbuffer ::gfx::g_current_glx_context->glXCreatePbufferFn
#define glXCreatePixmap ::gfx::g_current_glx_context->glXCreatePixmapFn
#define glXCreateWindow ::gfx::g_current_glx_context->glXCreateWindowFn
#define glXDestroyContext ::gfx::g_current_glx_context->glXDestroyContextFn
#define glXDestroyGLXPixmap ::gfx::g_current_glx_context->glXDestroyGLXPixmapFn
#define glXDestroyPbuffer ::gfx::g_current_glx_context->glXDestroyPbufferFn
#define glXDestroyPixmap ::gfx::g_current_glx_context->glXDestroyPixmapFn
#define glXDestroyWindow ::gfx::g_current_glx_context->glXDestroyWindowFn
#define glXGetClientString ::gfx::g_current_glx_context->glXGetClientStringFn
#define glXGetConfig ::gfx::g_current_glx_context->glXGetConfigFn
#define glXGetCurrentContext \
  ::gfx::g_current_glx_context->glXGetCurrentContextFn
#define glXGetCurrentDisplay \
  ::gfx::g_current_glx_context->glXGetCurrentDisplayFn
#define glXGetCurrentDrawable \
  ::gfx::g_current_glx_context->glXGetCurrentDrawableFn
#define glXGetCurrentReadDrawable \
  ::gfx::g_current_glx_context->glXGetCurrentReadDrawableFn
#define glXGetFBConfigAttrib \
  ::gfx::g_current_glx_context->glXGetFBConfigAttribFn
#define glXGetFBConfigFromVisualSGIX \
  ::gfx::g_current_glx_context->glXGetFBConfigFromVisualSGIXFn
#define glXGetFBConfigs ::gfx::g_current_glx_context->glXGetFBConfigsFn
#define glXGetMscRateOML ::gfx::g_current_glx_context->glXGetMscRateOMLFn
#define glXGetSelectedEvent ::gfx::g_current_glx_context->glXGetSelectedEventFn
#define glXGetSyncValuesOML ::gfx::g_current_glx_context->glXGetSyncValuesOMLFn
#define glXGetVisualFromFBConfig \
  ::gfx::g_current_glx_context->glXGetVisualFromFBConfigFn
#define glXIsDirect ::gfx::g_current_glx_context->glXIsDirectFn
#define glXMakeContextCurrent \
  ::gfx::g_current_glx_context->glXMakeContextCurrentFn
#define glXMakeCurrent ::gfx::g_current_glx_context->glXMakeCurrentFn
#define glXQueryContext ::gfx::g_current_glx_context->glXQueryContextFn
#define glXQueryDrawable ::gfx::g_current_glx_context->glXQueryDrawableFn
#define glXQueryExtension ::gfx::g_current_glx_context->glXQueryExtensionFn
#define glXQueryExtensionsString \
  ::gfx::g_current_glx_context->glXQueryExtensionsStringFn
#define glXQueryServerString \
  ::gfx::g_current_glx_context->glXQueryServerStringFn
#define glXQueryVersion ::gfx::g_current_glx_context->glXQueryVersionFn
#define glXReleaseTexImageEXT \
  ::gfx::g_current_glx_context->glXReleaseTexImageEXTFn
#define glXSelectEvent ::gfx::g_current_glx_context->glXSelectEventFn
#define glXSwapBuffers ::gfx::g_current_glx_context->glXSwapBuffersFn
#define glXSwapIntervalEXT ::gfx::g_current_glx_context->glXSwapIntervalEXTFn
#define glXSwapIntervalMESA ::gfx::g_current_glx_context->glXSwapIntervalMESAFn
#define glXUseXFont ::gfx::g_current_glx_context->glXUseXFontFn
#define glXWaitGL ::gfx::g_current_glx_context->glXWaitGLFn
#define glXWaitVideoSyncSGI ::gfx::g_current_glx_context->glXWaitVideoSyncSGIFn
#define glXWaitX ::gfx::g_current_glx_context->glXWaitXFn

#endif  //  UI_GFX_GL_GL_BINDINGS_AUTOGEN_GLX_H_
