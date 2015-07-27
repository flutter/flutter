// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_context_mac.h"
#include "ui/gl/gl_context_stub.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface.h"
#include "ui/gl/gl_switches.h"

#import <AppKit/AppKit.h>
#import <OpenGL/gl.h>

#define CAST_CONTEXT (reinterpret_cast<NSOpenGLContext*>(context_))

namespace gfx {

class GLShareGroup;

GLContextMac::GLContextMac(GLShareGroup* share_group)
    : GLContextReal(share_group),
      context_(0) {
  // Instead of creating a context here, we steal one from the NSOpenGLView
  // that is passed to us in the initialize call.
}

bool GLContextMac::Initialize(GLSurface* compatible_surface,
                              GpuPreference gpu_preference) {
  if (compatible_surface == nullptr) {
    return false;
  }

  auto view = reinterpret_cast<NSOpenGLView *>(compatible_surface->GetHandle());
  context_ = reinterpret_cast<uintptr_t>(view.openGLContext);
  [CAST_CONTEXT retain];

  return CAST_CONTEXT != nullptr;
}

void GLContextMac::Destroy() {
  [CAST_CONTEXT release];
  context_ = 0;
}

bool GLContextMac::MakeCurrent(GLSurface* surface) {
  [CAST_CONTEXT makeCurrentContext];

  SetRealGLApi();

  if (!InitializeDynamicBindings()) {
    return false;
  }

  if (!surface->OnMakeCurrent(this)) {
    return false;
  }

  return true;
}

void GLContextMac::ReleaseCurrent(GLSurface* surface) {
  [NSOpenGLContext clearCurrentContext];
}

bool GLContextMac::IsCurrent(GLSurface* surface) {
  return [NSOpenGLContext currentContext] == CAST_CONTEXT;
}

void* GLContextMac::GetHandle() {
  return reinterpret_cast<void *>(context_);
}

void GLContextMac::OnSetSwapInterval(int interval) {
}

std::string GLContextMac::GetExtensions() {
  return reinterpret_cast<const char*>(glGetString(GL_EXTENSIONS));
}

bool GLContextMac::WasAllocatedUsingRobustnessExtension() {
  return false;
}

bool GLContextMac::GetTotalGpuMemory(size_t* bytes) {
  DCHECK(false);
  return false;
}

void GLContextMac::SetUnbindFboOnMakeCurrent() {
  DCHECK(false);
}

GLContextMac::~GLContextMac() {
  Destroy();
}

scoped_refptr<GLContext> GLContext::CreateGLContext(
    GLShareGroup* share_group,
    GLSurface* compatible_surface,
    GpuPreference gpu_preference) {
  TRACE_EVENT0("gpu", "GLContext::CreateGLContext");
  switch (GetGLImplementation()) {
    case kGLImplementationDesktopGL:
    case kGLImplementationAppleGL: {
      scoped_refptr<GLContext> context;
      context = new GLContextMac(share_group);
      if (!context->Initialize(compatible_surface, gpu_preference))
        return NULL;

      return context;
    }
    case kGLImplementationMockGL:
      return new GLContextStub;
    default:
      NOTREACHED();
      return NULL;
  }
}

}  // namespace gfx
