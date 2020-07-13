// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

@interface UnobstructedPlatformViewTests : XCTestCase

@end

@implementation UnobstructedPlatformViewTests

- (void)setUp {
  self.continueAfterFailure = NO;
}

// A is the layer, which z index is higher than the platform view.
// +--------+
// | PV     |  +---+
// +--------+  | A |
//             +---+
- (void)testNoOverlay {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--platform-view-no-overlay-intersection" ];
  [app launch];

  XCUIElement* platform_view = app.textViews[@"platform_view[0]"];
  XCTAssertTrue([platform_view waitForExistenceWithTimeout:1.0]);
  XCTAssertEqual(platform_view.frame.origin.x, 25);
  XCTAssertEqual(platform_view.frame.origin.y, 25);
  XCTAssertEqual(platform_view.frame.size.width, 250);
  XCTAssertEqual(platform_view.frame.size.height, 250);

  XCUIElement* overlay = app.otherElements[@"platform_view[0].overlay[0]"];
  XCTAssertFalse(overlay.exists);
}

// A is the layer above the platform view.
// +-----------------+
// | PV        +---+ |
// |           | A | |
// |           +---+ |
// +-----------------+
- (void)testOneOverlay {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--platform-view" ];
  [app launch];

  XCUIElement* platform_view = app.textViews[@"platform_view[0]"];
  XCTAssertTrue([platform_view waitForExistenceWithTimeout:1.0]);
  XCTAssertEqual(platform_view.frame.origin.x, 25);
  XCTAssertEqual(platform_view.frame.origin.y, 25);
  XCTAssertEqual(platform_view.frame.size.width, 250);
  XCTAssertEqual(platform_view.frame.size.height, 250);

  XCUIElement* overlay = app.otherElements[@"platform_view[0].overlay[0]"];
  XCTAssertTrue(overlay.exists);
  XCTAssertEqual(overlay.frame.origin.x, 150);
  XCTAssertEqual(overlay.frame.origin.y, 150);
  XCTAssertEqual(overlay.frame.size.width, 50);
  XCTAssertEqual(overlay.frame.size.height, 50);
}

// A is the layer above the platform view.
// +-----------------+
// | PV        +---+ |
// +-----------| A |-+
//             +---+
- (void)testOneOverlayPartialIntersection {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--platform-view-partial-intersection" ];
  [app launch];

  XCUIElement* platform_view = app.textViews[@"platform_view[0]"];
  XCTAssertTrue([platform_view waitForExistenceWithTimeout:1.0]);
  XCTAssertEqual(platform_view.frame.origin.x, 25);
  XCTAssertEqual(platform_view.frame.origin.y, 25);
  XCTAssertEqual(platform_view.frame.size.width, 250);
  XCTAssertEqual(platform_view.frame.size.height, 250);

  XCUIElement* overlay = app.otherElements[@"platform_view[0].overlay[0]"];
  XCTAssertTrue(overlay.exists);
  XCTAssertEqual(overlay.frame.origin.x, 200);
  XCTAssertEqual(overlay.frame.origin.y, 250);
  XCTAssertEqual(overlay.frame.size.width, 50);
  // Half the height of the overlay.
  XCTAssertEqual(overlay.frame.size.height, 25);
}

// A and B are the layers above the platform view.
// +--------------------+
// | PV  +------------+ |
// |      | B +-----+ | |
// |      +---|  A  |-+ |
// +----------|     |---+
//            +-----+
- (void)testTwoIntersectingOverlays {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--platform-view-two-intersecting-overlays" ];
  [app launch];

  XCUIElement* platform_view = app.textViews[@"platform_view[0]"];
  XCTAssertTrue([platform_view waitForExistenceWithTimeout:1.0]);
  XCTAssertEqual(platform_view.frame.origin.x, 25);
  XCTAssertEqual(platform_view.frame.origin.y, 25);
  XCTAssertEqual(platform_view.frame.size.width, 250);
  XCTAssertEqual(platform_view.frame.size.height, 250);

  XCUIElement* overlay = app.otherElements[@"platform_view[0].overlay[0]"];
  XCTAssertTrue(overlay.exists);
  XCTAssertEqual(overlay.frame.origin.x, 150);
  XCTAssertEqual(overlay.frame.origin.y, 150);
  XCTAssertEqual(overlay.frame.size.width, 75);
  XCTAssertEqual(overlay.frame.size.height, 75);

  XCTAssertFalse(app.otherElements[@"platform_view[0].overlay[1]"].exists);
}

// A, B, and C are the layers above the platform view.
// +-------------------------+
// | PV        +-----------+ |
// | +---+     | B +-----+ | |
// | | C |     +---|  A  |-+ |
// | +---+         +-----+   |
// +-------------------------+
- (void)testOneOverlayAndTwoIntersectingOverlays {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--platform-view-one-overlay-two-intersecting-overlays" ];
  [app launch];

  XCUIElement* platform_view = app.textViews[@"platform_view[0]"];
  XCTAssertTrue([platform_view waitForExistenceWithTimeout:1.0]);
  XCTAssertEqual(platform_view.frame.origin.x, 25);
  XCTAssertEqual(platform_view.frame.origin.y, 25);
  XCTAssertEqual(platform_view.frame.size.width, 250);
  XCTAssertEqual(platform_view.frame.size.height, 250);

  XCUIElement* overlay1 = app.otherElements[@"platform_view[0].overlay[0]"];
  XCTAssertTrue(overlay1.exists);
  XCTAssertEqual(overlay1.frame.origin.x, 150);
  XCTAssertEqual(overlay1.frame.origin.y, 150);
  XCTAssertEqual(overlay1.frame.size.width, 75);
  XCTAssertEqual(overlay1.frame.size.height, 75);

  XCUIElement* overlay2 = app.otherElements[@"platform_view[0].overlay[1]"];
  XCTAssertTrue(overlay2.exists);
  XCTAssertEqual(overlay2.frame.origin.x, 75);
  XCTAssertEqual(overlay2.frame.origin.y, 225);
  XCTAssertEqual(overlay2.frame.size.width, 50);
  XCTAssertEqual(overlay2.frame.size.height, 50);
}

