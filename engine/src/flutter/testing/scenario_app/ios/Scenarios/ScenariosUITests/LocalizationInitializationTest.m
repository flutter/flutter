// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>

FLUTTER_ASSERT_ARC

@interface LocalizationInitializationTest : XCTestCase
@property(nonatomic, strong) XCUIApplication* application;
@end

@implementation LocalizationInitializationTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;

  self.application = [[XCUIApplication alloc] init];
  self.application.launchArguments = @[ @"--locale-initialization" ];
  [self.application launch];
}

- (void)testNoLocalePrepend {
  NSTimeInterval timeout = 10.0;

  // The locales received by dart:ui are exposed onBeginFrame via semantics label.
  // There should only be one locale, since the default iOS app only has en_US as
  // the locale. The list should consist of just the en locale.
  XCUIElement* textInputSemanticsObject =
      [self.application.textFields matchingIdentifier:@"[en]"].element;
  XCTAssertTrue([textInputSemanticsObject waitForExistenceWithTimeout:timeout]);

  [textInputSemanticsObject tap];
}

@end
