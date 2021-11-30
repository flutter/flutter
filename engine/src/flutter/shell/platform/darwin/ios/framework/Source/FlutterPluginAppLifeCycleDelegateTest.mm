// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"

FLUTTER_ASSERT_ARC

@interface FlutterPluginAppLifeCycleDelegate ()
- (void)application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary*)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler;
- (void)application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
- (void)application:(UIApplication*)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;
@end

@interface FlutterPluginAppLifeCycleDelegateSubclass : FlutterPluginAppLifeCycleDelegate
@property(nonatomic, strong) XCTestExpectation* didReceiveRemoteNotificationExpectation;
@end

@implementation FlutterPluginAppLifeCycleDelegateSubclass
- (void)performApplication:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary*)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
  [self.didReceiveRemoteNotificationExpectation fulfill];
  [super performApplication:application
      didReceiveRemoteNotification:userInfo
            fetchCompletionHandler:completionHandler];
}
@end

@interface FlutterPluginAppLifeCycleDelegateTest : XCTestCase
@end

@implementation FlutterPluginAppLifeCycleDelegateTest

- (void)testCreate {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  XCTAssertNotNil(delegate);
}

- (void)testDidEnterBackground {
  XCTNSNotificationExpectation* expectation = [[XCTNSNotificationExpectation alloc]
      initWithName:UIApplicationDidEnterBackgroundNotification];
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:nil];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMVerify([plugin applicationDidEnterBackground:[UIApplication sharedApplication]]);
}

- (void)testWillEnterForeground {
  XCTNSNotificationExpectation* expectation = [[XCTNSNotificationExpectation alloc]
      initWithName:UIApplicationWillEnterForegroundNotification];

  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:nil];
  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMVerify([plugin applicationWillEnterForeground:[UIApplication sharedApplication]]);
}

- (void)testWillResignActive {
  XCTNSNotificationExpectation* expectation =
      [[XCTNSNotificationExpectation alloc] initWithName:UIApplicationWillResignActiveNotification];

  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillResignActiveNotification
                    object:nil];
  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMVerify([plugin applicationWillResignActive:[UIApplication sharedApplication]]);
}

- (void)testDidBecomeActive {
  XCTNSNotificationExpectation* expectation =
      [[XCTNSNotificationExpectation alloc] initWithName:UIApplicationDidBecomeActiveNotification];

  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidBecomeActiveNotification
                    object:nil];
  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMVerify([plugin applicationDidBecomeActive:[UIApplication sharedApplication]]);
}

- (void)testWillTerminate {
  XCTNSNotificationExpectation* expectation =
      [[XCTNSNotificationExpectation alloc] initWithName:UIApplicationWillTerminateNotification];

  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification
                                                      object:nil];
  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMVerify([plugin applicationWillTerminate:[UIApplication sharedApplication]]);
}

- (void)testDidReceiveRemoteNotification {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  NSDictionary* info = @{};
  void (^handler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult result) {
  };
  XCTAssertTrue([delegate respondsToSelector:@selector
                          (application:didReceiveRemoteNotification:fetchCompletionHandler:)]);
  [delegate application:[UIApplication sharedApplication]
      didReceiveRemoteNotification:info
            fetchCompletionHandler:handler];
  [(NSObject<FlutterPlugin>*)[plugin verify] application:[UIApplication sharedApplication]
                            didReceiveRemoteNotification:info
                                  fetchCompletionHandler:handler];
}

- (void)flutterPluginAppLifeCycleDelegateSubclass {
  FlutterPluginAppLifeCycleDelegateSubclass* delegate =
      [[FlutterPluginAppLifeCycleDelegateSubclass alloc] init];
  XCTestExpectation* expecation = [self expectationWithDescription:@"subclass called"];
  delegate.didReceiveRemoteNotificationExpectation = expecation;
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  NSDictionary* info = @{};
  void (^handler)(UIBackgroundFetchResult) = ^(UIBackgroundFetchResult result) {
  };
  XCTAssertTrue([delegate respondsToSelector:@selector
                          (application:didReceiveRemoteNotification:fetchCompletionHandler:)]);
  [delegate application:[UIApplication sharedApplication]
      didReceiveRemoteNotification:info
            fetchCompletionHandler:handler];
  [(NSObject<FlutterPlugin>*)[plugin verify] application:[UIApplication sharedApplication]
                            didReceiveRemoteNotification:info
                                  fetchCompletionHandler:handler];
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testDidRegisterForRemoteNotificationsWithDeviceToken {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  NSData* token = [[NSData alloc] init];
  XCTAssertTrue([delegate
      respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]);
  [delegate application:[UIApplication sharedApplication]
      didRegisterForRemoteNotificationsWithDeviceToken:token];
  [(NSObject<FlutterPlugin>*)[plugin verify] application:[UIApplication sharedApplication]
        didRegisterForRemoteNotificationsWithDeviceToken:token];
}

- (void)testDidFailToRegisterForRemoteNotificationsWithError {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  NSError* error = [[NSError alloc] init];
  XCTAssertTrue([delegate
      respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]);
  [delegate application:[UIApplication sharedApplication]
      didFailToRegisterForRemoteNotificationsWithError:error];
  [(NSObject<FlutterPlugin>*)[plugin verify] application:[UIApplication sharedApplication]
        didFailToRegisterForRemoteNotificationsWithError:error];
}

@end
