// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;

static const CGFloat kStandardTimeOut = 60.0;

@interface XCUIElement(Test)
@property (nonatomic, readonly) BOOL flt_hasKeyboardFocus;
- (void)flt_forceTap;
@end

@implementation XCUIElement(Test)
- (BOOL)flt_hasKeyboardFocus {
  return [[self valueForKey:@"hasKeyboardFocus"] boolValue];
}

- (void)flt_forceTap {
  if (self.isHittable) {
    [self tap];
  } else {
    XCUICoordinate *normalized = [self coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
    // The offset is in actual pixels. (1, 1) to make sure tap within the view boundary.
    XCUICoordinate *coordinate = [normalized coordinateWithOffset:CGVectorMake(1, 1)];
    [coordinate tap];
  }
}
@end

@interface PlatformViewUITests : XCTestCase
@property (strong) XCUIApplication *app;
@end

@implementation PlatformViewUITests

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;

  self.app = [[XCUIApplication alloc] init];
  [self.app launch];
}

- (void)tearDown {
  [self.app terminate];
  [super tearDown];
}

- (void)testPlatformViewFocus {
  XCUIElement *entranceButton = self.app.buttons[@"platform view focus test"];
  XCTAssertTrue([entranceButton waitForExistenceWithTimeout:kStandardTimeOut], @"The element tree is %@", self.app.debugDescription);
  [entranceButton tap];

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

- (void)testPlatformViewZOrder {
  XCUIElement *entranceButton = self.app.buttons[@"platform view z order test"];
  XCTAssertTrue([entranceButton waitForExistenceWithTimeout:kStandardTimeOut], @"The element tree is %@", self.app.debugDescription);
  [entranceButton tap];

  XCUIElement *showAlertButton = self.app.buttons[@"Show Alert"];
  XCTAssertTrue([showAlertButton waitForExistenceWithTimeout:kStandardTimeOut]);

  [showAlertButton tap];

  XCUIElement *platformButton = self.app.buttons[@"platform_view[0]"];
  XCTAssertTrue([platformButton waitForExistenceWithTimeout:kStandardTimeOut]);
  XCTAssertTrue([platformButton.label isEqualToString:@"Initial Button Title"]);

  // The `app.otherElements` query fails to query `platform_view[1]` (the background),
  // because it is covered by a dialog prompt, which removes semantic nodes underneath.
  // The workaround is to set a manual delay here (must be longer than the delay used to
  // show the background view on the dart side).
  [NSThread sleepForTimeInterval:3];

  for (int i = 1; i <= 5; i++) {
    [platformButton flt_forceTap];
    NSString *expectedButtonTitle = [NSString stringWithFormat:@"Button Tapped %d", i];
    XCTAssertTrue([platformButton.label isEqualToString:expectedButtonTitle]);
  }
}

@end
