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

#ifndef LIB_TXT_SRC_PARAGRAPH_TXT_H_
#define LIB_TXT_SRC_PARAGRAPH_TXT_H_

#include <set>
#include <utility>
#include <vector>

#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/macros.h"
#include "font_collection.h"
#include "line_metrics.h"
#include "minikin/LineBreaker.h"
#include "paint_record.h"
#include "paragraph.h"
#include "paragraph_style.h"
#include "placeholder_run.h"
#include "run_metrics.h"
#include "styled_runs.h"
#include "third_party/googletest/googletest/include/gtest/gtest_prod.h"  // nogncheck
#include "third_party/skia/include/core/SkFontMetrics.h"
#include "third_party/skia/include/core/SkRect.h"
#include "utils/LinuxUtils.h"
#include "utils/MacUtils.h"
#include "utils/WindowsUtils.h"

namespace txt {

using GlyphID = uint32_t;

// Constant with the unicode codepoint for the "Object replacement character".
// Used as a stand-in character for Placeholder boxes.
const int objReplacementChar = 0xFFFC;
// Constant with the unicode codepoint for the "Replacement character". This is
// the character that commonly renders as a black diamond with a white question
// mark. Used to replace non-placeholder instances of 0xFFFC in the text buffer.
const int replacementChar = 0xFFFD;

// Paragraph provides Layout, metrics, and painting capabilities for text. Once
// a Paragraph is constructed with ParagraphBuilder::Build(), an example basic
// workflow can be this:
//
//   std::unique_ptr<Paragraph> paragraph = paragraph_builder.Build();
//   paragraph->Layout(<somewidthgoeshere>);
//   paragraph->Paint(<someSkCanvas>, <xpos>, <ypos>);
class ParagraphTxt : public Paragraph {
 public:
  // Constructor. It is highly recommended to construct a paragraph with a
  // ParagraphBuilder.
  ParagraphTxt();

  virtual ~ParagraphTxt();

  // Minikin Layout doLayout() and LineBreaker addStyleRun() has an
  // O(N^2) (according to benchmarks) time complexity where N is the total
  // number of characters. However, this is not significant for reasonably sized
  // paragraphs. It is currently recommended to break up very long paragraphs
  // (10k+ characters) to ensure speedy layout.
  virtual void Layout(double width) override;

  virtual void Paint(SkCanvas* canvas, double x, double y) override;

  // Getter for paragraph_style_.
  const ParagraphStyle& GetParagraphStyle() const;

  // Returns the number of characters/unicode characters. AKA text_.size()
  size_t TextSize() const;

  double GetHeight() override;

  double GetMaxWidth() override;

  double GetLongestLine() override;

  double GetAlphabeticBaseline() override;

  double GetIdeographicBaseline() override;

  double GetMaxIntrinsicWidth() override;

  // Currently, calculated similarly to as GetLayoutWidth(), however this is not
  // necessarily 100% correct in all cases.
  double GetMinIntrinsicWidth() override;

  std::vector<TextBox> GetRectsForRange(
      size_t start,
      size_t end,
      RectHeightStyle rect_height_style,
      RectWidthStyle rect_width_style) override;

  PositionWithAffinity GetGlyphPositionAtCoordinate(double dx,
                                                    double dy) override;

  std::vector<Paragraph::TextBox> GetRectsForPlaceholders() override;

  Range<size_t> GetWordBoundary(size_t offset) override;

  // Returns the number of lines the paragraph takes up. If the text exceeds the
  // amount width and maxlines provides, Layout() truncates the extra text from
  // the layout and this will return the max lines allowed.
  size_t GetLineCount();

  bool DidExceedMaxLines() override;

  // Gets the full vector of LineMetrics which includes detailed data on each
  // line in the final layout.
  std::vector<LineMetrics>& GetLineMetrics() override;

  // Sets the needs_layout_ to dirty. When Layout() is called, a new Layout will
  // be performed when this is set to true. Can also be used to prevent a new
  // Layout from being calculated by setting to false.
  void SetDirty(bool dirty = true);

