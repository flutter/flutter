// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

#include <Foundation/Foundation.h>
#include <QuartzCore/CAEAGLLayer.h>
#import <QuartzCore/CAMetalLayer.h>
#if SHELL_ENABLE_METAL
#include <Metal/Metal.h>
#endif  // SHELL_ENABLE_METAL
#import <TargetConditionals.h>

#include "flutter/fml/logging.h"

namespace flutter {

#if SHELL_ENABLE_METAL
bool ShouldUseMetalRenderer() {
  bool ios_version_supports_metal = false;
  if (@available(iOS METAL_IOS_VERSION_BASELINE, *)) {
    auto device = MTLCreateSystemDefaultDevice();
    ios_version_supports_metal = [device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily1_v3];
    [device release];
  }
  return ios_version_supports_metal;
}
#endif  // SHELL_ENABLE_METAL

IOSRenderingAPI GetRenderingAPIForProcess(bool force_software) {
#if TARGET_OS_SIMULATOR
  if (force_software) {
    return IOSRenderingAPI::kSoftware;
  }
#else
  if (force_software) {
    FML_LOG(WARNING) << "The --enable-software-rendering is only supported on Simulator targets "
                        "and will be ignored.";
  }
#endif  // TARGET_OS_SIMULATOR

#if SHELL_ENABLE_METAL
  static bool should_use_metal = ShouldUseMetalRenderer();
  if (should_use_metal) {
    return IOSRenderingAPI::kMetal;
  }
#endif  // SHELL_ENABLE_METAL

  // OpenGL will be emulated using software rendering by Apple on the simulator, so we use the
  // Skia software rendering since it performs a little better than the emulated OpenGL.
#if TARGET_OS_SIMULATOR
  return IOSRenderingAPI::kSoftware;
#else
  return IOSRenderingAPI::kOpenGLES;
#endif  // TARGET_OS_SIMULATOR
}

Class GetCoreAnimationLayerClassForRenderingAPI(IOSRenderingAPI rendering_api) {
  switch (rendering_api) {
    case IOSRenderingAPI::kSoftware:
      return [CALayer class];
    case IOSRenderingAPI::kOpenGLES:
      return [CAEAGLLayer class];
    case IOSRenderingAPI::kMetal:
      if (@available(iOS METAL_IOS_VERSION_BASELINE, *)) {
        return [CAMetalLayer class];
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
