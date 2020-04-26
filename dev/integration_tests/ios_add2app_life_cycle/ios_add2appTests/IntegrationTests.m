// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <EarlGrey/EarlGrey.h>
#import <XCTest/XCTest.h>

#import "AppDelegate.h"
#import "FullScreenViewController.h"

@interface FlutterTests : XCTestCase
@end

@implementation FlutterTests

- (void)expectSemanticsNotification:(UIViewController*)viewController
                             engine:(FlutterEngine*)engine {
   // Flutter app will only send semantics update if test passes in main.dart.
  [self expectationForNotification:FlutterSemanticsUpdateNotification object:viewController handler:nil];
  [self waitForExpectationsWithTimeout:30.0 handler:nil];
}

- (void)checkAppConnection {
  FlutterEngine *engine = [((AppDelegate *)[[UIApplication sharedApplication] delegate]) engine];
  UINavigationController *navController =
       (UINavigationController *)((AppDelegate *)
            [[UIApplication sharedApplication]
                 delegate])
       .window.rootViewController;
  __weak UIViewController *weakViewController = navController.visibleViewController;
  [self expectSemanticsNotification:weakViewController
                             engine:engine];
  GREYAssertNotNil(weakViewController,
                   @"Expected non-nil FullScreenViewController.");
}

- (void)testFullScreenCanPop {
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Full Screen (Cold)")]
      performAction:grey_tap()];
  [self checkAppConnection];
}

@end
