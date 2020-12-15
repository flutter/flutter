// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/stringprintf.h"
#include "base/timer/lap_timer.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/perf/perf_result_reporter.h"
#include "ui/accessibility/ax_node_position.h"
#include "ui/accessibility/ax_tree_id.h"
#include "ui/accessibility/ax_tree_update.h"
#include "ui/accessibility/test_ax_tree_manager.h"

namespace ui {

using TestPositionType = std::unique_ptr<AXPosition<AXNodePosition, AXNode>>;

namespace {

constexpr int kLaps = 5000;
constexpr int kWarmupLaps = 5;
constexpr char kMetricCallsPerSecondRunsPerS[] = "calls_per_second";

class AXPositionPerfTest : public testing::Test, public TestAXTreeManager {
 public:
  AXPositionPerfTest() = default;
  ~AXPositionPerfTest() override = default;

 protected:
  void SetUp() override;

  perf_test::PerfResultReporter SetUpReporter(const std::string& story) {
    perf_test::PerfResultReporter reporter("AXPositionPerfTest.", story);
    reporter.RegisterImportantMetric(kMetricCallsPerSecondRunsPerS, "runs/s");
    return reporter;
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(AXPositionPerfTest);
};

void AXPositionPerfTest::SetUp() {
  // Setup a root with 5 child kGenericContainer with 5 kStaticText each.
  // Each kStaticText contains 5 characters of text.
  //
  // +------------------------+--------------+
  // | Tree Hierarchy + Role  | anchor_id(s) |
  // +------------------------+--------------+
  // | ++kRootWebArea         | 1            |
  // | ++++kGenericContainer  | 2            |
  // | ++++++kStaticText      | 7 - 11       |
  // | ++++kGenericContainer  | 3            |
  // | ++++++kStaticText      | 12 - 16      |
  // | ++++kGenericContainer  | 4            |
  // | ++++++kStaticText      | 17 - 21      |
  // | ++++kGenericContainer  | 5            |
  // | ++++++kStaticText      | 22 - 26      |
  // | ++++kGenericContainer  | 6            |
  // | ++++++kStaticText      | 27 - 31      |
  // +------------------------+--------------+

  constexpr int kNumberOfGroups = 5;
  constexpr int kStaticTextNodesPerGroup = 5;
  constexpr int kNumberOfStaticTextNodes =
      kNumberOfGroups * kStaticTextNodesPerGroup;

  constexpr int kGroupNodesStartIndex = 1;
  constexpr int kStaticTextNodesStartIndex =
      kGroupNodesStartIndex + kNumberOfGroups;

  AXNode::AXID current_id = 0;
  std::vector<AXNodeData> nodes;
  nodes.resize(1 + kNumberOfGroups + kNumberOfStaticTextNodes);

  AXNodeData& root_data = nodes[0];
  root_data.id = ++current_id;
  root_data.role = ax::mojom::Role::kRootWebArea;

  for (int group_index = 0; group_index < kNumberOfGroups; ++group_index) {
    AXNodeData& group = nodes[kGroupNodesStartIndex + group_index];
    group.id = ++current_id;
    group.role = ax::mojom::Role::kGenericContainer;
    root_data.child_ids.push_back(group.id);
  }

  for (int text_index = 0; text_index < kNumberOfStaticTextNodes;
       ++text_index) {
    const int group_index = text_index / kStaticTextNodesPerGroup;
    AXNodeData& group = nodes[kGroupNodesStartIndex + group_index];
    AXNodeData& static_text = nodes[kStaticTextNodesStartIndex + text_index];
    static_text.id = ++current_id;
    static_text.role = ax::mojom::Role::kStaticText;
    static_text.SetName(base::StringPrintf("id_%02X", static_text.id));
    group.child_ids.push_back(static_text.id);
  }

  AXTreeUpdate initial_state;
  initial_state.root_id = nodes[0].id;
  initial_state.nodes = nodes;
  initial_state.has_tree_data = true;
  initial_state.tree_data.tree_id = AXTreeID::CreateNewAXTreeID();
  initial_state.tree_data.title = "Perftest title";

  SetTree(std::make_unique<AXTree>(initial_state));
}

}  // namespace

TEST_F(AXPositionPerfTest, AsTreePositionFromTextPosition) {
  TestPositionType text_position = AXNodePosition::CreateTextPosition(
      GetTreeID(), /*anchor_id=*/1, /*text_offset=*/103,
      ax::mojom::TextAffinity::kDownstream);

  // The time limit is unused. Use kLaps for the check interval so the time is
  // only measured once.
  base::LapTimer timer(kWarmupLaps, base::TimeDelta(), kLaps);
  for (int i = 0; i < kLaps + kWarmupLaps; ++i) {
    TestPositionType as_tree_position = text_position->AsTreePosition();
    timer.NextLap();
  }

  auto reporter = SetUpReporter("AsTreePositionFromTextPosition");
  reporter.AddResult(kMetricCallsPerSecondRunsPerS, timer.LapsPerSecond());
}

TEST_F(AXPositionPerfTest, AsLeafTextPositionFromTextPosition) {
  TestPositionType text_position = AXNodePosition::CreateTextPosition(
      GetTreeID(), /*anchor_id=*/1, /*text_offset=*/103,
      ax::mojom::TextAffinity::kDownstream);

  // The time limit is unused. Use kLaps for the check interval so the time is
  // only measured once.
  base::LapTimer timer(kWarmupLaps, base::TimeDelta(), kLaps);
  for (int i = 0; i < kLaps + kWarmupLaps; ++i) {
    TestPositionType as_tree_position = text_position->AsLeafTextPosition();
    timer.NextLap();
  }

  auto reporter = SetUpReporter("AsLeafTextPositionFromTextPosition");
  reporter.AddResult(kMetricCallsPerSecondRunsPerS, timer.LapsPerSecond());
}

TEST_F(AXPositionPerfTest, AsLeafTextPositionFromTreePosition) {
  TestPositionType tree_position = AXNodePosition::CreateTreePosition(
      GetTreeID(), /*anchor_id=*/1, /*child_index=*/4);

  base::LapTimer timer(kWarmupLaps, base::TimeDelta(), kLaps);
  for (int i = 0; i < kLaps + kWarmupLaps; ++i) {
    TestPositionType as_tree_position = tree_position->AsLeafTextPosition();
    timer.NextLap();
  }

  auto reporter = SetUpReporter("AsLeafTextPositionFromTreePosition");
  reporter.AddResult(kMetricCallsPerSecondRunsPerS, timer.LapsPerSecond());
}

TEST_F(AXPositionPerfTest, CompareTextPositions) {
  TestPositionType text_position_1 = AXNodePosition::CreateTextPosition(
      GetTreeID(), /*anchor_id=*/7, /*text_offset=*/1,
      ax::mojom::TextAffinity::kDownstream);

  TestPositionType text_position_2 = AXNodePosition::CreateTextPosition(
      GetTreeID(), /*anchor_id=*/27, /*text_offset=*/1,
      ax::mojom::TextAffinity::kDownstream);

  base::LapTimer timer(kWarmupLaps, base::TimeDelta(), kLaps);
  for (int i = 0; i < kLaps + kWarmupLaps; ++i) {
    text_position_1->CompareTo(*text_position_2);
    timer.NextLap();
  }

  auto reporter = SetUpReporter("CompareTextPositions");
  reporter.AddResult(kMetricCallsPerSecondRunsPerS, timer.LapsPerSecond());
}

}  // namespace ui
