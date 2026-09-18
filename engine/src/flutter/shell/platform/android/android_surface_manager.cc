// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_surface_manager.h"

#include <algorithm>
#include <cstring>

#include "flutter/fml/logging.h"

#if FML_OS_ANDROID
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <android/native_window.h>
#endif

namespace flutter {

std::unique_ptr<AndroidSurfaceManager> AndroidSurfaceManager::Create(
    AndroidRenderingAPI rendering_api) {
  auto manager = std::make_unique<AndroidSurfaceManager>(rendering_api);
  if (!manager->IsValid()) {
    FML_LOG(ERROR)
        << "Failed to initialize AndroidSurfaceManager for rendering API "
        << static_cast<int>(rendering_api);
  }
  return manager;
}

AndroidSurfaceManager::AndroidSurfaceManager(AndroidRenderingAPI rendering_api)
    : rendering_api_(rendering_api) {
  switch (rendering_api_) {
    case AndroidRenderingAPI::kSoftware:
      is_valid_ = true;
      break;
    case AndroidRenderingAPI::kSkiaOpenGLES:
    case AndroidRenderingAPI::kImpellerOpenGLES:
    case AndroidRenderingAPI::kImpellerAutoselect:
    case AndroidRenderingAPI::kImpellerVulkan:
      is_valid_ = InitializeEGL();
      break;
  }
}

AndroidSurfaceManager::~AndroidSurfaceManager() {
  ClearNativeWindow();
  TeardownEGL();
}

bool AndroidSurfaceManager::IsValid() const {
  return is_valid_;
}

bool AndroidSurfaceManager::IsFakeWindow() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  return is_fake_window_;
}

ANativeWindow* AndroidSurfaceManager::GetNativeWindow() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  return native_window_;
}

AndroidSurfaceDimensions AndroidSurfaceManager::GetNativeWindowSize() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  AndroidSurfaceDimensions dims;
#if FML_OS_ANDROID
  if (native_window_ != nullptr && !is_fake_window_) {
    dims.width = ANativeWindow_getWidth(native_window_);
    dims.height = ANativeWindow_getHeight(native_window_);
  }
#endif
  return dims;
}

bool AndroidSurfaceManager::SetNativeWindow(ANativeWindow* window,
                                            bool is_fake_window) {
  std::lock_guard<std::mutex> lock(window_mutex_);
  if (native_window_ == window && is_fake_window_ == is_fake_window) {
    return true;
  }

  DestroyOnscreenSurfaceLocked();

#if FML_OS_ANDROID
  if (native_window_ != nullptr && !is_fake_window_) {
    ANativeWindow_release(native_window_);
  }
#endif

  native_window_ = window;
  is_fake_window_ = is_fake_window;

#if FML_OS_ANDROID
  if (native_window_ != nullptr && !is_fake_window_) {
    ANativeWindow_acquire(native_window_);
    if (rendering_api_ == AndroidRenderingAPI::kSoftware) {
      ANativeWindow_setBuffersGeometry(native_window_, 0, 0,
                                       WINDOW_FORMAT_RGBA_8888);
    } else if (egl_display_ != EGL_NO_DISPLAY && egl_config_ != nullptr) {
      EGLint format = 0;
      if (eglGetConfigAttrib(egl_display_, egl_config_, EGL_NATIVE_VISUAL_ID,
                             &format) == EGL_TRUE &&
          format != 0) {
        ANativeWindow_setBuffersGeometry(native_window_, 0, 0, format);
      } else {
        ANativeWindow_setBuffersGeometry(native_window_, 0, 0,
                                         WINDOW_FORMAT_RGBA_8888);
      }
    }
  }
#endif

  if (native_window_ != nullptr) {
    return CreateOrUpdateOnscreenSurfaceLocked();
  }

  return true;
}

void AndroidSurfaceManager::ClearNativeWindow() {
  std::lock_guard<std::mutex> lock(window_mutex_);
  DestroyOnscreenSurfaceLocked();

#if FML_OS_ANDROID
  if (native_window_ != nullptr && !is_fake_window_) {
    ANativeWindow_release(native_window_);
  }
#endif

  native_window_ = nullptr;
  is_fake_window_ = false;
}

