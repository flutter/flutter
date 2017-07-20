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
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkTextBlob.h"

class SkCanvas;

namespace txt {

using GlyphID = uint32_t;

class Paragraph {
 public:
  Paragraph();

  ~Paragraph();

  void Layout(double width, bool force = false);

  // Paints the Laid out text onto the supplied SkCanvas at (x, y) offset from
  // the origin. Only valid after Layout() is called.
  void Paint(SkCanvas* canvas, double x, double y);

  const ParagraphStyle& GetParagraphStyle() const;

  size_t TextSize() const;

  double GetHeight() const;

  // Returns the actual max width of the longest line after Layout().
  double GetLayoutWidth() const;

  // Returns the width provided in the Layout() method.
  double GetMaxWidth() const;

  double GetAlphabeticBaseline() const;

  double GetIdeographicBaseline() const;

  double GetMaxIntrinsicWidth() const;

  double GetMinIntrinsicWidth() const;

  // Returns a vector of bounding boxes that enclose all text between start and
  // end glyph indexes, including start and excluding end.
  std::vector<SkRect> GetRectsForRange(size_t start, size_t end) const;

  // Returns the index of the glyph that corresponds to the provided coordinate,
  // with the top left corner as the origin, and +y direction as down.
  size_t GetGlyphPositionAtCoordinate(double dx, double dy) const;

  // Returns a bounding box that encloses the glyph at the index pos.
  SkRect GetCoordinatesForGlyphPosition(size_t pos) const;

  // Finds the first and last glyphs that define a word containing the glyph at
  // index offset.
  SkIPoint GetWordBoundary(size_t offset) const;

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
  FRIEND_TEST(RenderTest, DecorationsParagraph);
  FRIEND_TEST(RenderTest, ItalicsParagraph);
  FRIEND_TEST(RenderTest, ChineseParagraph);
  FRIEND_TEST(RenderTest, DISABLED_ArabicParagraph);
  FRIEND_TEST(RenderTest, SpacingParagraph);

  std::vector<uint16_t> text_;
  StyledRuns runs_;
  minikin::LineBreaker breaker_;
  std::vector<PaintRecord> records_;
  std::vector<double> line_widths_;

  // TODO(garyq): Can we access this info without redundantly storing it here?
  std::vector<double> line_heights_;
  std::vector<std::vector<double>> glyph_position_x_;

  // Set of glyph IDs that correspond to whitespace.
  std::set<GlyphID> whitespace_set_;

  ParagraphStyle paragraph_style_;
  FontCollection* font_collection_;
  SkScalar height_ = 0.0f;
  double width_ = 0.0f;
  size_t lines_ = 0;
  double max_intrinsic_width_ = 0;
  double min_intrinsic_width_ = 0;
  // TODO(garyq): Instead of using whitespace to delimit "words", use the
  // results of minikin breaker.
  std::vector<double> word_widths_;
  double alphabetic_baseline_ = FLT_MAX;
  double ideographic_baseline_ = FLT_MAX;
  bool needs_layout_ = true;

  struct WaveCoordinates {
    double x_start;
    double y_start;
    double x_end;
    double y_end;

    WaveCoordinates(double x_s, double y_s, double x_e, double y_e)
        : x_start(x_s), y_start(y_s), x_end(x_e), y_end(y_e) {}
  };

  void SetText(std::vector<uint16_t> text, StyledRuns runs);

  void SetParagraphStyle(const ParagraphStyle& style);

  void SetFontCollection(FontCollection* font_collection);

  void AddRunsToLineBreaker(
      std::unordered_map<std::string, std::shared_ptr<minikin::FontCollection>>&
          collection_map);

  // Calculates the GlyphIDs of all whitespace characters present in the text
  // between start and end. THis is used to correctly add extra whitespace when
  // justifying.
  void FillWhitespaceSet(size_t start, size_t end, hb_font_t* hb_font);

  void JustifyLine(std::vector<const SkTextBlobBuilder::RunBuffer*>& buffers,
                   std::vector<size_t>& buffer_sizes,
                   int word_count,
                   double& justify_spacing,
                   double multiplier = 1);

  void PaintDecorations(SkCanvas* canvas,
                        double x,
                        double y,
                        size_t record_index);

  void PaintWavyDecoration(SkCanvas* canvas,
                           std::vector<WaveCoordinates> wave_coords,
                           SkPaint paint,
                           double x,
                           double y,
                           double y_offset,
                           double width);

  void CalculateIntrinsicWidths();

  FTL_DISALLOW_COPY_AND_ASSIGN(Paragraph);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_H_
