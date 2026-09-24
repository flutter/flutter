// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/platform/android/android_surface_manager.h"

#include <dlfcn.h>
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
  DestroyOverlaySurfaces();
#if FML_OS_ANDROID
  if (egl_display_ != EGL_NO_DISPLAY &&
      egl_onscreen_context_ != EGL_NO_CONTEXT) {
    EGLSurface prev_draw = eglGetCurrentSurface(EGL_DRAW);
    EGLSurface prev_read = eglGetCurrentSurface(EGL_READ);
    EGLSurface pbuf = (egl_onscreen_pbuffer_surface_ != EGL_NO_SURFACE)
                          ? egl_onscreen_pbuffer_surface_
                          : EGL_NO_SURFACE;
    eglMakeCurrent(egl_display_, pbuf, pbuf, egl_onscreen_context_);
    std::lock_guard<std::mutex> lock(offscreen_fbo_mutex_);
    for (const auto& entry : offscreen_fbo_pool_) {
      if (entry.texture != 0) {
        GLuint tex = entry.texture;
        glDeleteTextures(1, &tex);
      }
      if (entry.fbo != 0) {
        GLuint fbo = entry.fbo;
        glDeleteFramebuffers(1, &fbo);
      }
    }
    offscreen_fbo_pool_.clear();
    eglMakeCurrent(egl_display_, prev_draw, prev_read, egl_onscreen_context_);
  }
#endif
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
    EGLint err = eglGetError();
    int32_t width = ANativeWindow_getWidth(native_window_);
    int32_t height = ANativeWindow_getHeight(native_window_);
    int32_t format = ANativeWindow_getFormat(native_window_);
    FML_LOG(ERROR) << "eglCreateWindowSurface failed: " << err
                   << " window=" << native_window_ << " w=" << width
                   << " h=" << height << " fmt=" << format
                   << " egl_display=" << egl_display_
                   << " egl_config=" << egl_config_;
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
    void* proc = reinterpret_cast<void*>(eglGetProcAddress(name));
    if (!proc) {
      proc = dlsym(RTLD_DEFAULT, name);
    }
    return proc;
#else
    return dlsym(RTLD_DEFAULT, name);
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

AndroidSurfaceManager::OffscreenFBO AndroidSurfaceManager::AcquireOffscreenFBO(
    size_t width,
    size_t height) {
  std::lock_guard<std::mutex> lock(offscreen_fbo_mutex_);
  for (auto it = offscreen_fbo_pool_.begin(); it != offscreen_fbo_pool_.end();
       ++it) {
    if (it->width == width && it->height == height) {
      OffscreenFBO result = *it;
      offscreen_fbo_pool_.erase(it);
      return result;
    }
  }

  OffscreenFBO result;
  result.width = width;
  result.height = height;
#if FML_OS_ANDROID
  GLuint fbo = 0;
  GLuint texture = 0;
  if (eglGetCurrentContext() != EGL_NO_CONTEXT) {
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);

    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, nullptr);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           texture, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
  }
  if (fbo == 0) {
    static uint32_t s_mock_fbo_counter = 1000;
    fbo = ++s_mock_fbo_counter;
    texture = ++s_mock_fbo_counter;
  }
  result.fbo = fbo;
  result.texture = texture;
#else
  static uint32_t s_mock_fbo_counter = 1000;
  result.fbo = ++s_mock_fbo_counter;
  result.texture = ++s_mock_fbo_counter;
#endif
  return result;
}

void AndroidSurfaceManager::ReleaseOffscreenFBO(const OffscreenFBO& fbo) {
  std::lock_guard<std::mutex> lock(offscreen_fbo_mutex_);
  offscreen_fbo_pool_.push_back(fbo);
}

