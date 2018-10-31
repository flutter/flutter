// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface.h"

#include <memory>

#include "flutter/shell/platform/darwin/ios/ios_surface_gl.h"
#include "flutter/shell/platform/darwin/ios/ios_surface_software.h"

namespace shell {

IOSSurface::IOSSurface(FlutterPlatformViewsController& platform_views_controller)
    : platform_views_controller_(platform_views_controller) {}

IOSSurface::~IOSSurface() = default;

FlutterPlatformViewsController& IOSSurface::GetPlatformViewsController() {
  return platform_views_controller_;
}
}  // namespace shell
