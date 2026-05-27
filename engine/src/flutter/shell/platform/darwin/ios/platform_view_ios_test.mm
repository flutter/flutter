// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "flutter/fml/message_loop.h"
#import "flutter/fml/thread.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSemanticsScrollView.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

FLUTTER_ASSERT_ARC

namespace flutter {

namespace {

class MockDelegate : public PlatformView::Delegate {
 public:
  void OnPlatformViewCreated(std::unique_ptr<Surface> surface) override {}
  void OnPlatformViewDestroyed() override {}
  void OnPlatformViewScheduleFrame() override {}
  void OnPlatformViewAddView(int64_t view_id,
                             const ViewportMetrics& viewport_metrics,
                             AddViewCallback callback) override {}
  void OnPlatformViewRemoveView(int64_t view_id, RemoveViewCallback callback) override {}
  void OnPlatformViewSetNextFrameCallback(const fml::closure& closure) override {}
  void OnPlatformViewSetViewportMetrics(int64_t view_id, const ViewportMetrics& metrics) override {}
  const flutter::Settings& OnPlatformViewGetSettings() const override { return settings_; }
  void OnPlatformViewDispatchPlatformMessage(std::unique_ptr<PlatformMessage> message) override {}
  void OnPlatformViewDispatchPointerDataPacket(std::unique_ptr<PointerDataPacket> packet) override {
  }
  HitTestResponse OnPlatformViewHitTest(int64_t view_id, const flutter::PointData offset) override {
    return {.has_platform_view = false};
  }
  void OnPlatformViewSendViewFocusEvent(const ViewFocusEvent& event) override {}
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

}  // namespace
}  // namespace flutter

@interface PlatformViewIOSTest : XCTestCase
@end

@implementation PlatformViewIOSTest

- (void)testSetSemanticsTreeEnabled {
  flutter::MockDelegate mock_delegate;
  auto thread = std::make_unique<fml::Thread>("PlatformViewIOSTest");
  auto thread_task_runner = thread->GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id engine = OCMClassMock([FlutterEngine class]);

  id flutterViewController = OCMClassMock([FlutterViewController class]);

  OCMStub([flutterViewController isViewLoaded]).andReturn(NO);
  OCMStub([flutterViewController engine]).andReturn(engine);
  OCMStub([engine binaryMessenger]).andReturn(messenger);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&] {
    platform_view->SetOwnerViewController(flutterViewController);
    XCTAssertFalse(platform_view->GetAccessibilityBridge());
    platform_view->SetSemanticsTreeEnabled(true);
    XCTAssertTrue(platform_view->GetAccessibilityBridge());
    platform_view->SetSemanticsTreeEnabled(false);
    XCTAssertFalse(platform_view->GetAccessibilityBridge());
    latch.Signal();
  });
  latch.Wait();

  [engine stopMocking];
}

- (void)testRebindsAccessibilityBridgeAfterOwnerControllerReattaches {
  flutter::MockDelegate mock_delegate;
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto thread_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id engine = OCMClassMock([FlutterEngine class]);

  id firstViewController = OCMClassMock([FlutterViewController class]);
  id secondViewController = OCMClassMock([FlutterViewController class]);
  UIView* firstView = [[UIView alloc] init];
  UIView* secondView = [[UIView alloc] init];

  OCMStub([firstViewController isViewLoaded]).andReturn(YES);
  OCMStub([firstViewController engine]).andReturn(engine);
  OCMStub([firstViewController view]).andReturn(firstView);
  OCMStub([firstViewController viewIfLoaded]).andReturn(firstView);
  OCMStub([secondViewController isViewLoaded]).andReturn(YES);
  OCMStub([secondViewController engine]).andReturn(engine);
  OCMStub([secondViewController view]).andReturn(secondView);
  OCMStub([secondViewController viewIfLoaded]).andReturn(secondView);
  OCMStub([engine binaryMessenger]).andReturn(messenger);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  platform_view->SetOwnerViewController(firstViewController);
  platform_view->SetSemanticsTreeEnabled(true);
  flutter::AccessibilityBridge* bridge = platform_view->GetAccessibilityBridge();
  XCTAssertTrue(bridge != nullptr);
  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.label = "root";
  flutter::SemanticsNodeUpdates update;
  update[kRootNodeId] = root_node;
  platform_view->UpdateSemantics(/*view_id=*/0, std::move(update),
                                 flutter::CustomAccessibilityActionUpdates());
  XCTAssertNotNil(firstView.accessibilityElements);

  platform_view->SetOwnerViewController(nil);
  XCTAssertEqual(platform_view->GetAccessibilityBridge(), bridge);
  XCTAssertNil(firstView.accessibilityElements);

  platform_view->SetOwnerViewController(secondViewController);
  XCTAssertEqual(platform_view->GetAccessibilityBridge(), bridge);
  XCTAssertNotNil(secondView.accessibilityElements);
  platform_view->SetSemanticsTreeEnabled(false);

  [engine stopMocking];
}

