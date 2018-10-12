// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph_builder.h"

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/third_party/txt/src/txt/font_style.h"
#include "flutter/third_party/txt/src/txt/font_weight.h"
#include "flutter/third_party/txt/src/txt/paragraph_style.h"
#include "flutter/third_party/txt/src/txt/text_decoration.h"
#include "flutter/third_party/txt/src/txt/text_style.h"
#include "third_party/icu/source/common/unicode/ustring.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace blink {
namespace {

// TextStyle

const int tsColorIndex = 1;
const int tsTextDecorationIndex = 2;
const int tsTextDecorationColorIndex = 3;
const int tsTextDecorationStyleIndex = 4;
const int tsFontWeightIndex = 5;
const int tsFontStyleIndex = 6;
const int tsTextBaselineIndex = 7;
const int tsFontFamilyIndex = 8;
const int tsFontSizeIndex = 9;
const int tsLetterSpacingIndex = 10;
const int tsWordSpacingIndex = 11;
const int tsHeightIndex = 12;
const int tsLocaleIndex = 13;
const int tsBackgroundIndex = 14;
const int tsForegroundIndex = 15;
const int tsTextShadowsIndex = 16;

const int tsColorMask = 1 << tsColorIndex;
const int tsTextDecorationMask = 1 << tsTextDecorationIndex;
const int tsTextDecorationColorMask = 1 << tsTextDecorationColorIndex;
const int tsTextDecorationStyleMask = 1 << tsTextDecorationStyleIndex;
const int tsFontWeightMask = 1 << tsFontWeightIndex;
const int tsFontStyleMask = 1 << tsFontStyleIndex;
const int tsTextBaselineMask = 1 << tsTextBaselineIndex;
const int tsFontFamilyMask = 1 << tsFontFamilyIndex;
const int tsFontSizeMask = 1 << tsFontSizeIndex;
const int tsLetterSpacingMask = 1 << tsLetterSpacingIndex;
const int tsWordSpacingMask = 1 << tsWordSpacingIndex;
const int tsHeightMask = 1 << tsHeightIndex;
const int tsLocaleMask = 1 << tsLocaleIndex;
const int tsBackgroundMask = 1 << tsBackgroundIndex;
const int tsForegroundMask = 1 << tsForegroundIndex;
const int tsTextShadowsMask = 1 << tsTextShadowsIndex;

// ParagraphStyle

const int psTextAlignIndex = 1;
const int psTextDirectionIndex = 2;
const int psFontWeightIndex = 3;
const int psFontStyleIndex = 4;
const int psMaxLinesIndex = 5;
const int psFontFamilyIndex = 6;
const int psFontSizeIndex = 7;
const int psLineHeightIndex = 8;
const int psEllipsisIndex = 9;
const int psLocaleIndex = 10;

const int psTextAlignMask = 1 << psTextAlignIndex;
const int psTextDirectionMask = 1 << psTextDirectionIndex;
const int psFontWeightMask = 1 << psFontWeightIndex;
const int psFontStyleMask = 1 << psFontStyleIndex;
const int psMaxLinesMask = 1 << psMaxLinesIndex;
const int psFontFamilyMask = 1 << psFontFamilyIndex;
const int psFontSizeMask = 1 << psFontSizeIndex;
const int psLineHeightMask = 1 << psLineHeightIndex;
const int psEllipsisMask = 1 << psEllipsisIndex;
const int psLocaleMask = 1 << psLocaleIndex;

// TextShadows decoding

constexpr uint32_t kColorDefault = 0xFF000000;
constexpr uint32_t kBytesPerShadow = 16;
constexpr uint32_t kShadowPropertiesCount = 4;
constexpr uint32_t kColorOffset = 0;
constexpr uint32_t kXOffset = 1;
constexpr uint32_t kYOffset = 2;
constexpr uint32_t kBlurOffset = 3;

}  // namespace

static void ParagraphBuilder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&ParagraphBuilder::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, ParagraphBuilder);

#define FOR_EACH_BINDING(V)      \
  V(ParagraphBuilder, pushStyle) \
  V(ParagraphBuilder, pop)       \
  V(ParagraphBuilder, addText)   \
  V(ParagraphBuilder, build)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void ParagraphBuilder::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"ParagraphBuilder_constructor", ParagraphBuilder_constructor, 7, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<ParagraphBuilder> ParagraphBuilder::create(
    tonic::Int32List& encoded,
    const std::string& fontFamily,
    double fontSize,
    double lineHeight,
    const std::u16string& ellipsis,
    const std::string& locale) {
  return fml::MakeRefCounted<ParagraphBuilder>(encoded, fontFamily, fontSize,
                                               lineHeight, ellipsis, locale);
}

ParagraphBuilder::ParagraphBuilder(tonic::Int32List& encoded,
                                   const std::string& fontFamily,
                                   double fontSize,
                                   double lineHeight,
                                   const std::u16string& ellipsis,
                                   const std::string& locale) {
  int32_t mask = encoded[0];
  txt::ParagraphStyle style;
  if (mask & psTextAlignMask)
    style.text_align = txt::TextAlign(encoded[psTextAlignIndex]);

  if (mask & psTextDirectionMask)
    style.text_direction = txt::TextDirection(encoded[psTextDirectionIndex]);

  if (mask & psFontWeightMask)
    style.font_weight =
        static_cast<txt::FontWeight>(encoded[psFontWeightIndex]);

  if (mask & psFontStyleMask)
    style.font_style = static_cast<txt::FontStyle>(encoded[psFontStyleIndex]);

  if (mask & psFontFamilyMask)
    style.font_family = fontFamily;

  if (mask & psFontSizeMask)
    style.font_size = fontSize;

  if (mask & psLineHeightMask)
    style.line_height = lineHeight;

  if (mask & psMaxLinesMask)
    style.max_lines = encoded[psMaxLinesIndex];

  if (mask & psEllipsisMask)
    style.ellipsis = ellipsis;

  if (mask & psLocaleMask)
    style.locale = locale;

  FontCollection& font_collection =
      UIDartState::Current()->window()->client()->GetFontCollection();
  m_paragraphBuilder = std::make_unique<txt::ParagraphBuilder>(
      style, font_collection.GetFontCollection());
}  // namespace blink

