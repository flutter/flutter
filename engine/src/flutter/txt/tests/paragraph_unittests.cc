// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cmath>
#include <limits>
#include <memory>
#include "display_list/dl_color.h"
#include "display_list/dl_paint.h"
#include "display_list/dl_tile_mode.h"
#include "display_list/effects/color_sources/dl_linear_gradient_color_source.h"
#include "display_list/effects/dl_color_source.h"
#include "display_list/utils/dl_receiver_utils.h"
#include "gtest/gtest.h"
#include "include/core/SkScalar.h"
#include "runtime/test_font_data.h"
#include "skia/paragraph_builder_skia.h"
#include "testing/canvas_test.h"
#include "testing/testing.h"
#include "txt/platform.h"

namespace flutter {
namespace testing {

[[maybe_unused]]
static const std::string kEmojiFontFile =
#if FML_OS_MACOSX
    "Apple Color Emoji.ttc";
#else
    "NotoColorEmoji.ttf";
#endif

[[maybe_unused]]
static const std::string kEmojiFontName =
#if FML_OS_MACOSX
    "Apple Color Emoji";
#else
    "Noto Color Emoji";
#endif

//------------------------------------------------------------------------------
/// @brief      A custom |DlOpReceiver| that records some |DlOps| it receives.
class DlOpRecorder final : public virtual DlOpReceiver,
                           private IgnoreAttributeDispatchHelper,
                           private IgnoreClipDispatchHelper,
                           private IgnoreDrawDispatchHelper,
                           private IgnoreTransformDispatchHelper {
 public:
  int lineCount() const { return lines_.size(); }
  int dashedLineCount() const { return dashed_lines_.size(); }
  int rectCount() const { return rects_.size(); }
  int pathCount() const { return paths_.size(); }
  int textFrameCount() const { return text_frames_.size(); }
  int blobCount() const { return blobs_.size(); }
  int clipRectCount() const { return clip_rects_.size(); }
  int saveLayerCount() const { return save_layer_count_; }
  const std::vector<DlRect>& rects() const { return rects_; }
  const std::vector<std::shared_ptr<DlColorSource>>& colorSources() const {
    return color_sources_;
  }

 private:
  void setColorSource(const DlColorSource* source) override {
    if (source) {
      color_sources_.push_back(source->shared());
    }
  }

  void clipRect(const DlRect& clip, DlClipOp clip_op, bool is_aa) override {
    clip_rects_.push_back(clip);
  }

  void saveLayer(const DlRect& bounds,
                 const SaveLayerOptions options,
                 const DlImageFilter* backdrop,
                 std::optional<int64_t> backdrop_id) override {
    save_layer_count_++;
  }
  void drawLine(const DlPoint& p0, const DlPoint& p1) override {
    lines_.emplace_back(p0, p1);
  }

  void drawDashedLine(const DlPoint& p0,
                      const DlPoint& p1,
                      DlScalar on_length,
                      DlScalar off_length) override {
    dashed_lines_.emplace_back(p0, p1, DlPoint(on_length, off_length));
  }

  void drawText(const std::shared_ptr<DlText>& text,
                SkScalar x,
                SkScalar y) override {
    auto blob = text->GetTextBlob();
    if (blob) {
      blobs_.push_back(sk_ref_sp(blob));
    } else {
      auto frame = text->GetTextFrame();
      FML_CHECK(frame);
      text_frames_.push_back(frame);
    }
  }

  void drawRect(const DlRect& rect) override { rects_.push_back(rect); }

  void drawPath(const DlPath& path) override { paths_.push_back(path); }

  std::vector<std::shared_ptr<impeller::TextFrame>> text_frames_;
  std::vector<sk_sp<SkTextBlob>> blobs_;
  std::vector<std::pair<DlPoint, DlPoint>> lines_;
  std::vector<std::tuple<DlPoint, DlPoint, DlPoint>> dashed_lines_;
  std::vector<DlRect> rects_;
  std::vector<DlPath> paths_;
  std::vector<DlRect> clip_rects_;
  std::vector<std::shared_ptr<DlColorSource>> color_sources_;
  int save_layer_count_ = 0;
};

template <typename T>
class PainterTestBase : public CanvasTestBase<T> {
 public:
  PainterTestBase() = default;

  void PretendImpellerIsEnabled(bool impeller) { impeller_ = impeller; }

