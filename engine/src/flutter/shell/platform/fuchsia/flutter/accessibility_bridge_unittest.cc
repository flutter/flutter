// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/fuchsia/flutter/accessibility_bridge.h"

#include <gtest/gtest.h>
#include <lib/async-loop/cpp/loop.h>
#include <lib/async-loop/default.h>
#include <lib/fidl/cpp/binding_set.h>
#include <lib/fidl/cpp/interface_request.h>
#include <lib/sys/cpp/testing/service_directory_provider.h>
#include <zircon/types.h>

#include <memory>

#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/shell/platform/fuchsia/flutter/flutter_runner_fakes.h"

namespace flutter_runner_test {

class AccessibilityBridgeTestDelegate
    : public flutter_runner::AccessibilityBridge::Delegate {
 public:
  void SetSemanticsEnabled(bool enabled) override { enabled_ = enabled; }
  void DispatchSemanticsAction(int32_t node_id,
                               flutter::SemanticsAction action) override {
    actions.push_back(std::make_pair(node_id, action));
  }

  bool enabled() { return enabled_; }
  std::vector<std::pair<int32_t, flutter::SemanticsAction>> actions;

 private:
  bool enabled_;
};

class AccessibilityBridgeTest : public testing::Test {
 public:
  AccessibilityBridgeTest()
      : loop_(&kAsyncLoopConfigAttachToCurrentThread),
        services_provider_(loop_.dispatcher()) {
    services_provider_.AddService(
        semantics_manager_.GetHandler(loop_.dispatcher()),
        SemanticsManager::Name_);
  }

  void RunLoopUntilIdle() {
    loop_.RunUntilIdle();
    loop_.ResetQuit();
  }

 protected:
  void SetUp() override {
    zx_status_t status = zx::eventpair::create(
        /*flags*/ 0u, &view_ref_control_.reference, &view_ref_.reference);
    EXPECT_EQ(status, ZX_OK);

    accessibility_delegate_.actions.clear();
    accessibility_bridge_ =
        std::make_unique<flutter_runner::AccessibilityBridge>(
            accessibility_delegate_, services_provider_.service_directory(),
            std::move(view_ref_));
    RunLoopUntilIdle();
  }

  void TearDown() override { semantics_manager_.ResetTree(); }

  fuchsia::ui::views::ViewRefControl view_ref_control_;
  fuchsia::ui::views::ViewRef view_ref_;
  MockSemanticsManager semantics_manager_;
  AccessibilityBridgeTestDelegate accessibility_delegate_;
  std::unique_ptr<flutter_runner::AccessibilityBridge> accessibility_bridge_;

 private:
  async::Loop loop_;
  sys::testing::ServiceDirectoryProvider services_provider_;
};

TEST_F(AccessibilityBridgeTest, RegistersViewRef) {
  EXPECT_TRUE(semantics_manager_.RegisterViewCalled());
}

TEST_F(AccessibilityBridgeTest, EnableDisable) {
  EXPECT_FALSE(accessibility_delegate_.enabled());
  std::unique_ptr<fuchsia::accessibility::semantics::SemanticListener> listener(
      accessibility_bridge_.release());
  listener->OnSemanticsModeChanged(true, nullptr);
  EXPECT_TRUE(accessibility_delegate_.enabled());
}

TEST_F(AccessibilityBridgeTest, DeletesChildrenTransitively) {
  // Test that when a node is deleted, so are its transitive children.
  flutter::SemanticsNode node2;
  node2.id = 2;

  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.childrenInTraversalOrder = {2};
  node1.childrenInHitTestOrder = {2};

  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.childrenInTraversalOrder = {1};
  node0.childrenInHitTestOrder = {1};

  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
      {2, node2},
  });
  RunLoopUntilIdle();

  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(1, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_EQ(3U, semantics_manager_.LastUpdatedNodes().size());
  EXPECT_EQ(0U, semantics_manager_.LastDeletedNodeIds().size());
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());

  // Remove the children
  node0.childrenInTraversalOrder.clear();
  node0.childrenInHitTestOrder.clear();
  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
  });
  RunLoopUntilIdle();

  EXPECT_EQ(1, semantics_manager_.DeleteCount());
  EXPECT_EQ(2, semantics_manager_.UpdateCount());
  EXPECT_EQ(2, semantics_manager_.CommitCount());
  EXPECT_EQ(1U, semantics_manager_.LastUpdatedNodes().size());
  ASSERT_EQ(std::vector<uint32_t>({1, 2}),
            semantics_manager_.LastDeletedNodeIds());
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}

