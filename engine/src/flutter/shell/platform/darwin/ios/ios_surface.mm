// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_surface.h"

#include <memory>

#include "flutter/shell/platform/darwin/ios/ios_surface_gl.h"
#include "flutter/shell/platform/darwin/ios/ios_surface_software.h"

namespace shell {

// The name of the Info.plist flag to enable the embedded iOS views preview.
const char* const kEmbeddedViewsPreview = "io.flutter.embedded_views_preview";

bool IsIosEmbeddedViewsPreviewEnabled() {
  return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@(kEmbeddedViewsPreview)] boolValue];
}

IOSSurface::IOSSurface(FlutterPlatformViewsController* platform_views_controller)
    : platform_views_controller_(platform_views_controller) {}

IOSSurface::~IOSSurface() = default;

FlutterPlatformViewsController* IOSSurface::GetPlatformViewsController() {
  return platform_views_controller_;
}
}  // namespace shell
