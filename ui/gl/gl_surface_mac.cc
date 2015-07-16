// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_surface.h"

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface_stub.h"
#include "ui/gl/gpu_switching_manager.h"

#include <OpenGL/CGLRenderers.h>
#include <OpenGL/CGLTypes.h>

extern "C" {
// The header <OpenGL/OpenGL.h> may not be directly imported since it includes
// gltypes.h which conflict with the types already included
extern CGLError CGLChoosePixelFormat(const CGLPixelFormatAttribute *attribs,
    CGLPixelFormatObj *pix, GLint *npix);
extern void CGLReleasePixelFormat(CGLPixelFormatObj pix);
}

namespace gfx {
namespace {

// A "no-op" surface. It is not required that a CGLContextObj have an
// associated drawable (pbuffer or fullscreen context) in order to be
// made current. Everywhere this surface type is used, we allocate an
// FBO at the user level as the drawable of the associated context.
class GL_EXPORT NoOpGLSurface : public GLSurface {
 public:
  explicit NoOpGLSurface(const gfx::Size& size,
                         const gfx::SurfaceConfiguration conf)
      : GLSurface(conf),
        size_(size) {}

  // Implement GLSurface.
  bool Initialize() override { return true; }
  void Destroy() override {}
  bool IsOffscreen() override { return true; }
  bool SwapBuffers() override {
    NOTREACHED() << "Cannot call SwapBuffers on a NoOpGLSurface.";
    return false;
  }
  gfx::Size GetSize() override { return size_; }
  void* GetHandle() override { return NULL; }
  void* GetDisplay() override { return NULL; }
  bool IsSurfaceless() const override { return true; }

 protected:
  ~NoOpGLSurface() override {}

 private:
  gfx::Size size_;

  DISALLOW_COPY_AND_ASSIGN(NoOpGLSurface);
};

// static
bool InitializeOneOffForSandbox() {
  static bool initialized = false;
  if (initialized)
    return true;

  // This is called from the sandbox warmup code on Mac OS X.
  // GPU-related stuff is very slow without this, probably because
  // the sandbox prevents loading graphics drivers or some such.
  std::vector<CGLPixelFormatAttribute> attribs;
  if (ui::GpuSwitchingManager::GetInstance()->SupportsDualGpus()) {
    // Avoid switching to the discrete GPU just for this pixel
    // format selection.
    attribs.push_back(kCGLPFAAllowOfflineRenderers);
  }
  if (GetGLImplementation() == kGLImplementationAppleGL) {
    attribs.push_back(kCGLPFARendererID);
    attribs.push_back(static_cast<CGLPixelFormatAttribute>(
      kCGLRendererGenericFloatID));
  }
  attribs.push_back(static_cast<CGLPixelFormatAttribute>(0));

  CGLPixelFormatObj format;
  GLint num_pixel_formats;
  if (CGLChoosePixelFormat(&attribs.front(),
                           &format,
                           &num_pixel_formats) != kCGLNoError) {
    LOG(ERROR) << "Error choosing pixel format.";
    return false;
  }
  if (!format) {
    LOG(ERROR) << "format == 0.";
    return false;
  }
  CGLReleasePixelFormat(format);
  DCHECK_NE(num_pixel_formats, 0);
  initialized = true;
  return true;
}

}  // namespace

bool GLSurface::InitializeOneOffInternal() {
  switch (GetGLImplementation()) {
    case kGLImplementationDesktopGL:
    case kGLImplementationAppleGL:
      if (!InitializeOneOffForSandbox()) {
        LOG(ERROR) << "GLSurfaceCGL::InitializeOneOff failed.";
        return false;
      }
      break;
    default:
      break;
  }
  return true;
}

scoped_refptr<GLSurface> GLSurface::CreateViewGLSurface(
    gfx::AcceleratedWidget window,
    const gfx::SurfaceConfiguration& conf) {
  TRACE_EVENT0("gpu", "GLSurface::CreateViewGLSurface");
  switch (GetGLImplementation()) {
    case kGLImplementationDesktopGL:
    case kGLImplementationAppleGL: {
      NOTIMPLEMENTED() << "No onscreen support on Mac.";
      return NULL;
    }
    case kGLImplementationMockGL:
      return new GLSurfaceStub(conf);
    default:
      NOTREACHED();
      return NULL;
  }
}

scoped_refptr<GLSurface> GLSurface::CreateOffscreenGLSurface(
    const gfx::Size& size,
    const gfx::SurfaceConfiguration& conf) {
  TRACE_EVENT0("gpu", "GLSurface::CreateOffscreenGLSurface");
  switch (GetGLImplementation()) {
    case kGLImplementationDesktopGL:
    case kGLImplementationAppleGL: {
      scoped_refptr<GLSurface> surface(new NoOpGLSurface(size, conf));
      if (!surface->Initialize())
        return NULL;

      return surface;
    }
    case kGLImplementationMockGL:
      return new GLSurfaceStub(conf);
    default:
      NOTREACHED();
      return NULL;
  }
}

}  // namespace gfx