bool AndroidSurfaceManager::InitializeEGL() {
#if FML_OS_ANDROID
  egl_display_ = eglGetDisplay(EGL_DEFAULT_DISPLAY);
  if (egl_display_ == EGL_NO_DISPLAY) {
    FML_LOG(ERROR) << "eglGetDisplay failed: " << eglGetError();
    return false;
  }

  EGLint major = 0;
  EGLint minor = 0;
  if (eglInitialize(egl_display_, &major, &minor) != EGL_TRUE) {
    FML_LOG(ERROR) << "eglInitialize failed: " << eglGetError();
    return false;
  }

  const char* extensions = eglQueryString(egl_display_, EGL_EXTENSIONS);
  if (extensions != nullptr &&
      std::strstr(extensions, "EGL_KHR_surfaceless_context") != nullptr) {
    has_surfaceless_context_ = true;
  }

  bool try_es3 = (rendering_api_ == AndroidRenderingAPI::kImpellerOpenGLES);

  auto choose_and_create = [this](EGLint renderable_type,
                                  EGLint client_version) -> bool {
    const EGLint config_attribs[] = {
        EGL_RENDERABLE_TYPE,
        renderable_type,
        EGL_SURFACE_TYPE,
        EGL_WINDOW_BIT | EGL_PBUFFER_BIT,
        EGL_RED_SIZE,
        8,
        EGL_GREEN_SIZE,
        8,
        EGL_BLUE_SIZE,
        8,
        EGL_ALPHA_SIZE,
        8,
        EGL_DEPTH_SIZE,
        0,
        EGL_STENCIL_SIZE,
        0,
        EGL_NONE,
    };

    EGLint num_configs = 0;
    if (eglChooseConfig(egl_display_, config_attribs, &egl_config_, 1,
                        &num_configs) != EGL_TRUE ||
        num_configs == 0 || egl_config_ == nullptr) {
      return false;
    }

    const EGLint context_attribs[] = {
        EGL_CONTEXT_CLIENT_VERSION,
        client_version,
        EGL_NONE,
    };

    egl_resource_context_ = eglCreateContext(egl_display_, egl_config_,
                                             EGL_NO_CONTEXT, context_attribs);
    if (egl_resource_context_ == EGL_NO_CONTEXT) {
      return false;
    }

    egl_onscreen_context_ = eglCreateContext(
        egl_display_, egl_config_, egl_resource_context_, context_attribs);
    if (egl_onscreen_context_ == EGL_NO_CONTEXT) {
      eglDestroyContext(egl_display_, egl_resource_context_);
      egl_resource_context_ = EGL_NO_CONTEXT;
      return false;
    }

    return true;
  };

  bool success = false;
  if (try_es3) {
    success = choose_and_create(EGL_OPENGL_ES3_BIT, 3);
  }
  if (!success) {
    success = choose_and_create(EGL_OPENGL_ES2_BIT, 2);
  }

  if (!success) {
    FML_LOG(ERROR) << "Failed to initialize EGL config and contexts: "
                   << eglGetError();
    return false;
  }

  const EGLint pbuffer_attribs[] = {
      EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE,
  };
  egl_onscreen_pbuffer_surface_ =
      eglCreatePbufferSurface(egl_display_, egl_config_, pbuffer_attribs);
  egl_resource_pbuffer_surface_ =
      eglCreatePbufferSurface(egl_display_, egl_config_, pbuffer_attribs);
  if ((egl_onscreen_pbuffer_surface_ == EGL_NO_SURFACE ||
       egl_resource_pbuffer_surface_ == EGL_NO_SURFACE) &&
      !has_surfaceless_context_) {
    FML_LOG(ERROR) << "Failed to create EGL pbuffer surfaces: "
                   << eglGetError();
    return false;
  }

  return true;
#else
  return true;
#endif  // FML_OS_ANDROID
}

void AndroidSurfaceManager::TeardownEGL() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (egl_display_ != EGL_NO_DISPLAY) {
    eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                   EGL_NO_CONTEXT);

    if (egl_onscreen_pbuffer_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(egl_display_, egl_onscreen_pbuffer_surface_);
      egl_onscreen_pbuffer_surface_ = EGL_NO_SURFACE;
    }

    if (egl_resource_pbuffer_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(egl_display_, egl_resource_pbuffer_surface_);
      egl_resource_pbuffer_surface_ = EGL_NO_SURFACE;
    }

    if (egl_onscreen_surface_ != EGL_NO_SURFACE) {
      eglDestroySurface(egl_display_, egl_onscreen_surface_);
      egl_onscreen_surface_ = EGL_NO_SURFACE;
    }

    if (egl_onscreen_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(egl_display_, egl_onscreen_context_);
      egl_onscreen_context_ = EGL_NO_CONTEXT;
    }

    if (egl_resource_context_ != EGL_NO_CONTEXT) {
      eglDestroyContext(egl_display_, egl_resource_context_);
      egl_resource_context_ = EGL_NO_CONTEXT;
    }

    eglReleaseThread();
    egl_display_ = EGL_NO_DISPLAY;
  }
