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
#include <windows.h>
#include <wrl/client.h>
#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/platform/windows/egl/context.h"
#include "flutter/shell/platform/windows/egl/surface.h"
#include "flutter/shell/platform/windows/egl/window_surface.h"

namespace flutter {
namespace egl {

// A manager for initializing ANGLE correctly and using it to create and
// destroy surfaces
class Manager {
 public:
  static std::unique_ptr<Manager> Create(bool enable_impeller);

  virtual ~Manager();

  // Whether the manager is currently valid.
  bool IsValid() const;

  // Creates an EGLSurface wrapper and backing DirectX 11 SwapChain
  // associated with window, in the appropriate format for display.
  // HWND is the window backing the surface. Width and height represent
  // dimensions surface is created at.
  //
  // After the surface is created, |SetVSyncEnabled| should be called on a
  // thread that can bind the |render_context_|.
  virtual bool CreateWindowSurface(HWND hwnd, size_t width, size_t height);

  // Resizes backing surface from current size to newly requested size
  // based on width and height for the specific case when width and height do
  // not match current surface dimensions. HWND is the window backing the
  // surface.
  //
  // This binds |render_context_| to the current thread.
  virtual void ResizeWindowSurface(HWND hwnd, size_t width, size_t height);

  // Check if the current thread has a context bound.
  bool HasContextCurrent();

  // Creates a |EGLSurface| from the provided handle.
  EGLSurface CreateSurfaceFromHandle(EGLenum handle_type,
                                     EGLClientBuffer handle,
                                     const EGLint* attributes) const;

  // Gets the |EGLDisplay|.
  EGLDisplay egl_display() const { return display_; };

  // Gets the |ID3D11Device| chosen by ANGLE.
  bool GetDevice(ID3D11Device** device);

  // Get the EGL context used to render Flutter views.
  virtual Context* render_context() const;

  // Get the EGL context used for async texture uploads.
  virtual Context* resource_context() const;

  // Get the EGL surface that backs the Flutter view.
  virtual WindowSurface* surface() const;

 protected:
  // Creates a new surface manager retaining reference to the passed-in target
  // for the lifetime of the manager.
  explicit Manager(bool enable_impeller);

 private:
  // Number of active instances of Manager
  static int instance_count_;

  // Initialize the EGL display.
  bool InitializeDisplay();

  // Initialize the EGL configs.
  bool InitializeConfig(bool enable_impeller);

  // Initialize the EGL render and resource contexts.
  bool InitializeContexts();

  // Initialize the D3D11 device.
  bool InitializeDevice();

  void CleanUp();

  // Whether the manager was initialized successfully.
  bool is_valid_ = false;

  // EGL representation of native display.
  EGLDisplay display_ = EGL_NO_DISPLAY;

  // EGL framebuffer configuration.
  EGLConfig config_ = nullptr;

  // The EGL context used to render Flutter views.
  std::unique_ptr<Context> render_context_;

  // The EGL context used for async texture uploads.
  std::unique_ptr<Context> resource_context_;

  // Th EGL surface used to render into the Flutter view.
  std::unique_ptr<WindowSurface> surface_;

  // The current D3D device.
  Microsoft::WRL::ComPtr<ID3D11Device> resolved_device_ = nullptr;

  FML_DISALLOW_COPY_AND_ASSIGN(Manager);
};

}  // namespace egl
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_EGL_MANAGER_H_