TEST_F(AccessibilityBridgeTest, PopulatesCheckedState) {
  flutter::SemanticsNode node0;
  node0.id = 0;
  // HasCheckedState = true
  // IsChecked = true
  // IsSelected = false
  // IsHidden = false
  node0.flags |= static_cast<int>(flutter::SemanticsFlags::kHasCheckedState);
  node0.flags |= static_cast<int>(flutter::SemanticsFlags::kIsChecked);
  node0.value = "value";

  accessibility_bridge_->AddSemanticsNodeUpdate({{0, node0}});
  RunLoopUntilIdle();

  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(1, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_EQ(1U, semantics_manager_.LastUpdatedNodes().size());
  const auto& fuchsia_node = semantics_manager_.LastUpdatedNodes().at(0u);
  EXPECT_EQ(fuchsia_node.node_id(), static_cast<unsigned int>(node0.id));
  EXPECT_TRUE(fuchsia_node.has_states());
  const auto& states = fuchsia_node.states();
  EXPECT_TRUE(states.has_checked_state());
  EXPECT_EQ(states.checked_state(),
            fuchsia::accessibility::semantics::CheckedState::CHECKED);
  EXPECT_TRUE(states.has_selected());
  EXPECT_FALSE(states.selected());
  EXPECT_TRUE(states.has_hidden());
  EXPECT_FALSE(states.hidden());
  EXPECT_TRUE(states.has_value());
  EXPECT_EQ(states.value(), node0.value);

  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}

TEST_F(AccessibilityBridgeTest, PopulatesSelectedState) {
  flutter::SemanticsNode node0;
  node0.id = 0;
  // HasCheckedState = false
  // IsChecked = false
  // IsSelected = true
  // IsHidden = false
  node0.flags = static_cast<int>(flutter::SemanticsFlags::kIsSelected);

  accessibility_bridge_->AddSemanticsNodeUpdate({{0, node0}});
  RunLoopUntilIdle();

  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(1, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_EQ(1U, semantics_manager_.LastUpdatedNodes().size());
  const auto& fuchsia_node = semantics_manager_.LastUpdatedNodes().at(0u);
  EXPECT_EQ(fuchsia_node.node_id(), static_cast<unsigned int>(node0.id));
  EXPECT_TRUE(fuchsia_node.has_states());
  const auto& states = fuchsia_node.states();
  EXPECT_TRUE(states.has_checked_state());
  EXPECT_EQ(states.checked_state(),
            fuchsia::accessibility::semantics::CheckedState::NONE);
  EXPECT_TRUE(states.has_selected());
  EXPECT_TRUE(states.selected());
  EXPECT_TRUE(states.has_hidden());
  EXPECT_FALSE(states.hidden());

  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}

TEST_F(AccessibilityBridgeTest, PopulatesHiddenState) {
  flutter::SemanticsNode node0;
  node0.id = 0;
  // HasCheckedState = false
  // IsChecked = false
  // IsSelected = false
  // IsHidden = true
  node0.flags = static_cast<int>(flutter::SemanticsFlags::kIsHidden);

  accessibility_bridge_->AddSemanticsNodeUpdate({{0, node0}});
  RunLoopUntilIdle();

  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(1, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_EQ(1u, semantics_manager_.LastUpdatedNodes().size());
  const auto& fuchsia_node = semantics_manager_.LastUpdatedNodes().at(0u);
  EXPECT_EQ(fuchsia_node.node_id(), static_cast<unsigned int>(node0.id));
  EXPECT_TRUE(fuchsia_node.has_states());
  const auto& states = fuchsia_node.states();
  EXPECT_TRUE(states.has_checked_state());
  EXPECT_EQ(states.checked_state(),
            fuchsia::accessibility::semantics::CheckedState::NONE);
  EXPECT_TRUE(states.has_selected());
  EXPECT_FALSE(states.selected());
  EXPECT_TRUE(states.has_hidden());
  EXPECT_TRUE(states.hidden());

  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}

TEST_F(AccessibilityBridgeTest, TruncatesLargeLabel) {
  // Test that labels which are too long are truncated.
  flutter::SemanticsNode node0;
  node0.id = 0;

  flutter::SemanticsNode node1;
  node1.id = 1;

  flutter::SemanticsNode bad_node;
  bad_node.id = 2;
  bad_node.label =
      std::string(fuchsia::accessibility::semantics::MAX_LABEL_SIZE + 1, '2');

  node0.childrenInTraversalOrder = {1, 2};
  node0.childrenInHitTestOrder = {1, 2};

  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
      {2, bad_node},
  });
  RunLoopUntilIdle();

  // Nothing to delete, but we should have broken
  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(1, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_EQ(3U, semantics_manager_.LastUpdatedNodes().size());
  auto trimmed_node =
      std::find_if(semantics_manager_.LastUpdatedNodes().begin(),
                   semantics_manager_.LastUpdatedNodes().end(),
                   [id = static_cast<uint32_t>(bad_node.id)](
                       fuchsia::accessibility::semantics::Node const& node) {
                     return node.node_id() == id;
                   });
  ASSERT_NE(trimmed_node, semantics_manager_.LastUpdatedNodes().end());
  ASSERT_TRUE(trimmed_node->has_attributes());
  EXPECT_EQ(
      trimmed_node->attributes().label(),
      std::string(fuchsia::accessibility::semantics::MAX_LABEL_SIZE, '2'));
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}

TEST_F(AccessibilityBridgeTest, TruncatesLargeValue) {
  // Test that values which are too long are truncated.
  flutter::SemanticsNode node0;
  node0.id = 0;

  flutter::SemanticsNode node1;
  node1.id = 1;

  flutter::SemanticsNode bad_node;
  bad_node.id = 2;
  bad_node.value =
      std::string(fuchsia::accessibility::semantics::MAX_VALUE_SIZE + 1, '2');

  node0.childrenInTraversalOrder = {1, 2};
  node0.childrenInHitTestOrder = {1, 2};

  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
      {2, bad_node},
  });
  RunLoopUntilIdle();

  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(1, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_EQ(3U, semantics_manager_.LastUpdatedNodes().size());
  auto trimmed_node =
      std::find_if(semantics_manager_.LastUpdatedNodes().begin(),
                   semantics_manager_.LastUpdatedNodes().end(),
                   [id = static_cast<uint32_t>(bad_node.id)](
                       fuchsia::accessibility::semantics::Node const& node) {
                     return node.node_id() == id;
                   });
  ASSERT_NE(trimmed_node, semantics_manager_.LastUpdatedNodes().end());
  ASSERT_TRUE(trimmed_node->has_states());
  EXPECT_EQ(
      trimmed_node->states().value(),
      std::string(fuchsia::accessibility::semantics::MAX_VALUE_SIZE, '2'));
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}

TEST_F(AccessibilityBridgeTest, SplitsLargeUpdates) {
  // Test that labels which are too long are truncated.
  flutter::SemanticsNode node0;
  node0.id = 0;

  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.label =
      std::string(fuchsia::accessibility::semantics::MAX_LABEL_SIZE, '1');

  flutter::SemanticsNode node2;
  node2.id = 2;
  node2.label = "2";

  flutter::SemanticsNode node3;
  node3.id = 3;
  node3.label = "3";

  flutter::SemanticsNode node4;
  node4.id = 4;
  node4.value =
      std::string(fuchsia::accessibility::semantics::MAX_VALUE_SIZE, '4');

  node0.childrenInTraversalOrder = {1, 2};
  node0.childrenInHitTestOrder = {1, 2};
  node1.childrenInTraversalOrder = {3, 4};
  node1.childrenInHitTestOrder = {3, 4};

  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
      {2, node2},
      {3, node3},
      {4, node4},
  });
  RunLoopUntilIdle();

  // Nothing to delete, but we should have broken into groups (4, 3, 2), (1, 0)
  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(2, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_EQ(2U, semantics_manager_.LastUpdatedNodes().size());
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}

