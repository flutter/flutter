// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifecycle.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifecycle_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"

FLUTTER_ASSERT_ARC

@interface FlutterSceneLifecycleTest : XCTestCase
@end

@implementation FlutterSceneLifecycleTest
- (void)setUp {
}

- (void)tearDown {
}

- (void)testAddSingleFlutterViewController {
  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];
  id mockLifecycleDelegate = OCMPartialMock(lifecycleDelegate);

  id mockViewController = [self createMockFlutterViewController:mockSceneDelegate
                                          mockLifecycleDelegate:mockLifecycleDelegate];

  [mockViewController viewIsAppearing:NO];

  OCMVerify(times(1), [lifecycleDelegate addFlutterViewController:mockViewController]);
  XCTAssertEqual(lifecycleDelegate.engines.count, 1.0);
}

- (void)testAddDuplicateFlutterViewController {
  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];
  id mockLifecycleDelegate = OCMPartialMock(lifecycleDelegate);

  id mockViewController = [self createMockFlutterViewController:mockSceneDelegate
                                          mockLifecycleDelegate:mockLifecycleDelegate];

  [mockViewController viewIsAppearing:NO];
  [mockViewController viewIsAppearing:NO];

  OCMVerify(times(2), [lifecycleDelegate addFlutterViewController:mockViewController]);
  XCTAssertEqual(lifecycleDelegate.engines.count, 1.0);
}

- (void)testAddMultipleFlutterViewControllerFromMultipleEngines {
  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];
  id mockLifecycleDelegate = OCMPartialMock(lifecycleDelegate);

  id mockViewController = [self createMockFlutterViewController:mockSceneDelegate
                                          mockLifecycleDelegate:mockLifecycleDelegate];

  id mockViewController2 = [self createMockFlutterViewController:mockSceneDelegate
                                           mockLifecycleDelegate:mockLifecycleDelegate];

  [mockViewController viewIsAppearing:NO];
  [mockViewController2 viewIsAppearing:NO];
  [mockViewController viewIsAppearing:NO];

  OCMVerify([lifecycleDelegate addFlutterViewController:mockViewController]);
  OCMVerify([lifecycleDelegate addFlutterViewController:mockViewController2]);
  XCTAssertEqual(lifecycleDelegate.engines.count, 2.0);
}

- (id)createMockFlutterViewController:(id)mockSceneDelegate
                mockLifecycleDelegate:(id)mockLifecycleDelegate {
  id mockEngine = OCMClassMock([FlutterEngine class]);
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:mockEngine
                                                                                nibName:nil
                                                                                 bundle:nil];

  FlutterViewController* mockViewController = OCMPartialMock(viewController);
  OCMStub([mockEngine viewController]).andReturn(viewController);
  OCMStub([mockViewController engine]).andReturn(mockEngine);

  id mockView = OCMClassMock([FlutterView class]);
  id mockWindow = OCMClassMock([UIWindow class]);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);

  OCMStub([mockViewController view]).andReturn(mockView);
  OCMStub([mockView window]).andReturn(mockWindow);
  OCMStub([mockWindow windowScene]).andReturn(mockWindowScene);
  OCMStub([mockWindowScene delegate]).andReturn(mockSceneDelegate);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);
  return mockViewController;
}

@end
