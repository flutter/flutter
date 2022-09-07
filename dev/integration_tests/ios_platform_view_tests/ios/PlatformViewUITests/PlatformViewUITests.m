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

    // It's possible that app icon is not hittable yet.
    NSPredicate *hittable = [NSPredicate predicateWithFormat:@"exists == YES AND hittable == YES"];
    [self expectationForPredicate:hittable evaluatedWithObject:appIcon handler:nil];
    [self waitForExpectationsWithTimeout:kStandardTimeOut handler:nil];

    // Pressing for 2 seconds will bring up context menu.
    // Pressing for 3 seconds will dismiss the context menu and make icons wiggle.
    [appIcon pressForDuration:2];

    // The "Remove App" button in context menu.
    XCUIElement *contextMenuRemoveButton = springboard.buttons[@"Remove App"];
    XCTAssert([contextMenuRemoveButton waitForExistenceWithTimeout:kStandardTimeOut], @"The context menu remove app button must appear.");
    [contextMenuRemoveButton tap];

    // Tap the delete confirmation
    XCUIElement *deleteConfirmationButton = springboard.alerts.buttons[@"Delete App"];
    XCTAssert([deleteConfirmationButton waitForExistenceWithTimeout:kStandardTimeOut], @"The first delete confirmation button must appear.");
    [deleteConfirmationButton tap];

    // Tap the second delete confirmation
    XCUIElement *secondDeleteConfirmationButton = springboard.alerts.buttons[@"Delete"];
    XCTAssert([secondDeleteConfirmationButton waitForExistenceWithTimeout:kStandardTimeOut], @"The second delete confirmation button must appear.");
    [secondDeleteConfirmationButton tap];

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
