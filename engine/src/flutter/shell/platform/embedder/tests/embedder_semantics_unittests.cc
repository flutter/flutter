// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_semantics_update.h"

#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/lib/ui/semantics/string_attribute.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

TEST(EmbedderSemanticsUpdateTest, EmbedderSemanticsUpdate2ExtendedFields) {
  // Representative test constants for semantics node fields and transforms.
  constexpr int32_t kTestNodeId = 7;
  constexpr int32_t kTestMaxValueLength = 100;
  constexpr int32_t kTestCurrentValueLength = 12;
  constexpr float kTestScaleX = 2.0f;
  constexpr float kTestScaleY = 3.0f;
  constexpr float kUnitScaleZ = 1.0f;
  constexpr size_t kSpellOutStartIndex = 0;
  constexpr size_t kSpellOutEndIndex = 4;
  constexpr int32_t kChildId1 = 1;
  constexpr int32_t kChildId2 = 2;
  constexpr int32_t kChildId3 = 3;
  constexpr int64_t kImplicitViewId = 0;
  constexpr size_t kExpectedNodeCount = 1u;
  constexpr size_t kExpectedTraversalChildCount = 2u;
  constexpr size_t kExpectedHitTestChildCount = 3u;
  constexpr size_t kExpectedAttributeCount = 1u;

  SemanticsNode node;
  node.id = kTestNodeId;
  node.flags.isTextField = true;
  node.maxValueLength = kTestMaxValueLength;
  node.currentValueLength = kTestCurrentValueLength;
  node.linkUrl = "https://flutter.dev";
  node.locale = "en-US";
  node.minValue = "10";
  node.maxValue = "90";
  node.hitTestTransform = SkM44::Scale(kTestScaleX, kTestScaleY, kUnitScaleZ);
  node.role = SemanticsRole::kSlider;
  // Simulate an OverlayPortal scenario where traversal order and hit-test order
  // have different child counts.
  node.childrenInTraversalOrder = {kChildId1, kChildId2};
  node.childrenInHitTestOrder = {kChildId2, kChildId1, kChildId3};

  auto spell_out = std::make_shared<SpellOutStringAttribute>();
  spell_out->start = kSpellOutStartIndex;
  spell_out->end = kSpellOutEndIndex;
  spell_out->type = StringAttributeType::kSpellOut;
  node.label = "Test";
  node.labelAttributes = {spell_out};

  SemanticsNodeUpdates nodes;
  nodes.emplace(node.id, node);
  CustomAccessibilityActionUpdates actions;

  EmbedderSemanticsUpdate2 update(kImplicitViewId, nodes, actions);
  FlutterSemanticsUpdate2* c_update = update.get();
  ASSERT_NE(c_update, nullptr);
  ASSERT_EQ(c_update->node_count, kExpectedNodeCount);
  const FlutterSemanticsNode2* c_node = c_update->nodes[0];
  ASSERT_NE(c_node, nullptr);
  EXPECT_EQ(c_node->struct_size, sizeof(FlutterSemanticsNode2));
  ASSERT_NE(c_node->flags2, nullptr);
  EXPECT_EQ(c_node->flags2->struct_size, sizeof(FlutterSemanticsFlags));
  EXPECT_TRUE(c_node->flags2->is_text_field);
  EXPECT_EQ(c_node->max_value_length, kTestMaxValueLength);
  EXPECT_EQ(c_node->current_value_length, kTestCurrentValueLength);
  EXPECT_STREQ(c_node->link_url, "https://flutter.dev");
  EXPECT_STREQ(c_node->locale, "en-US");
  EXPECT_STREQ(c_node->min_value, "10");
  EXPECT_STREQ(c_node->max_value, "90");
  EXPECT_DOUBLE_EQ(c_node->hit_test_transform.scaleX,
                   static_cast<double>(kTestScaleX));
  EXPECT_DOUBLE_EQ(c_node->hit_test_transform.scaleY,
                   static_cast<double>(kTestScaleY));
  EXPECT_EQ(c_node->role, kFlutterSemanticsRoleSlider);
  EXPECT_EQ(c_node->child_count, kExpectedTraversalChildCount);
  EXPECT_EQ(c_node->hit_test_child_count, kExpectedHitTestChildCount);

  ASSERT_EQ(c_node->label_attribute_count, kExpectedAttributeCount);
  ASSERT_NE(c_node->label_attributes, nullptr);
  ASSERT_NE(c_node->label_attributes[0], nullptr);
  EXPECT_EQ(c_node->label_attributes[0]->type,
            FlutterStringAttributeType::kSpellOut);
  ASSERT_NE(c_node->label_attributes[0]->spell_out, nullptr);
  EXPECT_EQ(c_node->label_attributes[0]->spell_out->struct_size,
            sizeof(FlutterSpellOutStringAttribute));
}

