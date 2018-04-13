// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/desktop/platform_view_mac.h"

#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>

#include "flutter/fml/trace_event.h"
#include "flutter/shell/common/io_manager.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/platform/darwin/desktop/vsync_waiter_mac.h"
#include "lib/fxl/command_line.h"
#include "lib/fxl/synchronization/waitable_event.h"

namespace shell {

PlatformViewMac::PlatformViewMac(Shell& shell, NSOpenGLView* gl_view)
    : PlatformView(shell, shell.GetTaskRunners()),
      opengl_view_([gl_view retain]),
      resource_loading_context_([[NSOpenGLContext alloc] initWithFormat:gl_view.pixelFormat
                                                           shareContext:gl_view.openGLContext]) {}

PlatformViewMac::~PlatformViewMac() = default;

std::unique_ptr<VsyncWaiter> PlatformViewMac::CreateVSyncWaiter() {
  return std::make_unique<VsyncWaiterMac>(task_runners_);
}

intptr_t PlatformViewMac::GLContextFBO() const {
  // Default window bound framebuffer FBO 0.
  return 0;
}

bool PlatformViewMac::GLContextMakeCurrent() {
  TRACE_EVENT0("flutter", "PlatformViewMac::GLContextMakeCurrent");
  if (!IsValid()) {
    return false;
  }

  [opengl_view_.get().openGLContext makeCurrentContext];
  return true;
}

bool PlatformViewMac::GLContextClearCurrent() {
  TRACE_EVENT0("flutter", "PlatformViewMac::GLContextClearCurrent");
  if (!IsValid()) {
    return false;
  }

  [NSOpenGLContext clearCurrentContext];
  return true;
}

bool PlatformViewMac::GLContextPresent() {
  TRACE_EVENT0("flutter", "PlatformViewMac::GLContextPresent");
  if (!IsValid()) {
    return false;
  }

  [opengl_view_.get().openGLContext flushBuffer];
  return true;
}

sk_sp<GrContext> PlatformViewMac::CreateResourceContext() const {
  [resource_loading_context_.get() makeCurrentContext];
  return IOManager::CreateCompatibleResourceLoadingContext(GrBackend::kOpenGL_GrBackend);
}

bool PlatformViewMac::IsValid() const {
  if (opengl_view_ == nullptr) {
    return false;
  }

  auto context = opengl_view_.get().openGLContext;

  if (context == nullptr) {
    return false;
  }

  return true;
}

std::unique_ptr<Surface> PlatformViewMac::CreateRenderingSurface() {
  return std::make_unique<GPUSurfaceGL>(this);
}

}  // namespace shell
