// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneLifeCycle.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPluginAppLifeCycleDelegate_internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSharedApplication.h"

FLUTTER_ASSERT_ARC

@protocol TestFlutterPluginWithSceneEvents <NSObject,
                                            FlutterApplicationLifeCycleDelegate,
                                            FlutterSceneLifeCycleDelegate>
@end

@interface FakeTestFlutterPluginWithSceneEvents : NSObject <TestFlutterPluginWithSceneEvents>
@end

@implementation FakeTestFlutterPluginWithSceneEvents
- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  return NO;
}

- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options {
  return YES;
}

- (BOOL)application:(UIApplication*)application
    continueUserActivity:(NSUserActivity*)userActivity
      restorationHandler:(void (^)(NSArray*))restorationHandler {
  return YES;
}

- (BOOL)application:(UIApplication*)application
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler
    API_AVAILABLE(ios(9.0)) {
  return YES;
}
@end

@interface FakePlugin : NSObject <FlutterApplicationLifeCycleDelegate>
@end

@implementation FakePlugin
- (BOOL)application:(UIApplication*)application
            openURL:(NSURL*)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id>*)options {
  return YES;
}

- (BOOL)application:(UIApplication*)application
    continueUserActivity:(NSUserActivity*)userActivity
      restorationHandler:(void (^)(NSArray*))restorationHandler {
  return YES;
}

- (BOOL)application:(UIApplication*)application
    performActionForShortcutItem:(UIApplicationShortcutItem*)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler
    API_AVAILABLE(ios(9.0)) {
  return YES;
}

- (BOOL)application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  return YES;
}

- (BOOL)application:(UIApplication*)application
    willFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
  return YES;
}
@end

@interface FlutterPluginAppLifeCycleDelegateTest : XCTestCase
@end

@implementation FlutterPluginAppLifeCycleDelegateTest

- (void)testCreate {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  XCTAssertNotNil(delegate);
}

- (void)testSceneWillConnectFallback {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  id mockOptions = OCMClassMock([UISceneConnectionOptions class]);
  id mockShortcutItem = OCMClassMock([UIApplicationShortcutItem class]);
  OCMStub([mockOptions shortcutItem]).andReturn(mockShortcutItem);
  OCMStub([mockOptions sourceApplication]).andReturn(@"bundle_id");
  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSURL* url = [NSURL URLWithString:@"http://example.com"];
  OCMStub([urlContext URL]).andReturn(url);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];
  OCMStub([mockOptions URLContexts]).andReturn(urlContexts);

  NSDictionary<UIApplicationOpenURLOptionsKey, id>* expectedApplicationOptions = @{
    UIApplicationLaunchOptionsShortcutItemKey : mockShortcutItem,
    UIApplicationLaunchOptionsSourceApplicationKey : @"bundle_id",
    UIApplicationLaunchOptionsURLKey : url,
  };

  [delegate sceneWillConnectFallback:mockOptions];
  OCMVerify([mockPlugin application:[UIApplication sharedApplication]
      didFinishLaunchingWithOptions:expectedApplicationOptions]);
}

- (void)testSceneWillConnectFallbackSkippedSupportsScenes {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakeTestFlutterPluginWithSceneEvents alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  id mockOptions = OCMClassMock([UISceneConnectionOptions class]);
  id mockShortcutItem = OCMClassMock([UIApplicationShortcutItem class]);
  OCMStub([mockOptions shortcutItem]).andReturn(mockShortcutItem);
  OCMStub([mockOptions sourceApplication]).andReturn(@"bundle_id");
  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSURL* url = [NSURL URLWithString:@"http://example.com"];
  OCMStub([urlContext URL]).andReturn(url);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];
  OCMStub([mockOptions URLContexts]).andReturn(urlContexts);

  [delegate sceneWillConnectFallback:mockOptions];
  OCMReject([mockPlugin application:[OCMArg any] didFinishLaunchingWithOptions:[OCMArg any]]);
}

