// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "display_list/geometry/dl_geometry_types.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"

#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <XCTest/XCTest.h>

#include <memory>

#include "flutter/display_list/effects/dl_image_filters.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/thread.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewsController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTouchInterceptingView_Test.h"
#include "flutter/shell/platform/darwin/ios/ios_context_noop.h"
#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"

FLUTTER_ASSERT_ARC

@class FlutterPlatformViewsTestMockPlatformView;
__weak static UIView* gMockPlatformView = nil;
const float kFloatCompareEpsilon = 0.001;

@interface FlutterPlatformViewsTestMockPlatformView : UIView
@end
@implementation FlutterPlatformViewsTestMockPlatformView

- (instancetype)init {
  self = [super init];
  if (self) {
    gMockPlatformView = self;
  }
  return self;
}

- (void)dealloc {
  gMockPlatformView = nil;
}

@end

// A mock recognizer without "TouchEventsGestureRecognizer" suffix in class name.
// This is to verify a fix to a bug on iOS 26 where web view link is not tappable.
// We reset the web view's WKTouchEventsGestureRecognizer in a bad state
// by disabling and re-enabling it.
// See: https://github.com/flutter/flutter/issues/175099.
@interface MockGestureRecognizer : UIGestureRecognizer
@property(nonatomic, strong) NSMutableArray<NSNumber*>* toggleHistory;
@end

@implementation MockGestureRecognizer
- (instancetype)init {
  self = [super init];
  if (self) {
    _toggleHistory = [NSMutableArray array];
  }
  return self;
}
- (void)setEnabled:(BOOL)enabled {
  [super setEnabled:enabled];
  [self.toggleHistory addObject:@(enabled)];
}
@end

// A mock recognizer with "TouchEventsGestureRecognizer" suffix in class name.
@interface MockTouchEventsGestureRecognizer : MockGestureRecognizer
@end

@implementation MockTouchEventsGestureRecognizer
@end

@interface FlutterPlatformViewsTestMockFlutterPlatformView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView* view;
@property(nonatomic, assign) BOOL viewCreated;
@end

@implementation FlutterPlatformViewsTestMockFlutterPlatformView

- (instancetype)init {
  if (self = [super init]) {
    _view = [[FlutterPlatformViewsTestMockPlatformView alloc] init];
    _viewCreated = NO;
  }
  return self;
}

- (UIView*)view {
  [self checkViewCreatedOnce];
  return _view;
}

- (void)checkViewCreatedOnce {
  if (self.viewCreated) {
    abort();
  }
  self.viewCreated = YES;
}

- (void)dealloc {
  gMockPlatformView = nil;
}
@end

@interface FlutterPlatformViewsTestMockFlutterPlatformFactory
    : NSObject <FlutterPlatformViewFactory>
@end

@implementation FlutterPlatformViewsTestMockFlutterPlatformFactory
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  return [[FlutterPlatformViewsTestMockFlutterPlatformView alloc] init];
}

@end

@interface FlutterPlatformViewsTestMockWebView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView* view;
@property(nonatomic, assign) BOOL viewCreated;
@end

@implementation FlutterPlatformViewsTestMockWebView
- (instancetype)init {
  if (self = [super init]) {
    _view = [[WKWebView alloc] init];
    gMockPlatformView = _view;
    _viewCreated = NO;
  }
  return self;
}

- (UIView*)view {
  [self checkViewCreatedOnce];
  return _view;
}

- (void)checkViewCreatedOnce {
  if (self.viewCreated) {
    abort();
  }
  self.viewCreated = YES;
}

- (void)dealloc {
  gMockPlatformView = nil;
}
@end

@interface FlutterPlatformViewsTestMockWebViewFactory : NSObject <FlutterPlatformViewFactory>
@end

@implementation FlutterPlatformViewsTestMockWebViewFactory
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  return [[FlutterPlatformViewsTestMockWebView alloc] init];
}
@end

@interface FlutterPlatformViewsTestNilFlutterPlatformFactory : NSObject <FlutterPlatformViewFactory>
@end

@implementation FlutterPlatformViewsTestNilFlutterPlatformFactory
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  return nil;
}

@end

@interface FlutterPlatformViewsTestMockWrapperWebView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView* view;
@property(nonatomic, assign) BOOL viewCreated;
@end

@implementation FlutterPlatformViewsTestMockWrapperWebView
- (instancetype)init {
  if (self = [super init]) {
    _view = [[UIView alloc] init];
    [_view addSubview:[[WKWebView alloc] init]];
    gMockPlatformView = _view;
    _viewCreated = NO;
  }
  return self;
}

- (UIView*)view {
  [self checkViewCreatedOnce];
  return _view;
}

- (void)checkViewCreatedOnce {
  if (self.viewCreated) {
    abort();
  }
  self.viewCreated = YES;
}

- (void)dealloc {
  gMockPlatformView = nil;
}
@end

@interface FlutterPlatformViewsTestMockWrapperWebViewFactory : NSObject <FlutterPlatformViewFactory>
@end

@implementation FlutterPlatformViewsTestMockWrapperWebViewFactory
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  return [[FlutterPlatformViewsTestMockWrapperWebView alloc] init];
}
@end

@interface FlutterPlatformViewsTestMockNestedWrapperWebView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView* view;
@property(nonatomic, assign) BOOL viewCreated;
@end

@implementation FlutterPlatformViewsTestMockNestedWrapperWebView
- (instancetype)init {
  if (self = [super init]) {
    _view = [[UIView alloc] init];
    UIView* childView = [[UIView alloc] init];
    [_view addSubview:childView];
    [childView addSubview:[[WKWebView alloc] init]];
    gMockPlatformView = _view;
    _viewCreated = NO;
  }
  return self;
}

- (UIView*)view {
  [self checkViewCreatedOnce];
  return _view;
}

- (void)checkViewCreatedOnce {
  if (self.viewCreated) {
    abort();
  }
  self.viewCreated = YES;
}
@end

@interface FlutterPlatformViewsTestMockNestedWrapperWebViewFactory
    : NSObject <FlutterPlatformViewFactory>
@end

@implementation FlutterPlatformViewsTestMockNestedWrapperWebViewFactory
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  return [[FlutterPlatformViewsTestMockNestedWrapperWebView alloc] init];
}
@end

namespace flutter {
namespace {
class FlutterPlatformViewsTestMockPlatformViewDelegate : public PlatformView::Delegate {
 public:
  void OnPlatformViewCreated(std::unique_ptr<Surface> surface) override {}
  void OnPlatformViewDestroyed() override {}
  void OnPlatformViewScheduleFrame() override {}
  void OnPlatformViewAddView(int64_t view_id,
                             const ViewportMetrics& viewport_metrics,
                             AddViewCallback callback) override {}
  void OnPlatformViewRemoveView(int64_t view_id, RemoveViewCallback callback) override {}
  void OnPlatformViewSendViewFocusEvent(const ViewFocusEvent& event) override {};
  void OnPlatformViewSetNextFrameCallback(const fml::closure& closure) override {}
  void OnPlatformViewSetViewportMetrics(int64_t view_id, const ViewportMetrics& metrics) override {}
  const flutter::Settings& OnPlatformViewGetSettings() const override { return settings_; }
  void OnPlatformViewDispatchPlatformMessage(std::unique_ptr<PlatformMessage> message) override {}
  void OnPlatformViewDispatchPointerDataPacket(std::unique_ptr<PointerDataPacket> packet) override {
  }
  void OnPlatformViewDispatchSemanticsAction(int64_t view_id,
                                             int32_t node_id,
                                             SemanticsAction action,
                                             fml::MallocMapping args) override {}
  void OnPlatformViewSetSemanticsEnabled(bool enabled) override {}
  void OnPlatformViewSetAccessibilityFeatures(int32_t flags) override {}
  void OnPlatformViewRegisterTexture(std::shared_ptr<Texture> texture) override {}
  void OnPlatformViewUnregisterTexture(int64_t texture_id) override {}
  void OnPlatformViewMarkTextureFrameAvailable(int64_t texture_id) override {}

  void LoadDartDeferredLibrary(intptr_t loading_unit_id,
                               std::unique_ptr<const fml::Mapping> snapshot_data,
                               std::unique_ptr<const fml::Mapping> snapshot_instructions) override {
  }
  void LoadDartDeferredLibraryError(intptr_t loading_unit_id,
                                    const std::string error_message,
                                    bool transient) override {}
  void UpdateAssetResolverByType(std::unique_ptr<flutter::AssetResolver> updated_asset_resolver,
                                 flutter::AssetResolver::AssetResolverType type) override {}

  flutter::Settings settings_;
};

BOOL BlurRadiusEqualToBlurRadius(CGFloat radius1, CGFloat radius2) {
  const CGFloat epsilon = 0.01;
  return std::abs(radius1 - radius2) < epsilon;
}

}  // namespace
}  // namespace flutter

@interface FlutterPlatformViewsTest : XCTestCase
@end

@implementation FlutterPlatformViewsTest

namespace {
fml::RefPtr<fml::TaskRunner> GetDefaultTaskRunner() {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  return fml::MessageLoop::GetCurrent().GetTaskRunner();
}
}  // namespace

- (void)testFlutterViewOnlyCreateOnceInOneFrame {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a translate matrix
  flutter::DlMatrix translateMatrix = flutter::DlMatrix::MakeTranslation({100, 100});
  stack.PushTransform(translateMatrix);
  flutter::DlMatrix finalMatrix = screenScaleMatrix * translateMatrix;

  auto embeddedViewParams =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];

  XCTAssertNotNil(gMockPlatformView);

  [flutterPlatformViewsController reset];
}

- (void)testCanCreatePlatformViewWithoutFlutterView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);
}

- (void)testChildClippingViewHitTests {
  ChildClippingView* childClippingView =
      [[ChildClippingView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  UIView* childView = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
  [childClippingView addSubview:childView];

  XCTAssertFalse([childClippingView pointInside:CGPointMake(50, 50) withEvent:nil]);
  XCTAssertFalse([childClippingView pointInside:CGPointMake(99, 100) withEvent:nil]);
  XCTAssertFalse([childClippingView pointInside:CGPointMake(100, 99) withEvent:nil]);
  XCTAssertFalse([childClippingView pointInside:CGPointMake(201, 200) withEvent:nil]);
  XCTAssertFalse([childClippingView pointInside:CGPointMake(200, 201) withEvent:nil]);
  XCTAssertFalse([childClippingView pointInside:CGPointMake(99, 200) withEvent:nil]);
  XCTAssertFalse([childClippingView pointInside:CGPointMake(200, 299) withEvent:nil]);

  XCTAssertTrue([childClippingView pointInside:CGPointMake(150, 150) withEvent:nil]);
  XCTAssertTrue([childClippingView pointInside:CGPointMake(100, 100) withEvent:nil]);
  XCTAssertTrue([childClippingView pointInside:CGPointMake(199, 100) withEvent:nil]);
  XCTAssertTrue([childClippingView pointInside:CGPointMake(100, 199) withEvent:nil]);
  XCTAssertTrue([childClippingView pointInside:CGPointMake(199, 199) withEvent:nil]);
}

- (void)testReleasesBackdropFilterSubviewsOnChildClippingViewDealloc {
  __weak NSMutableArray<UIVisualEffectView*>* weakBackdropFilterSubviews = nil;
  __weak UIVisualEffectView* weakVisualEffectView1 = nil;
  __weak UIVisualEffectView* weakVisualEffectView2 = nil;

  @autoreleasepool {
    ChildClippingView* clippingView = [[ChildClippingView alloc] initWithFrame:CGRectZero];
    UIVisualEffectView* visualEffectView1 = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    weakVisualEffectView1 = visualEffectView1;
    PlatformViewFilter* platformViewFilter1 =
        [[PlatformViewFilter alloc] initWithFrame:CGRectMake(0, 0, 10, 10)
                                       blurRadius:5
                                     cornerRadius:0
                                 visualEffectView:visualEffectView1];

    [clippingView applyBlurBackdropFilters:@[ platformViewFilter1 ]];

    // Replace the blur filter to validate the original and new UIVisualEffectView are released.
    UIVisualEffectView* visualEffectView2 = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    weakVisualEffectView2 = visualEffectView2;
    PlatformViewFilter* platformViewFilter2 =
        [[PlatformViewFilter alloc] initWithFrame:CGRectMake(0, 0, 10, 10)
                                       blurRadius:5
                                     cornerRadius:0
                                 visualEffectView:visualEffectView2];
    [clippingView applyBlurBackdropFilters:@[ platformViewFilter2 ]];

    weakBackdropFilterSubviews = clippingView.backdropFilterSubviews;
    XCTAssertNotNil(weakBackdropFilterSubviews);
    clippingView = nil;
  }
  XCTAssertNil(weakBackdropFilterSubviews);
  XCTAssertNil(weakVisualEffectView1);
  XCTAssertNil(weakVisualEffectView2);
}

- (void)testApplyBackdropFilter {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a backdrop filter
  auto filter = flutter::DlBlurImageFilter::Make(5, 2, flutter::DlTileMode::kClamp);
  stack.PushBackdropFilter(filter,
                           flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:[ChildClippingView class]]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  // childClippingView has visual effect view with the correct configurations.
  NSUInteger numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(numberOfExpectedVisualEffectView, 1u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:5]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 1u);
}

- (void)testApplyBackdropFilterWithCorrectFrame {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a backdrop filter
  auto filter = flutter::DlBlurImageFilter::Make(5, 2, flutter::DlTileMode::kClamp);
  stack.PushBackdropFilter(filter,
                           flutter::DlRect::MakeXYWH(0, 0, screenScale * 8, screenScale * 8));

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(5, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:[ChildClippingView class]]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  // childClippingView has visual effect view with the correct configurations.
  NSUInteger numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(numberOfExpectedVisualEffectView, 1u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 5, 8)
                              inputRadius:5]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 1u);
}

- (void)testApplyMultipleBackdropFilters {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push backdrop filters
  for (int i = 0; i < 50; i++) {
    auto filter = flutter::DlBlurImageFilter::Make(i, 2, flutter::DlTileMode::kClamp);
    stack.PushBackdropFilter(filter,
                             flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(20, 20), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSUInteger numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(numberOfExpectedVisualEffectView, 50u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)numberOfExpectedVisualEffectView]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, (NSUInteger)numberOfExpectedVisualEffectView);
}

