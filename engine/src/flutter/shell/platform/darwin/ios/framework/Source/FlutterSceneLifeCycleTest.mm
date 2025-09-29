// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPluginAppLifeCycleDelegate_internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSharedApplication.h"

FLUTTER_ASSERT_ARC

@interface FlutterSceneLifecycleTest : XCTestCase
@end

@implementation FlutterSceneLifecycleTest
- (void)setUp {
}

- (void)tearDown {
}

#pragma mark - FlutterPluginSceneLifeCycleDelegate

- (void)testAddFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);
}

- (void)testAddDuplicateFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  [delegate addFlutterEngine:mockEngine];
  [delegate addFlutterEngine:mockEngine];
  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);
}

- (void)testAddMultipleFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);
  [delegate addFlutterEngine:mockEngine];

  id mockEngine2 = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate2 = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine2 sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate2);
  [delegate addFlutterEngine:mockEngine2];

  XCTAssertEqual(delegate.engines.count, 2.0);
}

- (void)testRemoveFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate removeFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 0.0);
}

- (void)testRemoveNotFoundFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  XCTAssertEqual(delegate.engines.count, 0.0);

  [delegate removeFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 0.0);
}

- (void)testUpdateEnginesInSceneRemovesDeallocatedEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockWindowScene = OCMClassMock([UIWindowScene class]);

  @autoreleasepool {
    id mockEngine = OCMClassMock([FlutterEngine class]);
    [delegate addFlutterEngine:mockEngine];
    XCTAssertEqual(delegate.engines.count, 1.0);
  }

  [delegate updateEnginesInScene:mockWindowScene];
  XCTAssertEqual(delegate.engines.count, 0.0);
}

- (void)testUpdateEnginesInSceneRemovesEngineNotInScene {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockViewController = OCMClassMock([UIViewController class]);
  id mockView = OCMClassMock([UIView class]);
  id mockWindow = OCMClassMock([UIWindow class]);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);
  id mockLifecycleProvider = OCMProtocolMock(@protocol(FlutterSceneLifeCycleProvider));
  id mockLifecycleDelegate = OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine viewController]).andReturn(mockViewController);
  OCMStub([mockViewController view]).andReturn(mockView);
  OCMStub([mockView window]).andReturn(mockWindow);
  OCMStub([mockWindow windowScene]).andReturn(mockWindowScene);
  OCMStub([mockWindow windowScene]).andReturn(mockWindowScene);
  OCMStub([mockWindowScene delegate]).andReturn(mockLifecycleProvider);
  OCMStub([mockLifecycleProvider sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  id mockWindowScene2 = OCMClassMock([UIWindowScene class]);

  [delegate updateEnginesInScene:mockWindowScene2];
  OCMVerify(times(1), [mockLifecycleDelegate addFlutterEngine:mockEngine]);
  XCTAssertEqual(delegate.engines.count, 0.0);
}

- (void)testUpdateEnginesInSceneDoesNotRemoveEngineWithNilScene {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];
  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);
  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate updateEnginesInScene:mockWindowScene];
  XCTAssertEqual(delegate.engines.count, 1.0);
}

- (void)testEngineReceivedConnectNotificationForSceneBeforeActualEvent {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];
  FlutterPluginSceneLifeCycleDelegate* mockDelegate = OCMPartialMock(delegate);
  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any]
                  willConnectToSession:[OCMArg any]
                               options:[OCMArg any]])
      .andReturn(YES);

  // received notification
  [mockDelegate engine:mockEngine receivedConnectNotificationFor:mockScene];
  OCMVerify(times(1), [mockDelegate addFlutterEngine:mockEngine]);
  XCTAssertEqual(delegate.engines.count, 1.0);
  OCMVerify(times(0), [mockDelegate scene:[OCMArg any]
                          willConnectToSession:[OCMArg any]
                                       options:[OCMArg any]]);

  // actual event
  id session = OCMClassMock([UISceneSession class]);
  id options = OCMClassMock([UISceneConnectionOptions class]);
  [mockDelegate scene:mockScene willConnectToSession:session options:options];
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene
                              willConnectToSession:session
                                           options:options]);
  XCTAssertEqual(delegate.engines.count, 1.0);
}

