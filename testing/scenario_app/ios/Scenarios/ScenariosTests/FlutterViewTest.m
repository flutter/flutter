// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>
#import "AppDelegate.h"

@interface FlutterViewGLContextTest : XCTestCase
@property(nonatomic, strong) FlutterViewController* flutterViewController;
@property(nonatomic, strong) FlutterEngine* flutterEngine;
@end

@implementation FlutterViewGLContextTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
}

- (void)tearDown {
  if (self.flutterViewController) {
    [self.flutterViewController removeFromParentViewController];
    [self.flutterViewController release];
  }
  if (self.flutterEngine) {
    [self.flutterEngine release];
  }
  [super tearDown];
}

- (void)testFlutterViewDestroyed {
  self.flutterEngine = [[FlutterEngine alloc] initWithName:@"testGL" project:nil];
  [self.flutterEngine runWithEntrypoint:nil];
  self.flutterViewController = [[FlutterViewController alloc] initWithEngine:self.flutterEngine
                                                                     nibName:nil
                                                                      bundle:nil];

  AppDelegate* appDelegate = (AppDelegate*)UIApplication.sharedApplication.delegate;
  UIViewController* rootVC = appDelegate.window.rootViewController;
  [rootVC presentViewController:self.flutterViewController animated:NO completion:nil];

  // TODO: refactor this to not rely on private test-only APIs
  __weak id flutterView = [self.flutterViewController flutterView];
  XCTAssertNotNil(flutterView);
  XCTAssertTrue([self.flutterViewController hasOnscreenSurface]);

  [self.flutterViewController
      dismissViewControllerAnimated:NO
                         completion:^{
                           __weak id flutterView = [self.flutterViewController flutterView];
                           XCTAssertNil(flutterView);
                           XCTAssertFalse([self.flutterViewController hasOnscreenSurface]);
                         }];
}

@end
