// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_semantics_update.h"

#include <memory>
#include <string>

#include "flutter/lib/ui/semantics/string_attribute.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {
namespace {

// The id of the only node in these updates. Any id works.
constexpr int32_t kNodeId = 42;

SemanticsNodeUpdates UpdateWithNode(const SemanticsNode& node) {
  SemanticsNodeUpdates updates;
  updates[node.id] = node;
  return updates;
}

}  // namespace

TEST(EmbedderSemanticsUpdate2Test, FlagsReportTheirStructSize) {
  SemanticsNode node;
  node.id = kNodeId;
  node.flags.isButton = true;

  // The update points into the nodes, so they must outlive it.
  const SemanticsNodeUpdates nodes = UpdateWithNode(node);
  EmbedderSemanticsUpdate2 update(/*view_id=*/0, nodes, {});

  ASSERT_EQ(update.get()->node_count, 1u);
  const FlutterSemanticsNode2* embedder_node = update.get()->nodes[0];
  ASSERT_NE(embedder_node->flags2, nullptr);
  EXPECT_EQ(embedder_node->flags2->struct_size, sizeof(FlutterSemanticsFlags));
  EXPECT_TRUE(embedder_node->flags2->is_button);
}

TEST(EmbedderSemanticsUpdate2Test, SpellOutAttributesPointToAnAttribute) {
  SemanticsNode node;
  node.id = kNodeId;
  node.label = "Hello";
  auto spell_out = std::make_shared<SpellOutStringAttribute>();
  spell_out->start = 0;
  spell_out->end = 5;
  spell_out->type = StringAttributeType::kSpellOut;
  node.labelAttributes.push_back(spell_out);
  node.hintAttributes.push_back(spell_out);

  // The update points into the nodes, so they must outlive it.
  const SemanticsNodeUpdates nodes = UpdateWithNode(node);
  EmbedderSemanticsUpdate2 update(/*view_id=*/0, nodes, {});

  const FlutterSemanticsNode2* embedder_node = update.get()->nodes[0];
  ASSERT_EQ(embedder_node->label_attribute_count, 1u);
  const FlutterStringAttribute* attribute = embedder_node->label_attributes[0];
  EXPECT_EQ(attribute->type, FlutterStringAttributeType::kSpellOut);
  ASSERT_NE(attribute->spell_out, nullptr);
  EXPECT_EQ(attribute->spell_out->struct_size,
            sizeof(FlutterSpellOutStringAttribute));
  ASSERT_EQ(embedder_node->hint_attribute_count, 1u);
  EXPECT_EQ(embedder_node->hint_attributes[0]->spell_out, attribute->spell_out);
}

TEST(EmbedderSemanticsUpdate2Test, CarriesEveryNodeFieldAndroidEncodes) {
  // Arbitrary values that differ from every default.
  constexpr int32_t kMaxValueLength = 20;
  constexpr int32_t kCurrentValueLength = 5;
  constexpr int32_t kTraversalParent = 7;
  constexpr int32_t kTraversalChild = 3;
  constexpr int32_t kHitTestChildA = 4;
  constexpr int32_t kHitTestChildB = 5;
  SemanticsNode node;
  node.id = kNodeId;
  node.maxValueLength = kMaxValueLength;
  node.currentValueLength = kCurrentValueLength;
  node.traversalParent = kTraversalParent;
  node.role = SemanticsRole::kSlider;
  node.linkUrl = "https://flutter.dev";
  node.locale = "de-CH";
  node.minValue = "0";
  node.maxValue = "100";
  // A 3D rotation and a z translation, which a 3x3 matrix cannot hold.
  node.transform = SkM44::Rotate({1, 0, 0}, 0.5);
  node.transform.setRC(2, 3, 9);
  node.hitTestTransform = SkM44::Translate(1, 2, 3);
  node.childrenInTraversalOrder = {kTraversalChild};
  node.childrenInHitTestOrder = {kHitTestChildA, kHitTestChildB};

  // The update points into the nodes, so they must outlive it.
  const SemanticsNodeUpdates nodes = UpdateWithNode(node);
  EmbedderSemanticsUpdate2 update(/*view_id=*/0, nodes, {});

  const FlutterSemanticsNode2* embedder_node = update.get()->nodes[0];
  ASSERT_GE(
      embedder_node->struct_size,
      offsetof(FlutterSemanticsNode2, hit_test_child_count) + sizeof(size_t));
  EXPECT_EQ(embedder_node->max_value_length, kMaxValueLength);
  EXPECT_EQ(embedder_node->current_value_length, kCurrentValueLength);
  EXPECT_EQ(embedder_node->traversal_parent, kTraversalParent);
  EXPECT_EQ(embedder_node->role, kFlutterSemanticsRoleSlider);
  EXPECT_STREQ(embedder_node->link_url, "https://flutter.dev");
  EXPECT_STREQ(embedder_node->locale, "de-CH");
  EXPECT_STREQ(embedder_node->min_value, "0");
  EXPECT_STREQ(embedder_node->max_value, "100");
  for (int column = 0; column < 4; ++column) {
    for (int row = 0; row < 4; ++row) {
      EXPECT_FLOAT_EQ(embedder_node->transform_4x4.m[column * 4 + row],
                      node.transform.rc(row, column))
          << "transform row " << row << " column " << column;
      EXPECT_FLOAT_EQ(embedder_node->hit_test_transform.m[column * 4 + row],
                      node.hitTestTransform.rc(row, column))
          << "hit test transform row " << row << " column " << column;
    }
  }
  ASSERT_EQ(embedder_node->child_count, 1u);
  EXPECT_EQ(embedder_node->children_in_traversal_order[0], kTraversalChild);
  ASSERT_EQ(embedder_node->hit_test_child_count, 2u);
  EXPECT_EQ(embedder_node->children_in_hit_test_order[0], kHitTestChildA);
  EXPECT_EQ(embedder_node->children_in_hit_test_order[1], kHitTestChildB);
}

TEST(EmbedderSemanticsUpdate2Test, DefaultsMatchTheFramework) {
  SemanticsNode node;
  node.id = kNodeId;
  // SemanticsNode leaves `role` uninitialized; updates from the framework
  // always set it.
  node.role = SemanticsRole::kNone;

  // The update points into the nodes, so they must outlive it.
  const SemanticsNodeUpdates nodes = UpdateWithNode(node);
  EmbedderSemanticsUpdate2 update(/*view_id=*/0, nodes, {});

  const FlutterSemanticsNode2* embedder_node = update.get()->nodes[0];
  EXPECT_EQ(embedder_node->max_value_length, -1);
  EXPECT_EQ(embedder_node->current_value_length, -1);
  EXPECT_EQ(embedder_node->role, kFlutterSemanticsRoleNone);
  EXPECT_STREQ(embedder_node->link_url, "");
  EXPECT_STREQ(embedder_node->locale, "");
  EXPECT_EQ(embedder_node->hit_test_child_count, 0u);
  // Identity.
  for (int i = 0; i < 16; ++i) {
    EXPECT_EQ(embedder_node->transform_4x4.m[i], i % 5 == 0 ? 1.0 : 0.0);
  }
}

}  // namespace testing
}  // namespace flutter
