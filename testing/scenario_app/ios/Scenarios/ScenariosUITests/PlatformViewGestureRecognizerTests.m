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
  app.launchArguments =
      @[ @"--gesture-reject-after-touches-ended", @"--enable-software-rendering" ];
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
  XCTNSPredicateExpectation* exception =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:platformView];

  [platformView tap];
  [self waitForExpectations:@[ exception ] timeout:kSecondsToWaitForPlatformView];
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
  XCTNSPredicateExpectation* exception =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:platformView];

  [platformView tap];
  [self waitForExpectations:@[ exception ] timeout:kSecondsToWaitForPlatformView];
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
  XCTNSPredicateExpectation* exception =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:platformView];

  [platformView tap];

  [self waitForExpectations:@[ exception ] timeout:kSecondsToWaitForPlatformView];
  XCTAssertEqualObjects(platformView.label,
                        @"-gestureTouchesBegan-gestureTouchesEnded-platformViewTapped");
}

- (void)testGestureWithMaskViewBlockingPlatformView {
  XCUIApplication* app = [[XCUIApplication alloc] init];
  app.launchArguments = @[ @"--gesture-accept", @"--maskview-blocking" ];
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
  XCTNSPredicateExpectation* exception =
      [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:platformView];

  XCUICoordinate* coordinate =
      [self getNormalizedCoordinate:app
                              point:CGVectorMake(platformView.frame.origin.x + 10,
                                                 platformView.frame.origin.y + 10)];
  [coordinate tap];

  [self waitForExpectations:@[ exception ] timeout:kSecondsToWaitForPlatformView];
  XCTAssertEqualObjects(platformView.label,
                        @"-gestureTouchesBegan-gestureTouchesEnded-platformViewTapped");
}

- (XCUICoordinate*)getNormalizedCoordinate:(XCUIApplication*)app point:(CGVector)vector {
  XCUICoordinate* appZero = [app coordinateWithNormalizedOffset:CGVectorMake(0, 0)];
  XCUICoordinate* coordinate = [appZero coordinateWithOffset:vector];
  return coordinate;
}

@end