- (void)testAddBackdropFilters {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a backdrop filter
  auto filter = flutter::DlBlurImageFilter::Make(5, 2, flutter::DlTileMode::kClamp);
  stack.PushBackdropFilter(filter,
                           flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:[ChildClippingView class]]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSMutableArray* originalVisualEffectViews = [[NSMutableArray alloc] init];
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(originalVisualEffectViews.count, 1u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)5]) {
      [originalVisualEffectViews addObject:subview];
    }
  }
  XCTAssertEqual(originalVisualEffectViews.count, 1u);

  //
  // Simulate adding 1 backdrop filter (create a new mutators stack)
  // Create embedded view params
  flutter::MutatorsStack stack2;
  // Layer tree always pushes a screen scale factor to the stack
  stack2.PushTransform(screenScaleMatrix);
  // Push backdrop filters
  for (int i = 0; i < 2; i++) {
    stack2.PushBackdropFilter(filter,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSMutableArray* newVisualEffectViews = [[NSMutableArray alloc] init];
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(newVisualEffectViews.count, 2u);

    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)5]) {
      [newVisualEffectViews addObject:subview];
    }
  }
  XCTAssertEqual(newVisualEffectViews.count, 2u);
  for (NSUInteger i = 0; i < originalVisualEffectViews.count; i++) {
    UIView* originalView = originalVisualEffectViews[i];
    UIView* newView = newVisualEffectViews[i];
    // Compare reference.
    XCTAssertEqual(originalView, newView);
    id mockOrignalView = OCMPartialMock(originalView);
    OCMReject([mockOrignalView removeFromSuperview]);
    [mockOrignalView stopMocking];
  }
}

- (void)testRemoveBackdropFilters {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push backdrop filters
  auto filter = flutter::DlBlurImageFilter::Make(5, 2, flutter::DlTileMode::kClamp);
  for (int i = 0; i < 5; i++) {
    stack.PushBackdropFilter(filter,
                             flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSMutableArray* originalVisualEffectViews = [[NSMutableArray alloc] init];
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(originalVisualEffectViews.count, 5u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)5]) {
      [originalVisualEffectViews addObject:subview];
    }
  }

  // Simulate removing 1 backdrop filter (create a new mutators stack)
  // Create embedded view params
  flutter::MutatorsStack stack2;
  // Layer tree always pushes a screen scale factor to the stack
  stack2.PushTransform(screenScaleMatrix);
  // Push backdrop filters
  for (int i = 0; i < 4; i++) {
    stack2.PushBackdropFilter(filter,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSMutableArray* newVisualEffectViews = [[NSMutableArray alloc] init];
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(newVisualEffectViews.count, 4u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)5]) {
      [newVisualEffectViews addObject:subview];
    }
  }
  XCTAssertEqual(newVisualEffectViews.count, 4u);

  for (NSUInteger i = 0; i < newVisualEffectViews.count; i++) {
    UIView* newView = newVisualEffectViews[i];
    id mockNewView = OCMPartialMock(newView);
    UIView* originalView = originalVisualEffectViews[i];
    // Compare reference.
    XCTAssertEqual(originalView, newView);
    OCMReject([mockNewView removeFromSuperview]);
    [mockNewView stopMocking];
  }

  // Simulate removing all backdrop filters (replace the mutators stack)
  // Update embedded view params, delete except screenScaleMatrix
  for (int i = 0; i < 5; i++) {
    stack2.Pop();
  }
  // No backdrop filters in the stack, so no nothing to push

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSUInteger numberOfExpectedVisualEffectView = 0u;
  for (UIView* subview in childClippingView.subviews) {
    if ([subview isKindOfClass:[UIVisualEffectView class]]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 0u);
}

- (void)testEditBackdropFilters {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push backdrop filters
  auto filter = flutter::DlBlurImageFilter::Make(5, 2, flutter::DlTileMode::kClamp);
  for (int i = 0; i < 5; i++) {
    stack.PushBackdropFilter(filter,
                             flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSMutableArray* originalVisualEffectViews = [[NSMutableArray alloc] init];
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(originalVisualEffectViews.count, 5u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)5]) {
      [originalVisualEffectViews addObject:subview];
    }
  }

  // Simulate editing 1 backdrop filter in the middle of the stack (create a new mutators stack)
  // Create embedded view params
  flutter::MutatorsStack stack2;
  // Layer tree always pushes a screen scale factor to the stack
  stack2.PushTransform(screenScaleMatrix);
  // Push backdrop filters
  for (int i = 0; i < 5; i++) {
    if (i == 3) {
      auto filter2 = flutter::DlBlurImageFilter::Make(2, 5, flutter::DlTileMode::kClamp);

      stack2.PushBackdropFilter(
          filter2, flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
      continue;
    }

    stack2.PushBackdropFilter(filter,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSMutableArray* newVisualEffectViews = [[NSMutableArray alloc] init];
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(newVisualEffectViews.count, 5u);
    CGFloat expectInputRadius = 5;
    if (newVisualEffectViews.count == 3) {
      expectInputRadius = 2;
    }
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:expectInputRadius]) {
      [newVisualEffectViews addObject:subview];
    }
  }
  XCTAssertEqual(newVisualEffectViews.count, 5u);
  for (NSUInteger i = 0; i < newVisualEffectViews.count; i++) {
    UIView* newView = newVisualEffectViews[i];
    id mockNewView = OCMPartialMock(newView);
    UIView* originalView = originalVisualEffectViews[i];
    // Compare reference.
    XCTAssertEqual(originalView, newView);
    OCMReject([mockNewView removeFromSuperview]);
    [mockNewView stopMocking];
  }
  [newVisualEffectViews removeAllObjects];

  // Simulate editing 1 backdrop filter in the beginning of the stack (replace the mutators stack)
  // Update embedded view params, delete except screenScaleMatrix
  for (int i = 0; i < 5; i++) {
    stack2.Pop();
  }
  // Push backdrop filters
  for (int i = 0; i < 5; i++) {
    if (i == 0) {
      auto filter2 = flutter::DlBlurImageFilter::Make(2, 5, flutter::DlTileMode::kClamp);
      stack2.PushBackdropFilter(
          filter2, flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
      continue;
    }

    stack2.PushBackdropFilter(filter,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(newVisualEffectViews.count, 5u);
    CGFloat expectInputRadius = 5;
    if (newVisualEffectViews.count == 0) {
      expectInputRadius = 2;
    }
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:expectInputRadius]) {
      [newVisualEffectViews addObject:subview];
    }
  }
  for (NSUInteger i = 0; i < newVisualEffectViews.count; i++) {
    UIView* newView = newVisualEffectViews[i];
    id mockNewView = OCMPartialMock(newView);
    UIView* originalView = originalVisualEffectViews[i];
    // Compare reference.
    XCTAssertEqual(originalView, newView);
    OCMReject([mockNewView removeFromSuperview]);
    [mockNewView stopMocking];
  }
  [newVisualEffectViews removeAllObjects];

  // Simulate editing 1 backdrop filter in the end of the stack (replace the mutators stack)
  // Update embedded view params, delete except screenScaleMatrix
  for (int i = 0; i < 5; i++) {
    stack2.Pop();
  }
  // Push backdrop filters
  for (int i = 0; i < 5; i++) {
    if (i == 4) {
      auto filter2 = flutter::DlBlurImageFilter::Make(2, 5, flutter::DlTileMode::kClamp);
      stack2.PushBackdropFilter(
          filter2, flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
      continue;
    }

    stack2.PushBackdropFilter(filter,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(newVisualEffectViews.count, 5u);
    CGFloat expectInputRadius = 5;
    if (newVisualEffectViews.count == 4) {
      expectInputRadius = 2;
    }
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:expectInputRadius]) {
      [newVisualEffectViews addObject:subview];
    }
  }
  XCTAssertEqual(newVisualEffectViews.count, 5u);

  for (NSUInteger i = 0; i < newVisualEffectViews.count; i++) {
    UIView* newView = newVisualEffectViews[i];
    id mockNewView = OCMPartialMock(newView);
    UIView* originalView = originalVisualEffectViews[i];
    // Compare reference.
    XCTAssertEqual(originalView, newView);
    OCMReject([mockNewView removeFromSuperview]);
    [mockNewView stopMocking];
  }
  [newVisualEffectViews removeAllObjects];

  // Simulate editing all backdrop filters in the stack (replace the mutators stack)
  // Update embedded view params, delete except screenScaleMatrix
  for (int i = 0; i < 5; i++) {
    stack2.Pop();
  }
  // Push backdrop filters
  for (int i = 0; i < 5; i++) {
    auto filter2 = flutter::DlBlurImageFilter::Make(i, 2, flutter::DlTileMode::kClamp);

    stack2.PushBackdropFilter(filter2,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(newVisualEffectViews.count, 5u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)newVisualEffectViews.count]) {
      [newVisualEffectViews addObject:subview];
    }
  }
  XCTAssertEqual(newVisualEffectViews.count, 5u);

  for (NSUInteger i = 0; i < newVisualEffectViews.count; i++) {
    UIView* newView = newVisualEffectViews[i];
    id mockNewView = OCMPartialMock(newView);
    UIView* originalView = originalVisualEffectViews[i];
    // Compare reference.
    XCTAssertEqual(originalView, newView);
    OCMReject([mockNewView removeFromSuperview]);
    [mockNewView stopMocking];
  }
  [newVisualEffectViews removeAllObjects];
}

