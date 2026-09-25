// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_MANAGER_H_

#include <memory>
#include <mutex>
#include <optional>
#include <string>

#include "flutter/fml/build_config.h"
#include "flutter/fml/macros.h"
#include "flutter/shell/platform/android/android_rendering_selector.h"
#include "flutter/shell/platform/embedder/embedder.h"

#if FML_OS_ANDROID
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>
#include <android/native_window.h>
#else
// Stubs and type aliases for host unit testing
typedef void* EGLDisplay;
typedef void* EGLConfig;
typedef void* EGLContext;
typedef void* EGLSurface;
typedef int32_t EGLint;
typedef void ANativeWindow;
#ifndef EGL_NO_DISPLAY
#define EGL_NO_DISPLAY ((EGLDisplay)0)
#endif
#ifndef EGL_NO_CONTEXT
#define EGL_NO_CONTEXT ((EGLContext)0)
#endif
#ifndef EGL_NO_SURFACE
#define EGL_NO_SURFACE ((EGLSurface)0)
#endif
#ifndef EGL_DEFAULT_DISPLAY
#define EGL_DEFAULT_DISPLAY ((EGLDisplay)0)
#endif
#endif  // FML_OS_ANDROID

namespace flutter {

struct AndroidSurfaceDimensions {
  int32_t width = 0;
  int32_t height = 0;
};

/// @brief Manages platform window and graphics rendering contexts (EGL, Vulkan,
///        Software) for the Flutter Android Embedder, handling thread-safe
///        lifecycle, resource context pooling, and surface presentation.
class AndroidSurfaceManager {
 public:
  /// Creates a new surface manager configured for the specified rendering API.
  static std::unique_ptr<AndroidSurfaceManager> Create(
      AndroidRenderingAPI rendering_api);

  explicit AndroidSurfaceManager(AndroidRenderingAPI rendering_api);
  virtual ~AndroidSurfaceManager();

  AndroidRenderingAPI GetRenderingAPI() const { return rendering_api_; }

  /// Returns true if graphics subsystem was initialized successfully.
  bool IsValid() const;

  /// Associates the manager with a native window (e.g. from SurfaceView /
  /// SurfaceTexture). Thread-safe.
  bool SetNativeWindow(ANativeWindow* window, bool is_fake_window = false);

  /// Detaches and releases the native window reference. Thread-safe.
  void ClearNativeWindow();

  /// Returns current native window pointer. Thread-safe.
  ANativeWindow* GetNativeWindow() const;

  /// Returns dimensions of currently attached native window.
  AndroidSurfaceDimensions GetNativeWindowSize() const;

  /// Returns true if this manager is backed by a fake window (in unit testing).
  bool IsFakeWindow() const;

  // ---------------------------------------------------------------------------
  // OpenGL ES / EGL Lifecycle Methods
  // ---------------------------------------------------------------------------

  /// Makes the onscreen EGL context and surface current on the calling thread.
  bool MakeCurrent();

  /// Clears the current EGL context and surface on the calling thread.
  bool ClearCurrent();

  /// Makes the offscreen/resource EGL context current on the calling thread.
  bool MakeResourceCurrent();

  /// Swaps buffers on the onscreen surface.
  bool Present();

  /// Returns the current FBO (typically 0 for onscreen window surfaces).
  uint32_t GetFBO() const;

  /// Returns the EGLDisplay handle.
  EGLDisplay GetEGLDisplay() const;

  /// Returns the resource EGLContext handle.
  EGLContext GetResourceContext() const;

  // ---------------------------------------------------------------------------
  // Software Surface Lifecycle Methods
  // ---------------------------------------------------------------------------

  /// Presents a software-rendered pixel buffer to the native window.
  bool PresentSoftware(const void* allocation, size_t row_bytes, size_t height);

  // ---------------------------------------------------------------------------
  // Embedder C-API Configuration Helpers
  // ---------------------------------------------------------------------------

  /// Populates OpenGL renderer config for
  /// FlutterEngineInitialize/FlutterEngineRun.
  void PopulateGLRendererConfig(FlutterOpenGLRendererConfig* config);

  /// Populates Software renderer config for
  /// FlutterEngineInitialize/FlutterEngineRun.
  void PopulateSoftwareRendererConfig(FlutterSoftwareRendererConfig* config);

 private:
  const AndroidRenderingAPI rendering_api_;
  mutable std::mutex window_mutex_;
  ANativeWindow* native_window_ = nullptr;
  bool is_fake_window_ = false;
  bool is_valid_ = false;

  // EGL state
  EGLDisplay egl_display_ = EGL_NO_DISPLAY;
  EGLConfig egl_config_ = nullptr;
  EGLContext egl_onscreen_context_ = EGL_NO_CONTEXT;
  EGLContext egl_resource_context_ = EGL_NO_CONTEXT;
  EGLSurface egl_onscreen_surface_ = EGL_NO_SURFACE;
  EGLSurface egl_onscreen_pbuffer_surface_ = EGL_NO_SURFACE;
  EGLSurface egl_resource_pbuffer_surface_ = EGL_NO_SURFACE;
  bool has_surfaceless_context_ = false;

  bool InitializeEGL();
  void TeardownEGL();
  bool CreateOrUpdateOnscreenSurfaceLocked();
  void DestroyOnscreenSurfaceLocked();

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceManager);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_MANAGER_H_
