// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <functional>
#include <memory>
#include <vector>
#define FML_USED_ON_EMBEDDER

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#include "flutter/common/constants.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/thread.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine+Test.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterViewController_Internal.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"

FLUTTER_ASSERT_ARC

namespace {
constexpr int64_t kPrimaryFlutterViewId = 1;
constexpr int64_t kSecondaryFlutterViewId = 2;
constexpr int64_t kTertiaryFlutterViewId = 3;
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
    if (remove_view_handler_) {
      remove_view_handler_(std::move(callback));
    } else {
      callback(true);
    }
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
  std::function<void(RemoveViewCallback)> remove_view_handler_;
  int viewport_metrics_calls_ = 0;
  int64_t last_viewport_metrics_view_id_ = -1;
};

}  // namespace
}  // namespace flutter

@interface FlutterEngine (MultiViewTests)
- (void)setUpChannels;
- (void)resetChannels;
@end

// Avoid retaining view controllers through OCMock's recorded invocations.
@interface FlutterEngineWithFakePlatformView : FlutterEngine
@property(nonatomic, assign) flutter::PlatformViewIOS* fakePlatformView;
@property(nonatomic, strong) NSObject<FlutterBinaryMessenger>* fakeBinaryMessenger;
@end

@implementation FlutterEngineWithFakePlatformView

- (flutter::PlatformViewIOS*)platformView {
  return self.fakePlatformView;
}

- (NSObject<FlutterBinaryMessenger>*)binaryMessenger {
  return self.fakeBinaryMessenger ?: [super binaryMessenger];
}

@end

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
  fake_delegate.remove_view_handler_ = nullptr;
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

  [engine notifyViewRenderingSurfaceCreated:flutter::kFlutterImplicitViewId];
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

- (void)testSetViewControllerRejectsExplicitControllerInMultiView {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  [engine enableMultiView];
  FlutterViewController* controller = [[FlutterViewController alloc] initWithEngine:engine
                                                                            nibName:nil
                                                                             bundle:nil];

  XCTAssertThrowsSpecificNamed([engine setViewController:controller], NSException,
                               NSInternalInconsistencyException);
}

- (void)testSetViewControllerRejectsNilInMultiView {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  [engine enableMultiView];

  XCTAssertThrowsSpecificNamed([engine setViewController:nil], NSException,
                               NSInternalInconsistencyException);
}

- (void)testEnableMultiViewAssignsIncrementingIdentifiersAndLookup {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine enableMultiView];

  FlutterViewController* primaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* tertiaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];

  XCTAssertEqual(primaryViewController.viewIdentifier, kPrimaryFlutterViewId);
  XCTAssertEqual(secondaryViewController.viewIdentifier, kSecondaryFlutterViewId);
  XCTAssertEqual(tertiaryViewController.viewIdentifier, kTertiaryFlutterViewId);

  XCTAssertNil(engine.viewController);
  XCTAssertNil([engine viewControllerForIdentifier:flutter::kFlutterImplicitViewId]);
  XCTAssertNil(platform_view->GetOwnerViewController());
  XCTAssertEqual([engine viewControllerForIdentifier:kPrimaryFlutterViewId], primaryViewController);
  XCTAssertEqual([engine viewControllerForIdentifier:kSecondaryFlutterViewId],
                 secondaryViewController);
  XCTAssertEqual([engine viewControllerForIdentifier:kTertiaryFlutterViewId],
                 tertiaryViewController);

  XCTAssertTrue((fake_delegate.added_view_ids_ == std::vector<int64_t>{kPrimaryFlutterViewId,
                                                                       kSecondaryFlutterViewId,
                                                                       kTertiaryFlutterViewId}));
}

- (void)testEnableMultiViewRejectsAttachedImplicitController {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  FlutterViewController* controller = [[FlutterViewController alloc] initWithEngine:engine
                                                                            nibName:nil
                                                                             bundle:nil];

  XCTAssertThrowsSpecificNamed([engine enableMultiView], NSException,
                               NSInternalInconsistencyException);
  XCTAssertEqual(engine.viewController, controller);
  XCTAssertEqual(controller.viewIdentifier, flutter::kFlutterImplicitViewId);
  XCTAssertTrue(fake_delegate.added_view_ids_.empty());
}

