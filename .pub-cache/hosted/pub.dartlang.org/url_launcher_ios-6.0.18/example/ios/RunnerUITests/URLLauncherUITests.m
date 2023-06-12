// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;
@import os.log;

@interface URLLauncherUITests : XCTestCase
@property(nonatomic, strong) XCUIApplication *app;
@end

@implementation URLLauncherUITests

- (void)setUp {
  self.continueAfterFailure = NO;

  self.app = [[XCUIApplication alloc] init];
  [self.app launch];
}

- (void)testLaunch {
  XCUIApplication *app = self.app;

  NSArray<NSString *> *buttonNames = @[
    @"Launch in app", @"Launch in app(JavaScript ON)", @"Launch in app(DOM storage ON)",
    @"Launch a universal link in a native app, fallback to Safari.(Youtube)"
  ];
  for (NSString *buttonName in buttonNames) {
    XCUIElement *button = app.buttons[buttonName];
    XCTAssertTrue([button waitForExistenceWithTimeout:30.0]);
    XCTAssertEqual(app.webViews.count, 0);
    [button tap];
    XCUIElement *webView = app.webViews.firstMatch;
    XCTAssertTrue([webView waitForExistenceWithTimeout:30.0]);
    XCTAssertTrue([app.buttons[@"ForwardButton"] waitForExistenceWithTimeout:30.0]);
    XCTAssertTrue(app.buttons[@"Share"].exists);
    XCTAssertTrue(app.buttons[@"OpenInSafariButton"].exists);
    [app.buttons[@"Done"] tap];
  }
}

@end
