// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <QuartzCore/QuartzCore.h>
#import <XCTest/XCTest.h>

#include "flutter/common/constants.h"
#import "flutter/fml/thread.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterBinaryMessenger.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViewsController.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterRestorationPlugin.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

FLUTTER_ASSERT_ARC

namespace {
constexpr int64_t kSecondaryFlutterViewId = flutter::kFlutterImplicitViewId + 1;

FlutterViewController* CreateMockViewController(int64_t view_id, CALayer* layer) {
  id flutter_view = OCMClassMock([FlutterView class]);
  OCMStub([flutter_view layer]).andReturn(layer);
  id controller = OCMClassMock([FlutterViewController class]);
  OCMStub([controller isViewLoaded]).andReturn(YES);
  OCMStub([controller view]).andReturn(flutter_view);
  OCMStub([controller viewIdentifier]).andReturn(view_id);
  return controller;
}
}  // namespace

namespace flutter {

namespace {

class MockDelegate : public PlatformView::Delegate {
 public:
  void OnPlatformViewCreated(std::unique_ptr<Surface> surface) override {
    on_platform_view_created_calls_++;
    surface_ = std::move(surface);
  }
  void OnPlatformViewDestroyed() override {
    on_platform_view_destroyed_calls_++;
    surface_.reset();
  }
  void OnPlatformViewScheduleFrame() override { on_platform_view_schedule_frame_calls_++; }
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
  std::shared_ptr<fml::BasicTaskRunner> OnPlatformViewGetShutdownSafeIOTaskRunner() const override {
    return nullptr;
  }

  flutter::Settings settings_;
  int on_platform_view_created_calls_ = 0;
  int on_platform_view_destroyed_calls_ = 0;
  int on_platform_view_schedule_frame_calls_ = 0;
  std::unique_ptr<Surface> surface_;
};

class InvalidIOSContext : public IOSContext {
 public:

  std::unique_ptr<Texture> CreateExternalTexture(int64_t texture_id,
                                                 NSObject<FlutterTexture>* texture) override {
    return nullptr;
  }
};

}  // namespace
}  // namespace flutter

@interface AccessibilityCountingBinaryMessenger : NSObject <FlutterBinaryMessenger>
@property(nonatomic, assign) NSInteger accessibilityHandlerRegistrationCount;
@end

@implementation AccessibilityCountingBinaryMessenger {
  FlutterBinaryMessengerConnection _nextConnection;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _nextConnection = 1;
  }
  return self;
}

- (void)sendOnChannel:(NSString*)channel message:(NSData* _Nullable)message {
}

- (void)sendOnChannel:(NSString*)channel
              message:(NSData* _Nullable)message
          binaryReply:(FlutterBinaryReply _Nullable)callback {
}

- (FlutterBinaryMessengerConnection)setMessageHandlerOnChannel:(NSString*)channel
                                          binaryMessageHandler:
                                              (FlutterBinaryMessageHandler _Nullable)handler {
  if ([channel isEqualToString:@"flutter/accessibility"] && handler != nil) {
    self.accessibilityHandlerRegistrationCount++;
  }
  return _nextConnection++;
}

- (void)cleanUpConnection:(FlutterBinaryMessengerConnection)connection {
}

@end

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
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
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

