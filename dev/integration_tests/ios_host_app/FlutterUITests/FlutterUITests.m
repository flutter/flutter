// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;

@interface FlutterUITests : XCTestCase
@end

@implementation FlutterUITests

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)testFullScreenColdPop {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    [app.buttons[@"Full Screen (Cold)"] tap];

    XCTAssertTrue([app.otherElements[@"Button tapped 0 times."] waitForExistenceWithTimeout:1.0]);
    [app.otherElements[@"Increment via Flutter"] tap];
    XCTAssertTrue([app.otherElements[@"Button tapped 1 time."] waitForExistenceWithTimeout:1.0]);

    // Back navigation.
    [app.buttons[@"POP"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:1.0]);
}

- (void)testFullScreenWarm {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    [app.buttons[@"Full Screen (Warm)"] tap];

    XCTAssertTrue([app.otherElements[@"Button tapped 0 times."] waitForExistenceWithTimeout:1.0]);
    [app.otherElements[@"Increment via Flutter"] tap];
    XCTAssertTrue([app.otherElements[@"Button tapped 1 time."] waitForExistenceWithTimeout:1.0]);

    // Back navigation.
    [app.buttons[@"POP"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:1.0]);
}

- (void)testFlutterViewWarm {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    [app.buttons[@"Flutter View (Warm)"] tap];

    XCTAssertTrue([app.otherElements[@"Button tapped 0 times."] waitForExistenceWithTimeout:1.0]);
    [app.otherElements[@"Increment via Flutter"] tap];
    XCTAssertTrue([app.otherElements[@"Button tapped 1 time."] waitForExistenceWithTimeout:1.0]);

    // Back navigation.
    [app.buttons[@"POP"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:1.0]);
}

- (void)testHybridViewWarm {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    [app.buttons[@"Hybrid View (Warm)"] tap];

    XCTAssertTrue([app.staticTexts[@"Flutter button tapped 0 times."] waitForExistenceWithTimeout:1.0]);
    XCTAssertTrue(app.otherElements[@"Platform button tapped 0 times."].exists);

    [app.otherElements[@"Increment via Flutter"] tap];
    XCTAssertTrue([app.staticTexts[@"Flutter button tapped 1 time."] waitForExistenceWithTimeout:1.0]);
    XCTAssertTrue(app.otherElements[@"Platform button tapped 0 times."].exists);

    [app.buttons[@"Increment via iOS"] tap];
    XCTAssertTrue([app.staticTexts[@"Flutter button tapped 1 time."] waitForExistenceWithTimeout:1.0]);
    XCTAssertTrue(app.otherElements[@"Platform button tapped 1 time."].exists);

    // Back navigation.
    [app.navigationBars[@"Hybrid Flutter/Native"].buttons[@"Flutter iOS Demos Home"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:1.0]);
}

- (void)testDualCold {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app launch];

    [app.buttons[@"Dual Flutter View (Cold)"] tap];

    // There are two marquees.
    XCTAssertTrue([app.otherElements[@"This is Marquee"] waitForExistenceWithTimeout:1.0]);
    XCTAssertEqual([app.otherElements matchingType:XCUIElementTypeOther identifier:@"This is Marquee"].count, 2);

    // Back navigation.
    [app.navigationBars[@"Dual Flutter Views"].buttons[@"Flutter iOS Demos Home"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:1.0]);
}

@end
