// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;

static const CGFloat kStandardTimeOut = 60.0;

@interface XCUIElement(KeyboardFocus)
@property (nonatomic, readonly) BOOL flt_hasKeyboardFocus;
@end

@implementation XCUIElement(KeyboardFocus)
- (BOOL)flt_hasKeyboardFocus {
  return [[self valueForKey:@"hasKeyboardFocus"] boolValue];
}
@end

@interface PlatformViewUITests : XCTestCase
@property (strong) XCUIApplication *app;
@end

@implementation PlatformViewUITests

- (void)setUp {
  self.continueAfterFailure = NO;

  self.app = [[XCUIApplication alloc] init];
  [self.app launch];
}
- (void)testPlatformViewFocus {
  [self waitForAndTapElement:self.app.buttons[@"platform view focus test"]];
  /// Tries to wait and tap the button the second time, if the first time failed.
  /// https://github.com/flutter/flutter/pull/90535
  BOOL newPageAppeared = [self.app.textFields[@"platform_view[0]"] waitForExistenceWithTimeout:kStandardTimeOut];
  if (!newPageAppeared) {
    [self waitForAndTapElement:self.app.buttons[@"platform view focus test"]];
  }

  XCUIElement *platformView = self.app.textFields[@"platform_view[0]"];
  XCTAssertTrue([platformView waitForExistenceWithTimeout:kStandardTimeOut]);
  XCUIElement *flutterTextField = self.app.textFields[@"Flutter Text Field"];
  XCTAssertTrue([flutterTextField waitForExistenceWithTimeout:kStandardTimeOut]);

  [flutterTextField tap];
  XCTAssertTrue([self.app.windows.element waitForExistenceWithTimeout:kStandardTimeOut]);
  XCTAssertFalse(platformView.flt_hasKeyboardFocus);
  XCTAssertTrue(flutterTextField.flt_hasKeyboardFocus);

  // Tapping on platformView should unfocus the previously focused flutterTextField
  [platformView tap];
  XCTAssertTrue(platformView.flt_hasKeyboardFocus);
  XCTAssertFalse(flutterTextField.flt_hasKeyboardFocus);
}

- (void)waitForAndTapElement:(XCUIElement *)element {
  NSPredicate *hittable = [NSPredicate predicateWithFormat:@"exists == YES AND hittable == YES"];
  [self expectationForPredicate:hittable evaluatedWithObject:element handler:nil];
  [self waitForExpectationsWithTimeout:30.0 handler:nil];
  [element tap];
}

@end