- (void)testNotifyCreatedAndDestroyedNotifiesDelegateOnlyForFirstAndLastView {
  flutter::MockDelegate mock_delegate;
  auto thread = std::make_unique<fml::Thread>("PlatformViewIOSTest");
  auto thread_task_runner = thread->GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);

  id implicitFlutterView = OCMClassMock([FlutterView class]);
  CALayer* implicitLayer = [CALayer layer];
  OCMStub([implicitFlutterView layer]).andReturn(implicitLayer);
  id implicitViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([implicitViewController isViewLoaded]).andReturn(YES);
  OCMStub([implicitViewController view]).andReturn(implicitFlutterView);
  OCMStub([implicitViewController viewIdentifier]).andReturn(flutter::kFlutterImplicitViewId);

  id secondaryFlutterView = OCMClassMock([FlutterView class]);
  CALayer* secondaryLayer = [CALayer layer];
  OCMStub([secondaryFlutterView layer]).andReturn(secondaryLayer);
  id secondaryViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([secondaryViewController isViewLoaded]).andReturn(YES);
  OCMStub([secondaryViewController view]).andReturn(secondaryFlutterView);
  OCMStub([secondaryViewController viewIdentifier]).andReturn(kSecondaryFlutterViewId);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&] {
    platform_view->SetOwnerViewController(implicitViewController);
    platform_view->AddOwnerViewController(secondaryViewController);

    platform_view->NotifyViewRenderingSurfaceCreated(flutter::kFlutterImplicitViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 1);

    platform_view->NotifyViewRenderingSurfaceCreated(flutter::kFlutterImplicitViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 1);
    XCTAssertEqual(mock_delegate.on_platform_view_schedule_frame_calls_, 0);

    platform_view->NotifyViewRenderingSurfaceCreated(kSecondaryFlutterViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 1);
    XCTAssertEqual(mock_delegate.on_platform_view_schedule_frame_calls_, 1);

    platform_view->NotifyViewRenderingSurfaceDestroyed(kSecondaryFlutterViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 0);

    platform_view->NotifyViewRenderingSurfaceDestroyed(kSecondaryFlutterViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 0);

    platform_view->NotifyViewRenderingSurfaceCreated(kSecondaryFlutterViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 1);
    XCTAssertEqual(mock_delegate.on_platform_view_schedule_frame_calls_, 2);

    platform_view->RemoveOwnerViewController(kSecondaryFlutterViewId);
    XCTAssertEqual(platform_view->GetOwnerViewController(), implicitViewController);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 0);

    platform_view->NotifyViewRenderingSurfaceDestroyed(flutter::kFlutterImplicitViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 1);

    platform_view->NotifyViewRenderingSurfaceDestroyed(flutter::kFlutterImplicitViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 1);

    platform_view->NotifyViewRenderingSurfaceCreated(flutter::kFlutterImplicitViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 2);

    platform_view->RemoveOwnerViewController(flutter::kFlutterImplicitViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 2);
    latch.Signal();
  });
  latch.Wait();
}

- (void)testSurfaceCreationCanRetryAfterViewAttachment {
  flutter::MockDelegate mock_delegate;
  fml::Thread platform_thread("PlatformViewIOSTest.platform");
  fml::Thread raster_thread("PlatformViewIOSTest.raster");
  auto platform_runner = platform_thread.GetTaskRunner();
  flutter::TaskRunners runners(self.name.UTF8String, platform_runner, raster_thread.GetTaskRunner(),
                               platform_runner, platform_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      mock_delegate, nil, runners, std::make_shared<fml::SyncSwitch>());
  FlutterViewController* controller =
      CreateMockViewController(flutter::kFlutterImplicitViewId, [CAMetalLayer layer]);

  fml::AutoResetWaitableEvent latch;
  platform_runner->PostTask([&] {
    platform_view->NotifyViewRenderingSurfaceCreated(flutter::kFlutterImplicitViewId);
    platform_view->NotifyViewRenderingSurfaceDestroyed(flutter::kFlutterImplicitViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 0);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 0);

    platform_view->SetOwnerViewController(controller);
    platform_view->NotifyViewRenderingSurfaceCreated(flutter::kFlutterImplicitViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 1);
    XCTAssertTrue(mock_delegate.surface_ && mock_delegate.surface_->IsValid());

    platform_view->NotifyViewRenderingSurfaceCreated(kSecondaryFlutterViewId);
    platform_view->NotifyViewRenderingSurfaceDestroyed(kSecondaryFlutterViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 1);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 0);
    XCTAssertEqual(mock_delegate.on_platform_view_schedule_frame_calls_, 0);

    platform_view->SetOwnerViewController(nil);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 1);
    latch.Signal();
  });
  latch.Wait();
}

- (void)testInvalidContextDoesNotActivateRenderingSurface {
  flutter::MockDelegate mock_delegate;
  fml::Thread thread("PlatformViewIOSTest");
  auto runner = thread.GetTaskRunner();
  flutter::TaskRunners runners(self.name.UTF8String, runner, runner, runner, runner);
  auto context = std::make_shared<flutter::InvalidIOSContext>();
  auto platform_view =
      std::make_unique<flutter::PlatformViewIOS>(mock_delegate, context, nil, runners);
  FlutterViewController* controller =
      CreateMockViewController(flutter::kFlutterImplicitViewId, [CAMetalLayer layer]);

  fml::AutoResetWaitableEvent latch;
  runner->PostTask([&] {
    platform_view->SetOwnerViewController(controller);
    platform_view->NotifyViewRenderingSurfaceCreated(flutter::kFlutterImplicitViewId);
    platform_view->NotifyViewRenderingSurfaceCreated(flutter::kFlutterImplicitViewId);
    platform_view->RemoveOwnerViewController(flutter::kFlutterImplicitViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 0);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 0);
    XCTAssertEqual(mock_delegate.on_platform_view_schedule_frame_calls_, 0);
    latch.Signal();
  });
  latch.Wait();
}

