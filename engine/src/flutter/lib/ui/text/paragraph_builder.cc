// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/text/paragraph_builder.h"

#include <cstring>

#include "flutter/common/settings.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/platform_configuration.h"
#include "flutter/txt/src/txt/font_style.h"
#include "flutter/txt/src/txt/font_weight.h"
#include "flutter/txt/src/txt/paragraph_style.h"
#include "flutter/txt/src/txt/text_baseline.h"
#include "flutter/txt/src/txt/text_decoration.h"
#include "flutter/txt/src/txt/text_style.h"
#include "third_party/icu/source/common/unicode/ustring.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace flutter {
namespace {

const double kTextHeightNone = 0.0;

void DecodePaint(Dart_Handle list, std::optional<DlPaint>& out_paint) {
  Dart_Handle handles[2];
  Dart_ListGetRange(list, 0, 2, handles);
  Paint paint(handles[0], handles[1]);
  if (paint.isNotNull()) {
    paint.paint(out_paint.emplace(), DisplayListOpFlags::kDrawParagraphFlags,
                DlTileMode::kDecal);
  }
}

struct DartListElements {
  explicit DartListElements(Dart_Handle list) {
    Dart_ListLength(list, &length);
    if (length > 0) {
      if (length > kInlineCapacity) {
        heap_storage.resize(length);
        data = heap_storage.data();
      }
      Dart_ListGetRange(list, 0, length, data);
    }
  }

  static constexpr intptr_t kInlineCapacity = 16;
  intptr_t length = 0;
  Dart_Handle inline_storage[kInlineCapacity];
  std::vector<Dart_Handle> heap_storage;
  Dart_Handle* data = inline_storage;