TEST(EmbedderSemanticsUpdateTest, EmbedderSemanticsUpdate2RoleMapping) {
  struct RoleMappingCase {
    SemanticsRole engine_role;
    FlutterSemanticsRole expected_embedder_role;
  };

  // Exhaustive mapping table from flutter::SemanticsRole (0..35) to
  // FlutterSemanticsRole (0..35).
  const RoleMappingCase kCases[] = {
      {SemanticsRole::kNone, kFlutterSemanticsRoleNone},
      {SemanticsRole::kTab, kFlutterSemanticsRoleTab},
      {SemanticsRole::kTabBar, kFlutterSemanticsRoleTabBar},
      {SemanticsRole::kTabPanel, kFlutterSemanticsRoleTabPanel},
      {SemanticsRole::kDialog, kFlutterSemanticsRoleDialog},
      {SemanticsRole::kAlertDialog, kFlutterSemanticsRoleAlertDialog},
      {SemanticsRole::kTable, kFlutterSemanticsRoleTable},
      {SemanticsRole::kCell, kFlutterSemanticsRoleCell},
      {SemanticsRole::kRow, kFlutterSemanticsRoleRow},
      {SemanticsRole::kColumnHeader, kFlutterSemanticsRoleColumnHeader},
      {SemanticsRole::kDragHandle, kFlutterSemanticsRoleDragHandle},
      {SemanticsRole::kSpinButton, kFlutterSemanticsRoleSpinButton},
      {SemanticsRole::kComboBox, kFlutterSemanticsRoleComboBox},
      {SemanticsRole::kMenuBar, kFlutterSemanticsRoleMenuBar},
      {SemanticsRole::kMenu, kFlutterSemanticsRoleMenu},
      {SemanticsRole::kMenuItem, kFlutterSemanticsRoleMenuItem},
      {SemanticsRole::kMenuItemCheckbox, kFlutterSemanticsRoleMenuItemCheckbox},
      {SemanticsRole::kMenuItemRadio, kFlutterSemanticsRoleMenuItemRadio},
      {SemanticsRole::kList, kFlutterSemanticsRoleList},
      {SemanticsRole::kListItem, kFlutterSemanticsRoleListItem},
      {SemanticsRole::kForm, kFlutterSemanticsRoleForm},
      {SemanticsRole::kTooltip, kFlutterSemanticsRoleTooltip},
      {SemanticsRole::kLoadingSpinner, kFlutterSemanticsRoleLoadingSpinner},
      {SemanticsRole::kProgressBar, kFlutterSemanticsRoleProgressBar},
      {SemanticsRole::kHotKey, kFlutterSemanticsRoleHotKey},
      {SemanticsRole::kRadioGroup, kFlutterSemanticsRoleRadioGroup},
      {SemanticsRole::kStatus, kFlutterSemanticsRoleStatus},
      {SemanticsRole::kAlert, kFlutterSemanticsRoleAlert},
      {SemanticsRole::kComplementary, kFlutterSemanticsRoleComplementary},
      {SemanticsRole::kContentInfo, kFlutterSemanticsRoleContentInfo},
      {SemanticsRole::kMain, kFlutterSemanticsRoleMain},
      {SemanticsRole::kNavigation, kFlutterSemanticsRoleNavigation},
      {SemanticsRole::kRegion, kFlutterSemanticsRoleRegion},
      {SemanticsRole::kSlider, kFlutterSemanticsRoleSlider},
      {SemanticsRole::kListBox, kFlutterSemanticsRoleListBox},
      {SemanticsRole::kOption, kFlutterSemanticsRoleOption},
  };

  constexpr int64_t kImplicitViewId = 0;
  constexpr int32_t kBaseNodeId = 1;
  constexpr size_t kExpectedSingleNodeCount = 1u;

  for (const auto& test_case : kCases) {
    SemanticsNode node;
    node.id = kBaseNodeId;
    node.role = test_case.engine_role;

    SemanticsNodeUpdates nodes;
    nodes.emplace(node.id, node);
    CustomAccessibilityActionUpdates actions;

    EmbedderSemanticsUpdate2 update(kImplicitViewId, nodes, actions);
    FlutterSemanticsUpdate2* c_update = update.get();
    ASSERT_NE(c_update, nullptr);
    ASSERT_EQ(c_update->node_count, kExpectedSingleNodeCount);
    EXPECT_EQ(c_update->nodes[0]->role, test_case.expected_embedder_role);
  }
}

}  // namespace testing
}  // namespace flutter
