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

#include <set>
#include <tuple>
#include <vector>

#include "font_collection.h"
#include "lib/fxl/compiler_specific.h"
#include "lib/fxl/macros.h"
#include "minikin/LineBreaker.h"
#include "paint_record.h"
#include "paragraph_style.h"
#include "styled_runs.h"
#include "third_party/gtest/include/gtest/gtest_prod.h"
#include "third_party/skia/include/core/SkPoint.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkTextBlob.h"

class SkCanvas;

namespace txt {

using GlyphID = uint32_t;

// Paragraph provides Layout, metrics, and painting capabilites for text. Once a
// Paragraph is constructed with ParagraphBuilder::Build(), an example basic
// workflow can be this:
//
//   std::unique_ptr<Paragraph> paragraph = paragraph_builder.Build();
//   paragraph->Layout(<somewidthgoeshere>);
//   paragraph->Paint(<someSkCanvas>, <xpos>, <ypos>);
class Paragraph {
 public:
  // Constructor. I is highly recommended to construct a paragrph with a
  // ParagraphBuilder.
  Paragraph();

  ~Paragraph();

  enum Affinity { UPSTREAM, DOWNSTREAM };

  struct PositionWithAffinity {
    const size_t position;
    const Affinity affinity;

    PositionWithAffinity(size_t p, Affinity a) : position(p), affinity(a) {}
  };

  // Minikin Layout doLayout() and LineBreaker addStyleRun() has an
  // O(N^2) (according to benchmarks) time complexity where N is the total
  // number of characters. However, this is not significant for reasonably sized
  // paragraphs. It is currently recommended to break up very long paragraphs
  // (10k+ characters) to ensure speedy layout.
  //
  // Layout calculates the positioning of all the glyphs. Must call this method
  // before Painting and getting any statistics from this class.
  void Layout(double width, bool force = false);

  // Paints the Laid out text onto the supplied SkCanvas at (x, y) offset from
  // the origin. Only valid after Layout() is called.
  void Paint(SkCanvas* canvas, double x, double y);

  // Getter for paragraph_style_.
  const ParagraphStyle& GetParagraphStyle() const;

  // Returns the number of characters/unicode characters. AKA text_.size()
  size_t TextSize() const;

  // Returns the height of the laid out paragraph. NOTE this is not a tight
  // bounding height of the glyphs, as some glyphs do not reach as low as they
  // can.
  double GetHeight() const;

  // Returns the width provided in the Layout() method. This is the maximum
  // width any line in the laid out paragraph can occupy. We expect that
  // GetMaxWidth() >= GetLayoutWidth().
  double GetMaxWidth() const;

  // Distance from top of paragraph to the Alphabetic baseline of the first
  // line. Used for alphabetic fonts (A-Z, a-z, greek, etc.)
  double GetAlphabeticBaseline() const;

  // Distance from top of paragraph to the Ideographic baseline of the first
  // line. Used for ideographic fonts (Chinese, Japanese, Korean, etc.)
  double GetIdeographicBaseline() const;

  // Returns the total width covered by the paragraph without linebreaking.
  double GetMaxIntrinsicWidth() const;

  // Currently, calculated similarly to as GetLayoutWidth(), however this is not
  // nessecarily 100% correct in all cases.
  //
  // Returns the actual max width of the longest line after Layout().
  double GetMinIntrinsicWidth() const;

  // Returns a vector of bounding boxes that enclose all text between start and
  // end glyph indexes, including start and excluding end.
  std::vector<SkRect> GetRectsForRange(size_t start, size_t end) const;

  // Returns the index of the glyph that corresponds to the provided coordinate,
  // with the top left corner as the origin, and +y direction as down.
  //
  // When using_glyph_center_as_boundary == true, coords to the + direction of
  // the center x-position of the glyph will be considered as the next glyph. A
  // typical use-case for this is when the cursor is meant to be on either side
  // of any given character. This allows the transition border to be middle of
  // each character.
  PositionWithAffinity GetGlyphPositionAtCoordinate(
      double dx,
      double dy,
      bool using_glyph_center_as_boundary = false) const;

  // Returns a bounding box that encloses the glyph at the index pos.
  SkRect GetCoordinatesForGlyphPosition(size_t pos) const;

  // Finds the first and last glyphs that define a word containing the glyph at
  // index offset.
  SkIPoint GetWordBoundary(size_t offset) const;

  // Returns the number of lines the paragraph takes up. If the text exceeds the
  // amount width and maxlines provides, Layout() truncates the extra text from
  // the layout and this will return the max lines allowed.
  int GetLineCount() const;