- (void)testRootSurfaceSurvivesRemovalOfFirstView {
  flutter::MockDelegate mock_delegate;
  fml::Thread thread("PlatformViewIOSTest");
  auto runner = thread.GetTaskRunner();
  flutter::TaskRunners runners(self.name.UTF8String, runner, runner, runner, runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      mock_delegate, nil, runners, std::make_shared<fml::SyncSwitch>());
  FlutterViewController* secondary_controller =
      CreateMockViewController(kSecondaryFlutterViewId, [CAMetalLayer layer]);

  fml::AutoResetWaitableEvent latch;
  runner->PostTask([&] {
    __weak CALayer* first_layer;
    @autoreleasepool {
      CALayer* layer = [CAMetalLayer layer];
      first_layer = layer;
      id controller = CreateMockViewController(flutter::kFlutterImplicitViewId, layer);
      platform_view->SetOwnerViewController(controller);
      platform_view->NotifyViewRenderingSurfaceCreated(flutter::kFlutterImplicitViewId);
      platform_view->AddOwnerViewController(secondary_controller);
      platform_view->NotifyViewRenderingSurfaceCreated(kSecondaryFlutterViewId);

      platform_view->RemoveOwnerViewController(flutter::kFlutterImplicitViewId);
      [controller stopMocking];
    }
    XCTAssertNil(first_layer);
    XCTAssertEqual(mock_delegate.on_platform_view_created_calls_, 1);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 0);
    XCTAssertTrue(mock_delegate.surface_ != nullptr);
    if (mock_delegate.surface_) {
      XCTAssertFalse(mock_delegate.surface_->AllowsDrawingWhenGpuDisabled());
      XCTAssertEqual(mock_delegate.surface_->GetAiksContext().get(),
                     platform_view->GetIosContext()->GetAiksContext().get());
      auto frame = mock_delegate.surface_->AcquireFrame(flutter::DlISize(10, 10));
      XCTAssertTrue(frame != nullptr);
      if (frame) {
        XCTAssertTrue(frame->Submit());
      }
    }

    platform_view->RemoveOwnerViewController(kSecondaryFlutterViewId);
    XCTAssertEqual(mock_delegate.on_platform_view_destroyed_calls_, 1);
    latch.Signal();
  });
  latch.Wait();
}

- (void)testSetSemanticsTreeEnabledCreatesAccessibilityBridgesForAllControllers {
  flutter::MockDelegate mock_delegate;
  auto thread = std::make_unique<fml::Thread>("PlatformViewIOSTest");
  auto thread_task_runner = thread->GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);

  AccessibilityCountingBinaryMessenger* messenger =
      [[AccessibilityCountingBinaryMessenger alloc] init];
  id sharedEngine = OCMClassMock([FlutterEngine class]);
  OCMStub([sharedEngine binaryMessenger]).andReturn(messenger);
  id implicitViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([implicitViewController isViewLoaded]).andReturn(NO);
  OCMStub([implicitViewController engine]).andReturn(sharedEngine);
  OCMStub([implicitViewController viewIdentifier]).andReturn(flutter::kFlutterImplicitViewId);

  id secondaryViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([secondaryViewController isViewLoaded]).andReturn(NO);
  OCMStub([secondaryViewController engine]).andReturn(sharedEngine);
  OCMStub([secondaryViewController viewIdentifier]).andReturn(kSecondaryFlutterViewId);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&] {
    platform_view->SetOwnerViewController(implicitViewController);
    platform_view->AddOwnerViewController(secondaryViewController);
    XCTAssertFalse(platform_view->GetAccessibilityBridge());
    XCTAssertFalse(platform_view->GetAccessibilityBridge(kSecondaryFlutterViewId));
    platform_view->SetSemanticsTreeEnabled(true);
    XCTAssertTrue(platform_view->GetAccessibilityBridge());
    XCTAssertTrue(platform_view->GetAccessibilityBridge(kSecondaryFlutterViewId));
    platform_view->SetSemanticsTreeEnabled(false);
    XCTAssertFalse(platform_view->GetAccessibilityBridge());
    XCTAssertFalse(platform_view->GetAccessibilityBridge(kSecondaryFlutterViewId));
    latch.Signal();
  });
  latch.Wait();

  XCTAssertEqual(messenger.accessibilityHandlerRegistrationCount, 0);
  [sharedEngine stopMocking];
}

