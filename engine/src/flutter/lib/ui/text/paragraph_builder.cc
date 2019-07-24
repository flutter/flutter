// Copyright 2013 The Flutter Authors. All rights reserved.
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
#include "flutter/third_party/txt/src/txt/text_baseline.h"
#include "flutter/third_party/txt/src/txt/text_decoration.h"
#include "flutter/third_party/txt/src/txt/text_style.h"
#include "third_party/icu/source/common/unicode/ustring.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"
#include "third_party/tonic/typed_data/dart_byte_data.h"

namespace flutter {
namespace {

// TextStyle

const int tsColorIndex = 1;
const int tsTextDecorationIndex = 2;
const int tsTextDecorationColorIndex = 3;
const int tsTextDecorationStyleIndex = 4;
const int tsFontWeightIndex = 5;
const int tsFontStyleIndex = 6;
const int tsTextBaselineIndex = 7;
const int tsTextDecorationThicknessIndex = 8;
const int tsFontFamilyIndex = 9;
const int tsFontSizeIndex = 10;
const int tsLetterSpacingIndex = 11;
const int tsWordSpacingIndex = 12;
const int tsHeightIndex = 13;
const int tsLocaleIndex = 14;
const int tsBackgroundIndex = 15;
const int tsForegroundIndex = 16;
const int tsTextShadowsIndex = 17;
const int tsFontFeaturesIndex = 18;

const int tsColorMask = 1 << tsColorIndex;
const int tsTextDecorationMask = 1 << tsTextDecorationIndex;
const int tsTextDecorationColorMask = 1 << tsTextDecorationColorIndex;
const int tsTextDecorationStyleMask = 1 << tsTextDecorationStyleIndex;
const int tsTextDecorationThicknessMask = 1 << tsTextDecorationThicknessIndex;
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
const int tsFontFeaturesMask = 1 << tsFontFeaturesIndex;

// ParagraphStyle

const int psTextAlignIndex = 1;
const int psTextDirectionIndex = 2;
const int psFontWeightIndex = 3;
const int psFontStyleIndex = 4;
const int psMaxLinesIndex = 5;
const int psFontFamilyIndex = 6;
const int psFontSizeIndex = 7;
const int psHeightIndex = 8;
const int psStrutStyleIndex = 9;
const int psEllipsisIndex = 10;
const int psLocaleIndex = 11;

const int psTextAlignMask = 1 << psTextAlignIndex;
const int psTextDirectionMask = 1 << psTextDirectionIndex;
const int psFontWeightMask = 1 << psFontWeightIndex;
const int psFontStyleMask = 1 << psFontStyleIndex;
const int psMaxLinesMask = 1 << psMaxLinesIndex;
const int psFontFamilyMask = 1 << psFontFamilyIndex;
const int psFontSizeMask = 1 << psFontSizeIndex;
const int psHeightMask = 1 << psHeightIndex;
const int psStrutStyleMask = 1 << psStrutStyleIndex;
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

// FontFeature decoding
constexpr uint32_t kBytesPerFontFeature = 8;
constexpr uint32_t kFontFeatureTagLength = 4;

// Strut decoding
const int sFontWeightIndex = 0;
const int sFontStyleIndex = 1;
const int sFontFamilyIndex = 2;
const int sFontSizeIndex = 3;
const int sHeightIndex = 4;
const int sLeadingIndex = 5;
const int sForceStrutHeightIndex = 6;

const int sFontWeightMask = 1 << sFontWeightIndex;
const int sFontStyleMask = 1 << sFontStyleIndex;
const int sFontFamilyMask = 1 << sFontFamilyIndex;
const int sFontSizeMask = 1 << sFontSizeIndex;
const int sHeightMask = 1 << sHeightIndex;
const int sLeadingMask = 1 << sLeadingIndex;
const int sForceStrutHeightMask = 1 << sForceStrutHeightIndex;

}  // namespace

static void ParagraphBuilder_constructor(Dart_NativeArguments args) {
  DartCallConstructor(&ParagraphBuilder::create, args);
}

IMPLEMENT_WRAPPERTYPEINFO(ui, ParagraphBuilder);

#define FOR_EACH_BINDING(V)           \
  V(ParagraphBuilder, pushStyle)      \
  V(ParagraphBuilder, pop)            \
  V(ParagraphBuilder, addText)        \
  V(ParagraphBuilder, addPlaceholder) \
  V(ParagraphBuilder, build)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK)

void ParagraphBuilder::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register(
      {{"ParagraphBuilder_constructor", ParagraphBuilder_constructor, 9, true},
       FOR_EACH_BINDING(DART_REGISTER_NATIVE)});
}