- (void)testApplyBackdropFilterNotDlBlurImageFilter {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a dilate backdrop filter
  auto dilateFilter = flutter::DlDilateImageFilter::Make(5, 2);
  stack.PushBackdropFilter(dilateFilter, flutter::DlRect());

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:[ChildClippingView class]]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;

  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSUInteger numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if ([subview isKindOfClass:[UIVisualEffectView class]]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 0u);

  // Simulate adding a non-DlBlurImageFilter in the middle of the stack (create a new mutators
  // stack) Create embedded view params
  flutter::MutatorsStack stack2;
  // Layer tree always pushes a screen scale factor to the stack
  stack2.PushTransform(screenScaleMatrix);
  // Push backdrop filters and dilate filter
  auto blurFilter = flutter::DlBlurImageFilter::Make(5, 2, flutter::DlTileMode::kClamp);

  for (int i = 0; i < 5; i++) {
    if (i == 2) {
      stack2.PushBackdropFilter(
          dilateFilter, flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
      continue;
    }

    stack2.PushBackdropFilter(blurFilter,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(numberOfExpectedVisualEffectView, 4u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)5]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 4u);

  // Simulate adding a non-DlBlurImageFilter to the beginning of the stack (replace the mutators
  // stack) Update embedded view params, delete except screenScaleMatrix
  for (int i = 0; i < 5; i++) {
    stack2.Pop();
  }
  // Push backdrop filters and dilate filter
  for (int i = 0; i < 5; i++) {
    if (i == 0) {
      stack2.PushBackdropFilter(
          dilateFilter, flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
      continue;
    }

    stack2.PushBackdropFilter(blurFilter,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(numberOfExpectedVisualEffectView, 4u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)5]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 4u);

  // Simulate adding a non-DlBlurImageFilter to the end of the stack (replace the mutators stack)
  // Update embedded view params, delete except screenScaleMatrix
  for (int i = 0; i < 5; i++) {
    stack2.Pop();
  }
  // Push backdrop filters and dilate filter
  for (int i = 0; i < 5; i++) {
    if (i == 4) {
      stack2.PushBackdropFilter(
          dilateFilter, flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
      continue;
    }

    stack2.PushBackdropFilter(blurFilter,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(numberOfExpectedVisualEffectView, 4u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:(CGFloat)5]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 4u);

  // Simulate adding only non-DlBlurImageFilter to the stack (replace the mutators stack)
  // Update embedded view params, delete except screenScaleMatrix
  for (int i = 0; i < 5; i++) {
    stack2.Pop();
  }
  // Push dilate filters
  for (int i = 0; i < 5; i++) {
    stack2.PushBackdropFilter(dilateFilter,
                              flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));
  }

  embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if ([subview isKindOfClass:[UIVisualEffectView class]]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 0u);
}

- (void)testApplyBackdropFilterCorrectAPI {
  [PlatformViewFilter resetPreparation];
  // The gaussianBlur filter is extracted from UIVisualEffectView.
  // Each test requires a new PlatformViewFilter
  // Valid UIVisualEffectView API
  UIVisualEffectView* visualEffectView = [[UIVisualEffectView alloc]
      initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
  PlatformViewFilter* platformViewFilter =
      [[PlatformViewFilter alloc] initWithFrame:CGRectMake(0, 0, 10, 10)
                                     blurRadius:5
                                   cornerRadius:0
                               visualEffectView:visualEffectView];
  XCTAssertNotNil(platformViewFilter);
}

- (void)testApplyBackdropFilterAPIChangedInvalidUIVisualEffectView {
  [PlatformViewFilter resetPreparation];
  UIVisualEffectView* visualEffectView = [[UIVisualEffectView alloc] init];
  PlatformViewFilter* platformViewFilter =
      [[PlatformViewFilter alloc] initWithFrame:CGRectMake(0, 0, 10, 10)
                                     blurRadius:5
                                   cornerRadius:0
                               visualEffectView:visualEffectView];
  XCTAssertNil(platformViewFilter);
}

- (void)testApplyBackdropFilterAPIChangedNoGaussianBlurFilter {
  [PlatformViewFilter resetPreparation];
  UIVisualEffectView* editedUIVisualEffectView = [[UIVisualEffectView alloc]
      initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
  NSArray* subviews = editedUIVisualEffectView.subviews;
  for (UIView* view in subviews) {
    if ([NSStringFromClass([view class]) hasSuffix:@"BackdropView"]) {
      for (CIFilter* filter in view.layer.filters) {
        if ([[filter valueForKey:@"name"] isEqual:@"gaussianBlur"]) {
          [filter setValue:@"notGaussianBlur" forKey:@"name"];
          break;
        }
      }
      break;
    }
  }
  PlatformViewFilter* platformViewFilter =
      [[PlatformViewFilter alloc] initWithFrame:CGRectMake(0, 0, 10, 10)
                                     blurRadius:5
                                   cornerRadius:0
                               visualEffectView:editedUIVisualEffectView];
  XCTAssertNil(platformViewFilter);
}

- (void)testApplyBackdropFilterAPIChangedInvalidInputRadius {
  [PlatformViewFilter resetPreparation];
  UIVisualEffectView* editedUIVisualEffectView = [[UIVisualEffectView alloc]
      initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
  NSArray* subviews = editedUIVisualEffectView.subviews;
  for (UIView* view in subviews) {
    if ([NSStringFromClass([view class]) hasSuffix:@"BackdropView"]) {
      for (CIFilter* filter in view.layer.filters) {
        if ([[filter valueForKey:@"name"] isEqual:@"gaussianBlur"]) {
          [filter setValue:@"invalidInputRadius" forKey:@"inputRadius"];
          break;
        }
      }
      break;
    }
  }

  PlatformViewFilter* platformViewFilter =
      [[PlatformViewFilter alloc] initWithFrame:CGRectMake(0, 0, 10, 10)
                                     blurRadius:5
                                   cornerRadius:0
                               visualEffectView:editedUIVisualEffectView];
  XCTAssertNil(platformViewFilter);
}

- (void)testApplyBackdropFilterRespectsClipRRect {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);

  // Push a rounded rect clip
  auto clipRect = flutter::DlRect::MakeXYWH(2, 2, 6, 6);
  auto clipRRect = flutter::DlRoundRect::MakeRectXY(clipRect, 3, 3);
  stack.PushPlatformViewClipRRect(clipRRect);

  // Push a backdrop filter
  auto filter = flutter::DlBlurImageFilter::Make(5, 2, flutter::DlTileMode::kClamp);
  stack.PushBackdropFilter(filter,
                           flutter::DlRect::MakeXYWH(0, 0, screenScale * 10, screenScale * 10));

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:[ChildClippingView class]]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  NSArray<UIVisualEffectView*>* filters = childClippingView.backdropFilterSubviews;
  XCTAssertEqual(filters.count, 1u);

  UIVisualEffectView* visualEffectView = filters[0];
  auto radii = clipRRect.GetRadii();

  XCTAssertEqual(visualEffectView.layer.cornerRadius, radii.top_left.width);
}

- (void)testBackdropFilterVisualEffectSubviewBackgroundColor {
  __weak UIVisualEffectView* weakVisualEffectView;

  @autoreleasepool {
    UIVisualEffectView* visualEffectView = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    weakVisualEffectView = visualEffectView;
    PlatformViewFilter* platformViewFilter =
        [[PlatformViewFilter alloc] initWithFrame:CGRectMake(0, 0, 10, 10)
                                       blurRadius:5
                                     cornerRadius:0
                                 visualEffectView:visualEffectView];
    CGColorRef visualEffectSubviewBackgroundColor = nil;
    for (UIView* view in [platformViewFilter backdropFilterView].subviews) {
      if ([NSStringFromClass([view class]) hasSuffix:@"VisualEffectSubview"]) {
        visualEffectSubviewBackgroundColor = view.layer.backgroundColor;
      }
    }
    XCTAssertTrue(
        CGColorEqualToColor(visualEffectSubviewBackgroundColor, UIColor.clearColor.CGColor));
  }
  XCTAssertNil(weakVisualEffectView);
}

- (void)testCompositePlatformView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a translate matrix
  flutter::DlMatrix translateMatrix = flutter::DlMatrix::MakeTranslation({100, 100});
  stack.PushTransform(translateMatrix);
  flutter::DlMatrix finalMatrix = screenScaleMatrix * translateMatrix;

  auto embeddedViewParams =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  CGRect platformViewRectInFlutterView = [gMockPlatformView convertRect:gMockPlatformView.bounds
                                                                 toView:flutterView];
  XCTAssertTrue(CGRectEqualToRect(platformViewRectInFlutterView, CGRectMake(100, 100, 300, 300)));
}

- (void)testBackdropFilterCorrectlyPushedAndReset {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(0, 0)];
  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController pushVisitedPlatformViewId:2];
  auto filter = flutter::DlBlurImageFilter::Make(5, 2, flutter::DlTileMode::kClamp, std::nullopt);
  [flutterPlatformViewsController
      pushFilterToVisitedPlatformViews:filter
                              withRect:flutter::DlRect::MakeXYWH(0, 0, screenScale * 10,
                                                                 screenScale * 10)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:[ChildClippingView class]]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  // childClippingView has visual effect view with the correct configurations.
  NSUInteger numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    XCTAssertLessThan(numberOfExpectedVisualEffectView, 1u);
    if ([self validateOneVisualEffectView:subview
                            expectedFrame:CGRectMake(0, 0, 10, 10)
                              inputRadius:5]) {
      numberOfExpectedVisualEffectView++;
    }
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 1u);

  // New frame, with no filter pushed.
  auto embeddedViewParams2 = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);
  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(0, 0)];
  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams2)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:[ChildClippingView class]]);

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  numberOfExpectedVisualEffectView = 0;
  for (UIView* subview in childClippingView.subviews) {
    if (![subview isKindOfClass:[UIVisualEffectView class]]) {
      continue;
    }
    numberOfExpectedVisualEffectView++;
  }
  XCTAssertEqual(numberOfExpectedVisualEffectView, 0u);
}

- (void)testChildClippingViewShouldBeTheBoundingRectOfPlatformView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a rotate matrix
  flutter::DlMatrix rotateMatrix = flutter::DlMatrix::MakeRotationZ(flutter::DlDegrees(10));
  stack.PushTransform(rotateMatrix);
  flutter::DlMatrix finalMatrix = screenScaleMatrix * rotateMatrix;

  auto embeddedViewParams =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  CGRect platformViewRectInFlutterView = [gMockPlatformView convertRect:gMockPlatformView.bounds
                                                                 toView:flutterView];
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  // The childclippingview's frame is set based on flow, but the platform view's frame is set based
  // on quartz. Although they should be the same, but we should tolerate small floating point
  // errors.
  XCTAssertLessThan(fabs(platformViewRectInFlutterView.origin.x - childClippingView.frame.origin.x),
                    kFloatCompareEpsilon);
  XCTAssertLessThan(fabs(platformViewRectInFlutterView.origin.y - childClippingView.frame.origin.y),
                    kFloatCompareEpsilon);
  XCTAssertLessThan(
      fabs(platformViewRectInFlutterView.size.width - childClippingView.frame.size.width),
      kFloatCompareEpsilon);
  XCTAssertLessThan(
      fabs(platformViewRectInFlutterView.size.height - childClippingView.frame.size.height),
      kFloatCompareEpsilon);
}

- (void)testClipsDoNotInterceptWithPlatformViewShouldNotAddMaskView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params.
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack.
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  flutter::DlMatrix translateMatrix = flutter::DlMatrix::MakeTranslation({5, 5});
  // The platform view's rect for this test will be (5, 5, 10, 10).
  stack.PushTransform(translateMatrix);
  // Push a clip rect, big enough to contain the entire platform view bound.
  flutter::DlRect rect = flutter::DlRect::MakeXYWH(0, 0, 25, 25);
  stack.PushClipRect(rect);
  // Push a clip rrect, big enough to contain the entire platform view bound without clipping it.
  // Make the origin (-1, -1) so that the top left rounded corner isn't clipping the PlatformView.
  flutter::DlRect rect_for_rrect = flutter::DlRect::MakeXYWH(-1, -1, 25, 25);
  flutter::DlRoundRect rrect = flutter::DlRoundRect::MakeRectXY(rect_for_rrect, 1, 1);
  stack.PushClipRRect(rrect);

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix * translateMatrix, flutter::DlSize(5, 5), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  gMockPlatformView.backgroundColor = UIColor.redColor;
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];
  XCTAssertNil(childClippingView.maskView);
}

- (void)testClipRRectOnlyHasCornersInterceptWithPlatformViewShouldAddMaskView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack.
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  flutter::DlMatrix translateMatrix = flutter::DlMatrix::MakeTranslation({5, 5});
  // The platform view's rect for this test will be (5, 5, 10, 10).
  stack.PushTransform(translateMatrix);

  // Push a clip rrect, the rect of the rrect is the same as the PlatformView of the corner should.
  // clip the PlatformView.
  flutter::DlRect rect_for_rrect = flutter::DlRect::MakeXYWH(0, 0, 10, 10);
  flutter::DlRoundRect rrect = flutter::DlRoundRect::MakeRectXY(rect_for_rrect, 1, 1);
  stack.PushClipRRect(rrect);

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix * translateMatrix, flutter::DlSize(5, 5), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  gMockPlatformView.backgroundColor = UIColor.redColor;
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  XCTAssertNotNil(childClippingView.maskView);
}

- (void)testClipRect {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a clip rect
  flutter::DlRect rect = flutter::DlRect::MakeXYWH(2, 2, 3, 3);
  stack.PushClipRect(rect);

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  gMockPlatformView.backgroundColor = UIColor.redColor;
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  CGRect insideClipping = CGRectMake(2, 2, 3, 3);
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 10; j++) {
      CGPoint point = CGPointMake(i, j);
      int alpha = [self alphaOfPoint:CGPointMake(i, j) onView:flutterView];
      if (CGRectContainsPoint(insideClipping, point)) {
        XCTAssertEqual(alpha, 255);
      } else {
        XCTAssertEqual(alpha, 0);
      }
    }
  }
}

- (void)testClipRect_multipleClips {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a clip rect
  flutter::DlRect rect1 = flutter::DlRect::MakeXYWH(2, 2, 3, 3);
  stack.PushClipRect(rect1);
  // Push another clip rect
  flutter::DlRect rect2 = flutter::DlRect::MakeXYWH(3, 3, 3, 3);
  stack.PushClipRect(rect2);

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  gMockPlatformView.backgroundColor = UIColor.redColor;
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  /*
  clip 1            clip 2
    2 3 4 5 6         2 3 4 5 6
  2 + - - +         2
  3 |     |         3   + - - +
  4 |     |         4   |     |
  5 + - - +         5   |     |
  6                 6   + - - +

  Result should be the intersection of 2 clips
    2 3 4 5 6
  2
  3   + - +
  4   |   |
  5   + - +
  6
  */
  CGRect insideClipping = CGRectMake(3, 3, 2, 2);
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 10; j++) {
      CGPoint point = CGPointMake(i, j);
      int alpha = [self alphaOfPoint:CGPointMake(i, j) onView:flutterView];
      if (CGRectContainsPoint(insideClipping, point)) {
        XCTAssertEqual(alpha, 255);
      } else {
        XCTAssertEqual(alpha, 0);
      }
    }
  }
}

- (void)testClipRRect {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a clip rrect
  flutter::DlRoundRect rrect =
      flutter::DlRoundRect::MakeRectXY(flutter::DlRect::MakeXYWH(2, 2, 6, 6), 1, 1);
  stack.PushClipRRect(rrect);

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  gMockPlatformView.backgroundColor = UIColor.redColor;
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  /*
  ClippingMask          outterClipping
    2 3 4 5 6 7           2 3 4 5 6 7
  2 / - - - - \         2 + - - - - +
  3 |         |         3 |         |
  4 |         |         4 |         |
  5 |         |         5 |         |
  6 |         |         6 |         |
  7 \ - - - - /         7 + - - - - +

  innerClipping1        innerClipping2
    2 3 4 5 6 7           2 3 4 5 6 7
  2   + - - +           2
  3   |     |           3 + - - - - +
  4   |     |           4 |         |
  5   |     |           5 |         |
  6   |     |           6 + - - - - +
  7   + - - +           7
  */
  CGRect innerClipping1 = CGRectMake(3, 2, 4, 6);
  CGRect innerClipping2 = CGRectMake(2, 3, 6, 4);
  CGRect outterClipping = CGRectMake(2, 2, 6, 6);
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 10; j++) {
      CGPoint point = CGPointMake(i, j);
      int alpha = [self alphaOfPoint:CGPointMake(i, j) onView:flutterView];
      if (CGRectContainsPoint(innerClipping1, point) ||
          CGRectContainsPoint(innerClipping2, point)) {
        // Pixels inside either of the 2 inner clippings should be fully opaque.
        XCTAssertEqual(alpha, 255);
      } else if (CGRectContainsPoint(outterClipping, point)) {
        // Corner pixels (i.e. (2, 2), (2, 7), (7, 2) and (7, 7)) should be partially transparent.
        XCTAssert(0 < alpha && alpha < 255);
      } else {
        // Pixels outside outterClipping should be fully transparent.
        XCTAssertEqual(alpha, 0);
      }
    }
  }
}

- (void)testClipRRect_multipleClips {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a clip rrect
  flutter::DlRoundRect rrect =
      flutter::DlRoundRect::MakeRectXY(flutter::DlRect::MakeXYWH(2, 2, 6, 6), 1, 1);
  stack.PushClipRRect(rrect);
  // Push a clip rect
  flutter::DlRect rect = flutter::DlRect::MakeXYWH(4, 2, 6, 6);
  stack.PushClipRect(rect);

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  gMockPlatformView.backgroundColor = UIColor.redColor;
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  /*
  clip 1                 clip 2
    2 3 4 5 6 7 8 9       2 3 4 5 6 7 8 9
  2 / - - - - \         2     + - - - - +
  3 |         |         3     |         |
  4 |         |         4     |         |
  5 |         |         5     |         |
  6 |         |         6     |         |
  7 \ - - - - /         7     + - - - - +

  Result should be the intersection of 2 clips
    2 3 4 5 6 7 8 9
  2     + - - \
  3     |     |
  4     |     |
  5     |     |
  6     |     |
  7     + - - /
  */
  CGRect clipping = CGRectMake(4, 2, 4, 6);
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 10; j++) {
      CGPoint point = CGPointMake(i, j);
      int alpha = [self alphaOfPoint:CGPointMake(i, j) onView:flutterView];
      if (i == 7 && (j == 2 || j == 7)) {
        // Upper and lower right corners should be partially transparent.
        XCTAssert(0 < alpha && alpha < 255);
      } else if (
          // left
          (i == 4 && j >= 2 && j <= 7) ||
          // right
          (i == 7 && j >= 2 && j <= 7) ||
          // top
          (j == 2 && i >= 4 && i <= 7) ||
          // bottom
          (j == 7 && i >= 4 && i <= 7)) {
        // Since we are falling back to software rendering for this case
        // The edge pixels can be anti-aliased, so it may not be fully opaque.
        XCTAssert(alpha > 127);
      } else if ((i == 3 && j >= 1 && j <= 8) || (i == 8 && j >= 1 && j <= 8) ||
                 (j == 1 && i >= 3 && i <= 8) || (j == 8 && i >= 3 && i <= 8)) {
        // Since we are falling back to software rendering for this case
        // The edge pixels can be anti-aliased, so it may not be fully transparent.
        XCTAssert(alpha < 127);
      } else if (CGRectContainsPoint(clipping, point)) {
        // Other pixels inside clipping should be fully opaque.
        XCTAssertEqual(alpha, 255);
      } else {
        // Pixels outside clipping should be fully transparent.
        XCTAssertEqual(alpha, 0);
      }
    }
  }
}