TEST_F(AccessibilityBridgeTest, HandlesCycles) {
  // Test that cycles don't cause fatal error.
  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.childrenInTraversalOrder.push_back(0);
  node0.childrenInHitTestOrder.push_back(0);
  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
  });
  RunLoopUntilIdle();

  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(1, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());

  node0.childrenInTraversalOrder = {0, 1};
  node0.childrenInHitTestOrder = {0, 1};
  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.childrenInTraversalOrder = {0};
  node1.childrenInHitTestOrder = {0};
  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
  });
  RunLoopUntilIdle();

  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(2, semantics_manager_.UpdateCount());
  EXPECT_EQ(2, semantics_manager_.CommitCount());
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}

TEST_F(AccessibilityBridgeTest, BatchesLargeMessages) {
  // Tests that messages get batched appropriately.
  flutter::SemanticsNode node0;
  node0.id = 0;

  flutter::SemanticsNodeUpdates update;

  const int32_t child_nodes = 100;
  const int32_t leaf_nodes = 100;
  for (int32_t i = 1; i < child_nodes + 1; i++) {
    flutter::SemanticsNode node;
    node.id = i;
    node0.childrenInTraversalOrder.push_back(i);
    node0.childrenInHitTestOrder.push_back(i);
    for (int32_t j = 0; j < leaf_nodes; j++) {
      flutter::SemanticsNode leaf_node;
      int id = (i * child_nodes) + ((j + 1) * leaf_nodes);
      leaf_node.id = id;
      leaf_node.label = "A relatively simple label";
      node.childrenInTraversalOrder.push_back(id);
      node.childrenInHitTestOrder.push_back(id);
      update.insert(std::make_pair(id, std::move(leaf_node)));
    }
    update.insert(std::make_pair(i, std::move(node)));
  }

  update.insert(std::make_pair(0, std::move(node0)));
  accessibility_bridge_->AddSemanticsNodeUpdate(update);
  RunLoopUntilIdle();

  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(5, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());

  // Remove the children
  node0.childrenInTraversalOrder.clear();
  node0.childrenInHitTestOrder.clear();
  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
  });
  RunLoopUntilIdle();

  EXPECT_EQ(1, semantics_manager_.DeleteCount());
  EXPECT_EQ(6, semantics_manager_.UpdateCount());
  EXPECT_EQ(2, semantics_manager_.CommitCount());
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}

