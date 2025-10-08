// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPluginAppLifeCycleDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterAppDelegate_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneDelegate_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Internal.h"

@interface FlutterSceneDelegateTest : XCTestCase
@end

@implementation TestAppDelegate
@end

@implementation FlutterSceneDelegateTest

- (void)setUp {
}

- (void)tearDown {
}

- (void)testMoveRootViewControllerWhenWindow {
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);

  id mockAppDelegate = OCMClassMock([FlutterAppDelegate class]);
  OCMStub([mockApplication delegate]).andReturn(mockAppDelegate);

  id mockWindow = OCMClassMock([UIWindow class]);
  OCMStub([mockAppDelegate window]).andReturn(mockWindow);

  id mockRootViewController = OCMClassMock([UIViewController class]);
  OCMStub([mockWindow rootViewController]).andReturn(mockRootViewController);

  id scene = OCMClassMock([UIWindowScene class]);
  id session = OCMClassMock([UISceneSession class]);
  id connectionOptions = OCMClassMock([UISceneConnectionOptions class]);

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  FlutterSceneDelegate* mockSceneDelegate = OCMPartialMock(sceneDelegate);
  OCMStub([mockSceneDelegate moveRootViewControllerFrom:[OCMArg any] to:[OCMArg any]]);

  [mockSceneDelegate scene:scene willConnectToSession:session options:connectionOptions];

  OCMVerify(times(1), [mockSceneDelegate moveRootViewControllerFrom:mockAppDelegate to:scene]);
}

- (void)testMoveRootViewControllerWhenNoWindow {
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);

  id testAppDelegate = [[TestAppDelegate alloc] init];
  OCMStub([mockApplication delegate]).andReturn(testAppDelegate);

  id scene = OCMClassMock([UIWindowScene class]);
  id session = OCMClassMock([UISceneSession class]);
  id connectionOptions = OCMClassMock([UISceneConnectionOptions class]);

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  FlutterSceneDelegate* mockSceneDelegate = OCMPartialMock(sceneDelegate);
  OCMStub([mockSceneDelegate moveRootViewControllerFrom:[OCMArg any] to:[OCMArg any]]);

  [mockSceneDelegate scene:scene willConnectToSession:session options:connectionOptions];

  OCMReject([mockSceneDelegate moveRootViewControllerFrom:[OCMArg any] to:[OCMArg any]]);
}

- (void)testSceneWillConnectToSessionOptions {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  id mockLifecycleDelegate = OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);
  id session = OCMClassMock([UISceneSession class]);
  id connectionOptions = OCMClassMock([UISceneConnectionOptions class]);

  [(FlutterSceneDelegate*)mockSceneDelegate scene:scene
                             willConnectToSession:session
                                          options:connectionOptions];

  OCMVerify(times(1), [(FlutterSceneDelegate*)mockLifecycleDelegate scene:scene
                                                     willConnectToSession:session
                                                                  options:connectionOptions]);
}

- (void)testSceneDidDisconnect {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  id mockLifecycleDelegate = OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);

  [mockSceneDelegate sceneDidDisconnect:scene];

  OCMVerify(times(1), [mockLifecycleDelegate sceneDidDisconnect:scene]);
}

- (void)testSceneWillEnterForeground {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  id mockLifecycleDelegate = OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);

  [mockSceneDelegate sceneWillEnterForeground:scene];

  OCMVerify(times(1), [mockLifecycleDelegate sceneWillEnterForeground:scene]);
}

- (void)testSceneDidBecomeActive {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  id mockLifecycleDelegate = OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);

  [mockSceneDelegate sceneDidBecomeActive:scene];

  OCMVerify(times(1), [mockLifecycleDelegate sceneDidBecomeActive:scene]);
}

- (void)testSceneWillResignActive {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  id mockLifecycleDelegate = OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);

  [mockSceneDelegate sceneWillResignActive:scene];

  OCMVerify(times(1), [mockLifecycleDelegate sceneWillResignActive:scene]);
}