- (void)testClipPath {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a clip path
  flutter::DlPath path =
      flutter::DlPath::MakeRoundRectXY(flutter::DlRect::MakeXYWH(2, 2, 6, 6), 1, 1);
  stack.PushClipPath(path);

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  gMockPlatformView.backgroundColor = UIColor.redColor;
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  /*
  ClippingMask          outterClipping
    2 3 4 5 6 7           2 3 4 5 6 7
  2 / - - - - \         2 + - - - - +
  3 |         |         3 |         |
  4 |         |         4 |         |
  5 |         |         5 |         |
  6 |         |         6 |         |
  7 \ - - - - /         7 + - - - - +

  innerClipping1        innerClipping2
    2 3 4 5 6 7           2 3 4 5 6 7
  2   + - - +           2
  3   |     |           3 + - - - - +
  4   |     |           4 |         |
  5   |     |           5 |         |
  6   |     |           6 + - - - - +
  7   + - - +           7
  */
  CGRect innerClipping1 = CGRectMake(3, 2, 4, 6);
  CGRect innerClipping2 = CGRectMake(2, 3, 6, 4);
  CGRect outterClipping = CGRectMake(2, 2, 6, 6);
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 10; j++) {
      CGPoint point = CGPointMake(i, j);
      int alpha = [self alphaOfPoint:CGPointMake(i, j) onView:flutterView];
      if (CGRectContainsPoint(innerClipping1, point) ||
          CGRectContainsPoint(innerClipping2, point)) {
        // Pixels inside either of the 2 inner clippings should be fully opaque.
        XCTAssertEqual(alpha, 255);
      } else if (CGRectContainsPoint(outterClipping, point)) {
        // Corner pixels (i.e. (2, 2), (2, 7), (7, 2) and (7, 7)) should be partially transparent.
        XCTAssert(0 < alpha && alpha < 255);
      } else {
        // Pixels outside outterClipping should be fully transparent.
        XCTAssertEqual(alpha, 0);
      }
    }
  }
}

- (void)testClipPath_multipleClips {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a clip path
  flutter::DlPath path =
      flutter::DlPath::MakeRoundRectXY(flutter::DlRect::MakeXYWH(2, 2, 6, 6), 1, 1);
  stack.PushClipPath(path);
  // Push a clip rect
  flutter::DlRect rect = flutter::DlRect::MakeXYWH(4, 2, 6, 6);
  stack.PushClipRect(rect);

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  gMockPlatformView.backgroundColor = UIColor.redColor;
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  /*
  clip 1                 clip 2
    2 3 4 5 6 7 8 9       2 3 4 5 6 7 8 9
  2 / - - - - \         2     + - - - - +
  3 |         |         3     |         |
  4 |         |         4     |         |
  5 |         |         5     |         |
  6 |         |         6     |         |
  7 \ - - - - /         7     + - - - - +

  Result should be the intersection of 2 clips
    2 3 4 5 6 7 8 9
  2     + - - \
  3     |     |
  4     |     |
  5     |     |
  6     |     |
  7     + - - /
  */
  CGRect clipping = CGRectMake(4, 2, 4, 6);
  for (int i = 0; i < 10; i++) {
    for (int j = 0; j < 10; j++) {
      CGPoint point = CGPointMake(i, j);
      int alpha = [self alphaOfPoint:CGPointMake(i, j) onView:flutterView];
      if (i == 7 && (j == 2 || j == 7)) {
        // Upper and lower right corners should be partially transparent.
        XCTAssert(0 < alpha && alpha < 255);
      } else if (
          // left
          (i == 4 && j >= 2 && j <= 7) ||
          // right
          (i == 7 && j >= 2 && j <= 7) ||
          // top
          (j == 2 && i >= 4 && i <= 7) ||
          // bottom
          (j == 7 && i >= 4 && i <= 7)) {
        // Since we are falling back to software rendering for this case
        // The edge pixels can be anti-aliased, so it may not be fully opaque.
        XCTAssert(alpha > 127);
      } else if ((i == 3 && j >= 1 && j <= 8) || (i == 8 && j >= 1 && j <= 8) ||
                 (j == 1 && i >= 3 && i <= 8) || (j == 8 && i >= 3 && i <= 8)) {
        // Since we are falling back to software rendering for this case
        // The edge pixels can be anti-aliased, so it may not be fully transparent.
        XCTAssert(alpha < 127);
      } else if (CGRectContainsPoint(clipping, point)) {
        // Other pixels inside clipping should be fully opaque.
        XCTAssertEqual(alpha, 255);
      } else {
        // Pixels outside clipping should be fully transparent.
        XCTAssertEqual(alpha, 0);
      }
    }
  }
}

- (void)testSetFlutterViewControllerAfterCreateCanStillDispatchTouchEvents {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  // Find ForwardGestureRecognizer
  UIGestureRecognizer* forwardGectureRecognizer = nil;
  for (UIGestureRecognizer* gestureRecognizer in touchInteceptorView.gestureRecognizers) {
    if ([gestureRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]) {
      forwardGectureRecognizer = gestureRecognizer;
      break;
    }
  }

  // Before setting flutter view controller, events are not dispatched.
  NSSet* touches1 = [[NSSet alloc] init];
  id event1 = OCMClassMock([UIEvent class]);
  id flutterViewController = OCMClassMock([FlutterViewController class]);
  [forwardGectureRecognizer touchesBegan:touches1 withEvent:event1];
  OCMReject([flutterViewController touchesBegan:touches1 withEvent:event1]);

  // Set flutter view controller allows events to be dispatched.
  NSSet* touches2 = [[NSSet alloc] init];
  id event2 = OCMClassMock([UIEvent class]);
  flutterPlatformViewsController.flutterViewController = flutterViewController;
  [forwardGectureRecognizer touchesBegan:touches2 withEvent:event2];
  OCMVerify([flutterViewController touchesBegan:touches2 withEvent:event2]);
}

- (void)testSetFlutterViewControllerInTheMiddleOfTouchEventShouldStillAllowGesturesToBeHandled {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  // Find ForwardGestureRecognizer
  UIGestureRecognizer* forwardGectureRecognizer = nil;
  for (UIGestureRecognizer* gestureRecognizer in touchInteceptorView.gestureRecognizers) {
    if ([gestureRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]) {
      forwardGectureRecognizer = gestureRecognizer;
      break;
    }
  }
  id flutterViewController = OCMClassMock([FlutterViewController class]);
  {
    // ***** Sequence 1, finishing touch event with touchEnded ***** //
    flutterPlatformViewsController.flutterViewController = flutterViewController;

    NSSet* touches1 = [[NSSet alloc] init];
    id event1 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesBegan:touches1 withEvent:event1];
    OCMVerify([flutterViewController touchesBegan:touches1 withEvent:event1]);

    flutterPlatformViewsController.flutterViewController = nil;

    // Allow the touch events to finish
    NSSet* touches2 = [[NSSet alloc] init];
    id event2 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesMoved:touches2 withEvent:event2];
    OCMVerify([flutterViewController touchesMoved:touches2 withEvent:event2]);

    NSSet* touches3 = [[NSSet alloc] init];
    id event3 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesEnded:touches3 withEvent:event3];
    OCMVerify([flutterViewController touchesEnded:touches3 withEvent:event3]);

    // Now the 2nd touch sequence should not be allowed.
    NSSet* touches4 = [[NSSet alloc] init];
    id event4 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesBegan:touches4 withEvent:event4];
    OCMReject([flutterViewController touchesBegan:touches4 withEvent:event4]);

    NSSet* touches5 = [[NSSet alloc] init];
    id event5 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesEnded:touches5 withEvent:event5];
    OCMReject([flutterViewController touchesEnded:touches5 withEvent:event5]);
  }

  {
    // ***** Sequence 2, finishing touch event with touchCancelled ***** //
    flutterPlatformViewsController.flutterViewController = flutterViewController;

    NSSet* touches1 = [[NSSet alloc] init];
    id event1 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesBegan:touches1 withEvent:event1];
    OCMVerify([flutterViewController touchesBegan:touches1 withEvent:event1]);

    flutterPlatformViewsController.flutterViewController = nil;

    // Allow the touch events to finish
    NSSet* touches2 = [[NSSet alloc] init];
    id event2 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesMoved:touches2 withEvent:event2];
    OCMVerify([flutterViewController touchesMoved:touches2 withEvent:event2]);

    NSSet* touches3 = [[NSSet alloc] init];
    id event3 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesCancelled:touches3 withEvent:event3];
    OCMVerify([flutterViewController forceTouchesCancelled:touches3]);

    // Now the 2nd touch sequence should not be allowed.
    NSSet* touches4 = [[NSSet alloc] init];
    id event4 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesBegan:touches4 withEvent:event4];
    OCMReject([flutterViewController touchesBegan:touches4 withEvent:event4]);

    NSSet* touches5 = [[NSSet alloc] init];
    id event5 = OCMClassMock([UIEvent class]);
    [forwardGectureRecognizer touchesEnded:touches5 withEvent:event5];
    OCMReject([flutterViewController touchesEnded:touches5 withEvent:event5]);
  }

  [flutterPlatformViewsController reset];
}

- (void)
    testSetFlutterViewControllerInTheMiddleOfTouchEventAllowsTheNewControllerToHandleSecondTouchSequence {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  // Find ForwardGestureRecognizer
  UIGestureRecognizer* forwardGectureRecognizer = nil;
  for (UIGestureRecognizer* gestureRecognizer in touchInteceptorView.gestureRecognizers) {
    if ([gestureRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]) {
      forwardGectureRecognizer = gestureRecognizer;
      break;
    }
  }
  id flutterViewController = OCMClassMock([FlutterViewController class]);
  flutterPlatformViewsController.flutterViewController = flutterViewController;

  // The touches in this sequence requires 1 touch object, we always create the NSSet with one item.
  NSSet* touches1 = [NSSet setWithObject:@1];
  id event1 = OCMClassMock([UIEvent class]);
  [forwardGectureRecognizer touchesBegan:touches1 withEvent:event1];
  OCMVerify([flutterViewController touchesBegan:touches1 withEvent:event1]);

  FlutterViewController* flutterViewController2 = OCMClassMock([FlutterViewController class]);
  flutterPlatformViewsController.flutterViewController = flutterViewController2;

  // Touch events should still send to the old FlutterViewController if FlutterViewController
  // is updated in between.
  NSSet* touches2 = [NSSet setWithObject:@1];
  id event2 = OCMClassMock([UIEvent class]);
  [forwardGectureRecognizer touchesBegan:touches2 withEvent:event2];
  OCMVerify([flutterViewController touchesBegan:touches2 withEvent:event2]);
  OCMReject([flutterViewController2 touchesBegan:touches2 withEvent:event2]);

  NSSet* touches3 = [NSSet setWithObject:@1];
  id event3 = OCMClassMock([UIEvent class]);
  [forwardGectureRecognizer touchesMoved:touches3 withEvent:event3];
  OCMVerify([flutterViewController touchesMoved:touches3 withEvent:event3]);
  OCMReject([flutterViewController2 touchesMoved:touches3 withEvent:event3]);

  NSSet* touches4 = [NSSet setWithObject:@1];
  id event4 = OCMClassMock([UIEvent class]);
  [forwardGectureRecognizer touchesEnded:touches4 withEvent:event4];
  OCMVerify([flutterViewController touchesEnded:touches4 withEvent:event4]);
  OCMReject([flutterViewController2 touchesEnded:touches4 withEvent:event4]);

  NSSet* touches5 = [NSSet setWithObject:@1];
  id event5 = OCMClassMock([UIEvent class]);
  [forwardGectureRecognizer touchesEnded:touches5 withEvent:event5];
  OCMVerify([flutterViewController touchesEnded:touches5 withEvent:event5]);
  OCMReject([flutterViewController2 touchesEnded:touches5 withEvent:event5]);

  // Now the 2nd touch sequence should go to the new FlutterViewController

  NSSet* touches6 = [NSSet setWithObject:@1];
  id event6 = OCMClassMock([UIEvent class]);
  [forwardGectureRecognizer touchesBegan:touches6 withEvent:event6];
  OCMVerify([flutterViewController2 touchesBegan:touches6 withEvent:event6]);
  OCMReject([flutterViewController touchesBegan:touches6 withEvent:event6]);

  // Allow the touch events to finish
  NSSet* touches7 = [NSSet setWithObject:@1];
  id event7 = OCMClassMock([UIEvent class]);
  [forwardGectureRecognizer touchesMoved:touches7 withEvent:event7];
  OCMVerify([flutterViewController2 touchesMoved:touches7 withEvent:event7]);
  OCMReject([flutterViewController touchesMoved:touches7 withEvent:event7]);

  NSSet* touches8 = [NSSet setWithObject:@1];
  id event8 = OCMClassMock([UIEvent class]);
  [forwardGectureRecognizer touchesEnded:touches8 withEvent:event8];
  OCMVerify([flutterViewController2 touchesEnded:touches8 withEvent:event8]);
  OCMReject([flutterViewController touchesEnded:touches8 withEvent:event8]);

  [flutterPlatformViewsController reset];
}

