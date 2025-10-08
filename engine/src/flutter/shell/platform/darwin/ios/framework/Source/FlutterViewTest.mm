// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"

FLUTTER_ASSERT_ARC

@interface FakeDelegate : NSObject <FlutterViewEngineDelegate>
@property(nonatomic) BOOL callbackCalled;
@end

@implementation FakeDelegate

@synthesize platformViewsController = _platformViewsController;

- (instancetype)init {
  _callbackCalled = NO;
  return self;
}

- (flutter::Rasterizer::Screenshot)takeScreenshot:(flutter::Rasterizer::ScreenshotType)type
                                  asBase64Encoded:(BOOL)base64Encode {
  return {};
}

- (void)flutterViewAccessibilityDidCall {
  _callbackCalled = YES;
}

@end

@interface FlutterViewTest : XCTestCase
@end

@implementation FlutterViewTest

- (void)testFlutterViewEnableSemanticsWhenIsAccessibilityElementIsCalled {
  FakeDelegate* delegate = [[FakeDelegate alloc] init];
  FlutterView* view = [[FlutterView alloc] initWithDelegate:delegate opaque:NO enableWideGamut:NO];
  delegate.callbackCalled = NO;
  XCTAssertFalse(view.isAccessibilityElement);
  XCTAssertTrue(delegate.callbackCalled);
}

- (void)testFlutterViewBackgroundColorIsNil {
  FakeDelegate* delegate = [[FakeDelegate alloc] init];
  FlutterView* view = [[FlutterView alloc] initWithDelegate:delegate opaque:NO enableWideGamut:NO];
  XCTAssertNil(view.backgroundColor);
}

- (void)testLayerScalesMatchScreenAfterLayoutSubviews {
  FakeDelegate* delegate = [[FakeDelegate alloc] init];
  FlutterView* view = [[FlutterView alloc] initWithDelegate:delegate opaque:NO enableWideGamut:NO];
  view.layer.contentsScale = CGFloat(-99.0);
  view.layer.rasterizationScale = CGFloat(-99.0);
  UIScreen* screen = [view screen];
  XCTAssertNotEqual(view.layer.contentsScale, screen.scale);
  XCTAssertNotEqual(view.layer.rasterizationScale, screen.scale);
  [view layoutSubviews];
  XCTAssertEqual(view.layer.contentsScale, screen.scale);
  XCTAssertEqual(view.layer.rasterizationScale, screen.scale);
}

