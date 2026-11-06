// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/android_semantics_mapper.h"

#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/platform/embedder/embedder_struct_macros.h"

namespace flutter::android {

namespace {

// Upper bounds used to validate incoming C-API array counts and prevent
// out-of-bounds or integer-overflow allocations on malformed inputs.
constexpr size_t kMaxSemanticsNodes = 100000;
constexpr size_t kMaxSemanticsChildren = 100000;
constexpr size_t kMaxSemanticsActions = 10000;
constexpr size_t kMaxStringAttributes = 10000;
constexpr size_t kMaxStringByteLength = 1024 * 1024;  // 1 MiB max per string.

// Default sentinel values for optional integer fields in AccessibilityBridge.
constexpr int32_t kDefaultUnsetLength = -1;
constexpr int32_t kDefaultUnsetTraversalParent = -1;
constexpr int64_t kDefaultImplicitViewId = 0;

// Number of 32-bit int words occupied by a 64-bit semantics flags bitmask.
constexpr size_t kInt32WordsPerInt64Flags = 2;

// Bit positions in the 64-bit semantics flags bitmask read by
// AccessibilityBridge.java (AccessibilityBridge.Flag).
constexpr int kFlagBitHasCheckedState = 0;
constexpr int kFlagBitIsChecked = 1;
constexpr int kFlagBitIsSelected = 2;
constexpr int kFlagBitIsButton = 3;
constexpr int kFlagBitIsTextField = 4;
constexpr int kFlagBitIsFocused = 5;
constexpr int kFlagBitHasEnabledState = 6;
constexpr int kFlagBitIsEnabled = 7;
constexpr int kFlagBitIsInMutuallyExclusiveGroup = 8;
constexpr int kFlagBitIsHeader = 9;
constexpr int kFlagBitIsObscured = 10;
constexpr int kFlagBitScopesRoute = 11;
constexpr int kFlagBitNamesRoute = 12;
constexpr int kFlagBitIsHidden = 13;
constexpr int kFlagBitIsImage = 14;
constexpr int kFlagBitIsLiveRegion = 15;
constexpr int kFlagBitHasToggledState = 16;
constexpr int kFlagBitIsToggled = 17;
constexpr int kFlagBitHasImplicitScrolling = 18;
constexpr int kFlagBitIsMultiline = 19;
constexpr int kFlagBitIsReadOnly = 20;
constexpr int kFlagBitIsFocusable = 21;
constexpr int kFlagBitIsLink = 22;
constexpr int kFlagBitIsSlider = 23;
constexpr int kFlagBitIsKeyboardKey = 24;
constexpr int kFlagBitIsCheckStateMixed = 25;
constexpr int kFlagBitHasExpandedState = 26;
constexpr int kFlagBitIsExpanded = 27;
constexpr int kFlagBitHasSelectedState = 28;
constexpr int kFlagBitHasRequiredState = 29;
constexpr int kFlagBitIsRequired = 30;
constexpr int kFlagBitIsAccessibilityFocusBlocked = 31;

// Column-major 4x4 matrix element indices for mapping a 3x3
// FlutterTransformation into a 4x4 homogeneous matrix (with Z as identity).
constexpr size_t kMatCol0Row0 = 0;
constexpr size_t kMatCol0Row1 = 1;
constexpr size_t kMatCol0Row2 = 2;
constexpr size_t kMatCol0Row3 = 3;
constexpr size_t kMatCol1Row0 = 4;
constexpr size_t kMatCol1Row1 = 5;
constexpr size_t kMatCol1Row2 = 6;
constexpr size_t kMatCol1Row3 = 7;
constexpr size_t kMatCol2Row0 = 8;
constexpr size_t kMatCol2Row1 = 9;
constexpr size_t kMatCol2Row2 = 10;
constexpr size_t kMatCol2Row3 = 11;
constexpr size_t kMatCol3Row0 = 12;
constexpr size_t kMatCol3Row1 = 13;
constexpr size_t kMatCol3Row2 = 14;
constexpr size_t kMatCol3Row3 = 15;

bool IsValidStringAttributesArray(
    const FlutterStringAttribute* const* attributes,
    size_t count) {
  if (count == 0) {
    return true;
  }
  if (attributes == nullptr || count > kMaxStringAttributes) {
    return false;
  }
  for (size_t i = 0; i < count; ++i) {
    const FlutterStringAttribute* attr = attributes[i];
    if (attr == nullptr) {
      return false;
    }
    if (attr->struct_size == 0 ||
        attr->struct_size > sizeof(FlutterStringAttribute)) {
      return false;
    }
    FlutterStringAttributeType type = SAFE_ACCESS(attr, type, kSpellOut);
    if (type == kLocale) {
      const FlutterLocaleStringAttribute* locale_attr =
          SAFE_ACCESS(attr, locale, nullptr);
      if (locale_attr != nullptr) {
        if (locale_attr->struct_size == 0 ||
            locale_attr->struct_size > sizeof(FlutterLocaleStringAttribute)) {
          return false;
        }
      }
    } else if (type != kSpellOut) {
      return false;
    }
  }
  return true;
}

void PutStringIntoBuffer(const char* c_str,
                         int32_t* buffer,
                         size_t* position,
                         std::vector<std::string>& strings) {
  if (c_str == nullptr || c_str[0] == '\0') {
    buffer[(*position)++] = AndroidSemanticsMapper::kEmptyStringIndex;
  } else {
    size_t len = strnlen(c_str, kMaxStringByteLength);
    buffer[(*position)++] = static_cast<int32_t>(strings.size());
    strings.emplace_back(c_str, len);
  }
}

void PutStringAttributesIntoBuffer(
    const FlutterStringAttribute* const* attributes,
    size_t count,
    int32_t* buffer,
    size_t* position,
    std::vector<std::vector<uint8_t>>& string_attribute_args) {
  if (attributes == nullptr || count == 0) {
    buffer[(*position)++] = AndroidSemanticsMapper::kEmptyStringIndex;
    return;
  }
  buffer[(*position)++] = static_cast<int32_t>(count);
  for (size_t i = 0; i < count; ++i) {
    const FlutterStringAttribute* attr = attributes[i];
    if (attr == nullptr) {
      buffer[(*position)++] = 0;
      buffer[(*position)++] = 0;
      buffer[(*position)++] = 0;
      buffer[(*position)++] = AndroidSemanticsMapper::kEmptyStringIndex;
      continue;
    }
    buffer[(*position)++] = static_cast<int32_t>(SAFE_ACCESS(attr, start, 0));
    buffer[(*position)++] = static_cast<int32_t>(SAFE_ACCESS(attr, end, 0));
    FlutterStringAttributeType type = SAFE_ACCESS(attr, type, kSpellOut);
    buffer[(*position)++] = static_cast<int32_t>(type);
    switch (type) {
      case kSpellOut:
        buffer[(*position)++] = AndroidSemanticsMapper::kEmptyStringIndex;
        break;
      case kLocale: {
        const FlutterLocaleStringAttribute* locale_attr =
            SAFE_ACCESS(attr, locale, nullptr);
        const char* locale_str = (locale_attr != nullptr)
                                     ? SAFE_ACCESS(locale_attr, locale, nullptr)
                                     : nullptr;
        if (locale_str != nullptr) {
          size_t len = strnlen(locale_str, kMaxStringByteLength);
          buffer[(*position)++] =
              static_cast<int32_t>(string_attribute_args.size());
          string_attribute_args.emplace_back(
              reinterpret_cast<const uint8_t*>(locale_str),
              reinterpret_cast<const uint8_t*>(locale_str) + len);
        } else {
          buffer[(*position)++] = AndroidSemanticsMapper::kEmptyStringIndex;
        }
        break;
      }
      default:
        buffer[(*position)++] = AndroidSemanticsMapper::kEmptyStringIndex;
        break;
    }
  }
}

bool IsZeroTransform(const FlutterTransformation& t) {
  return t.scaleX == 0.0 && t.skewX == 0.0 && t.transX == 0.0 &&
         t.skewY == 0.0 && t.scaleY == 0.0 && t.transY == 0.0 &&
         t.pers0 == 0.0 && t.pers1 == 0.0 && t.pers2 == 0.0;
}

}  // namespace

int64_t AndroidSemanticsMapper::EncodeFlags(
    const FlutterSemanticsFlags* flags2,
    FlutterSemanticsFlag deprecated_flags) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::EncodeFlags");
  int64_t result = 0;
  if (flags2 != nullptr) {
    FlutterCheckState is_checked =
        SAFE_ACCESS(flags2, is_checked, kFlutterCheckStateNone);
    FlutterTristate is_selected =
        SAFE_ACCESS(flags2, is_selected, kFlutterTristateNone);
    FlutterTristate is_enabled =
        SAFE_ACCESS(flags2, is_enabled, kFlutterTristateNone);
    FlutterTristate is_toggled =
        SAFE_ACCESS(flags2, is_toggled, kFlutterTristateNone);
    FlutterTristate is_expanded =
        SAFE_ACCESS(flags2, is_expanded, kFlutterTristateNone);
    FlutterTristate is_focused =
        SAFE_ACCESS(flags2, is_focused, kFlutterTristateNone);
    FlutterTristate is_required =
        SAFE_ACCESS(flags2, is_required, kFlutterTristateNone);

    if (is_checked != kFlutterCheckStateNone) {
      result |= (INT64_C(1) << kFlagBitHasCheckedState);
    }
    if (is_checked == kFlutterCheckStateTrue) {
      result |= (INT64_C(1) << kFlagBitIsChecked);
    }
    if (is_selected == kFlutterTristateTrue) {
      result |= (INT64_C(1) << kFlagBitIsSelected);
    }
    if (SAFE_ACCESS(flags2, is_button, false)) {
      result |= (INT64_C(1) << kFlagBitIsButton);
    }
    if (SAFE_ACCESS(flags2, is_text_field, false)) {
      result |= (INT64_C(1) << kFlagBitIsTextField);
    }
    if (is_focused == kFlutterTristateTrue) {
      result |= (INT64_C(1) << kFlagBitIsFocused);
    }
    if (is_enabled != kFlutterTristateNone) {
      result |= (INT64_C(1) << kFlagBitHasEnabledState);
    }
    if (is_enabled == kFlutterTristateTrue) {
      result |= (INT64_C(1) << kFlagBitIsEnabled);
    }
    if (SAFE_ACCESS(flags2, is_in_mutually_exclusive_group, false)) {
      result |= (INT64_C(1) << kFlagBitIsInMutuallyExclusiveGroup);
    }
    if (SAFE_ACCESS(flags2, is_header, false)) {
      result |= (INT64_C(1) << kFlagBitIsHeader);
    }
    if (SAFE_ACCESS(flags2, is_obscured, false)) {
      result |= (INT64_C(1) << kFlagBitIsObscured);
    }
    if (SAFE_ACCESS(flags2, scopes_route, false)) {
      result |= (INT64_C(1) << kFlagBitScopesRoute);
    }
    if (SAFE_ACCESS(flags2, names_route, false)) {
      result |= (INT64_C(1) << kFlagBitNamesRoute);
    }
    if (SAFE_ACCESS(flags2, is_hidden, false)) {
      result |= (INT64_C(1) << kFlagBitIsHidden);
    }
    if (SAFE_ACCESS(flags2, is_image, false)) {
      result |= (INT64_C(1) << kFlagBitIsImage);
    }
    if (SAFE_ACCESS(flags2, is_live_region, false)) {
      result |= (INT64_C(1) << kFlagBitIsLiveRegion);
    }
    if (is_toggled != kFlutterTristateNone) {
      result |= (INT64_C(1) << kFlagBitHasToggledState);
    }
    if (is_toggled == kFlutterTristateTrue) {
      result |= (INT64_C(1) << kFlagBitIsToggled);
    }
    if (SAFE_ACCESS(flags2, has_implicit_scrolling, false)) {
      result |= (INT64_C(1) << kFlagBitHasImplicitScrolling);
    }
    if (SAFE_ACCESS(flags2, is_multiline, false)) {
      result |= (INT64_C(1) << kFlagBitIsMultiline);
    }
    if (SAFE_ACCESS(flags2, is_read_only, false)) {
      result |= (INT64_C(1) << kFlagBitIsReadOnly);
    }
    if (is_focused != kFlutterTristateNone) {
      result |= (INT64_C(1) << kFlagBitIsFocusable);
    }
    if (SAFE_ACCESS(flags2, is_link, false)) {
      result |= (INT64_C(1) << kFlagBitIsLink);
    }
    if (SAFE_ACCESS(flags2, is_slider, false)) {
      result |= (INT64_C(1) << kFlagBitIsSlider);
    }
    if (SAFE_ACCESS(flags2, is_keyboard_key, false)) {
      result |= (INT64_C(1) << kFlagBitIsKeyboardKey);
    }
    if (is_checked == kFlutterCheckStateMixed) {
      result |= (INT64_C(1) << kFlagBitIsCheckStateMixed);
    }
    if (is_expanded != kFlutterTristateNone) {
      result |= (INT64_C(1) << kFlagBitHasExpandedState);
    }
    if (is_expanded == kFlutterTristateTrue) {
      result |= (INT64_C(1) << kFlagBitIsExpanded);
    }
    if (is_selected != kFlutterTristateNone) {
      result |= (INT64_C(1) << kFlagBitHasSelectedState);
    }
    if (is_required != kFlutterTristateNone) {
      result |= (INT64_C(1) << kFlagBitHasRequiredState);
    }
    if (is_required == kFlutterTristateTrue) {
      result |= (INT64_C(1) << kFlagBitIsRequired);
    }
    if (SAFE_ACCESS(flags2, is_accessibility_focus_blocked, false)) {
      result |= (INT64_C(1) << kFlagBitIsAccessibilityFocusBlocked);
    }
  } else {
    result = static_cast<int64_t>(static_cast<uint32_t>(deprecated_flags));
  }
  return result;
}

