// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface_metal.h"
#include "flutter/shell/gpu/gpu_surface_metal.h"

namespace flutter {

IOSSurfaceMetal::IOSSurfaceMetal(fml::scoped_nsobject<CAMetalLayer> layer,
                                 FlutterPlatformViewsController* platform_views_controller)
    : IOSSurface(platform_views_controller), layer_(std::move(layer)) {}

IOSSurfaceMetal::~IOSSurfaceMetal() = default;

// |IOSSurface|
bool IOSSurfaceMetal::IsValid() const {
  return layer_;
}

// |IOSSurface|
bool IOSSurfaceMetal::ResourceContextMakeCurrent() {
  return false;
}

// |IOSSurface|
void IOSSurfaceMetal::UpdateStorageSizeIfNecessary() {}

// |IOSSurface|
std::unique_ptr<Surface> IOSSurfaceMetal::CreateGPUSurface() {
  return std::make_unique<GPUSurfaceMetal>(layer_);
}

}  // namespace flutter
