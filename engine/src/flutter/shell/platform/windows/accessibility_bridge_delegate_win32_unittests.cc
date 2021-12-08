// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/accessibility_bridge_delegate_win32.h"

#include <comdef.h>
#include <comutil.h>
#include <oleacc.h>

#include <vector>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/windows/flutter_platform_node_delegate_win32.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/shell/platform/windows/testing/engine_modifier.h"
#include "flutter/shell/platform/windows/testing/mock_window_binding_handler.h"
#include "flutter/shell/platform/windows/testing/test_keyboard.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {

// Returns an engine instance configured with dummy project path values, and
// overridden methods for sending platform messages, so that the engine can
// respond as if the framework were connected.
std::unique_ptr<FlutterWindowsEngine> GetTestEngine() {
  FlutterDesktopEngineProperties properties = {};
  properties.assets_path = L"C:\\foo\\flutter_assets";
  properties.icu_data_path = L"C:\\foo\\icudtl.dat";
  properties.aot_library_path = L"C:\\foo\\aot.so";
  FlutterProjectBundle project(properties);
  auto engine = std::make_unique<FlutterWindowsEngine>(project);

  EngineModifier modifier(engine.get());
  modifier.embedder_api().UpdateSemanticsEnabled =
      [](FLUTTER_API_SYMBOL(FlutterEngine) engine, bool enabled) {
        return kSuccess;
      };
  MockEmbedderApiForKeyboard(
      modifier, [] { return false; },
      [](const FlutterKeyEvent* event) { return false; });

  engine->RunWithEntrypoint(nullptr);
  return engine;
}

// Populates the AXTree associated with the specified bridge with test data.
//
//        node0
//        /   \
//    node1    node2
//             /   \
//         node3   node4
//
// node0 and node2 are grouping nodes. node1 and node2 are static text nodes.
// node4 is a static text node with no text, and hence has the "ignored" state.
void PopulateAXTree(std::shared_ptr<AccessibilityBridge> bridge) {
  // Add node 0: root.
  FlutterSemanticsNode node0{sizeof(FlutterSemanticsNode), 0};
  std::vector<int32_t> node0_children{1, 2};
  node0.child_count = node0_children.size();
  node0.children_in_traversal_order = node0_children.data();
  node0.children_in_hit_test_order = node0_children.data();

  // Add node 1: text child of node 0.
  FlutterSemanticsNode node1{sizeof(FlutterSemanticsNode), 1};
  node1.label = "prefecture";
  node1.value = "Kyoto";

  // Add node 2: subtree child of node 0.
  FlutterSemanticsNode node2{sizeof(FlutterSemanticsNode), 2};
  std::vector<int32_t> node2_children{3, 4};
  node2.child_count = node2_children.size();
  node2.children_in_traversal_order = node2_children.data();
  node2.children_in_hit_test_order = node2_children.data();

  // Add node 3: text child of node 2.
  FlutterSemanticsNode node3{sizeof(FlutterSemanticsNode), 3};
  node3.label = "city";
  node3.value = "Uji";

  // Add node 4: text child (with no text) of node 2.
  FlutterSemanticsNode node4{sizeof(FlutterSemanticsNode), 4};

  bridge->AddFlutterSemanticsNodeUpdate(&node0);
  bridge->AddFlutterSemanticsNodeUpdate(&node1);
  bridge->AddFlutterSemanticsNodeUpdate(&node2);
  bridge->AddFlutterSemanticsNodeUpdate(&node3);
  bridge->AddFlutterSemanticsNodeUpdate(&node4);
  bridge->CommitUpdates();
}

}  // namespace

TEST(AccessibilityBridgeDelegateWin32, NodeDelegateHasUniqueId) {
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(GetTestEngine());
  view.OnUpdateSemanticsEnabled(true);

  auto bridge = view.GetEngine()->accessibility_bridge().lock();
  PopulateAXTree(bridge);

  auto node0_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  auto node1_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  EXPECT_TRUE(node0_delegate->GetUniqueId() != node1_delegate->GetUniqueId());
}

TEST(AccessibilityBridgeDelegateWin32, DispatchAccessibilityAction) {
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(GetTestEngine());
  view.OnUpdateSemanticsEnabled(true);

  auto bridge = view.GetEngine()->accessibility_bridge().lock();
  PopulateAXTree(bridge);

  FlutterSemanticsAction actual_action = kFlutterSemanticsActionTap;
  EngineModifier modifier(view.GetEngine());
  modifier.embedder_api().DispatchSemanticsAction = MOCK_ENGINE_PROC(
      DispatchSemanticsAction,
      ([&actual_action](FLUTTER_API_SYMBOL(FlutterEngine) engine, uint64_t id,
                        FlutterSemanticsAction action, const uint8_t* data,
                        size_t data_length) {
        actual_action = action;
        return kSuccess;
      }));

  AccessibilityBridgeDelegateWin32 delegate(view.GetEngine());
  delegate.DispatchAccessibilityAction(1, kFlutterSemanticsActionCopy, {});
  EXPECT_EQ(actual_action, kFlutterSemanticsActionCopy);
}

}  // namespace testing
}  // namespace flutter
