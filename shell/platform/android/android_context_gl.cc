// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_gl.h"

#include <EGL/eglext.h>

#include <utility>

#include "flutter/fml/trace_event.h"

namespace shell {

template <class T>
using EGLResult = std::pair<bool, T>;

static void LogLastEGLError() {
  struct EGLNameErrorPair {
    const char* name;
    EGLint code;
  };

#define _EGL_ERROR_DESC(a) \
  { #a, a }

  const EGLNameErrorPair pairs[] = {
      _EGL_ERROR_DESC(EGL_SUCCESS),
      _EGL_ERROR_DESC(EGL_NOT_INITIALIZED),
      _EGL_ERROR_DESC(EGL_BAD_ACCESS),
      _EGL_ERROR_DESC(EGL_BAD_ALLOC),
      _EGL_ERROR_DESC(EGL_BAD_ATTRIBUTE),
      _EGL_ERROR_DESC(EGL_BAD_CONTEXT),
      _EGL_ERROR_DESC(EGL_BAD_CONFIG),
      _EGL_ERROR_DESC(EGL_BAD_CURRENT_SURFACE),
      _EGL_ERROR_DESC(EGL_BAD_DISPLAY),
      _EGL_ERROR_DESC(EGL_BAD_SURFACE),
      _EGL_ERROR_DESC(EGL_BAD_MATCH),
      _EGL_ERROR_DESC(EGL_BAD_PARAMETER),
      _EGL_ERROR_DESC(EGL_BAD_NATIVE_PIXMAP),
      _EGL_ERROR_DESC(EGL_BAD_NATIVE_WINDOW),
      _EGL_ERROR_DESC(EGL_CONTEXT_LOST),
  };

#undef _EGL_ERROR_DESC

  const auto count = sizeof(pairs) / sizeof(EGLNameErrorPair);

  EGLint last_error = eglGetError();

  for (size_t i = 0; i < count; i++) {
    if (last_error == pairs[i].code) {
      FML_LOG(ERROR) << "EGL Error: " << pairs[i].name << " (" << pairs[i].code
                     << ")";
      return;
    }
  }

  FML_LOG(ERROR) << "Unknown EGL Error";
}

static EGLResult<EGLSurface> CreateContext(EGLDisplay display,
                                           EGLConfig config,
                                           EGLContext share = EGL_NO_CONTEXT) {
  EGLint attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};

  EGLContext context = eglCreateContext(display, config, share, attributes);

  return {context != EGL_NO_CONTEXT, context};
}

static EGLResult<EGLConfig> ChooseEGLConfiguration(EGLDisplay display) {
  EGLint attributes[] = {
      // clang-format off
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
      EGL_SURFACE_TYPE,    EGL_WINDOW_BIT,
      EGL_RED_SIZE,        8,
      EGL_GREEN_SIZE,      8,
      EGL_BLUE_SIZE,       8,
      EGL_ALPHA_SIZE,      8,
      EGL_DEPTH_SIZE,      0,
      EGL_STENCIL_SIZE,    0,
      EGL_NONE,            // termination sentinel
      // clang-format on
  };

  EGLint config_count = 0;
  EGLConfig egl_config = nullptr;

  if (eglChooseConfig(display, attributes, &egl_config, 1, &config_count) !=
      EGL_TRUE) {
    return {false, nullptr};
  }

  bool success = config_count > 0 && egl_config != nullptr;

  return {success, success ? egl_config : nullptr};
}

static bool TeardownContext(EGLDisplay display, EGLContext context) {
  if (context != EGL_NO_CONTEXT) {
    return eglDestroyContext(display, context) == EGL_TRUE;
  }

  return true;
}

static bool TeardownSurface(EGLDisplay display, EGLSurface surface) {
  if (surface != EGL_NO_SURFACE) {
    return eglDestroySurface(display, surface) == EGL_TRUE;
  }

  return true;
}

// For onscreen rendering.
bool AndroidContextGL::CreateWindowSurface(
    fml::RefPtr<AndroidNativeWindow> window) {
  // The configurations are only required when dealing with extensions or VG.
  // We do neither.

  window_ = std::move(window);
  EGLDisplay display = environment_->Display();

  const EGLint attribs[] = {EGL_NONE};

  surface_ = eglCreateWindowSurface(
      display, config_,
      reinterpret_cast<EGLNativeWindowType>(window_->handle()), attribs);
  return surface_ != EGL_NO_SURFACE;
}

// For offscreen rendering.
bool AndroidContextGL::CreatePBufferSurface() {
  // We only ever create pbuffer surfaces for background resource loading
  // contexts. We never bind the pbuffer to anything.

  EGLDisplay display = environment_->Display();

  const EGLint attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};

