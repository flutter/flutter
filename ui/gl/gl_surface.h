// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_SURFACE_H_
#define UI_GL_GL_SURFACE_H_

#include <string>

#include "base/callback.h"
#include "base/memory/ref_counted.h"
#include "build/build_config.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/geometry/rect_f.h"
#include "ui/gfx/geometry/size.h"
#include "ui/gfx/native_widget_types.h"
#include "ui/gfx/overlay_transform.h"
#include "ui/gl/gl_export.h"
#include "ui/gl/gl_implementation.h"

namespace gfx {

class GLContext;
class GLImage;
class VSyncProvider;

struct SurfaceConfiguration {
  uint8_t red_bits = 8;
  uint8_t green_bits = 8;
  uint8_t blue_bits = 8;
  uint8_t alpha_bits = 8;
  uint8_t depth_bits = 0;
  uint8_t stencil_bits = 0;
};

// Encapsulates a surface that can be rendered to with GL, hiding platform
// specific management.
class GL_EXPORT GLSurface : public base::RefCounted<GLSurface> {
 public:
  explicit GLSurface(const gfx::SurfaceConfiguration requested_configuration);

  // (Re)create the surface. TODO(apatrick): This is an ugly hack to allow the
  // EGL surface associated to be recreated without destroying the associated
  // context. The implementation of this function for other GLSurface derived
  // classes is in a pending changelist.
  virtual bool Initialize();

  // Destroys the surface.
  virtual void Destroy() = 0;

  // Destroys the surface and terminates its underlying display. This must be
  // the last surface which uses the display.
  virtual void DestroyAndTerminateDisplay();

  virtual bool Resize(const gfx::Size& size);

  // Recreate the surface without changing the size.
  virtual bool Recreate();

  // Unschedule the GpuScheduler and return true to abort the processing of
  // a GL draw call to this surface and defer it until the GpuScheduler is
  // rescheduled.
  virtual bool DeferDraws();

  // Returns true if this surface is offscreen.
  virtual bool IsOffscreen() = 0;

  // Swaps front and back buffers. This has no effect for off-screen
  // contexts.
  virtual bool SwapBuffers() = 0;

  // Get the size of the surface.
  virtual gfx::Size GetSize() = 0;

  // Get the underlying platform specific surface "handle".
  virtual void* GetHandle() = 0;

  // Returns whether or not the surface supports PostSubBuffer.
  virtual bool SupportsPostSubBuffer();

  // Returns the internal frame buffer object name if the surface is backed by
  // FBO. Otherwise returns 0.
  virtual unsigned int GetBackingFrameBufferObject();

  typedef base::Callback<void()> SwapCompletionCallback;
  // Swaps front and back buffers. This has no effect for off-screen
  // contexts. On some platforms, we want to send SwapBufferAck only after the
  // surface is displayed on screen. The callback can be used to delay sending
  // SwapBufferAck till that data is available. The callback should be run on
  // the calling thread (i.e. same thread SwapBuffersAsync is called)
  virtual bool SwapBuffersAsync(const SwapCompletionCallback& callback);

  // Copy part of the backbuffer to the frontbuffer.
  virtual bool PostSubBuffer(int x, int y, int width, int height);

  // Copy part of the backbuffer to the frontbuffer. On some platforms, we want
  // to send SwapBufferAck only after the surface is displayed on screen. The
  // callback can be used to delay sending SwapBufferAck till that data is
  // available. The callback should be run on the calling thread (i.e. same
  // thread PostSubBufferAsync is called)
  virtual bool PostSubBufferAsync(int x,
                                  int y,
                                  int width,
                                  int height,
                                  const SwapCompletionCallback& callback);

  // Initialize GL bindings.
  static bool InitializeOneOff(GLImplementation = kGLImplementationNone);

  // Unit tests should call these instead of InitializeOneOff() to set up
  // GL bindings appropriate for tests.
  static void InitializeOneOffForTests();
  static void InitializeOneOffWithMockBindingsForTests();
  static void InitializeDynamicMockBindingsForTests(GLContext* context);

  // Called after a context is made current with this surface. Returns false
  // on error.
  virtual bool OnMakeCurrent(GLContext* context);

  // Called when the surface is bound as the current framebuffer for the
  // current context.
  virtual void NotifyWasBound();

  // Used for explicit buffer management.
  virtual bool SetBackbufferAllocation(bool allocated);
  virtual void SetFrontbufferAllocation(bool allocated);

  // Get a handle used to share the surface with another process. Returns null
  // if this is not possible.
  virtual void* GetShareHandle();

  // Get the platform specific display on which this surface resides, if
  // available.
  virtual void* GetDisplay();

  // Get the platfrom specific configuration for this surface, if available.
  virtual void* GetConfig();