 private:
  friend class ParagraphBuilderTxt;
  FRIEND_TEST(ParagraphTest, SimpleParagraph);
  FRIEND_TEST(ParagraphTest, SimpleParagraphSmall);
  FRIEND_TEST(ParagraphTest, SimpleRedParagraph);
  FRIEND_TEST(ParagraphTest, RainbowParagraph);
  FRIEND_TEST(ParagraphTest, DefaultStyleParagraph);
  FRIEND_TEST(ParagraphTest, BoldParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, LeftAlignParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, RightAlignParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, CenterAlignParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, JustifyAlignParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, JustifyRTL);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, InlinePlaceholderLongestLine);
  FRIEND_TEST_LINUX_ONLY(ParagraphTest, JustifyRTLNewLine);
  FRIEND_TEST(ParagraphTest, DecorationsParagraph);
  FRIEND_TEST(ParagraphTest, ItalicsParagraph);
  FRIEND_TEST(ParagraphTest, ChineseParagraph);
  FRIEND_TEST(ParagraphTest, DISABLED_ArabicParagraph);
  FRIEND_TEST(ParagraphTest, SpacingParagraph);
  FRIEND_TEST(ParagraphTest, LongWordParagraph);
  FRIEND_TEST_LINUX_ONLY(ParagraphTest, KernScaleParagraph);
  FRIEND_TEST_WINDOWS_DISABLED(ParagraphTest, NewlineParagraph);
  FRIEND_TEST_LINUX_ONLY(ParagraphTest, EmojiParagraph);
  FRIEND_TEST_LINUX_ONLY(ParagraphTest, EmojiMultiLineRectsParagraph);
  FRIEND_TEST(ParagraphTest, HyphenBreakParagraph);
  FRIEND_TEST(ParagraphTest, RepeatLayoutParagraph);
  FRIEND_TEST(ParagraphTest, Ellipsize);
  FRIEND_TEST(ParagraphTest, UnderlineShiftParagraph);
  FRIEND_TEST(ParagraphTest, WavyDecorationParagraph);
  FRIEND_TEST(ParagraphTest, SimpleShadow);
  FRIEND_TEST(ParagraphTest, ComplexShadow);
  FRIEND_TEST(ParagraphTest, FontFallbackParagraph);
  FRIEND_TEST(ParagraphTest, InlinePlaceholder0xFFFCParagraph);
  FRIEND_TEST(ParagraphTest, FontFeaturesParagraph);
  FRIEND_TEST(ParagraphTest, GetGlyphPositionAtCoordinateSegfault);
  FRIEND_TEST(ParagraphTest, KhmerLineBreaker);
  FRIEND_TEST(ParagraphTest, TextHeightBehaviorRectsParagraph);

  // Starting data to layout.
  std::vector<uint16_t> text_;
  // A vector of PlaceholderRuns, which detail the sizes, positioning and break
  // behavior of the empty spaces to leave. Each placeholder span corresponds to
  // a 0xFFFC (object replacement character) in text_, which indicates the
  // position in the text where the placeholder will occur. There should be an
  // equal number of 0xFFFC characters and elements in this vector.
  std::vector<PlaceholderRun> inline_placeholders_;
  // The indexes of the boxes that correspond to an inline placeholder.
  std::vector<size_t> inline_placeholder_boxes_;
  // The indexes of instances of 0xFFFC that correspond to placeholders. This is
  // necessary since the user may pass in manually entered 0xFFFC values using
  // AddText().
  std::unordered_set<size_t> obj_replacement_char_indexes_;
  StyledRuns runs_;
  ParagraphStyle paragraph_style_;
  std::shared_ptr<FontCollection> font_collection_;

  minikin::LineBreaker breaker_;
  mutable std::unique_ptr<icu::BreakIterator> word_breaker_;

  std::vector<LineMetrics> line_metrics_;
  size_t final_line_count_ = 0;
  std::vector<double> line_widths_;

  // Stores the result of Layout().
  std::vector<PaintRecord> records_;

  bool did_exceed_max_lines_;

  // Strut metrics of zero will have no effect on the layout.
  struct StrutMetrics {
    double ascent = 0;  // Positive value to keep signs clear.
    double descent = 0;
    double leading = 0;
    double half_leading = 0;
    double line_height = 0;
    bool force_strut = false;
  };

  StrutMetrics strut_;

  // Overall left and right extremes over all lines.
  double max_right_;
  double min_left_;

  class BidiRun {
   public:
    // Constructs a BidiRun with is_ghost defaulted to false.
    BidiRun(size_t s, size_t e, TextDirection d, const TextStyle& st)
        : start_(s), end_(e), direction_(d), style_(&st), is_ghost_(false) {}

