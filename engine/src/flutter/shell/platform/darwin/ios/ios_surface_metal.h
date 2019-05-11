// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_H_

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/gpu/gpu_surface_metal.h"
#include "flutter/shell/platform/darwin/ios/ios_surface.h"

@class CAMetalLayer;

namespace flutter {

class IOSSurfaceMetal final : public IOSSurface {
 public:
  IOSSurfaceMetal(fml::scoped_nsobject<CAMetalLayer> layer,
                  FlutterPlatformViewsController* platform_views_controller);

  ~IOSSurfaceMetal() override;

 private:
  fml::scoped_nsobject<CAMetalLayer> layer_;

  // |IOSSurface|
  bool IsValid() const override;

  // |IOSSurface|
  bool ResourceContextMakeCurrent() override;

  // |IOSSurface|
  void UpdateStorageSizeIfNecessary() override;

  // |IOSSurface|
  std::unique_ptr<Surface> CreateGPUSurface() override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceMetal);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_H_