- (void)testEngineReceivedConnectNotificationForSceneAfterActualEvent {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];
  FlutterPluginSceneLifeCycleDelegate* mockDelegate = OCMPartialMock(delegate);
  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any]
                  willConnectToSession:[OCMArg any]
                               options:[OCMArg any]])
      .andReturn(YES);

  // actual event
  id session = OCMClassMock([UISceneSession class]);
  id options = OCMClassMock([UISceneConnectionOptions class]);
  OCMStub([mockScene session]).andReturn(session);
  [mockDelegate scene:mockScene willConnectToSession:session options:options];
  XCTAssertEqual(delegate.engines.count, 0.0);
  OCMVerify(times(0), [mockLifecycleDelegate scene:mockScene
                              willConnectToSession:session
                                           options:options]);
  OCMStub([mockDelegate connectionOptions]).andReturn(options);

  // received notification
  [mockDelegate engine:mockEngine receivedConnectNotificationFor:mockScene];
  OCMVerify(times(1), [mockDelegate addFlutterEngine:mockEngine]);
  XCTAssertEqual(delegate.engines.count, 1.0);
  OCMVerify(times(2), [mockDelegate scene:mockScene
                          willConnectToSession:session
                                       options:options]);  // This is called twice because once is
                                                           // within the test itself.
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene
                              willConnectToSession:session
                                           options:options]);
}

- (void)testSceneWillConnectToSessionOptionsConsumedByScenePlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any]
                  willConnectToSession:[OCMArg any]
                               options:[OCMArg any]])
      .andReturn(YES);

  id session = OCMClassMock([UISceneSession class]);
  id options = OCMClassMock([UISceneConnectionOptions class]);

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertTrue([delegate scene:mockScene willConnectToSession:session options:options]);
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene
                              willConnectToSession:session
                                           options:options]);
}

- (void)testSceneWillConnectToSessionOptionsConsumedByNoPlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any]
                  willConnectToSession:[OCMArg any]
                               options:[OCMArg any]])
      .andReturn(NO);

  id session = OCMClassMock([UISceneSession class]);
  id options = OCMClassMock([UISceneConnectionOptions class]);

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertFalse([delegate scene:mockScene willConnectToSession:session options:options]);
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene
                              willConnectToSession:session
                                           options:options]);
}

- (void)testSceneDidDisconnect {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate sceneDidDisconnect:mockScene];
  OCMVerify(times(1), [mockLifecycleDelegate sceneDidDisconnect:mockScene]);
}

- (void)testSceneWillEnterForeground {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate sceneWillEnterForeground:mockScene];
  OCMVerify(times(1), [mockLifecycleDelegate sceneWillEnterForeground:mockScene]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneWillEnterForegroundFallback]);
}

- (void)testSceneDidBecomeActive {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate sceneDidBecomeActive:mockScene];
  OCMVerify(times(1), [mockLifecycleDelegate sceneDidBecomeActive:mockScene]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneDidBecomeActiveFallback]);
}

- (void)testSceneWillResignActive {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate sceneWillResignActive:mockScene];
  OCMVerify(times(1), [mockLifecycleDelegate sceneWillResignActive:mockScene]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneWillResignActiveFallback]);
}

- (void)testSceneDidEnterBackground {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate sceneDidEnterBackground:mockScene];
  OCMVerify(times(1), [mockLifecycleDelegate sceneDidEnterBackground:mockScene]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneDidEnterBackgroundFallback]);
}

- (void)testSceneOpenURLContextsConsumedByScenePlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any] openURLContexts:[OCMArg any]]).andReturn(YES);
  OCMStub([mockAppLifecycleDelegate sceneFallbackOpenURLContexts:[OCMArg any]]).andReturn(YES);

  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertTrue([delegate scene:mockScene openURLContexts:urlContexts]);
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene openURLContexts:urlContexts]);
  OCMVerify(times(0), [mockAppLifecycleDelegate sceneFallbackOpenURLContexts:urlContexts]);
}

- (void)testSceneOpenURLContextsConsumedByApplicationPlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any] openURLContexts:[OCMArg any]]).andReturn(NO);
  OCMStub([mockAppLifecycleDelegate sceneFallbackOpenURLContexts:[OCMArg any]]).andReturn(YES);

  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertTrue([delegate scene:mockScene openURLContexts:urlContexts]);
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene openURLContexts:urlContexts]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneFallbackOpenURLContexts:urlContexts]);
}

