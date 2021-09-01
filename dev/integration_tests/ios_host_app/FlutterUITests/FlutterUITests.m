// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;
@import OSLog;

static const CGFloat kStandardTimeout = 120.0;

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
    [self waitAndAssertExistOrLogError:app.staticTexts[@"Button tapped 0 times."]];

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    [self waitAndAssertExistOrLogError:app.staticTexts[@"Button tapped 1 time."]];


    // Back navigation.
    [app.buttons[@"POP"] tap];
    [self waitAndAssertExistOrLogError:app.navigationBars[@"Flutter iOS Demos Home"]];
}

- (void)testFullScreenWarm {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Full Screen (Warm)"]];
    [self waitAndAssertExistOrLogError:app.staticTexts[@"Button tapped 0 times."]];

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    [self waitAndAssertExistOrLogError:app.staticTexts[@"Button tapped 1 time."]];

    // Back navigation.
    [app.buttons[@"POP"] tap];
    [self waitAndAssertExistOrLogError:app.navigationBars[@"Flutter iOS Demos Home"]];
}

- (void)testFlutterViewWarm {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Flutter View (Warm)"]];
    [self waitAndAssertExistOrLogError:app.staticTexts[@"Button tapped 0 times."]];

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    [self waitAndAssertExistOrLogError:app.staticTexts[@"Button tapped 1 time."]];

    // Back navigation.
    [app.buttons[@"POP"] tap];
    [self waitAndAssertExistOrLogError:app.navigationBars[@"Flutter iOS Demos Home"]];
}

- (void)testHybridViewWarm {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Hybrid View (Warm)"]];

   [self waitAndAssertExistOrLogError:app.staticTexts[@"Flutter button tapped 0 times."]];
    XCTAssertTrue(app.staticTexts[@"Platform button tapped 0 times."].exists);

    [self waitForAndTapElement:app.otherElements[@"Increment via Flutter"]];
    [self waitAndAssertExistOrLogError:app.staticTexts[@"Flutter button tapped 1 time."]];
    XCTAssertTrue(app.staticTexts[@"Platform button tapped 0 times."].exists);

    [app.buttons[@"Increment via iOS"] tap];
    [self waitAndAssertExistOrLogError:app.staticTexts[@"Flutter button tapped 1 time."]];
    XCTAssertTrue(app.staticTexts[@"Platform button tapped 1 time."].exists);

    // Back navigation.
    [app.navigationBars[@"Hybrid Flutter/Native"].buttons[@"Flutter iOS Demos Home"] tap];
    [self waitAndAssertExistOrLogError:app.navigationBars[@"Flutter iOS Demos Home"]];
}

- (void)testDualCold {
    XCUIApplication *app = self.app;

    [self waitForAndTapElement:app.buttons[@"Dual Flutter View (Cold)"]];

    // There are two marquees.
    XCUIElementQuery *marqueeQuery = [app.staticTexts matchingIdentifier:@"This is Marquee"];
    [self expectationForPredicate:[NSPredicate predicateWithFormat:@"count = 2"] evaluatedWithObject:marqueeQuery handler:nil];
    [self waitForExpectationsOrLogError];

    // Back navigation.
    [app.navigationBars[@"Dual Flutter Views"].buttons[@"Flutter iOS Demos Home"] tap];
    [self waitAndAssertExistOrLogError:app.navigationBars[@"Flutter iOS Demos Home"]];
}

- (void)waitForAndTapElement:(XCUIElement *)element {
    NSPredicate *hittable = [NSPredicate predicateWithFormat:@"exists == YES AND hittable == YES"];
    [self expectationForPredicate:hittable evaluatedWithObject:element handler:nil];
    [self waitForExpectationsOrLogError];
    [element tap];
}

- (void)waitAndAssertExistOrLogError:(XCUIElement *)element {
  BOOL exist = [element waitForExistenceWithTimeout:kStandardTimeout];
  XCTAssertTrue(exist);
  if (!exist) {
    os_log_error(OS_LOG_DEFAULT, "Current app state: %@", self.app.debugDescription);
  }
}

- (void)waitForExpectationsOrLogError {
  [self waitForExpectationsWithTimeout:kStandardTimeout handler:^(NSError * _Nullable error) {
    if (!error) {
      return;
    }
    os_log_error(OS_LOG_DEFAULT, "Current app state: %@", self.app.debugDescription);
  }];
}

@end