  // Checks if the layout extends past the maximum lines and had to be
  // truncated.
  bool DidExceedMaxLines() const;

  // Sets the needs_layout_ to dirty. When Layout() is called, a new Layout will
  // be performed when this is set to true. Can also be used to prevent a new
  // Layout from being calculated by setting to false.
  void SetDirty(bool dirty = true);

 private:
  friend class ParagraphBuilder;
  FRIEND_TEST(ParagraphTest, SimpleParagraph);
  FRIEND_TEST(ParagraphTest, SimpleRedParagraph);
  FRIEND_TEST(ParagraphTest, RainbowParagraph);
  FRIEND_TEST(ParagraphTest, DefaultStyleParagraph);
  FRIEND_TEST(ParagraphTest, BoldParagraph);
  FRIEND_TEST(ParagraphTest, LeftAlignParagraph);
  FRIEND_TEST(ParagraphTest, RightAlignParagraph);
  FRIEND_TEST(ParagraphTest, CenterAlignParagraph);
  FRIEND_TEST(ParagraphTest, JustifyAlignParagraph);
  FRIEND_TEST(ParagraphTest, DecorationsParagraph);
  FRIEND_TEST(ParagraphTest, ItalicsParagraph);
  FRIEND_TEST(ParagraphTest, ChineseParagraph);
  FRIEND_TEST(ParagraphTest, DISABLED_ArabicParagraph);
  FRIEND_TEST(ParagraphTest, SpacingParagraph);
  FRIEND_TEST(ParagraphTest, LongWordParagraph);
  FRIEND_TEST(ParagraphTest, KernScaleParagraph);
  FRIEND_TEST(ParagraphTest, NewlineParagraph);
  FRIEND_TEST(ParagraphTest, EmojiParagraph);
  FRIEND_TEST(ParagraphTest, HyphenBreakParagraph);
  FRIEND_TEST(ParagraphTest, RepeatLayoutParagraph);
  FRIEND_TEST(ParagraphTest, Ellipsize);

  // Starting data to layout.
  std::vector<uint16_t> text_;
  StyledRuns runs_;
  ParagraphStyle paragraph_style_;
  std::shared_ptr<FontCollection> font_collection_;

  minikin::LineBreaker breaker_;
  size_t breaks_count_ = 0;

  // Stores the result of Layout().
  std::vector<PaintRecord> records_;

  std::vector<double> line_heights_;

  struct GlyphPosition {
    double start;
    double advance;

    GlyphPosition(double s, double a) : start(s), advance(a) {}

    double glyph_end() const { return start + advance; }
  };

  // Holds the laid out x positions of each glyph.
  std::vector<std::vector<GlyphPosition>> glyph_position_x_;

  // Set of glyph IDs that correspond to whitespace.
  std::set<GlyphID> whitespace_set_;

  // The max width of the paragraph as provided in the most recent Layout()
  // call.
  double width_ = -1.0f;
  size_t lines_ = 0;
  double max_intrinsic_width_ = 0;
  double min_intrinsic_width_ = 0;
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

  // Passes in the text and Styled Runs. text_ and runs_ will later be passed
  // into breaker_ in InitBreaker(), which is called in Layout().
  void SetText(std::vector<uint16_t> text, StyledRuns runs);

  // Sets up breaker_ with the contents of text_ and runs_. This is called every
  // Layout() call to allow for different widths to be used.
  void InitBreaker();

  void SetParagraphStyle(const ParagraphStyle& style);

  void SetFontCollection(std::shared_ptr<FontCollection> font_collection);

  FXL_WARN_UNUSED_RESULT
  bool AddRunsToLineBreaker(
      std::unordered_map<std::string, std::shared_ptr<minikin::FontCollection>>&
          collection_map);

  // Calculates the GlyphIDs of all whitespace characters present in the text
  // between start and end. THis is used to correctly add extra whitespace when
  // justifying.
  void FillWhitespaceSet(size_t start, size_t end, hb_font_t* hb_font);

  // Calculate the starting X offset of a line based on the line's width and
  // alignment.
  double GetLineXOffset(size_t line);

  // Calculates and amends the layout for one line to be justified.
  void JustifyLine(std::vector<const SkTextBlobBuilder::RunBuffer*>& buffers,
                   std::vector<size_t>& buffer_sizes,
                   int word_count,
                   double& justify_spacing,
                   double multiplier = 1);

  // Creates and draws the decorations onto the canvas.
  void PaintDecorations(SkCanvas* canvas,
                        double x,
                        double y,
                        size_t record_index);

  void CalculateIntrinsicWidths();

  FXL_DISALLOW_COPY_AND_ASSIGN(Paragraph);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_H_
