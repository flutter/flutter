// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;

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
    XCTAssertTrue([app.staticTexts[@"Button tapped 0 times."] waitForExistenceWithTimeout:60.0]);

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    XCTAssertTrue([app.staticTexts[@"Button tapped 1 time."] waitForExistenceWithTimeout:60.0]);

    // Back navigation.
    [app.buttons[@"POP"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:60.0]);
}

- (void)testFullScreenWarm {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Full Screen (Warm)"]];
    XCTAssertTrue([app.staticTexts[@"Button tapped 0 times."] waitForExistenceWithTimeout:60.0]);

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    XCTAssertTrue([app.staticTexts[@"Button tapped 1 time."] waitForExistenceWithTimeout:60.0]);

    // Back navigation.
    [app.buttons[@"POP"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:60.0]);
}

- (void)testFlutterViewWarm {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Flutter View (Warm)"]];
    XCTAssertTrue([app.staticTexts[@"Button tapped 0 times."] waitForExistenceWithTimeout:60.0]);

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    XCTAssertTrue([app.staticTexts[@"Button tapped 1 time."] waitForExistenceWithTimeout:60.0]);

    // Back navigation.
    [app.buttons[@"POP"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:60.0]);
}

- (void)testHybridViewWarm {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Hybrid View (Warm)"]];

    XCTAssertTrue([app.staticTexts[@"Flutter button tapped 0 times."] waitForExistenceWithTimeout:60.0]);
    XCTAssertTrue(app.staticTexts[@"Platform button tapped 0 times."].exists);

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    XCTAssertTrue([app.staticTexts[@"Flutter button tapped 1 time."] waitForExistenceWithTimeout:60.0]);
    XCTAssertTrue(app.staticTexts[@"Platform button tapped 0 times."].exists);

    [app.buttons[@"Increment via iOS"] tap];
    XCTAssertTrue([app.staticTexts[@"Flutter button tapped 1 time."] waitForExistenceWithTimeout:60.0]);
    XCTAssertTrue(app.staticTexts[@"Platform button tapped 1 time."].exists);

    // Back navigation.
    [app.navigationBars[@"Hybrid Flutter/Native"].buttons[@"Flutter iOS Demos Home"] tap];
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:60.0]);
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
    XCTAssertTrue([app.navigationBars[@"Flutter iOS Demos Home"] waitForExistenceWithTimeout:60.0]);
}

- (void)waitForAndTapElement:(XCUIElement *)element {
    NSPredicate *hittable = [NSPredicate predicateWithFormat:@"exists == YES AND hittable == YES"];
    [self expectationForPredicate:hittable evaluatedWithObject:element handler:nil];
    [self waitForExpectationsWithTimeout:30.0 handler:nil];
    [element tap];
}

@end
