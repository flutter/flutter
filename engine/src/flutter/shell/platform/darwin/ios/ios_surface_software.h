// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_SOFTWARE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_SOFTWARE_H_

#include "flutter/shell/gpu/gpu_surface_software.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"
#include "lib/fxl/macros.h"

namespace shell {

class IOSSurfaceSoftware : public IOSSurface,
                           public GPUSurfaceSoftwareDelegate {
 public:
  IOSSurfaceSoftware(PlatformView::SurfaceConfig surface_config,
                     CALayer* layer);

  ~IOSSurfaceSoftware() override;

  bool IsValid() const override;

  bool ResourceContextMakeCurrent() override;

  void UpdateStorageSizeIfNecessary() override;

  std::unique_ptr<Surface> CreateGPUSurface() override;

  sk_sp<SkSurface> AcquireBackingStore(const SkISize& size) override;

  bool PresentBackingStore(sk_sp<SkSurface> backing_store) override;

 private:
  sk_sp<SkSurface> sk_surface_;

  FXL_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceSoftware);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_SOFTWARE_H_