- (void)testSceneWillConnectFallbackSkippedNoOptions {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  id mockOptions = OCMClassMock([UISceneConnectionOptions class]);

  [delegate sceneWillConnectFallback:mockOptions];
  OCMReject([mockPlugin application:[OCMArg any] didFinishLaunchingWithOptions:[OCMArg any]]);
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

- (void)testDidEnterBackgroundWithUIScene {
  XCTNSNotificationExpectation* expectation = [[XCTNSNotificationExpectation alloc]
      initWithName:UIApplicationDidEnterBackgroundNotification];
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id mockApplication = OCMClassMock([FlutterSharedApplication class]);
  OCMStub([mockApplication hasSceneDelegate]).andReturn(YES);
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:nil];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMReject([plugin applicationDidEnterBackground:[OCMArg any]]);
}

- (void)testSceneDidEnterBackgroundFallback {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];

  [delegate sceneDidEnterBackgroundFallback];
  OCMVerify([plugin applicationDidEnterBackground:[UIApplication sharedApplication]]);
}

- (void)testUnnecessarySceneDidEnterBackgroundFallback {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(TestFlutterPluginWithSceneEvents));
  [delegate addDelegate:plugin];

  [delegate sceneDidEnterBackgroundFallback];
  OCMReject([plugin applicationDidEnterBackground:[OCMArg any]]);
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

- (void)testWillEnterForegroundWithUIScene {
  XCTNSNotificationExpectation* expectation = [[XCTNSNotificationExpectation alloc]
      initWithName:UIApplicationWillEnterForegroundNotification];
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id mockApplication = OCMClassMock([FlutterSharedApplication class]);
  OCMStub([mockApplication hasSceneDelegate]).andReturn(YES);
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:nil];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMReject([plugin applicationWillEnterForeground:[OCMArg any]]);
}

- (void)testSceneWillEnterForegroundFallback {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];

  [delegate sceneWillEnterForegroundFallback];
  OCMVerify([plugin applicationWillEnterForeground:[UIApplication sharedApplication]]);
}

- (void)testUnnecessarySceneWillEnterForegroundFallback {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(TestFlutterPluginWithSceneEvents));
  [delegate addDelegate:plugin];

  [delegate sceneWillEnterForegroundFallback];
  OCMReject([plugin applicationWillEnterForeground:[OCMArg any]]);
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

- (void)testWillResignActiveWithUIScene {
  XCTNSNotificationExpectation* expectation =
      [[XCTNSNotificationExpectation alloc] initWithName:UIApplicationWillResignActiveNotification];
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id mockApplication = OCMClassMock([FlutterSharedApplication class]);
  OCMStub([mockApplication hasSceneDelegate]).andReturn(YES);
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillResignActiveNotification
                    object:nil];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMReject([plugin applicationWillResignActive:[OCMArg any]]);
}

- (void)testSceneWillResignActiveFallback {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];

  [delegate sceneWillResignActiveFallback];
  OCMVerify([plugin applicationWillResignActive:[UIApplication sharedApplication]]);
}

- (void)testUnnecessarySceneWillResignActiveFallback {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(TestFlutterPluginWithSceneEvents));
  [delegate addDelegate:plugin];

  [delegate sceneWillResignActiveFallback];
  OCMReject([plugin applicationWillResignActive:[OCMArg any]]);
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

- (void)testDidBecomeActiveWithUIScene {
  XCTNSNotificationExpectation* expectation =
      [[XCTNSNotificationExpectation alloc] initWithName:UIApplicationDidBecomeActiveNotification];
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id mockApplication = OCMClassMock([FlutterSharedApplication class]);
  OCMStub([mockApplication hasSceneDelegate]).andReturn(YES);
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidBecomeActiveNotification
                    object:nil];

  [self waitForExpectations:@[ expectation ] timeout:5.0];
  OCMReject([plugin applicationDidBecomeActive:[OCMArg any]]);
}

- (void)testSceneDidBecomeActiveFallback {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(FlutterPlugin));
  [delegate addDelegate:plugin];

  [delegate sceneDidBecomeActiveFallback];
  OCMVerify([plugin applicationDidBecomeActive:[UIApplication sharedApplication]]);
}

