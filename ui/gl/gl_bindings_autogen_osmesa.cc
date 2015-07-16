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
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_osmesa_api_implementation.h"
#include "ui/gl/gl_version_info.h"

namespace gfx {

static bool g_debugBindingsInitialized;
DriverOSMESA g_driver_osmesa;

void DriverOSMESA::InitializeStaticBindings() {
  fn.OSMesaColorClampFn = reinterpret_cast<OSMesaColorClampProc>(
      GetGLProcAddress("OSMesaColorClamp"));
  fn.OSMesaCreateContextFn = reinterpret_cast<OSMesaCreateContextProc>(
      GetGLProcAddress("OSMesaCreateContext"));
  fn.OSMesaCreateContextExtFn = reinterpret_cast<OSMesaCreateContextExtProc>(
      GetGLProcAddress("OSMesaCreateContextExt"));
  fn.OSMesaDestroyContextFn = reinterpret_cast<OSMesaDestroyContextProc>(
      GetGLProcAddress("OSMesaDestroyContext"));
  fn.OSMesaGetColorBufferFn = reinterpret_cast<OSMesaGetColorBufferProc>(
      GetGLProcAddress("OSMesaGetColorBuffer"));
  fn.OSMesaGetCurrentContextFn = reinterpret_cast<OSMesaGetCurrentContextProc>(
      GetGLProcAddress("OSMesaGetCurrentContext"));
  fn.OSMesaGetDepthBufferFn = reinterpret_cast<OSMesaGetDepthBufferProc>(
      GetGLProcAddress("OSMesaGetDepthBuffer"));
  fn.OSMesaGetIntegervFn = reinterpret_cast<OSMesaGetIntegervProc>(
      GetGLProcAddress("OSMesaGetIntegerv"));
  fn.OSMesaGetProcAddressFn = reinterpret_cast<OSMesaGetProcAddressProc>(
      GetGLProcAddress("OSMesaGetProcAddress"));
  fn.OSMesaMakeCurrentFn = reinterpret_cast<OSMesaMakeCurrentProc>(
      GetGLProcAddress("OSMesaMakeCurrent"));
  fn.OSMesaPixelStoreFn = reinterpret_cast<OSMesaPixelStoreProc>(
      GetGLProcAddress("OSMesaPixelStore"));
  std::string extensions(GetPlatformExtensions());
  extensions += " ";
  ALLOW_UNUSED_LOCAL(extensions);

  if (g_debugBindingsInitialized)
    InitializeDebugBindings();
}

extern "C" {

static void GL_BINDING_CALL Debug_OSMesaColorClamp(GLboolean enable) {
  GL_SERVICE_LOG("OSMesaColorClamp"
                 << "(" << GLEnums::GetStringBool(enable) << ")");
  g_driver_osmesa.debug_fn.OSMesaColorClampFn(enable);
}

static OSMesaContext GL_BINDING_CALL
Debug_OSMesaCreateContext(GLenum format, OSMesaContext sharelist) {
  GL_SERVICE_LOG("OSMesaCreateContext"
                 << "(" << GLEnums::GetStringEnum(format) << ", " << sharelist
                 << ")");
  OSMesaContext result =
      g_driver_osmesa.debug_fn.OSMesaCreateContextFn(format, sharelist);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static OSMesaContext GL_BINDING_CALL
Debug_OSMesaCreateContextExt(GLenum format,
                             GLint depthBits,
                             GLint stencilBits,
                             GLint accumBits,
                             OSMesaContext sharelist) {
  GL_SERVICE_LOG("OSMesaCreateContextExt"
                 << "(" << GLEnums::GetStringEnum(format) << ", " << depthBits
                 << ", " << stencilBits << ", " << accumBits << ", "
                 << sharelist << ")");
  OSMesaContext result = g_driver_osmesa.debug_fn.OSMesaCreateContextExtFn(
      format, depthBits, stencilBits, accumBits, sharelist);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static void GL_BINDING_CALL Debug_OSMesaDestroyContext(OSMesaContext ctx) {
  GL_SERVICE_LOG("OSMesaDestroyContext"
                 << "(" << ctx << ")");
  g_driver_osmesa.debug_fn.OSMesaDestroyContextFn(ctx);
}

static GLboolean GL_BINDING_CALL Debug_OSMesaGetColorBuffer(OSMesaContext c,
                                                            GLint* width,
                                                            GLint* height,
                                                            GLint* format,
                                                            void** buffer) {
  GL_SERVICE_LOG("OSMesaGetColorBuffer"
                 << "(" << c << ", " << static_cast<const void*>(width) << ", "
                 << static_cast<const void*>(height) << ", "
                 << static_cast<const void*>(format) << ", " << buffer << ")");
  GLboolean result = g_driver_osmesa.debug_fn.OSMesaGetColorBufferFn(
      c, width, height, format, buffer);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static OSMesaContext GL_BINDING_CALL Debug_OSMesaGetCurrentContext(void) {
  GL_SERVICE_LOG("OSMesaGetCurrentContext"
                 << "("
                 << ")");
  OSMesaContext result = g_driver_osmesa.debug_fn.OSMesaGetCurrentContextFn();
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLboolean GL_BINDING_CALL
Debug_OSMesaGetDepthBuffer(OSMesaContext c,
                           GLint* width,
                           GLint* height,
                           GLint* bytesPerValue,
                           void** buffer) {
  GL_SERVICE_LOG("OSMesaGetDepthBuffer"
                 << "(" << c << ", " << static_cast<const void*>(width) << ", "
                 << static_cast<const void*>(height) << ", "
                 << static_cast<const void*>(bytesPerValue) << ", " << buffer
                 << ")");
  GLboolean result = g_driver_osmesa.debug_fn.OSMesaGetDepthBufferFn(
      c, width, height, bytesPerValue, buffer);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static void GL_BINDING_CALL Debug_OSMesaGetIntegerv(GLint pname, GLint* value) {
  GL_SERVICE_LOG("OSMesaGetIntegerv"
                 << "(" << pname << ", " << static_cast<const void*>(value)
                 << ")");
  g_driver_osmesa.debug_fn.OSMesaGetIntegervFn(pname, value);
}

static OSMESAproc GL_BINDING_CALL
Debug_OSMesaGetProcAddress(const char* funcName) {
  GL_SERVICE_LOG("OSMesaGetProcAddress"
                 << "(" << funcName << ")");
  OSMESAproc result = g_driver_osmesa.debug_fn.OSMesaGetProcAddressFn(funcName);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static GLboolean GL_BINDING_CALL Debug_OSMesaMakeCurrent(OSMesaContext ctx,
                                                         void* buffer,
                                                         GLenum type,
                                                         GLsizei width,
                                                         GLsizei height) {
  GL_SERVICE_LOG("OSMesaMakeCurrent"
                 << "(" << ctx << ", " << static_cast<const void*>(buffer)
                 << ", " << GLEnums::GetStringEnum(type) << ", " << width
                 << ", " << height << ")");
  GLboolean result = g_driver_osmesa.debug_fn.OSMesaMakeCurrentFn(
      ctx, buffer, type, width, height);
  GL_SERVICE_LOG("GL_RESULT: " << result);
  return result;
}

static void GL_BINDING_CALL Debug_OSMesaPixelStore(GLint pname, GLint value) {
  GL_SERVICE_LOG("OSMesaPixelStore"
                 << "(" << pname << ", " << value << ")");
  g_driver_osmesa.debug_fn.OSMesaPixelStoreFn(pname, value);
}
}  // extern "C"

void DriverOSMESA::InitializeDebugBindings() {
  if (!debug_fn.OSMesaColorClampFn) {
    debug_fn.OSMesaColorClampFn = fn.OSMesaColorClampFn;
    fn.OSMesaColorClampFn = Debug_OSMesaColorClamp;
  }
  if (!debug_fn.OSMesaCreateContextFn) {
    debug_fn.OSMesaCreateContextFn = fn.OSMesaCreateContextFn;
    fn.OSMesaCreateContextFn = Debug_OSMesaCreateContext;
  }
  if (!debug_fn.OSMesaCreateContextExtFn) {
    debug_fn.OSMesaCreateContextExtFn = fn.OSMesaCreateContextExtFn;
    fn.OSMesaCreateContextExtFn = Debug_OSMesaCreateContextExt;
  }
  if (!debug_fn.OSMesaDestroyContextFn) {
    debug_fn.OSMesaDestroyContextFn = fn.OSMesaDestroyContextFn;
    fn.OSMesaDestroyContextFn = Debug_OSMesaDestroyContext;
  }
  if (!debug_fn.OSMesaGetColorBufferFn) {
    debug_fn.OSMesaGetColorBufferFn = fn.OSMesaGetColorBufferFn;
    fn.OSMesaGetColorBufferFn = Debug_OSMesaGetColorBuffer;
  }
  if (!debug_fn.OSMesaGetCurrentContextFn) {
    debug_fn.OSMesaGetCurrentContextFn = fn.OSMesaGetCurrentContextFn;
    fn.OSMesaGetCurrentContextFn = Debug_OSMesaGetCurrentContext;
  }
  if (!debug_fn.OSMesaGetDepthBufferFn) {
    debug_fn.OSMesaGetDepthBufferFn = fn.OSMesaGetDepthBufferFn;
    fn.OSMesaGetDepthBufferFn = Debug_OSMesaGetDepthBuffer;
  }
  if (!debug_fn.OSMesaGetIntegervFn) {
    debug_fn.OSMesaGetIntegervFn = fn.OSMesaGetIntegervFn;
    fn.OSMesaGetIntegervFn = Debug_OSMesaGetIntegerv;
  }
  if (!debug_fn.OSMesaGetProcAddressFn) {
    debug_fn.OSMesaGetProcAddressFn = fn.OSMesaGetProcAddressFn;
    fn.OSMesaGetProcAddressFn = Debug_OSMesaGetProcAddress;
  }
  if (!debug_fn.OSMesaMakeCurrentFn) {
    debug_fn.OSMesaMakeCurrentFn = fn.OSMesaMakeCurrentFn;
    fn.OSMesaMakeCurrentFn = Debug_OSMesaMakeCurrent;
  }
  if (!debug_fn.OSMesaPixelStoreFn) {
    debug_fn.OSMesaPixelStoreFn = fn.OSMesaPixelStoreFn;
    fn.OSMesaPixelStoreFn = Debug_OSMesaPixelStore;
  }
  g_debugBindingsInitialized = true;
}

void DriverOSMESA::ClearBindings() {
  memset(this, 0, sizeof(*this));
}

void OSMESAApiBase::OSMesaColorClampFn(GLboolean enable) {
  driver_->fn.OSMesaColorClampFn(enable);
}

OSMesaContext OSMESAApiBase::OSMesaCreateContextFn(GLenum format,
                                                   OSMesaContext sharelist) {
  return driver_->fn.OSMesaCreateContextFn(format, sharelist);
}

OSMesaContext OSMESAApiBase::OSMesaCreateContextExtFn(GLenum format,
                                                      GLint depthBits,
                                                      GLint stencilBits,
                                                      GLint accumBits,
                                                      OSMesaContext sharelist) {
  return driver_->fn.OSMesaCreateContextExtFn(format, depthBits, stencilBits,
                                              accumBits, sharelist);
}

void OSMESAApiBase::OSMesaDestroyContextFn(OSMesaContext ctx) {
  driver_->fn.OSMesaDestroyContextFn(ctx);
}

GLboolean OSMESAApiBase::OSMesaGetColorBufferFn(OSMesaContext c,
                                                GLint* width,
                                                GLint* height,
                                                GLint* format,
                                                void** buffer) {
  return driver_->fn.OSMesaGetColorBufferFn(c, width, height, format, buffer);
}

OSMesaContext OSMESAApiBase::OSMesaGetCurrentContextFn(void) {
  return driver_->fn.OSMesaGetCurrentContextFn();
}

GLboolean OSMESAApiBase::OSMesaGetDepthBufferFn(OSMesaContext c,
                                                GLint* width,
                                                GLint* height,
                                                GLint* bytesPerValue,
                                                void** buffer) {
  return driver_->fn.OSMesaGetDepthBufferFn(c, width, height, bytesPerValue,
                                            buffer);
}

void OSMESAApiBase::OSMesaGetIntegervFn(GLint pname, GLint* value) {
  driver_->fn.OSMesaGetIntegervFn(pname, value);
}

OSMESAproc OSMESAApiBase::OSMesaGetProcAddressFn(const char* funcName) {
  return driver_->fn.OSMesaGetProcAddressFn(funcName);
}

GLboolean OSMESAApiBase::OSMesaMakeCurrentFn(OSMesaContext ctx,
                                             void* buffer,
                                             GLenum type,
                                             GLsizei width,
                                             GLsizei height) {
  return driver_->fn.OSMesaMakeCurrentFn(ctx, buffer, type, width, height);
}

void OSMESAApiBase::OSMesaPixelStoreFn(GLint pname, GLint value) {
  driver_->fn.OSMesaPixelStoreFn(pname, value);
}

void TraceOSMESAApi::OSMesaColorClampFn(GLboolean enable) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaColorClamp")
  osmesa_api_->OSMesaColorClampFn(enable);
}

OSMesaContext TraceOSMESAApi::OSMesaCreateContextFn(GLenum format,
                                                    OSMesaContext sharelist) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaCreateContext")
  return osmesa_api_->OSMesaCreateContextFn(format, sharelist);
}

OSMesaContext TraceOSMESAApi::OSMesaCreateContextExtFn(
    GLenum format,
    GLint depthBits,
    GLint stencilBits,
    GLint accumBits,
    OSMesaContext sharelist) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaCreateContextExt")
  return osmesa_api_->OSMesaCreateContextExtFn(format, depthBits, stencilBits,
                                               accumBits, sharelist);
}

void TraceOSMESAApi::OSMesaDestroyContextFn(OSMesaContext ctx) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaDestroyContext")
  osmesa_api_->OSMesaDestroyContextFn(ctx);
}

GLboolean TraceOSMESAApi::OSMesaGetColorBufferFn(OSMesaContext c,
                                                 GLint* width,
                                                 GLint* height,
                                                 GLint* format,
                                                 void** buffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaGetColorBuffer")
  return osmesa_api_->OSMesaGetColorBufferFn(c, width, height, format, buffer);
}

OSMesaContext TraceOSMESAApi::OSMesaGetCurrentContextFn(void) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaGetCurrentContext")
  return osmesa_api_->OSMesaGetCurrentContextFn();
}

GLboolean TraceOSMESAApi::OSMesaGetDepthBufferFn(OSMesaContext c,
                                                 GLint* width,
                                                 GLint* height,
                                                 GLint* bytesPerValue,
                                                 void** buffer) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaGetDepthBuffer")
  return osmesa_api_->OSMesaGetDepthBufferFn(c, width, height, bytesPerValue,
                                             buffer);
}

void TraceOSMESAApi::OSMesaGetIntegervFn(GLint pname, GLint* value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaGetIntegerv")
  osmesa_api_->OSMesaGetIntegervFn(pname, value);
}

OSMESAproc TraceOSMESAApi::OSMesaGetProcAddressFn(const char* funcName) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaGetProcAddress")
  return osmesa_api_->OSMesaGetProcAddressFn(funcName);
}

GLboolean TraceOSMESAApi::OSMesaMakeCurrentFn(OSMesaContext ctx,
                                              void* buffer,
                                              GLenum type,
                                              GLsizei width,
                                              GLsizei height) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaMakeCurrent")
  return osmesa_api_->OSMesaMakeCurrentFn(ctx, buffer, type, width, height);
}

void TraceOSMESAApi::OSMesaPixelStoreFn(GLint pname, GLint value) {
  TRACE_EVENT_BINARY_EFFICIENT0("gpu", "TraceGLAPI::OSMesaPixelStore")
  osmesa_api_->OSMesaPixelStoreFn(pname, value);
}

}  // namespace gfx
