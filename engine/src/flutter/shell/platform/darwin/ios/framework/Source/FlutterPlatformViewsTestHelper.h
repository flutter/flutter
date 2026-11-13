// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWSTESTHELPER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWSTESTHELPER_H_

#import <Foundation/Foundation.h>

#include <memory>

#include "flutter/flow/surface_frame.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterFMLTaskRunners.h"
#import "flutter/shell/platform/darwin/ios/ios_context.h"

@class FlutterPlatformViewsController;

namespace flutter {
namespace testing {

/**
 * An IOSContext fake for tests that do not need a real GPU context.
 */
class FakeIOSContext : public IOSContext {
 public:
  FakeIOSContext() = default;
  ~FakeIOSContext() override = default;

  // |IOSContext|
  std::unique_ptr<Texture> CreateExternalTexture(int64_t texture_id,
                                                 NSObject<FlutterTexture>* texture) override;
};

/**
 * Returns a task runner mapped to the current message loop on this thread.
 */
FlutterFMLTaskRunner* GetDefaultTaskRunner();

/**
 * Returns a task runners wrapper where all task runners map to the default test thread runner.
 */
FlutterFMLTaskRunners* CreateTestTaskRunners(NSString* label);

/**
 * Returns a FlutterPlatformViewsController pre-configured for testing with the default task runner.
 */
FlutterPlatformViewsController* CreateTestPlatformViewsController(NSString* label);

/**
 * Returns an 800x600 test SurfaceFrame.
 *
 * The SurfaceFrame's encode and submit callbacks succeed and its canvas is a display list builder,
 * so the frame can be sliced for platform views without a GPU surface.
 */
std::unique_ptr<SurfaceFrame> CreateTestSurfaceFrame();

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_FLUTTERPLATFORMVIEWSTESTHELPER_H_
