// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "PlatformViewController.h"

@interface PlatformViewControllerTests : XCTestCase
@property (nonatomic, strong) XCUIApplication *app;
@end

@implementation PlatformViewControllerTests

- (void)setUp {
  // Put setup code here.
  // This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here.
  // This method is called after the invocation of each test method in the class.
}

- (void)testViewControllerIconLoaded {
  UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
  PlatformViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"PlatformView"];
  XCTAssertNotNil(controller);
  [controller loadViewIfNeeded];

  UIImage* incrementButtonIcon = [controller.incrementButton imageForState:UIControlStateNormal];
  XCTAssertNotNil(incrementButtonIcon);
}

@end
