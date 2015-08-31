// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_GLX_API_IMPLEMENTATION_H_
#define UI_GL_GL_GLX_API_IMPLEMENTATION_H_

#include "base/compiler_specific.h"
#include "gl_bindings.h"
#include "ui/gl/gl_export.h"

namespace gfx {

class GLContext;
struct GLWindowSystemBindingInfo;

void InitializeStaticGLBindingsGLX();
void InitializeDebugGLBindingsGLX();
void ClearGLBindingsGLX();
bool GetGLWindowSystemBindingInfoGLX(GLWindowSystemBindingInfo* info);

class GL_EXPORT GLXApiBase : public GLXApi {
 public:
  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gl_bindings_api_autogen_glx.h"

 protected:
  GLXApiBase();
  ~GLXApiBase() override;
  void InitializeBase(DriverGLX* driver);

  DriverGLX* driver_;
};

class GL_EXPORT RealGLXApi : public GLXApiBase {
 public:
  RealGLXApi();
  ~RealGLXApi() override;
  void Initialize(DriverGLX* driver);
};

// Inserts a TRACE for every GLX call.
class GL_EXPORT TraceGLXApi : public GLXApi {
 public:
  TraceGLXApi(GLXApi* glx_api) : glx_api_(glx_api) { }
  ~TraceGLXApi() override;

  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gl_bindings_api_autogen_glx.h"

 private:
  GLXApi* glx_api_;
};

}  // namespace gfx

#endif  // UI_GL_GL_GLX_API_IMPLEMENTATION_H_



