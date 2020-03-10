// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

#include <Foundation/Foundation.h>
#include <QuartzCore/CAEAGLLayer.h>
#include <QuartzCore/CAMetalLayer.h>

#include "flutter/fml/logging.h"

namespace flutter {

bool ShouldUseSoftwareRenderer() {
  return [[[NSProcessInfo processInfo] arguments] containsObject:@"--force-software"];
}

bool ShouldUseMetalRenderer() {
  // If there is a command line argument that says Metal should not be used, that takes precedence
  // over everything else. This allows disabling Metal on a per run basis to check for regressions
  // on an application that has otherwise opted into Metal on an iOS version that supports it.
  if ([[[NSProcessInfo processInfo] arguments] containsObject:@"--disable-metal"]) {
    return false;
  }

  // If the application wants to use metal on a per run basis with disregard for version checks or
  // plist based opt ins, respect that opinion. This allows selectively testing features on older
  // version of iOS than those explicitly stated as being supported.
  if ([[[NSProcessInfo processInfo] arguments] containsObject:@"--force-metal"]) {
    return true;
  }

  // This is just a version we picked that is easy to support and has all necessary Metal features.
  bool ios_version_supports_metal = false;
  // TODO(52356): Update this to be the version selected for release.
  if (@available(iOS 11.0, *)) {
    ios_version_supports_metal = true;
  }

  // The application must opt-in by default to use Metal without command line flags.
  bool application_opts_into_metal =
      [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"io.flutter.metal_preview"] boolValue];

  return ios_version_supports_metal && application_opts_into_metal;
}

IOSRenderingAPI GetRenderingAPIForProcess() {
#if TARGET_IPHONE_SIMULATOR
  return IOSRenderingAPI::kSoftware;
#endif  // TARGET_IPHONE_SIMULATOR

#if FLUTTER_SHELL_ENABLE_METAL
  static bool should_use_software = ShouldUseSoftwareRenderer();
  if (should_use_software) {
    return IOSRenderingAPI::kSoftware;
  }
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
