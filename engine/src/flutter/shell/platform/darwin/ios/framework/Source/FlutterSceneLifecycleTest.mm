// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifecycle.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifecycle_Test.h"

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
  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);
}

- (void)testAddDuplicateFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  [delegate addFlutterEngine:mockEngine];
  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);
}

- (void)testAddMultipleFlutterEngine {
  FlutterPluginSceneLifeCycleDelegate* delegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];

  id mockEngine = OCMClassMock([FlutterEngine class]);
  [delegate addFlutterEngine:mockEngine];

  id mockEngine2 = OCMClassMock([FlutterEngine class]);
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

  @autoreleasepool {
    id mockEngine = OCMClassMock([FlutterEngine class]);
    [delegate addFlutterEngine:mockEngine];
    XCTAssertEqual(delegate.engines.count, 1.0);
  }

  id mockWindowScene = OCMClassMock([UIWindowScene class]);

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
  [delegate addFlutterEngine:mockEngine];
  XCTAssertEqual(delegate.engines.count, 1.0);

  id mockWindowScene = OCMClassMock([UIWindowScene class]);

  [delegate updateEnginesInScene:mockWindowScene];
  XCTAssertEqual(delegate.engines.count, 1.0);
}

@end
