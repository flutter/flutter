// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_GL_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_GL_IMPELLER_H_

#include "flutter/fml/macros.h"
#include "flutter/impeller/renderer/context.h"
#include "flutter/impeller/toolkit/egl/display.h"
#include "flutter/shell/gpu/gpu_surface_gl_delegate.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"
#include "flutter/shell/platform/android/surface/android_surface.h"

namespace flutter {

class AndroidSurfaceGLImpeller final : public GPUSurfaceGLDelegate,
                                       public AndroidSurface {
 public:
  AndroidSurfaceGLImpeller(
      const std::shared_ptr<AndroidContext>& android_context,
      std::shared_ptr<PlatformViewAndroidJNI> jni_facade);

  // |AndroidSurface|
  ~AndroidSurfaceGLImpeller() override;

  // |AndroidSurface|
  bool IsValid() const override;

  // |AndroidSurface|
  std::unique_ptr<Surface> CreateGPUSurface(
      GrDirectContext* gr_context) override;

  // |AndroidSurface|
  void TeardownOnScreenContext() override;

  // |AndroidSurface|
  bool OnScreenSurfaceResize(const SkISize& size) override;

  // |AndroidSurface|
  bool ResourceContextMakeCurrent() override;

  // |AndroidSurface|
  bool ResourceContextClearCurrent() override;

  // |AndroidSurface|
  bool SetNativeWindow(fml::RefPtr<AndroidNativeWindow> window) override;

  // |AndroidSurface|
  std::unique_ptr<Surface> CreateSnapshotSurface() override;

  // |AndroidSurface|
  std::shared_ptr<impeller::Context> GetImpellerContext() override;

  // |GPUSurfaceGLDelegate|
  std::unique_ptr<GLContextResult> GLContextMakeCurrent() override;

  // |GPUSurfaceGLDelegate|
  bool GLContextClearCurrent() override;

  // |GPUSurfaceGLDelegate|
  SurfaceFrame::FramebufferInfo GLContextFramebufferInfo() const override;

  // |GPUSurfaceGLDelegate|
  void GLContextSetDamageRegion(const std::optional<SkIRect>& region) override;

  // |GPUSurfaceGLDelegate|
  bool GLContextPresent(const GLPresentInfo& present_info) override;

  // |GPUSurfaceGLDelegate|
  intptr_t GLContextFBO(GLFrameInfo frame_info) const override;

  // |GPUSurfaceGLDelegate|
  sk_sp<const GrGLInterface> GetGLInterface() const override;

 private:
  class ReactorWorker;

  std::shared_ptr<ReactorWorker> reactor_worker_;
  std::unique_ptr<impeller::egl::Display> display_;
  std::unique_ptr<impeller::egl::Config> onscreen_config_;
  std::unique_ptr<impeller::egl::Config> offscreen_config_;
  std::unique_ptr<impeller::egl::Surface> onscreen_surface_;
  std::unique_ptr<impeller::egl::Surface> offscreen_surface_;
  std::unique_ptr<impeller::egl::Context> onscreen_context_;
  std::unique_ptr<impeller::egl::Context> offscreen_context_;
  std::shared_ptr<impeller::Context> impeller_context_;
  fml::RefPtr<AndroidNativeWindow> native_window_;

  bool is_valid_ = false;

  bool OnGLContextMakeCurrent();

  bool RecreateOnscreenSurfaceAndMakeOnscreenContextCurrent();

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceGLImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_GL_IMPELLER_H_