void AndroidSemanticsMapper::EncodeTransformation(
    const FlutterTransformation& transform,
    float* out_column_major_16) {
  if (out_column_major_16 == nullptr) {
    return;
  }
  // FlutterTransformation is a 3x3 perspective matrix:
  //   | scaleX  skewX   transX |
  //   | skewY   scaleY  transY |
  //   | pers0   pers1   pers2  |
  // Map to 4x4 column-major matrix (inserting 3rd row/col as identity Z):
  out_column_major_16[kMatCol0Row0] = static_cast<float>(transform.scaleX);
  out_column_major_16[kMatCol0Row1] = static_cast<float>(transform.skewY);
  out_column_major_16[kMatCol0Row2] = 0.0f;
  out_column_major_16[kMatCol0Row3] = static_cast<float>(transform.pers0);

  out_column_major_16[kMatCol1Row0] = static_cast<float>(transform.skewX);
  out_column_major_16[kMatCol1Row1] = static_cast<float>(transform.scaleY);
  out_column_major_16[kMatCol1Row2] = 0.0f;
  out_column_major_16[kMatCol1Row3] = static_cast<float>(transform.pers1);

  out_column_major_16[kMatCol2Row0] = 0.0f;
  out_column_major_16[kMatCol2Row1] = 0.0f;
  out_column_major_16[kMatCol2Row2] = 1.0f;
  out_column_major_16[kMatCol2Row3] = 0.0f;

  out_column_major_16[kMatCol3Row0] = static_cast<float>(transform.transX);
  out_column_major_16[kMatCol3Row1] = static_cast<float>(transform.transY);
  out_column_major_16[kMatCol3Row2] = 0.0f;
  out_column_major_16[kMatCol3Row3] = static_cast<float>(transform.pers2);
}

