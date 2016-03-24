// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_context_glfw.h"

#include <GLFW/glfw3.h>

#include "base/command_line.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/trace_event/trace_event.h"
#include "build/build_config.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context_stub.h"
#include "ui/gl/gl_surface_glfw.h"

namespace gfx {

GLContextGlfw::GLContextGlfw(GLShareGroup* share_group)
    : GLContextReal(share_group),
      surface_(NULL),
      context_(NULL),
      unbind_fbo_on_makecurrent_(false),
      swap_interval_(1) {
}

scoped_refptr<GLContext> GLContext::CreateGLContext(
    GLShareGroup* share_group,
    GLSurface* compatible_surface,
    GpuPreference gpu_preference) {
  TRACE_EVENT0("gpu", "GLContext::CreateGLContext");
  switch (GetGLImplementation()) {
    case kGLImplementationDesktopGL:
    case kGLImplementationEGLGLES2: {
      scoped_refptr<GLContext> context;
      context = new GLContextGlfw(share_group);
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


bool GLContextGlfw::Initialize(
    GLSurface* compatible_surface, GpuPreference gpu_preference) {
  DCHECK(compatible_surface);
  DCHECK(!surface_);
  DCHECK(!context_);

  surface_ = compatible_surface;
  context_ = reinterpret_cast<gfx::AcceleratedWidget>(surface_->GetHandle());

  return true;
}

void GLContextGlfw::Destroy() {
  if (surface_) {
    surface_ = NULL;
  }
  if (context_) {
    context_ = NULL;
  }
}

bool GLContextGlfw::MakeCurrent(GLSurface* surface) {
  DCHECK(surface_);
  if (IsCurrent(surface))
      return true;

  ScopedReleaseCurrent release_current;
  TRACE_EVENT2("gpu", "GLContextEGL::MakeCurrent",
               "context", surface_,
               "surface", surface);

  if (unbind_fbo_on_makecurrent_ && glfwGetCurrentContext() != NULL) {
    glBindFramebufferEXT(GL_FRAMEBUFFER, 0);
  }

  // Make the surface's context current.
  glfwMakeContextCurrent(context_);

  // Set this as soon as the context is current, since we might call into GL.
  SetRealGLApi();

  SetCurrent(surface);
  if (!InitializeDynamicBindings()) {
    return false;
  }

  if (!surface->OnMakeCurrent(this)) {
    LOG(ERROR) << "Could not make current.";
    return false;
  }

  surface->OnSetSwapInterval(swap_interval_);

  release_current.Cancel();
  return true;
}

void GLContextGlfw::SetUnbindFboOnMakeCurrent() {
  unbind_fbo_on_makecurrent_ = true;
}

void GLContextGlfw::ReleaseCurrent(GLSurface* surface) {
  if (!IsCurrent(surface))
    return;

  if (unbind_fbo_on_makecurrent_)
    glBindFramebufferEXT(GL_FRAMEBUFFER, 0);

  SetCurrent(NULL);
  glfwMakeContextCurrent(NULL);
}

bool GLContextGlfw::IsCurrent(GLSurface* surface) {
  DCHECK(surface_);
  DCHECK(context_);

  bool native_context_is_current = context_ == glfwGetCurrentContext();

  // If our context is current then our notion of which GLContext is
  // current must be correct. On the other hand, third-party code
  // using OpenGL might change the current context.
  DCHECK(!native_context_is_current || (GetRealCurrent() == this));

  if (!native_context_is_current)
    return false;

  return true;
}

void* GLContextGlfw::GetHandle() {
  return (void *)context_;
}

void GLContextGlfw::OnSetSwapInterval(int interval) {
  DCHECK(IsCurrent(NULL) && GLSurface::GetCurrent());

  glfwSwapInterval(interval);
  swap_interval_ = interval;
  GLSurface::GetCurrent()->OnSetSwapInterval(interval);
}

std::string GLContextGlfw::GetExtensions() {
  return GLContext::GetExtensions();
}

bool GLContextGlfw::WasAllocatedUsingRobustnessExtension() {
  int robust = glfwGetWindowAttrib(context_, GLFW_CONTEXT_ROBUSTNESS);
  return (robust != GLFW_NO_ROBUSTNESS);
}

GLContextGlfw::~GLContextGlfw() {
  Destroy();
}

#if !defined(OS_ANDROID)
bool GLContextGlfw::GetTotalGpuMemory(size_t* bytes) {
  // TODO(dalyj): Unimplemented.
  DCHECK(bytes);
  *bytes = 0;
  return false;
}
#endif

}  // namespace gfx
