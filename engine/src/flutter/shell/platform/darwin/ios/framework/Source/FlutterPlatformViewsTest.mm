// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterPlatformViews.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#import "third_party/ocmock/Source/OCMock/OCMock.h"

FLUTTER_ASSERT_NOT_ARC
@class FlutterPlatformViewsTestMockPlatformView;
static FlutterPlatformViewsTestMockPlatformView* gMockPlatformView = nil;

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
  [super dealloc];
}

@end

@interface FlutterPlatformViewsTestMockFlutterPlatformView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) UIView* view;
@end

@implementation FlutterPlatformViewsTestMockFlutterPlatformView

- (instancetype)init {
  if (self = [super init]) {
    _view = [[FlutterPlatformViewsTestMockPlatformView alloc] init];
  }
  return self;
}

- (void)dealloc {
  [_view release];
  _view = nil;
  [super dealloc];
}

@end

@interface FlutterPlatformViewsTestMockFlutterPlatformFactory
    : NSObject <FlutterPlatformViewFactory>
@end

@implementation FlutterPlatformViewsTestMockFlutterPlatformFactory
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  return [[[FlutterPlatformViewsTestMockFlutterPlatformView alloc] init] autorelease];
}

@end

namespace flutter {
namespace {
class FlutterPlatformViewsTestMockPlatformViewDelegate : public PlatformView::Delegate {
  void OnPlatformViewCreated(std::unique_ptr<Surface> surface) override {}
  void OnPlatformViewDestroyed() override {}
  void OnPlatformViewSetNextFrameCallback(const fml::closure& closure) override {}
  void OnPlatformViewSetViewportMetrics(const ViewportMetrics& metrics) override {}
  void OnPlatformViewDispatchPlatformMessage(fml::RefPtr<PlatformMessage> message) override {}
  void OnPlatformViewDispatchPointerDataPacket(std::unique_ptr<PointerDataPacket> packet) override {
  }
  void OnPlatformViewDispatchSemanticsAction(int32_t id,
                                             SemanticsAction action,
                                             std::vector<uint8_t> args) override {}
  void OnPlatformViewSetSemanticsEnabled(bool enabled) override {}
  void OnPlatformViewSetAccessibilityFeatures(int32_t flags) override {}
  void OnPlatformViewRegisterTexture(std::shared_ptr<Texture> texture) override {}
  void OnPlatformViewUnregisterTexture(int64_t texture_id) override {}
  void OnPlatformViewMarkTextureFrameAvailable(int64_t texture_id) override {}

  std::unique_ptr<std::vector<std::string>> ComputePlatformViewResolvedLocale(
      const std::vector<std::string>& supported_locale_data) override {
    std::unique_ptr<std::vector<std::string>> out = std::make_unique<std::vector<std::string>>();
    return out;
  }
};

}  // namespace
}  // namespace flutter

namespace {
fml::RefPtr<fml::TaskRunner> CreateNewThread(std::string name) {
  auto thread = std::make_unique<fml::Thread>(name);
  auto runner = thread->GetTaskRunner();
  return runner;
}
}  // namespace

@interface FlutterPlatformViewsTest : XCTestCase
@end

@implementation FlutterPlatformViewsTest

- (void)testCanCreatePlatformViewWithoutFlutterView {
  flutter::FlutterPlatformViewsTestMockPlatformViewDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("FlutterPlatformViewsTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);

  auto flutterPlatformViewsController = std::make_unique<flutter::FlutterPlatformViewsController>();

  FlutterPlatformViewsTestMockFlutterPlatformFactory* factory =
      [[FlutterPlatformViewsTestMockFlutterPlatformFactory new] autorelease];
  flutterPlatformViewsController->RegisterViewFactory(
      factory, @"MockFlutterPlatformView",
      FlutterPlatformViewGestureRecognizersBlockingPolicyEager);
  FlutterResult result = ^(id result) {
  };
  flutterPlatformViewsController->OnMethodCall(
      [FlutterMethodCall
          methodCallWithMethodName:@"create"
                         arguments:@{@"id" : @2, @"viewType" : @"MockFlutterPlatformView"}],
      result);

  XCTAssertNotNil(gMockPlatformView);

  flutterPlatformViewsController->Reset();
}

@end
