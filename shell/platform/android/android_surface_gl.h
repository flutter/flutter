// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_GL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_GL_H_

#include <jni.h>
#include <memory>

#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/android/android_context_gl.h"
#include "flutter/shell/platform/android/android_environment_gl.h"
#include "flutter/shell/platform/android/android_surface.h"
#include "lib/fxl/macros.h"

namespace shell {

class AndroidSurfaceGL : public GPUSurfaceGLDelegate, public AndroidSurface {
 public:
  explicit AndroidSurfaceGL(PlatformView::SurfaceConfig offscreen_config);

  ~AndroidSurfaceGL() override;

  bool IsValid() const override;

  bool IsOffscreenContextValid() const;

  std::unique_ptr<Surface> CreateGPUSurface() override;

  void TeardownOnScreenContext() override;

  SkISize OnScreenSurfaceSize() const override;

  bool OnScreenSurfaceResize(const SkISize& size) const override;

  bool ResourceContextMakeCurrent() override;

  bool SetNativeWindow(fxl::RefPtr<AndroidNativeWindow> window,
                       PlatformView::SurfaceConfig config) override;

  bool GLContextMakeCurrent() override;

  bool GLContextClearCurrent() override;

  bool GLContextPresent() override;

  intptr_t GLContextFBO() const override;

  bool SurfaceSupportsSRGB() const override;

 private:
  fxl::RefPtr<AndroidContextGL> onscreen_context_;
  fxl::RefPtr<AndroidContextGL> offscreen_context_;
  sk_sp<GrContext> gr_context_;

  FXL_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceGL);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_GL_H_
