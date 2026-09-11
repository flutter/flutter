// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_EGL_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_EGL_MANAGER_H_

#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <android/native_window.h>

#include <mutex>

#include "flutter/fml/macros.h"

namespace flutter {
namespace android {

/// @brief Manages EGL display, contexts, and surfaces for Android OpenGL ES
/// rendering within the public Embedder API boundary.
class AndroidEGLManager {
 public:
  AndroidEGLManager();
  ~AndroidEGLManager();

  /// @brief Initializes EGL display, configs, contexts, and offscreen pbuffer.
  /// @return True if EGL initialization succeeded.
  bool Initialize();

  /// @brief Checks whether EGL is initialized and valid.
  bool IsValid() const;

  /// @brief Updates the native window handle for onscreen presentation.
  /// @param window The ANativeWindow pointer (can be nullptr to detach).
  void SetNativeWindow(ANativeWindow* window);

  /// @brief Binds the render context to the calling thread.
  /// @return True if the context was successfully made current.
  bool MakeCurrent();

  /// @brief Clears the current EGL context from the calling thread.
  /// @return True if the context was successfully cleared.
  bool ClearCurrent();

  /// @brief Binds the offscreen resource context for async texture/shader work.
  /// @return True if the resource context was successfully made current.
  bool MakeResourceCurrent();

  /// @brief Swaps display buffers for onscreen rendering.
  /// @return True if presentation succeeded.
  bool Present();

  /// @brief Returns the underlying EGLDisplay handle.
  EGLDisplay GetDisplay() const;

  /// @brief Returns the underlying EGLContext handle for the render context.
  EGLContext GetContext() const;

  /// @brief Returns the underlying EGLContext handle for the resource context.
  EGLContext GetResourceContext() const;

 private:
  bool ChooseConfigLocked();
  bool CreateContextsLocked();
  bool CreatePbufferSurfacesLocked();

  mutable std::mutex mutex_;
  bool is_valid_ = false;

  EGLDisplay display_ = EGL_NO_DISPLAY;
  EGLConfig config_ = nullptr;
  EGLContext render_context_ = EGL_NO_CONTEXT;
  EGLContext resource_context_ = EGL_NO_CONTEXT;

  // Separate pbuffer surfaces ensure the render context and resource loading
  // context never attempt to bind the same surface simultaneously, which
  // would violate EGL 1.4 section 3.7.3 and cause EGL_BAD_ACCESS (12290).
  EGLSurface render_pbuffer_surface_ = EGL_NO_SURFACE;
  EGLSurface resource_pbuffer_surface_ = EGL_NO_SURFACE;
  EGLSurface window_surface_ = EGL_NO_SURFACE;

  ANativeWindow* pending_window_ = nullptr;
  ANativeWindow* current_window_ = nullptr;
  bool window_changed_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidEGLManager);
};

}  // namespace android
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_EGL_MANAGER_H_
