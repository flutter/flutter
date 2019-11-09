// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

@interface PlatformViewGLTests : XCTestCase

@property(nonatomic, strong) XCUIApplication* application;

@end

@implementation PlatformViewGLTests

- (void)setUp {
  self.continueAfterFailure = NO;

  self.application = [[XCUIApplication alloc] init];
  self.application.launchArguments = @[ @"--platform-view-gl" ];
  [self.application launch];
}

- (void)testExample {
  NSPredicate* predicateToFindPlatformView =
      [NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject,
                                            NSDictionary<NSString*, id>* _Nullable bindings) {
        XCUIElement* element = evaluatedObject;
        return [element.identifier isEqualToString:@"gl_platformview_wrong_context"] ||
               [element.identifier isEqualToString:@"gl_platformview_correct_context"];
      }];
  XCUIElement* firstElement =
      [self.application.otherElements elementMatchingPredicate:predicateToFindPlatformView];
  if (![firstElement waitForExistenceWithTimeout:30]) {
    XCTFail(@"Failed due to not able to find platform view with 30 seconds");
  }
  XCTAssertEqualObjects(firstElement.identifier, @"gl_platformview_correct_context");
}

@end