TEST_F(AccessibilityBridgeTest, HitTest) {
  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.rect.setLTRB(0, 0, 100, 100);

  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.rect.setLTRB(10, 10, 20, 20);

  flutter::SemanticsNode node2;
  node2.id = 2;
  node2.rect.setLTRB(25, 10, 45, 20);

  flutter::SemanticsNode node3;
  node3.id = 3;
  node3.rect.setLTRB(10, 25, 20, 45);

  flutter::SemanticsNode node4;
  node4.id = 4;
  node4.rect.setLTRB(10, 10, 20, 20);
  node4.transform.setTranslate(20, 20, 0);

  node0.childrenInTraversalOrder = {1, 2, 3, 4};
  node0.childrenInHitTestOrder = {1, 2, 3, 4};

  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
      {2, node2},
      {3, node3},
      {4, node4},
  });
  RunLoopUntilIdle();

  uint32_t hit_node_id;
  auto callback = [&hit_node_id](fuchsia::accessibility::semantics::Hit hit) {
    EXPECT_TRUE(hit.has_node_id());
    hit_node_id = hit.node_id();
  };

  // Nodes are:
  // ----------
  // | 1   2  |
  // | 3   4  |
  // ----------

  accessibility_bridge_->HitTest({1, 1}, callback);
  EXPECT_EQ(hit_node_id, 0u);
  accessibility_bridge_->HitTest({15, 15}, callback);
  EXPECT_EQ(hit_node_id, 1u);
  accessibility_bridge_->HitTest({30, 15}, callback);
  EXPECT_EQ(hit_node_id, 2u);
  accessibility_bridge_->HitTest({15, 30}, callback);
  EXPECT_EQ(hit_node_id, 3u);
  accessibility_bridge_->HitTest({30, 30}, callback);
  EXPECT_EQ(hit_node_id, 4u);
}

