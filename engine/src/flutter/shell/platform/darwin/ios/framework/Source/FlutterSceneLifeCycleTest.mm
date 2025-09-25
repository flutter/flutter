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

- (void)testAddFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);

  [delegate addFlutterEngine:mockEngine scene:mockWindowScene];
  XCTAssertEqual(delegate.engines.count, 1.0);
  OCMVerify(times(1), [mockLifecycleDelegate flutterViewDidConnectTo:mockWindowScene
                                                             options:[OCMArg isNil]]);
}

- (void)testAddDuplicateFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);
  id mockWindowScene2 = OCMClassMock([UIWindowScene class]);

  [delegate addFlutterEngine:mockEngine scene:mockWindowScene];
  [delegate addFlutterEngine:mockEngine scene:mockWindowScene];
  [delegate addFlutterEngine:mockEngine scene:mockWindowScene2];
  XCTAssertEqual(delegate.engines.count, 1.0);

  OCMVerify(times(1), [mockLifecycleDelegate flutterViewDidConnectTo:[OCMArg any]
                                                             options:[OCMArg any]]);
}

- (void)testAddMultipleFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);
  [delegate addFlutterEngine:mockEngine scene:mockWindowScene];

  id mockEngine2 = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate2 = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine2 sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate2);
  id mockWindowScene2 = OCMClassMock([UIWindowScene class]);
  [delegate addFlutterEngine:mockEngine2 scene:mockWindowScene2];

  XCTAssertEqual(delegate.engines.count, 2.0);
  OCMVerify(times(1), [mockLifecycleDelegate flutterViewDidConnectTo:mockWindowScene
                                                             options:[OCMArg isNil]]);
  OCMVerify(times(1), [mockLifecycleDelegate2 flutterViewDidConnectTo:mockWindowScene2
                                                              options:[OCMArg isNil]]);
}

- (void)testRemoveFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);
  [delegate addFlutterEngine:mockEngine scene:mockWindowScene];
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
    [delegate addFlutterEngine:mockEngine scene:mockWindowScene];
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

  [delegate addFlutterEngine:mockEngine scene:mockWindowScene];
  XCTAssertEqual(delegate.engines.count, 1.0);

  id mockWindowScene2 = OCMClassMock([UIWindowScene class]);

  [delegate updateEnginesInScene:mockWindowScene2];
  OCMVerify(times(1), [mockLifecycleDelegate addFlutterEngine:mockEngine scene:mockWindowScene]);
  XCTAssertEqual(delegate.engines.count, 0.0);
}

- (void)testUpdateEnginesInSceneDoesNotRemoveEngineWithNilScene {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];
  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);
  [delegate addFlutterEngine:mockEngine scene:mockWindowScene];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate updateEnginesInScene:mockWindowScene];
  XCTAssertEqual(delegate.engines.count, 1.0);
}

- (void)testSceneWillConnectToSessionOptions {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  id mockLifecycleDelegate = OCMClassMock([FlutterEnginePluginSceneLifeCycleDelegate class]);
  OCMStub([mockEngine sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);
  id mockSession = OCMClassMock([UISceneSession class]);
  id mockOptions = OCMClassMock([UISceneConnectionOptions class]);

  [delegate scene:mockWindowScene willConnectToSession:mockSession options:mockOptions];

  [delegate addFlutterEngine:mockEngine scene:mockWindowScene];
  XCTAssertEqual(delegate.engines.count, 1.0);
  OCMVerify(times(1), [mockLifecycleDelegate flutterViewDidConnectTo:mockWindowScene
                                                             options:mockOptions]);
}

- (void)testSceneDidDisconnect {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];

  [delegate addFlutterEngine:mockEngine scene:mockScene];
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

  [delegate addFlutterEngine:mockEngine scene:mockScene];
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

  [delegate addFlutterEngine:mockEngine scene:mockScene];
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

  [delegate addFlutterEngine:mockEngine scene:mockScene];
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

  [delegate addFlutterEngine:mockEngine scene:mockScene];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate sceneDidEnterBackground:mockScene];
  OCMVerify(times(1), [mockLifecycleDelegate sceneDidEnterBackground:mockScene]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneDidEnterBackgroundFallback]);
}

- (void)testSceneOpenURLContexts {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];

  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  [delegate addFlutterEngine:mockEngine scene:mockScene];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate scene:mockScene openURLContexts:urlContexts];
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene openURLContexts:urlContexts]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneFallbackOpenURLContexts:urlContexts]);
}

- (void)testSceneContinueUserActivity {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];

  id userActivity = OCMClassMock([NSUserActivity class]);

  [delegate addFlutterEngine:mockEngine scene:mockScene];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate scene:mockScene continueUserActivity:userActivity];
  OCMVerify(times(1), [mockLifecycleDelegate scene:mockScene continueUserActivity:userActivity]);
  OCMVerify(times(1), [mockAppLifecycleDelegate sceneFallbackContinueUserActivity:userActivity]);
}

- (void)testWindowScenePerformActionForShortcutItem {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mocks = [self mocksForEvents];
  id mockEngine = mocks[@"mockEngine"];
  id mockScene = mocks[@"mockScene"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  id mockAppLifecycleDelegate = mocks[@"mockAppLifecycleDelegate"];

  id shortcutItem = OCMClassMock([UIApplicationShortcutItem class]);
  id handler = ^(BOOL succeeded) {
  };

  [delegate addFlutterEngine:mockEngine scene:mockScene];
  XCTAssertEqual(delegate.engines.count, 1.0);

  [delegate windowScene:mockScene
      performActionForShortcutItem:shortcutItem
                 completionHandler:handler];
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

- (void)testFlutterViewDidConnectToScene {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  id mockPlugin = OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  [delegate addDelegate:mockPlugin];
  id mockScene = OCMClassMock([UIWindowScene class]);
  id mockOptions = OCMClassMock([UISceneConnectionOptions class]);

  [delegate flutterViewDidConnectTo:mockScene options:mockOptions];
  OCMVerify([mockPlugin flutterViewDidConnectTo:mockScene options:mockOptions]);
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

  id mockPlugin = OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  [delegate addDelegate:mockPlugin];
  id mockScene = OCMClassMock([UIWindowScene class]);
  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  [delegate scene:mockScene openURLContexts:urlContexts];
  OCMVerify([mockPlugin scene:mockScene openURLContexts:urlContexts]);
}

- (void)testEngineSceneContinueUserActivity {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  id mockPlugin = OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  [delegate addDelegate:mockPlugin];
  id mockScene = OCMClassMock([UIWindowScene class]);
  id userActivity = OCMClassMock([NSUserActivity class]);

  [delegate scene:mockScene continueUserActivity:userActivity];
  OCMVerify([mockPlugin scene:mockScene continueUserActivity:userActivity]);
}

- (void)testEngineWindowScenePerformActionForShortcutItem {
  FlutterEnginePluginSceneLifeCycleDelegate* delegate =
      [[FlutterEnginePluginSceneLifeCycleDelegate alloc] init];

  id mockPlugin = OCMProtocolMock(@protocol(FlutterSceneLifeCycleDelegate));
  [delegate addDelegate:mockPlugin];
  id mockScene = OCMClassMock([UIWindowScene class]);
  id shortcutItem = OCMClassMock([UIApplicationShortcutItem class]);
  id handler = ^(BOOL succeeded) {
  };

  [delegate windowScene:mockScene
      performActionForShortcutItem:shortcutItem
                 completionHandler:handler];
  OCMVerify([mockPlugin windowScene:mockScene
       performActionForShortcutItem:shortcutItem
                  completionHandler:handler]);
}

@end