- (void)testViewWillMoveToWindow {
  NSDictionary* mocks = [self createWindowMocks];
  FlutterView* view = (FlutterView*)mocks[@"view"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate =
      (FlutterPluginSceneLifeCycleDelegate*)mocks[@"lifecycleDelegate"];
  id mockEngine = mocks[@"mockEngine"];
  id mockWindow = mocks[@"mockWindow"];

  [view willMoveToWindow:mockWindow];
  OCMVerify(times(1), [mockLifecycleDelegate addFlutterManagedEngine:mockEngine]);
  XCTAssertEqual(lifecycleDelegate.flutterManagedEngines.count, 1.0);
}

- (void)testViewWillMoveToSameWindow {
  NSDictionary* mocks = [self createWindowMocks];
  FlutterView* view = (FlutterView*)mocks[@"view"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate =
      (FlutterPluginSceneLifeCycleDelegate*)mocks[@"lifecycleDelegate"];
  id mockEngine = mocks[@"mockEngine"];
  id mockWindow = mocks[@"mockWindow"];

  [view willMoveToWindow:mockWindow];
  [view willMoveToWindow:mockWindow];

  OCMVerify(times(2), [mockLifecycleDelegate addFlutterManagedEngine:mockEngine]);
  XCTAssertEqual(lifecycleDelegate.flutterManagedEngines.count, 1.0);
}

- (void)testMultipleViewsWillMoveToSameWindow {
  NSDictionary* mocks = [self createWindowMocks];
  FlutterView* view1 = (FlutterView*)mocks[@"view"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate =
      (FlutterPluginSceneLifeCycleDelegate*)mocks[@"lifecycleDelegate"];
  id mockEngine1 = mocks[@"mockEngine"];
  id mockWindow1 = mocks[@"mockWindow"];

  id mockEngine2 = OCMClassMock([FlutterEngine class]);
  FlutterView* view2 = [[FlutterView alloc] initWithDelegate:mockEngine2
                                                      opaque:NO
                                             enableWideGamut:NO];

  [view1 willMoveToWindow:mockWindow1];
  [view2 willMoveToWindow:mockWindow1];
  [view1 willMoveToWindow:mockWindow1];
  OCMVerify(times(2), [mockLifecycleDelegate addFlutterManagedEngine:mockEngine1]);
  OCMVerify(times(1), [mockLifecycleDelegate addFlutterManagedEngine:mockEngine2]);
  XCTAssertEqual(lifecycleDelegate.flutterManagedEngines.count, 2.0);
}

- (void)testMultipleViewsWillMoveToDifferentWindow {
  NSDictionary* mocks = [self createWindowMocks];
  FlutterView* view1 = (FlutterView*)mocks[@"view"];
  id mockLifecycleDelegate1 = mocks[@"mockLifecycleDelegate"];
  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate1 =
      (FlutterPluginSceneLifeCycleDelegate*)mocks[@"lifecycleDelegate"];
  id mockEngine1 = mocks[@"mockEngine"];
  id mockWindow1 = mocks[@"mockWindow"];

  NSDictionary* mocks2 = [self createWindowMocks];
  FlutterView* view2 = (FlutterView*)mocks2[@"view"];
  id mockLifecycleDelegate2 = mocks2[@"mockLifecycleDelegate"];
  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate2 =
      (FlutterPluginSceneLifeCycleDelegate*)mocks2[@"lifecycleDelegate"];
  id mockEngine2 = mocks2[@"mockEngine"];
  id mockWindow2 = mocks2[@"mockWindow"];

  [view1 willMoveToWindow:mockWindow1];
  [view2 willMoveToWindow:mockWindow2];
  [view1 willMoveToWindow:mockWindow1];
  OCMVerify(times(2), [mockLifecycleDelegate1 addFlutterManagedEngine:mockEngine1]);
  OCMVerify(times(1), [mockLifecycleDelegate2 addFlutterManagedEngine:mockEngine2]);
  XCTAssertEqual(lifecycleDelegate1.flutterManagedEngines.count, 1.0);
  XCTAssertEqual(lifecycleDelegate2.flutterManagedEngines.count, 1.0);
}

- (void)testViewRemovedFromWindowAndAddedToNewScene {
  NSDictionary* mocks = [self createWindowMocks];
  FlutterView* view = (FlutterView*)mocks[@"view"];
  id mockLifecycleDelegate = mocks[@"mockLifecycleDelegate"];
  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate =
      (FlutterPluginSceneLifeCycleDelegate*)mocks[@"lifecycleDelegate"];
  id mockEngine = mocks[@"mockEngine"];
  id mockWindow = mocks[@"mockWindow"];

  NSDictionary* mocks2 = [self createWindowMocks];
  id mockWindow2 = mocks2[@"mockWindow"];
  id mockLifecycleDelegate2 = mocks2[@"mockLifecycleDelegate"];
  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate2 =
      (FlutterPluginSceneLifeCycleDelegate*)mocks2[@"lifecycleDelegate"];

  id mockView = OCMPartialMock(view);

  [mockView willMoveToWindow:mockWindow];
  OCMVerify(times(1), [mockLifecycleDelegate addFlutterManagedEngine:mockEngine]);
  XCTAssertEqual(lifecycleDelegate.flutterManagedEngines.count, 1.0);

  OCMStub([mockView window]).andReturn(mockWindow);
  [mockView willMoveToWindow:nil];
  XCTAssertEqual(lifecycleDelegate.flutterManagedEngines.count, 1.0);

  OCMStub([mockView window]).andReturn(nil);
  [mockView willMoveToWindow:mockWindow2];
  OCMVerify(times(1), [mockLifecycleDelegate removeFlutterManagedEngine:mockEngine]);
  XCTAssertEqual(lifecycleDelegate.flutterManagedEngines.count, 0.0);
  OCMVerify(times(1), [mockLifecycleDelegate2 addFlutterManagedEngine:mockEngine]);
  XCTAssertEqual(lifecycleDelegate2.flutterManagedEngines.count, 1.0);
}

- (NSDictionary*)createWindowMocks {
  id mockEngine = OCMClassMock([FlutterEngine class]);
  FlutterView* view = [[FlutterView alloc] initWithDelegate:mockEngine
                                                     opaque:NO
                                            enableWideGamut:NO];
  id mockWindow = OCMClassMock([UIWindow class]);
  id mockWindowScene = OCMClassMock([UIWindowScene class]);

  FlutterSceneDelegate* sceneDelegate = [[FlutterSceneDelegate alloc] init];
  id mockSceneDelegate = OCMPartialMock(sceneDelegate);

  FlutterPluginSceneLifeCycleDelegate* lifecycleDelegate =
      [[FlutterPluginSceneLifeCycleDelegate alloc] init];
  id mockLifecycleDelegate = OCMPartialMock(lifecycleDelegate);

  OCMStub([mockWindow windowScene]).andReturn(mockWindowScene);
  OCMStub([mockWindowScene delegate]).andReturn(mockSceneDelegate);
  OCMStub([mockSceneDelegate sceneLifeCycleDelegate]).andReturn(mockLifecycleDelegate);

  return @{
    @"view" : view,
    @"mockLifecycleDelegate" : mockLifecycleDelegate,
    @"lifecycleDelegate" : lifecycleDelegate,
    @"mockEngine" : mockEngine,
    @"mockWindow" : mockWindow,
  };
}

@end
