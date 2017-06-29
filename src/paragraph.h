/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef LIB_TXT_SRC_PARAGRAPH_H_
#define LIB_TXT_SRC_PARAGRAPH_H_

#include <tuple>
#include <vector>

#include "lib/ftl/macros.h"
#include "lib/txt/src/font_collection.h"
#include "lib/txt/src/paint_record.h"
#include "lib/txt/src/paragraph_style.h"
#include "lib/txt/src/styled_runs.h"
#include "minikin/LineBreaker.h"
#include "third_party/gtest/include/gtest/gtest_prod.h"
#include "third_party/skia/include/core/SkTextBlob.h"

class SkCanvas;

namespace txt {

class Paragraph {
 public:
  Paragraph();

  ~Paragraph();

  void Layout(double width, bool force = false);

  void Paint(SkCanvas* canvas, double x, double y);

  const ParagraphStyle& GetParagraphStyle() const;

  double GetHeight() const;

  double GetAlphabeticBaseline() const;

  double GetIdeographicBaseline() const;

  double GetMaxIntrinsicWidth() const;

  double GetMinIntrinsicWidth() const;

  int GetLineCount() const;

  bool DidExceedMaxLines() const;

 private:
  friend class ParagraphBuilder;
  FRIEND_TEST(RenderTest, SimpleParagraph);
  FRIEND_TEST(RenderTest, SimpleRedParagraph);
  FRIEND_TEST(RenderTest, RainbowParagraph);
  FRIEND_TEST(RenderTest, DefaultStyleParagraph);
  FRIEND_TEST(RenderTest, BoldParagraph);
  FRIEND_TEST(RenderTest, LeftAlignParagraph);
  FRIEND_TEST(RenderTest, RightAlignParagraph);
  FRIEND_TEST(RenderTest, CenterAlignParagraph);
  FRIEND_TEST(RenderTest, JustifyAlignParagraph);
  FRIEND_TEST(RenderTest, ItalicsParagraph);

  std::vector<uint16_t> text_;
  StyledRuns runs_;
  minikin::LineBreaker breaker_;
  std::vector<PaintRecord> records_;
  std::vector<double> line_widths_;
  ParagraphStyle paragraph_style_;
  FontCollection* font_collection_;
  // TODO(garyq): Height of the paragraph after Layout().
  SkScalar height_ = 0.0f;
  double width_ = 0.0f;
  size_t lines_ = 0;
  double max_intrinsic_width_ = 0.0f;
  double min_intrinsic_width_ = 0.0f;
  double alphabetic_baseline_ = FLT_MAX;
  double ideographic_baseline_ = FLT_MAX;
  bool needs_layout_ = true;

  void SetText(std::vector<uint16_t> text, StyledRuns runs);

  void SetParagraphStyle(const ParagraphStyle& style);

  void SetFontCollection(FontCollection* font_collection);

  void AddRunsToLineBreaker(
      std::shared_ptr<minikin::FontCollection>& collection,
      std::string& prev_font_family);

  void JustifyLine(std::vector<const SkTextBlobBuilder::RunBuffer*>& buffers,
                   std::vector<size_t>& buffer_sizes,
                   int word_count,
                   size_t character_index);

  void PaintDecorations(SkCanvas* canvas,
                        double x,
                        double y,
                        TextStyle style,
                        SkPaint::FontMetrics metrics,
                        SkTextBlob* blob);

  FTL_DISALLOW_COPY_AND_ASSIGN(Paragraph);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_H_
