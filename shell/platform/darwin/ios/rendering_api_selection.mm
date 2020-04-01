// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

#include <Foundation/Foundation.h>
#include <QuartzCore/CAEAGLLayer.h>
#include <QuartzCore/CAMetalLayer.h>
#if FLUTTER_SHELL_ENABLE_METAL
#include <Metal/Metal.h>
#endif  // FLUTTER_SHELL_ENABLE_METAL

#include "flutter/fml/logging.h"

namespace flutter {

#if FLUTTER_SHELL_ENABLE_METAL
bool ShouldUseMetalRenderer() {
  // Flutter supports Metal on all devices with Apple A7 SoC or above that have been updated to or
  // past iOS 10.0. The processor was selected as it is the first version at which Metal was
  // supported. The iOS version floor was selected due to the availability of features used by Skia.
  bool ios_version_supports_metal = false;
  if (@available(iOS 10.0, *)) {
    auto device = MTLCreateSystemDefaultDevice();
    ios_version_supports_metal = [device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily1_v3];
  }
  return ios_version_supports_metal;
}
#endif  // FLUTTER_SHELL_ENABLE_METAL

IOSRenderingAPI GetRenderingAPIForProcess() {
#if TARGET_IPHONE_SIMULATOR
  return IOSRenderingAPI::kSoftware;
#endif  // TARGET_IPHONE_SIMULATOR

#if FLUTTER_SHELL_ENABLE_METAL
  static bool should_use_metal = ShouldUseMetalRenderer();
  if (should_use_metal) {
    return IOSRenderingAPI::kMetal;
  }
#endif  // FLUTTER_SHELL_ENABLE_METAL
  return IOSRenderingAPI::kOpenGLES;
}

Class GetCoreAnimationLayerClassForRenderingAPI(IOSRenderingAPI rendering_api) {
  switch (rendering_api) {
    case IOSRenderingAPI::kSoftware:
      return [CALayer class];
    case IOSRenderingAPI::kOpenGLES:
      return [CAEAGLLayer class];
#if !TARGET_IPHONE_SIMULATOR
    case IOSRenderingAPI::kMetal:
      return [CAMetalLayer class];
#endif  // !TARGET_IPHONE_SIMULATOR
    default:
      break;
  }
  FML_CHECK(false) << "Unknown client rendering API";
  return [CALayer class];
}

}  // namespace flutter
