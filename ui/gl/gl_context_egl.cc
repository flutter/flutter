// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_context_egl.h"

#include "base/command_line.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/trace_event/trace_event.h"
#include "build/build_config.h"
#include "third_party/khronos/EGL/egl.h"
#include "third_party/khronos/EGL/eglext.h"
#include "ui/gl/egl_util.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_surface_egl.h"

#if defined(USE_X11)
extern "C" {
#include <X11/Xlib.h>
}
#endif

using ui::GetLastEGLErrorString;

namespace gfx {

GLContextEGL::GLContextEGL(GLShareGroup* share_group)
    : GLContextReal(share_group),
      context_(NULL),
      display_(NULL),
      config_(NULL),
      unbind_fbo_on_makecurrent_(false),
      swap_interval_(1) {
}

bool GLContextEGL::Initialize(
    GLSurface* compatible_surface, GpuPreference gpu_preference) {
  DCHECK(compatible_surface);
  DCHECK(!context_);

  EGLint context_client_version = 2;
  if (base::CommandLine::ForCurrentProcess()->HasSwitch(
          switches::kEnableUnsafeES3APIs)) {
    context_client_version = 3;
  }

  const EGLint kContextAttributes[] = {
    EGL_CONTEXT_CLIENT_VERSION, context_client_version,
    EGL_NONE
  };
  const EGLint kContextRobustnessAttributes[] = {
    EGL_CONTEXT_CLIENT_VERSION, context_client_version,
    EGL_CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY_EXT,
    EGL_LOSE_CONTEXT_ON_RESET_EXT,
    EGL_NONE
  };

  display_ = compatible_surface->GetDisplay();
  config_ = compatible_surface->GetConfig();

  const EGLint* context_attributes = NULL;
  if (GLSurfaceEGL::IsCreateContextRobustnessSupported()) {
    DVLOG(1) << "EGL_EXT_create_context_robustness supported.";
    context_attributes = kContextRobustnessAttributes;
  } else {
    // At some point we should require the presence of the robustness
    // extension and remove this code path.
    DVLOG(1) << "EGL_EXT_create_context_robustness NOT supported.";
    context_attributes = kContextAttributes;
  }

  context_ = eglCreateContext(
      display_,
      config_,
      share_group() ? share_group()->GetHandle() : NULL,
      context_attributes);

  if (!context_) {
    LOG(ERROR) << "eglCreateContext failed with error "
               << GetLastEGLErrorString();
    return false;
  }

  return true;
}

void GLContextEGL::Destroy() {
  if (context_) {
    if (!eglDestroyContext(display_, context_)) {
      LOG(ERROR) << "eglDestroyContext failed with error "
                 << GetLastEGLErrorString();
    }

    context_ = NULL;
  }
}

bool GLContextEGL::MakeCurrent(GLSurface* surface) {
  DCHECK(context_);
  if (IsCurrent(surface))
      return true;

  ScopedReleaseCurrent release_current;
  TRACE_EVENT2("gpu", "GLContextEGL::MakeCurrent",
               "context", context_,
               "surface", surface);

  if (unbind_fbo_on_makecurrent_ &&
      eglGetCurrentContext() != EGL_NO_CONTEXT) {
    glBindFramebufferEXT(GL_FRAMEBUFFER, 0);
  }

  if (!eglMakeCurrent(display_,
                      surface->GetHandle(),
                      surface->GetHandle(),
                      context_)) {
    DVLOG(1) << "eglMakeCurrent failed with error "
             << GetLastEGLErrorString();
    return false;
  }

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

void GLContextEGL::SetUnbindFboOnMakeCurrent() {
  unbind_fbo_on_makecurrent_ = true;
}

void GLContextEGL::ReleaseCurrent(GLSurface* surface) {
  if (!IsCurrent(surface))
    return;

  if (unbind_fbo_on_makecurrent_)
    glBindFramebufferEXT(GL_FRAMEBUFFER, 0);

  SetCurrent(NULL);
  eglMakeCurrent(display_,
                 EGL_NO_SURFACE,
                 EGL_NO_SURFACE,
                 EGL_NO_CONTEXT);
}

bool GLContextEGL::IsCurrent(GLSurface* surface) {
  DCHECK(context_);

  bool native_context_is_current = context_ == eglGetCurrentContext();

  // If our context is current then our notion of which GLContext is
  // current must be correct. On the other hand, third-party code
  // using OpenGL might change the current context.
  DCHECK(!native_context_is_current || (GetRealCurrent() == this));

  if (!native_context_is_current)
    return false;

  if (surface) {
    if (surface->GetHandle() != eglGetCurrentSurface(EGL_DRAW))
      return false;
  }

  return true;
}

void* GLContextEGL::GetHandle() {
  return context_;
}

void GLContextEGL::OnSetSwapInterval(int interval) {
  DCHECK(IsCurrent(NULL) && GLSurface::GetCurrent());

  // This is a surfaceless context. eglSwapInterval doesn't take any effect in
  // this case and will just return EGL_BAD_SURFACE.
  if (GLSurface::GetCurrent()->IsSurfaceless())
    return;

  if (!eglSwapInterval(display_, interval)) {
    LOG(ERROR) << "eglSwapInterval failed with error "
               << GetLastEGLErrorString();
  } else {
    swap_interval_ = interval;
    GLSurface::GetCurrent()->OnSetSwapInterval(interval);
  }
}

std::string GLContextEGL::GetExtensions() {
  const char* extensions = eglQueryString(display_,
                                          EGL_EXTENSIONS);
  if (!extensions)
    return GLContext::GetExtensions();

  return GLContext::GetExtensions() + " " + extensions;
}

bool GLContextEGL::WasAllocatedUsingRobustnessExtension() {
  return GLSurfaceEGL::IsCreateContextRobustnessSupported();
}

GLContextEGL::~GLContextEGL() {
  Destroy();
}

#if !defined(OS_ANDROID)
bool GLContextEGL::GetTotalGpuMemory(size_t* bytes) {
  DCHECK(bytes);
  *bytes = 0;
  return false;
}
#endif

}  // namespace gfx
