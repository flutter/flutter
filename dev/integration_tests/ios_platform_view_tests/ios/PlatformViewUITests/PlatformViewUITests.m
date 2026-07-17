// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;

static const CGFloat kStandardTimeOut = 60.0;

static NSArray<NSString *> *ElementLabels(XCUIElementQuery *query) {
  NSMutableArray<NSString *> *labels = [[NSMutableArray alloc] init];
  for (XCUIElement *element in query.allElementsBoundByIndex) {
    [labels addObject:element.label];
  }
  return labels;
}

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

- (void)testReorderableListAccessibilityHierarchyUpdates {
  // Regression test for https://github.com/flutter/flutter/issues/100946.
  XCUIElement *entranceButton =
      self.app.buttons[@"reorderable list semantics test"];
  XCTAssertTrue([entranceButton waitForExistenceWithTimeout:kStandardTimeOut],
                @"The element tree is %@", self.app.debugDescription);
  [entranceButton tap];

  XCUIElement *item2 = self.app.staticTexts[@"Item 2"];
  XCUIElement *item4 = self.app.staticTexts[@"Item 4"];
  XCTAssertTrue([item2 waitForExistenceWithTimeout:kStandardTimeOut],
                @"The element tree is %@", self.app.debugDescription);
  XCTAssertTrue([item4 waitForExistenceWithTimeout:kStandardTimeOut],
                @"The element tree is %@", self.app.debugDescription);

  XCUIElementQuery *items = [self.app.staticTexts
      matchingPredicate:[NSPredicate
                            predicateWithFormat:@"label MATCHES 'Item [1-4]'"]];
  NSArray<NSString *> *initialOrder =
      @[ @"Item 1", @"Item 2", @"Item 3", @"Item 4" ];
  XCTAssertEqualObjects(ElementLabels(items), initialOrder,
                        @"The element tree is %@", self.app.debugDescription);

  CGRect item2FrameBeforeReorder = item2.frame;
  CGRect expectedItem2FrameAfterReorder = item4.frame;
  XCUICoordinate *dragStart =
      [item2 coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
  XCUICoordinate *dragEnd =
      [item4 coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
  [dragStart pressForDuration:1.0 thenDragToCoordinate:dragEnd];

  NSArray<NSString *> *reorderedItems =
      @[ @"Item 1", @"Item 3", @"Item 4", @"Item 2" ];
  NSPredicate *hierarchyUpdated =
      [NSPredicate predicateWithBlock:^BOOL(XCUIElementQuery *query,
                                            NSDictionary *bindings) {
        return [ElementLabels(query) isEqualToArray:reorderedItems];
      }];
  XCTNSPredicateExpectation *hierarchyExpectation =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:hierarchyUpdated
                                                    object:items];
  XCTWaiterResult result =
      [XCTWaiter waitForExpectations:@[ hierarchyExpectation ]
                             timeout:kStandardTimeOut];
  CGRect item2FrameAfterReorder = item2.frame;
  XCTAssertEqual(result, XCTWaiterResultCompleted,
                 @"Item 2 frame before: %@; after: %@. The element tree is %@",
                 NSStringFromCGRect(item2FrameBeforeReorder),
                 NSStringFromCGRect(item2FrameAfterReorder),
                 self.app.debugDescription);
  XCTAssertEqualObjects(ElementLabels(items), reorderedItems,
                        @"The element tree is %@", self.app.debugDescription);
  XCTAssertTrue(
      CGRectEqualToRect(item2FrameAfterReorder, expectedItem2FrameAfterReorder),
      @"Expected Item 2 frame %@ after reorder, but found %@. The element tree "
      @"is %@",
      NSStringFromCGRect(expectedItem2FrameAfterReorder),
      NSStringFromCGRect(item2FrameAfterReorder), self.app.debugDescription);
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

- (void)testPlatformViewWebViewLinkTappableForContextMenuScenario {
  XCUIElement *entranceButton = self.app.buttons[@"web view behind context menu test"];
  XCTAssertTrue([entranceButton waitForExistenceWithTimeout:kStandardTimeOut]);
  [entranceButton tap];

  XCUIElement *platformView = self.app.webViews[@"platform_view[0]"];
  XCTAssertTrue([platformView waitForExistenceWithTimeout:kStandardTimeOut]);

  // expand the context menu.
  XCUIElement *showMenuButton = self.app.buttons[@"Show menu"];
  XCTAssertTrue([showMenuButton waitForExistenceWithTimeout:kStandardTimeOut]);
  [showMenuButton tap];

  // tap to dismiss the context menu.
  XCUIElement *menuItem = self.app.buttons[@"menu button 1"];
  XCTAssertTrue([menuItem waitForExistenceWithTimeout:kStandardTimeOut]);
  XCUICoordinate *center = [self.app coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
  [center tap];
  XCTAssertTrue([menuItem waitForNonExistenceWithTimeout:kStandardTimeOut]);

  // Verify that the web view link is still tappable.
  XCUIElement *link = self.app.links[@"Target Link"];
  XCTAssertTrue([link waitForExistenceWithTimeout:kStandardTimeOut]);
  [link tap];
  XCUIElement *successText = self.app.staticTexts[@"Navigation Successful"];
  XCTAssertTrue([successText waitForExistenceWithTimeout:60]);
}


- (void)testPlatformViewDrawingWebViewCannotBeDrawnWhenContextMenuIsShown {
  XCUIElement *entranceButton = self.app.buttons[@"drawing web view behind context menu test"];
  XCTAssertTrue([entranceButton waitForExistenceWithTimeout:kStandardTimeOut]);
  [entranceButton tap];

  XCUIElement *platformView = self.app.webViews[@"platform_view[0]"];
  XCTAssertTrue([platformView waitForExistenceWithTimeout:kStandardTimeOut]);

  // expand the context menu.
  XCUIElement *showMenuButton = self.app.buttons[@"Show menu"];
  XCTAssertTrue([showMenuButton waitForExistenceWithTimeout:kStandardTimeOut]);
  [showMenuButton tap];
  XCUIElement *menuItem = self.app.buttons[@"menu button 1"];
  XCTAssertTrue([menuItem waitForExistenceWithTimeout:kStandardTimeOut]);

  // draw on the canvas
  XCUICoordinate *center = [self.app coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
  XCUICoordinate *end = [center coordinateWithOffset:CGVectorMake(0.0, 100.0)];
  [center pressForDuration:0.1 thenDragToCoordinate:end];

  // Dismiss the context menu (so that we can find web view under the accessibility tree).
  // Since context menu is on top right, we tap on the bottom left corner to avoid tapping within the menu area.
  XCUICoordinate *bottomLeft = [self.app coordinateWithNormalizedOffset:CGVectorMake(0.05, 0.95)];
  [bottomLeft tap];
  XCTAssertTrue([menuItem waitForNonExistenceWithTimeout:kStandardTimeOut]);

  // Verify that the web view does not have any pixels drawn
  XCUIElement *pixelCountLabel = self.app.staticTexts[@"pixel count: 0"];
  XCTAssertTrue([pixelCountLabel waitForExistenceWithTimeout:kStandardTimeOut]);
}

- (void)testPlatformViewFakeAdMobBannerTappableForScrollableListScenario {
  XCUIElement *entranceButton = self.app.buttons[@"admob banner in scrollable list test"];
  XCTAssertTrue([entranceButton waitForExistenceWithTimeout:kStandardTimeOut]);
  [entranceButton tap];

  XCUIElement *platformView = self.app.otherElements[@"platform_view[0]"];
  XCTAssertTrue([platformView waitForExistenceWithTimeout:kStandardTimeOut]);

  // Scroll the list (touch began on banner).
  XCUICoordinate *start = [platformView coordinateWithNormalizedOffset:CGVectorMake(0.5, 0.5)];
  XCUICoordinate *end = [start coordinateWithOffset:CGVectorMake(0.0, 100.0)];
  [start pressForDuration:0.1 thenDragToCoordinate:end];

  // Verify that the banner is still tappable.
  XCUIElement *link = [[self.app.links matchingIdentifier:@"Target Link"] firstMatch];
  XCTAssertTrue([link waitForExistenceWithTimeout:kStandardTimeOut]);
  [link tap];
  XCUIElement *successText = self.app.staticTexts[@"Navigation Successful"];
  XCTAssertTrue([successText waitForExistenceWithTimeout:kStandardTimeOut]);
}

@end