#endif  // FML_OS_ANDROID
}

bool AndroidSurfaceManager::CreateOrUpdateOnscreenSurfaceLocked() {
#if FML_OS_ANDROID
  if (rendering_api_ == AndroidRenderingAPI::kSoftware) {
    return true;
  }

  if (egl_display_ == EGL_NO_DISPLAY || egl_config_ == nullptr) {
    return is_fake_window_;
  }

  if (native_window_ == nullptr || is_fake_window_) {
    return true;
  }

  if (egl_onscreen_surface_ != EGL_NO_SURFACE) {
    eglDestroySurface(egl_display_, egl_onscreen_surface_);
    egl_onscreen_surface_ = EGL_NO_SURFACE;
  }

  egl_onscreen_surface_ = eglCreateWindowSurface(egl_display_, egl_config_,
                                                 native_window_, nullptr);
  if (egl_onscreen_surface_ == EGL_NO_SURFACE) {
    FML_LOG(ERROR) << "eglCreateWindowSurface failed: " << eglGetError();
    return false;
  }
  return true;
#else
  return true;
#endif
}

void AndroidSurfaceManager::DestroyOnscreenSurfaceLocked() {
#if FML_OS_ANDROID
  if (egl_display_ != EGL_NO_DISPLAY &&
      egl_onscreen_surface_ != EGL_NO_SURFACE) {
    EGLSurface surface_to_destroy = egl_onscreen_surface_;
    egl_onscreen_surface_ = EGL_NO_SURFACE;
    if (eglGetCurrentSurface(EGL_DRAW) == surface_to_destroy ||
        eglGetCurrentSurface(EGL_READ) == surface_to_destroy) {
      eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                     EGL_NO_CONTEXT);
    }
    eglDestroySurface(egl_display_, surface_to_destroy);
  }
#endif
}

bool AndroidSurfaceManager::MakeCurrent() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (is_fake_window_) {
    return true;
  }
  if (egl_display_ == EGL_NO_DISPLAY ||
      egl_onscreen_context_ == EGL_NO_CONTEXT) {
    return false;
  }
  EGLSurface surface = egl_onscreen_surface_;
  if (surface == EGL_NO_SURFACE) {
    surface =
        (egl_onscreen_pbuffer_surface_ != EGL_NO_SURFACE)
            ? egl_onscreen_pbuffer_surface_
            : (has_surfaceless_context_ ? EGL_NO_SURFACE : EGL_NO_SURFACE);
  }
  if (surface == EGL_NO_SURFACE && !has_surfaceless_context_) {
    return false;
  }
  EGLBoolean res =
      eglMakeCurrent(egl_display_, surface, surface, egl_onscreen_context_);
  if (res != EGL_TRUE) {
    FML_LOG(ERROR) << "eglMakeCurrent failed: " << eglGetError()
                   << " (surface=" << surface
                   << ", onscreen_surface=" << egl_onscreen_surface_
                   << ", pbuffer_surface=" << egl_onscreen_pbuffer_surface_
                   << ", context=" << egl_onscreen_context_ << ")";
    return false;
  }
  return true;
#else
  return true;
#endif
}

bool AndroidSurfaceManager::ClearCurrent() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (egl_display_ == EGL_NO_DISPLAY) {
    return true;
  }
  return eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        EGL_NO_CONTEXT) == EGL_TRUE;
#else
  return true;
#endif
}