ParagraphBuilder::~ParagraphBuilder() = default;

void decodeTextShadows(Dart_Handle shadows_data,
                       std::vector<txt::TextShadow>& decoded_shadows) {
  decoded_shadows.clear();

  tonic::DartByteData byte_data(shadows_data);
  FML_CHECK(byte_data.length_in_bytes() % kBytesPerShadow == 0);

  const uint32_t* uint_data = static_cast<const uint32_t*>(byte_data.data());
  const float* float_data = static_cast<const float*>(byte_data.data());

  size_t shadow_count = byte_data.length_in_bytes() / kBytesPerShadow;
  size_t shadow_count_offset = 0;
  for (size_t shadow_index = 0; shadow_index < shadow_count; ++shadow_index) {
    shadow_count_offset = shadow_index * kShadowPropertiesCount;
    SkColor color =
        uint_data[shadow_count_offset + kColorOffset] ^ kColorDefault;
    decoded_shadows.emplace_back(
        color,
        SkPoint::Make(float_data[shadow_count_offset + kXOffset],
                      float_data[shadow_count_offset + kYOffset]),
        float_data[shadow_count_offset + kBlurOffset]);
  }
}

void ParagraphBuilder::pushStyle(tonic::Int32List& encoded,
                                 const std::string& fontFamily,
                                 double fontSize,
                                 double letterSpacing,
                                 double wordSpacing,
                                 double height,
                                 const std::string& locale,
                                 Dart_Handle background_objects,
                                 Dart_Handle background_data,
                                 Dart_Handle foreground_objects,
                                 Dart_Handle foreground_data,
                                 Dart_Handle shadows_data) {
  FML_DCHECK(encoded.num_elements() == 8);

  int32_t mask = encoded[0];

  // Set to use the properties of the previous style if the property is not
  // explicitly given.
  txt::TextStyle style = m_paragraphBuilder->PeekStyle();

  // Only change the style property from the previous value if a new explicitly
  // set value is available
  if (mask & tsColorMask)
    style.color = encoded[tsColorIndex];

  if (mask & tsTextDecorationMask) {
    style.decoration =
        static_cast<txt::TextDecoration>(encoded[tsTextDecorationIndex]);
  }

  if (mask & tsTextDecorationColorMask)
    style.decoration_color = encoded[tsTextDecorationColorIndex];

  if (mask & tsTextDecorationStyleMask)
    style.decoration_style = static_cast<txt::TextDecorationStyle>(
        encoded[tsTextDecorationStyleIndex]);

  if (mask & tsTextBaselineMask) {
    // TODO(abarth): Implement TextBaseline. The CSS version of this
    // property wasn't wired up either.
  }

  if (mask & (tsFontWeightMask | tsFontStyleMask | tsFontFamilyMask |
              tsFontSizeMask | tsLetterSpacingMask | tsWordSpacingMask)) {
    if (mask & tsFontWeightMask)
      style.font_weight =
          static_cast<txt::FontWeight>(encoded[tsFontWeightIndex]);

    if (mask & tsFontStyleMask)
      style.font_style = static_cast<txt::FontStyle>(encoded[tsFontStyleIndex]);

    if (mask & tsFontFamilyMask)
      style.font_family = fontFamily;

    if (mask & tsFontSizeMask)
      style.font_size = fontSize;

    if (mask & tsLetterSpacingMask)
      style.letter_spacing = letterSpacing;

    if (mask & tsWordSpacingMask)
      style.word_spacing = wordSpacing;
  }

  if (mask & tsHeightMask) {
    style.height = height;
  }

  if (mask & tsLocaleMask) {
    style.locale = locale;
  }

  if (mask & tsBackgroundMask) {
    Paint background(background_objects, background_data);
    if (background.paint()) {
      style.has_background = true;
      style.background = *background.paint();
    }
  }

  if (mask & tsForegroundMask) {
    Paint foreground(foreground_objects, foreground_data);
    if (foreground.paint()) {
      style.has_foreground = true;
      style.foreground = *foreground.paint();
    }
  }

  if (mask & tsTextShadowsMask) {
    decodeTextShadows(shadows_data, style.text_shadows);
  }

  m_paragraphBuilder->PushStyle(style);
}

void ParagraphBuilder::pop() {
  m_paragraphBuilder->Pop();
}

Dart_Handle ParagraphBuilder::addText(const std::u16string& text) {
  if (text.empty())
    return Dart_Null();

  // Use ICU to validate the UTF-16 input.  Calling u_strToUTF8 with a null
  // output buffer will return U_BUFFER_OVERFLOW_ERROR if the input is well
  // formed.
  const UChar* text_ptr = reinterpret_cast<const UChar*>(text.data());
  UErrorCode error_code = U_ZERO_ERROR;
  u_strToUTF8(nullptr, 0, nullptr, text_ptr, text.size(), &error_code);
  if (error_code != U_BUFFER_OVERFLOW_ERROR)
    return tonic::ToDart("string is not well-formed UTF-16");

  m_paragraphBuilder->AddText(text);

  return Dart_Null();
}

fml::RefPtr<Paragraph> ParagraphBuilder::build() {
  return Paragraph::Create(m_paragraphBuilder->Build());
}

}  // namespace blink
