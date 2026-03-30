// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterSceneDelegate.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterOverlayView.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSceneLifeCycle_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"

FLUTTER_ASSERT_ARC

@interface FlutterView (Testing)
- (BOOL)isWideGamutSupported;
@end

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
  return [self createWindowMocksWithWideGamut:NO];
}

- (NSDictionary*)createWindowMocksWithWideGamut:(BOOL)enableWideGamut {
  id mockEngine = OCMClassMock([FlutterEngine class]);
  FlutterView* view = [[FlutterView alloc] initWithDelegate:mockEngine
                                                     opaque:NO
                                            enableWideGamut:enableWideGamut];
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

#pragma mark - Wide Gamut Tests

// Helper: add FlutterView to a real UIWindow so that layoutSubviews can access screen.
- (FlutterView*)createViewInWindowWithWideGamut:(BOOL)enableWideGamut {
  FakeDelegate* delegate = [[FakeDelegate alloc] init];
  FlutterView* view = [[FlutterView alloc] initWithDelegate:delegate
                                                     opaque:NO
                                            enableWideGamut:enableWideGamut];
  // Add to a real window so layoutSubviews has access to screen.
  UIWindow* window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  [window addSubview:view];
  view.frame = window.bounds;
  [view layoutSubviews];
  return view;
}

- (void)testWideGamutViewSetsBGRA10XRPixelFormat {
  FlutterView* view = [self createViewInWindowWithWideGamut:YES];
  // On a wide gamut capable device, the pixel format should be BGRA10_XR.
  // On non-wide-gamut devices, it falls back to BGRA8Unorm.
  if ([view isWideGamutSupported]) {
    XCTAssertEqual(view.pixelFormat, MTLPixelFormatBGRA10_XR);
  } else {
    XCTAssertEqual(view.pixelFormat, MTLPixelFormatBGRA8Unorm);
  }
}

- (void)testStandardGamutViewKeepsBGRA8Unorm {
  FlutterView* view = [self createViewInWindowWithWideGamut:NO];
  XCTAssertEqual(view.pixelFormat, MTLPixelFormatBGRA8Unorm);
}

- (void)testWideGamutViewSetsExtendedSRGBColorSpace {
  FlutterView* view = [self createViewInWindowWithWideGamut:YES];
  if ([view isWideGamutSupported]) {
    CAMetalLayer* layer = (CAMetalLayer*)view.layer;
    CGColorSpaceRef colorSpace = layer.colorspace;
    XCTAssertNotNil((__bridge id)colorSpace);
    CGColorSpaceRef extendedSRGB = CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
    XCTAssertTrue(CFEqual(colorSpace, extendedSRGB));
    CGColorSpaceRelease(extendedSRGB);
  }
}

- (void)testStandardGamutViewDoesNotSetExtendedColorSpace {
  FlutterView* view = [self createViewInWindowWithWideGamut:NO];
  CAMetalLayer* layer = (CAMetalLayer*)view.layer;
  // Default CAMetalLayer colorspace is nil (device default sRGB).
  XCTAssertNil((__bridge id)layer.colorspace);
}

#pragma mark - FlutterOverlayView Wide Gamut Tests

- (void)testOverlayViewWideGamutSetsBGRA10XR {
  FlutterOverlayView* overlay =
      [[FlutterOverlayView alloc] initWithContentsScale:2.0 pixelFormat:MTLPixelFormatBGRA10_XR];
  CAMetalLayer* layer = (CAMetalLayer*)overlay.layer;
  XCTAssertEqual(layer.pixelFormat, MTLPixelFormatBGRA10_XR);
}

- (void)testOverlayViewWideGamutSetsExtendedSRGBColorSpace {
  FlutterOverlayView* overlay =
      [[FlutterOverlayView alloc] initWithContentsScale:2.0 pixelFormat:MTLPixelFormatBGRA10_XR];
  CAMetalLayer* layer = (CAMetalLayer*)overlay.layer;
  CGColorSpaceRef colorSpace = layer.colorspace;
  XCTAssertNotNil((__bridge id)colorSpace);
  CGColorSpaceRef extendedSRGB = CGColorSpaceCreateWithName(kCGColorSpaceExtendedSRGB);
  XCTAssertTrue(CFEqual(colorSpace, extendedSRGB));
  CGColorSpaceRelease(extendedSRGB);
}

- (void)testOverlayViewStandardGamutKeepsBGRA8Unorm {
  FlutterOverlayView* overlay =
      [[FlutterOverlayView alloc] initWithContentsScale:2.0 pixelFormat:MTLPixelFormatBGRA8Unorm];
  CAMetalLayer* layer = (CAMetalLayer*)overlay.layer;
  XCTAssertEqual(layer.pixelFormat, MTLPixelFormatBGRA8Unorm);
}

- (void)testOverlayViewStandardGamutDoesNotSetExtendedColorSpace {
  FlutterOverlayView* overlay =
      [[FlutterOverlayView alloc] initWithContentsScale:2.0 pixelFormat:MTLPixelFormatBGRA8Unorm];
  CAMetalLayer* layer = (CAMetalLayer*)overlay.layer;
  XCTAssertNil((__bridge id)layer.colorspace);
}

- (void)testOverlayViewContentsScaleIsSet {
  FlutterOverlayView* overlay =
      [[FlutterOverlayView alloc] initWithContentsScale:3.0 pixelFormat:MTLPixelFormatBGRA10_XR];
  XCTAssertEqual(overlay.layer.contentsScale, 3.0);
  XCTAssertEqual(overlay.layer.rasterizationScale, 3.0);
}

@end