fml::RefPtr<ParagraphBuilder> ParagraphBuilder::create(
    tonic::Int32List& encoded,
    Dart_Handle strutData,
    const std::string& fontFamily,
    const std::vector<std::string>& strutFontFamilies,
    double fontSize,
    double height,
    const std::u16string& ellipsis,
    const std::string& locale) {
  return fml::MakeRefCounted<ParagraphBuilder>(encoded, strutData, fontFamily,
                                               strutFontFamilies, fontSize,
                                               height, ellipsis, locale);
}

// returns true if there is a font family defined. Font family is the only
// parameter passed directly.
void decodeStrut(Dart_Handle strut_data,
                 const std::vector<std::string>& strut_font_families,
                 txt::ParagraphStyle& paragraph_style) {
  if (strut_data == Dart_Null()) {
    return;
  }

  tonic::DartByteData byte_data(strut_data);
  if (byte_data.length_in_bytes() == 0) {
    return;
  }
  paragraph_style.strut_enabled = true;

  const uint8_t* uint8_data = static_cast<const uint8_t*>(byte_data.data());
  uint8_t mask = uint8_data[0];

  // Data is stored in order of increasing size, eg, 8 bit ints will be before
  // any 32 bit ints. In addition, the order of decoding is the same order
  // as it is encoded, and the order is used to maintain consistency.
  size_t byte_count = 1;
  if (mask & sFontWeightMask) {
    paragraph_style.strut_font_weight =
        static_cast<txt::FontWeight>(uint8_data[byte_count++]);
  }
  if (mask & sFontStyleMask) {
    paragraph_style.strut_font_style =
        static_cast<txt::FontStyle>(uint8_data[byte_count++]);
  }

  std::vector<float> float_data;
  float_data.resize((byte_data.length_in_bytes() - byte_count) / 4);
  memcpy(float_data.data(),
         static_cast<const char*>(byte_data.data()) + byte_count,
         byte_data.length_in_bytes() - byte_count);
  size_t float_count = 0;
  if (mask & sFontSizeMask) {
    paragraph_style.strut_font_size = float_data[float_count++];
  }
  if (mask & sHeightMask) {
    paragraph_style.strut_height = float_data[float_count++];
    paragraph_style.strut_has_height_override = true;
  }
  if (mask & sLeadingMask) {
    paragraph_style.strut_leading = float_data[float_count++];
  }
  if (mask & sForceStrutHeightMask) {
    // The boolean is stored as the last bit in the bitmask.
    paragraph_style.force_strut_height = (mask & 1 << 7) != 0;
  }

  if (mask & sFontFamilyMask) {
    paragraph_style.strut_font_families = strut_font_families;
  } else {
    // Provide an empty font name so that the platform default font will be
    // used.
    paragraph_style.strut_font_families.push_back("");
  }
}

ParagraphBuilder::ParagraphBuilder(
    tonic::Int32List& encoded,
    Dart_Handle strutData,
    const std::string& fontFamily,
    const std::vector<std::string>& strutFontFamilies,
    double fontSize,
    double height,
    const std::u16string& ellipsis,
    const std::string& locale) {
  int32_t mask = encoded[0];
  txt::ParagraphStyle style;

  if (mask & psTextAlignMask) {
    style.text_align = txt::TextAlign(encoded[psTextAlignIndex]);
  }

  if (mask & psTextDirectionMask) {
    style.text_direction = txt::TextDirection(encoded[psTextDirectionIndex]);
  }

  if (mask & psFontWeightMask) {
    style.font_weight =
        static_cast<txt::FontWeight>(encoded[psFontWeightIndex]);
  }

  if (mask & psFontStyleMask) {
    style.font_style = static_cast<txt::FontStyle>(encoded[psFontStyleIndex]);
  }

  if (mask & psFontFamilyMask) {
    style.font_family = fontFamily;
  }

  if (mask & psFontSizeMask) {
    style.font_size = fontSize;
  }

  if (mask & psHeightMask) {
    style.height = height;
    style.has_height_override = true;
  }

  if (mask & psStrutStyleMask) {
    decodeStrut(strutData, strutFontFamilies, style);
  }

  if (mask & psMaxLinesMask) {
    style.max_lines = encoded[psMaxLinesIndex];
  }

  if (mask & psEllipsisMask) {
    style.ellipsis = ellipsis;
  }

  if (mask & psLocaleMask) {
    style.locale = locale;
  }

  FontCollection& font_collection =
      UIDartState::Current()->window()->client()->GetFontCollection();

#if FLUTTER_ENABLE_SKSHAPER
#define FLUTTER_PARAGRAPH_BUILDER txt::ParagraphBuilder::CreateSkiaBuilder
#else
#define FLUTTER_PARAGRAPH_BUILDER txt::ParagraphBuilder::CreateTxtBuilder
#endif

  m_paragraphBuilder =
      FLUTTER_PARAGRAPH_BUILDER(style, font_collection.GetFontCollection());
}

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

