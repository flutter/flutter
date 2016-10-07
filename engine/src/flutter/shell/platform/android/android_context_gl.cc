// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_context_gl.h"

#include <utility>

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
      DLOG(INFO) << "EGL Error: " << pairs[i].name << " (" << pairs[i].code
                 << ")";
      return;
    }
  }

  DLOG(WARNING) << "Unknown EGL Error";
}

static EGLResult<EGLSurface> CreateContext(EGLDisplay display,
                                           EGLConfig config,
                                           EGLContext share = EGL_NO_CONTEXT) {
  EGLint attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};

  EGLContext context = eglCreateContext(display, config, share, attributes);

  return {context != EGL_NO_CONTEXT, context};
}

static EGLResult<EGLConfig> ChooseEGLConfiguration(
    EGLDisplay display,
    PlatformView::SurfaceConfig config) {
  EGLint attributes[] = {
      // clang-format off
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
      EGL_SURFACE_TYPE,    EGL_WINDOW_BIT,
      EGL_RED_SIZE,        config.red_bits,
      EGL_GREEN_SIZE,      config.green_bits,
      EGL_BLUE_SIZE,       config.blue_bits,
      EGL_ALPHA_SIZE,      config.alpha_bits,
      EGL_DEPTH_SIZE,      config.depth_bits,
      EGL_STENCIL_SIZE,    config.stencil_bits,
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
static EGLResult<EGLSurface> CreateWindowSurface(
    EGLDisplay display,
    EGLConfig config,
    AndroidNativeWindow::Handle window_handle) {
  // The configurations are only required when dealing with extensions or VG.
  // We do neither.
  EGLSurface surface = eglCreateWindowSurface(
      display, config, reinterpret_cast<EGLNativeWindowType>(window_handle),
      nullptr);
  return {surface != EGL_NO_SURFACE, surface};
}

// For offscreen rendering.
static EGLResult<EGLSurface> CreatePBufferSurface(EGLDisplay display,
                                                  EGLConfig config) {
  // We only ever create pbuffer surfaces for background resource loading
  // contexts. We never bind the pbuffer to anything.
  const EGLint attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};
  EGLSurface surface = eglCreatePbufferSurface(display, config, attribs);
  return {surface != EGL_NO_SURFACE, surface};
}

static EGLResult<EGLSurface> CreateSurface(EGLDisplay display,
                                           EGLConfig config,
                                           const AndroidNativeWindow& window) {
  return window.IsValid()
             ? CreateWindowSurface(display, config, window.handle())
             : CreatePBufferSurface(display, config);
}

AndroidContextGL::AndroidContextGL(ftl::RefPtr<AndroidEnvironmentGL> env,
                                   AndroidNativeWindow window,
                                   PlatformView::SurfaceConfig config,
                                   const AndroidContextGL* share_context)
    : environment_(env),
      window_(std::move(window)),
      config_(nullptr),
      surface_(EGL_NO_SURFACE),
      context_(EGL_NO_CONTEXT),
      valid_(false) {
  if (!environment_->IsValid()) {
    return;
  }

  bool success = false;

  // Choose a valid configuration.

  std::tie(success, config_) =
      ChooseEGLConfiguration(environment_->Display(), config);

  if (!success) {
    DLOG(INFO) << "Could not choose a configuration.";
    LogLastEGLError();
    return;
  }

  // Create a surface for the configuration.

  std::tie(success, surface_) =
      CreateSurface(environment_->Display(), config_, window_);

  if (!success) {
    DLOG(INFO) << "Could not create the surface.";
    LogLastEGLError();
    return;
  }

  // Create a context for the configuration.

  std::tie(success, context_) = CreateContext(
      environment_->Display(), config_,
      share_context != nullptr ? share_context->context_ : EGL_NO_CONTEXT);

  if (!success) {
    DLOG(INFO) << "Could not create a context";
    LogLastEGLError();
    return;
  }

  // All done!
  valid_ = true;
}

AndroidContextGL::AndroidContextGL(ftl::RefPtr<AndroidEnvironmentGL> env,
                                   PlatformView::SurfaceConfig config,
                                   const AndroidContextGL* share_context)
    : AndroidContextGL(env,
                       AndroidNativeWindow{nullptr},
                       config,
                       share_context) {}

AndroidContextGL::~AndroidContextGL() {
  if (!TeardownContext(environment_->Display(), context_)) {
    LOG(INFO) << "Could not tear down the EGL context. Possible resource leak.";
    LogLastEGLError();
  }

  if (!TeardownSurface(environment_->Display(), surface_)) {
    LOG(INFO) << "Could not tear down the EGL surface. Possible resource leak.";
    LogLastEGLError();
  }
}

ftl::RefPtr<AndroidEnvironmentGL> AndroidContextGL::Environment() const {
  return environment_;
}

bool AndroidContextGL::IsValid() const {
  return valid_;
}

bool AndroidContextGL::MakeCurrent() {
  if (eglMakeCurrent(environment_->Display(), surface_, surface_, context_) !=
      EGL_TRUE) {
    LOG(INFO) << "Could not make the context current";
    LogLastEGLError();
    return false;
  }
  return true;
}

bool AndroidContextGL::ClearCurrent() {
  if (eglMakeCurrent(environment_->Display(), EGL_NO_SURFACE, EGL_NO_SURFACE,
                     EGL_NO_CONTEXT) != EGL_TRUE) {
    LOG(INFO) << "Could not clear the current context";
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
    LOG(ERROR) << "Unable to query EGL surface size";
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

  bool success = false;
  std::tie(success, surface_) =
      CreateSurface(environment_->Display(), config_, window_);

  if (!success) {
    LOG(ERROR) << "Unable to create EGL window surface on resize.";
    return false;
  }

  return true;
}

}  // namespace shell
