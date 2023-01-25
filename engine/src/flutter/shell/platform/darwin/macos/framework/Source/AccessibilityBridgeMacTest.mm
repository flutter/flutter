// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/testing/testing.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/AccessibilityBridgeMac.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

namespace flutter::testing {

namespace {

class AccessibilityBridgeMacSpy : public AccessibilityBridgeMac {
 public:
  using AccessibilityBridgeMac::OnAccessibilityEvent;

  AccessibilityBridgeMacSpy(__weak FlutterEngine* flutter_engine,
                            __weak FlutterViewController* view_controller)
      : AccessibilityBridgeMac(flutter_engine, view_controller) {}

  std::unordered_map<std::string, gfx::NativeViewAccessible> actual_notifications;

 private:
  void DispatchMacOSNotification(gfx::NativeViewAccessible native_node,
                                 NSAccessibilityNotificationName mac_notification) override {
    actual_notifications[[mac_notification UTF8String]] = native_node;
  }
};

}  // namespace
}  // namespace flutter::testing

@interface AccessibilityBridgeTestEngine : FlutterEngine
- (std::shared_ptr<flutter::AccessibilityBridgeMac>)
    createAccessibilityBridge:(nonnull FlutterEngine*)engine
               viewController:(nonnull FlutterViewController*)viewController;
@end

@implementation AccessibilityBridgeTestEngine
- (std::shared_ptr<flutter::AccessibilityBridgeMac>)
    createAccessibilityBridge:(nonnull FlutterEngine*)engine
               viewController:(nonnull FlutterViewController*)viewController {
  return std::make_shared<flutter::testing::AccessibilityBridgeMacSpy>(engine, viewController);
}
@end

namespace flutter::testing {

namespace {

// Returns an engine configured for the text fixture resource configuration.
FlutterEngine* CreateTestEngine() {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  return [[AccessibilityBridgeTestEngine alloc] initWithName:@"test"
                                                     project:project
                                      allowHeadlessExecution:true];
}
}  // namespace

TEST(AccessibilityBridgeMacTest, sendsAccessibilityCreateNotificationToWindowOfFlutterView) {
  FlutterEngine* engine = CreateTestEngine();
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  [engine setViewController:viewController];

  NSWindow* expectedTarget = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
                                                         styleMask:NSBorderlessWindowMask
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
  expectedTarget.contentView = viewController.view;
  // Setting up bridge so that the AccessibilityBridgeMacDelegateSpy
  // can query semantics information from.
  engine.semanticsEnabled = YES;
  auto bridge =
      std::reinterpret_pointer_cast<AccessibilityBridgeMacSpy>(engine.accessibilityBridge.lock());
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = static_cast<FlutterSemanticsFlag>(0);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();
  auto platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();

  // Creates a targeted event.
  ui::AXTree tree;
  ui::AXNode ax_node(&tree, nullptr, 0, 0);
  ui::AXNodeData node_data;
  node_data.id = 0;
  ax_node.SetData(node_data);
  std::vector<ui::AXEventIntent> intent;
  ui::AXEventGenerator::EventParams event_params(ui::AXEventGenerator::Event::CHILDREN_CHANGED,
                                                 ax::mojom::EventFrom::kNone, intent);
  ui::AXEventGenerator::TargetedEvent targeted_event(&ax_node, event_params);

  bridge->OnAccessibilityEvent(targeted_event);

  EXPECT_EQ(bridge->actual_notifications.size(), 1u);
  EXPECT_EQ(
      bridge->actual_notifications.find([NSAccessibilityCreatedNotification UTF8String])->second,
      expectedTarget);
  [engine shutDownEngine];
}

TEST(AccessibilityBridgeMacTest, doesNotSendAccessibilityCreateNotificationWhenHeadless) {
  FlutterEngine* engine = CreateTestEngine();
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  [engine setViewController:viewController];
  // Setting up bridge so that the AccessibilityBridgeMacDelegateSpy
  // can query semantics information from.
  engine.semanticsEnabled = YES;
  auto bridge =
      std::reinterpret_pointer_cast<AccessibilityBridgeMacSpy>(engine.accessibilityBridge.lock());
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = static_cast<FlutterSemanticsFlag>(0);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();
  auto platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();

  // Creates a targeted event.
  ui::AXTree tree;
  ui::AXNode ax_node(&tree, nullptr, 0, 0);
  ui::AXNodeData node_data;
  node_data.id = 0;
  ax_node.SetData(node_data);
  std::vector<ui::AXEventIntent> intent;
  ui::AXEventGenerator::EventParams event_params(ui::AXEventGenerator::Event::CHILDREN_CHANGED,
                                                 ax::mojom::EventFrom::kNone, intent);
  ui::AXEventGenerator::TargetedEvent targeted_event(&ax_node, event_params);

  bridge->OnAccessibilityEvent(targeted_event);

  // Does not send any notification if the engine is headless.
  EXPECT_EQ(bridge->actual_notifications.size(), 0u);
  [engine shutDownEngine];
}

TEST(AccessibilityBridgeMacTest, doesNotSendAccessibilityCreateNotificationWhenNoWindow) {
  FlutterEngine* engine = CreateTestEngine();
  // Create a view controller without attaching it to a window.
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [viewController loadView];
  [engine setViewController:viewController];

  // Setting up bridge so that the AccessibilityBridgeMacDelegateSpy
  // can query semantics information from.
  engine.semanticsEnabled = YES;
  auto bridge =
      std::reinterpret_pointer_cast<AccessibilityBridgeMacSpy>(engine.accessibilityBridge.lock());
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = static_cast<FlutterSemanticsFlag>(0);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.tooltip = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();
  auto platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();

  // Creates a targeted event.
  ui::AXTree tree;
  ui::AXNode ax_node(&tree, nullptr, 0, 0);
  ui::AXNodeData node_data;
  node_data.id = 0;
  ax_node.SetData(node_data);
  std::vector<ui::AXEventIntent> intent;
  ui::AXEventGenerator::EventParams event_params(ui::AXEventGenerator::Event::CHILDREN_CHANGED,
                                                 ax::mojom::EventFrom::kNone, intent);
  ui::AXEventGenerator::TargetedEvent targeted_event(&ax_node, event_params);

  bridge->OnAccessibilityEvent(targeted_event);

  // Does not send any notification if the flutter view is not attached to a NSWindow.
  EXPECT_EQ(bridge->actual_notifications.size(), 0u);
  [engine shutDownEngine];
}

}  // namespace flutter::testing
