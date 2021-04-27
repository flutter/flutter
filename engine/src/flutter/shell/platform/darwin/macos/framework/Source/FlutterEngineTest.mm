// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>

#include "flutter/shell/platform/common/accessibility_bridge.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterAppDelegate.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewControllerTestUtils.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/testing/testing.h"

namespace flutter::testing {

namespace {
// Returns an engine configured for the test fixture resource configuration.
FlutterEngine* CreateTestEngine() {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  return [[FlutterEngine alloc] initWithName:@"test" project:project allowHeadlessExecution:true];
}
}  // namespace

TEST(FlutterEngine, CanLaunch) {
  FlutterEngine* engine = CreateTestEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);
  EXPECT_TRUE(engine.running);
  [engine shutDownEngine];
}

TEST(FlutterEngine, MessengerSend) {
  FlutterEngine* engine = CreateTestEngine();
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);

  NSData* test_message = [@"a message" dataUsingEncoding:NSUTF8StringEncoding];
  bool called = false;

  engine.embedderAPI.SendPlatformMessage = MOCK_ENGINE_PROC(
      SendPlatformMessage, ([&called, test_message](auto engine, auto message) {
        called = true;
        EXPECT_STREQ(message->channel, "test");
        EXPECT_EQ(memcmp(message->message, test_message.bytes, message->message_size), 0);
        return kSuccess;
      }));

  [engine.binaryMessenger sendOnChannel:@"test" message:test_message];
  EXPECT_TRUE(called);

  [engine shutDownEngine];
}

TEST(FlutterEngine, CanToggleAccessibility) {
  FlutterEngine* engine = CreateTestEngine();
  // Capture the update callbacks before the embedder API initializes.
  auto original_init = engine.embedderAPI.Initialize;
  std::function<void(const FlutterSemanticsNode*, void*)> update_node_callback;
  std::function<void(const FlutterSemanticsCustomAction*, void*)> update_action_callback;
  engine.embedderAPI.Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&update_action_callback, &update_node_callback, &original_init](
                       size_t version, const FlutterRendererConfig* config,
                       const FlutterProjectArgs* args, void* user_data, auto engine_out) {
        update_node_callback = args->update_semantics_node_callback;
        update_action_callback = args->update_semantics_custom_action_callback;
        return original_init(version, config, args, user_data, engine_out);
      }));
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);
  // Set up view controller.
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];
  FlutterViewController* viewController = [[FlutterViewController alloc] initWithProject:project];
  [engine setViewController:viewController];
  // Enable the semantics.
  bool enabled_called = false;
  engine.embedderAPI.UpdateSemanticsEnabled =
      MOCK_ENGINE_PROC(UpdateSemanticsEnabled, ([&enabled_called](auto engine, bool enabled) {
                         enabled_called = enabled;
                         return kSuccess;
                       }));
  engine.semanticsEnabled = YES;
  EXPECT_TRUE(enabled_called);
  // Send flutter semantics updates.
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
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  update_node_callback(&root, (void*)CFBridgingRetain(engine));

  FlutterSemanticsNode child1;
  child1.id = 1;
  child1.flags = static_cast<FlutterSemanticsFlag>(0);
  child1.actions = static_cast<FlutterSemanticsAction>(0);
  child1.text_selection_base = -1;
  child1.text_selection_extent = -1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;
  update_node_callback(&child1, (void*)CFBridgingRetain(engine));

  FlutterSemanticsNode node_batch_end;
  node_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_node_callback(&node_batch_end, (void*)CFBridgingRetain(engine));

  FlutterSemanticsCustomAction action_batch_end;
  action_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_action_callback(&action_batch_end, (void*)CFBridgingRetain(engine));

  // Verify the accessibility tree is attached to the flutter view.
  EXPECT_EQ([engine.viewController.view.accessibilityChildren count], 1u);
  NSAccessibilityElement* native_root = engine.viewController.view.accessibilityChildren[0];
  std::string root_label = [native_root.accessibilityLabel UTF8String];
  EXPECT_TRUE(root_label == "root");
  EXPECT_EQ(native_root.accessibilityRole, NSAccessibilityGroupRole);
  EXPECT_EQ([native_root.accessibilityChildren count], 1u);
  NSAccessibilityElement* native_child1 = native_root.accessibilityChildren[0];
  std::string child1_value = [native_child1.accessibilityValue UTF8String];
  EXPECT_TRUE(child1_value == "child 1");
  EXPECT_EQ(native_child1.accessibilityRole, NSAccessibilityStaticTextRole);
  EXPECT_EQ([native_child1.accessibilityChildren count], 0u);

  // Disable the semantics.
  bool semanticsEnabled = true;
  engine.embedderAPI.UpdateSemanticsEnabled =
      MOCK_ENGINE_PROC(UpdateSemanticsEnabled, ([&semanticsEnabled](auto engine, bool enabled) {
                         semanticsEnabled = enabled;
                         return kSuccess;
                       }));
  engine.semanticsEnabled = NO;
  EXPECT_FALSE(semanticsEnabled);
  // Verify the accessibility tree is removed from the view.
  EXPECT_EQ([engine.viewController.view.accessibilityChildren count], 0u);

  [engine setViewController:nil];
  [engine shutDownEngine];
}