- (void)testSceneOpenURLContextsConsumedByNoPlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any] openURLContexts:[OCMArg any]]).andReturn(NO);
  OCMStub([mockAppLifecycleDelegate sceneFallbackOpenURLContexts:[OCMArg any]]).andReturn(NO);

  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertFalse([delegate scene:mockScene openURLContexts:urlContexts]);
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene openURLContexts:urlContexts]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneFallbackOpenURLContexts:urlContexts]);
}

- (void)testSceneContinueUserActivityConsumedByScenePlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any] continueUserActivity:[OCMArg any]])
      .andReturn(YES);
  OCMStub([mockAppLifecycleDelegate sceneFallbackContinueUserActivity:[OCMArg any]]).andReturn(YES);

  id userActivity = OCMClassMock([NSUserActivity class]);

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertTrue([delegate scene:mockScene continueUserActivity:userActivity]);
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene continueUserActivity:userActivity]);
  OCMVerify(times(0), [mockAppLifecycleDelegate sceneFallbackContinueUserActivity:userActivity]);
}

- (void)testSceneContinueUserActivityConsumedByApplicationPlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any] continueUserActivity:[OCMArg any]])
      .andReturn(NO);
  OCMStub([mockAppLifecycleDelegate sceneFallbackContinueUserActivity:[OCMArg any]]).andReturn(YES);

  id userActivity = OCMClassMock([NSUserActivity class]);

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertTrue([delegate scene:mockScene continueUserActivity:userActivity]);
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene continueUserActivity:userActivity]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneFallbackContinueUserActivity:userActivity]);
}

- (void)testSceneContinueUserActivityConsumedByNoPlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate scene:[OCMArg any] continueUserActivity:[OCMArg any]])
      .andReturn(NO);
  OCMStub([mockAppLifecycleDelegate sceneFallbackContinueUserActivity:[OCMArg any]]).andReturn(NO);

  id userActivity = OCMClassMock([NSUserActivity class]);

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertFalse([delegate scene:mockScene continueUserActivity:userActivity]);
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene continueUserActivity:userActivity]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneFallbackContinueUserActivity:userActivity]);
}

- (void)testWindowScenePerformActionForShortcutItemConsumedByScenePlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate windowScene:[OCMArg any]
                performActionForShortcutItem:[OCMArg any]
                           completionHandler:[OCMArg any]])
      .andReturn(YES);
  OCMStub([mockAppLifecycleDelegate sceneFallbackPerformActionForShortcutItem:[OCMArg any]
                                                            completionHandler:[OCMArg any]])
      .andReturn(YES);

  id shortcutItem = OCMClassMock([UIApplicationShortcutItem class]);
  id handler = ^(BOOL succeeded) {
  };

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertTrue([delegate windowScene:mockScene
         performActionForShortcutItem:shortcutItem
                    completionHandler:handler]);
  OCMVerify(times(1), [mockLifecycleDelegate windowScene:mockScene
                            performActionForShortcutItem:shortcutItem
                                       completionHandler:handler]);
  OCMVerify(times(0),
            [mockAppLifecycleDelegate sceneFallbackPerformActionForShortcutItem:shortcutItem
                                                              completionHandler:handler]);
}

- (void)testWindowScenePerformActionForShortcutItemConsumedByApplicationPlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate windowScene:[OCMArg any]
                performActionForShortcutItem:[OCMArg any]
                           completionHandler:[OCMArg any]])
      .andReturn(NO);
  OCMStub([mockAppLifecycleDelegate sceneFallbackPerformActionForShortcutItem:[OCMArg any]
                                                            completionHandler:[OCMArg any]])
      .andReturn(YES);

  id shortcutItem = OCMClassMock([UIApplicationShortcutItem class]);
  id handler = ^(BOOL succeeded) {
  };

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertTrue([delegate windowScene:mockScene
         performActionForShortcutItem:shortcutItem
                    completionHandler:handler]);
  OCMVerify(times(1), [mockLifecycleDelegate windowScene:mockScene
                            performActionForShortcutItem:shortcutItem
                                       completionHandler:handler]);
  OCMVerify(times(1),
            [mockAppLifecycleDelegate sceneFallbackPerformActionForShortcutItem:shortcutItem
                                                              completionHandler:handler]);
}

