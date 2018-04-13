// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_MAC_PLATFORM_VIEW_MAC_H_
#define SHELL_PLATFORM_MAC_PLATFORM_VIEW_MAC_H_

#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "lib/fxl/memory/weak_ptr.h"

@class NSOpenGLView;
@class NSOpenGLContext;

namespace shell {

class PlatformViewMac final : public PlatformView, public GPUSurfaceGLDelegate {
 public:
  PlatformViewMac(Shell& shell, NSOpenGLView* gl_view);

  ~PlatformViewMac() override;

  std::unique_ptr<VsyncWaiter> CreateVSyncWaiter() override;

  bool GLContextMakeCurrent() override;

  bool GLContextClearCurrent() override;

  bool GLContextPresent() override;

  intptr_t GLContextFBO() const override;

 private:
  fml::scoped_nsobject<NSOpenGLView> opengl_view_;
  fml::scoped_nsobject<NSOpenGLContext> resource_loading_context_;

  bool IsValid() const;

  // |shell::PlatformView|
  std::unique_ptr<Surface> CreateRenderingSurface() override;

  // |shell::PlatformView|
  sk_sp<GrContext> CreateResourceContext() const override;

  FXL_DISALLOW_COPY_AND_ASSIGN(PlatformViewMac);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_MAC_PLATFORM_VIEW_MAC_H_