    // Constructs a BidiRun with a custom is_ghost flag.
    BidiRun(size_t s,
            size_t e,
            TextDirection d,
            const TextStyle& st,
            bool is_ghost)
        : start_(s), end_(e), direction_(d), style_(&st), is_ghost_(is_ghost) {}

    // Constructs a placeholder bidi run.
    BidiRun(size_t s,
            size_t e,
            TextDirection d,
            const TextStyle& st,
            PlaceholderRun& placeholder)
        : start_(s),
          end_(e),
          direction_(d),
          style_(&st),
          is_ghost_(false),
          placeholder_run_(&placeholder) {}

    size_t start() const { return start_; }
    size_t end() const { return end_; }
    size_t size() const { return end_ - start_; }
    TextDirection direction() const { return direction_; }
    const TextStyle& style() const { return *style_; }
    PlaceholderRun* placeholder_run() const { return placeholder_run_; }
    bool is_rtl() const { return direction_ == TextDirection::rtl; }
    // Tracks if the run represents trailing whitespace.
    bool is_ghost() const { return is_ghost_; }
    bool is_placeholder_run() const { return placeholder_run_ != nullptr; }

   private:
    size_t start_, end_;
    TextDirection direction_;
    const TextStyle* style_;
    bool is_ghost_;
    PlaceholderRun* placeholder_run_ = nullptr;
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
    SkFontMetrics font_metrics;
    const TextStyle* style;
    TextDirection direction;
    const PlaceholderRun* placeholder_run;

    CodeUnitRun(std::vector<GlyphPosition>&& p,
                Range<size_t> cu,
                Range<double> x,
                size_t line,
                const SkFontMetrics& metrics,
                const TextStyle& st,
                TextDirection dir,
                const PlaceholderRun* placeholder);

    void Shift(double delta);
  };

  // Holds the laid out x positions of each glyph.
  std::vector<GlyphLine> glyph_lines_;

  // Holds the positions of each range of code units in the text.
  // Sorted in code unit index order.
  std::vector<CodeUnitRun> code_unit_runs_;
  // Holds the positions of the inline placeholders.
  std::vector<CodeUnitRun> inline_placeholder_code_unit_runs_;

  // The max width of the paragraph as provided in the most recent Layout()
  // call.
  double width_ = -1.0f;
  double longest_line_ = -1.0f;
  double max_intrinsic_width_ = 0;
  double min_intrinsic_width_ = 0;
  double alphabetic_baseline_ = std::numeric_limits<double>::max();
  double ideographic_baseline_ = std::numeric_limits<double>::max();

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

  void SetInlinePlaceholders(
      std::vector<PlaceholderRun> inline_placeholders,
      std::unordered_set<size_t> obj_replacement_char_indexes);

  // Break the text into lines.
  bool ComputeLineBreaks();

  // Break the text into runs based on LTR/RTL text direction.
  bool ComputeBidiRuns(std::vector<BidiRun>* result);

  // Calculates and populates strut based on paragraph_style_ strut info.
  void ComputeStrut(StrutMetrics* strut, SkFont& font);

  // Adjusts the ascent and descent based on the existence and type of
  // placeholder. This method sets the proper metrics to achieve the different
  // PlaceholderAlignment options.
  void ComputePlaceholder(PlaceholderRun* placeholder_run,
                          double& ascent,
                          double& descent);

  bool IsStrutValid() const;

  void UpdateLineMetrics(const SkFontMetrics& metrics,
                         const TextStyle& style,
                         double& max_ascent,
                         double& max_descent,
                         double& max_unscaled_ascent,
                         PlaceholderRun* placeholder_run,
                         size_t line_number,
                         size_t line_limit);

  // Calculate the starting X offset of a line based on the line's width and
  // alignment.
  double GetLineXOffset(double line_total_advance, bool justify_line);

  // Creates and draws the decorations onto the canvas.
  void PaintDecorations(SkCanvas* canvas,
                        const PaintRecord& record,
                        SkPoint base_offset);

  // Computes the beziers for a wavy decoration. The results will be
  // applied to path.
  void ComputeWavyDecoration(SkPath& path,
                             double x,
                             double y,
                             double width,
                             double thickness);

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

  FML_DISALLOW_COPY_AND_ASSIGN(ParagraphTxt);
};

}  // namespace txt

#endif  // LIB_TXT_SRC_PARAGRAPH_TXT_H_
