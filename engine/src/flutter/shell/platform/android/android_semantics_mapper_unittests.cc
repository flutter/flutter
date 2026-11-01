// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_semantics_mapper.h"

#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <limits>
#include <string>
#include <vector>

#include "gtest/gtest.h"

namespace flutter::android::testing {

namespace {

constexpr FlutterTransformation kIdentityTransform = {
    1.0, 0.0, 0.0,  //
    0.0, 1.0, 0.0,  //
    0.0, 0.0, 1.0   //
};

}  // namespace

TEST(AndroidSemanticsMapperTest, MapUpdateNullOrEmptyReturnsEmpty) {
  auto mapped_null = AndroidSemanticsMapper::MapUpdate(nullptr);
  EXPECT_TRUE(mapped_null.nodes.buffer.empty());
  EXPECT_TRUE(mapped_null.nodes.strings.empty());
  EXPECT_TRUE(mapped_null.nodes.string_attribute_args.empty());
  EXPECT_TRUE(mapped_null.actions.buffer.empty());
  EXPECT_TRUE(mapped_null.actions.strings.empty());

  FlutterSemanticsUpdate2 empty_update = {};
  empty_update.struct_size = sizeof(FlutterSemanticsUpdate2);
  empty_update.node_count = 0;
  empty_update.nodes = nullptr;
  empty_update.custom_action_count = 0;
  empty_update.custom_actions = nullptr;

  auto mapped_empty = AndroidSemanticsMapper::MapUpdate(&empty_update);
  EXPECT_TRUE(mapped_empty.nodes.buffer.empty());
  EXPECT_TRUE(mapped_empty.actions.buffer.empty());
}

TEST(AndroidSemanticsMapperTest, EncodeFlagsMapsAll32BitPositions) {
  FlutterSemanticsFlags flags = {};
  flags.struct_size = sizeof(FlutterSemanticsFlags);
  flags.is_checked = kFlutterCheckStateTrue;    // bit 0 & bit 1
  flags.is_selected = kFlutterTristateTrue;     // bit 2 & bit 28
  flags.is_button = true;                       // bit 3
  flags.is_text_field = true;                   // bit 4
  flags.is_focused = kFlutterTristateTrue;      // bit 5 & bit 21
  flags.is_enabled = kFlutterTristateTrue;      // bit 6 & bit 7
  flags.is_in_mutually_exclusive_group = true;  // bit 8
  flags.is_header = true;                       // bit 9
  flags.is_obscured = true;                     // bit 10
  flags.scopes_route = true;                    // bit 11
  flags.names_route = true;                     // bit 12
  flags.is_hidden = true;                       // bit 13
  flags.is_image = true;                        // bit 14
  flags.is_live_region = true;                  // bit 15
  flags.is_toggled = kFlutterTristateTrue;      // bit 16 & bit 17
  flags.has_implicit_scrolling = true;          // bit 18
  flags.is_multiline = true;                    // bit 19
  flags.is_read_only = true;                    // bit 20
  flags.is_link = true;                         // bit 22
  flags.is_slider = true;                       // bit 23
  flags.is_keyboard_key = true;                 // bit 24
  flags.is_expanded = kFlutterTristateTrue;     // bit 26 & bit 27
  flags.is_required = kFlutterTristateTrue;     // bit 29 & bit 30
  flags.is_accessibility_focus_blocked = true;  // bit 31

  int64_t encoded = AndroidSemanticsMapper::EncodeFlags(&flags);
  for (int bit = 0; bit <= 31; ++bit) {
    if (bit == 25) {
      // Bit 25 is kFlutterCheckStateMixed.
      EXPECT_EQ(encoded & (INT64_C(1) << bit), 0);
    } else {
      EXPECT_NE(encoded & (INT64_C(1) << bit), 0) << "Bit " << bit << " unset";
    }
  }

  // Verify mixed check state (bit 0 and bit 25, not bit 1).
  FlutterSemanticsFlags mixed_flags = {};
  mixed_flags.struct_size = sizeof(FlutterSemanticsFlags);
  mixed_flags.is_checked = kFlutterCheckStateMixed;
  int64_t mixed_encoded = AndroidSemanticsMapper::EncodeFlags(&mixed_flags);
  EXPECT_NE(mixed_encoded & (INT64_C(1) << 0), 0);
  EXPECT_EQ(mixed_encoded & (INT64_C(1) << 1), 0);
  EXPECT_NE(mixed_encoded & (INT64_C(1) << 25), 0);
}

TEST(AndroidSemanticsMapperTest, EncodeFlagsDeprecatedFallback) {
  int32_t raw_deprecated =
      kFlutterSemanticsFlagIsButton | kFlutterSemanticsFlagIsHeader;
  FlutterSemanticsFlag deprecated = kFlutterSemanticsFlagIsButton;
  std::memcpy(&deprecated, &raw_deprecated, sizeof(int32_t));
  int64_t encoded = AndroidSemanticsMapper::EncodeFlags(nullptr, deprecated);
  EXPECT_NE(encoded & (INT64_C(1) << 3), 0);
  EXPECT_NE(encoded & (INT64_C(1) << 9), 0);
}

TEST(AndroidSemanticsMapperTest, EncodeTransformation3x3To4x4ColumnMajor) {
  FlutterTransformation t = {
      2.0, 3.0, 10.0,  // scaleX, skewX, transX
      4.0, 5.0, 20.0,  // skewY, scaleY, transY
      0.1, 0.2, 1.0    // pers0, pers1, pers2
  };
  float mat[16] = {};
  AndroidSemanticsMapper::EncodeTransformation(t, mat);

  // Column 0
  EXPECT_FLOAT_EQ(mat[0], 2.0f);
  EXPECT_FLOAT_EQ(mat[1], 4.0f);
  EXPECT_FLOAT_EQ(mat[2], 0.0f);
  EXPECT_FLOAT_EQ(mat[3], 0.1f);
  // Column 1
  EXPECT_FLOAT_EQ(mat[4], 3.0f);
  EXPECT_FLOAT_EQ(mat[5], 5.0f);
  EXPECT_FLOAT_EQ(mat[6], 0.0f);
  EXPECT_FLOAT_EQ(mat[7], 0.2f);
  // Column 2 (Z identity)
  EXPECT_FLOAT_EQ(mat[8], 0.0f);
  EXPECT_FLOAT_EQ(mat[9], 0.0f);
  EXPECT_FLOAT_EQ(mat[10], 1.0f);
  EXPECT_FLOAT_EQ(mat[11], 0.0f);
  // Column 3 (Translation + W)
  EXPECT_FLOAT_EQ(mat[12], 10.0f);
  EXPECT_FLOAT_EQ(mat[13], 20.0f);
  EXPECT_FLOAT_EQ(mat[14], 0.0f);
  EXPECT_FLOAT_EQ(mat[15], 1.0f);
}

TEST(AndroidSemanticsMapperTest,
     MapNodesSerializesFullBufferAndAll9Rfc410Fields) {
  FlutterSemanticsFlags flags = {};
  flags.struct_size = sizeof(FlutterSemanticsFlags);
  flags.is_button = true;
  flags.is_enabled = kFlutterTristateTrue;

  FlutterStringAttribute spell_attr = {};
  spell_attr.struct_size = sizeof(FlutterStringAttribute);
  spell_attr.start = 0;
  spell_attr.end = 5;
  spell_attr.type = kSpellOut;
  const FlutterStringAttribute* label_attrs[] = {&spell_attr};

  FlutterLocaleStringAttribute locale_payload = {};
  locale_payload.struct_size = sizeof(FlutterLocaleStringAttribute);
  locale_payload.locale = "en-US";

  FlutterStringAttribute locale_attr = {};
  locale_attr.struct_size = sizeof(FlutterStringAttribute);
  locale_attr.start = 1;
  locale_attr.end = 4;
  locale_attr.type = kLocale;
  locale_attr.locale = &locale_payload;
  const FlutterStringAttribute* value_attrs[] = {&locale_attr};

  // Distinct traversal vs hit-test child counts (e.g., OverlayPortal).
  int32_t traversal_children[] = {10, 20, 30};
  int32_t hit_test_children[] = {20};
  int32_t custom_actions[] = {100};

  FlutterTransformation hit_transform = {
      1.0, 0.0, 50.0,  //
      0.0, 1.0, 60.0,  //
      0.0, 0.0, 1.0    //
  };

  FlutterSemanticsNode2 node = {};
  node.struct_size = sizeof(FlutterSemanticsNode2);
  node.id = 42;
  node.flags2 = &flags;
  int32_t combined_actions =
      kFlutterSemanticsActionTap | kFlutterSemanticsActionLongPress;
  std::memcpy(&node.actions, &combined_actions, sizeof(int32_t));
  node.max_value_length = 120;
  node.current_value_length = 15;
  node.text_selection_base = 2;
  node.text_selection_extent = 8;
  node.platform_view_id = 7;
  node.scroll_child_count = 3;
  node.scroll_index = 1;
  node.scroll_position = 12.5;
  node.scroll_extent_max = 100.0;
  node.scroll_extent_min = 0.0;
  node.role = kFlutterSemanticsRoleOption;  // Role 35 (highest valid enum).
  node.identifier = "id_42";
  node.label = "Submit";
  node.label_attribute_count = 1;
  node.label_attributes = label_attrs;
  node.value = "val";
  node.value_attribute_count = 1;
  node.value_attributes = value_attrs;
  node.increased_value = "inc";
  node.decreased_value = "dec";
  node.hint = "tap to submit";
  node.tooltip = "button tooltip";
  node.link_url = "https://flutter.dev";
  node.locale = "en-GB";
  node.min_value = "0";
  node.max_value = "100";
  node.heading_level = 2;
  node.text_direction = kFlutterTextDirectionLTR;
  node.rect = {1.0, 2.0, 101.0, 52.0};
  node.transform = kIdentityTransform;
  node.hit_test_transform = hit_transform;
  node.child_count = 3;
  node.children_in_traversal_order = traversal_children;
  node.hit_test_child_count = 1;
  node.children_in_hit_test_order = hit_test_children;
  node.custom_accessibility_actions_count = 1;
  node.custom_accessibility_actions = custom_actions;

  FlutterSemanticsNode2* nodes[] = {&node};
  FlutterSemanticsUpdate2 update = {};
  update.struct_size = sizeof(FlutterSemanticsUpdate2);
  update.node_count = 1;
  update.nodes = nodes;

  MappedSemanticsNodes mapped = AndroidSemanticsMapper::MapNodes(&update);

  // Expected size:
  // 73 fixed ints + 3 traversal children + 1 hit-test child + 1 custom action
  // + 4 ints (label attr) + 4 ints (value attr) = 86 int32s.
  constexpr size_t kExpectedInts = 73 + 3 + 1 + 1 + 4 + 4;
  ASSERT_EQ(mapped.buffer.size(), kExpectedInts * sizeof(int32_t));

  const int32_t* buf32 = reinterpret_cast<const int32_t*>(mapped.buffer.data());
  const float* flt32 = reinterpret_cast<const float*>(mapped.buffer.data());
  size_t p = 0;

  EXPECT_EQ(buf32[p++], 42);  // id

  int64_t decoded_flags = 0;
  std::memcpy(&decoded_flags, &buf32[p], sizeof(int64_t));
  p += 2;
  EXPECT_EQ(decoded_flags, AndroidSemanticsMapper::EncodeFlags(&flags));

  EXPECT_EQ(buf32[p++], static_cast<int32_t>(kFlutterSemanticsActionTap |
                                             kFlutterSemanticsActionLongPress));
  EXPECT_EQ(buf32[p++], 120);  // max_value_length
  EXPECT_EQ(buf32[p++], 15);   // current_value_length
  EXPECT_EQ(buf32[p++], 2);    // text_selection_base
  EXPECT_EQ(buf32[p++], 8);    // text_selection_extent
  EXPECT_EQ(buf32[p++], 7);    // platform_view_id
  EXPECT_EQ(buf32[p++], 3);    // scroll_child_count
  EXPECT_EQ(buf32[p++], 1);    // scroll_index
  EXPECT_EQ(buf32[p++], -1);   // traversalParent sentinel
  EXPECT_FLOAT_EQ(flt32[p++], 12.5f);
  EXPECT_FLOAT_EQ(flt32[p++], 100.0f);
  EXPECT_FLOAT_EQ(flt32[p++], 0.0f);
  EXPECT_EQ(buf32[p++], static_cast<int32_t>(kFlutterSemanticsRoleOption));

  // identifier -> strings[0]
  EXPECT_EQ(buf32[p++], 0);
  // label -> strings[1]
  EXPECT_EQ(buf32[p++], 1);
  // label_attributes (1 spell out attribute)
  EXPECT_EQ(buf32[p++], 1);
  EXPECT_EQ(buf32[p++], 0);
  EXPECT_EQ(buf32[p++], 5);
  EXPECT_EQ(buf32[p++], static_cast<int32_t>(kSpellOut));
  EXPECT_EQ(buf32[p++], -1);

  // value -> strings[2]
  EXPECT_EQ(buf32[p++], 2);
  // value_attributes (1 locale attribute)
  EXPECT_EQ(buf32[p++], 1);
  EXPECT_EQ(buf32[p++], 1);
  EXPECT_EQ(buf32[p++], 4);
  EXPECT_EQ(buf32[p++], static_cast<int32_t>(kLocale));
  EXPECT_EQ(buf32[p++], 0);  // string_attribute_args[0]

  // increased_value -> strings[3], no attrs
  EXPECT_EQ(buf32[p++], 3);
  EXPECT_EQ(buf32[p++], -1);

  // decreased_value -> strings[4], no attrs
  EXPECT_EQ(buf32[p++], 4);
  EXPECT_EQ(buf32[p++], -1);

  // hint -> strings[5], no attrs
  EXPECT_EQ(buf32[p++], 5);
  EXPECT_EQ(buf32[p++], -1);

  // tooltip -> strings[6]
  EXPECT_EQ(buf32[p++], 6);
  // link_url -> strings[7]
  EXPECT_EQ(buf32[p++], 7);
  // locale -> strings[8]
  EXPECT_EQ(buf32[p++], 8);
  // min_value -> strings[9]
  EXPECT_EQ(buf32[p++], 9);
  // max_value -> strings[10]
  EXPECT_EQ(buf32[p++], 10);

  EXPECT_EQ(buf32[p++], 2);  // heading_level
  EXPECT_EQ(buf32[p++], static_cast<int32_t>(kFlutterTextDirectionLTR));

  // rect
  EXPECT_FLOAT_EQ(flt32[p++], 1.0f);
  EXPECT_FLOAT_EQ(flt32[p++], 2.0f);
  EXPECT_FLOAT_EQ(flt32[p++], 101.0f);
  EXPECT_FLOAT_EQ(flt32[p++], 52.0f);

  // transform (identity)
  EXPECT_FLOAT_EQ(flt32[p + 0], 1.0f);
  EXPECT_FLOAT_EQ(flt32[p + 5], 1.0f);
  EXPECT_FLOAT_EQ(flt32[p + 10], 1.0f);
  EXPECT_FLOAT_EQ(flt32[p + 15], 1.0f);
  p += 16;

  // hit_test_transform (translated by 50, 60)
  EXPECT_FLOAT_EQ(flt32[p + 12], 50.0f);
  EXPECT_FLOAT_EQ(flt32[p + 13], 60.0f);
  p += 16;

  // children_in_traversal_order (3 children)
  EXPECT_EQ(buf32[p++], 3);
  EXPECT_EQ(buf32[p++], 10);
  EXPECT_EQ(buf32[p++], 20);
  EXPECT_EQ(buf32[p++], 30);

  // children_in_hit_test_order (1 child via hit_test_child_count!)
  EXPECT_EQ(buf32[p++], 1);
  EXPECT_EQ(buf32[p++], 20);

  // custom_accessibility_actions (1 action)
  EXPECT_EQ(buf32[p++], 1);
  EXPECT_EQ(buf32[p++], 100);

  EXPECT_EQ(p, kExpectedInts);

  ASSERT_EQ(mapped.strings.size(), 11u);
  EXPECT_EQ(mapped.strings[0], "id_42");
  EXPECT_EQ(mapped.strings[1], "Submit");
  EXPECT_EQ(mapped.strings[2], "val");
  EXPECT_EQ(mapped.strings[3], "inc");
  EXPECT_EQ(mapped.strings[4], "dec");
  EXPECT_EQ(mapped.strings[5], "tap to submit");
  EXPECT_EQ(mapped.strings[6], "button tooltip");
  EXPECT_EQ(mapped.strings[7], "https://flutter.dev");
  EXPECT_EQ(mapped.strings[8], "en-GB");
  EXPECT_EQ(mapped.strings[9], "0");
  EXPECT_EQ(mapped.strings[10], "100");

  ASSERT_EQ(mapped.string_attribute_args.size(), 1u);
  std::string attr_locale(mapped.string_attribute_args[0].begin(),
                          mapped.string_attribute_args[0].end());
  EXPECT_EQ(attr_locale, "en-US");
}

TEST(AndroidSemanticsMapperTest,
     RoleValidationAcceptsRolesThroughOptionAndSanitizesOutOfBounds) {
  for (FlutterSemanticsRole r :
       {kFlutterSemanticsRoleSlider, kFlutterSemanticsRoleListBox,
        kFlutterSemanticsRoleOption}) {
    FlutterSemanticsNode2 node = {};
    node.struct_size = sizeof(FlutterSemanticsNode2);
    node.role = r;
    FlutterSemanticsNode2* nodes[] = {&node};
    FlutterSemanticsUpdate2 update = {};
    update.struct_size = sizeof(FlutterSemanticsUpdate2);
    update.node_count = 1;
    update.nodes = nodes;

    MappedSemanticsNodes mapped = AndroidSemanticsMapper::MapNodes(&update);
    ASSERT_EQ(mapped.buffer.size(), AndroidSemanticsMapper::kBytesPerNode);
    const int32_t* buf32 =
        reinterpret_cast<const int32_t*>(mapped.buffer.data());
    EXPECT_EQ(buf32[15], static_cast<int32_t>(r));
  }

  // Out-of-bounds role (36 and -5) should be sanitized to
  // kFlutterSemanticsRoleNone (0).
  for (int32_t invalid_role : {-5, 36, 999}) {
    FlutterSemanticsNode2 node = {};
    node.struct_size = sizeof(FlutterSemanticsNode2);
    std::memcpy(&node.role, &invalid_role, sizeof(int32_t));
    FlutterSemanticsNode2* nodes[] = {&node};
    FlutterSemanticsUpdate2 update = {};
    update.struct_size = sizeof(FlutterSemanticsUpdate2);
    update.node_count = 1;
    update.nodes = nodes;

    MappedSemanticsNodes mapped = AndroidSemanticsMapper::MapNodes(&update);
    ASSERT_EQ(mapped.buffer.size(), AndroidSemanticsMapper::kBytesPerNode);
    const int32_t* buf32 =
        reinterpret_cast<const int32_t*>(mapped.buffer.data());
    EXPECT_EQ(buf32[15], static_cast<int32_t>(kFlutterSemanticsRoleNone));
  }
}

TEST(AndroidSemanticsMapperTest,
     ZeroHitTestChildCountWithNonZeroTraversalChildren) {
  int32_t traversal_children[] = {1, 2};
  int32_t dummy_hit_test[] = {1, 2};

  FlutterSemanticsNode2 node = {};
  node.struct_size = sizeof(FlutterSemanticsNode2);
  node.id = 1;
  node.child_count = 2;
  node.children_in_traversal_order = traversal_children;
  node.hit_test_child_count = 0;
  node.children_in_hit_test_order = dummy_hit_test;

  FlutterSemanticsNode2* nodes[] = {&node};
  FlutterSemanticsUpdate2 update = {};
  update.struct_size = sizeof(FlutterSemanticsUpdate2);
  update.node_count = 1;
  update.nodes = nodes;

  MappedSemanticsNodes mapped = AndroidSemanticsMapper::MapNodes(&update);
  // 73 fixed ints + 2 traversal children + 0 hit-test children = 75 ints.
  ASSERT_EQ(mapped.buffer.size(), 75 * sizeof(int32_t));
  const int32_t* buf32 = reinterpret_cast<const int32_t*>(mapped.buffer.data());
  EXPECT_EQ(buf32[70], 2);  // traversal child count
  EXPECT_EQ(buf32[71], 1);
  EXPECT_EQ(buf32[72], 2);
  EXPECT_EQ(buf32[73], 0);  // hit-test child count
  EXPECT_EQ(buf32[74], 0);  // custom actions count
}

TEST(AndroidSemanticsMapperTest, MapCustomActionsSerializesFieldsAndStrings) {
  FlutterSemanticsCustomAction2 action1 = {};
  action1.struct_size = sizeof(FlutterSemanticsCustomAction2);
  action1.id = 10;
  int32_t unset_override = -1;
  std::memcpy(&action1.override_action, &unset_override, sizeof(int32_t));
  action1.label = "Delete";
  action1.hint = "Double tap to delete";

  FlutterSemanticsCustomAction2 action2 = {};
  action2.struct_size = sizeof(FlutterSemanticsCustomAction2);
  action2.id = 11;
  int32_t override_val = 5;
  std::memcpy(&action2.override_action, &override_val, sizeof(int32_t));
  action2.label = "Archive";
  action2.hint = nullptr;

  FlutterSemanticsCustomAction2* actions[] = {&action1, &action2};
  FlutterSemanticsUpdate2 update = {};
  update.struct_size = sizeof(FlutterSemanticsUpdate2);
  update.custom_action_count = 2;
  update.custom_actions = actions;

  MappedCustomActions mapped =
      AndroidSemanticsMapper::MapCustomActions(&update);
  ASSERT_EQ(mapped.buffer.size(), 2 * AndroidSemanticsMapper::kBytesPerAction);
  const int32_t* buf32 = reinterpret_cast<const int32_t*>(mapped.buffer.data());

  EXPECT_EQ(buf32[0], 10);
  EXPECT_EQ(buf32[1], -1);
  EXPECT_EQ(buf32[2], 0);  // "Delete"
  EXPECT_EQ(buf32[3], 1);  // "Double tap to delete"

  EXPECT_EQ(buf32[4], 11);
  EXPECT_EQ(buf32[5], 5);
  EXPECT_EQ(buf32[6], 2);   // "Archive"
  EXPECT_EQ(buf32[7], -1);  // null hint

  ASSERT_EQ(mapped.strings.size(), 3u);
  EXPECT_EQ(mapped.strings[0], "Delete");
  EXPECT_EQ(mapped.strings[1], "Double tap to delete");
  EXPECT_EQ(mapped.strings[2], "Archive");
}

TEST(AndroidSemanticsMapperTest,
     DispatchSemanticsActionRoutesThroughSendSemanticsAction) {
  static FlutterSendSemanticsActionInfo captured_info = {};
  static std::vector<uint8_t> captured_bytes;
  static FLUTTER_API_SYMBOL(FlutterEngine) captured_engine = nullptr;

  captured_info = {};
  captured_bytes.clear();
  captured_engine = nullptr;

  FlutterEngineProcTable procs = {};
  procs.struct_size = sizeof(FlutterEngineProcTable);
  procs.SendSemanticsAction = [](FLUTTER_API_SYMBOL(FlutterEngine) engine,
                                 const FlutterSendSemanticsActionInfo* info) {
    captured_engine = engine;
    if (info != nullptr) {
      captured_info = *info;
      if (info->data != nullptr && info->data_length > 0) {
        captured_bytes.assign(info->data, info->data + info->data_length);
      }
    }
    return kSuccess;
  };

  auto fake_engine =
      reinterpret_cast<FLUTTER_API_SYMBOL(FlutterEngine)>(0x1234);
  const uint8_t payload[] = {0x01, 0x02, 0x03};

  FlutterEngineResult res = AndroidSemanticsMapper::DispatchSemanticsAction(
      procs, fake_engine, /*view_id=*/2, /*node_id=*/99,
      kFlutterSemanticsActionSetSelection, payload, sizeof(payload));

  EXPECT_EQ(res, kSuccess);
  EXPECT_EQ(captured_engine, fake_engine);
  EXPECT_EQ(captured_info.struct_size, sizeof(FlutterSendSemanticsActionInfo));
  EXPECT_EQ(captured_info.view_id, 2);
  EXPECT_EQ(captured_info.node_id, 99u);
  EXPECT_EQ(captured_info.action, kFlutterSemanticsActionSetSelection);
  ASSERT_EQ(captured_bytes.size(), 3u);
  EXPECT_EQ(captured_bytes[0], 0x01);
  EXPECT_EQ(captured_bytes[1], 0x02);
  EXPECT_EQ(captured_bytes[2], 0x03);
}

TEST(AndroidSemanticsMapperTest, RejectsMalformedInputsSafely) {
  FlutterSemanticsNode2 node = {};
  node.struct_size = sizeof(FlutterSemanticsNode2);
  node.child_count = 5;
  node.children_in_traversal_order = nullptr;  // Invalid: non-zero count, null.

  FlutterSemanticsNode2* nodes[] = {&node};
  FlutterSemanticsUpdate2 update = {};
  update.struct_size = sizeof(FlutterSemanticsUpdate2);
  update.node_count = 1;
  update.nodes = nodes;

  MappedSemanticsNodes mapped = AndroidSemanticsMapper::MapNodes(&update);
  EXPECT_TRUE(mapped.buffer.empty());
}

}  // namespace flutter::android::testing