  Dart_Handle operator[](intptr_t index) const { return data[index]; }
};

void DecodeTextShadows(Dart_Handle shadows_handle,
                       std::vector<txt::TextShadow>& decoded_shadows) {
  decoded_shadows.clear();
  DartListElements handles(shadows_handle);
  if (handles.length <= 0) {
    return;
  }
  decoded_shadows.reserve(handles.length / 4);
  for (intptr_t i = 0; i < handles.length; i += 4) {
    decoded_shadows.emplace_back(
        static_cast<SkColor>(
            tonic::DartConverter<uint32_t>::FromDart(handles[i])),
        SkPoint::Make(static_cast<float>(tonic::DartConverter<double>::FromDart(
                          handles[i + 1])),
                      static_cast<float>(tonic::DartConverter<double>::FromDart(
                          handles[i + 2]))),
        tonic::DartConverter<double>::FromDart(handles[i + 3]));
  }
}

void DecodeFontFeatures(Dart_Handle font_features_handle,
                        txt::FontFeatures& font_features) {
  DartListElements handles(font_features_handle);
  for (intptr_t i = 0; i < handles.length; i += 2) {
    font_features.SetFeature(
        tonic::DartConverter<std::string>::FromDart(handles[i]),
        tonic::DartConverter<int32_t>::FromDart(handles[i + 1]));
  }
}

void DecodeFontVariations(Dart_Handle font_variations_handle,
                          txt::FontVariations& font_variations) {
  DartListElements handles(font_variations_handle);
  for (intptr_t i = 0; i < handles.length; i += 2) {
    font_variations.SetAxisValue(
        tonic::DartConverter<std::string>::FromDart(handles[i]),
        static_cast<float>(
            tonic::DartConverter<double>::FromDart(handles[i + 1])));
  }
}

void DecodeFontFamilyFallback(Dart_Handle fallback_handle,
                              std::vector<std::string>& font_families) {
  DartListElements handles(fallback_handle);
  if (handles.length <= 0) {
    return;
  }
  font_families.reserve(font_families.size() + handles.length);
  for (intptr_t i = 0; i < handles.length; ++i) {
    font_families.push_back(
        tonic::DartConverter<std::string>::FromDart(handles[i]));
  }
}

void DecodeStrut(Dart_Handle strut_handle,
                 bool default_half_leading,
                 txt::ParagraphStyle& paragraph_style) {
  StrutStyle in = tonic::DartConverter<StrutStyle>::FromDart(strut_handle);
  // Primitive fields on `flutter::StrutStyle` are pre-populated with their
  // default values from `StrutStyle._` in `lib/ui/text.dart` when omitted by
  // the caller, so `in.has_<field>()` checks are not needed to read them
  // (except `leading_distribution`, which falls back to `ParagraphStyle`'s
  // `default_half_leading` when omitted).
  const bool has_height_override = in.height != kTextHeightNone;
  if (!in.has_font_family() && !in.has_font_family_fallback() &&
      !in.has_font_size() && !has_height_override &&
      !in.has_leading_distribution() && !in.has_leading() &&
      !in.has_font_weight() && !in.has_font_style() &&
      !in.has_force_strut_height()) {
    return;
  }
  paragraph_style.strut_enabled = true;
  paragraph_style.strut_font_weight = in.font_weight;
  paragraph_style.strut_font_style = static_cast<txt::FontStyle>(in.font_style);
  paragraph_style.strut_half_leading = in.has_leading_distribution()
                                           ? (in.leading_distribution == 1)
                                           : default_half_leading;
  paragraph_style.strut_font_size = in.font_size;
  if (has_height_override) {
    paragraph_style.strut_height = in.height;
    paragraph_style.strut_has_height_override = true;
  }
  paragraph_style.strut_leading = in.leading;
  paragraph_style.force_strut_height = in.force_strut_height;

  if (in.has_font_family()) {
    paragraph_style.strut_font_families.push_back(
        tonic::DartConverter<std::string>::FromDart(in.font_family));
  }
  if (in.has_font_family_fallback()) {
    DecodeFontFamilyFallback(in.font_family_fallback,
                             paragraph_style.strut_font_families);
  }
  if (paragraph_style.strut_font_families.empty()) {
    // Provide an empty font name so that the platform default font will be
    // used.
    paragraph_style.strut_font_families.push_back("");
  }
}

template <bool kUseDefaults>
void ApplyTextStyle(const TextStyle& in, txt::TextStyle& style) {
  if (kUseDefaults || in.has_color()) {
    style.color = in.color;
  }
  if (kUseDefaults || in.has_decoration()) {
    style.decoration = static_cast<txt::TextDecoration>(in.decoration);
  }
  if (kUseDefaults || in.has_decoration_color()) {
    style.decoration_color = in.decoration_color;
  }
  if (kUseDefaults || in.has_decoration_style()) {
    style.decoration_style =
        static_cast<txt::TextDecorationStyle>(in.decoration_style);
  }
  if (kUseDefaults || in.has_decoration_thickness()) {
    style.decoration_thickness_multiplier = in.decoration_thickness;
  }
  if (kUseDefaults || in.has_text_baseline()) {
    // TODO(abarth): Implement TextBaseline. The CSS version of this
    // property wasn't wired up either.
    style.text_baseline = static_cast<txt::TextBaseline>(in.text_baseline);
  }
  if (kUseDefaults || in.has_font_weight()) {
    style.font_weight = in.font_weight;
  }
  if (kUseDefaults || in.has_font_style()) {
    style.font_style = static_cast<txt::FontStyle>(in.font_style);
  }
  if (kUseDefaults || in.has_font_size()) {
    style.font_size = in.font_size;
  }
  if (kUseDefaults || in.has_letter_spacing()) {
    style.letter_spacing = in.letter_spacing;
  }
  if (kUseDefaults || in.has_word_spacing()) {
    style.word_spacing = in.word_spacing;
  }
  if (kUseDefaults || in.has_height()) {
    style.height = in.height;
    style.has_height_override = style.height != kTextHeightNone;
  }
  if (kUseDefaults || in.has_leading_distribution()) {
    style.half_leading = in.leading_distribution == 1;
  }
  if (in.has_locale()) {
    style.locale = tonic::DartConverter<std::string>::FromDart(in.locale);
  }
  if (in.has_background()) {
    DecodePaint(in.background, style.background);
  }
  if (in.has_foreground()) {
    DecodePaint(in.foreground, style.foreground);
  }
  if (in.has_shadows()) {
    DecodeTextShadows(in.shadows, style.text_shadows);
  }
  if (in.has_font_family() || in.has_font_family_fallback()) {
    // The child style's font families override the parent's font families.
    // If the child's fonts are not available, then the font collection will
    // use the system fallback fonts (not the parent's fonts).
    style.font_families.clear();
    style.font_families.push_back(
        in.has_font_family()
            ? tonic::DartConverter<std::string>::FromDart(in.font_family)
            : "");
    if (in.has_font_family_fallback()) {
      DecodeFontFamilyFallback(in.font_family_fallback, style.font_families);
    }
  }
  if (in.has_font_features()) {
    DecodeFontFeatures(in.font_features, style.font_features);
  }
  if (in.has_font_variations()) {
    DecodeFontVariations(in.font_variations, style.font_variations);
  }
}

}  // namespace

IMPLEMENT_WRAPPERTYPEINFO(ui, ParagraphBuilder);

void ParagraphBuilder::Create(Dart_Handle wrapper,
                              const ParagraphStyle& in,
                              const TextStyle& default_text_style) {
  UIDartState::ThrowIfUIOperationsProhibited();
  auto res = fml::MakeRefCounted<ParagraphBuilder>(in, default_text_style);
  res->AssociateWithDartWrapper(wrapper);
}

