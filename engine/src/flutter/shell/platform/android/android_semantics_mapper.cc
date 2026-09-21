// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_semantics_mapper.h"

#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/embedder/embedder_struct_macros.h"

namespace flutter {
namespace android {

void AndroidSemanticsMapper::PutStringIntoBuffer(
    const char* str,
    int32_t* buffer,
    size_t* position,
    std::vector<std::string>& strings) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::PutStringIntoBuffer");
  if (!str || str[0] == '\0') {
    buffer[(*position)++] = kEmptyStringIndex;
  } else {
    buffer[(*position)++] = static_cast<int32_t>(strings.size());
    strings.push_back(std::string(str));
  }
}

void AndroidSemanticsMapper::PutStringAttributesIntoBuffer(
    const FlutterStringAttribute** attributes,
    size_t count,
    int32_t* buffer,
    size_t* position,
    std::vector<std::vector<uint8_t>>& string_attribute_args) {
  TRACE_EVENT0("flutter",
               "AndroidSemanticsMapper::PutStringAttributesIntoBuffer");
  if (!attributes || count == 0) {
    buffer[(*position)++] = kEmptyStringIndex;
    return;
  }
  buffer[(*position)++] = static_cast<int32_t>(count);
  for (size_t i = 0; i < count; ++i) {
    const FlutterStringAttribute* attribute = attributes[i];
    if (!attribute) {
      buffer[(*position)++] = 0;                                // start
      buffer[(*position)++] = 0;                                // end
      buffer[(*position)++] = static_cast<int32_t>(kSpellOut);  // type
      buffer[(*position)++] = kEmptyStringIndex;
      continue;
    }
    buffer[(*position)++] = static_cast<int32_t>(attribute->start);
    buffer[(*position)++] = static_cast<int32_t>(attribute->end);
    buffer[(*position)++] = static_cast<int32_t>(attribute->type);
    switch (attribute->type) {
      case kSpellOut:
        buffer[(*position)++] = kEmptyStringIndex;
        break;
      case kLocale:
        buffer[(*position)++] =
            static_cast<int32_t>(string_attribute_args.size());
        if (attribute->locale && attribute->locale->locale) {
          std::string loc(attribute->locale->locale);
          string_attribute_args.push_back(
              std::vector<uint8_t>(loc.begin(), loc.end()));
        } else {
          string_attribute_args.push_back({});
        }
        break;
      default:
        FML_LOG(WARNING) << "Unknown FlutterStringAttributeType: "
                         << attribute->type;
        buffer[(*position)++] = kEmptyStringIndex;
        break;
    }
  }
}

int64_t AndroidSemanticsMapper::EncodeFlags(
    const FlutterSemanticsFlags* flags2,
    FlutterSemanticsFlag deprecated_flags) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::EncodeFlags");
  if (!flags2) {
    return static_cast<int64_t>(deprecated_flags);
  }
  int64_t result = 0;
  if (flags2->is_checked != kFlutterCheckStateNone) {
    result |= (INT64_C(1) << 0);
  }
  if (flags2->is_checked == kFlutterCheckStateTrue) {
    result |= (INT64_C(1) << 1);
  }
  if (flags2->is_selected == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 2);
  }
  if (flags2->is_button) {
    result |= (INT64_C(1) << 3);
  }
  if (flags2->is_text_field) {
    result |= (INT64_C(1) << 4);
  }
  if (flags2->is_focused == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 5);
  }
  if (flags2->is_enabled != kFlutterTristateNone) {
    result |= (INT64_C(1) << 6);
  }
  if (flags2->is_enabled == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 7);
  }
  if (flags2->is_in_mutually_exclusive_group) {
    result |= (INT64_C(1) << 8);
  }
  if (flags2->is_header) {
    result |= (INT64_C(1) << 9);
  }
  if (flags2->is_obscured) {
    result |= (INT64_C(1) << 10);
  }
  if (flags2->scopes_route) {
    result |= (INT64_C(1) << 11);
  }
  if (flags2->names_route) {
    result |= (INT64_C(1) << 12);
  }
  if (flags2->is_hidden) {
    result |= (INT64_C(1) << 13);
  }
  if (flags2->is_image) {
    result |= (INT64_C(1) << 14);
  }
  if (flags2->is_live_region) {
    result |= (INT64_C(1) << 15);
  }
  if (flags2->is_toggled != kFlutterTristateNone) {
    result |= (INT64_C(1) << 16);
  }
  if (flags2->is_toggled == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 17);
  }
  if (flags2->has_implicit_scrolling) {
    result |= (INT64_C(1) << 18);
  }
  if (flags2->is_multiline) {
    result |= (INT64_C(1) << 19);
  }
  if (flags2->is_read_only) {
    result |= (INT64_C(1) << 20);
  }
  if (flags2->is_focused != kFlutterTristateNone) {
    result |= (INT64_C(1) << 21);
  }
  if (flags2->is_link) {
    result |= (INT64_C(1) << 22);
  }
  if (flags2->is_slider) {
    result |= (INT64_C(1) << 23);
  }
  if (flags2->is_keyboard_key) {
    result |= (INT64_C(1) << 24);
  }
  if (flags2->is_checked == kFlutterCheckStateMixed) {
    result |= (INT64_C(1) << 25);
  }
  if (flags2->is_expanded != kFlutterTristateNone) {
    result |= (INT64_C(1) << 26);
  }
  if (flags2->is_expanded == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 27);
  }
  if (flags2->is_selected != kFlutterTristateNone) {
    result |= (INT64_C(1) << 28);
  }
  if (flags2->is_required != kFlutterTristateNone) {
    result |= (INT64_C(1) << 29);
  }
  if (flags2->is_required == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 30);
  }
  if (flags2->is_accessibility_focus_blocked) {
    result |= (INT64_C(1) << 31);
  }
  return result;
}

