// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// GENERATED CODE - DO NOT EDIT BY HAND.

#ifndef FLUTTER_LIB_UI_TEXT_TEXT_STYLES_G_H_
#define FLUTTER_LIB_UI_TEXT_TEXT_STYLES_G_H_

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <type_traits>

#include "third_party/tonic/converter/dart_converter.h"

namespace flutter {

class TextStyle {
 public:
  double decoration_thickness;
  double font_size;
  double letter_spacing;
  double word_spacing;
  double height;
  uint32_t color;
  int32_t decoration;
  uint32_t decoration_color;
  int32_t font_weight;
  uint32_t present_mask;
  uint8_t decoration_style;
  uint8_t font_style;
  uint8_t text_baseline;
  uint8_t leading_distribution;
  Dart_Handle font_family;
  Dart_Handle font_family_fallback;
  Dart_Handle locale;
  Dart_Handle background;
  Dart_Handle foreground;
  Dart_Handle shadows;
  Dart_Handle font_features;
  Dart_Handle font_variations;

  bool has_color() const { return (present_mask & (1u << 0)) != 0; }
  bool has_decoration() const { return (present_mask & (1u << 1)) != 0; }
  bool has_decoration_color() const { return (present_mask & (1u << 2)) != 0; }
  bool has_decoration_style() const { return (present_mask & (1u << 3)) != 0; }
  bool has_decoration_thickness() const {
    return (present_mask & (1u << 4)) != 0;
  }
  bool has_font_weight() const { return (present_mask & (1u << 5)) != 0; }
  bool has_font_style() const { return (present_mask & (1u << 6)) != 0; }
  bool has_text_baseline() const { return (present_mask & (1u << 7)) != 0; }
  bool has_font_size() const { return (present_mask & (1u << 8)) != 0; }
  bool has_letter_spacing() const { return (present_mask & (1u << 9)) != 0; }
  bool has_word_spacing() const { return (present_mask & (1u << 10)) != 0; }
  bool has_height() const { return (present_mask & (1u << 11)) != 0; }
  bool has_leading_distribution() const {
    return (present_mask & (1u << 12)) != 0;
  }
  bool has_font_family() const { return (present_mask & (1u << 13)) != 0; }
  bool has_font_family_fallback() const {
    return (present_mask & (1u << 14)) != 0;
  }
  bool has_locale() const { return (present_mask & (1u << 15)) != 0; }
  bool has_background() const { return (present_mask & (1u << 16)) != 0; }
  bool has_foreground() const { return (present_mask & (1u << 17)) != 0; }
  bool has_shadows() const { return (present_mask & (1u << 18)) != 0; }
  bool has_font_features() const { return (present_mask & (1u << 19)) != 0; }
  bool has_font_variations() const { return (present_mask & (1u << 20)) != 0; }
};
static_assert(std::is_standard_layout_v<TextStyle>);
static_assert(std::is_trivially_copyable_v<TextStyle>);

class ParagraphStyle {
 public:
  double font_size;
  double height;
  int32_t max_lines;
  int32_t text_height_behavior;
  int32_t font_weight;
  uint16_t present_mask;
  uint8_t text_align;
  uint8_t text_direction;
  uint8_t font_style;
  uint8_t hyphens;
  Dart_Handle font_family;
  Dart_Handle strut_style;
  Dart_Handle ellipsis;
  Dart_Handle locale;

  bool has_text_align() const { return (present_mask & (1u << 0)) != 0; }
  bool has_text_direction() const { return (present_mask & (1u << 1)) != 0; }
  bool has_max_lines() const { return (present_mask & (1u << 2)) != 0; }
  bool has_font_size() const { return (present_mask & (1u << 3)) != 0; }
  bool has_height() const { return (present_mask & (1u << 4)) != 0; }
  bool has_text_height_behavior() const {
    return (present_mask & (1u << 5)) != 0;
  }
  bool has_font_weight() const { return (present_mask & (1u << 6)) != 0; }
  bool has_font_style() const { return (present_mask & (1u << 7)) != 0; }
  bool has_hyphens() const { return (present_mask & (1u << 8)) != 0; }
  bool has_font_family() const { return (present_mask & (1u << 9)) != 0; }
  bool has_strut_style() const { return (present_mask & (1u << 10)) != 0; }
  bool has_ellipsis() const { return (present_mask & (1u << 11)) != 0; }
  bool has_locale() const { return (present_mask & (1u << 12)) != 0; }
};
static_assert(std::is_standard_layout_v<ParagraphStyle>);
static_assert(std::is_trivially_copyable_v<ParagraphStyle>);

class StrutStyle {
 public:
  double font_size;
  double height;
  double leading;
  int32_t font_weight;
  uint16_t present_mask;
  uint8_t leading_distribution;
  uint8_t font_style;
  bool force_strut_height;
  Dart_Handle font_family;
  Dart_Handle font_family_fallback;