TEST_F(AccessibilityBridgeTest, HitTestOverlapping) {
  // Tests that the first node in hit test order wins, even if a later node
  // would be able to recieve the hit.
  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.rect.setLTRB(0, 0, 100, 100);

  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.rect.setLTRB(0, 0, 100, 100);

  flutter::SemanticsNode node2;
  node2.id = 2;
  node2.rect.setLTRB(25, 10, 45, 20);

  node0.childrenInTraversalOrder = {1, 2};
  node0.childrenInHitTestOrder = {2, 1};

  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
      {2, node2},
  });
  RunLoopUntilIdle();

  uint32_t hit_node_id;
  auto callback = [&hit_node_id](fuchsia::accessibility::semantics::Hit hit) {
    EXPECT_TRUE(hit.has_node_id());
    hit_node_id = hit.node_id();
  };

  accessibility_bridge_->HitTest({30, 15}, callback);
  EXPECT_EQ(hit_node_id, 2u);
}

TEST_F(AccessibilityBridgeTest, Actions) {
  flutter::SemanticsNode node0;
  node0.id = 0;

  flutter::SemanticsNode node1;
  node1.id = 1;

  node0.childrenInTraversalOrder = {1};
  node0.childrenInHitTestOrder = {1};

  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
      {1, node1},
  });
  RunLoopUntilIdle();

  auto handled_callback = [](bool handled) { EXPECT_TRUE(handled); };
  auto unhandled_callback = [](bool handled) { EXPECT_FALSE(handled); };

  accessibility_bridge_->OnAccessibilityActionRequested(
      0u, fuchsia::accessibility::semantics::Action::DEFAULT, handled_callback);
  EXPECT_EQ(accessibility_delegate_.actions.size(), 1u);
  EXPECT_EQ(accessibility_delegate_.actions.back(),
            std::make_pair(0, flutter::SemanticsAction::kTap));

  accessibility_bridge_->OnAccessibilityActionRequested(
      0u, fuchsia::accessibility::semantics::Action::SECONDARY,
      handled_callback);
  EXPECT_EQ(accessibility_delegate_.actions.size(), 2u);
  EXPECT_EQ(accessibility_delegate_.actions.back(),
            std::make_pair(0, flutter::SemanticsAction::kLongPress));

  accessibility_bridge_->OnAccessibilityActionRequested(
      0u, fuchsia::accessibility::semantics::Action::SET_FOCUS,
      unhandled_callback);
  EXPECT_EQ(accessibility_delegate_.actions.size(), 2u);

  accessibility_bridge_->OnAccessibilityActionRequested(
      0u, fuchsia::accessibility::semantics::Action::SET_VALUE,
      unhandled_callback);
  EXPECT_EQ(accessibility_delegate_.actions.size(), 2u);

  accessibility_bridge_->OnAccessibilityActionRequested(
      0u, fuchsia::accessibility::semantics::Action::SHOW_ON_SCREEN,
      handled_callback);
  EXPECT_EQ(accessibility_delegate_.actions.size(), 3u);
  EXPECT_EQ(accessibility_delegate_.actions.back(),
            std::make_pair(0, flutter::SemanticsAction::kShowOnScreen));

  accessibility_bridge_->OnAccessibilityActionRequested(
      2u, fuchsia::accessibility::semantics::Action::DEFAULT,
      unhandled_callback);
  EXPECT_EQ(accessibility_delegate_.actions.size(), 3u);
}
}  // namespace flutter_runner_test