 protected:
  txt::TextStyle makeDecoratedStyle(txt::TextDecorationStyle style) {
    auto t_style = txt::TextStyle();
    t_style.color = SK_ColorBLACK;  // default
    t_style.font_weight = txt::FontWeight::normal;
    t_style.font_size = 14;  // default
    t_style.decoration = txt::TextDecoration::kUnderline;
    t_style.decoration_style = style;
    t_style.decoration_color = SK_ColorBLACK;
    t_style.font_families.push_back("ahem");
    return t_style;
  }

  txt::TextStyle makeEmoji() {
    auto t_style = txt::TextStyle();
    t_style.color = SK_ColorBLACK;  // default
    t_style.font_weight = txt::FontWeight::normal;
    t_style.font_size = 14;  // default
    t_style.font_families.push_back(kEmojiFontName);
    return t_style;
  }

  txt::TextStyle makeStyle() {
    auto t_style = txt::TextStyle();
    t_style.color = SK_ColorBLACK;  // default
    t_style.font_weight = txt::FontWeight::normal;
    t_style.font_size = 14;  // default
    t_style.font_families.push_back("ahem");
    return t_style;
  }

  sk_sp<DisplayList> drawText(const txt::TextStyle& style,
                              const std::u16string& text) const {
    auto pb_skia = makeParagraphBuilder();
    pb_skia.PushStyle(style);
    pb_skia.AddText(text);
    pb_skia.Pop();

    auto builder = DisplayListBuilder();
    auto paragraph = pb_skia.Build();
    paragraph->Layout(10000);
    paragraph->Paint(&builder, 0, 0);

    return builder.Build();
  }

  sk_sp<DisplayList> draw(const txt::TextStyle& style) const {
    auto pb_skia = makeParagraphBuilder();
    pb_skia.PushStyle(style);
    pb_skia.AddText(u"Hello World!");
    pb_skia.Pop();

    auto builder = DisplayListBuilder();
    auto paragraph = pb_skia.Build();
    paragraph->Layout(10000);
    paragraph->Paint(&builder, 0, 0);

    return builder.Build();
  }

  std::unique_ptr<txt::Paragraph> buildParagraph(
      const txt::TextStyle& style,
      const std::u16string& text,
      size_t max_lines = std::numeric_limits<size_t>::max(),
      txt::TextDirection text_direction = txt::TextDirection::ltr) const {
    auto p_style = txt::ParagraphStyle();
    p_style.max_lines = max_lines;
    p_style.text_direction = text_direction;
    auto f_collection = makeFontCollection();
    auto pb_skia = txt::ParagraphBuilderSkia(p_style, f_collection, impeller_);
    pb_skia.PushStyle(style);
    pb_skia.AddText(text);
    pb_skia.Pop();
    return pb_skia.Build();
  }

 private:
  std::shared_ptr<txt::FontCollection> makeFontCollection() const {
    auto f_collection = std::make_shared<txt::FontCollection>();
    auto font_provider = std::make_unique<txt::TypefaceFontAssetProvider>();
    for (auto& font : GetTestFontData()) {
      font_provider->RegisterTypeface(font);
    }
    // Load emoji font.
    {
      auto c_font_fixture = std::string(kEmojiFontFile);
      auto mapping =
          flutter::testing::OpenFixtureAsSkData(c_font_fixture.c_str());
      auto typeface = txt::GetDefaultFontManager()->makeFromData(mapping);
      font_provider->RegisterTypeface(typeface);
    }

    auto manager = sk_make_sp<txt::AssetFontManager>(std::move(font_provider));
    f_collection->SetAssetFontManager(manager);
    return f_collection;
  }

  txt::ParagraphBuilderSkia makeParagraphBuilder() const {
    auto p_style = txt::ParagraphStyle();
    auto f_collection = makeFontCollection();
    return txt::ParagraphBuilderSkia(p_style, f_collection, impeller_);
  }

