// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

FLUTTER_ASSERT_NOT_ARC

@interface VSyncClient (Testing)

- (CADisplayLink*)getDisplayLink;

@end

@interface FlutterViewController (Testing)

@property(nonatomic, assign) double targetViewInsetBottom;
@property(nonatomic, retain) VSyncClient* keyboardAnimationVSyncClient;

- (void)setupKeyboardAnimationVsyncClient;

@end

@interface FlutterViewControllerTest_mrc : XCTestCase
@end

@implementation FlutterViewControllerTest_mrc

- (void)testSetupKeyboardAnimationVsyncClientWillCreateNewVsyncClientForFlutterViewController {
  id bundleMock = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([bundleMock objectForInfoDictionaryKey:@"CADisableMinimumFrameDurationOnPhone"])
      .andReturn(@YES);
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController setupKeyboardAnimationVsyncClient];
  XCTAssertNotNil(viewController.keyboardAnimationVSyncClient);
  CADisplayLink* link = [viewController.keyboardAnimationVSyncClient getDisplayLink];
  XCTAssertNotNil(link);
  if (@available(iOS 15.0, *)) {
    XCTAssertEqual(link.preferredFrameRateRange.maximum, maxFrameRate);
    XCTAssertEqual(link.preferredFrameRateRange.preferred, maxFrameRate);
    XCTAssertEqual(link.preferredFrameRateRange.minimum, maxFrameRate / 2);
  } else {
    XCTAssertEqual(link.preferredFramesPerSecond, maxFrameRate);
  }
}

@end
