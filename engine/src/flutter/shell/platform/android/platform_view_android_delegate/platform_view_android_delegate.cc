// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android_delegate/platform_view_android_delegate.h"

#include <cstring>
#include <utility>

namespace flutter {
namespace {
void putStringIntoBuffer(const std::string& string,
                         int32_t* buffer,
                         size_t* position,
                         std::vector<std::string>& strings) {
  if (string.empty()) {
    buffer[(*position)++] = PlatformViewAndroidDelegate::kEmptyStringIndex;
  } else {
    buffer[(*position)++] = strings.size();
    strings.push_back(string);
  }
}

// The StringAttributeType values that AccessibilityBridge.java decodes. They
// equal flutter::StringAttributeType.
constexpr int32_t kStringAttributeTypeSpellOut = 0;
constexpr int32_t kStringAttributeTypeLocale = 1;

void putStringAttributesIntoBuffer(
    const FlutterStringAttribute* const* attributes,
    size_t attribute_count,
    int32_t* buffer,
    size_t* position,
    std::vector<std::vector<uint8_t>>& string_attribute_args) {
  if (attribute_count == 0) {
    buffer[(*position)++] = PlatformViewAndroidDelegate::kEmptyStringIndex;
    return;
  }
  buffer[(*position)++] = attribute_count;
  for (size_t i = 0; i < attribute_count; ++i) {
    const FlutterStringAttribute* attribute = attributes[i];
    buffer[(*position)++] = attribute->start;
    buffer[(*position)++] = attribute->end;
    switch (attribute->type) {
      case FlutterStringAttributeType::kSpellOut:
        buffer[(*position)++] = kStringAttributeTypeSpellOut;
        buffer[(*position)++] = PlatformViewAndroidDelegate::kEmptyStringIndex;
        break;
      case FlutterStringAttributeType::kLocale: {
        buffer[(*position)++] = kStringAttributeTypeLocale;
        buffer[(*position)++] = string_attribute_args.size();
        const char* locale =
            (attribute->locale != nullptr && attribute->locale->locale)
                ? attribute->locale->locale
                : "";
        string_attribute_args.emplace_back(locale,
                                           locale + std::strlen(locale));
        break;
      }
    }
  }
}

void putStringIntoBuffer(const char* string,
                         int32_t* buffer,
                         size_t* position,
                         std::vector<std::string>& strings) {
  putStringIntoBuffer(std::string(string ? string : ""), buffer, position,
                      strings);
}

// The bits of AccessibilityBridge.java's Flag values.
int64_t flagsToInt64(const FlutterSemanticsFlags* flags) {
  if (flags == nullptr) {
    return 0;
  }
  int64_t result = 0;
  if (flags->is_checked != kFlutterCheckStateNone) {
    result |= (INT64_C(1) << 0);
  }
  if (flags->is_checked == kFlutterCheckStateTrue) {
    result |= (INT64_C(1) << 1);
  }
  if (flags->is_selected == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 2);
  }
  if (flags->is_button) {
    result |= (INT64_C(1) << 3);
  }
  if (flags->is_text_field) {
    result |= (INT64_C(1) << 4);
  }
  if (flags->is_focused == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 5);
  }
  if (flags->is_enabled != kFlutterTristateNone) {
    result |= (INT64_C(1) << 6);
  }
  if (flags->is_enabled == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 7);
  }
  if (flags->is_in_mutually_exclusive_group) {
    result |= (INT64_C(1) << 8);
  }
  if (flags->is_header) {
    result |= (INT64_C(1) << 9);
  }
  if (flags->is_obscured) {
    result |= (INT64_C(1) << 10);
  }
  if (flags->scopes_route) {
    result |= (INT64_C(1) << 11);
  }
  if (flags->names_route) {
    result |= (INT64_C(1) << 12);
  }
  if (flags->is_hidden) {
    result |= (INT64_C(1) << 13);
  }
  if (flags->is_image) {
    result |= (INT64_C(1) << 14);
  }
  if (flags->is_live_region) {
    result |= (INT64_C(1) << 15);
  }
  if (flags->is_toggled != kFlutterTristateNone) {
    result |= (INT64_C(1) << 16);
  }
  if (flags->is_toggled == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 17);
  }
  if (flags->has_implicit_scrolling) {
    result |= (INT64_C(1) << 18);
  }
  if (flags->is_multiline) {
    result |= (INT64_C(1) << 19);
  }
  if (flags->is_read_only) {
    result |= (INT64_C(1) << 20);
  }
  if (flags->is_focused != kFlutterTristateNone) {
    result |= (INT64_C(1) << 21);
  }
  if (flags->is_link) {
    result |= (INT64_C(1) << 22);
  }
  if (flags->is_slider) {
    result |= (INT64_C(1) << 23);
  }
  if (flags->is_keyboard_key) {
    result |= (INT64_C(1) << 24);
  }
  if (flags->is_checked == kFlutterCheckStateMixed) {
    result |= (INT64_C(1) << 25);
  }
  if (flags->is_expanded != kFlutterTristateNone) {
    result |= (INT64_C(1) << 26);
  }
  if (flags->is_expanded == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 27);
  }
  if (flags->is_selected != kFlutterTristateNone) {
    result |= (INT64_C(1) << 28);
  }
  if (flags->is_required != kFlutterTristateNone) {
    result |= (INT64_C(1) << 29);
  }
  if (flags->is_required == kFlutterTristateTrue) {
    result |= (INT64_C(1) << 30);
  }
  if (flags->is_accessibility_focus_blocked) {
    result |= (INT64_C(1) << 31);
  }
  return result;
}

