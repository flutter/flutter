// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"

#ifndef __has_feature
#define __has_feature(x) 0 /* for non-clang compilers */
#endif

#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@interface FlutterPluginAppLifeCycleDelegateTest : XCTestCase

@end

@implementation FlutterPluginAppLifeCycleDelegateTest

- (void)testCreate {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  XCTAssertNotNil(delegate);
}

- (void)testDidEnterBackground {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:nil];
  OCMVerify([plugin applicationDidEnterBackground:[UIApplication sharedApplication]]);
}

- (void)testWillEnterForeground {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:nil];
  OCMVerify([plugin applicationWillEnterForeground:[UIApplication sharedApplication]]);
}

- (void)testWillResignActive {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillResignActiveNotification
                    object:nil];
  OCMVerify([plugin applicationWillResignActive:[UIApplication sharedApplication]]);
}

- (void)testDidBecomeActive {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidBecomeActiveNotification
                    object:nil];
  OCMVerify([plugin applicationDidBecomeActive:[UIApplication sharedApplication]]);
}

- (void)testWillTerminate {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification
                                                      object:nil];
  OCMVerify([plugin applicationWillTerminate:[UIApplication sharedApplication]]);
}

@end