- (void)testEnableMultiViewIsIdempotent {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  [engine enableMultiView];
  FlutterViewController* primary = [[FlutterViewController alloc] initWithEngine:engine
                                                                         nibName:nil
                                                                          bundle:nil];
  XCTAssertNoThrow([engine enableMultiView]);
  FlutterViewController* secondary = [[FlutterViewController alloc] initWithEngine:engine
                                                                           nibName:nil
                                                                            bundle:nil];

  XCTAssertEqual(primary.viewIdentifier, kPrimaryFlutterViewId);
  XCTAssertEqual(secondary.viewIdentifier, kSecondaryFlutterViewId);
  XCTAssertTrue((fake_delegate.added_view_ids_ ==
                 std::vector<int64_t>{kPrimaryFlutterViewId, kSecondaryFlutterViewId}));
}

- (void)testRemovingViewClearsOnlyItsEngineInputClient {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  engine.fakeBinaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  [engine setUpChannels];
  [engine enableMultiView];
  FlutterViewController* primary = [[FlutterViewController alloc] initWithEngine:engine
                                                                         nibName:nil
                                                                          bundle:nil];
  FlutterViewController* secondary = [[FlutterViewController alloc] initWithEngine:engine
                                                                           nibName:nil
                                                                            bundle:nil];
  [engine.textInputPlugin
      handleMethodCall:[FlutterMethodCall
                           methodCallWithMethodName:@"TextInput.setClient"
                                          arguments:@[
                                            @123, @{
                                              @"viewId" : @(secondary.viewIdentifier),
                                              @"inputType" : @{@"name" : @"TextInputType.text"},
                                            }
                                          ]]
                result:^(id result){
                }];
  XCTAssertEqual(engine.textInputPlugin.currentViewController, secondary);

  [engine removeViewController:primary.viewIdentifier];
  XCTAssertEqual(engine.textInputPlugin.currentViewController, secondary);
  [engine removeViewController:secondary.viewIdentifier];
  XCTAssertNil(engine.textInputPlugin.currentViewController);
  XCTAssertNil(engine.textInputPlugin.textInputView.superview);
}

- (void)testImplicitViewDetachNotifiesDartBeforeReattachment {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  engine.fakeBinaryMessenger = messenger;
  [engine setUpChannels];
  FlutterViewController* controller = [[FlutterViewController alloc] initWithEngine:engine
                                                                            nibName:nil
                                                                             bundle:nil];
  [controller loadViewIfNeeded];
  id mockController = OCMPartialMock(controller);
  OCMStub([mockController touchesBegan:[OCMArg any] withEvent:[OCMArg any]]);
  OCMStub([mockController touchesMoved:[OCMArg any] withEvent:[OCMArg any]]);
  OCMStub([mockController touchesEnded:[OCMArg any] withEvent:[OCMArg any]]);
  for (NSNumber* client in @[ @123, @456 ]) {
    engine.viewController = controller;
    [engine.textInputPlugin
        handleMethodCall:[FlutterMethodCall
                             methodCallWithMethodName:@"TextInput.setClient"
                                            arguments:@[
                                              client, @{
                                                @"viewId" : @0,
                                                @"inputType" : @{@"name" : @"TextInputType.text"},
                                              }
                                            ]]
                  result:^(id result){
                  }];
    XCTAssertEqual(engine.textInputPlugin.currentViewController, controller);
    XCTAssertTrue(engine.textInputPlugin.textInputView.canBecomeFirstResponder);
    [engine.textInputPlugin
        handleMethodCall:[FlutterMethodCall methodCallWithMethodName:@"TextInput.show"
                                                           arguments:nil]
                  result:^(id result){
                  }];
    FlutterTextInputView* inputView = (FlutterTextInputView*)engine.textInputPlugin.textInputView;
    [inputView touchesBegan:[NSSet set] withEvent:nil];
    [inputView touchesMoved:[NSSet set] withEvent:nil];
    [inputView touchesEnded:[NSSet set] withEvent:nil];

    FlutterMethodCall* connectionClosed =
        [FlutterMethodCall methodCallWithMethodName:@"TextInputClient.onConnectionClosed"
                                          arguments:@[ client ]];
    NSData* message = [[FlutterJSONMethodCodec sharedInstance] encodeMethodCall:connectionClosed];
    OCMExpect([messenger sendOnChannel:@"flutter/textinput" message:message]);

    engine.viewController = nil;

    OCMVerifyAll(messenger);
    XCTAssertNil(engine.textInputPlugin.currentViewController);
    XCTAssertFalse(engine.textInputPlugin.textInputView.canBecomeFirstResponder);
  }
  XCTAssertTrue(fake_delegate.removed_view_ids_.empty());
  OCMVerify(times(2), [mockController touchesBegan:[OCMArg any] withEvent:[OCMArg any]]);
  OCMVerify(times(2), [mockController touchesMoved:[OCMArg any] withEvent:[OCMArg any]]);
  OCMVerify(times(2), [mockController touchesEnded:[OCMArg any] withEvent:[OCMArg any]]);
  [mockController stopMocking];
}

