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
  bool enabled() { return enabled_; }

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

  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.childrenInTraversalOrder = {1};

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
  node4.label =
      std::string(fuchsia::accessibility::semantics::MAX_LABEL_SIZE, '4');

  node0.childrenInTraversalOrder = {1, 2};
  node1.childrenInTraversalOrder = {3, 4};

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
  flutter::SemanticsNode node1;
  node1.id = 1;
  node1.childrenInTraversalOrder = {0};
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

  const int32_t child_nodes = fuchsia::accessibility::semantics::MAX_FAN_OUT;
  const int32_t leaf_nodes = fuchsia::accessibility::semantics::MAX_FAN_OUT;
  for (int32_t i = 1; i < child_nodes + 1; i++) {
    flutter::SemanticsNode node;
    node.id = i;
    node0.childrenInTraversalOrder.push_back(i);
    for (int32_t j = 0; j < leaf_nodes; j++) {
      flutter::SemanticsNode leaf_node;
      int id = (i * child_nodes) + ((j + 1) * leaf_nodes);
      leaf_node.id = id;
      leaf_node.label = "A relatively simple label";
      node.childrenInTraversalOrder.push_back(id);
      update.insert(std::make_pair(id, std::move(leaf_node)));
    }
    update.insert(std::make_pair(i, std::move(node)));
  }

  update.insert(std::make_pair(0, std::move(node0)));
  accessibility_bridge_->AddSemanticsNodeUpdate(update);
  RunLoopUntilIdle();

  EXPECT_EQ(0, semantics_manager_.DeleteCount());
  EXPECT_EQ(13, semantics_manager_.UpdateCount());
  EXPECT_EQ(1, semantics_manager_.CommitCount());
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());

  // Remove the children
  node0.childrenInTraversalOrder.clear();
  accessibility_bridge_->AddSemanticsNodeUpdate({
      {0, node0},
  });
  RunLoopUntilIdle();

  EXPECT_EQ(1, semantics_manager_.DeleteCount());
  EXPECT_EQ(14, semantics_manager_.UpdateCount());
  EXPECT_EQ(2, semantics_manager_.CommitCount());
  EXPECT_FALSE(semantics_manager_.DeleteOverflowed());
  EXPECT_FALSE(semantics_manager_.UpdateOverflowed());
}
}  // namespace flutter_runner_test