MappedSemanticsNodes AndroidSemanticsMapper::MapNodes(
    const FlutterSemanticsUpdate2* update) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::MapNodes");
  MappedSemanticsNodes result;
  if (update == nullptr) {
    return result;
  }
  if (update->struct_size == 0 ||
      update->struct_size > sizeof(FlutterSemanticsUpdate2)) {
    return result;
  }

  size_t node_count = SAFE_ACCESS(update, node_count, 0);
  FlutterSemanticsNode2** nodes = SAFE_ACCESS(update, nodes, nullptr);
  if (node_count == 0 || nodes == nullptr || node_count > kMaxSemanticsNodes) {
    return result;
  }

  size_t num_bytes = 0;
  for (size_t i = 0; i < node_count; ++i) {
    const FlutterSemanticsNode2* node = nodes[i];
    if (node == nullptr) {
      continue;
    }
    if (node->struct_size == 0 ||
        node->struct_size > sizeof(FlutterSemanticsNode2)) {
      return {};
    }
    if (node->flags2 != nullptr) {
      if (node->flags2->struct_size == 0 ||
          node->flags2->struct_size > sizeof(FlutterSemanticsFlags)) {
        return {};
      }
    }
    if (node->child_count > kMaxSemanticsChildren ||
        (node->child_count > 0 &&
         node->children_in_traversal_order == nullptr)) {
      return {};
    }
    size_t hit_test_count =
        SAFE_ACCESS(node, hit_test_child_count, node->child_count);
    if (hit_test_count > kMaxSemanticsChildren ||
        (hit_test_count > 0 && node->children_in_hit_test_order == nullptr)) {
      return {};
    }
    if (node->custom_accessibility_actions_count > kMaxSemanticsActions ||
        (node->custom_accessibility_actions_count > 0 &&
         node->custom_accessibility_actions == nullptr)) {
      return {};
    }
    if (!IsValidStringAttributesArray(node->label_attributes,
                                      node->label_attribute_count) ||
        !IsValidStringAttributesArray(node->value_attributes,
                                      node->value_attribute_count) ||
        !IsValidStringAttributesArray(node->increased_value_attributes,
                                      node->increased_value_attribute_count) ||
        !IsValidStringAttributesArray(node->decreased_value_attributes,
                                      node->decreased_value_attribute_count) ||
        !IsValidStringAttributesArray(node->hint_attributes,
                                      node->hint_attribute_count)) {
      return {};
    }

    size_t node_bytes = kBytesPerNode;
    if (node->children_in_traversal_order != nullptr && node->child_count > 0) {
      node_bytes += node->child_count * kBytesPerChild;
    }
    if (node->children_in_hit_test_order != nullptr && hit_test_count > 0) {
      node_bytes += hit_test_count * kBytesPerChild;
    }
    if (node->custom_accessibility_actions != nullptr &&
        node->custom_accessibility_actions_count > 0) {
      node_bytes +=
          node->custom_accessibility_actions_count * kBytesPerCustomAction;
    }
    if (node->label_attributes != nullptr && node->label_attribute_count > 0) {
      node_bytes += node->label_attribute_count * kBytesPerStringAttribute;
    }
    if (node->value_attributes != nullptr && node->value_attribute_count > 0) {
      node_bytes += node->value_attribute_count * kBytesPerStringAttribute;
    }
    if (node->increased_value_attributes != nullptr &&
        node->increased_value_attribute_count > 0) {
      node_bytes +=
          node->increased_value_attribute_count * kBytesPerStringAttribute;
    }
    if (node->decreased_value_attributes != nullptr &&
        node->decreased_value_attribute_count > 0) {
      node_bytes +=
          node->decreased_value_attribute_count * kBytesPerStringAttribute;
    }
    if (node->hint_attributes != nullptr && node->hint_attribute_count > 0) {
      node_bytes += node->hint_attribute_count * kBytesPerStringAttribute;
    }
    num_bytes += node_bytes;
  }

  result.buffer.resize(num_bytes);
  if (result.buffer.empty()) {
    return result;
  }

  int32_t* buffer_int32 = reinterpret_cast<int32_t*>(result.buffer.data());
  float* buffer_float32 = reinterpret_cast<float*>(result.buffer.data());
  size_t position = 0;

  for (size_t i = 0; i < node_count; ++i) {
    const FlutterSemanticsNode2* node = nodes[i];
    if (node == nullptr) {
      continue;
    }

    buffer_int32[position++] = node->id;

    int64_t flags = EncodeFlags(node->flags2, node->flags__deprecated__);
    std::memcpy(&buffer_int32[position], &flags, sizeof(int64_t));
    position += kInt32WordsPerInt64Flags;

    buffer_int32[position++] = static_cast<int32_t>(node->actions);
    buffer_int32[position++] =
        SAFE_ACCESS(node, max_value_length, kDefaultUnsetLength);
    buffer_int32[position++] =
        SAFE_ACCESS(node, current_value_length, kDefaultUnsetLength);
    buffer_int32[position++] = node->text_selection_base;
    buffer_int32[position++] = node->text_selection_extent;
    buffer_int32[position++] = static_cast<int32_t>(node->platform_view_id);
    buffer_int32[position++] = node->scroll_child_count;
    buffer_int32[position++] = node->scroll_index;
    buffer_int32[position++] = kDefaultUnsetTraversalParent;
    buffer_float32[position++] = static_cast<float>(node->scroll_position);
    buffer_float32[position++] = static_cast<float>(node->scroll_extent_max);
    buffer_float32[position++] = static_cast<float>(node->scroll_extent_min);

    FlutterSemanticsRole raw_role =
        SAFE_ACCESS(node, role, kFlutterSemanticsRoleNone);
    int32_t role = static_cast<int32_t>(raw_role);
    if (role < static_cast<int32_t>(kFlutterSemanticsRoleNone) ||
        role > static_cast<int32_t>(kFlutterSemanticsRoleOption)) {
      role = static_cast<int32_t>(kFlutterSemanticsRoleNone);
    }
    buffer_int32[position++] = role;

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

    const char* link_url = SAFE_ACCESS(node, link_url, nullptr);
    PutStringIntoBuffer(link_url, buffer_int32, &position, result.strings);

    const char* locale = SAFE_ACCESS(node, locale, nullptr);
    PutStringIntoBuffer(locale, buffer_int32, &position, result.strings);

    const char* min_value = SAFE_ACCESS(node, min_value, nullptr);
    PutStringIntoBuffer(min_value, buffer_int32, &position, result.strings);

    const char* max_value = SAFE_ACCESS(node, max_value, nullptr);
    PutStringIntoBuffer(max_value, buffer_int32, &position, result.strings);

    buffer_int32[position++] = node->heading_level;
    buffer_int32[position++] = static_cast<int32_t>(node->text_direction);

    buffer_float32[position++] = static_cast<float>(node->rect.left);
    buffer_float32[position++] = static_cast<float>(node->rect.top);
    buffer_float32[position++] = static_cast<float>(node->rect.right);
    buffer_float32[position++] = static_cast<float>(node->rect.bottom);

    EncodeTransformation(node->transform, &buffer_float32[position]);
    position += kMatrixElementCount;

    FlutterTransformation hit_transform =
        SAFE_ACCESS(node, hit_test_transform, node->transform);
    if (IsZeroTransform(hit_transform)) {
      hit_transform = node->transform;
    }
    EncodeTransformation(hit_transform, &buffer_float32[position]);
    position += kMatrixElementCount;

    if (node->children_in_traversal_order != nullptr && node->child_count > 0) {
      buffer_int32[position++] = static_cast<int32_t>(node->child_count);
      for (size_t c = 0; c < node->child_count; ++c) {
        buffer_int32[position++] = node->children_in_traversal_order[c];
      }
    } else {
      buffer_int32[position++] = 0;
    }

    size_t hit_test_count =
        SAFE_ACCESS(node, hit_test_child_count, node->child_count);
    if (node->children_in_hit_test_order != nullptr && hit_test_count > 0) {
      buffer_int32[position++] = static_cast<int32_t>(hit_test_count);
      for (size_t c = 0; c < hit_test_count; ++c) {
        buffer_int32[position++] = node->children_in_hit_test_order[c];
      }
    } else {
      buffer_int32[position++] = 0;
    }

    if (node->custom_accessibility_actions != nullptr &&
        node->custom_accessibility_actions_count > 0) {
      buffer_int32[position++] =
          static_cast<int32_t>(node->custom_accessibility_actions_count);
      for (size_t c = 0; c < node->custom_accessibility_actions_count; ++c) {
        buffer_int32[position++] = node->custom_accessibility_actions[c];
      }
    } else {
      buffer_int32[position++] = 0;
    }
  }

  return result;
}