- (void)testViewControllerPrefersFirstResponderThenKeyWindow {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  [engine enableMultiView];
  XCTAssertNil(engine.viewController);
  FlutterViewController* primary = [[FlutterViewController alloc] initWithEngine:engine
                                                                         nibName:nil
                                                                          bundle:nil];
  XCTAssertEqual(engine.viewController, primary);
  FlutterViewController* secondary = [[FlutterViewController alloc] initWithEngine:engine
                                                                           nibName:nil
                                                                            bundle:nil];
  XCTAssertNil(engine.viewController);
  id primaryMock = OCMPartialMock(primary);
  id secondaryMock = OCMPartialMock(secondary);
  UIWindow* window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 400, 800)];
  UIWindow* keyWindow = [[UIWindow alloc] initWithFrame:window.bounds];
  id keyWindowMock = OCMPartialMock(keyWindow);
  OCMStub([keyWindowMock isKeyWindow]).andReturn(YES);
  UIView* primaryView = [[UIView alloc] initWithFrame:window.bounds];
  [keyWindow addSubview:primaryView];
  OCMStub([primaryMock viewIfLoaded]).andReturn(primaryView);
  UIView* secondaryView = [[UIView alloc] initWithFrame:window.bounds];
  [window addSubview:secondaryView];
  OCMStub([secondaryMock viewIfLoaded]).andReturn(secondaryView);

  XCTAssertEqual(engine.viewController, primary);
  [window addSubview:primaryView];
  [keyWindow addSubview:secondaryView];
  XCTAssertEqual(engine.viewController, secondary);
  [keyWindow addSubview:primaryView];
  [window addSubview:secondaryView];

  UITextField* textField = [[UITextField alloc] init];
  [secondaryView addSubview:textField];
  id textFieldMock = OCMPartialMock(textField);
  OCMStub([textFieldMock isFirstResponder]).andReturn(YES);

  XCTAssertEqual(engine.viewController, secondary);
  XCTAssertNil([engine viewControllerForIdentifier:flutter::kFlutterImplicitViewId]);

  [secondaryView removeFromSuperview];
  XCTAssertEqual(engine.viewController, primary);
  [window addSubview:secondaryView];

  [engine removeViewController:secondary.viewIdentifier];
  XCTAssertEqual(engine.viewController, primary);
  [engine removeViewController:primary.viewIdentifier];
  XCTAssertNil(engine.viewController);
  [textFieldMock stopMocking];
  [keyWindowMock stopMocking];
  [primaryMock stopMocking];
  [secondaryMock stopMocking];
}