- (void)testWindowScenePerformActionForShortcutItemConsumedByNoPlugin {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  FlutterEnginePluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      (FlutterEnginePluginSceneLifeCycleDelegate*)mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];
  OCMStub([mockLifecycleDelegate windowScene:[OCMArg any]
                performActionForShortcutItem:[OCMArg any]
                           completionHandler:[OCMArg any]])
      .andReturn(NO);
  OCMStub([mockAppLifecycleDelegate sceneFallbackPerformActionForShortcutItem:[OCMArg any]
                                                            completionHandler:[OCMArg any]])
      .andReturn(NO);

  id shortcutItem = OCMClassMock([UIApplicationShortcutItem class]);
  id handler = ^(BOOL succeeded) {
  };

  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  XCTAssertFalse([delegate windowScene:mockScene
          performActionForShortcutItem:shortcutItem
                     completionHandler:handler]);
  OCMVerify(times(1), [mockLifecycleDelegate windowScene:mockScene
                            performActionForShortcutItem:shortcutItem
                                       completionHandler:handler]);
  OCMVerify(times(1),
            [mockAppLifecycleDelegate sceneFallbackPerformActionForShortcutItem:shortcutItem
                                                              completionHandler:handler]);
}

- (NSDictionary*)mocksForEvents {
  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);

  id mockAppDelegate = OCMClassMock([FlutterAppDelegate class]);
  OCMStub([mockApplication delegate]).andReturn(mockAppDelegate);

  id mockAppLifecycleDelegate = OCMClassMock([FlutterPluginAppLifeCycleDelegate class]);
  OCMStub([mockAppDelegate lifeCycleDelegate]).andReturn(mockAppLifecycleDelegate);

  id mockScene = OCMClassMock([UIWindowScene class]);

  return @{
    @"mockEngine" : mockEngine,
    @"mockScene" : mockScene,
    @"mockLifecycleDelegate" : mockLifecycleDelegate,
    @"mockAppLifecycleDelegate" : mockAppLifecycleDelegate,
  };
}

#pragma mark - FlutterEnginePluginSceneLifeCycleDelegate

- (void)testEngineSceneWillConnectToSession {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  NSObject<FlutterSceneLifeCycleDelegate>* mockPlugin =
      OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  OCMStub([mockPlugin scene:[OCMArg any] willConnectToSession:[OCMArg any] options:[OCMArg any]])
      .andReturn(YES);
  NSObject<FlutterSceneLifeCycleDelegate>* mockPlugin2 =
      OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  OCMStub([mockPlugin2 scene:[OCMArg any] willConnectToSession:[OCMArg any] options:[OCMArg any]])
      .andReturn(YES);

  [delegate addDelegate:mockPlugin];
  [delegate addDelegate:mockPlugin2];

  id mockScene = OCMClassMock([UIWindowScene class]);
  id mockSession = OCMClassMock([UISceneSession class]);
  id mockOptions = OCMClassMock([UISceneConnectionOptions class]);

  XCTAssertTrue([delegate scene:mockScene willConnectToSession:mockSession options:mockOptions]);
  OCMVerify(times(1), [mockPlugin scene:mockScene
                          willConnectToSession:mockSession
                                       options:mockOptions]);
  OCMVerify(times(1), [mockPlugin2 scene:mockScene willConnectToSession:mockSession options:nil]);
}

- (void)testEngineSceneDidDisconnect {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  id mockPlugin = OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  [delegate addDelegate:mockPlugin];
  id mockScene = OCMClassMock([UIWindowScene class]);
  [delegate sceneDidDisconnect:mockScene];
  OCMVerify([mockPlugin sceneDidDisconnect:mockScene]);
}

- (void)testEngineSceneWillEnterForeground {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  id mockPlugin = OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  [delegate addDelegate:mockPlugin];
  id mockScene = OCMClassMock([UIWindowScene class]);
  [delegate sceneWillEnterForeground:mockScene];
  OCMVerify([mockPlugin sceneWillEnterForeground:mockScene]);
}

