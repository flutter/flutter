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
  [super setUp];
  self.continueAfterFailure = NO;

  // Delete the previously installed app if needed before running.
  // This is to address "Failed to terminate" failure.
  // The solution is based on https://stackoverflow.com/questions/50016018/uitest-failed-to-terminate-com-test-abc3708-after-60-0s-state-is-still-runnin
  XCUIApplication *springboard = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.springboard"];
  [springboard activate];
  XCUIElement *appIcon = springboard.icons[@"ios_platform_view_tests"];

  if ([appIcon waitForExistenceWithTimeout:kStandardTimeOut]) {
    NSLog(@"Deleting previously installed app.");

    // Make icons wiggle
    [appIcon pressForDuration:3];

    // Tap the "x" button
    [appIcon.buttons[@"DeleteButton"] tap];
    // Tap the delete confirmation
    [springboard.alerts.buttons[@"Delete App"] tap];
    // Tap the second delete confirmation
    [springboard.alerts.buttons[@"Delete"] tap];
    // Press home button to stop wiggling
    [XCUIDevice.sharedDevice pressButton:XCUIDeviceButtonHome];
    [NSThread sleepForTimeInterval:3];
  } else {
    NSLog(@"No previously installed app found.");
  }

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

@end