- (void)testAccessibilityFocusFindsTheOwningExplicitView {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  engine.fakeBinaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  [engine enableMultiView];
  FlutterViewController* primary = [[FlutterViewController alloc] initWithEngine:engine
                                                                         nibName:nil
                                                                          bundle:nil];
  FlutterViewController* secondary = [[FlutterViewController alloc] initWithEngine:engine
                                                                           nibName:nil
                                                                            bundle:nil];
  [primary loadViewIfNeeded];
  [secondary loadViewIfNeeded];
  platform_view->SetSemanticsTreeEnabled(true);
  constexpr int32_t kPrimaryNodeId = 10;
  constexpr int32_t kSecondaryNodeId = 20;
  for (FlutterViewController* controller in @[ primary, secondary ]) {
    flutter::SemanticsNode root;
    root.id = 0;
    flutter::SemanticsNode child;
    child.id = controller == primary ? kPrimaryNodeId : kSecondaryNodeId;
    child.label = "Focusable node";
    root.childrenInTraversalOrder = {child.id};
    root.childrenInHitTestOrder = {child.id};
    platform_view->UpdateSemantics(controller.viewIdentifier, {{0, root}, {child.id, child}}, {});
  }
  // The Framework's FocusSemanticEvent includes a nodeId and an empty data dictionary.
  XCTAssertTrue(platform_view->HandleAccessibilityEvent(
      @{@"type" : @"focus", @"data" : @{}, @"nodeId" : @(kPrimaryNodeId)}));
  XCTAssertTrue(platform_view->HandleAccessibilityEvent(
      @{@"type" : @"focus", @"data" : @{}, @"nodeId" : @(kSecondaryNodeId)}));
  XCTAssertFalse(platform_view->HandleAccessibilityEvent(
      @{@"type" : @"focus", @"data" : @{}, @"nodeId" : @99}));
  // Root IDs are shared across trees and require an explicit view ID.
  XCTAssertFalse(platform_view->HandleAccessibilityEvent(
      @{@"type" : @"focus", @"data" : @{}, @"nodeId" : @0}));
  XCTAssertTrue(platform_view->HandleAccessibilityEvent(
      @{@"type" : @"focus", @"data" : @{@"viewId" : @(secondary.viewIdentifier)}, @"nodeId" : @0}));

  [engine removeViewController:primary.viewIdentifier];

  XCTAssertFalse(platform_view->HandleAccessibilityEvent(
      @{@"type" : @"focus", @"data" : @{}, @"nodeId" : @(kPrimaryNodeId)}));
  XCTAssertTrue(platform_view->HandleAccessibilityEvent(
      @{@"type" : @"focus", @"data" : @{}, @"nodeId" : @(kSecondaryNodeId)}));
}

- (void)testAccessibilityHandlerSurvivesViewRemovalAndBridgeRecreation {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  id messenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  engine.fakeBinaryMessenger = messenger;
  __block FlutterBinaryMessageHandler handler;
  FlutterBinaryMessengerConnection connection = 123;
  OCMStub([messenger setMessageHandlerOnChannel:@"flutter/accessibility"
                           binaryMessageHandler:[OCMArg any]])
      .andReturn(connection)
      .andDo(^(NSInvocation* invocation) {
        __unsafe_unretained FlutterBinaryMessageHandler argument;
        [invocation getArgument:&argument atIndex:3];
        handler = [argument copy];
      });
  OCMStub([messenger cleanUpConnection:connection]).andDo(^(NSInvocation* invocation) {
    handler = nil;
  });
  [engine setUpChannels];
  [engine enableMultiView];
  FlutterViewController* primary = [[FlutterViewController alloc] initWithEngine:engine
                                                                         nibName:nil
                                                                          bundle:nil];
  FlutterViewController* secondary = [[FlutterViewController alloc] initWithEngine:engine
                                                                           nibName:nil
                                                                            bundle:nil];
  platform_view->SetSemanticsTreeEnabled(true);
  [engine removeViewController:secondary.viewIdentifier];
  [primary loadViewIfNeeded];
  XCTAssertNotNil(handler);

  __block BOOL replied = NO;
  NSData* message = [[FlutterStandardMessageCodec sharedInstance] encode:@{
    @"type" : @"announce",
    @"data" : @{@"message" : @"Still available", @"viewId" : @(primary.viewIdentifier)}
  }];
  handler(message, ^(NSData* reply) {
    replied = YES;
  });
  XCTAssertTrue(replied);
  [engine resetChannels];
  XCTAssertNil(handler);
  OCMVerify(times(1), [messenger setMessageHandlerOnChannel:@"flutter/accessibility"
                                       binaryMessageHandler:[OCMArg any]]);
  OCMVerify(times(1), [messenger cleanUpConnection:connection]);
}

