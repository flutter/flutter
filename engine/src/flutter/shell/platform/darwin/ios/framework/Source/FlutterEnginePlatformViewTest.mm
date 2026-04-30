// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <vector>
#define FML_USED_ON_EMBEDDER

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#include "flutter/common/constants.h"
#include "flutter/fml/message_loop.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

FLUTTER_ASSERT_ARC

namespace {
constexpr int64_t kSecondaryFlutterViewId = flutter::kFlutterImplicitViewId + 1;
constexpr int64_t kTertiaryFlutterViewId = flutter::kFlutterImplicitViewId + 2;
}  // namespace

namespace flutter {
namespace {

class FakeDelegate : public PlatformView::Delegate {
 public:
  void OnPlatformViewCreated(std::unique_ptr<Surface> surface) override {
    on_platform_view_created_calls_++;
  }
  void OnPlatformViewDestroyed() override { on_platform_view_destroyed_calls_++; }
  void OnPlatformViewScheduleFrame() override {}
  void OnPlatformViewAddView(int64_t view_id,
                             const ViewportMetrics& viewport_metrics,
                             AddViewCallback callback) override {
    added_view_ids_.push_back(view_id);
    callback(true);
  }
  void OnPlatformViewRemoveView(int64_t view_id, RemoveViewCallback callback) override {
    removed_view_ids_.push_back(view_id);
    callback(true);
  }
  void OnPlatformViewSendViewFocusEvent(const ViewFocusEvent& event) override {}
  void OnPlatformViewSetNextFrameCallback(const fml::closure& closure) override {}
  void OnPlatformViewSetViewportMetrics(int64_t view_id, const ViewportMetrics& metrics) override {
    viewport_metrics_calls_++;
    last_viewport_metrics_view_id_ = view_id;
  }
  const flutter::Settings& OnPlatformViewGetSettings() const override { return settings_; }
  void OnPlatformViewDispatchPlatformMessage(std::unique_ptr<PlatformMessage> message) override {}
  void OnPlatformViewDispatchPointerDataPacket(std::unique_ptr<PointerDataPacket> packet) override {
  }
  HitTestResponse OnPlatformViewHitTest(int64_t view_id, const flutter::PointData offset) override {
    return {.has_platform_view = false};
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
  void UpdateAssetResolverByType(std::unique_ptr<AssetResolver> updated_asset_resolver,
                                 AssetResolver::AssetResolverType type) override {}

  flutter::Settings settings_;
  int on_platform_view_created_calls_ = 0;
  int on_platform_view_destroyed_calls_ = 0;
  std::vector<int64_t> added_view_ids_;
  std::vector<int64_t> removed_view_ids_;
  int viewport_metrics_calls_ = 0;
  int64_t last_viewport_metrics_view_id_ = -1;
};

}  // namespace
}  // namespace flutter

@interface FlutterEnginePlatformViewTest : XCTestCase
@end

@implementation FlutterEnginePlatformViewTest
std::unique_ptr<flutter::PlatformViewIOS> platform_view;
std::unique_ptr<fml::WeakPtrFactory<flutter::PlatformView>> weak_factory;
flutter::FakeDelegate fake_delegate;

- (void)setUp {
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  fake_delegate.on_platform_view_created_calls_ = 0;
  fake_delegate.on_platform_view_destroyed_calls_ = 0;
  fake_delegate.added_view_ids_.clear();
  fake_delegate.removed_view_ids_.clear();
  fake_delegate.viewport_metrics_calls_ = 0;
  fake_delegate.last_viewport_metrics_view_id_ = -1;
  auto thread_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  auto sync_switch = std::make_shared<fml::SyncSwitch>();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/fake_delegate,
      /*rendering_api=*/fake_delegate.settings_.enable_impeller
          ? flutter::IOSRenderingAPI::kMetal
          : flutter::IOSRenderingAPI::kSoftware,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_sync_switch=*/sync_switch);
  weak_factory = std::make_unique<fml::WeakPtrFactory<flutter::PlatformView>>(platform_view.get());
}

