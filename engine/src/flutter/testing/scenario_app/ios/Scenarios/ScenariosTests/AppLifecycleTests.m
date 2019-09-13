// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>
#import "ScreenBeforeFlutter.h"

@interface AppLifecycleTests : XCTestCase
@end

@implementation AppLifecycleTests

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
}

- (void)testLifecycleChannel {
  XCTestExpectation* engineStartedExpectation = [self expectationWithDescription:@"Engine started"];

  // Let the engine finish booting (at the end of which the channels are properly set-up) before
  // moving onto the next step of showing the next view controller.
  ScreenBeforeFlutter* rootVC = [[ScreenBeforeFlutter alloc] initWithEngineRunCompletion:^void() {
    [engineStartedExpectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:nil];

  UIApplication* application = UIApplication.sharedApplication;
  application.delegate.window.rootViewController = rootVC;
  FlutterEngine* engine = rootVC.engine;

  NSMutableArray* lifecycleExpectations = [NSMutableArray arrayWithCapacity:10];
  NSMutableArray* lifecycleEvents = [NSMutableArray arrayWithCapacity:10];

  [lifecycleExpectations addObject:[[XCTestExpectation alloc]
                                       initWithDescription:@"A loading FlutterViewController goes "
                                                           @"through AppLifecycleState.inactive"]];
  [lifecycleExpectations
      addObject:[[XCTestExpectation alloc]
                    initWithDescription:
                        @"A loading FlutterViewController goes through AppLifecycleState.resumed"]];

  FlutterViewController* flutterVC = [rootVC showFlutter];
  [engine.lifecycleChannel setMessageHandler:^(id message, FlutterReply callback) {
    if (lifecycleExpectations.count == 0) {
      XCTFail(@"Unexpected lifecycle transition: %@", message);
    }
    [lifecycleEvents addObject:message];
    [[lifecycleExpectations objectAtIndex:0] fulfill];
    [lifecycleExpectations removeObjectAtIndex:0];
  }];

  [self waitForExpectations:lifecycleExpectations timeout:5];

  // Expected sequence from showing the FlutterViewController is inactive and resumed.
  NSArray* expectedStates = @[ @"AppLifecycleState.inactive", @"AppLifecycleState.resumed" ];
  XCTAssertEqualObjects(lifecycleEvents, expectedStates,
                        @"AppLifecycleState transitions while presenting not as expected");

  // Now dismiss the FlutterViewController again and expect another inactive and paused.
  [lifecycleExpectations
      addObject:[[XCTestExpectation alloc]
                    initWithDescription:@"A dismissed FlutterViewController goes through "
                                        @"AppLifecycleState.inactive"]];
  [lifecycleExpectations
      addObject:[[XCTestExpectation alloc]
                    initWithDescription:@"A dismissed FlutterViewController goes through "
                                        @"AppLifecycleState.paused"]];
  [flutterVC dismissViewControllerAnimated:NO completion:nil];
  [self waitForExpectations:lifecycleExpectations timeout:5];
  expectedStates = @[
    @"AppLifecycleState.inactive", @"AppLifecycleState.resumed", @"AppLifecycleState.inactive",
    @"AppLifecycleState.paused"
  ];
  XCTAssertEqualObjects(lifecycleEvents, expectedStates,
                        @"AppLifecycleState transitions while dismissing not as expected");

  // Now put the app in the background (while the engine is still running) and bring it back to
  // the foreground. Granted, we're not winning any awards for hyper-realism but at least we're
  // checking that we aren't observing the UIApplication notifications and double registering
  // for AppLifecycleState events.

  // However the production is temporarily wrong. https://github.com/flutter/flutter/issues/37226.
  // It will be fixed in a next PR that removes the wrong asserts.
  [lifecycleExpectations
      addObject:
          [[XCTestExpectation alloc]
              initWithDescription:@"Current implementation sends another AppLifecycleState event"]];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillResignActiveNotification
                    object:nil];
  [lifecycleExpectations
      addObject:
          [[XCTestExpectation alloc]
              initWithDescription:@"Current implementation sends another AppLifecycleState event"]];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:nil];
  [lifecycleExpectations
      addObject:
          [[XCTestExpectation alloc]
              initWithDescription:@"Current implementation sends another AppLifecycleState event"]];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:nil];
  [lifecycleExpectations
      addObject:
          [[XCTestExpectation alloc]
              initWithDescription:@"Current implementation sends another AppLifecycleState event"]];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidBecomeActiveNotification
                    object:nil];

  // There's no timing latch for our semi-fake background-foreground cycle so launch the
  // FlutterViewController again to check the complete event list again.
  [lifecycleExpectations addObject:[[XCTestExpectation alloc]
                                       initWithDescription:@"A second FlutterViewController goes "
                                                           @"through AppLifecycleState.inactive"]];
  [lifecycleExpectations
      addObject:[[XCTestExpectation alloc]
                    initWithDescription:
                        @"A second FlutterViewController goes through AppLifecycleState.resumed"]];
  flutterVC = [rootVC showFlutter];
  [self waitForExpectations:lifecycleExpectations timeout:5];
  expectedStates = @[
    @"AppLifecycleState.inactive", @"AppLifecycleState.resumed", @"AppLifecycleState.inactive",
    @"AppLifecycleState.paused",

    // The production code currently misbehaves. https://github.com/flutter/flutter/issues/37226.
    // It will be fixed in a next PR that removes the wrong asserts.
    @"AppLifecycleState.inactive", @"AppLifecycleState.paused", @"AppLifecycleState.inactive",
    @"AppLifecycleState.resumed",

    // We only added 2 from re-launching the FlutterViewController
    // and none from the background-foreground cycle.
    @"AppLifecycleState.inactive", @"AppLifecycleState.resumed"
  ];
  XCTAssertEqualObjects(
      lifecycleEvents, expectedStates,
      @"AppLifecycleState transitions while presenting a second time not as expected");

  // Dismantle.
  [engine.lifecycleChannel setMessageHandler:nil];
  [flutterVC dismissViewControllerAnimated:NO completion:nil];
  flutterVC = nil;
  [engine setViewController:nil];
  [rootVC dismissViewControllerAnimated:NO completion:nil];
  rootVC = nil;
}
@end