- (void)testRemovingAllExplicitViewsDoesNotReuseIdentifiers {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine enableMultiView];

  FlutterViewController* primaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  XCTAssertEqual(secondaryViewController.viewIdentifier, kSecondaryFlutterViewId);

  [engine removeViewController:primaryViewController.viewIdentifier];
  XCTAssertNil([engine viewControllerForIdentifier:kPrimaryFlutterViewId]);
  XCTAssertEqual([engine viewControllerForIdentifier:kSecondaryFlutterViewId],
                 secondaryViewController);
  [engine removeViewController:secondaryViewController.viewIdentifier];
  XCTAssertNil([engine viewControllerForIdentifier:kSecondaryFlutterViewId]);
  XCTAssertNil([engine viewControllerForIdentifier:flutter::kFlutterImplicitViewId]);
  XCTAssertTrue((fake_delegate.removed_view_ids_ ==
                 std::vector<int64_t>{kPrimaryFlutterViewId, kSecondaryFlutterViewId}));

  FlutterViewController* tertiaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  XCTAssertEqual(tertiaryViewController.viewIdentifier, kTertiaryFlutterViewId);
  XCTAssertEqual([engine viewControllerForIdentifier:kTertiaryFlutterViewId],
                 tertiaryViewController);
  XCTAssertEqual(engine.viewController, tertiaryViewController);
}

- (void)testNotifyDestroyedOnlyDestroysPlatformViewWhenLastViewIsRemoved {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine enableMultiView];

  FlutterViewController* primaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];

  [primaryViewController loadViewIfNeeded];
  [secondaryViewController loadViewIfNeeded];

  [engine notifyViewRenderingSurfaceCreated:kPrimaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_created_calls_, 1);

  [engine notifyViewRenderingSurfaceCreated:kSecondaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_created_calls_, 1);

  [engine notifyViewRenderingSurfaceDestroyed:kSecondaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 0);

  [engine notifyViewRenderingSurfaceDestroyed:kPrimaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 1);
}

- (void)testRemovingActiveViewControllerWithoutSurfaceUpdateCleansUpSurface {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());
  [engine enableMultiView];

  FlutterViewController* primaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  [primaryViewController loadViewIfNeeded];
  [secondaryViewController loadViewIfNeeded];
  [engine notifyViewRenderingSurfaceCreated:kPrimaryFlutterViewId];
  [engine notifyViewRenderingSurfaceCreated:kSecondaryFlutterViewId];

  [engine removeViewController:kSecondaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_created_calls_, 1);
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 0);
  XCTAssertEqual(fake_delegate.removed_view_ids_.size(), 1UL);
  XCTAssertEqual(fake_delegate.removed_view_ids_[0], kSecondaryFlutterViewId);

  [engine notifyViewRenderingSurfaceDestroyed:kSecondaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 0);

  [engine removeViewController:kPrimaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 1);
  XCTAssertTrue((fake_delegate.removed_view_ids_ ==
                 std::vector<int64_t>{kSecondaryFlutterViewId, kPrimaryFlutterViewId}));
}

- (void)testReplacingExplicitControllerKeepsSecondarySurface {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());
  [engine enableMultiView];

  FlutterViewController* primaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  [primaryViewController loadViewIfNeeded];
  [secondaryViewController loadViewIfNeeded];
  [engine notifyViewRenderingSurfaceCreated:kPrimaryFlutterViewId];
  [engine notifyViewRenderingSurfaceCreated:kSecondaryFlutterViewId];

  [engine removeViewController:kPrimaryFlutterViewId];
  FlutterViewController* replacementController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  [replacementController loadViewIfNeeded];
  XCTAssertEqual(replacementController.viewIdentifier, kTertiaryFlutterViewId);
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 0);

  [engine notifyViewRenderingSurfaceCreated:kTertiaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_created_calls_, 1);
  [engine removeViewController:kSecondaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 0);
  [engine removeViewController:kTertiaryFlutterViewId];
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 1);
}

