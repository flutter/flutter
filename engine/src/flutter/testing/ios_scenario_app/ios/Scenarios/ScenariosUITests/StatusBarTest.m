// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "StatusBarTest.h"

@implementation StatusBarTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;

  self.application = [[XCUIApplication alloc] init];
  self.application.launchArguments = @[ @"--tap-status-bar" ];
  [self.application launch];
}

- (void)testTapStatusBar {
  XCUIElement* textField = self.application.textFields[@"handleScrollToTop"];
  BOOL exists = [textField waitForExistenceWithTimeout:1];
  XCTAssertFalse(exists, @"");

  XCUIApplication* systemApp =
      [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
  XCUIElement* statusBar = [systemApp.statusBars firstMatch];
  if (statusBar.isHittable) {
    [statusBar tap];
  } else {
    XCUICoordinate* coordinates = [statusBar coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
    [coordinates tap];
  }
  exists = [textField waitForExistenceWithTimeout:1];
  XCTAssertTrue(exists, @"");
}

@end
