// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_GL_API_IMPLEMENTATION_H_
#define UI_GL_GL_GL_API_IMPLEMENTATION_H_

#include "base/compiler_specific.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_export.h"

namespace gpu {
namespace gles2 {
class GLES2Decoder;
}
}
namespace gfx {

class GLContext;
class GLSurface;
struct GLVersionInfo;

void InitializeStaticGLBindingsGL();
void InitializeDynamicGLBindingsGL(GLContext* context);
void InitializeDebugGLBindingsGL();
void InitializeNullDrawGLBindingsGL();
// TODO(danakj): Remove this when all test suites are using null-draw.
bool HasInitializedNullDrawGLBindingsGL();
bool SetNullDrawGLBindingsEnabledGL(bool enabled);
void ClearGLBindingsGL();
void SetGLToRealGLApi();
void SetGLApi(GLApi* api);
void SetGLApiToNoContext();
const GLVersionInfo* GetGLVersionInfo();

class GLApiBase : public GLApi {
 public:
  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gl_bindings_api_autogen_gl.h"

 protected:
  GLApiBase();
  ~GLApiBase() override;
  void InitializeBase(DriverGL* driver);

  DriverGL* driver_;
};

// Implemenents the GL API by calling directly into the driver.
class RealGLApi : public GLApiBase {
 public:
  RealGLApi();
  ~RealGLApi() override;
  void Initialize(DriverGL* driver);

 private:
  void glFinishFn() override;
  void glFlushFn() override;
};

// Inserts a TRACE for every GL call.
class TraceGLApi : public GLApi {
 public:
  TraceGLApi(GLApi* gl_api) : gl_api_(gl_api) { }
  ~TraceGLApi() override;

  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gl_bindings_api_autogen_gl.h"

 private:
  GLApi* gl_api_;
};

// Catches incorrect usage when GL calls are made without a current context.
class NoContextGLApi : public GLApi {
 public:
  NoContextGLApi();
  ~NoContextGLApi() override;

  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gl_bindings_api_autogen_gl.h"
};

// Implementents the GL API using co-operative state restoring.
// Assumes there is only one real GL context and that multiple virtual contexts
// are implemented above it. Restores the needed state from the current context.
class VirtualGLApi : public GLApiBase {
 public:
  VirtualGLApi();
  ~VirtualGLApi() override;
  void Initialize(DriverGL* driver, GLContext* real_context);

  // Sets the current virutal context.
  bool MakeCurrent(GLContext* virtual_context, GLSurface* surface);

  void OnReleaseVirtuallyCurrent(GLContext* virtual_context);

private:
  // Overridden functions from GLApiBase
 const GLubyte* glGetStringFn(GLenum name) override;
 void glFinishFn() override;
 void glFlushFn() override;

  // The real context we're running on.
  GLContext* real_context_;

  // The current virtual context.
  GLContext* current_context_;

  // The supported extensions being advertised for this virtual context.
  std::string extensions_;
};

class GL_EXPORT ScopedSetGLToRealGLApi {
 public:
  ScopedSetGLToRealGLApi();
  ~ScopedSetGLToRealGLApi();

 private:
  GLApi* old_gl_api_;
};

}  // namespace gfx

#endif  // UI_GL_GL_GL_API_IMPLEMENTATION_H_
