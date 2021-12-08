// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "GoldenPlatformViewTests.h"

static const NSInteger kSecondsToWaitForPlatformView = 30;

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

@interface NonFullScreenFlutterViewPlatformViewUITests : GoldenPlatformViewTests

@end

@implementation NonFullScreenFlutterViewPlatformViewUITests

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager =
      [[GoldenTestManager alloc] initWithLaunchArg:@"--non-full-screen-flutter-view-platform-view"];
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

@interface PlatformViewWithOtherBackdropFilterTests : GoldenPlatformViewTests

@end

@implementation PlatformViewWithOtherBackdropFilterTests

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager =
      [[GoldenTestManager alloc] initWithLaunchArg:@"--platform-view-with-other-backdrop-filter"];
  return [super initWithManager:manager invocation:invocation];
}

- (void)testPlatformView {
  [self checkPlatformViewGolden];
}

@end

@interface TwoPlatformViewsWithOtherBackDropFilterTests : GoldenPlatformViewTests

@end

@implementation TwoPlatformViewsWithOtherBackDropFilterTests

- (instancetype)initWithInvocation:(NSInvocation*)invocation {
  GoldenTestManager* manager = [[GoldenTestManager alloc]
      initWithLaunchArg:@"--two-platform-views-with-other-backdrop-filter"];
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

@interface PlatformViewWithContinuousTexture : XCTestCase

@end

@implementation PlatformViewWithContinuousTexture

- (void)setUp {
  self.continueAfterFailure = NO;
}

- (void)testPlatformViewWithContinuousTexture {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments =
      @[ @"--platform-view-with-continuous-texture", @"--with-continuous-texture" ];
  [app launch];

  XCUIElement* platformView = app.textViews.firstMatch;
  BOOL exists = [platformView waitForExistenceWithTimeout:kSecondsToWaitForPlatformView];
  if (!exists) {
    XCTFail(@"It took longer than %@ second to find the platform view."
            @"There might be issues with the platform view's construction,"
            @"or with how the scenario is built.",
            @(kSecondsToWaitForPlatformView));
  }

  XCTAssertNotNil(platformView);
}

@end

@interface PlatformViewScrollingUnderWidget : XCTestCase

@end

@implementation PlatformViewScrollingUnderWidget

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
}

- (void)testPlatformViewScrollingUnderWidget {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments =
      @[ @"--platform-view-scrolling-under-widget", @"--with-continuous-texture" ];
  [app launch];

  XCUIElement* platformView = app.textViews.firstMatch;
  BOOL exists = [platformView waitForExistenceWithTimeout:kSecondsToWaitForPlatformView];
  if (!exists) {
    XCTFail(@"It took longer than %@ second to find the platform view."
            @"There might be issues with the platform view's construction,"
            @"or with how the scenario is built.",
            @(kSecondsToWaitForPlatformView));
  }

  // Wait and let the scenario app scroll a bit.
  XCTWaiterResult waitResult = [XCTWaiter
      waitForExpectations:@[ [[XCTestExpectation alloc] initWithDescription:@"Wait for 5 seconds"] ]
                  timeout:5];
  // If the waiter is not interrupted, we know the app is in a valid state after timeout, thus the
  // test passes.
  XCTAssert(waitResult != XCTWaiterResultInterrupted);
}

@end
