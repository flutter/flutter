// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_egl_manager.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

namespace flutter {
namespace android {

namespace {

// EGL configuration constants.
constexpr EGLint kColorBits = 8;  // 8 bits per channel for RGBA8888.
constexpr EGLint kDepthBits =
    0;  // Impeller GLES does not require depth buffer.
constexpr EGLint kStencilBits =
    8;  // 8-bit stencil buffer for clipping and paths.
constexpr EGLint kGlesVersion3 = 3;  // OpenGL ES 3.0 client version.
constexpr EGLint kGlesVersion2 = 2;  // OpenGL ES 2.0 fallback client version.
constexpr EGLint kPbufferDimension = 1;  // 1x1 pixel buffer offscreen surface.
constexpr int32_t kAutoDimension = 0;  // 0 dimensions match ANativeWindow size.

}  // namespace

AndroidEGLManager::AndroidEGLManager() = default;

AndroidEGLManager::~AndroidEGLManager() {
  TRACE_EVENT0("flutter", "AndroidEGLManager::~AndroidEGLManager");
  std::lock_guard<std::mutex> lock(mutex_);
  if (display_ != EGL_NO_DISPLAY) {
    if (eglGetCurrentContext() == render_context_ ||
        eglGetCurrentContext() == resource_context_) {
      eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
    }
    if (window_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(display_, window_surface_);
      window_surface_ = EGL_NO_SURFACE;
    }
    if (render_pbuffer_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(display_, render_pbuffer_surface_);
      render_pbuffer_surface_ = EGL_NO_SURFACE;
    }
    if (resource_pbuffer_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(display_, resource_pbuffer_surface_);
      resource_pbuffer_surface_ = EGL_NO_SURFACE;
    }
    if (resource_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(display_, resource_context_);
      resource_context_ = EGL_NO_CONTEXT;
    }
    if (render_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(display_, render_context_);
      render_context_ = EGL_NO_CONTEXT;
    }
    eglTerminate(display_);
    display_ = EGL_NO_DISPLAY;
  }
  if (current_window_) {
    ANativeWindow_release(current_window_);
    current_window_ = nullptr;
  }
  if (pending_window_) {
    ANativeWindow_release(pending_window_);
    pending_window_ = nullptr;
  }
  is_valid_ = false;
}

bool AndroidEGLManager::Initialize() {
  TRACE_EVENT0("flutter", "AndroidEGLManager::Initialize");
  std::lock_guard<std::mutex> lock(mutex_);
  if (is_valid_) {
    return true;
  }

  display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (display_ == EGL_NO_DISPLAY) {
    FML_LOG(ERROR) << "Failed to get default EGL display: " << eglGetError();
    return false;
  }

  EGLint major = 0;
  EGLint minor = 0;
  if (eglInitialize(display_, &major, &minor) != EGL_TRUE) {
    FML_LOG(ERROR) << "Failed to initialize EGL display: " << eglGetError();
    display_ = EGL_NO_DISPLAY;
    return false;
  }

  if (eglBindAPI(EGL_OPENGL_ES_API) != EGL_TRUE) {
    FML_LOG(ERROR) << "Failed to bind OpenGL ES API: " << eglGetError();
    eglTerminate(display_);
    display_ = EGL_NO_DISPLAY;
    return false;
  }

  if (!ChooseConfigLocked()) {
    FML_LOG(ERROR) << "Failed to choose EGLConfig";
    eglTerminate(display_);
    display_ = EGL_NO_DISPLAY;
    return false;
  }

  if (!CreateContextsLocked()) {
    FML_LOG(ERROR) << "Failed to create EGL contexts";
    eglTerminate(display_);
    display_ = EGL_NO_DISPLAY;
    return false;
  }

  if (!CreatePbufferSurfacesLocked()) {
    FML_LOG(ERROR) << "Failed to create EGL pbuffer surfaces";
    if (resource_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(display_, resource_context_);
      resource_context_ = EGL_NO_CONTEXT;
    }
    if (render_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(display_, render_context_);
      render_context_ = EGL_NO_CONTEXT;
    }
    eglTerminate(display_);
    display_ = EGL_NO_DISPLAY;
    return false;
  }

  is_valid_ = true;
  return true;
}

bool AndroidEGLManager::IsValid() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return is_valid_;
}

bool AndroidEGLManager::ChooseConfigLocked() {
  const EGLint config_attribs_es3[] = {
      EGL_RENDERABLE_TYPE,
      EGL_OPENGL_ES3_BIT,
      EGL_SURFACE_TYPE,
      EGL_WINDOW_BIT | EGL_PBUFFER_BIT,
      EGL_RED_SIZE,
      kColorBits,
      EGL_GREEN_SIZE,
      kColorBits,
      EGL_BLUE_SIZE,
      kColorBits,
      EGL_ALPHA_SIZE,
      kColorBits,
      EGL_DEPTH_SIZE,
      kDepthBits,
      EGL_STENCIL_SIZE,
      kStencilBits,
      EGL_NONE,
  };

  // Request 1 matching configuration; EGL orders matching configs by priority.
  constexpr EGLint kRequestedConfigs = 1;
  EGLint num_configs = 0;
  if (eglChooseConfig(display_, config_attribs_es3, &config_, kRequestedConfigs,
                      &num_configs) == EGL_TRUE &&
      num_configs > 0) {
    return true;
  }

  // Fallback to OpenGL ES 2 configuration.
  const EGLint config_attribs_es2[] = {
      EGL_RENDERABLE_TYPE,
      EGL_OPENGL_ES2_BIT,
      EGL_SURFACE_TYPE,
      EGL_WINDOW_BIT | EGL_PBUFFER_BIT,
      EGL_RED_SIZE,
      kColorBits,
      EGL_GREEN_SIZE,
      kColorBits,
      EGL_BLUE_SIZE,
      kColorBits,
      EGL_ALPHA_SIZE,
      kColorBits,
      EGL_DEPTH_SIZE,
      kDepthBits,
      EGL_STENCIL_SIZE,
      kStencilBits,
      EGL_NONE,
  };

  if (eglChooseConfig(display_, config_attribs_es2, &config_, kRequestedConfigs,
                      &num_configs) == EGL_TRUE &&
      num_configs > 0) {
    return true;
  }

  FML_LOG(ERROR) << "Failed to find matching EGL config: " << eglGetError();
  return false;
}

bool AndroidEGLManager::CreateContextsLocked() {
  const EGLint context_attribs_es3[] = {
      EGL_CONTEXT_CLIENT_VERSION,
      kGlesVersion3,
      EGL_NONE,
  };

  render_context_ =
      eglCreateContext(display_, config_, EGL_NO_CONTEXT, context_attribs_es3);
  const EGLint* context_attribs = context_attribs_es3;

  if (render_context_ == EGL_NO_CONTEXT) {
    const EGLint context_attribs_es2[] = {
        EGL_CONTEXT_CLIENT_VERSION,
        kGlesVersion2,
        EGL_NONE,
    };
    render_context_ = eglCreateContext(display_, config_, EGL_NO_CONTEXT,
                                       context_attribs_es2);
    context_attribs = context_attribs_es2;
  }

  if (render_context_ == EGL_NO_CONTEXT) {
    FML_LOG(ERROR) << "Failed to create render EGL context: " << eglGetError();
    return false;
  }

  resource_context_ =
      eglCreateContext(display_, config_, render_context_, context_attribs);
  if (resource_context_ == EGL_NO_CONTEXT) {
    FML_LOG(ERROR) << "Failed to create resource EGL context: "
                   << eglGetError();
    eglDestroyContext(display_, render_context_);
    render_context_ = EGL_NO_CONTEXT;
    return false;
  }

  return true;
}

bool AndroidEGLManager::CreatePbufferSurfacesLocked() {
  const EGLint pbuffer_attribs[] = {
      EGL_WIDTH, kPbufferDimension, EGL_HEIGHT, kPbufferDimension, EGL_NONE,
  };

  render_pbuffer_surface_ =
      eglCreatePbufferSurface(display_, config_, pbuffer_attribs);
  if (render_pbuffer_surface_ == EGL_NO_SURFACE) {
    FML_LOG(ERROR) << "Failed to create render pbuffer surface: "
                   << eglGetError();
    return false;
  }

  resource_pbuffer_surface_ =
      eglCreatePbufferSurface(display_, config_, pbuffer_attribs);
  if (resource_pbuffer_surface_ == EGL_NO_SURFACE) {
    FML_LOG(ERROR) << "Failed to create resource pbuffer surface: "
                   << eglGetError();
    eglDestroySurface(display_, render_pbuffer_surface_);
    render_pbuffer_surface_ = EGL_NO_SURFACE;
    return false;
  }
  return true;
}

void AndroidEGLManager::SetNativeWindow(ANativeWindow* window) {
  TRACE_EVENT0("flutter", "AndroidEGLManager::SetNativeWindow");
  std::lock_guard<std::mutex> lock(mutex_);
  if (window) {
    ANativeWindow_acquire(window);
  }
  if (pending_window_) {
    ANativeWindow_release(pending_window_);
  }
  pending_window_ = window;
  window_changed_ = true;
}

bool AndroidEGLManager::MakeCurrent() {
  TRACE_EVENT0("flutter", "AndroidEGLManager::MakeCurrent");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_valid_) {
    return false;
  }

