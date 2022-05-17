// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/toolkit/egl/context.h"

#include "impeller/toolkit/egl/surface.h"

namespace impeller {
namespace egl {

Context::Context(EGLDisplay display, EGLContext context)
    : display_(display), context_(context) {}

Context::~Context() {
  if (context_ != EGL_NO_CONTEXT) {
    if (::eglDestroyContext(display_, context_) != EGL_TRUE) {
      IMPELLER_LOG_EGL_ERROR;
    }
  }
}

bool Context::IsValid() const {
  return context_ != EGL_NO_CONTEXT;
}

const EGLContext& Context::GetHandle() const {
  return context_;
}

static EGLBoolean EGLMakeCurrentIfNecessary(EGLDisplay display,
                                            EGLSurface draw,
                                            EGLSurface read,
                                            EGLContext context) {
  if (display != ::eglGetCurrentDisplay() ||
      draw != ::eglGetCurrentSurface(EGL_DRAW) ||
      read != ::eglGetCurrentSurface(EGL_READ) ||
      context != ::eglGetCurrentContext()) {
    return ::eglMakeCurrent(display, draw, read, context);
  }
  // The specified context configuration is already current.
  return EGL_TRUE;
}

bool Context::MakeCurrent(const Surface& surface) const {
  if (context_ == EGL_NO_CONTEXT) {
    return false;
  }
  const auto result = EGLMakeCurrentIfNecessary(display_,             //
                                                surface.GetHandle(),  //
                                                surface.GetHandle(),  //
                                                context_              //
                                                ) == EGL_TRUE;
  if (!result) {
    IMPELLER_LOG_EGL_ERROR;
  }
  return result;
}

bool Context::ClearCurrent() const {
  const auto result = EGLMakeCurrentIfNecessary(display_,        //
                                                EGL_NO_SURFACE,  //
                                                EGL_NO_SURFACE,  //
                                                EGL_NO_CONTEXT   //
                                                ) == EGL_TRUE;
  if (!result) {
    IMPELLER_LOG_EGL_ERROR;
  }
  return result;
}

}  // namespace egl
}  // namespace impeller