  // Get the GL pixel format of the surface, if available.
  virtual unsigned GetFormat();

  // Get access to a helper providing time of recent refresh and period
  // of screen refresh. If unavailable, returns NULL.
  virtual VSyncProvider* GetVSyncProvider();

  // Schedule an overlay plane to be shown at swap time.
  // |z_order| specifies the stacking order of the plane relative to the
  // main framebuffer located at index 0. For the case where there is no
  // main framebuffer, overlays may be scheduled at 0, taking its place.
  // |transform| specifies how the buffer is to be transformed during
  // composition.
  // |image| to be presented by the overlay.
  // |bounds_rect| specify where it is supposed to be on the screen in pixels.
  // |crop_rect| specifies the region within the buffer to be placed inside
  // |bounds_rect|.
  virtual bool ScheduleOverlayPlane(int z_order,
                                    OverlayTransform transform,
                                    GLImage* image,
                                    const Rect& bounds_rect,
                                    const RectF& crop_rect);

  virtual bool IsSurfaceless() const;

  // Create a GL surface that renders directly to a view.
  static scoped_refptr<GLSurface> CreateViewGLSurface(
      gfx::AcceleratedWidget window,
      const gfx::SurfaceConfiguration& requested_configuration);

#if defined(USE_OZONE)
  // Create a GL surface that renders directly into a window with surfaceless
  // semantics - there is no default framebuffer and the primary surface must
  // be presented as an overlay. If surfaceless mode is not supported or
  // enabled it will return a null pointer.
  static scoped_refptr<GLSurface> CreateSurfacelessViewGLSurface(
      gfx::AcceleratedWidget window,
      const gfx::SurfaceConfiguration& requested_configuration);
#endif  // defined(USE_OZONE)

  // Create a GL surface used for offscreen rendering.
  static scoped_refptr<GLSurface> CreateOffscreenGLSurface(
      const gfx::Size& size,
      const gfx::SurfaceConfiguration& requested_configuration);

  static GLSurface* GetCurrent();

  // Called when the swap interval for the associated context changes.
  virtual void OnSetSwapInterval(int interval);

  const gfx::SurfaceConfiguration get_surface_configuration() {
    return surface_configuration_;
  }

 protected:
  virtual ~GLSurface();
  static bool InitializeOneOffImplementation(GLImplementation impl,
                                             bool fallback_to_osmesa,
                                             bool gpu_service_logging,
                                             bool disable_gl_drawing);
  static bool InitializeOneOffInternal();
  static void SetCurrent(GLSurface* surface);

  static bool ExtensionsContain(const char* extensions, const char* name);

 private:
  friend class base::RefCounted<GLSurface>;
  friend class GLContext;

  gfx::SurfaceConfiguration surface_configuration_;

  DISALLOW_COPY_AND_ASSIGN(GLSurface);
};

// Implementation of GLSurface that forwards all calls through to another
// GLSurface.
class GL_EXPORT GLSurfaceAdapter : public GLSurface {
 public:
  explicit GLSurfaceAdapter(GLSurface* surface);

  bool Initialize() override;
  void Destroy() override;
  bool Resize(const gfx::Size& size) override;
  bool Recreate() override;
  bool DeferDraws() override;
  bool IsOffscreen() override;
  bool SwapBuffers() override;
  bool SwapBuffersAsync(const SwapCompletionCallback& callback) override;
  bool PostSubBuffer(int x, int y, int width, int height) override;
  bool PostSubBufferAsync(int x,
                          int y,
                          int width,
                          int height,
                          const SwapCompletionCallback& callback) override;
  bool SupportsPostSubBuffer() override;
  gfx::Size GetSize() override;
  void* GetHandle() override;
  unsigned int GetBackingFrameBufferObject() override;
  bool OnMakeCurrent(GLContext* context) override;
  bool SetBackbufferAllocation(bool allocated) override;
  void SetFrontbufferAllocation(bool allocated) override;
  void* GetShareHandle() override;
  void* GetDisplay() override;
  void* GetConfig() override;
  unsigned GetFormat() override;
  VSyncProvider* GetVSyncProvider() override;
  bool ScheduleOverlayPlane(int z_order,
                            OverlayTransform transform,
                            GLImage* image,
                            const Rect& bounds_rect,
                            const RectF& crop_rect) override;
  bool IsSurfaceless() const override;

  GLSurface* surface() const { return surface_.get(); }

 protected:
  ~GLSurfaceAdapter() override;

 private:
  scoped_refptr<GLSurface> surface_;

  DISALLOW_COPY_AND_ASSIGN(GLSurfaceAdapter);
};

}  // namespace gfx

#endif  // UI_GL_GL_SURFACE_H_