// The number of elements of a 4x4 matrix.
constexpr size_t kMatrix4ElementCount = 16;

void putMatrixIntoBuffer(const FlutterTransformation4x4& matrix,
                         float* buffer,
                         size_t* position) {
  for (size_t i = 0; i < kMatrix4ElementCount; ++i) {
    buffer[(*position)++] = static_cast<float>(matrix.m[i]);
  }
}
}  // namespace

PlatformViewAndroidDelegate::PlatformViewAndroidDelegate(
    std::shared_ptr<PlatformViewAndroidJNI> jni_facade)
    : jni_facade_(std::move(jni_facade)) {};

void PlatformViewAndroidDelegate::UpdateSemantics(
    const FlutterSemanticsUpdate2& update) {
  size_t num_bytes = 0;
  for (size_t i = 0; i < update.node_count; ++i) {
    const FlutterSemanticsNode2& node = *update.nodes[i];
    num_bytes += kBytesPerNode;
    num_bytes += node.child_count * kBytesPerChild;
    num_bytes += node.hit_test_child_count * kBytesPerChild;
    num_bytes +=
        node.custom_accessibility_actions_count * kBytesPerCustomAction;
    num_bytes += node.label_attribute_count * kBytesPerStringAttribute;
    num_bytes += node.value_attribute_count * kBytesPerStringAttribute;
    num_bytes +=
        node.increased_value_attribute_count * kBytesPerStringAttribute;
    num_bytes +=
        node.decreased_value_attribute_count * kBytesPerStringAttribute;
    num_bytes += node.hint_attribute_count * kBytesPerStringAttribute;
  }
  // The encoding defined here is used in:
  //
  //  * AccessibilityBridge.java
  //  * AccessibilityBridgeTest.java
  //  * accessibility_bridge.mm
  //
  // If any of the encoding structure or length is changed, those locations
  // must be updated (at a minimum).
  std::vector<uint8_t> buffer(num_bytes);
  std::vector<std::string> strings;
  std::vector<std::vector<uint8_t>> string_attribute_args;

  if (!buffer.empty()) {
    int32_t* buffer_int32 = reinterpret_cast<int32_t*>(buffer.data());
    float* buffer_float32 = reinterpret_cast<float*>(buffer.data());

    size_t position = 0;
    for (size_t i = 0; i < update.node_count; ++i) {
      // If you edit this code, make sure you update kBytesPerNode
      // and/or kBytesPerChild above to match the number of values you are
      // sending.
      const FlutterSemanticsNode2& node = *update.nodes[i];
      buffer_int32[position++] = node.id;
      int64_t flags = flagsToInt64(node.flags2);
      std::memcpy(&buffer_int32[position], &flags, sizeof(flags));
      position += sizeof(flags) / sizeof(int32_t);
      buffer_int32[position++] = static_cast<int32_t>(node.actions);
      buffer_int32[position++] = node.max_value_length;
      buffer_int32[position++] = node.current_value_length;
      buffer_int32[position++] = node.text_selection_base;
      buffer_int32[position++] = node.text_selection_extent;
      buffer_int32[position++] = static_cast<int32_t>(node.platform_view_id);
      buffer_int32[position++] = node.scroll_child_count;
      buffer_int32[position++] = node.scroll_index;
      buffer_int32[position++] = node.traversal_parent;
      buffer_float32[position++] = static_cast<float>(node.scroll_position);
      buffer_float32[position++] = static_cast<float>(node.scroll_extent_max);
      buffer_float32[position++] = static_cast<float>(node.scroll_extent_min);
      buffer_int32[position++] = static_cast<int32_t>(node.role);

      putStringIntoBuffer(node.identifier, buffer_int32, &position, strings);

      putStringIntoBuffer(node.label, buffer_int32, &position, strings);
      putStringAttributesIntoBuffer(node.label_attributes,
                                    node.label_attribute_count, buffer_int32,
                                    &position, string_attribute_args);

      putStringIntoBuffer(node.value, buffer_int32, &position, strings);
      putStringAttributesIntoBuffer(node.value_attributes,
                                    node.value_attribute_count, buffer_int32,
                                    &position, string_attribute_args);

      putStringIntoBuffer(node.increased_value, buffer_int32, &position,
                          strings);
      putStringAttributesIntoBuffer(
          node.increased_value_attributes, node.increased_value_attribute_count,
          buffer_int32, &position, string_attribute_args);

      putStringIntoBuffer(node.decreased_value, buffer_int32, &position,
                          strings);
      putStringAttributesIntoBuffer(
          node.decreased_value_attributes, node.decreased_value_attribute_count,
          buffer_int32, &position, string_attribute_args);

      putStringIntoBuffer(node.hint, buffer_int32, &position, strings);
      putStringAttributesIntoBuffer(node.hint_attributes,
                                    node.hint_attribute_count, buffer_int32,
                                    &position, string_attribute_args);

      putStringIntoBuffer(node.tooltip, buffer_int32, &position, strings);
      putStringIntoBuffer(node.link_url, buffer_int32, &position, strings);
      putStringIntoBuffer(node.locale, buffer_int32, &position, strings);
      putStringIntoBuffer(node.min_value, buffer_int32, &position, strings);
      putStringIntoBuffer(node.max_value, buffer_int32, &position, strings);

      buffer_int32[position++] = node.heading_level;
      buffer_int32[position++] = static_cast<int32_t>(node.text_direction);
      buffer_float32[position++] = static_cast<float>(node.rect.left);
      buffer_float32[position++] = static_cast<float>(node.rect.top);
      buffer_float32[position++] = static_cast<float>(node.rect.right);
      buffer_float32[position++] = static_cast<float>(node.rect.bottom);
      putMatrixIntoBuffer(node.transform_4x4, buffer_float32, &position);
      putMatrixIntoBuffer(node.hit_test_transform, buffer_float32, &position);
      buffer_int32[position++] = node.child_count;
      for (size_t child = 0; child < node.child_count; ++child) {
        buffer_int32[position++] = node.children_in_traversal_order[child];
      }

      buffer_int32[position++] = node.hit_test_child_count;
      for (size_t child = 0; child < node.hit_test_child_count; ++child) {
        buffer_int32[position++] = node.children_in_hit_test_order[child];
      }

      buffer_int32[position++] = node.custom_accessibility_actions_count;
      for (size_t action = 0; action < node.custom_accessibility_actions_count;
           ++action) {
        buffer_int32[position++] = node.custom_accessibility_actions[action];
      }
    }
  }

  // custom accessibility actions.
  size_t num_action_bytes = update.custom_action_count * kBytesPerAction;
  std::vector<uint8_t> actions_buffer(num_action_bytes);

  if (!actions_buffer.empty()) {
    int32_t* actions_buffer_int32 =
        reinterpret_cast<int32_t*>(actions_buffer.data());

    std::vector<std::string> action_strings;
    size_t actions_position = 0;
    for (size_t i = 0; i < update.custom_action_count; ++i) {
      // If you edit this code, make sure you update kBytesPerAction
      // to match the number of values you are
      // sending.
      const FlutterSemanticsCustomAction2& action = *update.custom_actions[i];
      actions_buffer_int32[actions_position++] = action.id;
      actions_buffer_int32[actions_position++] =
          static_cast<int32_t>(action.override_action);
      putStringIntoBuffer(action.label, actions_buffer_int32, &actions_position,
                          action_strings);
      putStringIntoBuffer(action.hint, actions_buffer_int32, &actions_position,
                          action_strings);
    }
    // Calling NewDirectByteBuffer in API level 22 and below with a size of
    // zero will cause a JNI crash.
    jni_facade_->FlutterViewUpdateCustomAccessibilityActions(actions_buffer,
                                                             action_strings);
  }

  if (!buffer.empty()) {
    jni_facade_->FlutterViewUpdateSemantics(buffer, strings,
                                            string_attribute_args);
  }
}

}  // namespace flutter
