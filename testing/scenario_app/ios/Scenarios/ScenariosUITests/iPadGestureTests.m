// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

static const NSInteger kSecondsToWaitForFlutterView = 30;

@interface iPadGestureTests : XCTestCase

@end

@implementation iPadGestureTests

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
}

#ifdef __IPHONE_15_0
- (void)testPointerButtons {
  if (@available(iOS 15, *)) {
    XCTSkipUnless([XCUIDevice.sharedDevice supportsPointerInteraction],
                  "Device does not support pointer interaction");
    XCUIApplication* app = [[XCUIApplication alloc] init];
    app.launchArguments = @[ @"--pointer-events" ];
    [app launch];

    NSPredicate* predicateToFindFlutterView =
        [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject,
                                              NSDictionary<NSString*, id>* _Nullable bindings) {
          XCUIElement* element = evaluatedObject;
          return [element.identifier hasPrefix:@"flutter_view"];
        }];
    XCUIElement* flutterView = [[app descendantsMatchingType:XCUIElementTypeAny]
        elementMatchingPredicate:predicateToFindFlutterView];
    if (![flutterView waitForExistenceWithTimeout:kSecondsToWaitForFlutterView]) {
      NSLog(@"%@", app.debugDescription);
      XCTFail(@"Failed due to not able to find any flutterView with %@ seconds",
              @(kSecondsToWaitForFlutterView));
    }

    XCTAssertNotNil(flutterView);

    [flutterView tap];
    // Initial add event should have buttons = 0
    XCTAssertTrue([app.textFields[@"PointerChange.add:0"] waitForExistenceWithTimeout:1],
                  @"PointerChange.add event did not occur");
    // Normal tap should have buttons = 0, the flutter framework will ensure it has buttons = 1
    XCTAssertTrue([app.textFields[@"PointerChange.down:0"] waitForExistenceWithTimeout:1],
                  @"PointerChange.down event did not occur for a normal tap");
    XCTAssertTrue([app.textFields[@"PointerChange.up:0"] waitForExistenceWithTimeout:1],
                  @"PointerChange.up event did not occur for a normal tap");
    [flutterView rightClick];
    // Since each touch is its own device, we can't distinguish the other add event(s)
    // Right click should have buttons = 2
    XCTAssertTrue([app.textFields[@"PointerChange.down:2"] waitForExistenceWithTimeout:1],
                  @"PointerChange.down event did not occur for a right-click");
    XCTAssertTrue([app.textFields[@"PointerChange.up:2"] waitForExistenceWithTimeout:1],
                  @"PointerChange.up event did not occur for a right-click");
    NSLog(@"DebugDescriptionX: %@", app.debugDescription);
  }
}
#endif

@end
