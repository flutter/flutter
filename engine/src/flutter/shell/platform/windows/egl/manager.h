// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_EGL_MANAGER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_EGL_MANAGER_H_

// OpenGL ES and EGL includes
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <EGL/eglplatform.h>
#include <GLES2/gl2.h>
#include <GLES2/gl2ext.h>

// Windows platform specific includes
#include <d3d11.h>
#include <dxgi.h>
#include <dxgi1_6.h>
#include <windows.h>
#include <wrl/client.h>
#include <memory>
#include <optional>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/egl/context.h"
#include "flutter/shell/platform/windows/egl/surface.h"
#include "flutter/shell/platform/windows/egl/window_surface.h"

namespace flutter {
namespace egl {

enum class GpuPreference {
  NoPreference,
  LowPowerPreference,
  HighPerformancePreference,
};

// A manager for initializing ANGLE correctly and using it to create and
// destroy surfaces
class Manager {
 public:
  // Creates a manager.
  //
  // If |allow_inverted_surface| is true and ANGLE supports
  // EGL_ANGLE_surface_orientation, window surfaces are created with an
  // inverted Y axis so that the default framebuffer shares Impeller's
  // top-left origin. See |surface_origin_is_top_left|.
  static std::unique_ptr<Manager> Create(GpuPreference gpu_preference,
                                         bool allow_inverted_surface);

  virtual ~Manager();

  // Whether the manager is currently valid.
  bool IsValid() const;

  // Creates an EGL surface that can be used to render a Flutter view into a
  // win32 HWND.
  //
  // After the surface is created, |WindowSurface::SetVSyncEnabled| should be
  // called on a thread that can make the surface current.
  //
  // HWND is the window backing the surface. Width and height are the surface's
  // physical pixel dimensions.
  //
  // Returns nullptr on failure.
  virtual std::unique_ptr<WindowSurface> CreateWindowSurface(HWND hwnd,
                                                             size_t width,
                                                             size_t height);

  // Check if the current thread has a context bound.
  bool HasContextCurrent();

  // Creates a |EGLSurface| from the provided handle.
  EGLSurface CreateSurfaceFromHandle(EGLenum handle_type,
                                     EGLClientBuffer handle,
                                     const EGLint* attributes) const;

  // Gets the |EGLDisplay|.
  EGLDisplay egl_display() const { return display_; };

  // Gets the |EGLConfig|.
  EGLConfig egl_config() const { return config_; };

  // Whether the origin of the default framebuffer (framebuffer 0) is the
  // top-left of the window rather than OpenGL's usual bottom-left.
  //
  // This is true when window surfaces were created with
  // EGL_SURFACE_ORIENTATION_INVERT_Y_ANGLE. Content blitted or drawn into the
  // default framebuffer must be stored top-down in that case.
  virtual bool surface_origin_is_top_left() const;

  // Gets the |ID3D11Device| chosen by ANGLE.
  bool GetDevice(ID3D11Device** device);

  // Get the EGL context used to render Flutter views.
  virtual Context* render_context() const;

  // Get the EGL context used for async texture uploads.
  virtual Context* resource_context() const;

  static std::optional<LUID> GetLowPowerGpuLuid();

  static std::optional<LUID> GetHighPerformanceGpuLuid();

 protected:
  // Creates a new surface manager retaining reference to the passed-in target
  // for the lifetime of the manager.
  Manager(GpuPreference gpu_preference, bool allow_inverted_surface);

 private:
  // Number of active instances of Manager
  static int instance_count_;

  // Helper function to get GPU LUID by preference.
  static std::optional<LUID> GetGpuLuidByPreference(
      DXGI_GPU_PREFERENCE preference);

  // Initialize the EGL display.
  bool InitializeDisplay(GpuPreference gpu_preference,
                         bool allow_inverted_surface);

  // Initialize the EGL configs.
  bool InitializeConfig();

  // Initialize the EGL render and resource contexts.
  bool InitializeContexts();

  // Initialize the D3D11 device.
  bool InitializeDevice();

  void CleanUp();

  // Whether the manager was initialized successfully.
  bool is_valid_ = false;

  // The EGL_SURFACE_ORIENTATION_ANGLE value to create window surfaces with.
  //
  // Either 0 or EGL_SURFACE_ORIENTATION_INVERT_Y_ANGLE. Non-zero only when the
  // caller opted in and ANGLE advertised EGL_ANGLE_surface_orientation.
  EGLint surface_orientation_ = 0;

  // EGL representation of native display.
  EGLDisplay display_ = EGL_NO_DISPLAY;

  // EGL framebuffer configuration.
  EGLConfig config_ = nullptr;

  // The EGL context used to render Flutter views.
  std::unique_ptr<Context> render_context_;

  // The EGL context used for async texture uploads.
  std::unique_ptr<Context> resource_context_;

  // The current D3D device.
  Microsoft::WRL::ComPtr<ID3D11Device> resolved_device_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(Manager);
};

}  // namespace egl
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_EGL_MANAGER_H_