- (void)tearDown {
  weak_factory.reset();
  platform_view.reset();
}

- (fml::WeakPtr<flutter::PlatformView>)platformViewReplacement {
  return weak_factory->GetWeakPtr();
}

- (void)testCallsNotifyLowMemory {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  XCTAssertNotNil(engine);
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine notifyLowMemory]);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine setViewController:nil];
  OCMVerify([mockEngine notifyLowMemory]);
  OCMReject([mockEngine notifyLowMemory]);

  XCTNSNotificationExpectation* memoryExpectation = [[XCTNSNotificationExpectation alloc]
      initWithName:UIApplicationDidReceiveMemoryWarningNotification];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidReceiveMemoryWarningNotification
                    object:nil];
  [self waitForExpectations:@[ memoryExpectation ] timeout:5.0];
  OCMVerify([mockEngine notifyLowMemory]);
  OCMReject([mockEngine notifyLowMemory]);

  XCTNSNotificationExpectation* backgroundExpectation = [[XCTNSNotificationExpectation alloc]
      initWithName:UIApplicationDidEnterBackgroundNotification];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:nil];
  [self waitForExpectations:@[ backgroundExpectation ] timeout:5.0];

  OCMVerify([mockEngine notifyLowMemory]);
}

- (void)testSetViewControllerNilDestroysImplicitSurface {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  XCTAssertNotNil(engine);
  id mockEngine = OCMPartialMock(engine);
  id flutterViewController = OCMClassMock([FlutterViewController class]);
  UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

  OCMStub([mockEngine platformView]).andReturn(platform_view.get());
  OCMStub([flutterViewController isViewLoaded]).andReturn(YES);
  OCMStub([flutterViewController view]).andReturn(view);
  OCMStub([flutterViewController viewIdentifier]).andReturn(flutter::kFlutterImplicitViewId);
  OCMStub([flutterViewController setupViewIdentifier:flutter::kFlutterImplicitViewId]);

  [engine setViewController:flutterViewController];
  XCTAssertEqual(engine.viewController, flutterViewController);

  platform_view->NotifyCreated(flutter::kFlutterImplicitViewId);
  XCTAssertEqual(fake_delegate.on_platform_view_created_calls_, 1);

  [engine setViewController:nil];
  XCTAssertNil(engine.viewController);
  XCTAssertNil(platform_view->GetOwnerViewController());
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 1);

  [flutterViewController stopMocking];
}

- (void)testSetViewControllerNilRemovesImplicitMapping {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  XCTAssertNotNil(engine);
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                nibName:nil
                                                                                 bundle:nil];

  XCTAssertEqual(engine.viewController, viewController);
  XCTAssertEqual([engine viewControllerForIdentifier:flutter::kFlutterImplicitViewId],
                 viewController);

  [engine setViewController:nil];

  XCTAssertNil(engine.viewController);
  XCTAssertNil([engine viewControllerForIdentifier:flutter::kFlutterImplicitViewId]);
  XCTAssertNil(platform_view->GetOwnerViewController());
}

- (void)testEnableMultiViewAssignsIncrementingIdentifiersAndLookup {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine enableMultiView];

  FlutterViewController* implicitViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* tertiaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];

  XCTAssertEqual(implicitViewController.viewIdentifier, flutter::kFlutterImplicitViewId);
  XCTAssertEqual(secondaryViewController.viewIdentifier, kSecondaryFlutterViewId);
  XCTAssertEqual(tertiaryViewController.viewIdentifier, kTertiaryFlutterViewId);

  XCTAssertEqual(engine.viewController, implicitViewController);
  XCTAssertEqual([engine viewControllerForIdentifier:flutter::kFlutterImplicitViewId],
                 implicitViewController);
  XCTAssertEqual([engine viewControllerForIdentifier:kSecondaryFlutterViewId],
                 secondaryViewController);
  XCTAssertEqual([engine viewControllerForIdentifier:kTertiaryFlutterViewId],
                 tertiaryViewController);

  XCTAssertEqual(fake_delegate.added_view_ids_.size(), 2UL);
  XCTAssertEqual(fake_delegate.added_view_ids_[0], kSecondaryFlutterViewId);
  XCTAssertEqual(fake_delegate.added_view_ids_[1], kTertiaryFlutterViewId);
}