void AndroidSemanticsMapper::EncodeTransformation(
    const FlutterTransformation& transform,
    float* out_col_major_16) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::EncodeTransformation");
  if (!out_col_major_16) {
    return;
  }
  // Check if transformation is all zeros (uninitialized default)
  if (transform.scaleX == 0.0 && transform.scaleY == 0.0 &&
      transform.skewX == 0.0 && transform.skewY == 0.0 &&
      transform.transX == 0.0 && transform.transY == 0.0 &&
      transform.pers0 == 0.0 && transform.pers1 == 0.0 &&
      transform.pers2 == 0.0) {
    std::memset(out_col_major_16, 0, 16 * sizeof(float));
    out_col_major_16[0] = 1.0f;
    out_col_major_16[5] = 1.0f;
    out_col_major_16[10] = 1.0f;
    out_col_major_16[15] = 1.0f;
    return;
  }

  // Column 0
  out_col_major_16[0] = static_cast<float>(transform.scaleX);
  out_col_major_16[1] = static_cast<float>(transform.skewY);
  out_col_major_16[2] = 0.0f;
  out_col_major_16[3] = static_cast<float>(transform.pers0);

  // Column 1
  out_col_major_16[4] = static_cast<float>(transform.skewX);
  out_col_major_16[5] = static_cast<float>(transform.scaleY);
  out_col_major_16[6] = 0.0f;
  out_col_major_16[7] = static_cast<float>(transform.pers1);

  // Column 2
  out_col_major_16[8] = 0.0f;
  out_col_major_16[9] = 0.0f;
  out_col_major_16[10] = 1.0f;
  out_col_major_16[11] = 0.0f;

  // Column 3
  out_col_major_16[12] = static_cast<float>(transform.transX);
  out_col_major_16[13] = static_cast<float>(transform.transY);
  out_col_major_16[14] = 0.0f;
  out_col_major_16[15] =
      static_cast<float>(transform.pers2 != 0.0 ? transform.pers2 : 1.0);
}