// A is the layer, which z index is higher than the platform view.
// +--------+
// | PV     |  +---+
// +--------+  | A |
// +--------+  +---+
// | PV     |
// +--------+
- (void)testMultiplePlatformViewsWithoutOverlays {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--platform-view-multiple-without-overlays" ];
  [app launch];

  XCUIElement* platform_view1 = app.textViews[@"platform_view[0]"];
  XCTAssertTrue([platform_view1 waitForExistenceWithTimeout:1.0]);
  XCTAssertEqual(platform_view1.frame.origin.x, 25);
  XCTAssertEqual(platform_view1.frame.origin.y, 325);
  XCTAssertEqual(platform_view1.frame.size.width, 250);
  XCTAssertEqual(platform_view1.frame.size.height, 250);

  XCUIElement* platform_view2 = app.textViews[@"platform_view[1]"];
  XCTAssertTrue(platform_view2.exists);
  XCTAssertEqual(platform_view2.frame.origin.x, 25);
  XCTAssertEqual(platform_view2.frame.origin.y, 25);
  XCTAssertEqual(platform_view2.frame.size.width, 250);
  XCTAssertEqual(platform_view2.frame.size.height, 250);

  XCTAssertFalse(app.otherElements[@"platform_view[0].overlay[0]"].exists);
  XCTAssertFalse(app.otherElements[@"platform_view[1].overlay[0]"].exists);
}

// A is the layer above both platform view.
// +------------+
// | PV  +----+ |
// +-----| A  |-+
// +-----|    |-+
// | PV  +----+ |
// +------------+
- (void)testMultiplePlatformViewsWithOverlays {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--platform-view-multiple-background-foreground" ];
  [app launch];

  XCUIElement* platform_view1 = app.textViews[@"platform_view[0]"];
  XCTAssertTrue([platform_view1 waitForExistenceWithTimeout:1.0]);
  XCTAssertEqual(platform_view1.frame.origin.x, 25);
  XCTAssertEqual(platform_view1.frame.origin.y, 325);
  XCTAssertEqual(platform_view1.frame.size.width, 250);
  XCTAssertEqual(platform_view1.frame.size.height, 250);

  XCUIElement* platform_view2 = app.textViews[@"platform_view[1]"];
  XCTAssertTrue(platform_view2.exists);
  XCTAssertEqual(platform_view2.frame.origin.x, 25);
  XCTAssertEqual(platform_view2.frame.origin.y, 25);
  XCTAssertEqual(platform_view2.frame.size.width, 250);
  XCTAssertEqual(platform_view2.frame.size.height, 250);

  XCUIElement* overlay1 = app.otherElements[@"platform_view[0].overlay[0]"];
  XCTAssertTrue(overlay1.exists);
  XCTAssertEqual(overlay1.frame.origin.x, 25);
  XCTAssertEqual(overlay1.frame.origin.y, 325);
  XCTAssertEqual(overlay1.frame.size.width, 225);
  XCTAssertEqual(overlay1.frame.size.height, 175);

  XCUIElement* overlay2 = app.otherElements[@"platform_view[1].overlay[0]"];
  XCTAssertTrue(overlay2.exists);
  XCTAssertEqual(overlay2.frame.origin.x, 25);
  XCTAssertEqual(overlay2.frame.origin.y, 25);
  XCTAssertEqual(overlay2.frame.size.width, 225);
  XCTAssertEqual(overlay2.frame.size.height, 250);
}

// More then two overlays are merged into a single layer.
// +---------------------+
// | +---+  +---+  +---+ |
// | | A |  | B |  | C | |
// | +---+  +---+  +---+ |
// | +-------+           |
// +-|   D   |-----------+
//   +-------+
- (void)testPlatformViewsMaxOverlays {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--platform-view-max-overlays" ];
  [app launch];

  XCUIElement* platform_view = app.textViews[@"platform_view[0]"];
  XCTAssertTrue([platform_view waitForExistenceWithTimeout:1.0]);
  XCTAssertEqual(platform_view.frame.origin.x, 25);
  XCTAssertEqual(platform_view.frame.origin.y, 25);
  XCTAssertEqual(platform_view.frame.size.width, 250);
  XCTAssertEqual(platform_view.frame.size.height, 250);

  XCUIElement* overlay = app.otherElements[@"platform_view[0].overlay[0]"];
  XCTAssertTrue(overlay.exists);
  XCTAssertFalse(app.otherElements[@"platform_view[0].overlay[1]"].exists);
  XCTAssertTrue(CGRectContainsRect(platform_view.frame, overlay.frame));
}

@end
