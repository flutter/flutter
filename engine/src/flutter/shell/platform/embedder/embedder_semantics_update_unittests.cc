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

  EmbedderSemanticsUpdate2 update(/*view_id=*/0, UpdateWithNode(node), {});

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

  EmbedderSemanticsUpdate2 update(/*view_id=*/0, UpdateWithNode(node), {});

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

}  // namespace testing
}  // namespace flutter