- (void)testAddingSecondaryControllerAfterSemanticsEnabledCreatesAccessibilityBridge {
  flutter::MockDelegate mock_delegate;
  auto thread = std::make_unique<fml::Thread>("PlatformViewIOSTest");
  auto thread_task_runner = thread->GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);

  AccessibilityCountingBinaryMessenger* messenger =
      [[AccessibilityCountingBinaryMessenger alloc] init];
  id sharedEngine = OCMClassMock([FlutterEngine class]);
  OCMStub([sharedEngine binaryMessenger]).andReturn(messenger);
  id implicitViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([implicitViewController isViewLoaded]).andReturn(NO);
  OCMStub([implicitViewController engine]).andReturn(sharedEngine);
  OCMStub([implicitViewController viewIdentifier]).andReturn(flutter::kFlutterImplicitViewId);

  id secondaryViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([secondaryViewController isViewLoaded]).andReturn(NO);
  OCMStub([secondaryViewController engine]).andReturn(sharedEngine);
  OCMStub([secondaryViewController viewIdentifier]).andReturn(kSecondaryFlutterViewId);

  std::unique_ptr<flutter::PlatformViewIOS> platform_view;
  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&] {
    platform_view = std::make_unique<flutter::PlatformViewIOS>(
        /*delegate=*/mock_delegate,
        /*platform_views_controller=*/nil,
        /*task_runners=*/runners,
        /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
    platform_view->SetOwnerViewController(implicitViewController);
    platform_view->SetSemanticsTreeEnabled(true);
    platform_view->AddOwnerViewController(secondaryViewController);
    XCTAssertTrue(platform_view->GetAccessibilityBridge(kSecondaryFlutterViewId));
    latch.Signal();
  });
  latch.Wait();

  XCTAssertEqual(messenger.accessibilityHandlerRegistrationCount, 0);
  fml::AutoResetWaitableEvent teardown_latch;
  thread_task_runner->PostTask([&] {
    platform_view.reset();
    teardown_latch.Signal();
  });
  teardown_latch.Wait();
  [sharedEngine stopMocking];
}