  if (window_changed_) {
    if (window_surface_ != EGL_NO_SURFACE) {
      if (eglGetCurrentSurface(EGL_DRAW) == window_surface_ ||
          eglGetCurrentSurface(EGL_READ) == window_surface_) {
        eglMakeCurrent(display_, render_pbuffer_surface_,
                       render_pbuffer_surface_, render_context_);
      }
      eglDestroySurface(display_, window_surface_);
      window_surface_ = EGL_NO_SURFACE;
    }
    if (current_window_) {
      ANativeWindow_release(current_window_);
      current_window_ = nullptr;
    }
    current_window_ = pending_window_;
    pending_window_ = nullptr;
    window_changed_ = false;

    if (current_window_) {
      EGLint format = 0;
      if (eglGetConfigAttrib(display_, config_, EGL_NATIVE_VISUAL_ID,
                             &format) == EGL_TRUE) {
        ANativeWindow_setBuffersGeometry(current_window_, kAutoDimension,
                                         kAutoDimension, format);
      }
      window_surface_ =
          eglCreateWindowSurface(display_, config_, current_window_, nullptr);
      if (window_surface_ == EGL_NO_SURFACE) {
        FML_LOG(ERROR) << "Failed to create EGL window surface: "
                       << eglGetError();
      }
    }
  }