- (void)testFirstViewControllerDeallocationWaitsForViewRemoval {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  [engine enableMultiView];

  FlutterViewController* secondaryViewController = nil;
  __weak FlutterViewController* weakViewController = nil;
  __weak CALayer* weakLayer = nil;
  __weak id<NSObject> weakObserver = nil;
  fml::Thread raster_thread("FlutterEnginePlatformViewTest.raster");
  fake_delegate.remove_view_handler_ = [&](flutter::PlatformView::RemoveViewCallback callback) {
    raster_thread.GetTaskRunner()->PostTask([&, callback = std::move(callback)] {
      XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 0);
      XCTAssertNotNil(weakLayer);
      callback(true);
    });
  };
  @autoreleasepool {
    FlutterViewController* primaryViewController =
        [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
    secondaryViewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                    nibName:nil
                                                                     bundle:nil];
    weakViewController = primaryViewController;
    [primaryViewController loadViewIfNeeded];
    weakLayer = primaryViewController.view.layer;
    weakObserver = engine.flutterViewControllerWillDeallocObservers[@(kPrimaryFlutterViewId)];
    XCTAssertNotNil(weakObserver);
    [engine notifyViewRenderingSurfaceCreated:kPrimaryFlutterViewId];
    XCTAssertEqual(fake_delegate.on_platform_view_created_calls_, 1);
    primaryViewController = nil;
  }

  XCTAssertNil(weakViewController);
  XCTAssertNil(weakLayer);
  XCTAssertNil(weakObserver);
  XCTAssertNil(engine.flutterViewControllerWillDeallocObservers[@(kPrimaryFlutterViewId)]);
  XCTAssertEqual(engine.flutterViewControllerWillDeallocObservers.count, 1UL);
  XCTAssertNil([engine viewControllerForIdentifier:kPrimaryFlutterViewId]);
  XCTAssertEqual(engine.viewController, secondaryViewController);
  XCTAssertEqual([engine viewControllerForIdentifier:kSecondaryFlutterViewId],
                 secondaryViewController);
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 1);
  XCTAssertTrue(fake_delegate.removed_view_ids_ == std::vector<int64_t>{kPrimaryFlutterViewId});
  fake_delegate.remove_view_handler_ = nullptr;
}

- (void)testSingleViewControllerDeallocationCleansUpResourcesAndAllowsReattachment {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();
  engine.fakeBinaryMessenger = OCMProtocolMock(@protocol(FlutterBinaryMessenger));
  platform_view->SetSemanticsTreeEnabled(true);

  for (int attachment = 1; attachment <= 2; attachment++) {
    __weak FlutterViewController* weakViewController = nil;
    __weak CALayer* weakLayer = nil;
    __weak id<NSObject> weakObserver = nil;
    fml::WeakPtr<flutter::AccessibilityBridge> weak_bridge;
    @autoreleasepool {
      FlutterViewController* viewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                    nibName:nil
                                                                                     bundle:nil];
      weakViewController = viewController;
      XCTAssertEqual(viewController.viewIdentifier, flutter::kFlutterImplicitViewId);
      [viewController loadViewIfNeeded];
      weakLayer = viewController.view.layer;
      weakObserver =
          engine.flutterViewControllerWillDeallocObservers[@(flutter::kFlutterImplicitViewId)];
      XCTAssertNotNil(weakObserver);
      weak_bridge = platform_view->GetAccessibilityBridge()->GetWeakPtr();
      XCTAssertTrue(weak_bridge.get());
      [engine notifyViewRenderingSurfaceCreated:flutter::kFlutterImplicitViewId];
      XCTAssertEqual(fake_delegate.on_platform_view_created_calls_, attachment);
      viewController = nil;
    }
    XCTAssertNil(weakViewController);
    XCTAssertNil(weakLayer);
    XCTAssertNil(weakObserver);
    XCTAssertFalse(weak_bridge.get());
    XCTAssertNil(engine.viewController);
    XCTAssertNil(platform_view->GetOwnerViewController());
    XCTAssertEqual(engine.flutterViewControllerWillDeallocObservers.count, 0UL);
    XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, attachment);
  }
  XCTAssertTrue(fake_delegate.added_view_ids_.empty());
  XCTAssertTrue(fake_delegate.removed_view_ids_.empty());
}