- (void)testEngineSceneDidBecomeActive {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  id mockPlugin = OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  [delegate addDelegate:mockPlugin];
  id mockScene = OCMClassMock([UIWindowScene class]);
  [delegate sceneDidBecomeActive:mockScene];
  OCMVerify([mockPlugin sceneDidBecomeActive:mockScene]);
}

- (void)testEngineSceneWillResignActive {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  id mockPlugin = OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  [delegate addDelegate:mockPlugin];
  id mockScene = OCMClassMock([UIWindowScene class]);
  [delegate sceneWillResignActive:mockScene];
  OCMVerify([mockPlugin sceneWillResignActive:mockScene]);
}

- (void)testEngineSceneDidEnterBackground {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  id mockPlugin = OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  [delegate addDelegate:mockPlugin];
  id mockScene = OCMClassMock([UIWindowScene class]);
  [delegate sceneDidEnterBackground:mockScene];
  OCMVerify([mockPlugin sceneDidEnterBackground:mockScene]);
}

- (void)testEngineSceneOpenURLContexts {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  NSObject<FlutterSceneLifeCycleDelegate>* mockPlugin =
      OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  OCMStub([mockPlugin scene:[OCMArg any] openURLContexts:[OCMArg any]]).andReturn(YES);
  NSObject<FlutterSceneLifeCycleDelegate>* mockPlugin2 =
      OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  OCMStub([mockPlugin2 scene:[OCMArg any] openURLContexts:[OCMArg any]]).andReturn(YES);

  [delegate addDelegate:mockPlugin];
  [delegate addDelegate:mockPlugin2];

  id mockScene = OCMClassMock([UIWindowScene class]);
  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  XCTAssertTrue([delegate scene:mockScene openURLContexts:urlContexts]);
  OCMVerify(times(1), [mockPlugin scene:mockScene openURLContexts:urlContexts]);
  OCMVerify(times(0), [mockPlugin2 scene:mockScene openURLContexts:urlContexts]);
}

- (void)testEngineSceneContinueUserActivity {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  NSObject<FlutterSceneLifeCycleDelegate>* mockPlugin =
      OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  OCMStub([mockPlugin scene:[OCMArg any] continueUserActivity:[OCMArg any]]).andReturn(YES);
  NSObject<FlutterSceneLifeCycleDelegate>* mockPlugin2 =
      OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  OCMStub([mockPlugin2 scene:[OCMArg any] continueUserActivity:[OCMArg any]]).andReturn(YES);

  [delegate addDelegate:mockPlugin];
  [delegate addDelegate:mockPlugin2];

  id mockScene = OCMClassMock([UIWindowScene class]);
  id userActivity = OCMClassMock([NSUserActivity class]);

  XCTAssertTrue([delegate scene:mockScene continueUserActivity:userActivity]);
  OCMVerify(times(1), [mockPlugin scene:mockScene continueUserActivity:userActivity]);
  OCMVerify(times(0), [mockPlugin2 scene:mockScene continueUserActivity:userActivity]);
}

- (void)testEngineWindowScenePerformActionForShortcutItem {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  NSObject<FlutterSceneLifeCycleDelegate>* mockPlugin =
      OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  OCMStub([mockPlugin windowScene:[OCMArg any]
              performActionForShortcutItem:[OCMArg any]
                         completionHandler:[OCMArg any]])
      .andReturn(YES);
  NSObject<FlutterSceneLifeCycleDelegate>* mockPlugin2 =
      OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  OCMStub([mockPlugin2 windowScene:[OCMArg any]
              performActionForShortcutItem:[OCMArg any]
                         completionHandler:[OCMArg any]])
      .andReturn(YES);

  [delegate addDelegate:mockPlugin];
  [delegate addDelegate:mockPlugin2];

  id mockScene = OCMClassMock([UIWindowScene class]);
  id shortcutItem = OCMClassMock([UIApplicationShortcutItem class]);
  id handler = ^(BOOL succeeded) {
  };

  XCTAssertTrue([delegate windowScene:mockScene
         performActionForShortcutItem:shortcutItem
                    completionHandler:handler]);
  OCMVerify(times(1), [mockPlugin windowScene:mockScene
                          performActionForShortcutItem:shortcutItem
                                     completionHandler:handler]);
  OCMVerify(times(0), [mockPlugin2 windowScene:mockScene
                          performActionForShortcutItem:shortcutItem
                                     completionHandler:handler]);
}

@end