  bool has_font_family() const { return (present_mask & (1u << 0)) != 0; }
  bool has_font_family_fallback() const {
    return (present_mask & (1u << 1)) != 0;
  }
  bool has_font_size() const { return (present_mask & (1u << 2)) != 0; }
  bool has_height() const { return (present_mask & (1u << 3)) != 0; }
  bool has_leading_distribution() const {
    return (present_mask & (1u << 4)) != 0;
  }
  bool has_leading() const { return (present_mask & (1u << 5)) != 0; }
  bool has_font_weight() const { return (present_mask & (1u << 6)) != 0; }
  bool has_font_style() const { return (present_mask & (1u << 7)) != 0; }
  bool has_force_strut_height() const {
    return (present_mask & (1u << 8)) != 0;
  }
};
static_assert(std::is_standard_layout_v<StrutStyle>);
static_assert(std::is_trivially_copyable_v<StrutStyle>);

}  // namespace flutter

namespace tonic {

template <>
struct DartConverter<flutter::TextStyle> {
  using FfiType = Dart_Handle;
  static constexpr const char* kFfiRepresentation = "Handle";
  static constexpr const char* kDartRepresentation = "Object";
  static constexpr bool kAllowedInLeafCall = false;

  static flutter::TextStyle FromDart(Dart_Handle handle) {
    if (Dart_IsNull(handle)) {
      return {};
    }
    flutter::TextStyle result;
    Dart_Handle handles[9];
    Dart_ListGetRange(handle, 1, 9, handles);
    Dart_Handle bytes_handle = handles[0];
    Dart_TypedData_Type type;
    void* data = nullptr;
    intptr_t length = 0;
    Dart_TypedDataAcquireData(bytes_handle, &type, &data, &length);
    std::memcpy(&result, data,
                offsetof(flutter::TextStyle, leading_distribution) +
                    sizeof(result.leading_distribution));
    Dart_TypedDataReleaseData(bytes_handle);
    result.font_family = handles[1];
    result.font_family_fallback = handles[2];
    result.locale = handles[3];
    result.background = handles[4];
    result.foreground = handles[5];
    result.shadows = handles[6];
    result.font_features = handles[7];
    result.font_variations = handles[8];
    return result;
  }

  static flutter::TextStyle FromFfi(FfiType val) { return FromDart(val); }
  static const char* GetFfiRepresentation() { return kFfiRepresentation; }
  static const char* GetDartRepresentation() { return kDartRepresentation; }
  static bool AllowedInLeafCall() { return kAllowedInLeafCall; }
};

template <>
struct DartConverter<flutter::ParagraphStyle> {
  using FfiType = Dart_Handle;
  static constexpr const char* kFfiRepresentation = "Handle";
  static constexpr const char* kDartRepresentation = "Object";
  static constexpr bool kAllowedInLeafCall = false;

  static flutter::ParagraphStyle FromDart(Dart_Handle handle) {
    if (Dart_IsNull(handle)) {
      return {};
    }
    flutter::ParagraphStyle result;
    Dart_Handle handles[5];
    Dart_ListGetRange(handle, 1, 5, handles);
    Dart_Handle bytes_handle = handles[0];
    Dart_TypedData_Type type;
    void* data = nullptr;
    intptr_t length = 0;
    Dart_TypedDataAcquireData(bytes_handle, &type, &data, &length);
    std::memcpy(
        &result, data,
        offsetof(flutter::ParagraphStyle, hyphens) + sizeof(result.hyphens));
    Dart_TypedDataReleaseData(bytes_handle);
    result.font_family = handles[1];
    result.strut_style = handles[2];
    result.ellipsis = handles[3];
    result.locale = handles[4];
    return result;
  }

  static flutter::ParagraphStyle FromFfi(FfiType val) { return FromDart(val); }
  static const char* GetFfiRepresentation() { return kFfiRepresentation; }
  static const char* GetDartRepresentation() { return kDartRepresentation; }
  static bool AllowedInLeafCall() { return kAllowedInLeafCall; }
};

template <>
struct DartConverter<flutter::StrutStyle> {
  using FfiType = Dart_Handle;
  static constexpr const char* kFfiRepresentation = "Handle";
  static constexpr const char* kDartRepresentation = "Object";
  static constexpr bool kAllowedInLeafCall = false;

  static flutter::StrutStyle FromDart(Dart_Handle handle) {
    if (Dart_IsNull(handle)) {
      return {};
    }
    flutter::StrutStyle result;
    Dart_Handle handles[3];
    Dart_ListGetRange(handle, 1, 3, handles);
    Dart_Handle bytes_handle = handles[0];
    Dart_TypedData_Type type;
    void* data = nullptr;
    intptr_t length = 0;
    Dart_TypedDataAcquireData(bytes_handle, &type, &data, &length);
    std::memcpy(&result, data,
                offsetof(flutter::StrutStyle, force_strut_height) +
                    sizeof(result.force_strut_height));
    Dart_TypedDataReleaseData(bytes_handle);
    result.font_family = handles[1];
    result.font_family_fallback = handles[2];
    return result;
  }

  static flutter::StrutStyle FromFfi(FfiType val) { return FromDart(val); }
  static const char* GetFfiRepresentation() { return kFfiRepresentation; }
  static const char* GetDartRepresentation() { return kDartRepresentation; }
  static bool AllowedInLeafCall() { return kAllowedInLeafCall; }
};

}  // namespace tonic

#endif  // FLUTTER_LIB_UI_TEXT_TEXT_STYLES_G_H_