- (void)testReplacingSingleViewControllerKeepsReplacementAfterOldDeallocation {
  FlutterEngineWithFakePlatformView* engine =
      [[FlutterEngineWithFakePlatformView alloc] initWithName:@"tester"];
  engine.fakePlatformView = platform_view.get();

  __weak FlutterViewController* weakOldViewController = nil;
  __weak CALayer* weakOldLayer = nil;
  __weak id<NSObject> weakOldObserver = nil;
  __weak id<NSObject> weakReplacementObserver = nil;
  FlutterViewController* replacement = nil;
  @autoreleasepool {
    FlutterViewController* oldViewController = [[FlutterViewController alloc] initWithEngine:engine
                                                                                     nibName:nil
                                                                                      bundle:nil];
    weakOldViewController = oldViewController;
    [oldViewController loadViewIfNeeded];
    weakOldLayer = oldViewController.view.layer;
    weakOldObserver =
        engine.flutterViewControllerWillDeallocObservers[@(flutter::kFlutterImplicitViewId)];
    XCTAssertNotNil(weakOldObserver);
    [engine notifyViewRenderingSurfaceCreated:flutter::kFlutterImplicitViewId];

    replacement = [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
    [replacement loadViewIfNeeded];
    [engine notifyViewRenderingSurfaceCreated:flutter::kFlutterImplicitViewId];
    weakReplacementObserver =
        engine.flutterViewControllerWillDeallocObservers[@(flutter::kFlutterImplicitViewId)];
    XCTAssertNotNil(weakReplacementObserver);
    XCTAssertEqual(fake_delegate.on_platform_view_created_calls_, 2);
    XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 1);
    oldViewController = nil;
  }
  XCTAssertNil(weakOldViewController);
  XCTAssertNil(weakOldLayer);
  XCTAssertNil(weakOldObserver);
  XCTAssertEqual(engine.viewController, replacement);
  XCTAssertEqual(platform_view->GetOwnerViewController(), replacement);
  XCTAssertEqual(engine.flutterViewControllerWillDeallocObservers.count, 1UL);
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 1);

  @autoreleasepool {
    [engine setViewController:nil];
  }
  XCTAssertNil(weakReplacementObserver);
  XCTAssertEqual(engine.flutterViewControllerWillDeallocObservers.count, 0UL);
  XCTAssertEqual(fake_delegate.on_platform_view_destroyed_calls_, 2);
  XCTAssertTrue(fake_delegate.added_view_ids_.empty());
  XCTAssertTrue(fake_delegate.removed_view_ids_.empty());
}

- (void)testRemovingSecondaryViewControllerKeepsOtherControllerMappings {
  FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"tester"];
  id mockEngine = OCMPartialMock(engine);
  OCMStub([mockEngine platformView]).andReturn(platform_view.get());

  [engine enableMultiView];

  FlutterViewController* primaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* tertiaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];

  [engine removeViewController:secondaryViewController.viewIdentifier];

  XCTAssertEqual([engine viewControllerForIdentifier:kPrimaryFlutterViewId], primaryViewController);
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

  FlutterViewController* primaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  FlutterViewController* secondaryViewController =
      [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  XCTAssertEqual(primaryViewController.viewIdentifier, kPrimaryFlutterViewId);

  flutter::ViewportMetrics metrics = {};
  metrics.physical_width = 320;
  metrics.physical_height = 480;

  [engine updateViewportMetrics:metrics viewIdentifier:flutter::kFlutterImplicitViewId];
  XCTAssertEqual(fake_delegate.viewport_metrics_calls_, 0);

  [engine updateViewportMetrics:metrics viewIdentifier:primaryViewController.viewIdentifier];
  XCTAssertEqual(fake_delegate.viewport_metrics_calls_, 1);
  XCTAssertEqual(fake_delegate.last_viewport_metrics_view_id_, kPrimaryFlutterViewId);

  [engine updateViewportMetrics:metrics viewIdentifier:secondaryViewController.viewIdentifier];
  XCTAssertEqual(fake_delegate.viewport_metrics_calls_, 2);
  XCTAssertEqual(fake_delegate.last_viewport_metrics_view_id_,
                 secondaryViewController.viewIdentifier);

  const FlutterViewIdentifier unregisteredFlutterViewId =
      secondaryViewController.viewIdentifier + 1;
  [engine updateViewportMetrics:metrics viewIdentifier:unregisteredFlutterViewId];
  XCTAssertEqual(fake_delegate.viewport_metrics_calls_, 2);
}

@end