  bool impeller_ = false;
};

using PainterTest = PainterTestBase<::testing::Test>;

TEST_F(PainterTest, DrawsSolidLineSkia) {
  PretendImpellerIsEnabled(false);

  auto recorder = DlOpRecorder();
  draw(makeDecoratedStyle(txt::TextDecorationStyle::kSolid))
      ->Dispatch(recorder);

  // Skia may draw a solid underline as a filled rectangle:
  // https://skia.googlesource.com/skia/+/refs/heads/main/modules/skparagraph/src/Decorations.cpp#91
  EXPECT_EQ(recorder.rectCount(), 1);
}

TEST_F(PainterTest, DrawDashedLineSkia) {
  PretendImpellerIsEnabled(false);

  auto recorder = DlOpRecorder();
  draw(makeDecoratedStyle(txt::TextDecorationStyle::kDashed))
      ->Dispatch(recorder);

  // Skia draws a dashed underline as a filled rectangle with a path effect.
  EXPECT_EQ(recorder.lineCount(), 0);
  EXPECT_EQ(recorder.dashedLineCount(), 1);
}

#ifdef IMPELLER_SUPPORTS_RENDERING
TEST_F(PainterTest, DrawsSolidLineImpeller) {
  PretendImpellerIsEnabled(true);

  auto recorder = DlOpRecorder();
  draw(makeDecoratedStyle(txt::TextDecorationStyle::kSolid))
      ->Dispatch(recorder);

  // Skia may draw a solid underline as a filled rectangle:
  // https://skia.googlesource.com/skia/+/refs/heads/main/modules/skparagraph/src/Decorations.cpp#91
  EXPECT_EQ(recorder.rectCount(), 1);
}

TEST_F(PainterTest, DrawDashedLineImpeller) {
  PretendImpellerIsEnabled(true);

  auto recorder = DlOpRecorder();
  draw(makeDecoratedStyle(txt::TextDecorationStyle::kDashed))
      ->Dispatch(recorder);

  // Impeller draws a dashed underline as a path.
  EXPECT_EQ(recorder.pathCount(), 0);
  EXPECT_EQ(recorder.dashedLineCount(), 1);
}

TEST_F(PainterTest, DrawTextImpeller) {
  PretendImpellerIsEnabled(true);

  auto recorder = DlOpRecorder();
  draw(makeStyle())->Dispatch(recorder);

  EXPECT_EQ(recorder.textFrameCount(), 1);
  EXPECT_EQ(recorder.blobCount(), 0);
}

TEST_F(PainterTest, DrawStrokedTextImpeller) {
  PretendImpellerIsEnabled(true);

  auto style = makeStyle();
  // What is your shtyle?
  DlPaint foreground;
  foreground.setDrawStyle(DlDrawStyle::kStroke);
  style.foreground = foreground;

  auto recorder = DlOpRecorder();
  draw(style)->Dispatch(recorder);

  EXPECT_EQ(recorder.textFrameCount(), 1);
  EXPECT_EQ(recorder.blobCount(), 0);
  EXPECT_EQ(recorder.pathCount(), 0);
}

TEST_F(PainterTest, DrawStrokedTextWithLargeWidthImpeller) {
  PretendImpellerIsEnabled(true);

  auto style = makeStyle();
  DlPaint foreground;
  foreground.setDrawStyle(DlDrawStyle::kStroke);
  foreground.setStrokeWidth(10);
  style.foreground = foreground;

  auto recorder = DlOpRecorder();
  draw(style)->Dispatch(recorder);

  EXPECT_EQ(recorder.textFrameCount(), 0);
  EXPECT_EQ(recorder.blobCount(), 0);
  EXPECT_EQ(recorder.pathCount(), 1);
}

TEST_F(PainterTest, DrawTextWithGradientImpeller) {
  PretendImpellerIsEnabled(true);

  auto style = makeStyle();
  // how do you like my shtyle?
  DlPaint foreground;
  std::vector<DlColor> colors = {DlColor::kRed(), DlColor::kCyan()};
  std::vector<float> stops = {0.0, 1.0};
  foreground.setColorSource(DlColorSource::MakeLinear(
      DlPoint(0, 0), DlPoint(100, 100), 2, colors.data(), stops.data(),
      DlTileMode::kClamp));
  style.foreground = foreground;

  auto recorder = DlOpRecorder();
  draw(style)->Dispatch(recorder);

  EXPECT_EQ(recorder.textFrameCount(), 0);
  EXPECT_EQ(recorder.blobCount(), 0);
  EXPECT_EQ(recorder.pathCount(), 1);
}

TEST_F(PainterTest, DrawEmojiTextWithGradientImpeller) {
  PretendImpellerIsEnabled(true);

  auto style = makeEmoji();
  // how do you like my shtyle?
  DlPaint foreground;
  std::vector<DlColor> colors = {DlColor::kRed(), DlColor::kCyan()};
  std::vector<float> stops = {0.0, 1.0};
  foreground.setColorSource(DlColorSource::MakeLinear(
      DlPoint(0, 0), DlPoint(100, 100), 2, colors.data(), stops.data(),
      DlTileMode::kClamp));
  style.foreground = foreground;

  auto recorder = DlOpRecorder();
  drawText(style, u"😀 😃 😄 😁 😆 😅 😂 🤣 🥲 😊")->Dispatch(recorder);

  EXPECT_EQ(recorder.textFrameCount(), 1);
  EXPECT_EQ(recorder.blobCount(), 0);
  EXPECT_EQ(recorder.pathCount(), 0);
}

TEST_F(PainterTest, DrawTextBlobNoImpeller) {
  PretendImpellerIsEnabled(false);

  auto recorder = DlOpRecorder();
  draw(makeStyle())->Dispatch(recorder);

  EXPECT_EQ(recorder.textFrameCount(), 0);
  EXPECT_EQ(recorder.blobCount(), 1);
}
#endif  // IMPELLER_SUPPORTS_RENDERING

TEST_F(PainterTest, PaintMaskedScrollShrinkLockAndOpacity) {
  PretendImpellerIsEnabled(false);

  auto paragraph = buildParagraph(
      makeStyle(), u"Sample headline text that locks its layout width");
  // Initial layout at expanded width (300px).
  paragraph->LayoutWithShrinkLock(300.0, /*lock_width=*/true);
  const size_t initial_lines = paragraph->GetNumberOfLines();
  const double initial_height = paragraph->GetHeight();

  // Shrinking container to 150px with lock_width=true preserves the 300px line
  // metrics without re-wrapping.
  paragraph->LayoutWithShrinkLock(150.0, /*lock_width=*/true);
  EXPECT_EQ(paragraph->GetNumberOfLines(), initial_lines);
  EXPECT_DOUBLE_EQ(paragraph->GetHeight(), initial_height);

  // Scroll fade reaches 0.0 at 50% width (150px / 300px).
  const double alpha_at_half =
      paragraph->ComputeScrollFadeOpacity(150.0, initial_height, 0.5);
  EXPECT_NEAR(alpha_at_half, 0.0, 1e-4);

  // At 225px (25% shrunk), opacity is 0.5.
  const double alpha_at_quarter =
      paragraph->ComputeScrollFadeOpacity(225.0, initial_height, 0.5);
  EXPECT_NEAR(alpha_at_quarter, 0.5, 1e-4);

  // PaintMasked with opacity 0.5 records a clipRect and a saveLayer.
  auto builder = DisplayListBuilder();
  paragraph->PaintMasked(&builder, 0, 0, 0, 0, 225.0, initial_height,
                         alpha_at_quarter, /*fade_horizontal=*/false);
  auto recorder = DlOpRecorder();
  builder.Build()->Dispatch(recorder);
  EXPECT_EQ(recorder.clipRectCount(), 1);
  EXPECT_EQ(recorder.saveLayerCount(), 1);
  // Layout() resets the shrink lock so subsequent ComputeScrollFadeOpacity
  // starts fresh.
  paragraph->Layout(150.0);
  EXPECT_DOUBLE_EQ(paragraph->ComputeScrollFadeOpacity(150.0, initial_height),
                   1.0);

  // Zero and NaN opacities record no draw operations.
  for (const double invalid_opacity :
       {0.0, -0.5, std::numeric_limits<double>::quiet_NaN()}) {
    auto noop_builder = DisplayListBuilder();
    paragraph->PaintMasked(&noop_builder, 0, 0, 0, 0, 150.0, initial_height,
                           invalid_opacity, /*fade_horizontal=*/true);
    auto noop_recorder = DlOpRecorder();
    noop_builder.Build()->Dispatch(noop_recorder);
    EXPECT_EQ(noop_recorder.clipRectCount(), 0);
    EXPECT_EQ(noop_recorder.saveLayerCount(), 0);
  }
}

TEST_F(PainterTest, PaintMaskedMultilineLastLineHorizontalFade) {
  PretendImpellerIsEnabled(false);

  // Multiline text with max_lines = 2 and horizontal fade modulates only the
  // last line's vertical band, and uses a single SaveLayer even with opacity
  // < 1.
  auto paragraph = buildParagraph(
      makeStyle(),
      u"Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod",
      /*max_lines=*/2);
  paragraph->Layout(200.0);
  ASSERT_EQ(paragraph->GetNumberOfLines(), 2u);

  auto builder = DisplayListBuilder();
  paragraph->PaintMasked(&builder, 0, 0, 0, 0, 200.0, paragraph->GetHeight(),
                         /*opacity=*/0.5, /*fade_horizontal=*/true,
                         txt::OverflowPosition::kEnd);
  auto recorder = DlOpRecorder();
  builder.Build()->Dispatch(recorder);

  EXPECT_EQ(recorder.clipRectCount(), 1);
  EXPECT_EQ(recorder.saveLayerCount(), 1);
  ASSERT_EQ(recorder.rectCount(), 1);
  // The modulate gradient rect only covers the 2nd line (top > 0).
  EXPECT_GT(recorder.rects().front().GetTop(), 0.0f);
  EXPECT_FLOAT_EQ(recorder.rects().front().GetBottom(),
                  static_cast<float>(paragraph->GetHeight()));
  ASSERT_FALSE(recorder.colorSources().empty());
  const auto* linear = recorder.colorSources().back()->asLinearGradient();
  ASSERT_NE(linear, nullptr);
  EXPECT_LT(linear->start_point().x, linear->end_point().x);
}

TEST_F(PainterTest, PaintMaskedSingleLineOverflowPositions) {
  PretendImpellerIsEnabled(false);

  // Single-line directional fade for kStart, kMiddle, kEnd in LTR.
  auto paragraph = buildParagraph(
      makeStyle(), u"0x71C95823F4B9E1029384756ABCDEF01239B8F", /*max_lines=*/1);
  paragraph->Layout(120.0);

  // kStart (LTR): fades toward left edge (start_point.x > end_point.x == 0).
  {
    auto builder = DisplayListBuilder();
    paragraph->PaintMasked(&builder, 0, 0, 0, 0, 120.0, paragraph->GetHeight(),
                           /*opacity=*/1.0, /*fade_horizontal=*/true,
                           txt::OverflowPosition::kStart);
    auto recorder = DlOpRecorder();
    builder.Build()->Dispatch(recorder);
    EXPECT_EQ(recorder.clipRectCount(), 1);
    EXPECT_EQ(recorder.saveLayerCount(), 1);
    ASSERT_EQ(recorder.rectCount(), 1);
    ASSERT_FALSE(recorder.colorSources().empty());
    const auto* linear = recorder.colorSources().back()->asLinearGradient();
    ASSERT_NE(linear, nullptr);
    EXPECT_EQ(linear->stop_count(), 2);
    EXPECT_GT(linear->start_point().x, linear->end_point().x);
    EXPECT_FLOAT_EQ(linear->end_point().x, 0.0f);
  }

  // kMiddle: keeps leading and trailing edges opaque and fades the center.
  {
    auto builder = DisplayListBuilder();
    paragraph->PaintMasked(&builder, 0, 0, 0, 0, 120.0, paragraph->GetHeight(),
                           /*opacity=*/1.0, /*fade_horizontal=*/true,
                           txt::OverflowPosition::kMiddle);
    auto recorder = DlOpRecorder();
    builder.Build()->Dispatch(recorder);
    EXPECT_EQ(recorder.clipRectCount(), 1);
    EXPECT_EQ(recorder.saveLayerCount(), 1);
    ASSERT_EQ(recorder.rectCount(), 1);
    ASSERT_FALSE(recorder.colorSources().empty());
    const auto* linear = recorder.colorSources().back()->asLinearGradient();
    ASSERT_NE(linear, nullptr);
    EXPECT_EQ(linear->stop_count(), 5);
    EXPECT_EQ(linear->colors()[0], DlColor::kWhite());
    EXPECT_EQ(linear->colors()[2], DlColor::kTransparent());
    EXPECT_EQ(linear->colors()[4], DlColor::kWhite());
  }

  // kEnd (LTR): fades toward right edge (start_point.x < end_point.x == 120).
  {
    auto builder = DisplayListBuilder();
    paragraph->PaintMasked(&builder, 0, 0, 0, 0, 120.0, paragraph->GetHeight(),
                           /*opacity=*/1.0, /*fade_horizontal=*/true,
                           txt::OverflowPosition::kEnd);
    auto recorder = DlOpRecorder();
    builder.Build()->Dispatch(recorder);
    EXPECT_EQ(recorder.clipRectCount(), 1);
    EXPECT_EQ(recorder.saveLayerCount(), 1);
    ASSERT_EQ(recorder.rectCount(), 1);
    ASSERT_FALSE(recorder.colorSources().empty());
    const auto* linear = recorder.colorSources().back()->asLinearGradient();
    ASSERT_NE(linear, nullptr);
    EXPECT_EQ(linear->stop_count(), 2);
    EXPECT_LT(linear->start_point().x, linear->end_point().x);
    EXPECT_FLOAT_EQ(linear->end_point().x, 120.0f);
  }

  // kEnd (RTL): fades toward the left edge (end_point.x == 0).
  auto rtl_paragraph =
      buildParagraph(makeStyle(), u"0x71C95823F4B9E1029384756ABCDEF01239B8F",
                     /*max_lines=*/1, txt::TextDirection::rtl);
  rtl_paragraph->Layout(120.0);
  {
    auto builder = DisplayListBuilder();
    rtl_paragraph->PaintMasked(&builder, 0, 0, 0, 0, 120.0,
                               rtl_paragraph->GetHeight(), /*opacity=*/1.0,
                               /*fade_horizontal=*/true,
                               txt::OverflowPosition::kEnd);
    auto recorder = DlOpRecorder();
    builder.Build()->Dispatch(recorder);
    ASSERT_FALSE(recorder.colorSources().empty());
    const auto* linear = recorder.colorSources().back()->asLinearGradient();
    ASSERT_NE(linear, nullptr);
    EXPECT_GT(linear->start_point().x, linear->end_point().x);
    EXPECT_FLOAT_EQ(linear->end_point().x, 0.0f);
  }
}

#ifdef IMPELLER_SUPPORTS_RENDERING
TEST_F(PainterTest, PaintMaskedWithImpeller) {
  PretendImpellerIsEnabled(true);

  // Multiline paragraph with opacity < 1.0 and horizontal fade records Impeller
  // TextFrames (no SkTextBlobs), a single SaveLayer, clipRect, and modulate
  // linear gradient over the last line.
  auto multiline = buildParagraph(
      makeStyle(),
      u"Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod",
      /*max_lines=*/2);
  multiline->Layout(200.0);
  ASSERT_EQ(multiline->GetNumberOfLines(), 2u);

  {
    auto builder = DisplayListBuilder();
    multiline->PaintMasked(&builder, 0, 0, 0, 0, 200.0, multiline->GetHeight(),
                           /*opacity=*/0.5, /*fade_horizontal=*/true,
                           txt::OverflowPosition::kEnd);
    auto recorder = DlOpRecorder();
    builder.Build()->Dispatch(recorder);

    EXPECT_GT(recorder.textFrameCount(), 0);
    EXPECT_EQ(recorder.blobCount(), 0);
    EXPECT_EQ(recorder.clipRectCount(), 1);
    EXPECT_EQ(recorder.saveLayerCount(), 1);
    ASSERT_EQ(recorder.rectCount(), 1);
    EXPECT_GT(recorder.rects().front().GetTop(), 0.0f);
    ASSERT_FALSE(recorder.colorSources().empty());
    const auto* linear = recorder.colorSources().back()->asLinearGradient();
    ASSERT_NE(linear, nullptr);
    EXPECT_LT(linear->start_point().x, linear->end_point().x);
  }

  // Single-line middle fade under Impeller emits TextFrames and the 5-stop
  // center fade gradient.
  auto single_line = buildParagraph(
      makeStyle(), u"0x71C95823F4B9E1029384756ABCDEF01239B8F", /*max_lines=*/1);
  single_line->Layout(120.0);

  {
    auto builder = DisplayListBuilder();
    single_line->PaintMasked(
        &builder, 0, 0, 0, 0, 120.0, single_line->GetHeight(), /*opacity=*/1.0,
        /*fade_horizontal=*/true, txt::OverflowPosition::kMiddle);
    auto recorder = DlOpRecorder();
    builder.Build()->Dispatch(recorder);

    EXPECT_GT(recorder.textFrameCount(), 0);
    EXPECT_EQ(recorder.blobCount(), 0);
    EXPECT_EQ(recorder.clipRectCount(), 1);
    EXPECT_EQ(recorder.saveLayerCount(), 1);
    ASSERT_EQ(recorder.rectCount(), 1);
    ASSERT_FALSE(recorder.colorSources().empty());
    const auto* linear = recorder.colorSources().back()->asLinearGradient();
    ASSERT_NE(linear, nullptr);
    EXPECT_EQ(linear->stop_count(), 5);
    EXPECT_EQ(linear->colors()[0], DlColor::kWhite());
    EXPECT_EQ(linear->colors()[2], DlColor::kTransparent());
    EXPECT_EQ(linear->colors()[4], DlColor::kWhite());
  }
}
#endif  // IMPELLER_SUPPORTS_RENDERING

}  // namespace testing
}  // namespace flutter
