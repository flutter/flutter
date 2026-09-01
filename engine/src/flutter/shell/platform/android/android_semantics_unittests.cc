// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_semantics_mapper.h"

#include <cstring>
#include <future>
#include <thread>
#include <vector>

#include "gtest/gtest.h"

namespace flutter {
namespace android {
namespace testing {

TEST(AndroidSemanticsTest, EmptyAndNullInputs) {
  FlutterSemanticsUpdate2 update = {};
  update.struct_size = sizeof(FlutterSemanticsUpdate2);

  EncodedSemanticsBatch batch =
      AndroidSemanticsMapper::MapSemanticsUpdate(update);
  EXPECT_TRUE(batch.empty());
  EXPECT_TRUE(batch.nodes.empty());
  EXPECT_TRUE(batch.custom_actions.empty());

  EncodedSemanticsUpdate node_res =
      AndroidSemanticsMapper::MapNodes(nullptr, 0);
  EXPECT_TRUE(node_res.empty());

  EncodedCustomAccessibilityActions action_res =
      AndroidSemanticsMapper::MapCustomActions(nullptr, 0);
  EXPECT_TRUE(action_res.empty());
}

TEST(AndroidSemanticsTest, EncodeFlagsComprehensive) {
  // Test fallback to deprecated flags
  FlutterSemanticsFlag dep_flag = kFlutterSemanticsFlagIsButton;
  int64_t dep_res = AndroidSemanticsMapper::EncodeFlags(nullptr, dep_flag);
  EXPECT_EQ(dep_res, (1 << 3));

  // Test full flags2
  FlutterSemanticsFlags flags = {};
  flags.struct_size = sizeof(FlutterSemanticsFlags);
  flags.is_checked = kFlutterCheckStateTrue;
  flags.is_selected = kFlutterTristateTrue;
  flags.is_enabled = kFlutterTristateTrue;
  flags.is_toggled = kFlutterTristateTrue;
  flags.is_expanded = kFlutterTristateTrue;
  flags.is_required = kFlutterTristateTrue;
  flags.is_focused = kFlutterTristateTrue;
  flags.is_button = true;
  flags.is_text_field = true;
  flags.is_in_mutually_exclusive_group = true;
  flags.is_header = true;
  flags.is_obscured = true;
  flags.scopes_route = true;
  flags.names_route = true;
  flags.is_hidden = true;
  flags.is_image = true;
  flags.is_live_region = true;
  flags.has_implicit_scrolling = true;
  flags.is_multiline = true;
  flags.is_read_only = true;
  flags.is_link = true;
  flags.is_slider = true;
  flags.is_keyboard_key = true;
  flags.is_accessibility_focus_blocked = true;

  int64_t encoded = AndroidSemanticsMapper::EncodeFlags(&flags);
  EXPECT_NE(encoded & (INT64_C(1) << 0), 0);   // HAS_CHECKED_STATE
  EXPECT_NE(encoded & (INT64_C(1) << 1), 0);   // IS_CHECKED
  EXPECT_NE(encoded & (INT64_C(1) << 2), 0);   // IS_SELECTED
  EXPECT_NE(encoded & (INT64_C(1) << 3), 0);   // IS_BUTTON
  EXPECT_NE(encoded & (INT64_C(1) << 4), 0);   // IS_TEXT_FIELD
  EXPECT_NE(encoded & (INT64_C(1) << 5), 0);   // IS_FOCUSED
  EXPECT_NE(encoded & (INT64_C(1) << 6), 0);   // HAS_ENABLED_STATE
  EXPECT_NE(encoded & (INT64_C(1) << 7), 0);   // IS_ENABLED
  EXPECT_NE(encoded & (INT64_C(1) << 8), 0);   // IS_IN_MUTUALLY_EXCLUSIVE_GROUP
  EXPECT_NE(encoded & (INT64_C(1) << 9), 0);   // IS_HEADER
  EXPECT_NE(encoded & (INT64_C(1) << 10), 0);  // IS_OBSCURED
  EXPECT_NE(encoded & (INT64_C(1) << 11), 0);  // SCOPES_ROUTE
  EXPECT_NE(encoded & (INT64_C(1) << 12), 0);  // NAMES_ROUTE
  EXPECT_NE(encoded & (INT64_C(1) << 13), 0);  // IS_HIDDEN
  EXPECT_NE(encoded & (INT64_C(1) << 14), 0);  // IS_IMAGE
  EXPECT_NE(encoded & (INT64_C(1) << 15), 0);  // IS_LIVE_REGION
  EXPECT_NE(encoded & (INT64_C(1) << 16), 0);  // HAS_TOGGLED_STATE
  EXPECT_NE(encoded & (INT64_C(1) << 17), 0);  // IS_TOGGLED
  EXPECT_NE(encoded & (INT64_C(1) << 18), 0);  // HAS_IMPLICIT_SCROLLING
  EXPECT_NE(encoded & (INT64_C(1) << 19), 0);  // IS_MULTILINE
  EXPECT_NE(encoded & (INT64_C(1) << 20), 0);  // IS_READ_ONLY
  EXPECT_NE(encoded & (INT64_C(1) << 21), 0);  // IS_FOCUSABLE
  EXPECT_NE(encoded & (INT64_C(1) << 22), 0);  // IS_LINK
  EXPECT_NE(encoded & (INT64_C(1) << 23), 0);  // IS_SLIDER
  EXPECT_NE(encoded & (INT64_C(1) << 24), 0);  // IS_KEYBOARD_KEY
  EXPECT_NE(encoded & (INT64_C(1) << 26), 0);  // HAS_EXPANDED_STATE
  EXPECT_NE(encoded & (INT64_C(1) << 27), 0);  // IS_EXPANDED
  EXPECT_NE(encoded & (INT64_C(1) << 28), 0);  // HAS_SELECTED_STATE
  EXPECT_NE(encoded & (INT64_C(1) << 29), 0);  // HAS_REQUIRED_STATE
  EXPECT_NE(encoded & (INT64_C(1) << 30), 0);  // IS_REQUIRED
  EXPECT_NE(encoded & (INT64_C(1) << 31), 0);  // IS_ACCESSIBILITY_FOCUS_BLOCKED

  // Test mixed check state
  FlutterSemanticsFlags mixed_flags = {};
  mixed_flags.struct_size = sizeof(FlutterSemanticsFlags);
  mixed_flags.is_checked = kFlutterCheckStateMixed;
  int64_t mixed_encoded = AndroidSemanticsMapper::EncodeFlags(&mixed_flags);
  EXPECT_NE(mixed_encoded & (INT64_C(1) << 25), 0);  // IS_CHECK_STATE_MIXED
}

TEST(AndroidSemanticsTest, EncodeTransformation) {
  // Test zero / uninitialized default produces identity matrix
  FlutterTransformation zero_tx = {};
  float mat[16];
  AndroidSemanticsMapper::EncodeTransformation(zero_tx, mat);
  EXPECT_FLOAT_EQ(mat[0], 1.0f);
  EXPECT_FLOAT_EQ(mat[5], 1.0f);
  EXPECT_FLOAT_EQ(mat[10], 1.0f);
  EXPECT_FLOAT_EQ(mat[15], 1.0f);
  EXPECT_FLOAT_EQ(mat[1], 0.0f);
  EXPECT_FLOAT_EQ(mat[12], 0.0f);

  // Test transformation values
  FlutterTransformation tx = {
      .scaleX = 2.0,
      .skewX = 0.5,
      .transX = 100.0,
      .skewY = -0.5,
      .scaleY = 3.0,
      .transY = 200.0,
      .pers0 = 0.001,
      .pers1 = 0.002,
      .pers2 = 1.0,
  };
  AndroidSemanticsMapper::EncodeTransformation(tx, mat);
  EXPECT_FLOAT_EQ(mat[0], 2.0f);     // scaleX
  EXPECT_FLOAT_EQ(mat[1], -0.5f);    // skewY
  EXPECT_FLOAT_EQ(mat[3], 0.001f);   // pers0
  EXPECT_FLOAT_EQ(mat[4], 0.5f);     // skewX
  EXPECT_FLOAT_EQ(mat[5], 3.0f);     // scaleY
  EXPECT_FLOAT_EQ(mat[7], 0.002f);   // pers1
  EXPECT_FLOAT_EQ(mat[10], 1.0f);    // Z diagonal
  EXPECT_FLOAT_EQ(mat[12], 100.0f);  // transX
  EXPECT_FLOAT_EQ(mat[13], 200.0f);  // transY
  EXPECT_FLOAT_EQ(mat[15], 1.0f);    // pers2
}

TEST(AndroidSemanticsTest, PutStringAndAttributes) {
  std::vector<std::string> strings;
  int32_t buffer[10];
  size_t pos = 0;

  // Empty string
  AndroidSemanticsMapper::PutStringIntoBuffer("", buffer, &pos, strings);
  EXPECT_EQ(buffer[0], -1);
  EXPECT_EQ(pos, 1u);
  EXPECT_TRUE(strings.empty());

  // Non-empty string
  AndroidSemanticsMapper::PutStringIntoBuffer("Flutter A11y", buffer, &pos,
                                              strings);
  EXPECT_EQ(buffer[1], 0);
  EXPECT_EQ(pos, 2u);
  ASSERT_EQ(strings.size(), 1u);
  EXPECT_EQ(strings[0], "Flutter A11y");

  // String attributes
  FlutterSpellOutStringAttribute spell_out = {
      .struct_size = sizeof(FlutterSpellOutStringAttribute),
  };
  FlutterLocaleStringAttribute locale_attr = {
      .struct_size = sizeof(FlutterLocaleStringAttribute),
      .locale = "en-US",
  };
  FlutterStringAttribute attr1 = {
      .struct_size = sizeof(FlutterStringAttribute),
      .start = 0,
      .end = 5,
      .type = kSpellOut,
      .spell_out = &spell_out,
  };
  FlutterStringAttribute attr2 = {
      .struct_size = sizeof(FlutterStringAttribute),
      .start = 6,
      .end = 12,
      .type = kLocale,
      .locale = &locale_attr,
  };

  const FlutterStringAttribute* attrs[] = {&attr1, &attr2};
  std::vector<std::vector<uint8_t>> string_attribute_args;
  int32_t attr_buffer[20];
  size_t attr_pos = 0;

  AndroidSemanticsMapper::PutStringAttributesIntoBuffer(
      attrs, 2, attr_buffer, &attr_pos, string_attribute_args);

  // attr_buffer layout:
  // [0]: count (2)
  // [1]: start (0), [2]: end (5), [3]: type (0 = kSpellOut), [4]: -1
  // [5]: start (6), [6]: end (12), [7]: type (1 = kLocale), [8]: 0 (arg index)
  EXPECT_EQ(attr_buffer[0], 2);
  EXPECT_EQ(attr_buffer[1], 0);
  EXPECT_EQ(attr_buffer[2], 5);
  EXPECT_EQ(attr_buffer[3], 0);
  EXPECT_EQ(attr_buffer[4], -1);
  EXPECT_EQ(attr_buffer[5], 6);
  EXPECT_EQ(attr_buffer[6], 12);
  EXPECT_EQ(attr_buffer[7], 1);
  EXPECT_EQ(attr_buffer[8], 0);
  EXPECT_EQ(attr_pos, 9u);

  ASSERT_EQ(string_attribute_args.size(), 1u);
  std::string decoded_locale(string_attribute_args[0].begin(),
                             string_attribute_args[0].end());
  EXPECT_EQ(decoded_locale, "en-US");
}

TEST(AndroidSemanticsTest, SemanticsNodePackingAndBinaryVerification) {
  FlutterSemanticsFlags flags = {};
  flags.struct_size = sizeof(FlutterSemanticsFlags);
  flags.is_button = true;
  flags.is_focused = kFlutterTristateTrue;

  int32_t traversal_children[] = {101, 102};
  int32_t hit_test_children[] = {102, 101};
  int32_t custom_actions[] = {1, 2, 3};

  FlutterSemanticsNode2 node = {
      .struct_size = sizeof(FlutterSemanticsNode2),
      .id = 42,
      .flags__deprecated__ = kFlutterSemanticsFlagHasCheckedState,
      .actions = kFlutterSemanticsActionTap,
      .text_selection_base = 0,
      .text_selection_extent = 5,
      .scroll_child_count = 10,
      .scroll_index = 2,
      .scroll_position = 150.0,
      .scroll_extent_max = 500.0,
      .scroll_extent_min = 0.0,
      .elevation = 4.0,
      .thickness = 1.0,
      .label = "Submit Button",
      .hint = "Double tap to submit",
      .value = "Active",
      .increased_value = "Incremented",
      .decreased_value = "Decremented",
      .text_direction = kFlutterTextDirectionLTR,
      .rect = {10.0, 20.0, 110.0, 70.0},
      .transform =
          {
              .scaleX = 1.0,
              .skewX = 0.0,
              .transX = 15.0,
              .skewY = 0.0,
              .scaleY = 1.0,
              .transY = 25.0,
              .pers0 = 0.0,
              .pers1 = 0.0,
              .pers2 = 1.0,
          },
      .child_count = 2,
      .children_in_traversal_order = traversal_children,
      .children_in_hit_test_order = hit_test_children,
      .custom_accessibility_actions_count = 3,
      .custom_accessibility_actions = custom_actions,
      .platform_view_id = 999,
      .tooltip = "Click to proceed",
      .label_attribute_count = 0,
      .label_attributes = nullptr,
      .hint_attribute_count = 0,
      .hint_attributes = nullptr,
      .value_attribute_count = 0,
      .value_attributes = nullptr,
      .increased_value_attribute_count = 0,
      .increased_value_attributes = nullptr,
      .decreased_value_attribute_count = 0,
      .decreased_value_attributes = nullptr,
      .flags2 = &flags,
      .heading_level = 1,
      .identifier = "submit_btn_42",
  };

  const FlutterSemanticsNode2* nodes[] = {&node};
  EncodedSemanticsUpdate update = AndroidSemanticsMapper::MapNodes(nodes, 1);

  EXPECT_FALSE(update.empty());
  EXPECT_GT(update.buffer.size(), 0u);

  // Unpack and verify the byte buffer layout as expected by
  // AccessibilityBridge.java
  const int32_t* buf32 = reinterpret_cast<const int32_t*>(update.buffer.data());
  const float* bufF32 = reinterpret_cast<const float*>(update.buffer.data());

  size_t p = 0;
  EXPECT_EQ(buf32[p++], 42);  // id

  int64_t read_flags;
  std::memcpy(&read_flags, &buf32[p], sizeof(int64_t));
  p += 2;
  EXPECT_NE(read_flags & (INT64_C(1) << 3), 0);  // IS_BUTTON
  EXPECT_NE(read_flags & (INT64_C(1) << 5), 0);  // IS_FOCUSED

  EXPECT_EQ(buf32[p++],
            static_cast<int32_t>(kFlutterSemanticsActionTap));  // actions
  EXPECT_EQ(buf32[p++], 0);  // maxValueLength
  EXPECT_EQ(buf32[p++],
            static_cast<int32_t>(std::strlen("Active")));  // currentValueLength
  EXPECT_EQ(buf32[p++], 0);                                // textSelectionBase
  EXPECT_EQ(buf32[p++], 5);              // textSelectionExtent
  EXPECT_EQ(buf32[p++], 999);            // platformViewId
  EXPECT_EQ(buf32[p++], 10);             // scrollChildren
  EXPECT_EQ(buf32[p++], 2);              // scrollIndex
  EXPECT_EQ(buf32[p++], -1);             // traversalParent
  EXPECT_FLOAT_EQ(bufF32[p++], 150.0f);  // scrollPosition
  EXPECT_FLOAT_EQ(bufF32[p++], 500.0f);  // scrollExtentMax
  EXPECT_FLOAT_EQ(bufF32[p++], 0.0f);    // scrollExtentMin
  EXPECT_EQ(buf32[p++], 0);              // role

  // Identifier string index
  int32_t id_str_idx = buf32[p++];
  ASSERT_GE(id_str_idx, 0);
  EXPECT_EQ(update.strings[id_str_idx], "submit_btn_42");

  // Label string index
  int32_t label_str_idx = buf32[p++];
  ASSERT_GE(label_str_idx, 0);
  EXPECT_EQ(update.strings[label_str_idx], "Submit Button");

  // Label attributes count (-1 for empty)
  EXPECT_EQ(buf32[p++], -1);

  // Value string index
  int32_t val_str_idx = buf32[p++];
  ASSERT_GE(val_str_idx, 0);
  EXPECT_EQ(update.strings[val_str_idx], "Active");
  EXPECT_EQ(buf32[p++], -1);  // value attributes

  // Increased value string index
  int32_t inc_str_idx = buf32[p++];
  ASSERT_GE(inc_str_idx, 0);
  EXPECT_EQ(update.strings[inc_str_idx], "Incremented");
  EXPECT_EQ(buf32[p++], -1);  // increased value attributes

  // Decreased value string index
  int32_t dec_str_idx = buf32[p++];
  ASSERT_GE(dec_str_idx, 0);
  EXPECT_EQ(update.strings[dec_str_idx], "Decremented");
  EXPECT_EQ(buf32[p++], -1);  // decreased value attributes

  // Hint string index
  int32_t hint_str_idx = buf32[p++];
  ASSERT_GE(hint_str_idx, 0);
  EXPECT_EQ(update.strings[hint_str_idx], "Double tap to submit");
  EXPECT_EQ(buf32[p++], -1);  // hint attributes

  // Tooltip string index
  int32_t tooltip_str_idx = buf32[p++];
  ASSERT_GE(tooltip_str_idx, 0);
  EXPECT_EQ(update.strings[tooltip_str_idx], "Click to proceed");

  // linkUrl, locale, minValue, maxValue (all -1)
  EXPECT_EQ(buf32[p++], -1);
  EXPECT_EQ(buf32[p++], -1);
  EXPECT_EQ(buf32[p++], -1);
  EXPECT_EQ(buf32[p++], -1);

  EXPECT_EQ(buf32[p++], 1);  // headingLevel
  EXPECT_EQ(buf32[p++],
            static_cast<int32_t>(kFlutterTextDirectionLTR));  // textDirection
  EXPECT_FLOAT_EQ(bufF32[p++], 10.0f);                        // rect.left
  EXPECT_FLOAT_EQ(bufF32[p++], 20.0f);                        // rect.top
  EXPECT_FLOAT_EQ(bufF32[p++], 110.0f);                       // rect.right
  EXPECT_FLOAT_EQ(bufF32[p++], 70.0f);                        // rect.bottom

  // Transform matrix (16 floats)
  EXPECT_FLOAT_EQ(bufF32[p + 0], 1.0f);
  EXPECT_FLOAT_EQ(bufF32[p + 12], 15.0f);
  EXPECT_FLOAT_EQ(bufF32[p + 13], 25.0f);
  p += 16;

  // Hit test transform matrix (16 floats)
  EXPECT_FLOAT_EQ(bufF32[p + 0], 1.0f);
  EXPECT_FLOAT_EQ(bufF32[p + 12], 15.0f);
  EXPECT_FLOAT_EQ(bufF32[p + 13], 25.0f);
  p += 16;

  // Traversal order children
  EXPECT_EQ(buf32[p++], 2);    // child_count
  EXPECT_EQ(buf32[p++], 101);  // child 0
  EXPECT_EQ(buf32[p++], 102);  // child 1

  // Hit test order children
  EXPECT_EQ(buf32[p++], 2);    // child_count
  EXPECT_EQ(buf32[p++], 102);  // child 0
  EXPECT_EQ(buf32[p++], 101);  // child 1

  // Custom accessibility actions
  EXPECT_EQ(buf32[p++], 3);  // custom_accessibility_actions_count
  EXPECT_EQ(buf32[p++], 1);  // action 0
  EXPECT_EQ(buf32[p++], 2);  // action 1
  EXPECT_EQ(buf32[p++], 3);  // action 2

  // Ensure all bytes were consumed
  EXPECT_EQ(p * sizeof(int32_t), update.buffer.size());
}

TEST(AndroidSemanticsTest, CustomAccessibilityActionsPacking) {
  FlutterSemanticsCustomAction2 a1 = {
      .struct_size = sizeof(FlutterSemanticsCustomAction2),
      .id = 10,
      .override_action = kFlutterSemanticsActionTap,
      .label = "Custom Tap",
      .hint = "Performs custom tap action",
  };
  FlutterSemanticsCustomAction2 a2 = {
      .struct_size = sizeof(FlutterSemanticsCustomAction2),
      .id = 20,
      .override_action = kFlutterSemanticsActionDismiss,
      .label = "Dismiss Card",
      .hint = "Dismisses current item",
  };

  const FlutterSemanticsCustomAction2* actions[] = {&a1, &a2};
  EncodedCustomAccessibilityActions result =
      AndroidSemanticsMapper::MapCustomActions(actions, 2);

  EXPECT_FALSE(result.empty());
  EXPECT_EQ(result.buffer.size(), 2 * 4 * sizeof(int32_t));

  const int32_t* buf32 = reinterpret_cast<const int32_t*>(result.buffer.data());
  EXPECT_EQ(buf32[0], 10);  // id
  EXPECT_EQ(buf32[1], static_cast<int32_t>(kFlutterSemanticsActionTap));
  EXPECT_EQ(result.strings[buf32[2]], "Custom Tap");
  EXPECT_EQ(result.strings[buf32[3]], "Performs custom tap action");

  EXPECT_EQ(buf32[4], 20);  // id
  EXPECT_EQ(buf32[5], static_cast<int32_t>(kFlutterSemanticsActionDismiss));
  EXPECT_EQ(result.strings[buf32[6]], "Dismiss Card");
  EXPECT_EQ(result.strings[buf32[7]], "Dismisses current item");
}

TEST(AndroidSemanticsTest, MultithreadedConcurrentMapping) {
  constexpr size_t kThreadCount = 8;
  constexpr size_t kIterations = 100;

  std::vector<std::future<void>> futures;
  futures.reserve(kThreadCount);

  for (size_t t = 0; t < kThreadCount; ++t) {
    futures.push_back(std::async(std::launch::async, [t]() {
      for (size_t i = 0; i < kIterations; ++i) {
        FlutterSemanticsFlags flags = {};
        flags.struct_size = sizeof(FlutterSemanticsFlags);
        flags.is_button = true;

        FlutterSemanticsNode2 node = {};
        node.struct_size = sizeof(FlutterSemanticsNode2);
        node.id = static_cast<int32_t>(t * 1000 + i);
        node.label = "Thread Node";
        node.flags2 = &flags;

        FlutterSemanticsCustomAction2 action = {};
        action.struct_size = sizeof(FlutterSemanticsCustomAction2);
        action.id = static_cast<int32_t>(i);
        action.label = "Thread Action";

        FlutterSemanticsNode2* node_ptrs[] = {&node};
        FlutterSemanticsCustomAction2* action_ptrs[] = {&action};

        FlutterSemanticsUpdate2 update = {
            .struct_size = sizeof(FlutterSemanticsUpdate2),
            .node_count = 1,
            .nodes = node_ptrs,
            .custom_action_count = 1,
            .custom_actions = action_ptrs,
            .view_id = static_cast<FlutterViewId>(t),
        };

        EncodedSemanticsBatch batch =
            AndroidSemanticsMapper::MapSemanticsUpdate(update);
        EXPECT_FALSE(batch.empty());
        EXPECT_FALSE(batch.nodes.empty());
        EXPECT_FALSE(batch.custom_actions.empty());
        EXPECT_EQ(batch.view_id, static_cast<FlutterViewId>(t));
      }
    }));
  }

  for (auto& f : futures) {
    f.get();
  }
}

}  // namespace testing
}  // namespace android
}  // namespace flutter
