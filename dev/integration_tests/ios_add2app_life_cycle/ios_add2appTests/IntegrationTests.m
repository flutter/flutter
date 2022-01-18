// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <EarlGreyTest/EarlGrey.h>
#import <XCTest/XCTest.h>

#import "AppDelegate.h"
#import "FullScreenViewController.h"

@interface FlutterTests : XCTestCase
@end

@implementation FlutterTests

- (void)setUp {
  self.continueAfterFailure = NO;
  XCUIApplication *app = [[XCUIApplication alloc] init];
  [app launch];
}

- (void)testFullScreenCanPop {
  XCTestExpectation *notificationReceived = [self expectationWithDescription:@"Remote semantics notification"];
  NSNotificationCenter *notificationCenter = [[GREYHostApplicationDistantObject sharedInstance] notificationCenter];
  id observer = [notificationCenter addObserverForName:FlutterSemanticsUpdateNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
    XCTAssertTrue([notification.object isKindOfClass:GREY_REMOTE_CLASS_IN_APP(FullScreenViewController)]);
    [notificationReceived fulfill];
  }];

  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Full Screen (Cold)")]
      performAction:grey_tap()];

  [self waitForExpectationsWithTimeout:30.0 handler:nil];
  [notificationCenter removeObserver:observer];
}

@end
