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
#include <utility>
#include <vector>

#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/macros.h"
#include "font_collection.h"
#include "minikin/LineBreaker.h"
#include "paint_record.h"
#include "paragraph_style.h"
#include "styled_runs.h"
#include "third_party/googletest/googletest/include/gtest/gtest_prod.h"  // nogncheck
#include "third_party/skia/include/core/SkRect.h"
#include "utils/WindowsUtils.h"

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
  // Constructor. It is highly recommended to construct a paragraph with a
  // ParagraphBuilder.
  Paragraph();

  ~Paragraph();

  enum Affinity { UPSTREAM, DOWNSTREAM };

  // TODO(garyq): Implement kIncludeLineSpacing and kExtendEndOfLine

  // Options for various types of bounding boxes provided by
  // GetRectsForRange(...).
  // These options can be individually enabled, for example:
  //
  //   (RectStyle::kTight | RectStyle::kExtendEndOfLine)
  //
  // provides tight bounding boxes and extends the last box per line to the end
  // of the layout area.
  enum RectStyle {
    kNone = 0x0,  // kNone cannot be combined with |.

    // Provide tight bounding boxes that fit heights per span. Otherwise, the
    // heights of spans are the max of the heights of the line the span belongs
    // in.
    kTight = 0x1
  };

  struct PositionWithAffinity {
    const size_t position;
    const Affinity affinity;

    PositionWithAffinity(size_t p, Affinity a) : position(p), affinity(a) {}
  };

  struct TextBox {
    SkRect rect;
    TextDirection direction;

    TextBox(SkRect r, TextDirection d) : rect(r), direction(d) {}
  };

  template <typename T>
  struct Range {
    Range() : start(), end() {}
    Range(T s, T e) : start(s), end(e) {}

    T start, end;

    bool operator==(const Range<T>& other) const {
      return start == other.start && end == other.end;
    }

    T width() { return end - start; }

    void Shift(T delta) {
      start += delta;
      end += delta;
    }
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
  std::vector<TextBox> GetRectsForRange(size_t start,
                                        size_t end,
                                        RectStyle rect_style) const;

  // Returns the index of the glyph that corresponds to the provided coordinate,
  // with the top left corner as the origin, and +y direction as down.
  PositionWithAffinity GetGlyphPositionAtCoordinate(double dx, double dy) const;

  // Finds the first and last glyphs that define a word containing the glyph at
  // index offset.
  Range<size_t> GetWordBoundary(size_t offset) const;

  // Returns the number of lines the paragraph takes up. If the text exceeds the
  // amount width and maxlines provides, Layout() truncates the extra text from
  // the layout and this will return the max lines allowed.
  size_t GetLineCount() const;

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
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, LeftAlignParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, RightAlignParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, CenterAlignParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, JustifyAlignParagraph);
  FRIEND_TEST(ParagraphTest, DecorationsParagraph);
  FRIEND_TEST(ParagraphTest, ItalicsParagraph);
  FRIEND_TEST(ParagraphTest, ChineseParagraph);
  FRIEND_TEST(ParagraphTest, DISABLED_ArabicParagraph);
  FRIEND_TEST(ParagraphTest, SpacingParagraph);
  FRIEND_TEST(ParagraphTest, LongWordParagraph);
  FRIEND_TEST(ParagraphTest, KernScaleParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, NewlineParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, EmojiParagraph);
  FRIEND_TEST(ParagraphTest, HyphenBreakParagraph);
  FRIEND_TEST(ParagraphTest, RepeatLayoutParagraph);
  FRIEND_TEST(ParagraphTest, Ellipsize);
  FRIEND_TEST(ParagraphTest, UnderlineShiftParagraph);
  FRIEND_TEST(ParagraphTest, SimpleShadow);
  FRIEND_TEST(ParagraphTest, ComplexShadow);

  // Starting data to layout.
  std::vector<uint16_t> text_;
  StyledRuns runs_;
  ParagraphStyle paragraph_style_;
  std::shared_ptr<FontCollection> font_collection_;

  minikin::LineBreaker breaker_;
  mutable std::unique_ptr<icu::BreakIterator> word_breaker_;

  struct LineRange {
    LineRange(size_t s, size_t e, size_t eew, size_t ein, bool h)
        : start(s),
          end(e),
          end_excluding_whitespace(eew),
          end_including_newline(ein),
          hard_break(h) {}
    size_t start, end;
    size_t end_excluding_whitespace;
    size_t end_including_newline;
    bool hard_break;
  };
  std::vector<LineRange> line_ranges_;
  std::vector<double> line_widths_;

  // Stores the result of Layout().
  std::vector<PaintRecord> records_;

  std::vector<double> line_heights_;
  std::vector<double> line_baselines_;
  bool did_exceed_max_lines_;

  class BidiRun {
   public:
    BidiRun(size_t s, size_t e, TextDirection d, const TextStyle& st)
        : start_(s), end_(e), direction_(d), style_(&st) {}

    size_t start() const { return start_; }
    size_t end() const { return end_; }
    TextDirection direction() const { return direction_; }
    const TextStyle& style() const { return *style_; }
    bool is_rtl() const { return direction_ == TextDirection::rtl; }

   private:
    size_t start_, end_;
    TextDirection direction_;
    const TextStyle* style_;
  };

  struct GlyphPosition {
    Range<size_t> code_units;
    Range<double> x_pos;

    GlyphPosition(double x_start,
                  double x_advance,
                  size_t code_unit_index,
                  size_t code_unit_width);

    void Shift(double delta);
  };

  struct GlyphLine {
    // Glyph positions sorted by x coordinate.
    const std::vector<GlyphPosition> positions;
    const size_t total_code_units;

    GlyphLine(std::vector<GlyphPosition>&& p, size_t tcu);
  };

  struct CodeUnitRun {
    // Glyph positions sorted by code unit index.
    std::vector<GlyphPosition> positions;
    Range<size_t> code_units;
    Range<double> x_pos;
    size_t line_number;
    SkPaint::FontMetrics font_metrics;
    TextDirection direction;

    CodeUnitRun(std::vector<GlyphPosition>&& p,
                Range<size_t> cu,
                Range<double> x,
                size_t line,
                const SkPaint::FontMetrics& metrics,
                TextDirection dir);

    void Shift(double delta);
  };

  // Holds the laid out x positions of each glyph.
  std::vector<GlyphLine> glyph_lines_;

  // Holds the positions of each range of code units in the text.
  // Sorted in code unit index order.
  std::vector<CodeUnitRun> code_unit_runs_;

  // The max width of the paragraph as provided in the most recent Layout()
  // call.
  double width_ = -1.0f;
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

  void SetParagraphStyle(const ParagraphStyle& style);

  void SetFontCollection(std::shared_ptr<FontCollection> font_collection);

  // Break the text into lines.
  bool ComputeLineBreaks();

  // Break the text into runs based on LTR/RTL text direction.
  bool ComputeBidiRuns(std::vector<BidiRun>* result);

  // Calculate the starting X offset of a line based on the line's width and
  // alignment.
  double GetLineXOffset(double line_total_advance);

  // Creates and draws the decorations onto the canvas.
  void PaintDecorations(SkCanvas* canvas,
                        const PaintRecord& record,
                        SkPoint base_offset);

  // Draws the background onto the canvas.
  void PaintBackground(SkCanvas* canvas,
                       const PaintRecord& record,
                       SkPoint base_offset);

  // Draws the shadows onto the canvas.
  void PaintShadow(SkCanvas* canvas, const PaintRecord& record, SkPoint offset);

  // Obtain a Minikin font collection matching this text style.
  std::shared_ptr<minikin::FontCollection> GetMinikinFontCollectionForStyle(
      const TextStyle& style);

  // Get a default SkTypeface for a text style.
  sk_sp<SkTypeface> GetDefaultSkiaTypeface(const TextStyle& style);

  FML_DISALLOW_COPY_AND_ASSIGN(Paragraph);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_H_
