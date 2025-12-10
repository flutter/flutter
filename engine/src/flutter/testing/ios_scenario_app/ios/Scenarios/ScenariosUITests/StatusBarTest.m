// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

#import "StatusBarTest.h"

@interface FlutterEngine ()
@property(nonatomic, strong) FlutterMethodChannel* statusBarChannel;
@end

@implementation StatusBarTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;

  self.application = [[XCUIApplication alloc] init];
  self.application.launchArguments = @[ @"--tap-status-bar" ];
  [self.application launch];
}

- (void)testTapStatusBar {
  XCUIApplication* systemApp =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
  XCUIElement* statusBar = [systemApp.statusBars firstMatch];
  if (statusBar.isHittable) {
    [statusBar tap];
  } else {
    XCUICoordinate* coordinates = [statusBar coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
    [coordinates tap];
  }
  UIApplication* application = UIApplication.sharedApplication;
  FlutterViewController* rootVC =
      (FlutterViewController*)application.delegate.window.rootViewController;
  FlutterEngine* engine = rootVC.engine;
  XCTestExpectation expectation =
      [[XCTestExpectation alloc] initWithDescription:@"status bar tap message received"];

  [engine.statusBarChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult callback) {
    if (![call.method isEqualToString:@"handleScrollToTop"]) {
      XCTFail(@"Unexpected method call %@", call.method);
      return;
    }

    [expectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

@end