MappedCustomActions AndroidSemanticsMapper::MapCustomActions(
    const FlutterSemanticsUpdate2* update) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::MapCustomActions");
  MappedCustomActions result;
  if (update == nullptr) {
    return result;
  }
  if (update->struct_size == 0 ||
      update->struct_size > sizeof(FlutterSemanticsUpdate2)) {
    return result;
  }

  size_t action_count = SAFE_ACCESS(update, custom_action_count, 0);
  FlutterSemanticsCustomAction2** actions =
      SAFE_ACCESS(update, custom_actions, nullptr);
  if (action_count == 0 || actions == nullptr ||
      action_count > kMaxSemanticsActions) {
    return result;
  }

  size_t valid_actions = 0;
  for (size_t i = 0; i < action_count; ++i) {
    const FlutterSemanticsCustomAction2* action = actions[i];
    if (action != nullptr) {
      if (action->struct_size == 0 ||
          action->struct_size > sizeof(FlutterSemanticsCustomAction2)) {
        return {};
      }
      valid_actions++;
    }
  }

  size_t num_bytes = valid_actions * kBytesPerAction;
  result.buffer.resize(num_bytes);
  if (result.buffer.empty()) {
    return result;
  }

  int32_t* actions_buffer_int32 =
      reinterpret_cast<int32_t*>(result.buffer.data());
  size_t position = 0;

  for (size_t i = 0; i < action_count; ++i) {
    const FlutterSemanticsCustomAction2* action = actions[i];
    if (action == nullptr) {
      continue;
    }
    actions_buffer_int32[position++] = SAFE_ACCESS(action, id, 0);
    actions_buffer_int32[position++] =
        STRUCT_HAS_MEMBER(action, override_action)
            ? static_cast<int32_t>(action->override_action)
            : kEmptyStringIndex;
    PutStringIntoBuffer(SAFE_ACCESS(action, label, nullptr),
                        actions_buffer_int32, &position, result.strings);
    PutStringIntoBuffer(SAFE_ACCESS(action, hint, nullptr),
                        actions_buffer_int32, &position, result.strings);
  }

  return result;
}

