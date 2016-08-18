// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/platform/mac/platform_view_mac.h"

#include <AppKit/AppKit.h>

#include "base/trace_event/trace_event.h"

namespace sky {
namespace shell {

PlatformViewMac::PlatformViewMac(NSOpenGLView* gl_view)
    : opengl_view_([gl_view retain]),
      resource_loading_context_([[NSOpenGLContext alloc]
          initWithFormat:gl_view.pixelFormat
            shareContext:gl_view.openGLContext]),
      weak_factory_(this) {}

PlatformViewMac::~PlatformViewMac() = default;

ftl::WeakPtr<sky::shell::PlatformView> PlatformViewMac::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

uint64_t PlatformViewMac::DefaultFramebuffer() const {
  // Default window bound framebuffer FBO 0.
  return 0;
}

bool PlatformViewMac::ContextMakeCurrent() {
  if (!IsValid()) {
    return false;
  }

  [opengl_view_.get().openGLContext makeCurrentContext];
  return true;
}

bool PlatformViewMac::ResourceContextMakeCurrent() {
  NSOpenGLContext* context = resource_loading_context_.get();

  if (context == nullptr) {
    return false;
  }

  [context makeCurrentContext];
  return true;
}

bool PlatformViewMac::SwapBuffers() {
  TRACE_EVENT0("flutter", "PlatformViewMac::SwapBuffers");

  if (!IsValid()) {
    return false;
  }

  [opengl_view_.get().openGLContext flushBuffer];
  return true;
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

void PlatformViewMac::RunFromSource(const std::string& main,
                                    const std::string& packages,
                                    const std::string& assets_directory) {
  // TODO(johnmccutchan): Call to the Mac UI thread so that services work
  // properly like we do in PlatformViewAndroid.
  engine().RunFromSource(main, packages, assets_directory);
}

}  // namespace shell
}  // namespace sky