bool AndroidSurfaceManager::BlitAndSwapOverlaySurface(
    ANativeWindow* overlay_window,
    uint32_t offscreen_fbo,
    size_t width,
    size_t height) {
#if FML_OS_ANDROID
  if (!overlay_window) {
    return true;
  }
  if (egl_display_ == EGL_NO_DISPLAY ||
      egl_onscreen_context_ == EGL_NO_CONTEXT) {
    return false;
  }
  EGLSurface overlay_surface = EGL_NO_SURFACE;
  {
    std::lock_guard<std::mutex> lock(overlay_surfaces_mutex_);
    auto it = overlay_egl_surfaces_.find(overlay_window);
    if (it != overlay_egl_surfaces_.end()) {
      overlay_surface = it->second;
    } else {
      overlay_surface = eglCreateWindowSurface(egl_display_, egl_config_,
                                               overlay_window, nullptr);
      if (overlay_surface == EGL_NO_SURFACE) {
        FML_LOG(ERROR) << "eglCreateWindowSurface for overlay failed: "
                       << eglGetError();
        return false;
      }
      overlay_egl_surfaces_[overlay_window] = overlay_surface;
    }
  }

  EGLSurface prev_draw = eglGetCurrentSurface(EGL_DRAW);
  EGLSurface prev_read = eglGetCurrentSurface(EGL_READ);

  if (!eglMakeCurrent(egl_display_, overlay_surface, overlay_surface,
                      egl_onscreen_context_)) {
    FML_LOG(ERROR) << "eglMakeCurrent on overlay surface failed: "
                   << eglGetError();
    return false;
  }

  typedef void (*PFNGLBLITFRAMEBUFFERPROC)(
      GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0,
      GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
  static PFNGLBLITFRAMEBUFFERPROC glBlitFramebuffer_fn = []() {
    PFNGLBLITFRAMEBUFFERPROC fn = nullptr;

    // 1. Attempt lookup in libGLESv3.so directly.
    void* gles3_handle = dlopen("libGLESv3.so", RTLD_NOW | RTLD_LOCAL);
    if (gles3_handle) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          dlsym(gles3_handle, "glBlitFramebuffer"));
    }

    // 2. Fall back to libGLESv2.so (some Android devices ship unified GLES).
    if (!fn) {
      void* gles2_handle = dlopen("libGLESv2.so", RTLD_NOW | RTLD_LOCAL);
      if (gles2_handle) {
        fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
            dlsym(gles2_handle, "glBlitFramebuffer"));
      }
    }

    // 3. Fall back to RTLD_DEFAULT.
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          dlsym(RTLD_DEFAULT, "glBlitFramebuffer"));
    }

    // 4. Fall back to eglGetProcAddress core symbol.
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          eglGetProcAddress("glBlitFramebuffer"));
    }

    // 5. Fall back to vendor extensions.
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          eglGetProcAddress("glBlitFramebufferEXT"));
    }
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          eglGetProcAddress("glBlitFramebufferANGLE"));
    }
    if (!fn) {
      fn = reinterpret_cast<PFNGLBLITFRAMEBUFFERPROC>(
          eglGetProcAddress("glBlitFramebufferNV"));
    }
    return fn;
  }();

  if (glBlitFramebuffer_fn) {
    // GL_READ_FRAMEBUFFER = 0x8CA8
    constexpr GLenum kGLReadFramebuffer = 0x8CA8;
    // GL_DRAW_FRAMEBUFFER = 0x8CA9
    constexpr GLenum kGLDrawFramebuffer = 0x8CA9;
    glBindFramebuffer(kGLReadFramebuffer, offscreen_fbo);
    glBindFramebuffer(kGLDrawFramebuffer, 0);
    glBlitFramebuffer_fn(0, 0, width, height, 0, 0, width, height,
                         GL_COLOR_BUFFER_BIT, GL_NEAREST);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
  } else {
    FML_LOG(ERROR)
        << "glBlitFramebuffer could not be resolved; skipping overlay blit.";
    eglMakeCurrent(egl_display_, prev_draw, prev_read, egl_onscreen_context_);
    return false;
  }

  EGLBoolean swapped = eglSwapBuffers(egl_display_, overlay_surface);
  if (!swapped) {
    FML_LOG(ERROR) << "eglSwapBuffers on overlay surface failed: "
                   << eglGetError();
  }

  eglMakeCurrent(egl_display_, prev_draw, prev_read, egl_onscreen_context_);
  return swapped == EGL_TRUE;
#else
  (void)overlay_window;
  (void)offscreen_fbo;
  (void)width;
  (void)height;
  return true;
#endif
}

void AndroidSurfaceManager::DestroyOverlaySurfaces() {
#if FML_OS_ANDROID
  std::lock_guard<std::mutex> lock(overlay_surfaces_mutex_);
  if (egl_display_ != EGL_NO_DISPLAY) {
    for (auto& [window, surface] : overlay_egl_surfaces_) {
      if (surface != EGL_NO_SURFACE) {
        if (eglGetCurrentSurface(EGL_DRAW) == surface ||
            eglGetCurrentSurface(EGL_READ) == surface) {
          eglMakeCurrent(egl_display_, EGL_NO_SURFACE, EGL_NO_SURFACE,
                         EGL_NO_CONTEXT);
        }
        eglDestroySurface(egl_display_, surface);
      }
    }
  }
  overlay_egl_surfaces_.clear();
#endif
}

}  // namespace flutter
