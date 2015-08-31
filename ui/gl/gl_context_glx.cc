// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

extern "C" {
#include <X11/Xlib.h>
}

#include "ui/gl/gl_context_glx.h"

#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/GL/glextchromium.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface_glx.h"

namespace gfx {

GLContextGLX::GLContextGLX(GLShareGroup* share_group)
  : GLContextReal(share_group),
    context_(NULL),
    display_(NULL) {
}

XDisplay* GLContextGLX::display() {
  return display_;
}

bool GLContextGLX::Initialize(
    GLSurface* compatible_surface, GpuPreference gpu_preference) {
  display_ = static_cast<XDisplay*>(compatible_surface->GetDisplay());

  GLXContext share_handle = static_cast<GLXContext>(
      share_group() ? share_group()->GetHandle() : NULL);

  if (GLSurfaceGLX::IsCreateContextSupported()) {
    DVLOG(1) << "GLX_ARB_create_context supported.";
    std::vector<int> attribs;
    if (GLSurfaceGLX::IsCreateContextRobustnessSupported()) {
      DVLOG(1) << "GLX_ARB_create_context_robustness supported.";
      attribs.push_back(GLX_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB);
      attribs.push_back(GLX_LOSE_CONTEXT_ON_RESET_ARB);
    }
    attribs.push_back(0);
    context_ = glXCreateContextAttribsARB(
        display_,
        static_cast<GLXFBConfig>(compatible_surface->GetConfig()),
        share_handle,
        True,
        &attribs.front());
    if (!context_) {
      LOG(ERROR) << "Failed to create GL context with "
                 << "glXCreateContextAttribsARB.";
      return false;
    }
  } else {
    DVLOG(1) << "GLX_ARB_create_context not supported.";
    context_ = glXCreateNewContext(
       display_,
       static_cast<GLXFBConfig>(compatible_surface->GetConfig()),
       GLX_RGBA_TYPE,
       share_handle,
       True);
    if (!context_) {
      LOG(ERROR) << "Failed to create GL context with glXCreateNewContext.";
      return false;
    }
  }
  DCHECK(context_);
  DVLOG(1) << "  Successfully allocated "
           << (compatible_surface->IsOffscreen() ?
               "offscreen" : "onscreen")
           << " GL context with LOSE_CONTEXT_ON_RESET_ARB";

  DVLOG(1) << (compatible_surface->IsOffscreen() ? "Offscreen" : "Onscreen")
           << " context was "
           << (glXIsDirect(display_,
                           static_cast<GLXContext>(context_))
                   ? "direct" : "indirect")
           << ".";

  return true;
}

void GLContextGLX::Destroy() {
  if (context_) {
    glXDestroyContext(display_,
                      static_cast<GLXContext>(context_));
    context_ = NULL;
  }
}

bool GLContextGLX::MakeCurrent(GLSurface* surface) {
  DCHECK(context_);
  if (IsCurrent(surface))
    return true;

  ScopedReleaseCurrent release_current;
  TRACE_EVENT0("gpu", "GLContextGLX::MakeCurrent");
  if (!glXMakeContextCurrent(
      display_,
      reinterpret_cast<GLXDrawable>(surface->GetHandle()),
      reinterpret_cast<GLXDrawable>(surface->GetHandle()),
      static_cast<GLXContext>(context_))) {
    LOG(ERROR) << "Couldn't make context current with X drawable.";
    Destroy();
    return false;
  }

  // Set this as soon as the context is current, since we might call into GL.
  SetRealGLApi();

  SetCurrent(surface);
  if (!InitializeDynamicBindings()) {
    Destroy();
    return false;
  }

  if (!surface->OnMakeCurrent(this)) {
    LOG(ERROR) << "Could not make current.";
    Destroy();
    return false;
  }

  release_current.Cancel();
  return true;
}

void GLContextGLX::ReleaseCurrent(GLSurface* surface) {
  if (!IsCurrent(surface))
    return;

  SetCurrent(NULL);
  if (!glXMakeContextCurrent(display_, 0, 0, 0))
    LOG(ERROR) << "glXMakeCurrent failed in ReleaseCurrent";
}

bool GLContextGLX::IsCurrent(GLSurface* surface) {
  bool native_context_is_current =
      glXGetCurrentContext() == static_cast<GLXContext>(context_);

  // If our context is current then our notion of which GLContext is
  // current must be correct. On the other hand, third-party code
  // using OpenGL might change the current context.
  DCHECK(!native_context_is_current || (GetRealCurrent() == this));

  if (!native_context_is_current)
    return false;

  if (surface) {
    if (glXGetCurrentDrawable() !=
        reinterpret_cast<GLXDrawable>(surface->GetHandle())) {
      return false;
    }
  }

  return true;
}

void* GLContextGLX::GetHandle() {
  return context_;
}

void GLContextGLX::OnSetSwapInterval(int interval) {
  DCHECK(IsCurrent(NULL));
  if (HasExtension("GLX_EXT_swap_control") &&
      g_driver_glx.fn.glXSwapIntervalEXTFn) {
    glXSwapIntervalEXT(
        display_,
        glXGetCurrentDrawable(),
        interval);
  } else if (HasExtension("GLX_MESA_swap_control") &&
             g_driver_glx.fn.glXSwapIntervalMESAFn) {
    glXSwapIntervalMESA(interval);
  } else {
    if(interval == 0)
      LOG(WARNING) <<
          "Could not disable vsync: driver does not "
          "support GLX_EXT_swap_control";
  }
}

std::string GLContextGLX::GetExtensions() {
  DCHECK(IsCurrent(NULL));
  const char* extensions = GLSurfaceGLX::GetGLXExtensions();
  if (extensions) {
    return GLContext::GetExtensions() + " " + extensions;
  }

  return GLContext::GetExtensions();
}

bool GLContextGLX::GetTotalGpuMemory(size_t* bytes) {
  DCHECK(bytes);
  *bytes = 0;
  if (HasExtension("GL_NVX_gpu_memory_info")) {
    GLint kbytes = 0;
    glGetIntegerv(GL_GPU_MEMORY_INFO_DEDICATED_VIDMEM_NVX, &kbytes);
    *bytes = 1024*kbytes;
    return true;
  }
  return false;
}

bool GLContextGLX::WasAllocatedUsingRobustnessExtension() {
  return GLSurfaceGLX::IsCreateContextRobustnessSupported();
}

GLContextGLX::~GLContextGLX() {
  Destroy();
}

}  // namespace gfx