- (void)testUpdateSemanticsDoesNotLoadOwnerControllerView {
  flutter::MockDelegate mock_delegate;
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto thread_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id engine = OCMClassMock([FlutterEngine class]);

  id flutterViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([flutterViewController isViewLoaded]).andReturn(NO);
  OCMStub([flutterViewController viewIfLoaded]).andReturn(nil);
  OCMStub([flutterViewController engine]).andReturn(engine);
  OCMReject([flutterViewController view]);
  OCMStub([engine binaryMessenger]).andReturn(messenger);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  platform_view->SetOwnerViewController(flutterViewController);
  platform_view->SetSemanticsTreeEnabled(true);
  XCTAssertTrue(platform_view->GetAccessibilityBridge());

  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.label = "root";
  flutter::SemanticsNodeUpdates update;
  update[kRootNodeId] = root_node;
  platform_view->UpdateSemantics(/*view_id=*/0, std::move(update),
                                 flutter::CustomAccessibilityActionUpdates());
  XCTAssertTrue(platform_view->GetAccessibilityBridge());
  platform_view->SetSemanticsTreeEnabled(false);

  OCMVerifyAll(flutterViewController);
  [engine stopMocking];
}

- (void)testPreservesSemanticsUpdatesWhileOwnerControllerIsDetached {
  flutter::MockDelegate mock_delegate;
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto thread_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id engine = OCMClassMock([FlutterEngine class]);

  id firstViewController = OCMClassMock([FlutterViewController class]);
  id secondViewController = OCMClassMock([FlutterViewController class]);
  UIView* firstView = [[UIView alloc] init];
  UIView* secondView = [[UIView alloc] init];

  OCMStub([firstViewController isViewLoaded]).andReturn(YES);
  OCMStub([firstViewController engine]).andReturn(engine);
  OCMStub([firstViewController view]).andReturn(firstView);
  OCMStub([firstViewController viewIfLoaded]).andReturn(firstView);
  OCMStub([secondViewController isViewLoaded]).andReturn(YES);
  OCMStub([secondViewController engine]).andReturn(engine);
  OCMStub([secondViewController view]).andReturn(secondView);
  OCMStub([secondViewController viewIfLoaded]).andReturn(secondView);
  OCMStub([engine binaryMessenger]).andReturn(messenger);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  platform_view->SetOwnerViewController(firstViewController);
  platform_view->SetSemanticsTreeEnabled(true);
  flutter::AccessibilityBridge* bridge = platform_view->GetAccessibilityBridge();
  XCTAssertTrue(bridge != nullptr);

  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.label = "root";
  flutter::SemanticsNodeUpdates initial_update;
  initial_update[kRootNodeId] = root_node;
  platform_view->UpdateSemantics(/*view_id=*/0, std::move(initial_update),
                                 flutter::CustomAccessibilityActionUpdates());
  XCTAssertNotNil(firstView.accessibilityElements);

  platform_view->SetOwnerViewController(nil);

  flutter::SemanticsNode detached_root_node;
  detached_root_node.id = kRootNodeId;
  detached_root_node.label = "updated while detached";
  flutter::SemanticsNodeUpdates detached_update;
  detached_update[kRootNodeId] = detached_root_node;
  platform_view->UpdateSemantics(/*view_id=*/0, std::move(detached_update),
                                 flutter::CustomAccessibilityActionUpdates());
  XCTAssertEqual(platform_view->GetAccessibilityBridge(), bridge);
  XCTAssertNil(firstView.accessibilityElements);

  platform_view->SetOwnerViewController(secondViewController);
  XCTAssertEqual(platform_view->GetAccessibilityBridge(), bridge);
  XCTAssertNotNil(secondView.accessibilityElements);
  id rootContainer = secondView.accessibilityElements.firstObject;
  id rootElement = [rootContainer accessibilityElementAtIndex:0];
  XCTAssertEqualObjects([rootElement accessibilityLabel], @"updated while detached");
  platform_view->SetSemanticsTreeEnabled(false);

  [engine stopMocking];
}