- (void)testSceneDidEnterBackground {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  id mockLifecycleDelegate = OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);

  [mockSceneDelegate sceneDidEnterBackground:scene];

  OCMVerify(times(1), [mockLifecycleDelegate sceneDidEnterBackground:scene]);
}

- (void)testSceneOpenURLContexts {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  FlutterPluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);
  id urlContext = OCMClassMock([UIOpenURLContext class]);
  NSSet<UIOpenURLContext*>* urlContexts = [NSSet setWithObjects:urlContext, nil];

  [((FlutterSceneDelegate*)mockSceneDelegate) scene:scene openURLContexts:urlContexts];

  OCMVerify(times(1), [mockLifecycleDelegate scene:scene openURLContexts:urlContexts]);
}

- (void)testSceneContinueUserActivity {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  FlutterPluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);
  id userActivity = OCMClassMock([NSUserActivity class]);

  [((FlutterSceneDelegate*)mockSceneDelegate) scene:scene continueUserActivity:userActivity];

  OCMVerify(times(1), [mockLifecycleDelegate scene:scene continueUserActivity:userActivity]);
}

- (void)testStateRestorationActivityForScene {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  FlutterPluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);

  [((FlutterSceneDelegate*)mockSceneDelegate) stateRestorationActivityForScene:scene];

  OCMVerify(times(1), [mockLifecycleDelegate stateRestorationActivityForScene:scene]);
}

- (void)testSceneRestoreInteractionStateWithUserActivity {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  FlutterPluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);
  id userActivity = OCMClassMock([NSUserActivity class]);

  [((FlutterSceneDelegate*)mockSceneDelegate) scene:scene
            restoreInteractionStateWithUserActivity:userActivity];

  OCMVerify(times(1), [mockLifecycleDelegate scene:scene
                          restoreInteractionStateWithUserActivity:userActivity]);
}

- (void)testWindowScenePerformActionForShortcutItem {
  [self setupMockApplication];

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  FlutterPluginSceneLifeCycleDelegate* mockLifecycleDelegate =
      OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  id scene = OCMClassMock([UIWindowScene class]);
  id shortcutItem = OCMClassMock([UIApplicationShortcutItem class]);

  [((FlutterSceneDelegate*)mockSceneDelegate) windowScene:scene
                             performActionForShortcutItem:shortcutItem
                                        completionHandler:^(BOOL succeeded){
                                        }];

  OCMVerify(times(1), [mockLifecycleDelegate windowScene:scene
                            performActionForShortcutItem:shortcutItem
                                       completionHandler:[OCMArg any]]);
}

- (void)testRegisterSceneLifeCycleWithFlutterEngine {
  [self setupMockApplication];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  id mockLifecycleDelegate = OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  [mockSceneDelegate registerSceneLifeCycleWithFlutterEngine:mockEngine];

  OCMVerify(times(1), [mockLifecycleDelegate registerSceneLifeCycleWithFlutterEngine:mockEngine]);
}

- (void)testUnregisterSceneLifeCycleWithFlutterEngine {
  [self setupMockApplication];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  id mockLifecycleDelegate = OCMClassMock([FlutterPluginSceneLifeCycleDelegate class]);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  [mockSceneDelegate unregisterSceneLifeCycleWithFlutterEngine:mockEngine];

  OCMVerify(times(1), [mockLifecycleDelegate unregisterSceneLifeCycleWithFlutterEngine:mockEngine]);
}

- (NSDictionary*)setupMockApplication {
  id mockApplication = OCMClassMock([UIApplication class]);
  OCMStub([mockApplication sharedApplication]).andReturn(mockApplication);

  id testAppDelegate = [[TestAppDelegate alloc] init];
  OCMStub([mockApplication delegate]).andReturn(testAppDelegate);

  return @{
    @"mockApplication" : mockApplication,
    @"testAppDelegate" : testAppDelegate,
  };
}

@end