- (void)testRemovingImplicitViewInMultiViewDoesNotReuseIdentifier {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine enableMultiView];

  FlutterViewController* implicitViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  XCTAssertEqual(secondaryViewController.viewIdentifier, kSecondaryFlutterViewId);

  [engine removeViewController:implicitViewController.viewIdentifier];
  XCTAssertNil([engine viewControllerForIdentifier:flutter::kFlutterImplicitViewId]);

  FlutterViewController* tertiaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  XCTAssertEqual(tertiaryViewController.viewIdentifier, kTertiaryFlutterViewId);
}

- (void)testNotifyDestroyedOnlyDestroysPlatformViewWhenLastViewIsRemoved {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine enableMultiView];

  FlutterViewController* implicitViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];

  [implicitViewController loadViewIfNeeded];
  [secondaryViewController loadViewIfNeeded];

  platform_view->NotifyCreated(flutter::kFlutterImplicitViewId);
  platform_view->NotifyCreated(kSecondaryFlutterViewId);
  XCTAssertTrue(platform_view->HasRenderingSurface(flutter::kFlutterImplicitViewId));
  XCTAssertTrue(platform_view->HasRenderingSurface(kSecondaryFlutterViewId));
  XCTAssertEqual(fake_delegate.on_platform_view_created_calls_, 1);

  platform_view->NotifyDestroyed(kSecondaryFlutterViewId);
  XCTAssertTrue(platform_view->HasRenderingSurface(flutter::kFlutterImplicitViewId));
  XCTAssertFalse(platform_view->HasRenderingSurface(kSecondaryFlutterViewId));
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 0);

  platform_view->NotifyDestroyed(flutter::kFlutterImplicitViewId);
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 1);
}

- (void)testRemovingSecondaryViewControllerKeepsOtherControllerMappings {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine enableMultiView];

  FlutterViewController* implicitViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* tertiaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];

  [engine removeViewController:secondaryViewController.viewIdentifier];

  XCTAssertEqual([engine viewControllerForIdentifier:flutter::kFlutterImplicitViewId],
                 implicitViewController);
  XCTAssertNil([engine viewControllerForIdentifier:secondaryViewController.viewIdentifier]);
  XCTAssertEqual([engine viewControllerForIdentifier:tertiaryViewController.viewIdentifier],
                 tertiaryViewController);
  XCTAssertEqual(fake_delegate.removed_view_ids_.size(), 1UL);
  XCTAssertEqual(fake_delegate.removed_view_ids_[0], secondaryViewController.viewIdentifier);
}

- (void)testUpdateViewportMetricsOnlyRoutesToRegisteredViewIdentifiers {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine enableMultiView];

  FlutterViewController* implicitViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  XCTAssertEqual(implicitViewController.viewIdentifier, flutter::kFlutterImplicitViewId);

  flutter::ViewportMetrics metrics = {};
  metrics.physical_width = 320;
  metrics.physical_height = 480;

  [engine updateViewportMetrics:metrics viewIdentifier:secondaryViewController.viewIdentifier];
  XCTAssertEqual(fake_delegate.viewport_metrics_calls_, 1);
  XCTAssertEqual(fake_delegate.last_viewport_metrics_view_id_,
                 secondaryViewController.viewIdentifier);

  const FlutterViewIdentifier unregisteredFlutterViewId =
      secondaryViewController.viewIdentifier + 1;
  [engine updateViewportMetrics:metrics viewIdentifier:unregisteredFlutterViewId];
  XCTAssertEqual(fake_delegate.viewport_metrics_calls_, 1);
}

@end
