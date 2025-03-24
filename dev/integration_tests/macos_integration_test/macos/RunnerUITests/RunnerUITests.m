// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

@interface integration1UITests : XCTestCase

@end

@implementation integration1UITests

- (void)setUp {
  self.continueAfterFailure = NO;
}

- (void)tearDown {
}

- (void)testInteractionAfterResize {
  XCUIApplication *app = [[XCUIApplication alloc] init];
  [app launch];

  XCUIElement *label = [app staticTexts][@"Count is 0"];
  XCTAssertTrue([label waitForExistenceWithTimeout:10.0]);

  // Shrink the window by 20 pixels
  XCUIElement *window = [[app windows] elementBoundByIndex:0];
  CGRect frameBefore = window.frame;
  XCUICoordinate *startCoordinate =
      [window coordinateWithNormalizedOffset:CGVectorMake(0.99, 0.99)];
  XCUICoordinate *endCoordinate =
      [startCoordinate coordinateWithOffset:CGVectorMake(-20, -20)];
  [startCoordinate pressForDuration:0.5 thenDragToCoordinate:endCoordinate];

  CGRect frameAfter = window.frame;

  // Make sure window got resized without deadlocking main thread.
  XCTAssert(frameAfter.size.width == frameBefore.size.width - 20);
  XCTAssert(frameAfter.size.height == frameBefore.size.height - 20);

  // Increment counter to make sure application is responsive after resizing.
  XCUIElement *button = [app buttons][@"Increment"];
  XCTAssertTrue([label exists]);

  [button click];
  label = [app staticTexts][@"Count is 1"];
  XCTAssertTrue([label waitForExistenceWithTimeout:1.0]);
}

@end
