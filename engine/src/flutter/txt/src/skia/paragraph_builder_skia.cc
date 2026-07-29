// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "paragraph_builder_skia.h"
#include "paragraph_skia.h"

#include <unicode/ustring.h>

#include "third_party/skia/modules/skparagraph/include/ParagraphStyle.h"
#include "third_party/skia/modules/skparagraph/include/TextStyle.h"
#include "third_party/skia/modules/skunicode/include/SkUnicode_icu.h"
#include "txt/paragraph_style.h"
#include "txt/text_direction_util.h"

namespace skt = skia::textlayout;

namespace txt {

namespace {

constexpr std::string_view kWeightAxisTag = "wght";

template <typename T>
SkFourByteTag GetFourByteTag(const T& tag) {
  return SkSetFourByteTag(tag[0], tag[1], tag[2], tag[3]);
}

SkFontStyle MakeSkFontStyle(int font_weight, txt::FontStyle font_style) {
  return SkFontStyle(font_weight, SkFontStyle::Width::kNormal_Width,
                     font_style == txt::FontStyle::normal
                         ? SkFontStyle::Slant::kUpright_Slant
                         : SkFontStyle::Slant::kItalic_Slant);
}

}  // anonymous namespace

ParagraphBuilderSkia::ParagraphBuilderSkia(
    const ParagraphStyle& style,
    const std::shared_ptr<FontCollection>& font_collection,
    const bool impeller_enabled)
    : base_style_(style.GetTextStyle()),
      original_style_(style),
      font_collection_(font_collection),
      direction_is_auto_(!style.text_direction.has_value()),
      impeller_enabled_(impeller_enabled) {
  if (direction_is_auto_) {
    original_style_.text_direction =
        style.default_text_direction.value_or(TextDirection::ltr);
  }
  builder_ = skt::ParagraphBuilder::make(
      TxtToSkia(original_style_), font_collection->CreateSktFontCollection(),
      SkUnicodes::ICU::Make());
}

ParagraphBuilderSkia::~ParagraphBuilderSkia() = default;

void ParagraphBuilderSkia::PushStyle(const TextStyle& style) {
  if (direction_is_auto_) {
    RecordedOp op;
    op.kind = RecordedOp::Kind::kPushStyle;
    op.style = style;
    recorded_ops_.push_back(std::move(op));
  }
  builder_->pushStyle(TxtToSkia(style));
  txt_style_stack_.push(style);
}

void ParagraphBuilderSkia::Pop() {
  if (direction_is_auto_) {
    RecordedOp op;
    op.kind = RecordedOp::Kind::kPop;
    recorded_ops_.push_back(std::move(op));
  }
  builder_->pop();
  txt_style_stack_.pop();
}

const TextStyle& ParagraphBuilderSkia::PeekStyle() {
  return txt_style_stack_.empty() ? base_style_ : txt_style_stack_.top();
}

void ParagraphBuilderSkia::AddText(const std::u16string& text) {
  if (direction_is_auto_) {
    RecordedOp op;
    op.kind = RecordedOp::Kind::kUtf16;
    op.utf16_text = text;
    recorded_ops_.push_back(std::move(op));
    accumulated_text_.append(text);
  }
  builder_->addText(text);
}

void ParagraphBuilderSkia::AddText(const uint8_t* utf8_data,
                                   size_t byte_length) {
  if (direction_is_auto_) {
    RecordedOp op;
    op.kind = RecordedOp::Kind::kUtf8;
    op.utf8_text.assign(reinterpret_cast<const char*>(utf8_data), byte_length);
    recorded_ops_.push_back(std::move(op));
    UErrorCode status = U_ZERO_ERROR;
    int32_t destCapacity = 0;
    // 先计算所需长度
    u_strFromUTF8(nullptr, 0, &destCapacity,
                  reinterpret_cast<const char*>(utf8_data), byte_length, &status);
    if (destCapacity > 0) {
      status = U_ZERO_ERROR;
      auto dest = std::make_unique<UChar[]>(destCapacity + 1);
      u_strFromUTF8(dest.get(), destCapacity + 1, nullptr,
                    reinterpret_cast<const char*>(utf8_data), byte_length, &status);
      if (U_SUCCESS(status)) {
        accumulated_text_.append(reinterpret_cast<const char16_t*>(dest.get()), destCapacity);
      }
    }
  }
  builder_->addText(reinterpret_cast<const char*>(utf8_data), byte_length);
}

void ParagraphBuilderSkia::AddPlaceholder(PlaceholderRun& span) {
  if (direction_is_auto_) {
    RecordedOp op;
    op.kind = RecordedOp::Kind::kPlaceholder;
    op.placeholder = span;
    recorded_ops_.push_back(std::move(op));
  }

  skt::PlaceholderStyle placeholder_style;
  placeholder_style.fHeight = span.height;
  placeholder_style.fWidth = span.width;
  placeholder_style.fBaseline = static_cast<skt::TextBaseline>(span.baseline);
  placeholder_style.fBaselineOffset = span.baseline_offset;
  placeholder_style.fAlignment =
      static_cast<skt::PlaceholderAlignment>(span.alignment);

  builder_->addPlaceholder(placeholder_style);
}

TextDirection ParagraphBuilderSkia::ResolveEffectiveDirection() const {
  if (!direction_is_auto_) {
    return original_style_.text_direction.value();
  }
  std::optional<TextDirection> resolved =
      ResolveTextDirectionByContent(accumulated_text_);
  if (resolved.has_value()) {
    return resolved.value();
  }
  return original_style_.default_text_direction.value_or(TextDirection::ltr);
}

void ParagraphBuilderSkia::ReplayOperations(
    skia::textlayout::ParagraphBuilder& target) {
  for (const auto& op : recorded_ops_) {
    switch (op.kind) {
      case RecordedOp::Kind::kPushStyle:
        target.pushStyle(TxtToSkia(op.style));
        break;
      case RecordedOp::Kind::kPop:
        target.pop();
        break;
      case RecordedOp::Kind::kUtf16:
        target.addText(op.utf16_text);
        break;
      case RecordedOp::Kind::kUtf8:
        target.addText(op.utf8_text.data(), op.utf8_text.size());
        break;
      case RecordedOp::Kind::kPlaceholder: {
        const auto& span = op.placeholder.value();
        skt::PlaceholderStyle placeholder_style;
        placeholder_style.fHeight = span.height;
        placeholder_style.fWidth = span.width;
        placeholder_style.fBaseline =
            static_cast<skt::TextBaseline>(span.baseline);
        placeholder_style.fBaselineOffset = span.baseline_offset;
        placeholder_style.fAlignment =
            static_cast<skt::PlaceholderAlignment>(span.alignment);
        target.addPlaceholder(placeholder_style);
        break;
      }
    }
  }
}

std::unique_ptr<Paragraph> ParagraphBuilderSkia::Build() {
  if (!direction_is_auto_) {
    return std::make_unique<ParagraphSkia>(
        builder_->Build(), std::move(dl_paints_), impeller_enabled_,
        original_style_.text_direction.value());
  }

  TextDirection resolved_direction = ResolveEffectiveDirection();

  if (resolved_direction == original_style_.text_direction.value()) {
    return std::make_unique<ParagraphSkia>(
        builder_->Build(), std::move(dl_paints_), impeller_enabled_,
        resolved_direction);
  }

  original_style_.text_direction = resolved_direction;

  dl_paints_.clear();

  builder_ = skt::ParagraphBuilder::make(
      TxtToSkia(original_style_), font_collection_->CreateSktFontCollection(),
      SkUnicodes::ICU::Make());

  ReplayOperations(*builder_);

  return std::make_unique<ParagraphSkia>(builder_->Build(),
                                         std::move(dl_paints_),
                                         impeller_enabled_, resolved_direction);
}

skt::ParagraphPainter::PaintID ParagraphBuilderSkia::CreatePaintID(
    const flutter::DlPaint& dl_paint) {
  dl_paints_.push_back(dl_paint);
  return dl_paints_.size() - 1;
}

skt::ParagraphStyle ParagraphBuilderSkia::TxtToSkia(const ParagraphStyle& txt) {
  skt::ParagraphStyle skia;
  skt::TextStyle text_style;

  // Convert the default color of an SkParagraph text style into a DlPaint.
  flutter::DlPaint dl_paint;
  dl_paint.setColor(flutter::DlColor(text_style.getColor()));
  text_style.setForegroundPaintID(CreatePaintID(dl_paint));

  text_style.setFontStyle(MakeSkFontStyle(txt.font_weight, txt.font_style));
  text_style.setFontSize(SkDoubleToScalar(txt.font_size));
  text_style.setHeight(SkDoubleToScalar(txt.height));
  text_style.setHeightOverride(txt.has_height_override);
  text_style.setFontFamilies({SkString(txt.font_family.c_str())});
  text_style.setLocale(SkString(txt.locale.c_str()));
  SkFontArguments::VariationPosition::Coordinate weight_coord{
      GetFourByteTag(kWeightAxisTag), static_cast<float>(txt.font_weight)};
  text_style.setFontArguments(
      SkFontArguments().setVariationDesignPosition({&weight_coord, 1}));
  skia.setTextStyle(text_style);

  skt::StrutStyle strut_style;
  strut_style.setFontStyle(
      MakeSkFontStyle(txt.strut_font_weight, txt.strut_font_style));
  strut_style.setFontSize(SkDoubleToScalar(txt.strut_font_size));
  strut_style.setHeight(SkDoubleToScalar(txt.strut_height));
  strut_style.setHeightOverride(txt.strut_has_height_override);
  strut_style.setHalfLeading(txt.strut_half_leading);

  std::vector<SkString> strut_fonts;
  std::transform(txt.strut_font_families.begin(), txt.strut_font_families.end(),
                 std::back_inserter(strut_fonts),
                 [](const std::string& f) { return SkString(f.c_str()); });
  strut_style.setFontFamilies(strut_fonts);
  strut_style.setLeading(txt.strut_leading);
  strut_style.setForceStrutHeight(txt.force_strut_height);
  strut_style.setStrutEnabled(txt.strut_enabled);
  skia.setStrutStyle(strut_style);

  skia.setTextAlign(static_cast<skt::TextAlign>(txt.text_align));
  skia.setTextDirection(
      static_cast<skt::TextDirection>(txt.text_direction.value_or(
          txt.default_text_direction.value_or(TextDirection::ltr))));
  skia.setMaxLines(txt.max_lines);
  skia.setEllipsis(txt.ellipsis);
  skia.setTextHeightBehavior(
      static_cast<skt::TextHeightBehavior>(txt.text_height_behavior));

  skia.turnHintingOff();
  skia.setReplaceTabCharacters(true);
  skia.setApplyRoundingHack(false);

  return skia;
}

skt::TextStyle ParagraphBuilderSkia::TxtToSkia(const TextStyle& txt) {
  skt::TextStyle skia;

  skia.setColor(txt.color);
  skia.setDecoration(static_cast<skt::TextDecoration>(txt.decoration));
  skia.setDecorationColor(txt.decoration_color);
  skia.setDecorationStyle(
      static_cast<skt::TextDecorationStyle>(txt.decoration_style));
  skia.setDecorationThicknessMultiplier(
      SkDoubleToScalar(txt.decoration_thickness_multiplier));
  skia.setFontStyle(MakeSkFontStyle(txt.font_weight, txt.font_style));
  skia.setTextBaseline(static_cast<skt::TextBaseline>(txt.text_baseline));

  std::vector<SkString> skia_fonts;
  std::transform(txt.font_families.begin(), txt.font_families.end(),
                 std::back_inserter(skia_fonts),
                 [](const std::string& f) { return SkString(f.c_str()); });
  skia.setFontFamilies(skia_fonts);

  skia.setFontSize(SkDoubleToScalar(txt.font_size));
  skia.setLetterSpacing(SkDoubleToScalar(txt.letter_spacing));
  skia.setWordSpacing(SkDoubleToScalar(txt.word_spacing));
  skia.setHeight(SkDoubleToScalar(txt.height));
  skia.setHeightOverride(txt.has_height_override);
  skia.setHalfLeading(txt.half_leading);

  skia.setLocale(SkString(txt.locale.c_str()));
  if (txt.background.has_value()) {
    skia.setBackgroundPaintID(CreatePaintID(txt.background.value()));
  }
  if (txt.foreground.has_value()) {
    skia.setForegroundPaintID(CreatePaintID(txt.foreground.value()));
  } else {
    flutter::DlPaint dl_paint;
    dl_paint.setColor(flutter::DlColor(txt.color));
    skia.setForegroundPaintID(CreatePaintID(dl_paint));
  }

  skia.resetFontFeatures();
  for (const auto& ff : txt.font_features.GetFontFeatures()) {
    skia.addFontFeature(SkString(ff.first.c_str()), ff.second);
  }

  std::vector<SkFontArguments::VariationPosition::Coordinate> coordinates;
  bool weight_axis_set = false;
  if (!txt.font_variations.GetAxisValues().empty()) {
    for (const auto& it : txt.font_variations.GetAxisValues()) {
      const std::string& axis = it.first;
      if (axis.length() != 4) {
        continue;
      }
      if (axis == kWeightAxisTag) {
        weight_axis_set = true;
      }
      coordinates.push_back({GetFourByteTag(axis), it.second});
    }
  }
  if (!weight_axis_set) {
    coordinates.push_back({
        GetFourByteTag(kWeightAxisTag),
        static_cast<float>(txt.font_weight),
    });
  }
  SkFontArguments::VariationPosition position = {
      coordinates.data(), static_cast<int>(coordinates.size())};
  skia.setFontArguments(SkFontArguments().setVariationDesignPosition(position));

  skia.resetShadows();
  for (const txt::TextShadow& txt_shadow : txt.text_shadows) {
    skt::TextShadow shadow;
    shadow.fOffset = txt_shadow.offset;
    shadow.fBlurSigma = txt_shadow.blur_sigma;
    shadow.fColor = txt_shadow.color;
    skia.addShadow(shadow);
  }

  return skia;
}

}  // namespace txt
