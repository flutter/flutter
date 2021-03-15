// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/testing/testing.h"

#include "flutter/shell/platform/common/accessibility_bridge.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/AccessibilityBridgeMacDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformNodeDelegateMac.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/third_party/accessibility/ax/ax_action_data.h"

namespace flutter::testing {

namespace {
// Returns an engine configured for the text fixture resource configuration.
FlutterEngine* CreateTestEngine() {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  return [[FlutterEngine alloc] initWithName:@"test" project:project allowHeadlessExecution:true];
}
}  // namespace

TEST(FlutterPlatformNodeDelegateMac, Basics) {
  FlutterEngine* engine = CreateTestEngine();
  engine.semanticsEnabled = YES;
  auto bridge = engine.accessibilityBridge.lock();
  // Initialize ax node data.
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags = static_cast<FlutterSemanticsFlag>(0);
  ;
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "accessibility";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();

  auto root_platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  // Verify the accessibility attribute matches.
  NSAccessibilityElement* native_accessibility =
      root_platform_node_delegate->GetNativeViewAccessible();
  std::string value = [native_accessibility.accessibilityValue UTF8String];
  EXPECT_TRUE(value == "accessibility");
  EXPECT_EQ(native_accessibility.accessibilityRole, NSAccessibilityStaticTextRole);
  EXPECT_EQ([native_accessibility.accessibilityChildren count], 0u);
  [engine shutDownEngine];
}

TEST(FlutterPlatformNodeDelegateMac, SelectableTextHasCorrectSemantics) {
  FlutterEngine* engine = CreateTestEngine();
  engine.semanticsEnabled = YES;
  auto bridge = engine.accessibilityBridge.lock();
  // Initialize ax node data.
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags =
      static_cast<FlutterSemanticsFlag>(FlutterSemanticsFlag::kFlutterSemanticsFlagIsTextField |
                                        FlutterSemanticsFlag::kFlutterSemanticsFlagIsReadOnly);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = 1;
  root.text_selection_extent = 3;
  root.label = "";
  root.hint = "";
  // Selectable text store its text in value
  root.value = "selectable text";
  root.increased_value = "";
  root.decreased_value = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();

  auto root_platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  // Verify the accessibility attribute matches.
  NSAccessibilityElement* native_accessibility =
      root_platform_node_delegate->GetNativeViewAccessible();
  std::string value = [native_accessibility.accessibilityValue UTF8String];
  EXPECT_EQ(value, "selectable text");
  EXPECT_EQ(native_accessibility.accessibilityRole, NSAccessibilityStaticTextRole);
  EXPECT_EQ([native_accessibility.accessibilityChildren count], 0u);
  NSRange selection = native_accessibility.accessibilitySelectedTextRange;
  EXPECT_EQ(selection.location, 1u);
  EXPECT_EQ(selection.length, 2u);
  std::string selected_text = [native_accessibility.accessibilitySelectedText UTF8String];
  EXPECT_EQ(selected_text, "el");
}

TEST(FlutterPlatformNodeDelegateMac, SelectableTextWithoutSelectionReturnZeroRange) {
  FlutterEngine* engine = CreateTestEngine();
  engine.semanticsEnabled = YES;
  auto bridge = engine.accessibilityBridge.lock();
  // Initialize ax node data.
  FlutterSemanticsNode root;
  root.id = 0;
  root.flags =
      static_cast<FlutterSemanticsFlag>(FlutterSemanticsFlag::kFlutterSemanticsFlagIsTextField |
                                        FlutterSemanticsFlag::kFlutterSemanticsFlagIsReadOnly);
  root.actions = static_cast<FlutterSemanticsAction>(0);
  root.text_selection_base = -1;
  root.text_selection_extent = -1;
  root.label = "";
  root.hint = "";
  // Selectable text store its text in value
  root.value = "selectable text";
  root.increased_value = "";
  root.decreased_value = "";
  root.child_count = 0;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  bridge->CommitUpdates();

  auto root_platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  // Verify the accessibility attribute matches.
  NSAccessibilityElement* native_accessibility =
      root_platform_node_delegate->GetNativeViewAccessible();
  NSRange selection = native_accessibility.accessibilitySelectedTextRange;
  EXPECT_TRUE(selection.location == NSNotFound);
  EXPECT_EQ(selection.length, 0u);
}

TEST(FlutterPlatformNodeDelegateMac, CanPerformAction) {
  FlutterEngine* engine = CreateTestEngine();
  engine.semanticsEnabled = YES;
  auto bridge = engine.accessibilityBridge.lock();
  // Initialize ax node data.
  FlutterSemanticsNode root;
  root.id = 0;
  root.label = "root";
  root.hint = "";
  root.value = "";
  root.increased_value = "";
  root.decreased_value = "";
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&root);

  FlutterSemanticsNode child1;
  child1.id = 1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;
  bridge->AddFlutterSemanticsNodeUpdate(&child1);

  bridge->CommitUpdates();

  auto root_platform_node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();

  // Set up embedder API mock.
  FlutterSemanticsAction called_action;
  uint64_t called_id;

  engine.embedderAPI.DispatchSemanticsAction = MOCK_ENGINE_PROC(
      DispatchSemanticsAction,
      ([&called_id, &called_action](auto engine, uint64_t id, FlutterSemanticsAction action,
                                    const uint8_t* data, size_t data_length) {
        called_id = id;
        called_action = action;
        return kSuccess;
      }));

  // Performs an AXAction.
  ui::AXActionData action_data;
  action_data.action = ax::mojom::Action::kDoDefault;
  root_platform_node_delegate->AccessibilityPerformAction(action_data);

  EXPECT_EQ(called_action, FlutterSemanticsAction::kFlutterSemanticsActionTap);
  EXPECT_EQ(called_id, 1u);
  [engine shutDownEngine];
}

}  // flutter::testing