MappedSemanticsUpdate AndroidSemanticsMapper::MapUpdate(
    const FlutterSemanticsUpdate2* update) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::MapUpdate");
  MappedSemanticsUpdate mapped;
  mapped.nodes = MapNodes(update);
  mapped.actions = MapCustomActions(update);
  return mapped;
}

FlutterSendSemanticsActionInfo
AndroidSemanticsMapper::BuildSendSemanticsActionInfo(
    int64_t view_id,
    uint64_t node_id,
    FlutterSemanticsAction action,
    const uint8_t* data,
    size_t data_length) {
  FlutterSendSemanticsActionInfo info = {};
  info.struct_size = sizeof(FlutterSendSemanticsActionInfo);
  info.view_id = view_id;
  info.node_id = node_id;
  info.action = action;
  info.data = (data_length > 0) ? data : nullptr;
  info.data_length = (data != nullptr) ? data_length : 0;
  return info;
}

FlutterEngineResult AndroidSemanticsMapper::DispatchSemanticsAction(
    const FlutterEngineProcTable& proc_table,
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    int64_t view_id,
    uint64_t node_id,
    FlutterSemanticsAction action,
    const uint8_t* data,
    size_t data_length) {
  TRACE_EVENT0("flutter", "AndroidSemanticsMapper::DispatchSemanticsAction");
  if (engine == nullptr) {
    return kInvalidArguments;
  }
  if (data_length > 0 && data == nullptr) {
    return kInvalidArguments;
  }
  FlutterSendSemanticsActionInfo info =
      BuildSendSemanticsActionInfo(view_id, node_id, action, data, data_length);
  if (proc_table.SendSemanticsAction != nullptr) {
    return proc_table.SendSemanticsAction(engine, &info);
  }
  if (proc_table.DispatchSemanticsAction != nullptr) {
    return proc_table.DispatchSemanticsAction(engine, node_id, action,
                                              info.data, info.data_length);
  }
  return kInternalInconsistency;
}

FlutterEngineResult AndroidSemanticsMapper::DispatchSemanticsAction(
    const FlutterEngineProcTable& proc_table,
    FLUTTER_API_SYMBOL(FlutterEngine) engine,
    uint64_t node_id,
    FlutterSemanticsAction action,
    const uint8_t* data,
    size_t data_length) {
  return DispatchSemanticsAction(proc_table, engine, kDefaultImplicitViewId,
                                 node_id, action, data, data_length);
}

}  // namespace flutter::android