  EGLSurface target_surface = (window_surface_ != EGL_NO_SURFACE)
                                  ? window_surface_
                                  : render_pbuffer_surface_;
  if (target_surface == EGL_NO_SURFACE || render_context_ == EGL_NO_CONTEXT) {
    return false;
  }

  if (eglGetCurrentContext() == render_context_ &&
      eglGetCurrentSurface(EGL_DRAW) == target_surface &&
      eglGetCurrentSurface(EGL_READ) == target_surface) {
    return true;
  }

  if (eglMakeCurrent(display_, target_surface, target_surface,
                     render_context_) != EGL_TRUE) {
    FML_LOG(ERROR) << "eglMakeCurrent failed: " << eglGetError();
    return false;
  }
  return true;
}

bool AndroidEGLManager::ClearCurrent() {
  TRACE_EVENT0("flutter", "AndroidEGLManager::ClearCurrent");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_valid_ || display_ == EGL_NO_DISPLAY) {
    return true;
  }
  if (eglGetCurrentContext() == EGL_NO_CONTEXT) {
    return true;
  }
  if (eglMakeCurrent(display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                     EGL_NO_CONTEXT) != EGL_TRUE) {
    FML_LOG(ERROR) << "eglMakeCurrent clear failed: " << eglGetError();
    return false;
  }
  return true;
}

bool AndroidEGLManager::MakeResourceCurrent() {
  TRACE_EVENT0("flutter", "AndroidEGLManager::MakeResourceCurrent");
  std::lock_guard<std::mutex> lock(mutex_);
  if (!is_valid_ || resource_context_ == EGL_NO_CONTEXT ||
      resource_pbuffer_surface_ == EGL_NO_SURFACE) {
    return false;
  }
  if (eglGetCurrentContext() == resource_context_ &&
      eglGetCurrentSurface(EGL_DRAW) == resource_pbuffer_surface_ &&
      eglGetCurrentSurface(EGL_READ) == resource_pbuffer_surface_) {
    return true;
  }
  if (eglMakeCurrent(display_, resource_pbuffer_surface_,
                     resource_pbuffer_surface_,
                     resource_context_) != EGL_TRUE) {
    FML_LOG(ERROR) << "eglMakeCurrent resource failed: " << eglGetError();
    return false;
  }
  return true;
}

bool AndroidEGLManager::Present() {
  TRACE_EVENT0("flutter", "AndroidEGLManager::Present");
  EGLDisplay display = EGL_NO_DISPLAY;
  EGLSurface surface = EGL_NO_SURFACE;
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (!is_valid_ || window_surface_ == EGL_NO_SURFACE ||
        (window_changed_ && pending_window_ == nullptr)) {
      return true;
    }
    display = display_;
    surface = window_surface_;
  }
  // eglSwapBuffers is called outside mutex_ to avoid holding the lock during
  // VSync backpressure or buffer queue wait, which would block the Android
  // platform UI thread during window lifecycle changes.
  if (eglSwapBuffers(display, surface) != EGL_TRUE) {
    FML_LOG(ERROR) << "eglSwapBuffers failed: " << eglGetError();
    return false;
  }
  return true;
}

EGLDisplay AndroidEGLManager::GetDisplay() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return display_;
}

EGLContext AndroidEGLManager::GetContext() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return render_context_;
}

EGLContext AndroidEGLManager::GetResourceContext() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return resource_context_;
}

}  // namespace android
}  // namespace flutter