- (void)testFlutterPlatformViewTouchesCancelledEventAreForcedToBeCancelled {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  // Find ForwardGestureRecognizer
  UIGestureRecognizer* forwardGectureRecognizer = nil;
  for (UIGestureRecognizer* gestureRecognizer in touchInteceptorView.gestureRecognizers) {
    if ([gestureRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]) {
      forwardGectureRecognizer = gestureRecognizer;
      break;
    }
  }
  id flutterViewController = OCMClassMock([FlutterViewController class]);
  flutterPlatformViewsController.flutterViewController = flutterViewController;

  NSSet* touches1 = [NSSet setWithObject:@1];
  id event1 = OCMClassMock([UIEvent class]);
  [forwardGectureRecognizer touchesBegan:touches1 withEvent:event1];

  [forwardGectureRecognizer touchesCancelled:touches1 withEvent:event1];
  OCMVerify([flutterViewController forceTouchesCancelled:touches1]);

  [flutterPlatformViewsController reset];
}

- (void)testFlutterPlatformViewTouchesEndedOrTouchesCancelledEventDoesNotFailTheGestureRecognizer {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  // Find ForwardGestureRecognizer
  __block UIGestureRecognizer* forwardGestureRecognizer = nil;
  for (UIGestureRecognizer* gestureRecognizer in touchInteceptorView.gestureRecognizers) {
    if ([gestureRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]) {
      forwardGestureRecognizer = gestureRecognizer;
      break;
    }
  }
  id flutterViewController = OCMClassMock([FlutterViewController class]);
  flutterPlatformViewsController.flutterViewController = flutterViewController;

  NSSet* touches1 = [NSSet setWithObject:@1];
  id event1 = OCMClassMock([UIEvent class]);
  XCTAssert(forwardGestureRecognizer.state == UIGestureRecognizerStatePossible,
            @"Forwarding gesture recognizer must start with possible state.");
  [forwardGestureRecognizer touchesBegan:touches1 withEvent:event1];
  [forwardGestureRecognizer touchesEnded:touches1 withEvent:event1];
  XCTAssert(forwardGestureRecognizer.state == UIGestureRecognizerStateFailed,
            @"Forwarding gesture recognizer must end with failed state.");

  XCTestExpectation* touchEndedExpectation =
      [self expectationWithDescription:@"Wait for gesture recognizer's state change."];
  dispatch_async(dispatch_get_main_queue(), ^{
    // Re-query forward gesture recognizer since it's recreated.
    for (UIGestureRecognizer* gestureRecognizer in touchInteceptorView.gestureRecognizers) {
      if ([gestureRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]) {
        forwardGestureRecognizer = gestureRecognizer;
        break;
      }
    }
    XCTAssert(forwardGestureRecognizer.state == UIGestureRecognizerStatePossible,
              @"Forwarding gesture recognizer must be reset to possible state.");
    [touchEndedExpectation fulfill];
  });
  [self waitForExpectationsWithTimeout:30 handler:nil];

  XCTAssert(forwardGestureRecognizer.state == UIGestureRecognizerStatePossible,
            @"Forwarding gesture recognizer must start with possible state.");
  [forwardGestureRecognizer touchesBegan:touches1 withEvent:event1];
  [forwardGestureRecognizer touchesCancelled:touches1 withEvent:event1];
  XCTAssert(forwardGestureRecognizer.state == UIGestureRecognizerStateFailed,
            @"Forwarding gesture recognizer must end with failed state.");
  XCTestExpectation* touchCancelledExpectation =
      [self expectationWithDescription:@"Wait for gesture recognizer's state change."];
  dispatch_async(dispatch_get_main_queue(), ^{
    // Re-query forward gesture recognizer since it's recreated.
    for (UIGestureRecognizer* gestureRecognizer in touchInteceptorView.gestureRecognizers) {
      if ([gestureRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]) {
        forwardGestureRecognizer = gestureRecognizer;
        break;
      }
    }
    XCTAssert(forwardGestureRecognizer.state == UIGestureRecognizerStatePossible,
              @"Forwarding gesture recognizer must be reset to possible state.");
    [touchCancelledExpectation fulfill];
  });
  [self waitForExpectationsWithTimeout:30 handler:nil];

  [flutterPlatformViewsController reset];
}

- (void)
    testFlutterPlatformViewBlockGestureUnderEagerPolicyShouldRemoveAndAddBackDelayingRecognizerForWebView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockWebViewFactory* factory =
      [[FlutterPlatformViewsTestMockWebViewFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockWebView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall
                       methodCallWithMethodName:@"create"
                                      arguments:@{@"id" : @2, @"viewType" : @"MockWebView"}]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  XCTAssert(touchInteceptorView.gestureRecognizers.count == 2);
  UIGestureRecognizer* delayingRecognizer = touchInteceptorView.gestureRecognizers[0];
  UIGestureRecognizer* forwardingRecognizer = touchInteceptorView.gestureRecognizers[1];

  XCTAssert([delayingRecognizer isKindOfClass:[FlutterDelayingGestureRecognizer class]]);
  XCTAssert([forwardingRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]);

  [(FlutterTouchInterceptingView*)touchInteceptorView blockGesture];

  BOOL shouldReAddDelayingRecognizer = NO;
  if (@available(iOS 26.0, *)) {
    // TODO(hellohuanlin): find a solution for iOS 26,
    // https://github.com/flutter/flutter/issues/175099.
  } else if (@available(iOS 18.2, *)) {
    shouldReAddDelayingRecognizer = YES;
  }
  if (shouldReAddDelayingRecognizer) {
    // Since we remove and add back delayingRecognizer, it would be reordered to the last.
    XCTAssertEqual(touchInteceptorView.gestureRecognizers[0], forwardingRecognizer);
    XCTAssertEqual(touchInteceptorView.gestureRecognizers[1], delayingRecognizer);
  } else {
    XCTAssertEqual(touchInteceptorView.gestureRecognizers[0], delayingRecognizer);
    XCTAssertEqual(touchInteceptorView.gestureRecognizers[1], forwardingRecognizer);
  }
}

- (void)
    testFlutterPlatformViewBlockGestureUnderEagerPolicyShouldRemoveAndAddBackDelayingRecognizerForWrapperWebView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockWrapperWebViewFactory* factory =
      [[FlutterPlatformViewsTestMockWrapperWebViewFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockWrapperWebView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall
                       methodCallWithMethodName:@"create"
                                      arguments:@{@"id" : @2, @"viewType" : @"MockWrapperWebView"}]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  XCTAssert(touchInteceptorView.gestureRecognizers.count == 2);
  UIGestureRecognizer* delayingRecognizer = touchInteceptorView.gestureRecognizers[0];
  UIGestureRecognizer* forwardingRecognizer = touchInteceptorView.gestureRecognizers[1];

  XCTAssert([delayingRecognizer isKindOfClass:[FlutterDelayingGestureRecognizer class]]);
  XCTAssert([forwardingRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]);

  [(FlutterTouchInterceptingView*)touchInteceptorView blockGesture];

  BOOL shouldReAddDelayingRecognizer = NO;
  if (@available(iOS 26.0, *)) {
    // TODO(hellohuanlin): find a solution for iOS 26,
    // https://github.com/flutter/flutter/issues/175099.
  } else if (@available(iOS 18.2, *)) {
    shouldReAddDelayingRecognizer = YES;
  }
  if (shouldReAddDelayingRecognizer) {
    // Since we remove and add back delayingRecognizer, it would be reordered to the last.
    XCTAssertEqual(touchInteceptorView.gestureRecognizers[0], forwardingRecognizer);
    XCTAssertEqual(touchInteceptorView.gestureRecognizers[1], delayingRecognizer);
  } else {
    XCTAssertEqual(touchInteceptorView.gestureRecognizers[0], delayingRecognizer);
    XCTAssertEqual(touchInteceptorView.gestureRecognizers[1], forwardingRecognizer);
  }
}

- (void)
    testFlutterPlatformViewBlockGestureUnderEagerPolicyShouldNotRemoveAndAddBackDelayingRecognizerForNestedWrapperWebView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockNestedWrapperWebViewFactory* factory =
      [[FlutterPlatformViewsTestMockNestedWrapperWebViewFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockNestedWrapperWebView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockNestedWrapperWebView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  XCTAssert(touchInteceptorView.gestureRecognizers.count == 2);
  UIGestureRecognizer* delayingRecognizer = touchInteceptorView.gestureRecognizers[0];
  UIGestureRecognizer* forwardingRecognizer = touchInteceptorView.gestureRecognizers[1];

  XCTAssert([delayingRecognizer isKindOfClass:[FlutterDelayingGestureRecognizer class]]);
  XCTAssert([forwardingRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]);

  [(FlutterTouchInterceptingView*)touchInteceptorView blockGesture];

  XCTAssertEqual(touchInteceptorView.gestureRecognizers[0], delayingRecognizer);
  XCTAssertEqual(touchInteceptorView.gestureRecognizers[1], forwardingRecognizer);
}

- (void)
    testFlutterPlatformViewBlockGestureUnderEagerPolicyShouldNotRemoveAndAddBackDelayingRecognizerForNonWebView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Find touch inteceptor view
  UIView* touchInteceptorView = gMockPlatformView;
  while (touchInteceptorView != nil &&
         ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
    touchInteceptorView = touchInteceptorView.superview;
  }
  XCTAssertNotNil(touchInteceptorView);

  XCTAssert(touchInteceptorView.gestureRecognizers.count == 2);
  UIGestureRecognizer* delayingRecognizer = touchInteceptorView.gestureRecognizers[0];
  UIGestureRecognizer* forwardingRecognizer = touchInteceptorView.gestureRecognizers[1];

  XCTAssert([delayingRecognizer isKindOfClass:[FlutterDelayingGestureRecognizer class]]);
  XCTAssert([forwardingRecognizer isKindOfClass:[ForwardingGestureRecognizer class]]);

  [(FlutterTouchInterceptingView*)touchInteceptorView blockGesture];

  XCTAssertEqual(touchInteceptorView.gestureRecognizers[0], delayingRecognizer);
  XCTAssertEqual(touchInteceptorView.gestureRecognizers[1], forwardingRecognizer);
}

- (void)
    testFlutterPlatformViewBlockGestureUnderEagerPolicyShouldDisableAndReEnableTouchEventsGestureRecognizerForSimpleWebView {
  if (@available(iOS 26.0, *)) {
    flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

    flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                                 /*platform=*/GetDefaultTaskRunner(),
                                 /*raster=*/GetDefaultTaskRunner(),
                                 /*ui=*/GetDefaultTaskRunner(),
                                 /*io=*/GetDefaultTaskRunner());
    FlutterPlatformViewsController* flutterPlatformViewsController =
        [[FlutterPlatformViewsController alloc] init];
    flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
    auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
        /*delegate=*/mock_delegate,
        /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
        /*platform_views_controller=*/flutterPlatformViewsController,
        /*task_runners=*/runners,
        /*worker_task_runner=*/nil,
        /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

    FlutterPlatformViewsTestMockWebViewFactory* factory =
        [[FlutterPlatformViewsTestMockWebViewFactory alloc] init];
    [flutterPlatformViewsController
                     registerViewFactory:factory
                                  withId:@"MockWebView"
        gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
    FlutterResult result = ^(id result) {
    };
    [flutterPlatformViewsController
        onMethodCall:[FlutterMethodCall
                         methodCallWithMethodName:@"create"
                                        arguments:@{@"id" : @2, @"viewType" : @"MockWebView"}]
              result:result];

    XCTAssertNotNil(gMockPlatformView);

    // Find touch inteceptor view
    UIView* touchInteceptorView = gMockPlatformView;
    while (touchInteceptorView != nil &&
           ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
      touchInteceptorView = touchInteceptorView.superview;
    }
    XCTAssertNotNil(touchInteceptorView);

    /*
      Simple Web View at root, with [*] indicating views containing
      MockTouchEventsGestureRecognizer.

      Root (Web View) [*]
        ├── Child 1
        └── Child 2
              ├── Child 2.1
              └── Child 2.2 [*]
    */

    UIView* root = gMockPlatformView;
    root.gestureRecognizers = nil;
    for (UIView* subview in root.subviews) {
      [subview removeFromSuperview];
    }

    MockGestureRecognizer* normalRecognizer0 = [[MockGestureRecognizer alloc] init];
    [root addGestureRecognizer:normalRecognizer0];

    UIView* child1 = [[UIView alloc] init];
    [root addSubview:child1];
    MockGestureRecognizer* normalRecognizer1 = [[MockGestureRecognizer alloc] init];
    [child1 addGestureRecognizer:normalRecognizer1];

    UIView* child2 = [[UIView alloc] init];
    [root addSubview:child2];
    MockGestureRecognizer* normalRecognizer2 = [[MockGestureRecognizer alloc] init];
    [child2 addGestureRecognizer:normalRecognizer2];

    UIView* child2_1 = [[UIView alloc] init];
    [child2 addSubview:child2_1];
    MockGestureRecognizer* normalRecognizer2_1 = [[MockGestureRecognizer alloc] init];
    [child2_1 addGestureRecognizer:normalRecognizer2_1];

    UIView* child2_2 = [[UIView alloc] init];
    [child2 addSubview:child2_2];
    MockGestureRecognizer* normalRecognizer2_2 = [[MockGestureRecognizer alloc] init];
    [child2_2 addGestureRecognizer:normalRecognizer2_2];

    // Add the target recognizer at root & child2_2.
    MockTouchEventsGestureRecognizer* targetRecognizer0 =
        [[MockTouchEventsGestureRecognizer alloc] init];
    [root addGestureRecognizer:targetRecognizer0];

    MockTouchEventsGestureRecognizer* targetRecognizer2_2 =
        [[MockTouchEventsGestureRecognizer alloc] init];
    [child2_2 addGestureRecognizer:targetRecognizer2_2];

    [(FlutterTouchInterceptingView*)touchInteceptorView blockGesture];

    NSArray* normalRecognizers = @[
      normalRecognizer0, normalRecognizer1, normalRecognizer2, normalRecognizer2_1,
      normalRecognizer2_2
    ];

    NSArray* targetRecognizers = @[ targetRecognizer0, targetRecognizer2_2 ];

    NSArray* expectedEmptyHistory = @[];
    NSArray* expectedToggledHistory = @[ @NO, @YES ];

    for (MockGestureRecognizer* recognizer in normalRecognizers) {
      XCTAssertEqualObjects(recognizer.toggleHistory, expectedEmptyHistory);
    }
    for (MockGestureRecognizer* recognizer in targetRecognizers) {
      XCTAssertEqualObjects(recognizer.toggleHistory, expectedToggledHistory);
    }
  }
}

