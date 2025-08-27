// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;
@import os.log;

static const CGFloat kStandardTimeOut = 60.0;

@interface FlutterUITests : XCTestCase
@property (strong) XCUIApplication *app;
@end

@implementation FlutterUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;

    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];
    self.app = app;
}

- (void)testFullScreenColdPop {
    XCUIApplication *app = self.app;
    [self waitForAndTapElement:app.buttons[@"Full Screen (Cold)"]];
    XCTAssertTrue([app.staticTexts[@"Button tapped 0 times."] waitForExistenceWithTimeout:kStandardTimeOut]);

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    XCTAssertTrue([app.staticTexts[@"Button tapped 1 time."] waitForExistenceWithTimeout:kStandardTimeOut]);

    // Back navigation.
    [app.buttons[@"POP"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:kStandardTimeOut]);
}

- (void)testFullScreenWarm {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Full Screen (Warm)"]];
    BOOL newPageAppeared = [app.staticTexts[@"Button tapped 0 times."] waitForExistenceWithTimeout:kStandardTimeOut];
    if (!newPageAppeared) {
        // Sometimes, the element doesn't respond to the tap, it seems an XCUITest race condition where the tap happened
        // too soon. Trying to tap the element again.
        [self waitForAndTapElement:app.buttons[@"Full Screen (Warm)"]];
        newPageAppeared = [app.staticTexts[@"Button tapped 0 times."] waitForExistenceWithTimeout:kStandardTimeOut];
    }
    XCTAssertTrue(newPageAppeared);

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    XCTAssertTrue([app.staticTexts[@"Button tapped 1 time."] waitForExistenceWithTimeout:kStandardTimeOut]);

    // Back navigation.
    [app.buttons[@"POP"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:kStandardTimeOut]);
}

- (void)testFlutterViewWarm {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Flutter View (Warm)"]];
    BOOL newPageAppeared = [app.staticTexts[@"Button tapped 0 times."] waitForExistenceWithTimeout:kStandardTimeOut];
    if (!newPageAppeared) {
      // Sometimes, the element doesn't respond to the tap, it seems an XCUITest race condition where the tap happened
      // too soon. Trying to tap the element again.
      [self waitForAndTapElement:app.buttons[@"Flutter View (Warm)"]];
      newPageAppeared = [app.staticTexts[@"Button tapped 0 times."] waitForExistenceWithTimeout:kStandardTimeOut];
      if (!newPageAppeared) {
        os_log(OS_LOG_DEFAULT, "%@", app.debugDescription);
      }
    }
    XCTAssertTrue(newPageAppeared);

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    BOOL countIncremented = [app.staticTexts[@"Button tapped 1 time."] waitForExistenceWithTimeout:kStandardTimeOut];
    if (!countIncremented) {
        // Sometimes, the element doesn't respond to the tap, it seems to be an iOS 17 Simulator issue where the
        // simulator reboots. Try to tap the element again.
        [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
        countIncremented = [app.staticTexts[@"Button tapped 1 time."] waitForExistenceWithTimeout:kStandardTimeOut];
        if (!countIncremented) {
            os_log(OS_LOG_DEFAULT, "%@", app.debugDescription);
        }
    }
    XCTAssertTrue(countIncremented);

    // Back navigation.
    [app.buttons[@"POP"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:kStandardTimeOut]);
}

- (void)testHybridViewWarm {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Hybrid View (Warm)"]];

    XCTAssertTrue([app.staticTexts[@"Flutter button tapped 0 times."] waitForExistenceWithTimeout:kStandardTimeOut]);
    XCTAssertTrue(app.staticTexts[@"Platform button tapped 0 times."].exists);

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    XCTAssertTrue([app.staticTexts[@"Flutter button tapped 1 time."] waitForExistenceWithTimeout:kStandardTimeOut]);
    XCTAssertTrue(app.staticTexts[@"Platform button tapped 0 times."].exists);

    [app.buttons[@"Increment via iOS"] tap];
    XCTAssertTrue([app.staticTexts[@"Flutter button tapped 1 time."] waitForExistenceWithTimeout:kStandardTimeOut]);
    XCTAssertTrue(app.staticTexts[@"Platform button tapped 1 time."].exists);

    // Back navigation.
    [app.navigationBars[@"Hybrid Flutter/Native"].buttons[@"Flutter iOS Demos Home"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:kStandardTimeOut]);
}

- (void)testDualCold {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Dual Flutter View (Cold)"]];

    // There are two marquees.
    XCUIElementQuery *marqueeQuery = [app.staticTexts matchingIdentifier:@"This is Marquee"];
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"count = 2"] evaluatedWithObject:marqueeQuery handler:nil];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];

    // Back navigation.
    [app.navigationBars[@"Dual Flutter Views"].buttons[@"Flutter iOS Demos Home"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:kStandardTimeOut]);
}

- (void)waitForAndTapElement:(XCUIElement *)element {
    NSPredicate *hittable = [NSPredicate predicateWithFormat:@"exists == YES AND hittable == YES"];
    [self expectationForPredicate:hittable evaluatedWithObject:element handler:nil];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    [element tap];
}

@end
