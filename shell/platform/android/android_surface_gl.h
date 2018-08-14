// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_GL_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_GL_H_

#include <jni.h>
#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/gpu/gpu_surface_gl.h"
#include "flutter/shell/platform/android/android_context_gl.h"
#include "flutter/shell/platform/android/android_environment_gl.h"
#include "flutter/shell/platform/android/android_surface.h"

namespace shell {

class AndroidSurfaceGL final : public GPUSurfaceGLDelegate,
                               public AndroidSurface {
 public:
  AndroidSurfaceGL();

  ~AndroidSurfaceGL() override;

  bool IsOffscreenContextValid() const;

  // |shell::AndroidSurface|
  bool IsValid() const override;

  // |shell::AndroidSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  // |shell::AndroidSurface|
  void TeardownOnScreenContext() override;

  // |shell::AndroidSurface|
  bool OnScreenSurfaceResize(const SkISize& size) const override;

  // |shell::AndroidSurface|
  bool ResourceContextMakeCurrent() override;

  // |shell::AndroidSurface|
  bool ResourceContextClearCurrent() override;

  // |shell::AndroidSurface|
  bool SetNativeWindow(fml::RefPtr<AndroidNativeWindow> window) override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextMakeCurrent() override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override;

  // |shell::GPUSurfaceGLDelegate|
  bool GLContextPresent() override;

  // |shell::GPUSurfaceGLDelegate|
  intptr_t GLContextFBO() const override;

 private:
  fml::RefPtr<AndroidContextGL> onscreen_context_;
  fml::RefPtr<AndroidContextGL> offscreen_context_;
  sk_sp<GrContext> gr_context_;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceGL);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_GL_H_
