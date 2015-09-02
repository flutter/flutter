// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_surface_osmesa_x11.h"

#include <X11/Xlib.h>

#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface_egl.h"

namespace gfx {

// static
bool GLSurface::InitializeOneOffInternal() {
  if (!NativeViewGLSurfaceOSMesa::InitializeOneOff()) {
    LOG(ERROR) << "NativeViewGLSurfaceOSMesa::InitializeOneOff failed.";
    return false;
  }
  return true;
}

// static
bool NativeViewGLSurfaceOSMesa::InitializeOneOff() {
  static bool initialized = false;
  if (initialized)
    return true;

  if (!GetXDisplay()) {
    LOG(ERROR) << "XOpenDisplay failed.";
    return false;
  }

  initialized = true;
  return true;
}

scoped_refptr<GLSurface> GLSurface::CreateViewGLSurface(
    gfx::AcceleratedWidget window,
    const gfx::SurfaceConfiguration& requested_configuration) {
  TRACE_EVENT0("gpu", "GLSurface::CreateViewGLSurface");
  scoped_refptr<GLSurface> surface(
      new NativeViewGLSurfaceOSMesa(window, requested_configuration));
  if (!surface->Initialize())
    return NULL;

  return surface;
}

scoped_refptr<GLSurface> GLSurface::CreateOffscreenGLSurface(
    const gfx::Size& size,
    const gfx::SurfaceConfiguration& requested_configuration) {
  TRACE_EVENT0("gpu", "GLSurface::CreateOffscreenGLSurface");
  scoped_refptr<GLSurface> surface(new GLSurfaceOSMesa(
      OSMesaSurfaceFormatRGBA, size, requested_configuration));
  if (!surface->Initialize())
    return NULL;

  return surface;
}

NativeViewGLSurfaceOSMesa::NativeViewGLSurfaceOSMesa(
    AcceleratedWidget window,
    const SurfaceConfiguration& requested_configuration)
    : GLSurfaceOSMesa(OSMesaSurfaceFormatBGRA,
                      Size(1, 1),
                      requested_configuration),
      xdisplay_(GetXDisplay()),
      window_graphics_context_(0),
      window_(window),
      pixmap_graphics_context_(0),
      pixmap_(0) {
  DCHECK(xdisplay_);
  DCHECK(window_);
}

bool NativeViewGLSurfaceOSMesa::Initialize() {
  if (!GLSurfaceOSMesa::Initialize())
    return false;

  window_graphics_context_ = XCreateGC(xdisplay_, window_, 0, NULL);
  if (!window_graphics_context_) {
    LOG(ERROR) << "XCreateGC failed.";
    Destroy();
    return false;
  }

  return true;
}

void NativeViewGLSurfaceOSMesa::Destroy() {
  if (pixmap_graphics_context_) {
    XFreeGC(xdisplay_, pixmap_graphics_context_);
    pixmap_graphics_context_ = NULL;
  }

  if (pixmap_) {
    XFreePixmap(xdisplay_, pixmap_);
    pixmap_ = 0;
  }

  if (window_graphics_context_) {
    XFreeGC(xdisplay_, window_graphics_context_);
    window_graphics_context_ = NULL;
  }

  XSync(xdisplay_, False);
}

bool NativeViewGLSurfaceOSMesa::Resize(const Size& new_size) {
  if (!GLSurfaceOSMesa::Resize(new_size))
    return false;

  XWindowAttributes attributes;
  if (!XGetWindowAttributes(xdisplay_, window_, &attributes)) {
    LOG(ERROR) << "XGetWindowAttributes failed for window " << window_ << ".";
    return false;
  }

  // Destroy the previous pixmap and graphics context.
  if (pixmap_graphics_context_) {
    XFreeGC(xdisplay_, pixmap_graphics_context_);
    pixmap_graphics_context_ = NULL;
  }
  if (pixmap_) {
    XFreePixmap(xdisplay_, pixmap_);
    pixmap_ = 0;
  }

  // Recreate a pixmap to hold the frame.
  pixmap_ = XCreatePixmap(xdisplay_, window_, new_size.width(),
                          new_size.height(), attributes.depth);
  if (!pixmap_) {
    LOG(ERROR) << "XCreatePixmap failed.";
    return false;
  }

  // Recreate a graphics context for the pixmap.
  pixmap_graphics_context_ = XCreateGC(xdisplay_, pixmap_, 0, NULL);
  if (!pixmap_graphics_context_) {
    LOG(ERROR) << "XCreateGC failed";
    return false;
  }

  return true;
}

bool NativeViewGLSurfaceOSMesa::IsOffscreen() {
  return false;
}

bool NativeViewGLSurfaceOSMesa::SwapBuffers() {
  TRACE_EVENT2("gpu", "NativeViewGLSurfaceOSMesa:RealSwapBuffers", "width",
               GetSize().width(), "height", GetSize().height());

  Size size = GetSize();

  XWindowAttributes attributes;
  if (!XGetWindowAttributes(xdisplay_, window_, &attributes)) {
    LOG(ERROR) << "XGetWindowAttributes failed for window " << window_ << ".";
    return false;
  }

  // Copy the frame into the pixmap.
  PutARGBImage(xdisplay_, attributes.visual, attributes.depth, pixmap_,
               pixmap_graphics_context_, static_cast<const uint8*>(GetHandle()),
               size.width(), size.height());

  // Copy the pixmap to the window.
  XCopyArea(xdisplay_, pixmap_, window_, window_graphics_context_, 0, 0,
            size.width(), size.height(), 0, 0);

  return true;
}

bool NativeViewGLSurfaceOSMesa::SupportsPostSubBuffer() {
  return true;
}

bool NativeViewGLSurfaceOSMesa::PostSubBuffer(int x,
                                              int y,
                                              int width,
                                              int height) {
  Size size = GetSize();

  // Move (0,0) from lower-left to upper-left
  y = size.height() - y - height;

  XWindowAttributes attributes;
  if (!XGetWindowAttributes(xdisplay_, window_, &attributes)) {
    LOG(ERROR) << "XGetWindowAttributes failed for window " << window_ << ".";
    return false;
  }

  // Copy the frame into the pixmap.
  PutARGBImage(xdisplay_, attributes.visual, attributes.depth, pixmap_,
               pixmap_graphics_context_, static_cast<const uint8*>(GetHandle()),
               size.width(), size.height(), x, y, x, y, width, height);

  // Copy the pixmap to the window.
  XCopyArea(xdisplay_, pixmap_, window_, window_graphics_context_, x, y, width,
            height, x, y);

  return true;
}

NativeViewGLSurfaceOSMesa::~NativeViewGLSurfaceOSMesa() {
  Destroy();
}

EGLNativeDisplayType GetPlatformDefaultEGLNativeDisplay() {
  return gfx::GetXDisplay();
}
}
