// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_SURFACE_GLX_H_
#define UI_GL_GL_SURFACE_GLX_H_

#include <string>

#include "base/compiler_specific.h"
#include "ui/events/platform/platform_event_dispatcher.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gfx/native_widget_types.h"
#include "ui/gfx/vsync_provider.h"
#include "ui/gfx/x/x11_types.h"
#include "ui/gl/gl_export.h"
#include "ui/gl/gl_surface.h"

namespace gfx {

// Base class for GLX surfaces.
class GL_EXPORT GLSurfaceGLX : public GLSurface {
 public:
  explicit GLSurfaceGLX(
    const gfx::SurfaceConfiguration& requested_configuration);

  static bool InitializeOneOff();

  // These aren't particularly tied to surfaces, but since we already
  // have the static InitializeOneOff here, it's easiest to reuse its
  // initialization guards.
  static const char* GetGLXExtensions();
  static bool HasGLXExtension(const char* name);
  static bool IsCreateContextSupported();
  static bool IsCreateContextRobustnessSupported();
  static bool IsTextureFromPixmapSupported();
  static bool IsOMLSyncControlSupported();

  void* GetDisplay() override;

  // Get the FB config that the surface was created with or NULL if it is not
  // a GLX drawable.
  void* GetConfig() override = 0;

 protected:
  ~GLSurfaceGLX() override;

 private:
  DISALLOW_COPY_AND_ASSIGN(GLSurfaceGLX);
};

// A surface used to render to a view.
class GL_EXPORT NativeViewGLSurfaceGLX : public GLSurfaceGLX,
                                         public ui::PlatformEventDispatcher {
 public:
  NativeViewGLSurfaceGLX(
    gfx::AcceleratedWidget window,
    const gfx::SurfaceConfiguration& requested_configuration);

  // Implement GLSurfaceGLX.
  bool Initialize() override;
  void Destroy() override;
  bool Resize(const gfx::Size& size) override;
  bool IsOffscreen() override;
  bool SwapBuffers() override;
  gfx::Size GetSize() override;
  void* GetHandle() override;
  bool SupportsPostSubBuffer() override;
  void* GetConfig() override;
  bool PostSubBuffer(int x, int y, int width, int height) override;
  VSyncProvider* GetVSyncProvider() override;

 protected:
  ~NativeViewGLSurfaceGLX() override;

 private:
  // The handle for the drawable to make current or swap.
  gfx::AcceleratedWidget GetDrawableHandle() const;

  // PlatformEventDispatcher implementation
  bool CanDispatchEvent(const ui::PlatformEvent& event) override;
  uint32_t DispatchEvent(const ui::PlatformEvent& event) override;

  // Window passed in at creation. Always valid.
  gfx::AcceleratedWidget parent_window_;

  // Child window, used to control resizes so that they're in-order with GL.
  gfx::AcceleratedWidget window_;

  void* config_;
  gfx::Size size_;

  scoped_ptr<VSyncProvider> vsync_provider_;

  DISALLOW_COPY_AND_ASSIGN(NativeViewGLSurfaceGLX);
};

// A surface used to render to an offscreen pbuffer.
class GL_EXPORT PbufferGLSurfaceGLX : public GLSurfaceGLX {
 public:
  PbufferGLSurfaceGLX(
    const gfx::Size& size,
    const gfx::SurfaceConfiguration& requested_configuration);

  // Implement GLSurfaceGLX.
  bool Initialize() override;
  void Destroy() override;
  bool IsOffscreen() override;
  bool SwapBuffers() override;
  gfx::Size GetSize() override;
  void* GetHandle() override;
  void* GetConfig() override;

 protected:
  ~PbufferGLSurfaceGLX() override;

 private:
  gfx::Size size_;
  void* config_;
  XID pbuffer_;

  DISALLOW_COPY_AND_ASSIGN(PbufferGLSurfaceGLX);
};

}  // namespace gfx

#endif  // UI_GL_GL_SURFACE_GLX_H_
