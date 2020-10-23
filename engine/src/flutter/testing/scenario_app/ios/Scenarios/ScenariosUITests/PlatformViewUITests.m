// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "GoldenPlatformViewTests.h"

@interface PlatformViewUITests : GoldenPlatformViewTests

@end

@implementation PlatformViewUITests

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager = [[GoldenTestManager alloc] initWithLaunchArg:@"--platform-view"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)testPlatformView {
  [self checkPlatformViewGolden];
}

@end

@interface MultiplePlatformViewsTest : GoldenPlatformViewTests

@end

@implementation MultiplePlatformViewsTest

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager =
      [[GoldenTestManager alloc] initWithLaunchArg:@"--platform-view-multiple"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)testPlatformView {
  [self checkPlatformViewGolden];
}

@end

@interface MultiplePlatformViewsBackgroundForegroundTest : GoldenPlatformViewTests

@end

@implementation MultiplePlatformViewsBackgroundForegroundTest

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager = [[GoldenTestManager alloc]
      initWithLaunchArg:@"--platform-view-multiple-background-foreground"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)testPlatformView {
  [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
  [self.application activate];
  [self checkPlatformViewGolden];
}

@end

// Clip Rect Tests
@interface PlatformViewMutationClipRectTests : GoldenPlatformViewTests

@end

@implementation PlatformViewMutationClipRectTests

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager =
      [[GoldenTestManager alloc] initWithLaunchArg:@"--platform-view-cliprect"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)testPlatformView {
  [self checkPlatformViewGolden];
}

@end

@interface PlatformViewMutationClipRRectTests : GoldenPlatformViewTests

@end

@implementation PlatformViewMutationClipRRectTests

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager =
      [[GoldenTestManager alloc] initWithLaunchArg:@"--platform-view-cliprrect"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)testPlatformView {
  [self checkPlatformViewGolden];
}

@end

@interface PlatformViewMutationClipPathTests : GoldenPlatformViewTests

@end

@implementation PlatformViewMutationClipPathTests

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager =
      [[GoldenTestManager alloc] initWithLaunchArg:@"--platform-view-clippath"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)testPlatformView {
  [self checkPlatformViewGolden];
}

@end

@interface PlatformViewMutationTransformTests : GoldenPlatformViewTests

@end

@implementation PlatformViewMutationTransformTests

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager =
      [[GoldenTestManager alloc] initWithLaunchArg:@"--platform-view-transform"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)testPlatformView {
  [self checkPlatformViewGolden];
}

@end

@interface PlatformViewMutationOpacityTests : GoldenPlatformViewTests

@end

@implementation PlatformViewMutationOpacityTests

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager =
      [[GoldenTestManager alloc] initWithLaunchArg:@"--platform-view-opacity"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)testPlatformView {
  [self checkPlatformViewGolden];
}

@end

@interface PlatformViewRotation : GoldenPlatformViewTests
@end

@implementation PlatformViewRotation
- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager =
      [[GoldenTestManager alloc] initWithLaunchArg:@"--platform-view-rotate"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)tearDown {
  XCUIDevice.sharedDevice.orientation = UIDeviceOrientationPortrait;
  [super tearDown];
}

- (void)testPlatformView {
  XCUIDevice.sharedDevice.orientation = UIDeviceOrientationLandscapeLeft;
  [self checkPlatformViewGolden];
}
@end
