// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include "display_list/dl_color.h"
#include "display_list/dl_paint.h"
#include "display_list/dl_tile_mode.h"
#include "display_list/effects/dl_color_source.h"
#include "display_list/utils/dl_receiver_utils.h"
#include "gtest/gtest.h"
#include "include/core/SkScalar.h"
#include "runtime/test_font_data.h"
#include "skia/paragraph_builder_skia.h"
#include "testing/canvas_test.h"

namespace flutter {
namespace testing {

//------------------------------------------------------------------------------
/// @brief      A custom |DlOpReceiver| that records some |DlOps| it receives.
class DlOpRecorder final : public virtual DlOpReceiver,
                           private IgnoreAttributeDispatchHelper,
                           private IgnoreClipDispatchHelper,
                           private IgnoreDrawDispatchHelper,
                           private IgnoreTransformDispatchHelper {
 public:
  int lineCount() const { return lines_.size(); }
  int rectCount() const { return rects_.size(); }
  int pathCount() const { return paths_.size(); }
  int textFrameCount() const { return text_frames_.size(); }
  int blobCount() const { return blobs_.size(); }
  bool hasPathEffect() const { return path_effect_ != nullptr; }

 private:
  void drawLine(const SkPoint& p0, const SkPoint& p1) override {
    lines_.emplace_back(p0, p1);
  }

  void drawTextFrame(const std::shared_ptr<impeller::TextFrame>& text_frame,
                     SkScalar x,
                     SkScalar y) override {
    text_frames_.push_back(text_frame);
  }

  void drawTextBlob(const sk_sp<SkTextBlob> blob,
                    SkScalar x,
                    SkScalar y) override {
    blobs_.push_back(blob);
  }

  void drawRect(const SkRect& rect) override { rects_.push_back(rect); }

  void drawPath(const SkPath& path) override { paths_.push_back(path); }

  void setPathEffect(const DlPathEffect* effect) override {
    path_effect_ = effect;
  }

  std::vector<std::shared_ptr<impeller::TextFrame>> text_frames_;
  std::vector<sk_sp<SkTextBlob>> blobs_;
  std::vector<std::pair<SkPoint, SkPoint>> lines_;
  std::vector<SkRect> rects_;
  std::vector<SkPath> paths_;
  const DlPathEffect* path_effect_;
};

template <typename T>
class PainterTestBase : public CanvasTestBase<T> {
 public:
  PainterTestBase() = default;

  void PretendImpellerIsEnabled(bool impeller) { impeller_ = impeller; }

 protected:
  txt::TextStyle makeDecoratedStyle(txt::TextDecorationStyle style) {
    auto t_style = txt::TextStyle();
    t_style.color = SK_ColorBLACK;                // default
    t_style.font_weight = txt::FontWeight::w400;  // normal
    t_style.font_size = 14;                       // default
    t_style.decoration = txt::TextDecoration::kUnderline;
    t_style.decoration_style = style;
    t_style.decoration_color = SK_ColorBLACK;
    t_style.font_families.push_back("ahem");
    return t_style;
  }

  txt::TextStyle makeStyle() {
    auto t_style = txt::TextStyle();
    t_style.color = SK_ColorBLACK;                // default
    t_style.font_weight = txt::FontWeight::w400;  // normal
    t_style.font_size = 14;                       // default
    t_style.font_families.push_back("ahem");
    return t_style;
  }

  sk_sp<DisplayList> draw(txt::TextStyle style) const {
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

 private:
  std::shared_ptr<txt::FontCollection> makeFontCollection() const {
    auto f_collection = std::make_shared<txt::FontCollection>();
    auto font_provider = std::make_unique<txt::TypefaceFontAssetProvider>();
    for (auto& font : GetTestFontData()) {
      font_provider->RegisterTypeface(font);
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
  EXPECT_FALSE(recorder.hasPathEffect());
}

TEST_F(PainterTest, DrawDashedLineSkia) {
  PretendImpellerIsEnabled(false);

  auto recorder = DlOpRecorder();
  draw(makeDecoratedStyle(txt::TextDecorationStyle::kDashed))
      ->Dispatch(recorder);

  // Skia draws a dashed underline as a filled rectangle with a path effect.
  EXPECT_EQ(recorder.lineCount(), 1);
  EXPECT_TRUE(recorder.hasPathEffect());
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
  EXPECT_FALSE(recorder.hasPathEffect());
}

TEST_F(PainterTest, DrawDashedLineImpeller) {
  PretendImpellerIsEnabled(true);

  auto recorder = DlOpRecorder();
  draw(makeDecoratedStyle(txt::TextDecorationStyle::kDashed))
      ->Dispatch(recorder);

  // Impeller draws a dashed underline as a path.
  EXPECT_EQ(recorder.pathCount(), 1);
  EXPECT_FALSE(recorder.hasPathEffect());
}

TEST_F(PainterTest, DrawTextFrameImpeller) {
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
      SkPoint::Make(0, 0), SkPoint::Make(100, 100), 2, colors.data(),
      stops.data(), DlTileMode::kClamp));
  style.foreground = foreground;

  auto recorder = DlOpRecorder();
  draw(style)->Dispatch(recorder);

  EXPECT_EQ(recorder.textFrameCount(), 0);
  EXPECT_EQ(recorder.blobCount(), 0);
  EXPECT_EQ(recorder.pathCount(), 1);
}

TEST_F(PainterTest, DrawTextBlobNoImpeller) {
  PretendImpellerIsEnabled(false);

  auto recorder = DlOpRecorder();
  draw(makeStyle())->Dispatch(recorder);

  EXPECT_EQ(recorder.textFrameCount(), 0);
  EXPECT_EQ(recorder.blobCount(), 1);
}
#endif  // IMPELLER_SUPPORTS_RENDERING

}  // namespace testing
}  // namespace flutter
