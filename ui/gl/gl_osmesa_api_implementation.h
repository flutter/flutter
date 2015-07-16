// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_OSMESA_API_IMPLEMENTATION_H_
#define UI_GL_GL_OSMESA_API_IMPLEMENTATION_H_

#include "base/compiler_specific.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_export.h"

namespace gfx {

class GLContext;

void InitializeStaticGLBindingsOSMESA();
void InitializeDebugGLBindingsOSMESA();
void ClearGLBindingsOSMESA();

class GL_EXPORT OSMESAApiBase : public OSMESAApi {
 public:
  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gl_bindings_api_autogen_osmesa.h"

 protected:
  OSMESAApiBase();
  ~OSMESAApiBase() override;
  void InitializeBase(DriverOSMESA* driver);

  DriverOSMESA* driver_;
};

class GL_EXPORT RealOSMESAApi : public OSMESAApiBase {
 public:
  RealOSMESAApi();
  ~RealOSMESAApi() override;
  void Initialize(DriverOSMESA* driver);
};

// Inserts a TRACE for every OSMESA call.
class GL_EXPORT TraceOSMESAApi : public OSMESAApi {
 public:
  TraceOSMESAApi(OSMESAApi* osmesa_api) : osmesa_api_(osmesa_api) { }
  ~TraceOSMESAApi() override;

  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gl_bindings_api_autogen_osmesa.h"

 private:
  OSMESAApi* osmesa_api_;
};

}  // namespace gfx

#endif  // UI_GL_GL_OSMESA_API_IMPLEMENTATION_H_



