// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

static const NSInteger kSecondsToWaitForPlatformView = 30;

@interface PlatformViewGestureRecognizerTests : XCTestCase

@end

@implementation PlatformViewGestureRecognizerTests

- (void)setUp {
  self.continueAfterFailure = NO;
}

- (void)testRejectPolicyUtilTouchesEnded {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--gesture-reject-after-touches-ended" ];
  [app launch];

  NSPredicate* predicateToFindPlatformView =
      [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject,
                                            NSDictionary<NSString*, id>* _Nullable bindings) {
        XCUIElement* element = evaluatedObject;
        return [element.identifier hasPrefix:@"platform_view"];
      }];
  XCUIElement* platformView = [app.textViews elementMatchingPredicate:predicateToFindPlatformView];
  if (![platformView waitForExistenceWithTimeout:kSecondsToWaitForPlatformView]) {
    NSLog(@"%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find any platformView with %@ seconds",
            @(kSecondsToWaitForPlatformView));
  }

  XCTAssertNotNil(platformView);
  XCTAssertEqualObjects(platformView.label, @"");

  NSPredicate* predicate =
      [NSPredicate predicateWithFormat:@"label == %@", @"-gestureTouchesBegan-gestureTouchesEnded"];
  XCTNSPredicateExpectation* expection =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:platformView];

  [platformView tap];
  [self waitForExpectations:@[ expection ] timeout:kSecondsToWaitForPlatformView];
  XCTAssertEqualObjects(platformView.label, @"-gestureTouchesBegan-gestureTouchesEnded");
}

- (void)testRejectPolicyEager {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--gesture-reject-eager" ];
  [app launch];

  NSPredicate* predicateToFindPlatformView =
      [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject,
                                            NSDictionary<NSString*, id>* _Nullable bindings) {
        XCUIElement* element = evaluatedObject;
        return [element.identifier hasPrefix:@"platform_view"];
      }];
  XCUIElement* platformView = [app.textViews elementMatchingPredicate:predicateToFindPlatformView];
  if (![platformView waitForExistenceWithTimeout:kSecondsToWaitForPlatformView]) {
    NSLog(@"%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find any platformView with %@ seconds",
            @(kSecondsToWaitForPlatformView));
  }

  XCTAssertNotNil(platformView);
  XCTAssertEqualObjects(platformView.label, @"");

  NSPredicate* predicate =
      [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject,
                                            NSDictionary<NSString*, id>* _Nullable bindings) {
        XCUIElement* view = (XCUIElement*)evaluatedObject;
        return [view.label containsString:@"-gestureTouchesBegan"];
      }];
  XCTNSPredicateExpectation* expection =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:platformView];

  [platformView tap];
  [self waitForExpectations:@[ expection ] timeout:kSecondsToWaitForPlatformView];
  XCTAssertTrue([platformView.label containsString:@"-gestureTouchesBegan"]);
}

- (void)testAccept {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--gesture-accept" ];
  [app launch];

  NSPredicate* predicateToFindPlatformView =
      [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject,
                                            NSDictionary<NSString*, id>* _Nullable bindings) {
        XCUIElement* element = evaluatedObject;
        return [element.identifier hasPrefix:@"platform_view"];
      }];
  XCUIElement* platformView = [app.textViews elementMatchingPredicate:predicateToFindPlatformView];
  if (![platformView waitForExistenceWithTimeout:kSecondsToWaitForPlatformView]) {
    NSLog(@"%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find any platformView with %@ seconds",
            @(kSecondsToWaitForPlatformView));
  }

  XCTAssertNotNil(platformView);
  XCTAssertEqualObjects(platformView.label, @"");

  NSPredicate* predicate = [NSPredicate
      predicateWithFormat:@"label == %@",
                          @"-gestureTouchesBegan-gestureTouchesEnded-platformViewTapped"];
  XCTNSPredicateExpectation* expection =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:platformView];

  [platformView tap];
  [self waitForExpectations:@[ expection ] timeout:kSecondsToWaitForPlatformView];
  XCTAssertEqualObjects(platformView.label,
                        @"-gestureTouchesBegan-gestureTouchesEnded-platformViewTapped");
}

@end
