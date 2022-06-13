// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;

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

  XCUIElement *entranceButton = self.app.buttons[@"platform view focus test"];
  XCTAssertTrue([entranceButton waitForExistenceWithTimeout:1]);
  [entranceButton tap];

  XCUIElement *platformView = self.app.textFields[@"platform_view[0]"];
  XCTAssertTrue([platformView waitForExistenceWithTimeout:1]);
  XCUIElement *flutterTextField = self.app.textFields[@"Flutter Text Field"];
  XCTAssertTrue([flutterTextField waitForExistenceWithTimeout:1]);

  [flutterTextField tap];
  XCTAssertTrue([self.app.windows.element waitForExistenceWithTimeout:1]);
  XCTAssertFalse(platformView.flt_hasKeyboardFocus);
  XCTAssertTrue(flutterTextField.flt_hasKeyboardFocus);

  // Tapping on platformView should unfocus the previously focused flutterTextField
  [platformView tap];
  XCTAssertTrue(platformView.flt_hasKeyboardFocus);
  XCTAssertFalse(flutterTextField.flt_hasKeyboardFocus);
}

@end
