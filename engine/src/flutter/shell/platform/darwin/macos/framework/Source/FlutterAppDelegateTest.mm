// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterAppDelegate.h"

#import "flutter/testing/testing.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"

@interface AppDelegateNoopFlutterAppLifecycleDelegate : NSObject <FlutterAppLifecycleDelegate>
@property(nonatomic, copy, nullable) NSArray<NSURL*>* receivedURLs;
@end

@implementation AppDelegateNoopFlutterAppLifecycleDelegate
@end

@interface AppDelegateTestFlutterAppLifecycleDelegate : NSObject <FlutterAppLifecycleDelegate>
@property(nonatomic, copy, nullable) NSArray<NSURL*>* receivedURLs;
@property(nonatomic, strong, nullable) NSUserActivity* receivedUserActivity;
@property(nonatomic, assign) BOOL disableHandlingUserActivity;
@end

@implementation AppDelegateTestFlutterAppLifecycleDelegate

- (BOOL)handleOpenURLs:(NSArray<NSURL*>*)urls {
  self.receivedURLs = [urls copy];
  return YES;
}

- (BOOL)handleContinueUserActivity:(NSUserActivity*)userActivity
                restorationHandler:
                    (void (^)(NSArray<id<NSUserActivityRestoring>>* restorableObjects))
                        restorationHandler {
  self.receivedUserActivity = userActivity;
  return !self.disableHandlingUserActivity;
}

@end

namespace flutter::testing {

TEST(FlutterAppDelegateTest, DoesNotCallDelegatesWithoutHandler) {
  FlutterAppDelegate* appDelegate = [[FlutterAppDelegate alloc] init];
  AppDelegateNoopFlutterAppLifecycleDelegate* noopDelegate =
      [[AppDelegateNoopFlutterAppLifecycleDelegate alloc] init];
  [appDelegate addApplicationLifecycleDelegate:noopDelegate];

  [appDelegate application:NSApplication.sharedApplication openURLs:@[]];
  // No EXPECT, since the test is that the call doesn't throw due to calling without checking that
  // the method is implemented.
}

TEST(FlutterAppDelegateTest, ReceivesOpenURLs) {
  FlutterAppDelegate* appDelegate = [[FlutterAppDelegate alloc] init];
  AppDelegateTestFlutterAppLifecycleDelegate* delegate =
      [[AppDelegateTestFlutterAppLifecycleDelegate alloc] init];
  [appDelegate addApplicationLifecycleDelegate:delegate];

  NSURL* URL = [NSURL URLWithString:@"https://flutter.dev"];
  EXPECT_NE(URL, nil);
  NSArray<NSURL*>* URLs = @[ URL ];
  [appDelegate application:NSApplication.sharedApplication openURLs:URLs];

  EXPECT_EQ([delegate receivedURLs], URLs);
}

TEST(FlutterAppDelegateTest, OperURLsStopsAfterHandled) {
  FlutterAppDelegate* appDelegate = [[FlutterAppDelegate alloc] init];
  AppDelegateTestFlutterAppLifecycleDelegate* firstDelegate =
      [[AppDelegateTestFlutterAppLifecycleDelegate alloc] init];
  AppDelegateTestFlutterAppLifecycleDelegate* secondDelegate =
      [[AppDelegateTestFlutterAppLifecycleDelegate alloc] init];
  [appDelegate addApplicationLifecycleDelegate:firstDelegate];
  [appDelegate addApplicationLifecycleDelegate:secondDelegate];

  NSURL* URL = [NSURL URLWithString:@"https://flutter.dev"];
  EXPECT_NE(URL, nil);
  NSArray<NSURL*>* URLs = @[ URL ];
  [appDelegate application:NSApplication.sharedApplication openURLs:URLs];

  EXPECT_EQ([firstDelegate receivedURLs], URLs);
  EXPECT_EQ([secondDelegate receivedURLs], nil);
}

TEST(FlutterAppDelegateTest, ContinueUserActivityReturnsNoWhenNotHandled) {
  FlutterAppDelegate* appDelegate = [[FlutterAppDelegate alloc] init];
  AppDelegateNoopFlutterAppLifecycleDelegate* noopDelegate =
      [[AppDelegateNoopFlutterAppLifecycleDelegate alloc] init];
  AppDelegateTestFlutterAppLifecycleDelegate* decliningDelegate =
      [[AppDelegateTestFlutterAppLifecycleDelegate alloc] init];
  decliningDelegate.disableHandlingUserActivity = YES;
  [appDelegate addApplicationLifecycleDelegate:noopDelegate];
  [appDelegate addApplicationLifecycleDelegate:decliningDelegate];

  NSUserActivity* userActivity =
      [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
  BOOL result = [appDelegate application:NSApplication.sharedApplication
                    continueUserActivity:userActivity
                      restorationHandler:^(NSArray<id<NSUserActivityRestoring>>* objects){
                      }];

  EXPECT_FALSE(result);
  EXPECT_EQ([decliningDelegate receivedUserActivity], userActivity);
}

TEST(FlutterAppDelegateTest, ReceivesContinueUserActivity) {
  FlutterAppDelegate* appDelegate = [[FlutterAppDelegate alloc] init];
  AppDelegateTestFlutterAppLifecycleDelegate* delegate =
      [[AppDelegateTestFlutterAppLifecycleDelegate alloc] init];
  [appDelegate addApplicationLifecycleDelegate:delegate];

  NSUserActivity* userActivity =
      [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
  BOOL result = [appDelegate application:NSApplication.sharedApplication
                    continueUserActivity:userActivity
                      restorationHandler:^(NSArray<id<NSUserActivityRestoring>>* objects){
                      }];

  EXPECT_TRUE(result);
  EXPECT_EQ([delegate receivedUserActivity], userActivity);
}

TEST(FlutterAppDelegateTest, ContinueUserActivityStopsAfterHandled) {
  FlutterAppDelegate* appDelegate = [[FlutterAppDelegate alloc] init];
  AppDelegateTestFlutterAppLifecycleDelegate* firstDelegate =
      [[AppDelegateTestFlutterAppLifecycleDelegate alloc] init];
  firstDelegate.disableHandlingUserActivity = YES;
  AppDelegateTestFlutterAppLifecycleDelegate* secondDelegate =
      [[AppDelegateTestFlutterAppLifecycleDelegate alloc] init];
  AppDelegateTestFlutterAppLifecycleDelegate* thirdDelegate =
      [[AppDelegateTestFlutterAppLifecycleDelegate alloc] init];
  [appDelegate addApplicationLifecycleDelegate:firstDelegate];
  [appDelegate addApplicationLifecycleDelegate:secondDelegate];
  [appDelegate addApplicationLifecycleDelegate:thirdDelegate];

  NSUserActivity* userActivity =
      [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
  BOOL result = [appDelegate application:NSApplication.sharedApplication
                    continueUserActivity:userActivity
                      restorationHandler:^(NSArray<id<NSUserActivityRestoring>>* objects){
                      }];

  EXPECT_TRUE(result);
  EXPECT_EQ([firstDelegate receivedUserActivity], userActivity);
  EXPECT_EQ([secondDelegate receivedUserActivity], userActivity);
  EXPECT_EQ([thirdDelegate receivedUserActivity], nil);
}

}  // namespace flutter::testing
