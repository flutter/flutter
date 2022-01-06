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

// A structure representing a Win32 MSAA event targeting a specified node.
struct MsaaEvent {
  std::shared_ptr<FlutterPlatformNodeDelegateWin32> node_delegate;
  DWORD event_type;
};

// Accessibility bridge delegate that captures events dispatched to the OS.
class AccessibilityBridgeDelegateWin32Spy
    : public AccessibilityBridgeDelegateWin32 {
 public:
  explicit AccessibilityBridgeDelegateWin32Spy(FlutterWindowsEngine* engine)
      : AccessibilityBridgeDelegateWin32(engine) {}

  void DispatchWinAccessibilityEvent(
      std::shared_ptr<FlutterPlatformNodeDelegateWin32> node_delegate,
      DWORD event_type) override {
    dispatched_events_.push_back({node_delegate, event_type});
  }

  void SetFocus(std::shared_ptr<FlutterPlatformNodeDelegateWin32> node_delegate)
      override {
    focused_nodes_.push_back(node_delegate->GetAXNode()->id());
  }

  void Reset() {
    dispatched_events_.clear();
    focused_nodes_.clear();
  }

  const std::vector<MsaaEvent>& dispatched_events() const {
    return dispatched_events_;
  }

  const std::vector<int32_t> focused_nodes() const { return focused_nodes_; }

 private:
  std::vector<MsaaEvent> dispatched_events_;
  std::vector<int32_t> focused_nodes_;
};

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

  MockEmbedderApiForKeyboard(modifier,
                             std::make_shared<MockKeyResponseController>());

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

ui::AXNode* AXNodeFromID(std::shared_ptr<AccessibilityBridge> bridge,
                         int32_t id) {
  auto node_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(id).lock();
  return node_delegate ? node_delegate->GetAXNode() : nullptr;
}

void ExpectWinEventFromAXEvent(int32_t node_id,
                               ui::AXEventGenerator::Event ax_event,
                               DWORD expected_event) {
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(GetTestEngine());
  view.OnUpdateSemanticsEnabled(true);

  auto bridge = view.GetEngine()->accessibility_bridge().lock();
  PopulateAXTree(bridge);

  AccessibilityBridgeDelegateWin32Spy spy(view.GetEngine());
  spy.OnAccessibilityEvent({AXNodeFromID(bridge, node_id),
                            {ax_event, ax::mojom::EventFrom::kNone, {}}});
  ASSERT_EQ(spy.dispatched_events().size(), 1);
  EXPECT_EQ(spy.dispatched_events()[0].event_type, expected_event);
}

}  // namespace

TEST(AccessibilityBridgeDelegateWin32, GetParent) {
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(GetTestEngine());
  view.OnUpdateSemanticsEnabled(true);

  auto bridge = view.GetEngine()->accessibility_bridge().lock();
  PopulateAXTree(bridge);

  auto node0_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  auto node1_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(1).lock();
  EXPECT_EQ(node0_delegate->GetNativeViewAccessible(),
            node1_delegate->GetParent());
}

TEST(AccessibilityBridgeDelegateWin32, GetParentOnRootRetunsNullptr) {
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(GetTestEngine());
  view.OnUpdateSemanticsEnabled(true);

  auto bridge = view.GetEngine()->accessibility_bridge().lock();
  PopulateAXTree(bridge);

  auto node0_delegate = bridge->GetFlutterPlatformNodeDelegateFromID(0).lock();
  ASSERT_TRUE(node0_delegate->GetParent() == nullptr);
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

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityEventAlert) {
  ExpectWinEventFromAXEvent(0, ui::AXEventGenerator::Event::ALERT,
                            EVENT_SYSTEM_ALERT);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityEventChildrenChanged) {
  ExpectWinEventFromAXEvent(0, ui::AXEventGenerator::Event::CHILDREN_CHANGED,
                            EVENT_OBJECT_REORDER);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityEventFocusChanged) {
  auto window_binding_handler =
      std::make_unique<::testing::NiceMock<MockWindowBindingHandler>>();
  FlutterWindowsView view(std::move(window_binding_handler));
  view.SetEngine(GetTestEngine());
  view.OnUpdateSemanticsEnabled(true);

  auto bridge = view.GetEngine()->accessibility_bridge().lock();
  PopulateAXTree(bridge);

  AccessibilityBridgeDelegateWin32Spy spy(view.GetEngine());
  spy.OnAccessibilityEvent({AXNodeFromID(bridge, 1),
                            {ui::AXEventGenerator::Event::FOCUS_CHANGED,
                             ax::mojom::EventFrom::kNone,
                             {}}});
  ASSERT_EQ(spy.dispatched_events().size(), 1);
  EXPECT_EQ(spy.dispatched_events()[0].event_type, EVENT_OBJECT_FOCUS);

  ASSERT_EQ(spy.focused_nodes().size(), 1);
  EXPECT_EQ(spy.focused_nodes()[0], 1);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityEventIgnoredChanged) {
  // Static test nodes with no text, hint, or scrollability are ignored.
  ExpectWinEventFromAXEvent(4, ui::AXEventGenerator::Event::IGNORED_CHANGED,
                            EVENT_OBJECT_HIDE);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityImageAnnotationChanged) {
  ExpectWinEventFromAXEvent(
      1, ui::AXEventGenerator::Event::IMAGE_ANNOTATION_CHANGED,
      EVENT_OBJECT_NAMECHANGE);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityLiveRegionChanged) {
  ExpectWinEventFromAXEvent(1, ui::AXEventGenerator::Event::LIVE_REGION_CHANGED,
                            EVENT_OBJECT_LIVEREGIONCHANGED);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityNameChanged) {
  ExpectWinEventFromAXEvent(1, ui::AXEventGenerator::Event::NAME_CHANGED,
                            EVENT_OBJECT_NAMECHANGE);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityHScrollPosChanged) {
  ExpectWinEventFromAXEvent(
      1, ui::AXEventGenerator::Event::SCROLL_HORIZONTAL_POSITION_CHANGED,
      EVENT_SYSTEM_SCROLLINGEND);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityVScrollPosChanged) {
  ExpectWinEventFromAXEvent(
      1, ui::AXEventGenerator::Event::SCROLL_VERTICAL_POSITION_CHANGED,
      EVENT_SYSTEM_SCROLLINGEND);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilitySelectedChanged) {
  ExpectWinEventFromAXEvent(1, ui::AXEventGenerator::Event::SELECTED_CHANGED,
                            EVENT_OBJECT_VALUECHANGE);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilitySelectedChildrenChanged) {
  ExpectWinEventFromAXEvent(
      2, ui::AXEventGenerator::Event::SELECTED_CHILDREN_CHANGED,
      EVENT_OBJECT_SELECTIONWITHIN);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilitySubtreeCreated) {
  ExpectWinEventFromAXEvent(0, ui::AXEventGenerator::Event::SUBTREE_CREATED,
                            EVENT_OBJECT_SHOW);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityValueChanged) {
  ExpectWinEventFromAXEvent(1, ui::AXEventGenerator::Event::VALUE_CHANGED,
                            EVENT_OBJECT_VALUECHANGE);
}

TEST(AccessibilityBridgeDelegateWin32, OnAccessibilityStateChanged) {
  ExpectWinEventFromAXEvent(
      1, ui::AXEventGenerator::Event::WIN_IACCESSIBLE_STATE_CHANGED,
      EVENT_OBJECT_STATECHANGE);
}

}  // namespace testing
}  // namespace flutter
