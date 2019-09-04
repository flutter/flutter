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

namespace flutter {

// An manager for inializing ANGLE correctly and using it to create and
// destroy surfaces
class AngleSurfaceManager {
 public:
  AngleSurfaceManager();
  ~AngleSurfaceManager();

  // Disallow copy/move.
  AngleSurfaceManager(const AngleSurfaceManager&) = delete;
  AngleSurfaceManager& operator=(const AngleSurfaceManager&) = delete;

  // Creates and returns an EGLSurface wrapper and backing DirectX 11 SwapChain
  // asociated with window, in the appropriate format for display in a
  // HWND-backed window.
  EGLSurface CreateSurface(HWND window);

  // queries EGL for the dimensions of surface in physical
  // pixels returning width and height as out params.
  void GetSurfaceDimensions(const EGLSurface surface,
                            EGLint* width,
                            EGLint* height);

  // Releases the pass-in EGLSurface wrapping and backing resources if not null.
  void DestroySurface(const EGLSurface surface);

  // Binds egl_context_ to the current rendering thread and to the draw and read
  // surfaces returning a boolean result reflecting success.
  bool MakeCurrent(const EGLSurface surface);

  // Binds egl_resource_context_ to the current rendering thread and to the draw
  // and read surfaces returning a boolean result reflecting success.
  bool MakeResourceCurrent();

  // Swaps the front and back buffers of the DX11 swapchain backing surface if
  // not null.
  EGLBoolean SwapBuffers(const EGLSurface surface);

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
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_ANGLE_SURFACE_MANAGER_H_