- (void)testRebindsScrollableSemanticsViewAfterOwnerControllerReattaches {
  flutter::MockDelegate mock_delegate;
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto thread_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id engine = OCMClassMock([FlutterEngine class]);

  id firstViewController = OCMClassMock([FlutterViewController class]);
  id secondViewController = OCMClassMock([FlutterViewController class]);
  UIView* firstView = [[UIView alloc] init];
  UIView* secondView = [[UIView alloc] init];

  OCMStub([firstViewController isViewLoaded]).andReturn(YES);
  OCMStub([firstViewController engine]).andReturn(engine);
  OCMStub([firstViewController view]).andReturn(firstView);
  OCMStub([firstViewController viewIfLoaded]).andReturn(firstView);
  OCMStub([secondViewController isViewLoaded]).andReturn(YES);
  OCMStub([secondViewController engine]).andReturn(engine);
  OCMStub([secondViewController view]).andReturn(secondView);
  OCMStub([secondViewController viewIfLoaded]).andReturn(secondView);
  OCMStub([engine binaryMessenger]).andReturn(messenger);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  platform_view->SetOwnerViewController(firstViewController);
  platform_view->SetSemanticsTreeEnabled(true);

  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.childrenInTraversalOrder = {1};
  root_node.childrenInHitTestOrder = {1};
  flutter::SemanticsNode scrollable_node;
  scrollable_node.id = 1;
  scrollable_node.flags.hasImplicitScrolling = true;
  scrollable_node.actions = flutter::kVerticalScrollSemanticsActions;
  scrollable_node.rect = SkRect::MakeXYWH(0, 0, 100, 120);
  scrollable_node.scrollExtentMax = 100.0;
  scrollable_node.scrollPosition = 10.0;
  flutter::SemanticsNodeUpdates update;
  update[kRootNodeId] = root_node;
  update[scrollable_node.id] = scrollable_node;
  platform_view->UpdateSemantics(/*view_id=*/0, std::move(update),
                                 flutter::CustomAccessibilityActionUpdates());
  XCTAssertEqual(firstView.subviews.count, 1ul);
  FlutterSemanticsScrollView* scrollable_view =
      (FlutterSemanticsScrollView*)firstView.subviews.firstObject;
  XCTAssertTrue([scrollable_view isKindOfClass:[FlutterSemanticsScrollView class]]);
  CGRect expected_frame = scrollable_view.frame;
  CGSize expected_content_size = scrollable_view.contentSize;
  CGPoint expected_content_offset = scrollable_view.contentOffset;

  platform_view->SetOwnerViewController(nil);
  XCTAssertEqual(firstView.subviews.count, 0ul);
  scrollable_view.frame = CGRectMake(1, 2, 3, 4);
  scrollable_view.contentSize = CGSizeMake(5, 6);
  scrollable_view.contentOffset = CGPointMake(7, 8);

  platform_view->SetOwnerViewController(secondViewController);
  XCTAssertEqual(secondView.subviews.count, 1ul);
  XCTAssertEqual(secondView.subviews.firstObject, scrollable_view);
  XCTAssertTrue(CGRectEqualToRect(scrollable_view.frame, expected_frame));
  XCTAssertTrue(CGSizeEqualToSize(scrollable_view.contentSize, expected_content_size));
  XCTAssertTrue(CGPointEqualToPoint(scrollable_view.contentOffset, expected_content_offset));
  platform_view->SetSemanticsTreeEnabled(false);

  [engine stopMocking];
}

- (void)testLocaleCanBeSetWithoutViewController {
  flutter::MockDelegate mock_delegate;
  auto thread = std::make_unique<fml::Thread>("PlatformViewIOSTest");
  auto thread_task_runner = thread->GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id engine = OCMClassMock([FlutterEngine class]);

  id flutterViewController = OCMClassMock([FlutterViewController class]);

  OCMStub([flutterViewController isViewLoaded]).andReturn(NO);
  OCMStub([flutterViewController engine]).andReturn(engine);
  OCMStub([engine binaryMessenger]).andReturn(messenger);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kMetal,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*worker_task_runner=*/nil,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&] {
    std::string locale = "en-US";
    platform_view->SetApplicationLocale(locale);
    platform_view->SetOwnerViewController(flutterViewController);
    OCMVerify([flutterViewController setApplicationLocale:@"en-US"]);
    latch.Signal();
  });
  latch.Wait();

  [engine stopMocking];
}

@end
