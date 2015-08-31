// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_surface.h"

#include "base/bind.h"
#include "base/callback.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"
#include "base/threading/worker_pool.h"
#include "ui/gfx/native_widget_types.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_image.h"
#include "ui/gl/gl_image_linux_dma_buffer.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface_egl.h"
#include "ui/gl/gl_surface_osmesa.h"
#include "ui/gl/gl_surface_stub.h"
#include "ui/gl/scoped_binders.h"
#include "ui/gl/scoped_make_current.h"
#include "ui/ozone/public/native_pixmap.h"
#include "ui/ozone/public/surface_factory_ozone.h"
#include "ui/ozone/public/surface_ozone_egl.h"

namespace gfx {

namespace {

void WaitForFence(EGLDisplay display, EGLSyncKHR fence) {
  eglClientWaitSyncKHR(display, fence, EGL_SYNC_FLUSH_COMMANDS_BIT_KHR,
                       EGL_FOREVER_KHR);
}

// A thin wrapper around GLSurfaceEGL that owns the EGLNativeWindow
class GL_EXPORT GLSurfaceOzoneEGL : public NativeViewGLSurfaceEGL {
 public:
  GLSurfaceOzoneEGL(scoped_ptr<ui::SurfaceOzoneEGL> ozone_surface,
                    AcceleratedWidget widget)
      : NativeViewGLSurfaceEGL(ozone_surface->GetNativeWindow()),
        ozone_surface_(ozone_surface.Pass()),
        widget_(widget) {}

  bool Initialize() override {
    return Initialize(ozone_surface_->CreateVSyncProvider());
  }
  bool Resize(const gfx::Size& size) override {
    if (!ozone_surface_->ResizeNativeWindow(size)) {
      if (!ReinitializeNativeSurface() ||
          !ozone_surface_->ResizeNativeWindow(size))
        return false;
    }

    return NativeViewGLSurfaceEGL::Resize(size);
  }
  bool SwapBuffers() override {
    if (!NativeViewGLSurfaceEGL::SwapBuffers())
      return false;

    return ozone_surface_->OnSwapBuffers();
  }
  bool ScheduleOverlayPlane(int z_order,
                            OverlayTransform transform,
                            GLImage* image,
                            const Rect& bounds_rect,
                            const RectF& crop_rect) override {
    return image->ScheduleOverlayPlane(
        widget_, z_order, transform, bounds_rect, crop_rect);
  }

 private:
  using NativeViewGLSurfaceEGL::Initialize;

  ~GLSurfaceOzoneEGL() override {
    Destroy();  // EGL surface must be destroyed before SurfaceOzone
  }

  bool ReinitializeNativeSurface() {
    scoped_ptr<ui::ScopedMakeCurrent> scoped_make_current;
    GLContext* current_context = GLContext::GetCurrent();
    bool was_current =
        current_context && current_context->IsCurrent(this);
    if (was_current) {
      scoped_make_current.reset(
          new ui::ScopedMakeCurrent(current_context, this));
    }

    Destroy();
    ozone_surface_ =
        ui::SurfaceFactoryOzone::GetInstance()->CreateEGLSurfaceForWidget(
            widget_).Pass();
    if (!ozone_surface_) {
      LOG(ERROR) << "Failed to create native surface.";
      return false;
    }

    window_ = ozone_surface_->GetNativeWindow();
    if (!Initialize()) {
      LOG(ERROR) << "Failed to initialize.";
      return false;
    }

    return true;
  }

  // The native surface. Deleting this is allowed to free the EGLNativeWindow.
  scoped_ptr<ui::SurfaceOzoneEGL> ozone_surface_;
  AcceleratedWidget widget_;

  DISALLOW_COPY_AND_ASSIGN(GLSurfaceOzoneEGL);
};

class GL_EXPORT GLSurfaceOzoneSurfaceless : public SurfacelessEGL {
 public:
  GLSurfaceOzoneSurfaceless(scoped_ptr<ui::SurfaceOzoneEGL> ozone_surface,
                            AcceleratedWidget widget)
      : SurfacelessEGL(gfx::Size()),
        ozone_surface_(ozone_surface.Pass()),
        widget_(widget),
        has_implicit_external_sync_(
            HasEGLExtension("EGL_ARM_implicit_external_sync")),
        last_swap_buffers_result_(true),
        weak_factory_(this) {}