- (void)testOnPreEngineRestartResetsAllRegisteredControllers {
  flutter::MockDelegate mock_delegate;
  auto thread = std::make_unique<fml::Thread>("PlatformViewIOSTest");
  auto thread_task_runner = thread->GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);

  id implicitPlatformViewsController = OCMClassMock([FlutterPlatformViewsController class]);
  id implicitRestorationPlugin = OCMClassMock([FlutterRestorationPlugin class]);
  id implicitTextInputPlugin = OCMClassMock([FlutterTextInputPlugin class]);
  id implicitViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([implicitViewController isViewLoaded]).andReturn(NO);
  OCMStub([implicitViewController viewIdentifier]).andReturn(flutter::kFlutterImplicitViewId);
  OCMStub([implicitViewController platformViewsController])
      .andReturn(implicitPlatformViewsController);
  OCMStub([implicitViewController restorationPlugin]).andReturn(implicitRestorationPlugin);
  OCMStub([implicitViewController textInputPlugin]).andReturn(implicitTextInputPlugin);

  id secondaryPlatformViewsController = OCMClassMock([FlutterPlatformViewsController class]);
  id secondaryRestorationPlugin = OCMClassMock([FlutterRestorationPlugin class]);
  id secondaryTextInputPlugin = OCMClassMock([FlutterTextInputPlugin class]);
  id secondaryViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([secondaryViewController isViewLoaded]).andReturn(NO);
  OCMStub([secondaryViewController viewIdentifier]).andReturn(kSecondaryFlutterViewId);
  OCMStub([secondaryViewController platformViewsController])
      .andReturn(secondaryPlatformViewsController);
  OCMStub([secondaryViewController restorationPlugin]).andReturn(secondaryRestorationPlugin);
  OCMStub([secondaryViewController textInputPlugin]).andReturn(secondaryTextInputPlugin);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&] {
    platform_view->SetOwnerViewController(implicitViewController);
    platform_view->AddOwnerViewController(secondaryViewController);
    platform_view->OnPreEngineRestart();
    latch.Signal();
  });
  latch.Wait();

  OCMVerify([implicitPlatformViewsController reset]);
  OCMVerify([implicitRestorationPlugin reset]);
  OCMVerify([implicitTextInputPlugin reset]);
  OCMVerify([secondaryPlatformViewsController reset]);
  OCMVerify([secondaryRestorationPlugin reset]);
  OCMVerify([secondaryTextInputPlugin reset]);
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

  id implicitViewController = OCMClassMock([FlutterViewController class]);
  id explicitViewController = OCMClassMock([FlutterViewController class]);
  OCMStub([implicitViewController viewIdentifier]).andReturn(flutter::kFlutterImplicitViewId);
  OCMStub([explicitViewController viewIdentifier]).andReturn(kSecondaryFlutterViewId);
  for (id controller in @[ implicitViewController, explicitViewController ]) {
    OCMStub([controller isViewLoaded]).andReturn(NO);
    OCMStub([controller engine]).andReturn(engine);
  }
  OCMStub([engine binaryMessenger]).andReturn(messenger);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&] {
    std::string locale = "en-US";
    platform_view->SetApplicationLocale(locale);
    platform_view->AddOwnerViewController(explicitViewController);
    OCMVerify([explicitViewController setApplicationLocale:@"en-US"]);

    platform_view->SetOwnerViewController(implicitViewController);
    OCMVerify(times(1), [implicitViewController setApplicationLocale:@"en-US"]);
    OCMVerify(times(1), [explicitViewController setApplicationLocale:@"en-US"]);

    platform_view->SetApplicationLocale("fr-FR");
    OCMVerify([implicitViewController setApplicationLocale:@"fr-FR"]);
    OCMVerify([explicitViewController setApplicationLocale:@"fr-FR"]);
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
  FlutterView* firstView = [[FlutterView alloc] initWithDelegate:engine
                                                          opaque:YES
                                                 enableWideGamut:NO];
  FlutterView* secondView = [[FlutterView alloc] initWithDelegate:engine
                                                           opaque:YES
                                                  enableWideGamut:NO];

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
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
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

- (void)testSwappingOwnerControllersPreservesAccessibilityElementsInstalledByNewOwner {
  flutter::MockDelegate first_delegate;
  flutter::MockDelegate second_delegate;
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  auto thread_task_runner = fml::MessageLoop::GetCurrent().GetTaskRunner();
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  id firstMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id secondMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  id firstEngine = OCMClassMock([FlutterEngine class]);
  id secondEngine = OCMClassMock([FlutterEngine class]);
  OCMStub([firstEngine binaryMessenger]).andReturn(firstMessenger);
  OCMStub([secondEngine binaryMessenger]).andReturn(secondMessenger);

  id firstViewController = OCMClassMock([FlutterViewController class]);
  id secondViewController = OCMClassMock([FlutterViewController class]);
  FlutterView* firstView = [[FlutterView alloc] initWithDelegate:firstEngine
                                                          opaque:YES
                                                 enableWideGamut:NO];
  FlutterView* secondView = [[FlutterView alloc] initWithDelegate:secondEngine
                                                           opaque:YES
                                                  enableWideGamut:NO];
  OCMStub([firstViewController isViewLoaded]).andReturn(YES);
  OCMStub([firstViewController engine]).andReturn(firstEngine);
  OCMStub([firstViewController view]).andReturn(firstView);
  OCMStub([firstViewController viewIfLoaded]).andReturn(firstView);
  OCMStub([secondViewController isViewLoaded]).andReturn(YES);
  OCMStub([secondViewController engine]).andReturn(secondEngine);
  OCMStub([secondViewController view]).andReturn(secondView);
  OCMStub([secondViewController viewIfLoaded]).andReturn(secondView);

  auto first_platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/first_delegate,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  auto second_platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/second_delegate,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());

  first_platform_view->SetOwnerViewController(firstViewController);
  first_platform_view->SetSemanticsTreeEnabled(true);
  flutter::AccessibilityBridge* first_bridge = first_platform_view->GetAccessibilityBridge();
  flutter::SemanticsNode first_root;
  first_root.id = kRootNodeId;
  flutter::SemanticsNodeUpdates first_update;
  first_update[kRootNodeId] = first_root;
  first_platform_view->UpdateSemantics(/*view_id=*/0, std::move(first_update),
                                       flutter::CustomAccessibilityActionUpdates());

  second_platform_view->SetOwnerViewController(secondViewController);
  second_platform_view->SetSemanticsTreeEnabled(true);
  flutter::AccessibilityBridge* second_bridge = second_platform_view->GetAccessibilityBridge();
  flutter::SemanticsNode second_root;
  second_root.id = kRootNodeId;
  flutter::SemanticsNodeUpdates second_update;
  second_update[kRootNodeId] = second_root;
  second_platform_view->UpdateSemantics(/*view_id=*/0, std::move(second_update),
                                        flutter::CustomAccessibilityActionUpdates());

  first_platform_view->SetOwnerViewController(secondViewController);
  SemanticsObjectContainer* secondViewRoot = secondView.accessibilityElements.firstObject;
  XCTAssertEqual(secondViewRoot.semanticsObject.bridge, first_bridge);

  second_platform_view->SetOwnerViewController(firstViewController);
  SemanticsObjectContainer* firstViewRoot = firstView.accessibilityElements.firstObject;
  secondViewRoot = secondView.accessibilityElements.firstObject;
  XCTAssertEqual(firstViewRoot.semanticsObject.bridge, second_bridge);
  XCTAssertEqual(secondViewRoot.semanticsObject.bridge, first_bridge);

  first_platform_view->SetSemanticsTreeEnabled(false);
  second_platform_view->SetSemanticsTreeEnabled(false);
  [firstEngine stopMocking];
  [secondEngine stopMocking];
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
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
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

- (void)testAttachViewAppliesSemanticsUpdatesReceivedBeforeViewLoaded {
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
  FlutterView* flutterView = [[FlutterView alloc] initWithDelegate:engine
                                                            opaque:YES
                                                   enableWideGamut:NO];
  __block BOOL isViewLoaded = NO;
  __block UIView* viewIfLoaded = nil;
  OCMStub([flutterViewController isViewLoaded]).andDo(^(NSInvocation* invocation) {
    [invocation setReturnValue:&isViewLoaded];
  });
  OCMStub([flutterViewController viewIfLoaded]).andDo(^(NSInvocation* invocation) {
    [invocation setReturnValue:&viewIfLoaded];
  });
  OCMStub([flutterViewController view]).andReturn(flutterView);
  OCMStub([flutterViewController engine]).andReturn(engine);
  OCMStub([engine binaryMessenger]).andReturn(messenger);

  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
      /*is_gpu_disabled_sync_switch=*/std::make_shared<fml::SyncSwitch>());
  platform_view->SetOwnerViewController(flutterViewController);
  platform_view->SetSemanticsTreeEnabled(true);
  XCTAssertTrue(platform_view->GetAccessibilityBridge());

  __block NSInteger semanticsUpdateNotificationCount = 0;
  id observer =
      [[NSNotificationCenter defaultCenter] addObserverForName:FlutterSemanticsUpdateNotification
                                                        object:flutterViewController
                                                         queue:nil
                                                    usingBlock:^(NSNotification* notification) {
                                                      semanticsUpdateNotificationCount += 1;
                                                    }];

  flutter::SemanticsNode root_node;
  root_node.id = kRootNodeId;
  root_node.label = "root before view loaded";
  flutter::SemanticsNodeUpdates update;
  update[kRootNodeId] = root_node;
  platform_view->UpdateSemantics(/*view_id=*/0, std::move(update),
                                 flutter::CustomAccessibilityActionUpdates());
  XCTAssertNil(flutterView.accessibilityElements);
  XCTAssertEqual(semanticsUpdateNotificationCount, 0);

  isViewLoaded = YES;
  viewIfLoaded = flutterView;
  platform_view->attachView(flutter::kFlutterImplicitViewId);

  XCTAssertEqual(semanticsUpdateNotificationCount, 1);
  XCTAssertNotNil(flutterView.accessibilityElements);
  id rootContainer = flutterView.accessibilityElements.firstObject;
  id rootElement = [rootContainer accessibilityElementAtIndex:0];
  XCTAssertEqualObjects([rootElement accessibilityLabel], @"root before view loaded");
  platform_view->SetSemanticsTreeEnabled(false);
  [[NSNotificationCenter defaultCenter] removeObserver:observer];

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
  FlutterView* firstView = [[FlutterView alloc] initWithDelegate:engine
                                                          opaque:YES
                                                 enableWideGamut:NO];
  FlutterView* secondView = [[FlutterView alloc] initWithDelegate:engine
                                                           opaque:YES
                                                  enableWideGamut:NO];

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
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
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
  FlutterView* firstView = [[FlutterView alloc] initWithDelegate:engine
                                                          opaque:YES
                                                 enableWideGamut:NO];
  FlutterView* secondView = [[FlutterView alloc] initWithDelegate:engine
                                                           opaque:YES
                                                  enableWideGamut:NO];

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
      /*platform_views_controller=*/nil,
      /*task_runners=*/runners,
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

@end
