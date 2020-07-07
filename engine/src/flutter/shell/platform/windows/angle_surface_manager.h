// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_ANGLE_SURFACE_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_ANGLE_SURFACE_MANAGER_H_

// OpenGL ES and EGL includes
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglplatform.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

// Windows platform specific includes
#include <windows.h>

#include "window_binding_handler.h"

namespace flutter {

// A manager for inializing ANGLE correctly and using it to create and
// destroy surfaces
class AngleSurfaceManager {
 public:
  AngleSurfaceManager();
  ~AngleSurfaceManager();

  // Disallow copy/move.
  AngleSurfaceManager(const AngleSurfaceManager&) = delete;
  AngleSurfaceManager& operator=(const AngleSurfaceManager&) = delete;

  // Creates an EGLSurface wrapper and backing DirectX 11 SwapChain
  // asociated with window, in the appropriate format for display.
  // Target represents the visual entity to bind to.
  bool CreateSurface(WindowsRenderTarget* render_target);

  // queries EGL for the dimensions of surface in physical
  // pixels returning width and height as out params.
  void GetSurfaceDimensions(EGLint* width, EGLint* height);

  // Releases the pass-in EGLSurface wrapping and backing resources if not null.
  void DestroySurface();

  // Binds egl_context_ to the current rendering thread and to the draw and read
  // surfaces returning a boolean result reflecting success.
  bool MakeCurrent();

  // Clears current egl_context_
  bool ClearContext();

  // Binds egl_resource_context_ to the current rendering thread and to the draw
  // and read surfaces returning a boolean result reflecting success.
  bool MakeResourceCurrent();

  // Swaps the front and back buffers of the DX11 swapchain backing surface if
  // not null.
  EGLBoolean SwapBuffers();

 private:
  bool Initialize();
  void CleanUp();

 private:
  // EGL representation of native display.
  EGLDisplay egl_display_;

  // EGL representation of current rendering context.
  EGLContext egl_context_;

  // EGL representation of current rendering context used for async texture
  // uploads.
  EGLContext egl_resource_context_;

  // current frame buffer configuration.
  EGLConfig egl_config_;

  // State representing success or failure of display initialization used when
  // creating surfaces.
  bool initialize_succeeded_;

  // Current render_surface that engine will draw into.
  EGLSurface render_surface_ = EGL_NO_SURFACE;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_ANGLE_SURFACE_MANAGER_H_
