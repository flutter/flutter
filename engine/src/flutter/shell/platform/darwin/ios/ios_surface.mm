// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface.h"

#include <flutter/shell/platform/darwin/ios/ios_surface_gl.h>
#include <flutter/shell/platform/darwin/ios/ios_surface_software.h>
#include <memory>

@class CALayer;
@class CAEAGLLayer;

namespace shell {

std::unique_ptr<IOSSurface> IOSSurface::Create(PlatformView::SurfaceConfig surface_config,
                                               CALayer* layer) {
  // Check if we can use OpenGL.
  if ([layer isKindOfClass:[CAEAGLLayer class]]) {
    return std::make_unique<IOSSurfaceGL>(surface_config, reinterpret_cast<CAEAGLLayer*>(layer));
  }

  // If we ever support the metal rendering API, a check for CAMetalLayer would
  // go here.

  // Finally, fallback to software rendering.
  return std::make_unique<IOSSurfaceSoftware>(surface_config, layer);
}

IOSSurface::IOSSurface(PlatformView::SurfaceConfig surface_config, CALayer* layer)
    : surface_config_(surface_config), layer_([layer retain]) {}

IOSSurface::~IOSSurface() = default;

CALayer* IOSSurface::GetLayer() const {
  return layer_;
}

PlatformView::SurfaceConfig IOSSurface::GetSurfaceConfig() const {
  return surface_config_;
}

}  // namespace shell
