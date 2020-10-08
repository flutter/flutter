// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>

@interface RenderingSelectionTest : XCTestCase
@property(nonatomic, strong) XCUIApplication* application;
@end

@implementation RenderingSelectionTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
  self.application = [[XCUIApplication alloc] init];
}

- (void)testSoftwareRendering {
  self.application.launchArguments =
      @[ @"--animated-color-square", @"--assert-ca-layer-type", @"--enable-software-rendering" ];
  [self.application launch];

  // App asserts that the rendering API is CALayer
}

- (void)testMetalRendering {
  self.application.launchArguments = @[ @"--animated-color-square", @"--assert-ca-layer-type" ];
  [self.application launch];

  // App asserts that the rendering API is CAMetalLayer
}
@end