EncodedSemanticsUpdate AndroidSemanticsMapper::MapNodes(
    const FlutterSemanticsNode2** nodes,
    size_t count) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::MapNodes");
  EncodedSemanticsUpdate result;
  if (!nodes || count == 0) {
    return result;
  }
  if (count > kMaxSemanticsNodes) {
    FML_LOG(ERROR) << "Semantics node count exceeds ceiling: " << count;
    return result;
  }

  size_t num_bytes = 0;
  for (size_t i = 0; i < count; ++i) {
    const FlutterSemanticsNode2* node = nodes[i];
    if (!node) {
      continue;
    }
    if (node->struct_size < kMinSemanticsNode2Size) {
      FML_LOG(ERROR) << "Invalid FlutterSemanticsNode2 struct size: "
                     << node->struct_size;
      return {};
    }
    if (node->child_count > kMaxSemanticsChildren) {
      FML_LOG(ERROR) << "Semantics child count exceeds ceiling: "
                     << node->child_count;
      return {};
    }
    if (node->custom_accessibility_actions_count > kMaxSemanticsActions) {
      FML_LOG(ERROR) << "Semantics custom actions count exceeds ceiling: "
                     << node->custom_accessibility_actions_count;
      return {};
    }
    if (node->label_attribute_count > kMaxStringAttributes ||
        node->value_attribute_count > kMaxStringAttributes ||
        node->increased_value_attribute_count > kMaxStringAttributes ||
        node->decreased_value_attribute_count > kMaxStringAttributes ||
        node->hint_attribute_count > kMaxStringAttributes) {
      FML_LOG(ERROR) << "Semantics string attribute count exceeds ceiling";
      return {};
    }

    size_t node_bytes = kBytesPerNode;
    if (node->children_in_traversal_order && node->child_count > 0) {
      node_bytes += node->child_count * kBytesPerChild;
    }
    if (node->children_in_hit_test_order && node->child_count > 0) {
      node_bytes += node->child_count * kBytesPerChild;
    }
    if (node->custom_accessibility_actions &&
        node->custom_accessibility_actions_count > 0) {
      node_bytes +=
          node->custom_accessibility_actions_count * kBytesPerCustomAction;
    }
    if (node->label_attributes && node->label_attribute_count > 0) {
      node_bytes += node->label_attribute_count * kBytesPerStringAttribute;
    }
    if (node->value_attributes && node->value_attribute_count > 0) {
      node_bytes += node->value_attribute_count * kBytesPerStringAttribute;
    }
    if (node->increased_value_attributes &&
        node->increased_value_attribute_count > 0) {
      node_bytes +=
          node->increased_value_attribute_count * kBytesPerStringAttribute;
    }
    if (node->decreased_value_attributes &&
        node->decreased_value_attribute_count > 0) {
      node_bytes +=
          node->decreased_value_attribute_count * kBytesPerStringAttribute;
    }
    if (node->hint_attributes && node->hint_attribute_count > 0) {
      node_bytes += node->hint_attribute_count * kBytesPerStringAttribute;
    }

    num_bytes += node_bytes;
    if (num_bytes > kMaxSemanticsBufferBytes) {
      FML_LOG(ERROR) << "Semantics buffer exceeds maximum allowed bytes: "
                     << num_bytes;
      return {};
    }
  }

  if (num_bytes == 0) {
    return result;
  }

  result.buffer.resize(num_bytes);
  int32_t* buffer_int32 = reinterpret_cast<int32_t*>(result.buffer.data());
  float* buffer_float32 = reinterpret_cast<float*>(result.buffer.data());

  size_t position = 0;
  for (size_t i = 0; i < count; ++i) {
    const FlutterSemanticsNode2* node = nodes[i];
    if (!node) {
      continue;
    }
    buffer_int32[position++] = node->id;
    int64_t flags = EncodeFlags(node->flags2, node->flags__deprecated__);
    std::memcpy(&buffer_int32[position], &flags, sizeof(int64_t));
    position += 2;
    buffer_int32[position++] = node->actions;
    buffer_int32[position++] = 0;  // maxValueLength
    buffer_int32[position++] =
        node->value ? static_cast<int32_t>(std::strlen(node->value))
                    : 0;  // currentValueLength
    buffer_int32[position++] = node->text_selection_base;
    buffer_int32[position++] = node->text_selection_extent;
    buffer_int32[position++] = static_cast<int32_t>(node->platform_view_id);
    buffer_int32[position++] = node->scroll_child_count;
    buffer_int32[position++] = node->scroll_index;
    buffer_int32[position++] = -1;  // traversalParent
    buffer_float32[position++] = static_cast<float>(node->scroll_position);
    buffer_float32[position++] = static_cast<float>(node->scroll_extent_max);
    buffer_float32[position++] = static_cast<float>(node->scroll_extent_min);
    FlutterSemanticsRole role =
        SAFE_ACCESS(node, role, kFlutterSemanticsRoleNone);
    if (static_cast<int32_t>(role) <
            static_cast<int32_t>(kFlutterSemanticsRoleNone) ||
        static_cast<int32_t>(role) >
            static_cast<int32_t>(kFlutterSemanticsRoleRegion)) {
      role = kFlutterSemanticsRoleNone;
    }
    buffer_int32[position++] = static_cast<int32_t>(role);

    PutStringIntoBuffer(node->identifier, buffer_int32, &position,
                        result.strings);

    PutStringIntoBuffer(node->label, buffer_int32, &position, result.strings);
    PutStringAttributesIntoBuffer(node->label_attributes,
                                  node->label_attribute_count, buffer_int32,
                                  &position, result.string_attribute_args);

    PutStringIntoBuffer(node->value, buffer_int32, &position, result.strings);
    PutStringAttributesIntoBuffer(node->value_attributes,
                                  node->value_attribute_count, buffer_int32,
                                  &position, result.string_attribute_args);

    PutStringIntoBuffer(node->increased_value, buffer_int32, &position,
                        result.strings);
    PutStringAttributesIntoBuffer(
        node->increased_value_attributes, node->increased_value_attribute_count,
        buffer_int32, &position, result.string_attribute_args);

    PutStringIntoBuffer(node->decreased_value, buffer_int32, &position,
                        result.strings);
    PutStringAttributesIntoBuffer(
        node->decreased_value_attributes, node->decreased_value_attribute_count,
        buffer_int32, &position, result.string_attribute_args);

    PutStringIntoBuffer(node->hint, buffer_int32, &position, result.strings);
    PutStringAttributesIntoBuffer(node->hint_attributes,
                                  node->hint_attribute_count, buffer_int32,
                                  &position, result.string_attribute_args);

    PutStringIntoBuffer(node->tooltip, buffer_int32, &position, result.strings);
    PutStringIntoBuffer(
        nullptr, buffer_int32, &position,
        result.strings);  // linkUrl (unsupported in FlutterSemanticsNode2)
    PutStringIntoBuffer(
        nullptr, buffer_int32, &position,
        result.strings);  // locale (unsupported in FlutterSemanticsNode2)
    PutStringIntoBuffer(
        nullptr, buffer_int32, &position,
        result.strings);  // minValue (unsupported in FlutterSemanticsNode2)
    PutStringIntoBuffer(
        nullptr, buffer_int32, &position,
        result.strings);  // maxValue (unsupported in FlutterSemanticsNode2)

    buffer_int32[position++] = node->heading_level;
    buffer_int32[position++] = static_cast<int32_t>(node->text_direction);
    buffer_float32[position++] = static_cast<float>(node->rect.left);
    buffer_float32[position++] = static_cast<float>(node->rect.top);
    buffer_float32[position++] = static_cast<float>(node->rect.right);
    buffer_float32[position++] = static_cast<float>(node->rect.bottom);

    EncodeTransformation(node->transform, &buffer_float32[position]);
    position += 16;
    // hitTestTransform falls back to node->transform due to lack of distinct
    // hit test transform in FlutterSemanticsNode2.
    EncodeTransformation(node->transform, &buffer_float32[position]);
    position += 16;

    if (node->children_in_traversal_order && node->child_count > 0) {
      buffer_int32[position++] = static_cast<int32_t>(node->child_count);
      for (size_t c = 0; c < node->child_count; ++c) {
        buffer_int32[position++] = node->children_in_traversal_order[c];
      }
    } else {
      buffer_int32[position++] = 0;
    }

    if (node->children_in_hit_test_order && node->child_count > 0) {
      buffer_int32[position++] = static_cast<int32_t>(node->child_count);
      for (size_t c = 0; c < node->child_count; ++c) {
        buffer_int32[position++] = node->children_in_hit_test_order[c];
      }
    } else {
      buffer_int32[position++] = 0;
    }

    if (node->custom_accessibility_actions &&
        node->custom_accessibility_actions_count > 0) {
      buffer_int32[position++] =
          static_cast<int32_t>(node->custom_accessibility_actions_count);
      for (size_t a = 0; a < node->custom_accessibility_actions_count; ++a) {
        buffer_int32[position++] = node->custom_accessibility_actions[a];
      }
    } else {
      buffer_int32[position++] = 0;
    }
  }

  FML_CHECK(position * sizeof(int32_t) == result.buffer.size())
      << "Buffer write position mismatch: wrote " << position * sizeof(int32_t)
      << " bytes, allocated " << result.buffer.size() << " bytes";

  return result;
}

