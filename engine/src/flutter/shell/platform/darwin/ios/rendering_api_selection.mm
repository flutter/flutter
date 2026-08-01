// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

#include <Foundation/Foundation.h>
#include <Metal/Metal.h>
#include <QuartzCore/CAEAGLLayer.h>
#import <QuartzCore/CAMetalLayer.h>
#import <TargetConditionals.h>

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/common/InternalFlutterSwiftCommon/InternalFlutterSwiftCommon.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterMetalLayer.h"

FLUTTER_ASSERT_ARC

namespace flutter {
namespace {

bool IsMetalAvailable() {
  bool ios_version_supports_metal = false;
  if (@available(iOS METAL_IOS_VERSION_BASELINE, *)) {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    ios_version_supports_metal = [device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily1_v3];
  }
  return ios_version_supports_metal;
}

}  // namespace

IOSRenderingAPI GetRenderingAPIForProcess() {
  static bool metal_available = IsMetalAvailable();
  if (metal_available) {
    return IOSRenderingAPI::kMetal;
  }
  FML_CHECK(false) << "Metal is unavailable. On a simulator this means the host environment "
                      "does not expose a Metal device; enabling GPU passthrough may fix this.";
  FML_UNREACHABLE();
}

Class GetCoreAnimationLayerClassForRenderingAPI(IOSRenderingAPI rendering_api) {
  switch (rendering_api) {
    case IOSRenderingAPI::kMetal:
      if (@available(iOS METAL_IOS_VERSION_BASELINE, *)) {
        if ([FlutterMetalLayer enabled]) {
          return [FlutterMetalLayer class];
        } else {
          return [CAMetalLayer class];
        }
      }
      FML_CHECK(false) << "Metal availability should already have been checked";
      break;
    default:
      break;
  }
  FML_CHECK(false) << "Unknown client rendering API";
  return [CALayer class];
}

}  // namespace flutter