void decodeFontFeatures(Dart_Handle font_features_data,
                        txt::FontFeatures& font_features) {
  tonic::DartByteData byte_data(font_features_data);
  FML_CHECK(byte_data.length_in_bytes() % kBytesPerFontFeature == 0);

  size_t feature_count = byte_data.length_in_bytes() / kBytesPerFontFeature;
  for (size_t feature_index = 0; feature_index < feature_count;
       ++feature_index) {
    size_t feature_offset = feature_index * kBytesPerFontFeature;
    const char* feature_bytes =
        static_cast<const char*>(byte_data.data()) + feature_offset;
    std::string tag(feature_bytes, kFontFeatureTagLength);
    int32_t value = *(reinterpret_cast<const int32_t*>(feature_bytes +
                                                       kFontFeatureTagLength));
    font_features.SetFeature(tag, value);
  }
}

void ParagraphBuilder::pushStyle(tonic::Int32List& encoded,
                                 const std::vector<std::string>& fontFamilies,
                                 double fontSize,
                                 double letterSpacing,
                                 double wordSpacing,
                                 double height,
                                 double decorationThickness,
                                 const std::string& locale,
                                 Dart_Handle background_objects,
                                 Dart_Handle background_data,
                                 Dart_Handle foreground_objects,
                                 Dart_Handle foreground_data,
                                 Dart_Handle shadows_data,
                                 Dart_Handle font_features_data) {
  FML_DCHECK(encoded.num_elements() == 8);

  int32_t mask = encoded[0];

  // Set to use the properties of the previous style if the property is not
  // explicitly given.
  txt::TextStyle style = m_paragraphBuilder->PeekStyle();

  // Only change the style property from the previous value if a new explicitly
  // set value is available
  if (mask & tsColorMask) {
    style.color = encoded[tsColorIndex];
  }

  if (mask & tsTextDecorationMask) {
    style.decoration =
        static_cast<txt::TextDecoration>(encoded[tsTextDecorationIndex]);
  }

  if (mask & tsTextDecorationColorMask) {
    style.decoration_color = encoded[tsTextDecorationColorIndex];
  }

  if (mask & tsTextDecorationStyleMask) {
    style.decoration_style = static_cast<txt::TextDecorationStyle>(
        encoded[tsTextDecorationStyleIndex]);
  }

  if (mask & tsTextDecorationThicknessMask) {
    style.decoration_thickness_multiplier = decorationThickness;
  }

  if (mask & tsTextBaselineMask) {
    // TODO(abarth): Implement TextBaseline. The CSS version of this
    // property wasn't wired up either.
  }

  if (mask & (tsFontWeightMask | tsFontStyleMask | tsFontSizeMask |
              tsLetterSpacingMask | tsWordSpacingMask)) {
    if (mask & tsFontWeightMask)
      style.font_weight =
          static_cast<txt::FontWeight>(encoded[tsFontWeightIndex]);

    if (mask & tsFontStyleMask)
      style.font_style = static_cast<txt::FontStyle>(encoded[tsFontStyleIndex]);

    if (mask & tsFontSizeMask)
      style.font_size = fontSize;

    if (mask & tsLetterSpacingMask)
      style.letter_spacing = letterSpacing;

    if (mask & tsWordSpacingMask)
      style.word_spacing = wordSpacing;
  }

  if (mask & tsHeightMask) {
    style.height = height;
    style.has_height_override = true;
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

  if (mask & tsFontFamilyMask) {
    // The child style's font families override the parent's font families.
    // If the child's fonts are not available, then the font collection will
    // use the system fallback fonts (not the parent's fonts).
    style.font_families = fontFamilies;
  }

  if (mask & tsFontFeaturesMask) {
    decodeFontFeatures(font_features_data, style.font_features);
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

Dart_Handle ParagraphBuilder::addPlaceholder(double width,
                                             double height,
                                             unsigned alignment,
                                             double baseline_offset,
                                             unsigned baseline) {
  txt::PlaceholderRun placeholder_run(
      width, height, static_cast<txt::PlaceholderAlignment>(alignment),
      static_cast<txt::TextBaseline>(baseline), baseline_offset);

  m_paragraphBuilder->AddPlaceholder(placeholder_run);

  return Dart_Null();
}

fml::RefPtr<Paragraph> ParagraphBuilder::build() {
  return Paragraph::Create(m_paragraphBuilder->Build());
}

}  // namespace flutter
