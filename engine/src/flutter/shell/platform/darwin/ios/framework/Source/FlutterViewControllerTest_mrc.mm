// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

FLUTTER_ASSERT_NOT_ARC

@interface UITouch ()

@property(nonatomic, readwrite) UITouchPhase phase;

@end

@interface VSyncClient (Testing)

- (CADisplayLink*)getDisplayLink;

@end

@interface FlutterViewController (Testing)

@property(nonatomic, assign) double targetViewInsetBottom;
@property(nonatomic, retain) VSyncClient* keyboardAnimationVSyncClient;

@property(nonatomic, retain) VSyncClient* touchRateCorrectionVSyncClient;

- (void)createTouchRateCorrectionVSyncClientIfNeeded;
- (void)setUpKeyboardAnimationVsyncClient:
    (FlutterKeyboardAnimationCallback)keyboardAnimationCallback;
- (void)startKeyBoardAnimation:(NSTimeInterval)duration;
- (void)triggerTouchRateCorrectionIfNeeded:(NSSet*)touches;

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
  FlutterKeyboardAnimationCallback callback = ^(fml::TimePoint targetTime) {
  };
  [viewController setUpKeyboardAnimationVsyncClient:callback];
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

- (void)
    testCreateTouchRateCorrectionVSyncClientWillCreateVsyncClientWhenRefreshRateIsLargerThan60HZ {
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController createTouchRateCorrectionVSyncClientIfNeeded];
  XCTAssertNotNil(viewController.touchRateCorrectionVSyncClient);
}

- (void)testCreateTouchRateCorrectionVSyncClientWillNotCreateNewVSyncClientWhenClientAlreadyExists {
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];

  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController createTouchRateCorrectionVSyncClientIfNeeded];
  VSyncClient* clientBefore = viewController.touchRateCorrectionVSyncClient;
  XCTAssertNotNil(clientBefore);

  [viewController createTouchRateCorrectionVSyncClientIfNeeded];
  VSyncClient* clientAfter = viewController.touchRateCorrectionVSyncClient;
  XCTAssertNotNil(clientAfter);

  XCTAssertTrue(clientBefore == clientAfter);
}

- (void)testCreateTouchRateCorrectionVSyncClientWillNotCreateVsyncClientWhenRefreshRateIs60HZ {
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 60;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController createTouchRateCorrectionVSyncClientIfNeeded];
  XCTAssertNil(viewController.touchRateCorrectionVSyncClient);
}

- (void)testTriggerTouchRateCorrectionVSyncClientCorrectly {
  id mockDisplayLinkManager = [OCMockObject mockForClass:[DisplayLinkManager class]];
  double maxFrameRate = 120;
  [[[mockDisplayLinkManager stub] andReturnValue:@(maxFrameRate)] displayRefreshRate];
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController loadView];
  [viewController viewDidLoad];

  VSyncClient* client = viewController.touchRateCorrectionVSyncClient;
  CADisplayLink* link = [client getDisplayLink];

  UITouch* fakeTouchBegan = [[UITouch alloc] init];
  fakeTouchBegan.phase = UITouchPhaseBegan;

  UITouch* fakeTouchMove = [[UITouch alloc] init];
  fakeTouchMove.phase = UITouchPhaseMoved;

  UITouch* fakeTouchEnd = [[UITouch alloc] init];
  fakeTouchEnd.phase = UITouchPhaseEnded;

  UITouch* fakeTouchCancelled = [[UITouch alloc] init];
  fakeTouchCancelled.phase = UITouchPhaseCancelled;

  [viewController
      triggerTouchRateCorrectionIfNeeded:[[NSSet alloc] initWithObjects:fakeTouchBegan, nil]];
  XCTAssertFalse(link.isPaused);

  [viewController
      triggerTouchRateCorrectionIfNeeded:[[NSSet alloc] initWithObjects:fakeTouchEnd, nil]];
  XCTAssertTrue(link.isPaused);

  [viewController
      triggerTouchRateCorrectionIfNeeded:[[NSSet alloc] initWithObjects:fakeTouchMove, nil]];
  XCTAssertFalse(link.isPaused);

  [viewController
      triggerTouchRateCorrectionIfNeeded:[[NSSet alloc] initWithObjects:fakeTouchCancelled, nil]];
  XCTAssertTrue(link.isPaused);

  [viewController
      triggerTouchRateCorrectionIfNeeded:[[NSSet alloc]
                                             initWithObjects:fakeTouchBegan, fakeTouchEnd, nil]];
  XCTAssertFalse(link.isPaused);

  [viewController
      triggerTouchRateCorrectionIfNeeded:[[NSSet alloc] initWithObjects:fakeTouchEnd,
                                                                        fakeTouchCancelled, nil]];
  XCTAssertTrue(link.isPaused);

  [viewController
      triggerTouchRateCorrectionIfNeeded:[[NSSet alloc]
                                             initWithObjects:fakeTouchMove, fakeTouchEnd, nil]];
  XCTAssertFalse(link.isPaused);
}

- (void)testFlutterViewControllerStartKeyboardAnimationWillCreateVsyncClientCorrectly {
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  viewController.targetViewInsetBottom = 100;
  [viewController startKeyBoardAnimation:0.25];
  XCTAssertNotNil(viewController.keyboardAnimationVSyncClient);
}

- (void)
    testSetupKeyboardAnimationVsyncClientWillNotCreateNewVsyncClientWhenKeyboardAnimationCallbackIsNil {
  FlutterEngine* engine = [[FlutterEngine alloc] init];
  [engine runWithEntrypoint:nil];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];
  [viewController setUpKeyboardAnimationVsyncClient:nil];
  XCTAssertNil(viewController.keyboardAnimationVSyncClient);
}

@end