  bool Initialize() override {
    if (!SurfacelessEGL::Initialize())
      return false;
    vsync_provider_ = ozone_surface_->CreateVSyncProvider();
    if (!vsync_provider_)
      return false;
    return true;
  }
  bool Resize(const gfx::Size& size) override {
    if (!ozone_surface_->ResizeNativeWindow(size))
      return false;

    return SurfacelessEGL::Resize(size);
  }
  bool SwapBuffers() override {
    glFlush();
    // TODO: the following should be replaced by a per surface flush as it gets
    // implemented in GL drivers.
    if (has_implicit_external_sync_) {
      EGLSyncKHR fence = InsertFence();
      if (!fence)
        return false;

      EGLDisplay display = GetDisplay();
      WaitForFence(display, fence);
      eglDestroySyncKHR(display, fence);
    } else if (ozone_surface_->IsUniversalDisplayLinkDevice()) {
      glFinish();
    }

    return ozone_surface_->OnSwapBuffers();
  }
  bool ScheduleOverlayPlane(int z_order,
                            OverlayTransform transform,
                            GLImage* image,
                            const Rect& bounds_rect,
                            const RectF& crop_rect) override {
    return image->ScheduleOverlayPlane(
        widget_, z_order, transform, bounds_rect, crop_rect);
  }
  bool IsOffscreen() override { return false; }
  VSyncProvider* GetVSyncProvider() override { return vsync_provider_.get(); }
  bool SupportsPostSubBuffer() override { return true; }
  bool PostSubBuffer(int x, int y, int width, int height) override {
    // The actual sub buffer handling is handled at higher layers.
    SwapBuffers();
    return true;
  }
  bool SwapBuffersAsync(const SwapCompletionCallback& callback) override {
    glFlush();
    // TODO: the following should be replaced by a per surface flush as it gets
    // implemented in GL drivers.
    if (has_implicit_external_sync_) {
      // If last swap failed, don't try to schedule new ones.
      if (!last_swap_buffers_result_) {
        last_swap_buffers_result_ = true;
        return false;
      }

      EGLSyncKHR fence = InsertFence();
      if (!fence)
        return false;

      base::Closure fence_wait_task =
          base::Bind(&WaitForFence, GetDisplay(), fence);

      base::Closure fence_retired_callback =
          base::Bind(&GLSurfaceOzoneSurfaceless::FenceRetired,
                     weak_factory_.GetWeakPtr(), fence, callback);

      base::WorkerPool::PostTaskAndReply(FROM_HERE, fence_wait_task,
                                         fence_retired_callback, false);
      return true;
    } else if (ozone_surface_->IsUniversalDisplayLinkDevice()) {
      glFinish();
    }
    return ozone_surface_->OnSwapBuffersAsync(callback);
  }
  bool PostSubBufferAsync(int x,
                          int y,
                          int width,
                          int height,
                          const SwapCompletionCallback& callback) override {
    return SwapBuffersAsync(callback);
  }

 protected:
  ~GLSurfaceOzoneSurfaceless() override {
    Destroy();  // EGL surface must be destroyed before SurfaceOzone
  }

  EGLSyncKHR InsertFence() {
    const EGLint attrib_list[] = {EGL_SYNC_CONDITION_KHR,
                                  EGL_SYNC_PRIOR_COMMANDS_IMPLICIT_EXTERNAL_ARM,
                                  EGL_NONE};
    return eglCreateSyncKHR(GetDisplay(), EGL_SYNC_FENCE_KHR, attrib_list);
  }

  void FenceRetired(EGLSyncKHR fence, const SwapCompletionCallback& callback) {
    eglDestroySyncKHR(GetDisplay(), fence);
    last_swap_buffers_result_ = ozone_surface_->OnSwapBuffersAsync(callback);
  }

  // The native surface. Deleting this is allowed to free the EGLNativeWindow.
  scoped_ptr<ui::SurfaceOzoneEGL> ozone_surface_;
  AcceleratedWidget widget_;
  scoped_ptr<VSyncProvider> vsync_provider_;
  bool has_implicit_external_sync_;
  bool last_swap_buffers_result_;

