// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file is auto-generated from
// ui/gl/generate_bindings.py
// It's formatted by clang-format using chromium coding style:
//    clang-format -i -style=chromium filename
// DO NOT EDIT!

#ifndef UI_GFX_GL_GL_BINDINGS_AUTOGEN_OSMESA_H_
#define UI_GFX_GL_GL_BINDINGS_AUTOGEN_OSMESA_H_

namespace gfx {

class GLContext;

typedef void(GL_BINDING_CALL* OSMesaColorClampProc)(GLboolean enable);
typedef OSMesaContext(GL_BINDING_CALL* OSMesaCreateContextProc)(
    GLenum format,
    OSMesaContext sharelist);
typedef OSMesaContext(GL_BINDING_CALL* OSMesaCreateContextExtProc)(
    GLenum format,
    GLint depthBits,
    GLint stencilBits,
    GLint accumBits,
    OSMesaContext sharelist);
typedef void(GL_BINDING_CALL* OSMesaDestroyContextProc)(OSMesaContext ctx);
typedef GLboolean(GL_BINDING_CALL* OSMesaGetColorBufferProc)(OSMesaContext c,
                                                             GLint* width,
                                                             GLint* height,
                                                             GLint* format,
                                                             void** buffer);
typedef OSMesaContext(GL_BINDING_CALL* OSMesaGetCurrentContextProc)(void);
typedef GLboolean(GL_BINDING_CALL* OSMesaGetDepthBufferProc)(
    OSMesaContext c,
    GLint* width,
    GLint* height,
    GLint* bytesPerValue,
    void** buffer);
typedef void(GL_BINDING_CALL* OSMesaGetIntegervProc)(GLint pname, GLint* value);
typedef OSMESAproc(GL_BINDING_CALL* OSMesaGetProcAddressProc)(
    const char* funcName);
typedef GLboolean(GL_BINDING_CALL* OSMesaMakeCurrentProc)(OSMesaContext ctx,
                                                          void* buffer,
                                                          GLenum type,
                                                          GLsizei width,
                                                          GLsizei height);
typedef void(GL_BINDING_CALL* OSMesaPixelStoreProc)(GLint pname, GLint value);

struct ExtensionsOSMESA {};

struct ProcsOSMESA {
  OSMesaColorClampProc OSMesaColorClampFn;
  OSMesaCreateContextProc OSMesaCreateContextFn;
  OSMesaCreateContextExtProc OSMesaCreateContextExtFn;
  OSMesaDestroyContextProc OSMesaDestroyContextFn;
  OSMesaGetColorBufferProc OSMesaGetColorBufferFn;
  OSMesaGetCurrentContextProc OSMesaGetCurrentContextFn;
  OSMesaGetDepthBufferProc OSMesaGetDepthBufferFn;
  OSMesaGetIntegervProc OSMesaGetIntegervFn;
  OSMesaGetProcAddressProc OSMesaGetProcAddressFn;
  OSMesaMakeCurrentProc OSMesaMakeCurrentFn;
  OSMesaPixelStoreProc OSMesaPixelStoreFn;
};

class GL_EXPORT OSMESAApi {
 public:
  OSMESAApi();
  virtual ~OSMESAApi();

  virtual void OSMesaColorClampFn(GLboolean enable) = 0;
  virtual OSMesaContext OSMesaCreateContextFn(GLenum format,
                                              OSMesaContext sharelist) = 0;
  virtual OSMesaContext OSMesaCreateContextExtFn(GLenum format,
                                                 GLint depthBits,
                                                 GLint stencilBits,
                                                 GLint accumBits,
                                                 OSMesaContext sharelist) = 0;
  virtual void OSMesaDestroyContextFn(OSMesaContext ctx) = 0;
  virtual GLboolean OSMesaGetColorBufferFn(OSMesaContext c,
                                           GLint* width,
                                           GLint* height,
                                           GLint* format,
                                           void** buffer) = 0;
  virtual OSMesaContext OSMesaGetCurrentContextFn(void) = 0;
  virtual GLboolean OSMesaGetDepthBufferFn(OSMesaContext c,
                                           GLint* width,
                                           GLint* height,
                                           GLint* bytesPerValue,
                                           void** buffer) = 0;
  virtual void OSMesaGetIntegervFn(GLint pname, GLint* value) = 0;
  virtual OSMESAproc OSMesaGetProcAddressFn(const char* funcName) = 0;
  virtual GLboolean OSMesaMakeCurrentFn(OSMesaContext ctx,
                                        void* buffer,
                                        GLenum type,
                                        GLsizei width,
                                        GLsizei height) = 0;
  virtual void OSMesaPixelStoreFn(GLint pname, GLint value) = 0;
};

}  // namespace gfx

#define OSMesaColorClamp ::gfx::g_current_osmesa_context->OSMesaColorClampFn
#define OSMesaCreateContext \
  ::gfx::g_current_osmesa_context->OSMesaCreateContextFn
#define OSMesaCreateContextExt \
  ::gfx::g_current_osmesa_context->OSMesaCreateContextExtFn
#define OSMesaDestroyContext \
  ::gfx::g_current_osmesa_context->OSMesaDestroyContextFn
#define OSMesaGetColorBuffer \
  ::gfx::g_current_osmesa_context->OSMesaGetColorBufferFn
#define OSMesaGetCurrentContext \
  ::gfx::g_current_osmesa_context->OSMesaGetCurrentContextFn
#define OSMesaGetDepthBuffer \
  ::gfx::g_current_osmesa_context->OSMesaGetDepthBufferFn
#define OSMesaGetIntegerv ::gfx::g_current_osmesa_context->OSMesaGetIntegervFn
#define OSMesaGetProcAddress \
  ::gfx::g_current_osmesa_context->OSMesaGetProcAddressFn
#define OSMesaMakeCurrent ::gfx::g_current_osmesa_context->OSMesaMakeCurrentFn
#define OSMesaPixelStore ::gfx::g_current_osmesa_context->OSMesaPixelStoreFn

#endif  //  UI_GFX_GL_GL_BINDINGS_AUTOGEN_OSMESA_H_
