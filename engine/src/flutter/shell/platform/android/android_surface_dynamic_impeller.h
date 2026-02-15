// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_DYNAMIC_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_DYNAMIC_IMPELLER_H_

#include "flutter/fml/concurrent_message_loop.h"
#include "flutter/fml/macros.h"
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/renderer/backend/vulkan/surface_context_vk.h"
#include "flutter/shell/platform/android/android_context_vk_impeller.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"
#include "flutter/shell/platform/android/surface/android_surface.h"
#include "shell/gpu/gpu_surface_vulkan_impeller.h"
#include "shell/platform/android/android_context_dynamic_impeller.h"
#include "shell/platform/android/android_surface_gl_impeller.h"
#include "shell/platform/android/android_surface_vk_impeller.h"

namespace flutter {

/// @brief An Impeller Android surface class that dynamically creates either an
/// [AndroidSurfaceVKImpeller] or an [AndroidSurfaceGLImpeller].
///
/// The backing surface is created the first time [CreateGPUSurface] is called.
class AndroidSurfaceDynamicImpeller : public AndroidSurface {
 public:
  explicit AndroidSurfaceDynamicImpeller(
      std::shared_ptr<AndroidContextDynamicImpeller>& android_context);

  ~AndroidSurfaceDynamicImpeller() override;

  // |AndroidSurface|
  bool IsValid() const override;

  // |AndroidSurface|
  std::unique_ptr<Surface> CreateGPUSurface(
      GrDirectContext* gr_context) override;

  // |AndroidSurface|
  void TeardownOnScreenContext() override;

  // |AndroidSurface|
  bool OnScreenSurfaceResize(const DlISize& size) override;

  // |AndroidSurface|
  bool ResourceContextMakeCurrent() override;

  // |AndroidSurface|
  bool ResourceContextClearCurrent() override;

  // |AndroidSurface|
  std::shared_ptr<impeller::Context> GetImpellerContext() override;

  // |AndroidSurface|
  bool SetNativeWindow(
      fml::RefPtr<AndroidNativeWindow> window,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade) override;

  // |AndroidSurface|
  std::unique_ptr<Surface> CreateSnapshotSurface() override;

  // |AndroidSurface|
  void SetupImpellerSurface() override;

 private:
  std::shared_ptr<AndroidContextDynamicImpeller> android_context_;
  std::unique_ptr<AndroidSurfaceVKImpeller> vulkan_surface_;
  std::unique_ptr<AndroidSurfaceGLImpeller> gl_surface_;
  fml::RefPtr<AndroidNativeWindow> window_;
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceDynamicImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_DYNAMIC_IMPELLER_H_