bool AndroidSurfaceManager::MakeResourceCurrent() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (is_fake_window_) {
    return true;
  }
  if (egl_display_ == EGL_NO_DISPLAY ||
      egl_resource_context_ == EGL_NO_CONTEXT) {
    return false;
  }
  EGLSurface surface =
      (egl_resource_pbuffer_surface_ != EGL_NO_SURFACE)
          ? egl_resource_pbuffer_surface_
          : (has_surfaceless_context_ ? EGL_NO_SURFACE : EGL_NO_SURFACE);
  if (surface == EGL_NO_SURFACE && !has_surfaceless_context_) {
    return false;
  }
  EGLBoolean res =
      eglMakeCurrent(egl_display_, surface, surface, egl_resource_context_);
  if (res != EGL_TRUE) {
    FML_LOG(ERROR) << "eglMakeCurrent (resource) failed: " << eglGetError()
                   << " (surface=" << surface
                   << ", context=" << egl_resource_context_ << ")";
    return false;
  }
  return true;
#else
  return true;
#endif
}

bool AndroidSurfaceManager::Present() {
  std::lock_guard<std::mutex> lock(window_mutex_);
#if FML_OS_ANDROID
  if (is_fake_window_) {
    return true;
  }
  if (egl_display_ == EGL_NO_DISPLAY ||
      egl_onscreen_surface_ == EGL_NO_SURFACE) {
    return false;
  }
  EGLBoolean res = eglSwapBuffers(egl_display_, egl_onscreen_surface_);
  if (res != EGL_TRUE) {
    FML_LOG(ERROR) << "eglSwapBuffers failed: " << eglGetError();
    return false;
  }
  return true;
#else
  return true;
#endif
}

uint32_t AndroidSurfaceManager::GetFBO() const {
  return 0;
}

EGLDisplay AndroidSurfaceManager::GetEGLDisplay() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  return egl_display_;
}

EGLContext AndroidSurfaceManager::GetResourceContext() const {
  std::lock_guard<std::mutex> lock(window_mutex_);
  return egl_resource_context_;
}

bool AndroidSurfaceManager::PresentSoftware(const void* allocation,
                                            size_t row_bytes,
                                            size_t height) {
  std::lock_guard<std::mutex> lock(window_mutex_);
  if (is_fake_window_) {
    return true;
  }
  if (native_window_ == nullptr) {
    return false;
  }
#if FML_OS_ANDROID
  ANativeWindow_Buffer buffer;
  if (ANativeWindow_lock(native_window_, &buffer, nullptr) != 0) {
    return false;
  }

  if (buffer.bits == nullptr || buffer.stride <= 0 || buffer.height <= 0) {
    ANativeWindow_unlockAndPost(native_window_);
    return false;
  }

  const uint8_t* src = static_cast<const uint8_t*>(allocation);
  uint8_t* dst = static_cast<uint8_t*>(buffer.bits);
  size_t copy_bytes_per_row =
      std::min(row_bytes, static_cast<size_t>(buffer.stride * 4));
  size_t copy_rows = std::min(height, static_cast<size_t>(buffer.height));

  for (size_t y = 0; y < copy_rows; ++y) {
    std::memcpy(dst + y * buffer.stride * 4, src + y * row_bytes,
                copy_bytes_per_row);
  }

  return ANativeWindow_unlockAndPost(native_window_) == 0;
#else
  return true;
#endif
}

void AndroidSurfaceManager::PopulateGLRendererConfig(
    FlutterOpenGLRendererConfig* config) {
  if (config == nullptr) {
    return;
  }
  config->struct_size = sizeof(FlutterOpenGLRendererConfig);
  config->make_current = [](void* user_data) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)->MakeCurrent();
  };
  config->clear_current = [](void* user_data) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)->ClearCurrent();
  };
  config->present = [](void* user_data) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)->Present();
  };
  config->fbo_callback = [](void* user_data) -> uint32_t {
    return static_cast<AndroidSurfaceManager*>(user_data)->GetFBO();
  };
  config->make_resource_current = [](void* user_data) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)
        ->MakeResourceCurrent();
  };
  config->gl_proc_resolver = [](void*, const char* name) -> void* {
#if FML_OS_ANDROID
    return reinterpret_cast<void*>(eglGetProcAddress(name));
#else
    return nullptr;
#endif
  };
}

void AndroidSurfaceManager::PopulateSoftwareRendererConfig(
    FlutterSoftwareRendererConfig* config) {
  if (config == nullptr) {
    return;
  }
  config->struct_size = sizeof(FlutterSoftwareRendererConfig);
  config->surface_present_callback = [](void* user_data, const void* allocation,
                                        size_t row_bytes,
                                        size_t height) -> bool {
    return static_cast<AndroidSurfaceManager*>(user_data)->PresentSoftware(
        allocation, row_bytes, height);
  };
}

}  // namespace flutter