EncodedCustomAccessibilityActions AndroidSemanticsMapper::MapCustomActions(
    const FlutterSemanticsCustomAction2** actions,
    size_t count) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::MapCustomActions");
  EncodedCustomAccessibilityActions result;
  if (!actions || count == 0) {
    return result;
  }
  if (count > kMaxSemanticsActions) {
    FML_LOG(ERROR) << "Custom actions count exceeds ceiling: " << count;
    return result;
  }

  size_t num_action_bytes = count * kBytesPerAction;
  result.buffer.resize(num_action_bytes);
  int32_t* actions_buffer_int32 =
      reinterpret_cast<int32_t*>(result.buffer.data());

  size_t actions_position = 0;
  for (size_t i = 0; i < count; ++i) {
    const FlutterSemanticsCustomAction2* action = actions[i];
    if (!action) {
      continue;
    }
    if (action->struct_size < sizeof(FlutterSemanticsCustomAction2)) {
      FML_LOG(ERROR) << "Invalid FlutterSemanticsCustomAction2 struct size: "
                     << action->struct_size;
      continue;
    }
    actions_buffer_int32[actions_position++] = action->id;
    actions_buffer_int32[actions_position++] =
        static_cast<int32_t>(action->override_action);
    PutStringIntoBuffer(action->label, actions_buffer_int32, &actions_position,
                        result.strings);
    PutStringIntoBuffer(action->hint, actions_buffer_int32, &actions_position,
                        result.strings);
  }

  result.buffer.resize(actions_position * sizeof(int32_t));
  return result;
}

EncodedSemanticsBatch AndroidSemanticsMapper::MapSemanticsUpdate(
    const FlutterSemanticsUpdate2& update) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::MapSemanticsUpdate");
  EncodedSemanticsBatch batch;
  if (update.struct_size < sizeof(FlutterSemanticsUpdate2)) {
    FML_LOG(ERROR) << "Invalid FlutterSemanticsUpdate2 struct size: "
                   << update.struct_size;
    return batch;
  }
  batch.view_id = update.view_id;
  if (update.nodes && update.node_count > 0) {
    batch.nodes =
        MapNodes(const_cast<const FlutterSemanticsNode2**>(update.nodes),
                 update.node_count);
  }
  if (update.custom_actions && update.custom_action_count > 0) {
    batch.custom_actions =
        MapCustomActions(const_cast<const FlutterSemanticsCustomAction2**>(
                             update.custom_actions),
                         update.custom_action_count);
  }
  return batch;
}

}  // namespace android
}  // namespace flutter
