// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_

#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_view.h"
#include "lib/fxl/macros.h"

@class CALayer;

namespace shell {

class IOSSurface {
 public:
  static std::unique_ptr<IOSSurface> Create(
      PlatformView::SurfaceConfig surface_config,
      CALayer* layer);

  IOSSurface(PlatformView::SurfaceConfig surface_config, CALayer* layer);

  CALayer* GetLayer() const;

  PlatformView::SurfaceConfig GetSurfaceConfig() const;

  virtual ~IOSSurface();

  virtual bool IsValid() const = 0;

  virtual bool ResourceContextMakeCurrent() = 0;

  virtual void UpdateStorageSizeIfNecessary() = 0;

  virtual std::unique_ptr<Surface> CreateGPUSurface() = 0;

 public:
  PlatformView::SurfaceConfig surface_config_;
  fml::scoped_nsobject<CALayer> layer_;

  FXL_DISALLOW_COPY_AND_ASSIGN(IOSSurface);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_H_
