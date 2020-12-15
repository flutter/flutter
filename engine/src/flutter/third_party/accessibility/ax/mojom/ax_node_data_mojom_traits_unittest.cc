// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/mojom/ax_node_data_mojom_traits.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/accessibility/ax_node_data.h"
#include "ui/accessibility/mojom/ax_node_data.mojom.h"
#include "ui/accessibility/mojom/ax_relative_bounds_mojom_traits.h"

using mojo::test::SerializeAndDeserialize;

TEST(AXNodeDataMojomTraitsTest, ID) {
  ui::AXNodeData input, output;
  input.id = 42;
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ(42, output.id);
}

TEST(AXNodeDataMojomTraitsTest, Role) {
  ui::AXNodeData input, output;
  input.role = ax::mojom::Role::kButton;
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ(ax::mojom::Role::kButton, output.role);
}

TEST(AXNodeDataMojomTraitsTest, State) {
  ui::AXNodeData input, output;
  input.state = 0;
  input.AddState(ax::mojom::State::kCollapsed);
  input.AddState(ax::mojom::State::kHorizontal);
  input.AddState(ax::mojom::State::kMaxValue);
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_TRUE(output.HasState(ax::mojom::State::kCollapsed));
  EXPECT_TRUE(output.HasState(ax::mojom::State::kHorizontal));
  EXPECT_TRUE(output.HasState(ax::mojom::State::kMaxValue));
  EXPECT_FALSE(output.HasState(ax::mojom::State::kFocusable));
  EXPECT_FALSE(output.HasState(ax::mojom::State::kMultiline));
}

TEST(AXNodeDataMojomTraitsTest, Actions) {
  ui::AXNodeData input, output;
  input.actions = 0;
  input.AddAction(ax::mojom::Action::kDoDefault);
  input.AddAction(ax::mojom::Action::kDecrement);
  input.AddAction(ax::mojom::Action::kMaxValue);
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_TRUE(output.HasAction(ax::mojom::Action::kDoDefault));
  EXPECT_TRUE(output.HasAction(ax::mojom::Action::kDecrement));
  EXPECT_TRUE(output.HasAction(ax::mojom::Action::kMaxValue));
  EXPECT_FALSE(output.HasAction(ax::mojom::Action::kFocus));
  EXPECT_FALSE(output.HasAction(ax::mojom::Action::kBlur));
}

TEST(AXNodeDataMojomTraitsTest, StringAttributes) {
  ui::AXNodeData input, output;
  input.AddStringAttribute(ax::mojom::StringAttribute::kName, "Mojo");
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ("Mojo",
            output.GetStringAttribute(ax::mojom::StringAttribute::kName));
}

TEST(AXNodeDataMojomTraitsTest, IntAttributes) {
  ui::AXNodeData input, output;
  input.AddIntAttribute(ax::mojom::IntAttribute::kScrollX, 42);
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ(42, output.GetIntAttribute(ax::mojom::IntAttribute::kScrollX));
}

TEST(AXNodeDataMojomTraitsTest, FloatAttributes) {
  ui::AXNodeData input, output;
  input.AddFloatAttribute(ax::mojom::FloatAttribute::kFontSize, 42);
  input.AddFloatAttribute(ax::mojom::FloatAttribute::kFontWeight, 100);
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ(42, output.GetFloatAttribute(ax::mojom::FloatAttribute::kFontSize));
  EXPECT_EQ(100,
            output.GetFloatAttribute(ax::mojom::FloatAttribute::kFontWeight));
}

TEST(AXNodeDataMojomTraitsTest, BoolAttributes) {
  ui::AXNodeData input, output;
  input.AddBoolAttribute(ax::mojom::BoolAttribute::kBusy, true);
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_TRUE(output.GetBoolAttribute(ax::mojom::BoolAttribute::kBusy));
}

TEST(AXNodeDataMojomTraitsTest, IntListAttributes) {
  ui::AXNodeData input, output;
  input.AddIntListAttribute(ax::mojom::IntListAttribute::kControlsIds, {1, 2});
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ(
      std::vector<int32_t>({1, 2}),
      output.GetIntListAttribute(ax::mojom::IntListAttribute::kControlsIds));
}

TEST(AXNodeDataMojomTraitsTest, StringListAttributes) {
  ui::AXNodeData input, output;
  input.AddStringListAttribute(
      ax::mojom::StringListAttribute::kCustomActionDescriptions,
      {"foo", "bar"});
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ(std::vector<std::string>({"foo", "bar"}),
            output.GetStringListAttribute(
                ax::mojom::StringListAttribute::kCustomActionDescriptions));
}

TEST(AXNodeDataMojomTraitsTest, ChildIds) {
  ui::AXNodeData input, output;
  input.child_ids = {3, 4};
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ(std::vector<int32_t>({3, 4}), output.child_ids);
}

TEST(AXNodeDataMojomTraitsTest, OffsetContainerID) {
  ui::AXNodeData input, output;
  input.relative_bounds.offset_container_id = 10;
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ(10, output.relative_bounds.offset_container_id);
}

TEST(AXNodeDataMojomTraitsTest, RelativeBounds) {
  ui::AXNodeData input, output;
  input.relative_bounds.bounds = gfx::RectF(1, 2, 3, 4);
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_EQ(1, output.relative_bounds.bounds.x());
  EXPECT_EQ(2, output.relative_bounds.bounds.y());
  EXPECT_EQ(3, output.relative_bounds.bounds.width());
  EXPECT_EQ(4, output.relative_bounds.bounds.height());
}

TEST(AXNodeDataMojomTraitsTest, Transform) {
  ui::AXNodeData input, output;
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_FALSE(output.relative_bounds.transform);

  input.relative_bounds.transform = std::make_unique<gfx::Transform>();
  input.relative_bounds.transform->Scale(2.0, 2.0);
  EXPECT_TRUE(SerializeAndDeserialize<ax::mojom::AXNodeData>(&input, &output));
  EXPECT_TRUE(output.relative_bounds.transform);
  EXPECT_FALSE(output.relative_bounds.transform->IsIdentity());
}