  surface_ = eglCreatePbufferSurface(display, config_, attribs);
  return surface_ != EGL_NO_SURFACE;
}

AndroidContextGL::AndroidContextGL(fml::RefPtr<AndroidEnvironmentGL> env,
                                   const AndroidContextGL* share_context)
    : environment_(env),
      window_(nullptr),
      config_(nullptr),
      surface_(EGL_NO_SURFACE),
      context_(EGL_NO_CONTEXT),
      valid_(false) {
  if (!environment_->IsValid()) {
    return;
  }

  bool success = false;

  // Choose a valid configuration.

  std::tie(success, config_) = ChooseEGLConfiguration(environment_->Display());

  if (!success) {
    FML_LOG(ERROR) << "Could not choose an EGL configuration.";
    LogLastEGLError();
    return;
  }

  // Create a context for the configuration.

  std::tie(success, context_) = CreateContext(
      environment_->Display(), config_,
      share_context != nullptr ? share_context->context_ : EGL_NO_CONTEXT);

  if (!success) {
    FML_LOG(ERROR) << "Could not create an EGL context";
    LogLastEGLError();
    return;
  }

  if (!this->CreatePBufferSurface()) {
    FML_LOG(ERROR) << "Could not create the EGL surface.";
    LogLastEGLError();
    return;
  }

  // All done!
  valid_ = true;
}

AndroidContextGL::~AndroidContextGL() {
  if (!TeardownContext(environment_->Display(), context_)) {
    FML_LOG(ERROR)
        << "Could not tear down the EGL context. Possible resource leak.";
    LogLastEGLError();
  }

  if (!TeardownSurface(environment_->Display(), surface_)) {
    FML_LOG(ERROR)
        << "Could not tear down the EGL surface. Possible resource leak.";
    LogLastEGLError();
  }
}

fml::RefPtr<AndroidEnvironmentGL> AndroidContextGL::Environment() const {
  return environment_;
}

bool AndroidContextGL::IsValid() const {
  return valid_;
}

bool AndroidContextGL::MakeCurrent() {
  if (eglMakeCurrent(environment_->Display(), surface_, surface_, context_) !=
      EGL_TRUE) {
    FML_LOG(ERROR) << "Could not make the context current";
    LogLastEGLError();
    return false;
  }
  return true;
}

bool AndroidContextGL::ClearCurrent() {
  if (eglGetCurrentContext() != context_) {
    return true;
  }
  if (eglMakeCurrent(environment_->Display(), EGL_NO_SURFACE, EGL_NO_SURFACE,
                     EGL_NO_CONTEXT) != EGL_TRUE) {
    FML_LOG(ERROR) << "Could not clear the current context";
    LogLastEGLError();
    return false;
  }
  return true;
}

bool AndroidContextGL::SwapBuffers() {
  TRACE_EVENT0("flutter", "AndroidContextGL::SwapBuffers");
  return eglSwapBuffers(environment_->Display(), surface_);
}

SkISize AndroidContextGL::GetSize() {
  EGLint width = 0;
  EGLint height = 0;

  if (!eglQuerySurface(environment_->Display(), surface_, EGL_WIDTH, &width) ||
      !eglQuerySurface(environment_->Display(), surface_, EGL_HEIGHT,
                       &height)) {
    FML_LOG(ERROR) << "Unable to query EGL surface size";
    LogLastEGLError();
    return SkISize::Make(0, 0);
  }
  return SkISize::Make(width, height);
}

bool AndroidContextGL::Resize(const SkISize& size) {
  if (size == GetSize()) {
    return true;
  }

  ClearCurrent();

  TeardownSurface(environment_->Display(), surface_);

  if (!this->CreateWindowSurface(window_)) {
    FML_LOG(ERROR) << "Unable to create EGL window surface on resize.";
    return false;
  }

  MakeCurrent();

  return true;
}

}  // namespace shell
