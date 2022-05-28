// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/testing/testing.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/AccessibilityBridgeMacDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"
namespace flutter::testing {

namespace {

class AccessibilityBridgeMacDelegateSpy : public AccessibilityBridgeMacDelegate {
 public:
  AccessibilityBridgeMacDelegateSpy(__weak FlutterEngine* flutter_engine,
                                    __weak FlutterViewController* view_controller)
      : AccessibilityBridgeMacDelegate(flutter_engine, view_controller) {}

  std::unordered_map<std::string, gfx::NativeViewAccessible> actual_notifications;

 private:
  void DispatchMacOSNotification(gfx::NativeViewAccessible native_node,
                                 NSAccessibilityNotificationName mac_notification) override {
    actual_notifications[[mac_notification UTF8String]] = native_node;
  }
};

// Returns an engine configured for the text fixture resource configuration.
FlutterEngine* CreateTestEngine() {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  return [[FlutterEngine alloc] initWithName:@"test" project:project allowHeadlessExecution:true];
}
}  // namespace

TEST(AccessibilityBridgeMacDelegateTest,
     sendsAccessibilityCreateNotificationToWindowOfFlutterView) {
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
  auto bridge = engine.accessibilityBridge.lock();
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
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();
  auto platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();

  AccessibilityBridgeMacDelegateSpy spy(engine, viewController);

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

  spy.OnAccessibilityEvent(targeted_event);

  EXPECT_EQ(spy.actual_notifications.size(), 1u);
  EXPECT_EQ(spy.actual_notifications.find([NSAccessibilityCreatedNotification UTF8String])->second,
            expectedTarget);
  [engine shutDownEngine];
}

TEST(AccessibilityBridgeMacDelegateTest, doesNotSendAccessibilityCreateNotificationWhenHeadless) {
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
  auto bridge = engine.accessibilityBridge.lock();
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
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();
  auto platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();

  AccessibilityBridgeMacDelegateSpy spy(engine, viewController);

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

  spy.OnAccessibilityEvent(targeted_event);

  // Does not send any notification if the engine is headless.
  EXPECT_EQ(spy.actual_notifications.size(), 0u);
  [engine shutDownEngine];
}

TEST(AccessibilityBridgeMacDelegateTest, doesNotSendAccessibilityCreateNotificationWhenNoWindow) {
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
  auto bridge = engine.accessibilityBridge.lock();
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
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();
  auto platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();

  AccessibilityBridgeMacDelegateSpy spy(engine, viewController);

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

  spy.OnAccessibilityEvent(targeted_event);

  // Does not send any notification if the flutter view is not attached to a NSWindow.
  EXPECT_EQ(spy.actual_notifications.size(), 0u);
  [engine shutDownEngine];
}

}  // namespace flutter::testing