ParagraphBuilder::ParagraphBuilder(const ParagraphStyle& in,
                                   const TextStyle& default_text_style) {
  // Primitive fields on `flutter::ParagraphStyle` and `flutter::TextStyle` are
  // pre-populated with their default values from `ParagraphStyle._` and
  // `TextStyle._` in `lib/ui/text.dart` when omitted by the caller, so they can
  // be assigned directly without `has_<field>()` checks.
  txt::ParagraphStyle style;
  style.text_align = static_cast<txt::TextAlign>(in.text_align);
  style.text_direction = static_cast<txt::TextDirection>(in.text_direction);
  style.text_height_behavior = in.text_height_behavior & 0x3;

  // Still check `in.has_max_lines()` because an omitted `maxLines`
  // means unlimited lines (`std::numeric_limits<size_t>::max()`).
  if (in.has_max_lines()) {
    style.max_lines = in.max_lines;
  }
  if (in.has_ellipsis()) {
    style.ellipsis =
        tonic::DartConverter<std::u16string>::FromDart(in.ellipsis);
  }
  // Hyphens.manual (0) renders the soft hyphen glyph; Hyphens.hidden (1)
  // suppresses it.
  style.render_soft_hyphens = in.hyphens == 0;

  // Seed `style.default_text_style` with all fields (including defaults) from
  // `default_text_style`, then mirror the paragraph-level font properties onto
  // `style` for SkParagraph and `ParagraphStyle::GetTextStyle()`.
  ApplyTextStyle</*kUseDefaults=*/true>(default_text_style,
                                        style.default_text_style);
  style.font_weight = style.default_text_style.font_weight;
  style.font_style = style.default_text_style.font_style;
  if (default_text_style.has_font_family()) {
    style.font_family = style.default_text_style.font_families[0];
  }
  style.font_size = style.default_text_style.font_size;
  style.height = style.default_text_style.height;
  style.has_height_override = style.default_text_style.has_height_override;
  style.locale = style.default_text_style.locale;

  if (in.has_strut_style()) {
    DecodeStrut(in.strut_style, style.default_text_style.half_leading, style);
  }

  FontCollection& font_collection = UIDartState::Current()
                                        ->platform_configuration()
                                        ->client()
                                        ->GetFontCollection();

  auto impeller_enabled = UIDartState::Current()->IsImpellerEnabled();
  m_paragraph_builder_ = txt::ParagraphBuilder::CreateSkiaBuilder(
      style, font_collection.GetFontCollection(), impeller_enabled);
}

ParagraphBuilder::~ParagraphBuilder() = default;

void ParagraphBuilder::pushStyle(const TextStyle& in) {
  // `PeekStyle()` returns `base_style_` (seeded from `default_text_style` in
  // the constructor) when the style stack is empty, or the parent
  // `txt::TextStyle` when styles are nested. Only fields explicitly provided on
  // `in` (`in.has_<field>()`) overwrite the inherited style.
  txt::TextStyle style = m_paragraph_builder_->PeekStyle();
  ApplyTextStyle</*kUseDefaults=*/false>(in, style);
  m_paragraph_builder_->PushStyle(style);
}

void ParagraphBuilder::pop() {
  m_paragraph_builder_->Pop();
}

Dart_Handle ParagraphBuilder::addText(const std::u16string& text) {
  if (text.empty()) {
    return Dart_Null();
  }

  // Use ICU to validate the UTF-16 input.  Calling u_strToUTF8 with a null
  // output buffer will return U_BUFFER_OVERFLOW_ERROR if the input is well
  // formed.
  const UChar* text_ptr = reinterpret_cast<const UChar*>(text.data());
  UErrorCode error_code = U_ZERO_ERROR;
  u_strToUTF8(nullptr, 0, nullptr, text_ptr, text.size(), &error_code);
  if (error_code != U_BUFFER_OVERFLOW_ERROR) {
    return tonic::ToDart("string is not well-formed UTF-16");
  }

  m_paragraph_builder_->AddText(text);

  return Dart_Null();
}

void ParagraphBuilder::addPlaceholder(double width,
                                      double height,
                                      unsigned alignment,
                                      double baseline_offset,
                                      unsigned baseline) {
  txt::PlaceholderRun placeholder_run(
      width, height, static_cast<txt::PlaceholderAlignment>(alignment),
      static_cast<txt::TextBaseline>(baseline), baseline_offset);

  m_paragraph_builder_->AddPlaceholder(placeholder_run);
}

void ParagraphBuilder::build(Dart_Handle paragraph_handle) {
  Paragraph::Create(paragraph_handle, m_paragraph_builder_->Build());
  m_paragraph_builder_.reset();
  ClearDartWrapper();
}

}  // namespace flutter
