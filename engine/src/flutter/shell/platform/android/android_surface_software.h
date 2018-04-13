// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_SOFTWARE_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_SOFTWARE_H_

#include "flutter/fml/platform/android/jni_weak_ref.h"
#include "flutter/fml/platform/android/scoped_java_ref.h"
#include "flutter/shell/gpu/gpu_surface_software.h"
#include "flutter/shell/platform/android/android_surface.h"
#include "lib/fxl/macros.h"

namespace shell {

class AndroidSurfaceSoftware final : public AndroidSurface,
                                     public GPUSurfaceSoftwareDelegate {
 public:
  AndroidSurfaceSoftware();

  ~AndroidSurfaceSoftware() override;

  // |shell::AndroidSurface|
  bool IsValid() const override;

  // |shell::AndroidSurface|
  bool ResourceContextMakeCurrent() override;

  // |shell::AndroidSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  // |shell::AndroidSurface|
  void TeardownOnScreenContext() override;

  // |shell::AndroidSurface|
  bool OnScreenSurfaceResize(const SkISize& size) const override;

  // |shell::AndroidSurface|
  bool SetNativeWindow(fxl::RefPtr<AndroidNativeWindow> window) override;

  // |shell::GPUSurfaceSoftwareDelegate|
  sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) override;

  // |shell::GPUSurfaceSoftwareDelegate|
  bool PresentBackingStore(sk_sp<SkSurface> backing_store) override;

 private:
  sk_sp<SkSurface> sk_surface_;
  fxl::RefPtr<AndroidNativeWindow> native_window_;
  SkColorType target_color_type_;
  SkAlphaType target_alpha_type_;

  FXL_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceSoftware);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_SOFTWARE_H_
