// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

void glXBindTexImageEXTFn(Display* dpy,
                          GLXDrawable drawable,
                          int buffer,
                          int* attribList) override;
GLXFBConfig* glXChooseFBConfigFn(Display* dpy,
                                 int screen,
                                 const int* attribList,
                                 int* nitems) override;
XVisualInfo* glXChooseVisualFn(Display* dpy,
                               int screen,
                               int* attribList) override;
void glXCopyContextFn(Display* dpy,
                      GLXContext src,
                      GLXContext dst,
                      unsigned long mask) override;
void glXCopySubBufferMESAFn(Display* dpy,
                            GLXDrawable drawable,
                            int x,
                            int y,
                            int width,
                            int height) override;
GLXContext glXCreateContextFn(Display* dpy,
                              XVisualInfo* vis,
                              GLXContext shareList,
                              int direct) override;
GLXContext glXCreateContextAttribsARBFn(Display* dpy,
                                        GLXFBConfig config,
                                        GLXContext share_context,
                                        int direct,
                                        const int* attrib_list) override;
GLXPixmap glXCreateGLXPixmapFn(Display* dpy,
                               XVisualInfo* visual,
                               Pixmap pixmap) override;
GLXContext glXCreateNewContextFn(Display* dpy,
                                 GLXFBConfig config,
                                 int renderType,
                                 GLXContext shareList,
                                 int direct) override;
GLXPbuffer glXCreatePbufferFn(Display* dpy,
                              GLXFBConfig config,
                              const int* attribList) override;
GLXPixmap glXCreatePixmapFn(Display* dpy,
                            GLXFBConfig config,
                            Pixmap pixmap,
                            const int* attribList) override;
GLXWindow glXCreateWindowFn(Display* dpy,
                            GLXFBConfig config,
                            Window win,
                            const int* attribList) override;
void glXDestroyContextFn(Display* dpy, GLXContext ctx) override;
void glXDestroyGLXPixmapFn(Display* dpy, GLXPixmap pixmap) override;
void glXDestroyPbufferFn(Display* dpy, GLXPbuffer pbuf) override;
void glXDestroyPixmapFn(Display* dpy, GLXPixmap pixmap) override;
void glXDestroyWindowFn(Display* dpy, GLXWindow window) override;
const char* glXGetClientStringFn(Display* dpy, int name) override;
int glXGetConfigFn(Display* dpy,
                   XVisualInfo* visual,
                   int attrib,
                   int* value) override;
GLXContext glXGetCurrentContextFn(void) override;
Display* glXGetCurrentDisplayFn(void) override;
GLXDrawable glXGetCurrentDrawableFn(void) override;
GLXDrawable glXGetCurrentReadDrawableFn(void) override;
int glXGetFBConfigAttribFn(Display* dpy,
                           GLXFBConfig config,
                           int attribute,
                           int* value) override;
GLXFBConfig glXGetFBConfigFromVisualSGIXFn(Display* dpy,
                                           XVisualInfo* visualInfo) override;
GLXFBConfig* glXGetFBConfigsFn(Display* dpy,
                               int screen,
                               int* nelements) override;
bool glXGetMscRateOMLFn(Display* dpy,
                        GLXDrawable drawable,
                        int32* numerator,
                        int32* denominator) override;
void glXGetSelectedEventFn(Display* dpy,
                           GLXDrawable drawable,
                           unsigned long* mask) override;
bool glXGetSyncValuesOMLFn(Display* dpy,
                           GLXDrawable drawable,
                           int64* ust,
                           int64* msc,
                           int64* sbc) override;
XVisualInfo* glXGetVisualFromFBConfigFn(Display* dpy,
                                        GLXFBConfig config) override;
int glXIsDirectFn(Display* dpy, GLXContext ctx) override;
int glXMakeContextCurrentFn(Display* dpy,
                            GLXDrawable draw,
                            GLXDrawable read,
                            GLXContext ctx) override;
int glXMakeCurrentFn(Display* dpy,
                     GLXDrawable drawable,
                     GLXContext ctx) override;
int glXQueryContextFn(Display* dpy,
                      GLXContext ctx,
                      int attribute,
                      int* value) override;
void glXQueryDrawableFn(Display* dpy,
                        GLXDrawable draw,
                        int attribute,
                        unsigned int* value) override;
int glXQueryExtensionFn(Display* dpy, int* errorb, int* event) override;
const char* glXQueryExtensionsStringFn(Display* dpy, int screen) override;
const char* glXQueryServerStringFn(Display* dpy, int screen, int name) override;
int glXQueryVersionFn(Display* dpy, int* maj, int* min) override;
void glXReleaseTexImageEXTFn(Display* dpy,
                             GLXDrawable drawable,
                             int buffer) override;
void glXSelectEventFn(Display* dpy,
                      GLXDrawable drawable,
                      unsigned long mask) override;
void glXSwapBuffersFn(Display* dpy, GLXDrawable drawable) override;
void glXSwapIntervalEXTFn(Display* dpy,
                          GLXDrawable drawable,
                          int interval) override;
void glXSwapIntervalMESAFn(unsigned int interval) override;
void glXUseXFontFn(Font font, int first, int count, int list) override;
void glXWaitGLFn(void) override;
int glXWaitVideoSyncSGIFn(int divisor,
                          int remainder,
                          unsigned int* count) override;
void glXWaitXFn(void) override;