- (void)
    testFlutterPlatformViewBlockGestureUnderEagerPolicyShouldDisableAndReEnableTouchEventsGestureRecognizerForMultipleWebViewInDifferentBranches {
  if (@available(iOS 26.0, *)) {
    flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

    flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                                 /*platform=*/GetDefaultTaskRunner(),
                                 /*raster=*/GetDefaultTaskRunner(),
                                 /*ui=*/GetDefaultTaskRunner(),
                                 /*io=*/GetDefaultTaskRunner());
    FlutterPlatformViewsController* flutterPlatformViewsController =
        [[FlutterPlatformViewsController alloc] init];
    flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
    auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
        /*delegate=*/mock_delegate,
        /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
        /*platform_views_controller=*/flutterPlatformViewsController,
        /*task_runners=*/runners,
        /*worker_task_runner=*/nil,
        /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

    FlutterPlatformViewsTestMockWrapperWebViewFactory* factory =
        [[FlutterPlatformViewsTestMockWrapperWebViewFactory alloc] init];
    [flutterPlatformViewsController
                     registerViewFactory:factory
                                  withId:@"MockWrapperWebView"
        gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
    FlutterResult result = ^(id result) {
    };
    [flutterPlatformViewsController
        onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                       arguments:@{
                                                         @"id" : @2,
                                                         @"viewType" : @"MockWrapperWebView"
                                                       }]
              result:result];

    XCTAssertNotNil(gMockPlatformView);

    // Find touch inteceptor view
    UIView* touchInteceptorView = gMockPlatformView;
    while (touchInteceptorView != nil &&
           ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
      touchInteceptorView = touchInteceptorView.superview;
    }
    XCTAssertNotNil(touchInteceptorView);

    /*
      Platform View with Multiple Web Views in different branches, with [*] indicating views
      containing MockTouchEventsGestureRecognizer.

      Root (Platform View)
        ├── Child 1
        ├── Child 2 (Web View)
        |       ├── Child 2.1
        |       └── Child 2.2 [*]
        └── Child 3
                └── Child 3.1 (Web View)
                        ├── Child 3.1.1
                        └── Child 3.1.2 [*]
      */

    UIView* root = gMockPlatformView;
    for (UIView* subview in root.subviews) {
      [subview removeFromSuperview];
    }

    MockGestureRecognizer* normalRecognizer0 = [[MockGestureRecognizer alloc] init];
    [root addGestureRecognizer:normalRecognizer0];

    UIView* child1 = [[UIView alloc] init];
    [root addSubview:child1];
    MockGestureRecognizer* normalRecognizer1 = [[MockGestureRecognizer alloc] init];
    [child1 addGestureRecognizer:normalRecognizer1];

    UIView* child2 = [[WKWebView alloc] init];
    child2.gestureRecognizers = nil;
    for (UIView* subview in child2.subviews) {
      [subview removeFromSuperview];
    }
    [root addSubview:child2];
    MockGestureRecognizer* normalRecognizer2 = [[MockGestureRecognizer alloc] init];
    [child2 addGestureRecognizer:normalRecognizer2];

    UIView* child2_1 = [[UIView alloc] init];
    [child2 addSubview:child2_1];
    MockGestureRecognizer* normalRecognizer2_1 = [[MockGestureRecognizer alloc] init];
    [child2_1 addGestureRecognizer:normalRecognizer2_1];

    UIView* child2_2 = [[UIView alloc] init];
    [child2 addSubview:child2_2];
    MockGestureRecognizer* normalRecognizer2_2 = [[MockGestureRecognizer alloc] init];
    [child2_2 addGestureRecognizer:normalRecognizer2_2];

    UIView* child3 = [[UIView alloc] init];
    [root addSubview:child3];
    MockGestureRecognizer* normalRecognizer3 = [[MockGestureRecognizer alloc] init];
    [child3 addGestureRecognizer:normalRecognizer3];

    UIView* child3_1 = [[WKWebView alloc] init];
    child3_1.gestureRecognizers = nil;
    for (UIView* subview in child3_1.subviews) {
      [subview removeFromSuperview];
    }
    [child3 addSubview:child3_1];
    MockGestureRecognizer* normalRecognizer3_1 = [[MockGestureRecognizer alloc] init];
    [child3_1 addGestureRecognizer:normalRecognizer3_1];

    UIView* child3_1_1 = [[UIView alloc] init];
    [child3_1 addSubview:child3_1_1];
    MockGestureRecognizer* normalRecognizer3_1_1 = [[MockGestureRecognizer alloc] init];
    [child3_1_1 addGestureRecognizer:normalRecognizer3_1_1];

    UIView* child3_1_2 = [[UIView alloc] init];
    [child3_1 addSubview:child3_1_2];
    MockGestureRecognizer* normalRecognizer3_1_2 = [[MockGestureRecognizer alloc] init];
    [child3_1_2 addGestureRecognizer:normalRecognizer3_1_2];

    // Add the target recognizer at child2_2 & child3_1_2

    MockTouchEventsGestureRecognizer* targetRecognizer2_2 =
        [[MockTouchEventsGestureRecognizer alloc] init];
    [child2_2 addGestureRecognizer:targetRecognizer2_2];

    MockTouchEventsGestureRecognizer* targetRecognizer3_1_2 =
        [[MockTouchEventsGestureRecognizer alloc] init];
    [child3_1_2 addGestureRecognizer:targetRecognizer3_1_2];

    [(FlutterTouchInterceptingView*)touchInteceptorView blockGesture];

    NSArray* normalRecognizers = @[
      normalRecognizer0, normalRecognizer1, normalRecognizer2, normalRecognizer2_1,
      normalRecognizer2_2, normalRecognizer3, normalRecognizer3_1, normalRecognizer3_1_1,
      normalRecognizer3_1_2
    ];
    NSArray* targetRecognizers = @[ targetRecognizer2_2, targetRecognizer3_1_2 ];

    NSArray* expectedEmptyHistory = @[];
    NSArray* expectedToggledHistory = @[ @NO, @YES ];

    for (MockGestureRecognizer* recognizer in normalRecognizers) {
      XCTAssertEqualObjects(recognizer.toggleHistory, expectedEmptyHistory);
    }

    for (MockGestureRecognizer* recognizer in targetRecognizers) {
      XCTAssertEqualObjects(recognizer.toggleHistory, expectedToggledHistory);
    }
  }
}

- (void)
    testFlutterPlatformViewBlockGestureUnderEagerPolicyShouldDisableAndReEnableTouchEventsGestureRecognizerForNestedMultipleWebView {
  if (@available(iOS 26.0, *)) {
    flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

    flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                                 /*platform=*/GetDefaultTaskRunner(),
                                 /*raster=*/GetDefaultTaskRunner(),
                                 /*ui=*/GetDefaultTaskRunner(),
                                 /*io=*/GetDefaultTaskRunner());
    FlutterPlatformViewsController* flutterPlatformViewsController =
        [[FlutterPlatformViewsController alloc] init];
    flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
    auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
        /*delegate=*/mock_delegate,
        /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
        /*platform_views_controller=*/flutterPlatformViewsController,
        /*task_runners=*/runners,
        /*worker_task_runner=*/nil,
        /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

    FlutterPlatformViewsTestMockWebViewFactory* factory =
        [[FlutterPlatformViewsTestMockWebViewFactory alloc] init];
    [flutterPlatformViewsController
                     registerViewFactory:factory
                                  withId:@"MockWebView"
        gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
    FlutterResult result = ^(id result) {
    };
    [flutterPlatformViewsController
        onMethodCall:[FlutterMethodCall
                         methodCallWithMethodName:@"create"
                                        arguments:@{@"id" : @2, @"viewType" : @"MockWebView"}]
              result:result];

    XCTAssertNotNil(gMockPlatformView);

    // Find touch inteceptor view
    UIView* touchInteceptorView = gMockPlatformView;
    while (touchInteceptorView != nil &&
           ![touchInteceptorView isKindOfClass:[FlutterTouchInterceptingView class]]) {
      touchInteceptorView = touchInteceptorView.superview;
    }
    XCTAssertNotNil(touchInteceptorView);

    /*
      Platform View with nested web views, with [*] indicating views containing
    MockTouchEventsGestureRecognizer.

    Root (Web View)
      ├── Child 1
      ├── Child 2
      |     ├── Child 2.1
      |     └── Child 2.2 [*]
      └── Child 3
            └── Child 3.1 (Another Web View)
                  └── Child 3.1.1
                  └── Child 3.1.2
                        ├── Child 3.1.2.1
                        └── Child 3.1.2.2 [*]
      */

    UIView* root = gMockPlatformView;
    root.gestureRecognizers = nil;
    for (UIView* subview in root.subviews) {
      [subview removeFromSuperview];
    }

    MockGestureRecognizer* normalRecognizer0 = [[MockGestureRecognizer alloc] init];
    [root addGestureRecognizer:normalRecognizer0];

    UIView* child1 = [[UIView alloc] init];
    [root addSubview:child1];
    MockGestureRecognizer* normalRecognizer1 = [[MockGestureRecognizer alloc] init];
    [child1 addGestureRecognizer:normalRecognizer1];

    UIView* child2 = [[UIView alloc] init];
    [root addSubview:child2];
    MockGestureRecognizer* normalRecognizer2 = [[MockGestureRecognizer alloc] init];
    [child2 addGestureRecognizer:normalRecognizer2];

    UIView* child2_1 = [[UIView alloc] init];
    [child2 addSubview:child2_1];
    MockGestureRecognizer* normalRecognizer2_1 = [[MockGestureRecognizer alloc] init];
    [child2_1 addGestureRecognizer:normalRecognizer2_1];

    UIView* child2_2 = [[UIView alloc] init];
    [child2 addSubview:child2_2];
    MockGestureRecognizer* normalRecognizer2_2 = [[MockGestureRecognizer alloc] init];
    [child2_2 addGestureRecognizer:normalRecognizer2_2];

    UIView* child3 = [[UIView alloc] init];
    [root addSubview:child3];
    MockGestureRecognizer* normalRecognizer3 = [[MockGestureRecognizer alloc] init];
    [child3 addGestureRecognizer:normalRecognizer3];

    UIView* child3_1 = [[WKWebView alloc] init];
    child3_1.gestureRecognizers = nil;
    for (UIView* subview in child3_1.subviews) {
      [subview removeFromSuperview];
    }
    [child3 addSubview:child3_1];
    MockGestureRecognizer* normalRecognizer3_1 = [[MockGestureRecognizer alloc] init];
    [child3_1 addGestureRecognizer:normalRecognizer3_1];

    UIView* child3_1_1 = [[UIView alloc] init];
    [child3_1 addSubview:child3_1_1];
    MockGestureRecognizer* normalRecognizer3_1_1 = [[MockGestureRecognizer alloc] init];
    [child3_1_1 addGestureRecognizer:normalRecognizer3_1_1];

    UIView* child3_1_2 = [[UIView alloc] init];
    [child3_1 addSubview:child3_1_2];
    MockGestureRecognizer* normalRecognizer3_1_2 = [[MockGestureRecognizer alloc] init];
    [child3_1_2 addGestureRecognizer:normalRecognizer3_1_2];

    UIView* child3_1_2_1 = [[UIView alloc] init];
    [child3_1_2 addSubview:child3_1_2_1];
    MockGestureRecognizer* normalRecognizer3_1_2_1 = [[MockGestureRecognizer alloc] init];
    [child3_1_2_1 addGestureRecognizer:normalRecognizer3_1_2_1];

    UIView* child3_1_2_2 = [[UIView alloc] init];
    [child3_1_2 addSubview:child3_1_2_2];
    MockGestureRecognizer* normalRecognizer3_1_2_2 = [[MockGestureRecognizer alloc] init];
    [child3_1_2_2 addGestureRecognizer:normalRecognizer3_1_2_2];

    // Add the target recognizer at child2_2 & child3_1_2_2

    MockTouchEventsGestureRecognizer* targetRecognizer2_2 =
        [[MockTouchEventsGestureRecognizer alloc] init];
    [child2_2 addGestureRecognizer:targetRecognizer2_2];

    MockTouchEventsGestureRecognizer* targetRecognizer3_1_2_2 =
        [[MockTouchEventsGestureRecognizer alloc] init];
    [child3_1_2_2 addGestureRecognizer:targetRecognizer3_1_2_2];

    [(FlutterTouchInterceptingView*)touchInteceptorView blockGesture];

    NSArray* normalRecognizers = @[
      normalRecognizer0, normalRecognizer1, normalRecognizer2, normalRecognizer2_1,
      normalRecognizer2_2, normalRecognizer3, normalRecognizer3_1, normalRecognizer3_1_1,
      normalRecognizer3_1_2, normalRecognizer3_1_2_1, normalRecognizer3_1_2_2
    ];

    NSArray* targetRecognizers = @[ targetRecognizer2_2, targetRecognizer3_1_2_2 ];

    NSArray* expectedEmptyHistory = @[];
    NSArray* expectedToggledHistory = @[ @NO, @YES ];

    for (MockGestureRecognizer* recognizer in normalRecognizers) {
      XCTAssertEqualObjects(recognizer.toggleHistory, expectedEmptyHistory);
    }

    for (MockGestureRecognizer* recognizer in targetRecognizers) {
      XCTAssertEqualObjects(recognizer.toggleHistory, expectedToggledHistory);
    }
  }
}

- (void)testFlutterPlatformViewControllerSubmitFrameWithoutFlutterViewNotCrashing {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  // Create embedded view params
  flutter::MutatorsStack stack;
  flutter::DlMatrix finalMatrix;

  auto embeddedViewParams_1 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams_1)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  auto mock_surface = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return false; },
      [](const flutter::SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/flutter::DlISize(800, 600));
  XCTAssertFalse([flutterPlatformViewsController
         submitFrame:std::move(mock_surface)
      withIosContext:std::make_shared<flutter::IOSContextNoop>()]);

  auto embeddedViewParams_2 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams_2)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  auto mock_surface_submit_true = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
      [](const flutter::SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/flutter::DlISize(800, 600));
  XCTAssertTrue([flutterPlatformViewsController
         submitFrame:std::move(mock_surface_submit_true)
      withIosContext:std::make_shared<flutter::IOSContextNoop>()]);
}