TEST(FlutterEngine, CanToggleAccessibilityWhenHeadless) {
  FlutterEngine* engine = CreateTestEngine();
  // Capture the update callbacks before the embedder API initializes.
  auto original_init = engine.embedderAPI.Initialize;
  std::function<void(const FlutterSemanticsNode*, void*)> update_node_callback;
  std::function<void(const FlutterSemanticsCustomAction*, void*)> update_action_callback;
  engine.embedderAPI.Initialize = MOCK_ENGINE_PROC(
      Initialize, ([&update_action_callback, &update_node_callback, &original_init](
                       size_t version, const FlutterRendererConfig* config,
                       const FlutterProjectArgs* args, void* user_data, auto engine_out) {
        update_node_callback = args->update_semantics_node_callback;
        update_action_callback = args->update_semantics_custom_action_callback;
        return original_init(version, config, args, user_data, engine_out);
      }));
  EXPECT_TRUE([engine runWithEntrypoint:@"main"]);

  // Enable the semantics without attaching a view controller.
  bool enabled_called = false;
  engine.embedderAPI.UpdateSemanticsEnabled =
      MOCK_ENGINE_PROC(UpdateSemanticsEnabled, ([&enabled_called](auto engine, bool enabled) {
                         enabled_called = enabled;
                         return kSuccess;
                       }));
  engine.semanticsEnabled = YES;
  EXPECT_TRUE(enabled_called);
  // Send flutter semantics updates.
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
  root.child_count = 1;
  int32_t children[] = {1};
  root.children_in_traversal_order = children;
  root.custom_accessibility_actions_count = 0;
  update_node_callback(&root, (void*)CFBridgingRetain(engine));

  FlutterSemanticsNode child1;
  child1.id = 1;
  child1.flags = static_cast<FlutterSemanticsFlag>(0);
  child1.actions = static_cast<FlutterSemanticsAction>(0);
  child1.text_selection_base = -1;
  child1.text_selection_extent = -1;
  child1.label = "child 1";
  child1.hint = "";
  child1.value = "";
  child1.increased_value = "";
  child1.decreased_value = "";
  child1.child_count = 0;
  child1.custom_accessibility_actions_count = 0;
  update_node_callback(&child1, (void*)CFBridgingRetain(engine));

  FlutterSemanticsNode node_batch_end;
  node_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_node_callback(&node_batch_end, (void*)CFBridgingRetain(engine));

  FlutterSemanticsCustomAction action_batch_end;
  action_batch_end.id = kFlutterSemanticsNodeIdBatchEnd;
  update_action_callback(&action_batch_end, (void*)CFBridgingRetain(engine));

  // No crashes.
  EXPECT_EQ(engine.viewController, nil);

  // Disable the semantics.
  bool semanticsEnabled = true;
  engine.embedderAPI.UpdateSemanticsEnabled =
      MOCK_ENGINE_PROC(UpdateSemanticsEnabled, ([&semanticsEnabled](auto engine, bool enabled) {
                         semanticsEnabled = enabled;
                         return kSuccess;
                       }));
  engine.semanticsEnabled = NO;
  EXPECT_FALSE(semanticsEnabled);
  // Still no crashes
  EXPECT_EQ(engine.viewController, nil);
  [engine shutDownEngine];
}

}  // namespace flutter::testing