  base::WeakPtrFactory<GLSurfaceOzoneSurfaceless> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(GLSurfaceOzoneSurfaceless);
};

// This provides surface-like semantics implemented through surfaceless.
// A framebuffer is bound automatically.
class GL_EXPORT GLSurfaceOzoneSurfacelessSurfaceImpl
    : public GLSurfaceOzoneSurfaceless {
 public:
  GLSurfaceOzoneSurfacelessSurfaceImpl(
      scoped_ptr<ui::SurfaceOzoneEGL> ozone_surface,
      AcceleratedWidget widget)
      : GLSurfaceOzoneSurfaceless(ozone_surface.Pass(), widget),
        fbo_(0),
        current_surface_(0) {
    for (auto& texture : textures_)
      texture = 0;
  }

  unsigned int GetBackingFrameBufferObject() override { return fbo_; }

  bool OnMakeCurrent(GLContext* context) override {
    if (!fbo_) {
      glGenFramebuffersEXT(1, &fbo_);
      if (!fbo_)
        return false;
      glGenTextures(arraysize(textures_), textures_);
      if (!CreatePixmaps())
        return false;
    }
    BindFramebuffer();
    glBindFramebufferEXT(GL_FRAMEBUFFER, fbo_);
    return SurfacelessEGL::OnMakeCurrent(context);
  }

  bool Resize(const gfx::Size& size) override {
    if (size == GetSize())
      return true;
    return GLSurfaceOzoneSurfaceless::Resize(size) && CreatePixmaps();
  }

  bool SupportsPostSubBuffer() override { return false; }

  bool SwapBuffers() override {
    if (!images_[current_surface_]->ScheduleOverlayPlane(
            widget_, 0, OverlayTransform::OVERLAY_TRANSFORM_NONE,
            gfx::Rect(GetSize()), gfx::RectF(1, 1)))
      return false;
    if (!GLSurfaceOzoneSurfaceless::SwapBuffers())
      return false;
    current_surface_ ^= 1;
    BindFramebuffer();
    return true;
  }

  bool SwapBuffersAsync(const SwapCompletionCallback& callback) override {
    if (!images_[current_surface_]->ScheduleOverlayPlane(
            widget_, 0, OverlayTransform::OVERLAY_TRANSFORM_NONE,
            gfx::Rect(GetSize()), gfx::RectF(1, 1)))
      return false;
    if (!GLSurfaceOzoneSurfaceless::SwapBuffersAsync(callback))
      return false;
    current_surface_ ^= 1;
    BindFramebuffer();
    return true;
  }

  void Destroy() override {
    GLContext* current_context = GLContext::GetCurrent();
    DCHECK(current_context && current_context->IsCurrent(this));
    glBindFramebufferEXT(GL_FRAMEBUFFER, 0);
    if (fbo_) {
      glDeleteTextures(arraysize(textures_), textures_);
      for (auto& texture : textures_)
        texture = 0;
      glDeleteFramebuffersEXT(1, &fbo_);
      fbo_ = 0;
    }
    for (auto image : images_) {
      if (image)
        image->Destroy(true);
    }
  }

 private:
  class SurfaceImage : public GLImageLinuxDMABuffer {
   public:
    SurfaceImage(const gfx::Size& size, unsigned internalformat)
        : GLImageLinuxDMABuffer(size, internalformat) {}

    bool Initialize(scoped_refptr<ui::NativePixmap> pixmap,
                    gfx::GpuMemoryBuffer::Format format) {
      base::FileDescriptor handle(pixmap->GetDmaBufFd(), false);
      if (!GLImageLinuxDMABuffer::Initialize(handle, format,
                                             pixmap->GetDmaBufPitch()))
        return false;
      pixmap_ = pixmap;
      return true;
    }
    bool ScheduleOverlayPlane(gfx::AcceleratedWidget widget,
                              int z_order,
                              gfx::OverlayTransform transform,
                              const gfx::Rect& bounds_rect,
                              const gfx::RectF& crop_rect) override {
      return ui::SurfaceFactoryOzone::GetInstance()->ScheduleOverlayPlane(
          widget, z_order, transform, pixmap_, bounds_rect, crop_rect);
    }

   private:
    ~SurfaceImage() override {}

    scoped_refptr<ui::NativePixmap> pixmap_;
  };

  ~GLSurfaceOzoneSurfacelessSurfaceImpl() override {
    DCHECK(!fbo_);
    for (size_t i = 0; i < arraysize(textures_); i++)
      DCHECK(!textures_[i]) << "texture " << i << " not released";
  }

  void BindFramebuffer() {
    ScopedFrameBufferBinder fb(fbo_);
    glFramebufferTexture2DEXT(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_TEXTURE_2D, textures_[current_surface_], 0);
  }

  bool CreatePixmaps() {
    if (!fbo_)
      return true;
    for (size_t i = 0; i < arraysize(textures_); i++) {
      scoped_refptr<ui::NativePixmap> pixmap =
          ui::SurfaceFactoryOzone::GetInstance()->CreateNativePixmap(
              widget_, GetSize(), ui::SurfaceFactoryOzone::RGBA_8888,
              ui::SurfaceFactoryOzone::SCANOUT);
      if (!pixmap)
        return false;
      scoped_refptr<SurfaceImage> image = new SurfaceImage(GetSize(), GL_RGBA);
      if (!image->Initialize(pixmap, gfx::GpuMemoryBuffer::Format::BGRA_8888))
        return false;
      images_[i] = image;
      // Bind image to texture.
      ScopedTextureBinder binder(GL_TEXTURE_2D, textures_[i]);
      if (!images_[i]->BindTexImage(GL_TEXTURE_2D))
        return false;
    }
    return true;
  }

  GLuint fbo_;
  GLuint textures_[2];
  scoped_refptr<GLImage> images_[2];
  int current_surface_;
  DISALLOW_COPY_AND_ASSIGN(GLSurfaceOzoneSurfacelessSurfaceImpl);
};

}  // namespace

// static
bool GLSurface::InitializeOneOffInternal() {
  switch (GetGLImplementation()) {
    case kGLImplementationEGLGLES2:
      if (!GLSurfaceEGL::InitializeOneOff()) {
        LOG(ERROR) << "GLSurfaceEGL::InitializeOneOff failed.";
        return false;
      }

      return true;
    case kGLImplementationOSMesaGL:
    case kGLImplementationMockGL:
      return true;
    default:
      return false;
  }
}

// static
scoped_refptr<GLSurface> GLSurface::CreateSurfacelessViewGLSurface(
    gfx::AcceleratedWidget window) {
  if (GetGLImplementation() == kGLImplementationEGLGLES2 &&
      window != kNullAcceleratedWidget &&
      GLSurfaceEGL::IsEGLSurfacelessContextSupported() &&
      ui::SurfaceFactoryOzone::GetInstance()->CanShowPrimaryPlaneAsOverlay()) {
    scoped_ptr<ui::SurfaceOzoneEGL> surface_ozone =
        ui::SurfaceFactoryOzone::GetInstance()
            ->CreateSurfacelessEGLSurfaceForWidget(window);
    if (!surface_ozone)
      return nullptr;
    scoped_refptr<GLSurface> surface;
    surface = new GLSurfaceOzoneSurfaceless(surface_ozone.Pass(), window);
    if (surface->Initialize())
      return surface;
  }

  return nullptr;
}

// static
scoped_refptr<GLSurface> GLSurface::CreateViewGLSurface(
    gfx::AcceleratedWidget window) {
  if (GetGLImplementation() == kGLImplementationOSMesaGL) {
    scoped_refptr<GLSurface> surface(new GLSurfaceOSMesaHeadless());
    if (!surface->Initialize())
      return NULL;
    return surface;
  }
  DCHECK(GetGLImplementation() == kGLImplementationEGLGLES2);
  if (window != kNullAcceleratedWidget) {
    scoped_refptr<GLSurface> surface;
    if (GLSurfaceEGL::IsEGLSurfacelessContextSupported() &&
        ui::SurfaceFactoryOzone::GetInstance()
            ->CanShowPrimaryPlaneAsOverlay()) {
      scoped_ptr<ui::SurfaceOzoneEGL> surface_ozone =
          ui::SurfaceFactoryOzone::GetInstance()
              ->CreateSurfacelessEGLSurfaceForWidget(window);
      if (!surface_ozone)
        return NULL;
      surface = new GLSurfaceOzoneSurfacelessSurfaceImpl(surface_ozone.Pass(),
                                                         window);
    } else {
      scoped_ptr<ui::SurfaceOzoneEGL> surface_ozone =
          ui::SurfaceFactoryOzone::GetInstance()->CreateEGLSurfaceForWidget(
              window);
      if (!surface_ozone)
        return NULL;

      surface = new GLSurfaceOzoneEGL(surface_ozone.Pass(), window);
    }
    if (!surface->Initialize())
      return NULL;
    return surface;
  } else {
    scoped_refptr<GLSurface> surface = new GLSurfaceStub();
    if (surface->Initialize())
      return surface;
  }
  return NULL;
}

// static
scoped_refptr<GLSurface> GLSurface::CreateOffscreenGLSurface(
    const gfx::Size& size) {
  switch (GetGLImplementation()) {
    case kGLImplementationOSMesaGL: {
      scoped_refptr<GLSurface> surface(
          new GLSurfaceOSMesa(OSMesaSurfaceFormatBGRA, size));
      if (!surface->Initialize())
        return NULL;

      return surface;
    }
    case kGLImplementationEGLGLES2: {
      scoped_refptr<GLSurface> surface;
      if (GLSurfaceEGL::IsEGLSurfacelessContextSupported() &&
          (size.width() == 0 && size.height() == 0)) {
        surface = new SurfacelessEGL(size);
      } else
        surface = new PbufferGLSurfaceEGL(size);

      if (!surface->Initialize())
        return NULL;
      return surface;
    }
    default:
      NOTREACHED();
      return NULL;
  }
}

EGLNativeDisplayType GetPlatformDefaultEGLNativeDisplay() {
  return ui::SurfaceFactoryOzone::GetInstance()->GetNativeDisplay();
}

}  // namespace gfx
