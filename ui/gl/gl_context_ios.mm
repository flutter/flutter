// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_context_ios.h"
#include "ui/gl/gl_context_stub.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gl_switches.h"

#include <OpenGLES/EAGL.h>
#include <OpenGLES/ES2/gl.h>
#include <QuartzCore/CALayer.h>

#define CAST_CONTEXT (reinterpret_cast<EAGLContext*>(context_))

namespace gfx {

GLContextIOS::GLContextIOS(GLShareGroup* share_group)
    : GLContextReal(share_group) {
  EAGLContext* context =
      [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  DCHECK(context);
  context_ = reinterpret_cast<uintptr_t>(context);
}

GLContextIOS::~GLContextIOS() {
  Destroy();
}

bool GLContextIOS::Initialize(GLSurface* compatible_surface,
                              GpuPreference gpu_preference) {
  return CAST_CONTEXT != nullptr && compatible_surface != nullptr;
}

void GLContextIOS::Destroy() {
  [CAST_CONTEXT release];
}

bool GLContextIOS::MakeCurrent(GLSurface* surface) {
  bool result = [EAGLContext setCurrentContext:CAST_CONTEXT];

  if (!result) {
    return false;
  }

  SetRealGLApi();

  if (!InitializeDynamicBindings()) {
    return false;
  }

  if (!surface->OnMakeCurrent(this)) {
    return false;
  }

  return true;
}

void GLContextIOS::ReleaseCurrent(GLSurface* surface) {
  [EAGLContext setCurrentContext:nil];
}

bool GLContextIOS::IsCurrent(GLSurface* surface) {
  return [EAGLContext currentContext] == CAST_CONTEXT;
}

void* GLContextIOS::GetHandle() {
  return CAST_CONTEXT;
}

void GLContextIOS::OnSetSwapInterval(int interval) {
}

std::string GLContextIOS::GetExtensions() {
  return reinterpret_cast<const char*>(glGetString(GL_EXTENSIONS));
}

bool GLContextIOS::WasAllocatedUsingRobustnessExtension() {
  return false;
}

bool GLContextIOS::GetTotalGpuMemory(size_t* bytes) {
  DCHECK(false);
  return false;
}

void GLContextIOS::SetUnbindFboOnMakeCurrent() {
  DCHECK(false);
}

class GLShareGroup;

scoped_refptr<GLContext> GLContext::CreateGLContext(
    GLShareGroup* share_group,
    GLSurface* compatible_surface,
    GpuPreference gpu_preference) {
  TRACE_EVENT0("gpu", "GLContext::CreateGLContext");

  scoped_refptr<GLContext> context;

  context = new GLContextIOS(share_group);

  if (!context->Initialize(compatible_surface, gpu_preference))
    return nullptr;

  return context;
}

}  // namespace gfx