- (void)testUnnecessarySceneDidBecomeActiveFallback {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = OCMProtocolMock(@protocol(TestFlutterPluginWithSceneEvents));
  [delegate addDelegate:plugin];

  [delegate sceneDidBecomeActiveFallback];
  OCMReject([plugin applicationDidBecomeActive:[OCMArg any]]);
}

- (void)testSceneFallbackOpenURLContexts {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSURL* url = [NSURL URLWithString:@"http://example.com"];
  OCMStub([urlContext URL]).andReturn(url);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  NSDictionary<UIApplicationOpenURLOptionsKey, id>* expectedApplicationOptions = @{
    UIApplicationOpenURLOptionsOpenInPlaceKey : @(NO),
  };

  [delegate sceneFallbackOpenURLContexts:urlContexts];
  OCMVerify([mockPlugin application:[UIApplication sharedApplication]
                            openURL:url
                            options:expectedApplicationOptions]);
}

- (void)testConvertURLOptions {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  NSString* bundleId = @"app.bundle.id";
  id annotation = @{@"key" : @"value"};
  id eventAttribution = OCMClassMock([UIEventAttribution class]);

  UIOpenURLContext* urlContext = OCMClassMock([UIOpenURLContext class]);
  NSURL* url = [NSURL URLWithString:@"http://example.com"];
  OCMStub([urlContext URL]).andReturn(url);
  id sceneOptions = OCMClassMock([UISceneOpenURLOptions class]);
  OCMStub([sceneOptions sourceApplication]).andReturn(bundleId);
  OCMStub([sceneOptions annotation]).andReturn(annotation);
  OCMStub([sceneOptions openInPlace]).andReturn(YES);
  OCMStub([sceneOptions eventAttribution]).andReturn(eventAttribution);

  OCMStub([urlContext options]).andReturn(sceneOptions);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  [delegate sceneFallbackOpenURLContexts:urlContexts];

  NSDictionary<UIApplicationOpenURLOptionsKey, id>* expectedApplicationOptions = @{
    UIApplicationOpenURLOptionsSourceApplicationKey : bundleId,
    UIApplicationOpenURLOptionsAnnotationKey : annotation,
    UIApplicationOpenURLOptionsOpenInPlaceKey : @(YES),
    UIApplicationOpenURLOptionsEventAttributionKey : eventAttribution,
  };

  OCMVerify([mockPlugin application:[UIApplication sharedApplication]
                            openURL:url
                            options:expectedApplicationOptions]);
}

- (void)testUnnecessarySceneFallbackOpenURLContexts {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakeTestFlutterPluginWithSceneEvents alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  [delegate sceneFallbackOpenURLContexts:urlContexts];
  OCMReject([mockPlugin application:[OCMArg any] openURL:[OCMArg any] options:[OCMArg any]]);
}

- (void)testSceneFallbackContinueUserActivity {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  id userActivity = OCMClassMock([NSUserActivity class]);

  [delegate sceneFallbackContinueUserActivity:userActivity];
  OCMVerify([mockPlugin application:[UIApplication sharedApplication]
               continueUserActivity:userActivity
                 restorationHandler:[OCMArg any]]);
}

- (void)testUnnecessarySceneFallbackContinueUserActivity {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakeTestFlutterPluginWithSceneEvents alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  id userActivity = OCMClassMock([NSUserActivity class]);

  [delegate sceneFallbackContinueUserActivity:userActivity];
  OCMReject([mockPlugin application:[UIApplication sharedApplication]
               continueUserActivity:userActivity
                 restorationHandler:[OCMArg any]]);
}

- (void)testSceneFallbackPerformActionForShortcutItem {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  FakePlugin* plugin = [[FakePlugin alloc] init];
  FakePlugin* mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  id shortcut = OCMClassMock([UIApplicationShortcutItem class]);
  id handler = ^(BOOL succeeded) {
  };

  [delegate sceneFallbackPerformActionForShortcutItem:shortcut completionHandler:handler];
  OCMVerify([mockPlugin application:[UIApplication sharedApplication]
       performActionForShortcutItem:shortcut
                  completionHandler:handler]);
}