- (void)
    testFlutterPlatformViewControllerResetDeallocsPlatformViewWhenRootViewsNotBindedToFlutterView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  // autorelease pool to trigger an autorelease for all the root_views_ and touch_interceptors_.
  @autoreleasepool {
    [flutterPlatformViewsController
        onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                       arguments:@{
                                                         @"id" : @2,
                                                         @"viewType" : @"MockFlutterPlatformView"
                                                       }]
              result:result];

    flutter::MutatorsStack stack;
    flutter::DlMatrix finalMatrix;
    auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
        finalMatrix, flutter::DlSize(300, 300), stack);
    [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                      withParams:std::move(embeddedViewParams)];

    // Not calling |[flutterPlatformViewsController submitFrame:withIosContext:]| so that
    // the platform views are not added to flutter_view_.

    XCTAssertNotNil(gMockPlatformView);
    [flutterPlatformViewsController reset];
  }
  XCTAssertNil(gMockPlatformView);
}

- (void)testFlutterPlatformViewControllerBeginFrameShouldResetCompisitionOrder {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };

  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @0,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  // First frame, |embeddedViewCount| is not empty after composite.
  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(300, 300)];
  flutter::MutatorsStack stack;
  flutter::DlMatrix finalMatrix;
  auto embeddedViewParams1 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:0
                                                    withParams:std::move(embeddedViewParams1)];
  [flutterPlatformViewsController
      compositeView:0
         withParams:[flutterPlatformViewsController compositionParamsForView:0]];

  XCTAssertEqual(flutterPlatformViewsController.embeddedViewCount, 1UL);

  // Second frame, |embeddedViewCount| should be empty at the start
  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(300, 300)];
  XCTAssertEqual(flutterPlatformViewsController.embeddedViewCount, 0UL);

  auto embeddedViewParams2 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:0
                                                    withParams:std::move(embeddedViewParams2)];
  [flutterPlatformViewsController
      compositeView:0
         withParams:[flutterPlatformViewsController compositionParamsForView:0]];

  XCTAssertEqual(flutterPlatformViewsController.embeddedViewCount, 1UL);
}

- (void)
    testFlutterPlatformViewControllerSubmitFrameShouldOrderSubviewsCorrectlyWithDifferentViewHierarchy {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @0,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* view1 = gMockPlatformView;

  // This overwrites `gMockPlatformView` to another view.
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @1,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* view2 = gMockPlatformView;

  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(300, 300)];
  flutter::MutatorsStack stack;
  flutter::DlMatrix finalMatrix;
  auto embeddedViewParams1 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:0
                                                    withParams:std::move(embeddedViewParams1)];

  auto embeddedViewParams2 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(500, 500), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                    withParams:std::move(embeddedViewParams2)];

  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  auto mock_surface = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
      [](const flutter::SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/flutter::DlISize(800, 600), nullptr, /*display_list_fallback=*/true);
  XCTAssertTrue([flutterPlatformViewsController
         submitFrame:std::move(mock_surface)
      withIosContext:std::make_shared<flutter::IOSContextNoop>()]);

  // platform view is wrapped by touch interceptor, which itself is wrapped by clipping view.
  UIView* clippingView1 = view1.superview.superview;
  UIView* clippingView2 = view2.superview.superview;
  XCTAssertTrue([flutterView.subviews indexOfObject:clippingView1] <
                    [flutterView.subviews indexOfObject:clippingView2],
                @"The first clipping view should be added before the second clipping view.");

  // Need to recreate these params since they are `std::move`ed.
  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(300, 300)];
  // Process the second frame in the opposite order.
  embeddedViewParams2 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(500, 500), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                    withParams:std::move(embeddedViewParams2)];

  embeddedViewParams1 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:0
                                                    withParams:std::move(embeddedViewParams1)];

  mock_surface = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
      [](const flutter::SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/flutter::DlISize(800, 600), nullptr, /*display_list_fallback=*/true);
  XCTAssertTrue([flutterPlatformViewsController
         submitFrame:std::move(mock_surface)
      withIosContext:std::make_shared<flutter::IOSContextNoop>()]);

  XCTAssertTrue([flutterView.subviews indexOfObject:clippingView1] >
                    [flutterView.subviews indexOfObject:clippingView2],
                @"The first clipping view should be added after the second clipping view.");
}

- (void)
    testFlutterPlatformViewControllerSubmitFrameShouldOrderSubviewsCorrectlyWithSameViewHierarchy {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @0,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* view1 = gMockPlatformView;

  // This overwrites `gMockPlatformView` to another view.
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @1,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* view2 = gMockPlatformView;

  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(300, 300)];
  flutter::MutatorsStack stack;
  flutter::DlMatrix finalMatrix;
  auto embeddedViewParams1 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:0
                                                    withParams:std::move(embeddedViewParams1)];

  auto embeddedViewParams2 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(500, 500), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                    withParams:std::move(embeddedViewParams2)];

  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  auto mock_surface = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
      [](const flutter::SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/flutter::DlISize(800, 600), nullptr, /*display_list_fallback=*/true);
  XCTAssertTrue([flutterPlatformViewsController
         submitFrame:std::move(mock_surface)
      withIosContext:std::make_shared<flutter::IOSContextNoop>()]);

  // platform view is wrapped by touch interceptor, which itself is wrapped by clipping view.
  UIView* clippingView1 = view1.superview.superview;
  UIView* clippingView2 = view2.superview.superview;
  XCTAssertTrue([flutterView.subviews indexOfObject:clippingView1] <
                    [flutterView.subviews indexOfObject:clippingView2],
                @"The first clipping view should be added before the second clipping view.");

  // Need to recreate these params since they are `std::move`ed.
  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(300, 300)];
  // Process the second frame in the same order.
  embeddedViewParams1 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:0
                                                    withParams:std::move(embeddedViewParams1)];

  embeddedViewParams2 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(500, 500), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                    withParams:std::move(embeddedViewParams2)];

  mock_surface = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
      [](const flutter::SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/flutter::DlISize(800, 600), nullptr, /*display_list_fallback=*/true);
  XCTAssertTrue([flutterPlatformViewsController
         submitFrame:std::move(mock_surface)
      withIosContext:std::make_shared<flutter::IOSContextNoop>()]);

  XCTAssertTrue([flutterView.subviews indexOfObject:clippingView1] <
                    [flutterView.subviews indexOfObject:clippingView2],
                @"The first clipping view should be added before the second clipping view.");
}

- (int)alphaOfPoint:(CGPoint)point onView:(UIView*)view {
  unsigned char pixel[4] = {0};

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  // Draw the pixel on `point` in the context.
  CGContextRef context =
      CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace,
                            static_cast<uint32_t>(kCGBitmapAlphaInfoMask) &
                                static_cast<uint32_t>(kCGImageAlphaPremultipliedLast));
  CGContextTranslateCTM(context, -point.x, -point.y);
  [view.layer renderInContext:context];

  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  // Get the alpha from the pixel that we just rendered.
  return pixel[3];
}

- (void)testHasFirstResponderInViewHierarchySubtree_viewItselfBecomesFirstResponder {
  // For view to become the first responder, it must be a descendant of a UIWindow
  UIWindow* window = [[UIWindow alloc] init];
  UITextField* textField = [[UITextField alloc] init];
  [window addSubview:textField];

  [textField becomeFirstResponder];
  XCTAssertTrue(textField.isFirstResponder);
  XCTAssertTrue(textField.flt_hasFirstResponderInViewHierarchySubtree);
  [textField resignFirstResponder];
  XCTAssertFalse(textField.isFirstResponder);
  XCTAssertFalse(textField.flt_hasFirstResponderInViewHierarchySubtree);
}

- (void)testHasFirstResponderInViewHierarchySubtree_descendantViewBecomesFirstResponder {
  // For view to become the first responder, it must be a descendant of a UIWindow
  UIWindow* window = [[UIWindow alloc] init];
  UIView* view = [[UIView alloc] init];
  UIView* childView = [[UIView alloc] init];
  UITextField* textField = [[UITextField alloc] init];
  [window addSubview:view];
  [view addSubview:childView];
  [childView addSubview:textField];

  [textField becomeFirstResponder];
  XCTAssertTrue(textField.isFirstResponder);
  XCTAssertTrue(view.flt_hasFirstResponderInViewHierarchySubtree);
  [textField resignFirstResponder];
  XCTAssertFalse(textField.isFirstResponder);
  XCTAssertFalse(view.flt_hasFirstResponderInViewHierarchySubtree);
}

- (void)testFlutterClippingMaskViewPoolReuseViewsAfterRecycle {
  FlutterClippingMaskViewPool* pool = [[FlutterClippingMaskViewPool alloc] initWithCapacity:2];
  FlutterClippingMaskView* view1 = [pool getMaskViewWithFrame:CGRectZero];
  FlutterClippingMaskView* view2 = [pool getMaskViewWithFrame:CGRectZero];
  [pool insertViewToPoolIfNeeded:view1];
  [pool insertViewToPoolIfNeeded:view2];
  CGRect newRect = CGRectMake(0, 0, 10, 10);
  FlutterClippingMaskView* view3 = [pool getMaskViewWithFrame:newRect];
  FlutterClippingMaskView* view4 = [pool getMaskViewWithFrame:newRect];
  // view3 and view4 should randomly get either of view1 and view2.
  NSSet* set1 = [NSSet setWithObjects:view1, view2, nil];
  NSSet* set2 = [NSSet setWithObjects:view3, view4, nil];
  XCTAssertEqualObjects(set1, set2);
  XCTAssertTrue(CGRectEqualToRect(view3.frame, newRect));
  XCTAssertTrue(CGRectEqualToRect(view4.frame, newRect));
}

- (void)testFlutterClippingMaskViewPoolAllocsNewMaskViewsAfterReachingCapacity {
  FlutterClippingMaskViewPool* pool = [[FlutterClippingMaskViewPool alloc] initWithCapacity:2];
  FlutterClippingMaskView* view1 = [pool getMaskViewWithFrame:CGRectZero];
  FlutterClippingMaskView* view2 = [pool getMaskViewWithFrame:CGRectZero];
  FlutterClippingMaskView* view3 = [pool getMaskViewWithFrame:CGRectZero];
  XCTAssertNotEqual(view1, view3);
  XCTAssertNotEqual(view2, view3);
}

- (void)testMaskViewsReleasedWhenPoolIsReleased {
  __weak UIView* weakView;
  @autoreleasepool {
    FlutterClippingMaskViewPool* pool = [[FlutterClippingMaskViewPool alloc] initWithCapacity:2];
    FlutterClippingMaskView* view = [pool getMaskViewWithFrame:CGRectZero];
    weakView = view;
    XCTAssertNotNil(weakView);
  }
  XCTAssertNil(weakView);
}

- (void)testClipMaskViewIsReused {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @1,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);
  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack1;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack1.PushTransform(screenScaleMatrix);
  // Push a clip rect
  flutter::DlRect rect = flutter::DlRect::MakeXYWH(2, 2, 3, 3);
  stack1.PushClipRect(rect);

  auto embeddedViewParams1 = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack1);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                    withParams:std::move(embeddedViewParams1)];
  [flutterPlatformViewsController
      compositeView:1
         withParams:[flutterPlatformViewsController compositionParamsForView:1]];

  UIView* childClippingView1 = gMockPlatformView.superview.superview;
  UIView* maskView1 = childClippingView1.maskView;
  XCTAssertNotNil(maskView1);

  // Composite a new frame.
  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(100, 100)];
  flutter::MutatorsStack stack2;
  auto embeddedViewParams2 = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);
  auto embeddedViewParams3 = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                    withParams:std::move(embeddedViewParams3)];
  [flutterPlatformViewsController
      compositeView:1
         withParams:[flutterPlatformViewsController compositionParamsForView:1]];

  childClippingView1 = gMockPlatformView.superview.superview;

  // This overrides gMockPlatformView to point to the newly created platform view.
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  auto embeddedViewParams4 = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack1);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams4)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  UIView* childClippingView2 = gMockPlatformView.superview.superview;

  UIView* maskView2 = childClippingView2.maskView;
  XCTAssertEqual(maskView1, maskView2);
  XCTAssertNotNil(childClippingView2.maskView);
  XCTAssertNil(childClippingView1.maskView);
}

- (void)testDifferentClipMaskViewIsUsedForEachView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };

  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @1,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* view1 = gMockPlatformView;

  // This overwrites `gMockPlatformView` to another view.
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* view2 = gMockPlatformView;

  XCTAssertNotNil(gMockPlatformView);
  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack1;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack1.PushTransform(screenScaleMatrix);
  // Push a clip rect
  flutter::DlRect rect = flutter::DlRect::MakeXYWH(2, 2, 3, 3);
  stack1.PushClipRect(rect);

  auto embeddedViewParams1 = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack1);

  flutter::MutatorsStack stack2;
  stack2.PushClipRect(rect);
  auto embeddedViewParams2 = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                    withParams:std::move(embeddedViewParams1)];
  [flutterPlatformViewsController
      compositeView:1
         withParams:[flutterPlatformViewsController compositionParamsForView:1]];

  UIView* childClippingView1 = view1.superview.superview;

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams2)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  UIView* childClippingView2 = view2.superview.superview;
  UIView* maskView1 = childClippingView1.maskView;
  UIView* maskView2 = childClippingView2.maskView;
  XCTAssertNotEqual(maskView1, maskView2);
}

- (void)testMaskViewUsesCAShapeLayerAsTheBackingLayer {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };

  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @1,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);
  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack1;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack1.PushTransform(screenScaleMatrix);
  // Push a clip rect
  flutter::DlRect rect = flutter::DlRect::MakeXYWH(2, 2, 3, 3);
  stack1.PushClipRect(rect);

  auto embeddedViewParams1 = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack1);

  flutter::MutatorsStack stack2;
  stack2.PushClipRect(rect);
  auto embeddedViewParams2 = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack2);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                    withParams:std::move(embeddedViewParams1)];
  [flutterPlatformViewsController
      compositeView:1
         withParams:[flutterPlatformViewsController compositionParamsForView:1]];

  UIView* childClippingView = gMockPlatformView.superview.superview;

  UIView* maskView = childClippingView.maskView;
  XCTAssert([maskView.layer isKindOfClass:[CAShapeLayer class]],
            @"Mask view must use CAShapeLayer as its backing layer.");
}

