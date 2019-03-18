// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <EarlGrey/EarlGrey.h>
#import <XCTest/XCTest.h>

#import "../ios_add2app/AppDelegate.h"
#import "../ios_add2app/DualFlutterViewController.h"
#import "../ios_add2app/FullScreenViewController.h"
#import "../ios_add2app/MainViewController.h"
#import "../ios_add2app/HybridViewController.h"

static void waitForFlutterSemanticsTree(FlutterViewController *viewController) {
  int tries = 10;
  double delay = 1.0;

  // ensureSemanticsEnabled is a synchronous call, but only ensures that the
  // semantics tree will be built on a subsequent frame (as opposed to being
  // available at time it returns).
  // To actually get the tree, we have to wait for the FlutterSemanticsUpdate
  // notification, which lets us know that a semantics tree has been built;
  // but we cannot block the main thread while waiting (so we use
  // CFRunLoopRunInMode).

  __block BOOL semanticsAvailable = NO;
  __block id<NSObject> observer = [[NSNotificationCenter defaultCenter]
      addObserverForName:@"FlutterSemanticsUpdate"
                  object:viewController
                   queue:nil
              usingBlock:^(NSNotification *notification) {
                semanticsAvailable = YES;
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
              }];
  [viewController.engine ensureSemanticsEnabled];
  while (semanticsAvailable == NO && tries != 0) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, delay, false);
    tries--;
    [viewController.engine ensureSemanticsEnabled];
  }
  GREYAssertTrue(semanticsAvailable, @"Semantics Tree did not build!");
}

@interface FlutterTests : XCTestCase
@end

@implementation FlutterTests {
  int _flutterWarmEngineTaps;
}

- (instancetype)init {
  self = [super init];

  if (self) {
    _flutterWarmEngineTaps = 0;
  }

  return self;
}

- (void)testFullScreenCanPop {
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Full Screen (Cold)")]
      performAction:grey_tap()];

  __weak FlutterViewController *weakViewController;
  @autoreleasepool {
    UINavigationController *navController =
        (UINavigationController *)((AppDelegate *)
                                       [[UIApplication sharedApplication]
                                           delegate])
            .window.rootViewController;
    weakViewController =
        (FullScreenViewController *)navController.visibleViewController;
    waitForFlutterSemanticsTree(weakViewController);
    GREYAssertNotNil(weakViewController,
                     @"Expected non-nil FullScreenViewController.");
  }

  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"POP")]
      performAction:grey_tap()];
  // EarlGrey v1 isn't good at detecting this yet - 2.0 will be able to do it
  int tries = 10;
  double delay = 1.0;
  while (weakViewController != nil && tries != 0) {
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, delay, false);
    tries--;
  }
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Native iOS View")]
      assertWithMatcher:grey_sufficientlyVisible()];
  GREYAssertNil(weakViewController,
                @"Expected FullScreenViewController to be deallocated.");
}

- (void)testDualFlutterView {
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey
      selectElementWithMatcher:grey_buttonTitle(@"Dual Flutter View (Cold)")]
      performAction:grey_tap()];

  @autoreleasepool {
    UINavigationController *navController =
        (UINavigationController *)((AppDelegate *)
                                       [[UIApplication sharedApplication]
                                           delegate])
            .window.rootViewController;
    DualFlutterViewController *viewController =
        (DualFlutterViewController *)navController.visibleViewController;
    GREYAssertNotNil(viewController,
                     @"Expected non-nil DualFlutterViewController.");
    waitForFlutterSemanticsTree(viewController.topFlutterViewController);
    waitForFlutterSemanticsTree(viewController.bottomFlutterViewController);
  }

  // Verify that there are two Flutter views with the expected marquee text.
  [[[EarlGrey
      selectElementWithMatcher:grey_accessibilityLabel(@"This is Marquee")]
      atIndex:0] assertWithMatcher:grey_notNil()];
  [[[EarlGrey
      selectElementWithMatcher:grey_accessibilityLabel(@"This is Marquee")]
      atIndex:1] assertWithMatcher:grey_notNil()];

  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Back")]
      performAction:grey_tap()];

  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Native iOS View")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)testHybridView {
  [[EarlGrey selectElementWithMatcher:grey_keyWindow()]
      assertWithMatcher:grey_sufficientlyVisible()];

  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Hybrid View (Warm)")]
      performAction:grey_tap()];

  @autoreleasepool {
    UINavigationController *navController =
        (UINavigationController *)((AppDelegate *)
                                       [[UIApplication sharedApplication]
                                           delegate])
            .window.rootViewController;
    HybridViewController *viewController =
        (HybridViewController *)navController.visibleViewController;
    GREYAssertNotNil(viewController.flutterViewController,
                     @"Expected non-nil FlutterViewController.");
    waitForFlutterSemanticsTree(viewController.flutterViewController);
  }

  [self validateCountsFlutter:@"Platform" count:0];
  [self validateCountsPlatform:@"Flutter" count:_flutterWarmEngineTaps];

  static const int platformTapCount = 4;
  static const int flutterTapCount = 6;

  for (int i = _flutterWarmEngineTaps; i < flutterTapCount;
       i++, _flutterWarmEngineTaps++) {
    [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(
                                            @"Increment via Flutter")]
        performAction:grey_tap()];
  }

  [self validateCountsFlutter:@"Platform" count:0];
  [self validateCountsPlatform:@"Flutter" count:_flutterWarmEngineTaps];

  for (int i = 0; i < platformTapCount; i++) {
    [[EarlGrey
        selectElementWithMatcher:grey_accessibilityLabel(@"Increment via iOS")]
        performAction:grey_tap()];
  }

  [self validateCountsFlutter:@"Platform" count:platformTapCount];
  [self validateCountsPlatform:@"Flutter" count:_flutterWarmEngineTaps];

  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Back")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_buttonTitle(@"Native iOS View")]
      assertWithMatcher:grey_sufficientlyVisible()];
}

/** Validates that the text labels showing the number of button taps match the
 * expected counts. */
- (void)validateCountsFlutter:(NSString *)labelPrefix count:(int)flutterCount {
  NSString *flutterCountStr =
      [NSString stringWithFormat:@"%@ button tapped %d times.", labelPrefix,
                                 flutterCount];

  // TODO(https://github.com/flutter/flutter/issues/17988): Flutter doesn't
  // expose accessibility IDs, so the best we can do is to search for an element
  // with the text we expect.
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(flutterCountStr)]
      assertWithMatcher:grey_sufficientlyVisible()];
}

- (void)validateCountsPlatform:(NSString *)labelPrefix
                         count:(int)platformCount {
  NSString *platformCountStr =
      [NSString stringWithFormat:@"%@ button tapped %d times.", labelPrefix,
                                 platformCount];

  [[[EarlGrey selectElementWithMatcher:grey_accessibilityID(@"counter_on_iOS")]
      assertWithMatcher:grey_text(platformCountStr)]
      assertWithMatcher:grey_sufficientlyVisible()];
}

@end
