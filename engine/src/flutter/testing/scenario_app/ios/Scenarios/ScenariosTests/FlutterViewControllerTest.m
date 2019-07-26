// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>
#import "AppDelegate.h"

@interface FlutterViewControllerTest : XCTestCase
@property(nonatomic, strong) FlutterViewController* flutterViewController;
@end

@implementation FlutterViewControllerTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
}

- (void)tearDown {
  if (self.flutterViewController) {
    [self.flutterViewController removeFromParentViewController];
  }
  [super tearDown];
}

- (void)testFirstFrameCallback {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"test" project:nil];
  [engine runWithEntrypoint:nil];
  self.flutterViewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                     nibName:nil
                                                                      bundle:nil];
  __block BOOL shouldKeepRunning = YES;
  [self.flutterViewController setFlutterViewDidRenderCallback:^{
    shouldKeepRunning = NO;
  }];
  AppDelegate* appDelegate = (AppDelegate*)UIApplication.sharedApplication.delegate;
  UIViewController* rootVC = appDelegate.window.rootViewController;
  [rootVC presentViewController:self.flutterViewController animated:NO completion:nil];
  NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
  int countDownMs = 2000;
  while (shouldKeepRunning && countDownMs > 0) {
    [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    countDownMs -= 100;
  }
  XCTAssertGreaterThan(countDownMs, 0);
}

@end
