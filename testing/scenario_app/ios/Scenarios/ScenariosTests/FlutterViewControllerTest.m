// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>

#import "AppDelegate.h"

FLUTTER_ASSERT_ARC

@interface FlutterViewControllerTest : XCTestCase
@property(nonatomic, strong) FlutterViewController* flutterViewController;
@end

@implementation FlutterViewControllerTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
}

- (void)tearDown {
  if (self.flutterViewController) {
    XCTestExpectation* vcDismissed = [self expectationWithDescription:@"dismiss"];
    [self.flutterViewController dismissViewControllerAnimated:NO
                                                   completion:^{
                                                     [vcDismissed fulfill];
                                                   }];
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
  }
  [super tearDown];
}

- (void)testFirstFrameCallback {
  XCTestExpectation* firstFrameRendered = [self expectationWithDescription:@"firstFrameRendered"];

  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];
  self.flutterViewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                     nibName:nil
                                                                      bundle:nil];

  XCTAssertFalse(self.flutterViewController.isDisplayingFlutterUI);

  XCTestExpectation* displayingFlutterUIExpectation =
      [self keyValueObservingExpectationForObject:self.flutterViewController
                                          keyPath:@"displayingFlutterUI"
                                    expectedValue:@YES];
  displayingFlutterUIExpectation.assertForOverFulfill = YES;

  [self.flutterViewController setFlutterViewDidRenderCallback:^{
    [firstFrameRendered fulfill];
  }];

  AppDelegate* appDelegate = (AppDelegate*)UIApplication.sharedApplication.delegate;
  UIViewController* rootVC = appDelegate.window.rootViewController;
  [rootVC presentViewController:self.flutterViewController animated:NO completion:nil];

  [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

@end
