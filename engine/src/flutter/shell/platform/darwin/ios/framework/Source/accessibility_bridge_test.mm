// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <XCTest/XCTest.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#import "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#import "third_party/ocmock/Source/OCMock/OCMock.h"

FLUTTER_ASSERT_NOT_ARC

namespace flutter {
namespace {
class MockDelegate : public PlatformView::Delegate {
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

@interface AccessibilityBridgeTest : XCTestCase
@end

@implementation AccessibilityBridgeTest

- (void)testCreate {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view=*/nil,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil);
  XCTAssertTrue(bridge.get());
}

- (void)testUpdateSemanticsEmpty {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  id mockFlutterView = OCMClassMock([FlutterView class]);
  OCMExpect([mockFlutterView setAccessibilityElements:[OCMArg isNil]]);
  auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view=*/mockFlutterView,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil);
  flutter::SemanticsNodeUpdates nodes;
  flutter::CustomAccessibilityActionUpdates actions;
  bridge->UpdateSemantics(/*nodes=*/nodes, /*actions=*/actions);
  OCMVerifyAll(mockFlutterView);
}

- (void)testUpdateSemanticsOneNode {
  flutter::MockDelegate mock_delegate;
  auto thread_task_runner = CreateNewThread("AccessibilityBridgeTest");
  flutter::TaskRunners runners(/*label=*/self.name.UTF8String,
                               /*platform=*/thread_task_runner,
                               /*raster=*/thread_task_runner,
                               /*ui=*/thread_task_runner,
                               /*io=*/thread_task_runner);
  auto platform_view = std::make_unique<flutter::PlatformViewIOS>(
      /*delegate=*/mock_delegate,
      /*rendering_api=*/flutter::IOSRenderingAPI::kSoftware,
      /*task_runners=*/runners);
  id mockFlutterView = OCMClassMock([FlutterView class]);
  std::string label = "some label";

  __block auto bridge =
      std::make_unique<flutter::AccessibilityBridge>(/*view=*/mockFlutterView,
                                                     /*platform_view=*/platform_view.get(),
                                                     /*platform_views_controller=*/nil);

  OCMExpect([mockFlutterView setAccessibilityElements:[OCMArg checkWithBlock:^BOOL(NSArray* value) {
                               if ([value count] != 1) {
                                 return NO;
                               } else {
                                 SemanticsObjectContainer* container = value[0];
                                 SemanticsObject* object = container.semanticsObject;
                                 return object.uid == kRootNodeId &&
                                        object.bridge.get() == bridge.get() &&
                                        object.node.label == label;
                               }
                             }]]);

  flutter::SemanticsNodeUpdates nodes;
  flutter::SemanticsNode semantics_node;
  semantics_node.id = kRootNodeId;
  semantics_node.label = label;
  nodes[kRootNodeId] = semantics_node;
  flutter::CustomAccessibilityActionUpdates actions;
  bridge->UpdateSemantics(/*nodes=*/nodes, /*actions=*/actions);
  OCMVerifyAll(mockFlutterView);
}

@end