- (void)testUnnecessarySceneFallbackPerformActionForShortcutItem {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  FakeTestFlutterPluginWithSceneEvents* plugin =
      [[FakeTestFlutterPluginWithSceneEvents alloc] init];
  FakeTestFlutterPluginWithSceneEvents* mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];

  id shortcut = OCMClassMock([UIApplicationShortcutItem class]);
  [delegate sceneFallbackPerformActionForShortcutItem:shortcut
                                    completionHandler:^(BOOL succeeded){
                                    }];
  OCMReject([mockPlugin application:[OCMArg any]
       performActionForShortcutItem:[OCMArg any]
                  completionHandler:[OCMArg any]]);
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

- (void)testReleasesPluginOnDealloc {
  __weak id<FlutterApplicationLifeCycleDelegate> weakPlugin;
  __weak FlutterPluginAppLifeCycleDelegate* weakDelegate;
  @autoreleasepool {
    FakePlugin* fakePlugin = [[FakePlugin alloc] init];
    weakPlugin = fakePlugin;
    FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
    [delegate addDelegate:fakePlugin];
    weakDelegate = delegate;
  }
  XCTAssertNil(weakPlugin);
  XCTAssertNil(weakDelegate);
}

- (void)testApplicationWillFinishLaunchingSceneFallbackForwards {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];
  id mockApplication = OCMClassMock([UIApplication class]);
  NSDictionary* options = @{};

  [delegate sceneFallbackWillFinishLaunchingApplication:mockApplication];
  OCMVerify(times(1), [mockPlugin application:mockApplication
                          willFinishLaunchingWithOptions:options]);
}

- (void)testApplicationWillFinishLaunchingSceneFallbackNoForwardAfterWillLaunch {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];
  id mockApplication = OCMClassMock([UIApplication class]);
  NSDictionary* options = @{@"key" : @"value"};

  [delegate application:mockApplication willFinishLaunchingWithOptions:options];
  [delegate sceneFallbackWillFinishLaunchingApplication:mockApplication];
  OCMVerify(times(1), [mockPlugin application:mockApplication
                          willFinishLaunchingWithOptions:options]);
}

- (void)testApplicationWillFinishLaunchingSceneFallbackNoForwardAfterDidLaunch {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];
  id mockApplication = OCMClassMock([UIApplication class]);
  NSDictionary* options = @{@"key" : @"value"};

  [delegate application:mockApplication didFinishLaunchingWithOptions:options];
  [delegate sceneFallbackWillFinishLaunchingApplication:mockApplication];
  OCMVerify(times(0), [mockPlugin application:mockApplication
                          willFinishLaunchingWithOptions:options]);
}

- (void)testApplicationDidFinishLaunchingSceneFallbackForwards {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];
  id mockApplication = OCMClassMock([UIApplication class]);
  NSDictionary* options = @{};

  [delegate sceneFallbackDidFinishLaunchingApplication:mockApplication];
  OCMVerify(times(1), [mockPlugin application:mockApplication
                          didFinishLaunchingWithOptions:options]);
}

- (void)testApplicationDidFinishLaunchingSceneFallbackNoForward {
  FlutterPluginAppLifeCycleDelegate* delegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
  id plugin = [[FakePlugin alloc] init];
  id mockPlugin = OCMPartialMock(plugin);
  [delegate addDelegate:mockPlugin];
  id mockApplication = OCMClassMock([UIApplication class]);
  NSDictionary* options = @{@"key" : @"value"};

  [delegate application:mockApplication didFinishLaunchingWithOptions:options];
  [delegate sceneFallbackDidFinishLaunchingApplication:mockApplication];
  OCMVerify(times(1), [mockPlugin application:mockApplication
                          didFinishLaunchingWithOptions:options]);
}

@end