// Return true if a correct visual effect view is found. It also implies all the validation in this
// method passes.
//
// There are two fail states for this method. 1. One of the XCTAssert method failed; or 2. No
// correct visual effect view found.
- (BOOL)validateOneVisualEffectView:(UIView*)visualEffectView
                      expectedFrame:(CGRect)frame
                        inputRadius:(CGFloat)inputRadius {
  XCTAssertTrue(CGRectEqualToRect(visualEffectView.frame, frame));
  for (UIView* view in visualEffectView.subviews) {
    if (![NSStringFromClass([view class]) hasSuffix:@"BackdropView"]) {
      continue;
    }
    XCTAssertEqual(view.layer.filters.count, 1u);
    NSObject* filter = view.layer.filters.firstObject;

    XCTAssertEqualObjects([filter valueForKey:@"name"], @"gaussianBlur");

    NSObject* inputRadiusInFilter = [filter valueForKey:@"inputRadius"];
    XCTAssertTrue([inputRadiusInFilter isKindOfClass:[NSNumber class]] &&
                  flutter::BlurRadiusEqualToBlurRadius(((NSNumber*)inputRadiusInFilter).floatValue,
                                                       inputRadius));
    return YES;
  }
  return NO;
}

- (void)testDisposingViewInCompositionOrderDoNotCrash {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };

  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @0,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @1,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  {
    // **** First frame, view id 0, 1 in the composition_order_, disposing view 0 is called. **** //
    // No view should be disposed, or removed from the composition order.
    [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(300, 300)];
    flutter::MutatorsStack stack;
    flutter::DlMatrix finalMatrix;
    auto embeddedViewParams0 = std::make_unique<flutter::EmbeddedViewParams>(
        finalMatrix, flutter::DlSize(300, 300), stack);
    [flutterPlatformViewsController prerollCompositeEmbeddedView:0
                                                      withParams:std::move(embeddedViewParams0)];

    auto embeddedViewParams1 = std::make_unique<flutter::EmbeddedViewParams>(
        finalMatrix, flutter::DlSize(300, 300), stack);
    [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                      withParams:std::move(embeddedViewParams1)];

    XCTAssertEqual(flutterPlatformViewsController.embeddedViewCount, 2UL);

    XCTestExpectation* expectation = [self expectationWithDescription:@"dispose call ended."];
    FlutterResult disposeResult = ^(id result) {
      [expectation fulfill];
    };

    [flutterPlatformViewsController
        onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"dispose" arguments:@0]
              result:disposeResult];
    [self waitForExpectationsWithTimeout:30 handler:nil];

    flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
    auto mock_surface = std::make_unique<flutter::SurfaceFrame>(
        nullptr, framebuffer_info,
        [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
        [](const flutter::SurfaceFrame& surface_frame) { return true; },
        /*frame_size=*/flutter::DlISize(800, 600), nullptr,
        /*display_list_fallback=*/true);
    XCTAssertTrue([flutterPlatformViewsController
           submitFrame:std::move(mock_surface)
        withIosContext:std::make_shared<flutter::IOSContextNoop>()]);

    // Disposing won't remove embedded views until the view is removed from the composition_order_
    XCTAssertEqual(flutterPlatformViewsController.embeddedViewCount, 2UL);
    XCTAssertNotNil([flutterPlatformViewsController platformViewForId:0]);
    XCTAssertNotNil([flutterPlatformViewsController platformViewForId:1]);
  }

  {
    // **** Second frame, view id 1 in the composition_order_, no disposing view is called,  **** //
    // View 0 is removed from the composition order in this frame, hence also disposed.
    [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(300, 300)];
    flutter::MutatorsStack stack;
    flutter::DlMatrix finalMatrix;
    auto embeddedViewParams1 = std::make_unique<flutter::EmbeddedViewParams>(
        finalMatrix, flutter::DlSize(300, 300), stack);
    [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                      withParams:std::move(embeddedViewParams1)];

    flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
    auto mock_surface = std::make_unique<flutter::SurfaceFrame>(
        nullptr, framebuffer_info,
        [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
        [](const flutter::SurfaceFrame& surface_frame) { return true; },
        /*frame_size=*/flutter::DlISize(800, 600), nullptr, /*display_list_fallback=*/true);
    XCTAssertTrue([flutterPlatformViewsController
           submitFrame:std::move(mock_surface)
        withIosContext:std::make_shared<flutter::IOSContextNoop>()]);

    // Disposing won't remove embedded views until the view is removed from the composition_order_
    XCTAssertEqual(flutterPlatformViewsController.embeddedViewCount, 1UL);
    XCTAssertNil([flutterPlatformViewsController platformViewForId:0]);
    XCTAssertNotNil([flutterPlatformViewsController platformViewForId:1]);
  }
}
- (void)testOnlyPlatformViewsAreRemovedWhenReset {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a translate matrix
  flutter::DlMatrix translateMatrix = flutter::DlMatrix::MakeTranslation({100, 100});
  stack.PushTransform(translateMatrix);
  flutter::DlMatrix finalMatrix = screenScaleMatrix * translateMatrix;

  auto embeddedViewParams =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];

  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  auto mock_surface = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
      [](const flutter::SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/flutter::DlISize(800, 600), nullptr, /*display_list_fallback=*/true);
  [flutterPlatformViewsController submitFrame:std::move(mock_surface)
                               withIosContext:std::make_shared<flutter::IOSContextNoop>()];

  UIView* someView = [[UIView alloc] init];
  [flutterView addSubview:someView];

  [flutterPlatformViewsController reset];
  XCTAssertEqual(flutterView.subviews.count, 1u);
  XCTAssertEqual(flutterView.subviews.firstObject, someView);
}

- (void)testResetClearsPreviousCompositionOrder {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a translate matrix
  flutter::DlMatrix translateMatrix = flutter::DlMatrix::MakeTranslation({100, 100});
  stack.PushTransform(translateMatrix);
  flutter::DlMatrix finalMatrix = screenScaleMatrix * translateMatrix;

  auto embeddedViewParams =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];

  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  auto mock_surface = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
      [](const flutter::SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/flutter::DlISize(800, 600), nullptr, /*display_list_fallback=*/true);
  [flutterPlatformViewsController submitFrame:std::move(mock_surface)
                               withIosContext:std::make_shared<flutter::IOSContextNoop>()];

  // The above code should result in previousCompositionOrder having one viewId in it
  XCTAssertEqual(flutterPlatformViewsController.previousCompositionOrder.size(), 1ul);

  // reset should clear previousCompositionOrder
  [flutterPlatformViewsController reset];

  // previousCompositionOrder should now be empty
  XCTAssertEqual(flutterPlatformViewsController.previousCompositionOrder.size(), 0ul);
}

- (void)testNilPlatformViewDoesntCrash {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestNilFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestNilFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];
  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;

  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a translate matrix
  flutter::DlMatrix translateMatrix = flutter::DlMatrix::MakeTranslation({100, 100});
  stack.PushTransform(translateMatrix);
  flutter::DlMatrix finalMatrix = screenScaleMatrix * translateMatrix;

  auto embeddedViewParams =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];

  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  auto mock_surface = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
      [](const flutter::SurfaceFrame& surface_frame) { return true; },
      /*frame_size=*/flutter::DlISize(800, 600), nullptr, /*display_list_fallback=*/true);
  [flutterPlatformViewsController submitFrame:std::move(mock_surface)
                               withIosContext:std::make_shared<flutter::IOSContextNoop>()];

  XCTAssertEqual(flutterView.subviews.count, 1u);
}

- (void)testFlutterTouchInterceptingViewLinksToAccessibilityContainer {
  FlutterTouchInterceptingView* touchInteceptorView = [[FlutterTouchInterceptingView alloc] init];
  NSObject* container = [[NSObject alloc] init];
  [touchInteceptorView setFlutterAccessibilityContainer:container];
  XCTAssertEqualObjects([touchInteceptorView accessibilityContainer], container);
}

- (void)testLayerPool {
  // Create an IOSContext.
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"foobar"];
  [engine run];
  XCTAssertTrue(engine.platformView != nullptr);
  auto ios_context = engine.platformView->GetIosContext();

  auto pool = flutter::OverlayLayerPool{};

  // Add layers to the pool.
  pool.CreateLayer(ios_context, MTLPixelFormatBGRA8Unorm);
  XCTAssertEqual(pool.size(), 1u);
  pool.CreateLayer(ios_context, MTLPixelFormatBGRA8Unorm);
  XCTAssertEqual(pool.size(), 2u);

  // Mark all layers as unused.
  pool.RecycleLayers();
  XCTAssertEqual(pool.size(), 2u);

  // Free the unused layers. One should remain.
  auto unused_layers = pool.RemoveUnusedLayers();
  XCTAssertEqual(unused_layers.size(), 2u);
  XCTAssertEqual(pool.size(), 1u);
}

- (void)testFlutterPlatformViewControllerSubmitFramePreservingFrameDamage {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
  flutterPlatformViewsController.flutterView = flutterView;

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @0,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  // This overwrites `gMockPlatformView` to another view.
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @1,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  [flutterPlatformViewsController beginFrameWithSize:flutter::DlISize(300, 300)];
  flutter::MutatorsStack stack;
  flutter::DlMatrix finalMatrix;
  auto embeddedViewParams1 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(300, 300), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:0
                                                    withParams:std::move(embeddedViewParams1)];

  auto embeddedViewParams2 =
      std::make_unique<flutter::EmbeddedViewParams>(finalMatrix, flutter::DlSize(500, 500), stack);
  [flutterPlatformViewsController prerollCompositeEmbeddedView:1
                                                    withParams:std::move(embeddedViewParams2)];

  flutter::SurfaceFrame::FramebufferInfo framebuffer_info;
  std::optional<flutter::SurfaceFrame::SubmitInfo> submit_info;
  auto mock_surface = std::make_unique<flutter::SurfaceFrame>(
      nullptr, framebuffer_info,
      [](const flutter::SurfaceFrame& surface_frame, flutter::DlCanvas* canvas) { return true; },
      [&](const flutter::SurfaceFrame& surface_frame) {
        submit_info = surface_frame.submit_info();
        return true;
      },
      /*frame_size=*/flutter::DlISize(800, 600), nullptr,
      /*display_list_fallback=*/true);
  mock_surface->set_submit_info({
      .frame_damage = flutter::DlIRect::MakeWH(800, 600),
      .buffer_damage = flutter::DlIRect::MakeWH(400, 600),
  });

  [flutterPlatformViewsController submitFrame:std::move(mock_surface)
                               withIosContext:std::make_shared<flutter::IOSContextNoop>()];

  XCTAssertTrue(submit_info.has_value());
  XCTAssertEqual(*submit_info->frame_damage, flutter::DlIRect::MakeWH(800, 600));
  XCTAssertEqual(*submit_info->buffer_damage, flutter::DlIRect::MakeWH(400, 600));
}

- (void)testClipSuperellipse {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;

  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/GetDefaultTaskRunner(),
                               /*raster=*/GetDefaultTaskRunner(),
                               /*ui=*/GetDefaultTaskRunner(),
                               /*io=*/GetDefaultTaskRunner());
  FlutterPlatformViewsController* flutterPlatformViewsController =
      [[FlutterPlatformViewsController alloc] init];
  flutterPlatformViewsController.taskRunner = GetDefaultTaskRunner();
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/flutterPlatformViewsController,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_jsync_switch=*/std::make_shared<fml::SyncSwitch>());

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory alloc] init];
  [flutterPlatformViewsController
                   registerViewFactory:factory
                                withId:@"MockFlutterPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  FlutterResult result = ^(id result) {
  };
  [flutterPlatformViewsController
      onMethodCall:[FlutterMethodCall methodCallWithMethodName:@"create"
                                                     arguments:@{
                                                       @"id" : @2,
                                                       @"viewType" : @"MockFlutterPlatformView"
                                                     }]
            result:result];

  XCTAssertNotNil(gMockPlatformView);

  UIView* flutterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  flutterPlatformViewsController.flutterView = flutterView;
  // Create embedded view params
  flutter::MutatorsStack stack;
  // Layer tree always pushes a screen scale factor to the stack
  flutter::DlScalar screenScale = [UIScreen mainScreen].scale;
  flutter::DlMatrix screenScaleMatrix = flutter::DlMatrix::MakeScale({screenScale, screenScale, 1});
  stack.PushTransform(screenScaleMatrix);
  // Push a clip superellipse
  flutter::DlRect rect = flutter::DlRect::MakeXYWH(3, 3, 5, 5);
  stack.PushClipRSE(flutter::DlRoundSuperellipse::MakeOval(rect));

  auto embeddedViewParams = std::make_unique<flutter::EmbeddedViewParams>(
      screenScaleMatrix, flutter::DlSize(10, 10), stack);

  [flutterPlatformViewsController prerollCompositeEmbeddedView:2
                                                    withParams:std::move(embeddedViewParams)];
  [flutterPlatformViewsController
      compositeView:2
         withParams:[flutterPlatformViewsController compositionParamsForView:2]];

  gMockPlatformView.backgroundColor = UIColor.redColor;
  XCTAssertTrue([gMockPlatformView.superview.superview isKindOfClass:ChildClippingView.class]);
  ChildClippingView* childClippingView = (ChildClippingView*)gMockPlatformView.superview.superview;
  [flutterView addSubview:childClippingView];

  [flutterView setNeedsLayout];
  [flutterView layoutIfNeeded];

  CGPoint corners[] = {CGPointMake(rect.GetLeft(), rect.GetTop()),
                       CGPointMake(rect.GetRight(), rect.GetTop()),
                       CGPointMake(rect.GetLeft(), rect.GetBottom()),
                       CGPointMake(rect.GetRight(), rect.GetBottom())};
  for (auto point : corners) {
    int alpha = [self alphaOfPoint:point onView:flutterView];
    XCTAssertNotEqual(alpha, 255);
  }
  CGPoint center =
      CGPointMake(rect.GetLeft() + rect.GetWidth() / 2, rect.GetTop() + rect.GetHeight() / 2);
  int alpha = [self alphaOfPoint:center onView:flutterView];
  XCTAssertEqual(alpha, 255);
}

@end
