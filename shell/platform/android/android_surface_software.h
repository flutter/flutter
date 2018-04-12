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

class AndroidSurfaceSoftware : public AndroidSurface,
                               public GPUSurfaceSoftwareDelegate {
 public:
  AndroidSurfaceSoftware();

  ~AndroidSurfaceSoftware() override;

  bool IsValid() const override;

  bool ResourceContextMakeCurrent() override;

  std::unique_ptr<Surface> CreateGPUSurface() override;

  sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) override;

  bool PresentBackingStore(sk_sp<SkSurface> backing_store) override;

  void TeardownOnScreenContext() override;

  SkISize OnScreenSurfaceSize() const override;

  bool OnScreenSurfaceResize(const SkISize& size) const override;

  bool SetNativeWindow(fxl::RefPtr<AndroidNativeWindow> window,
                       PlatformView::SurfaceConfig config) override;

 private:
  sk_sp<SkSurface> sk_surface_;

  fxl::RefPtr<AndroidNativeWindow> native_window_;
  SkColorType target_color_type_;
  SkAlphaType target_alpha_type_;

  FXL_DISALLOW_COPY_AND_ASSIGN(AndroidSurfaceSoftware);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_SURFACE_SOFTWARE_H_
