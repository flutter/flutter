/*
 * Copyright 2017 Google, Inc.
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

#include <cstring>
#include <iostream>

#include "flutter/fml/logging.h"
#include "render_test.h"
#include "third_party/icu/source/common/unicode/unistr.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkPath.h"
#include "txt/font_style.h"
#include "txt/font_weight.h"
#include "txt/paragraph_builder_txt.h"
#include "txt/paragraph_txt.h"
#include "txt/placeholder_run.h"
#include "txt_test_utils.h"

#define DISABLE_ON_WINDOWS(TEST) DISABLE_TEST_WINDOWS(TEST)
#define DISABLE_ON_MAC(TEST) DISABLE_TEST_MAC(TEST)

namespace txt {

using ParagraphTest = RenderTest;

TEST_F(ParagraphTest, SimpleParagraph) {
  const char* text = "Hello World Text Dialog";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  // We must supply a font here, as the default is Arial, and we do not
  // include Arial in our test fonts as it is proprietary. We want it to
  // be Arial default though as it is one of the most common fonts on host
  // platforms. On real devices/apps, Arial should be able to be resolved.
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, SimpleParagraphSmall) {
  const char* text =
      "Hello World Text Dialog. This is a very small text in order to check "
      "for constant advance additions that are only visible when the advance "
      "of the glyphs are small.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_size = 6;
  // We must supply a font here, as the default is Arial, and we do not
  // include Arial in our test fonts as it is proprietary. We want it to
  // be Arial default though as it is one of the most common fonts on host
  // platforms. On real devices/apps, Arial should be able to be resolved.
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

// It is possible for the line_metrics_ vector in paragraph to have an empty
// line at the end as a result of the line breaking algorithm. This causes
// the final_line_count_ to be one less than line metrics. This tests that we
// properly handle this case and do not segfault.
TEST_F(ParagraphTest, GetGlyphPositionAtCoordinateSegfault) {
  const char* text = "Hello World\nText Dialog";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  // We must supply a font here, as the default is Arial, and we do not
  // include Arial in our test fonts as it is proprietary. We want it to
  // be Arial default though as it is one of the most common fonts on host
  // platforms. On real devices/apps, Arial should be able to be resolved.
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->final_line_count_, paragraph->line_metrics_.size());
  ASSERT_EQ(paragraph->final_line_count_, 2ull);
  ASSERT_EQ(paragraph->GetLineCount(), 2ull);

  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(0.2, 0.2).position, 0ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(20.2, 0.2).position, 3ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(0.2, 20.2).position, 12ull);

  // We artificially reproduce the conditions that cause segfaults in very
  // specific circumstances in the wild. By adding this empty un-laid-out
  // LineMetrics at the end, we force the case where final_line_count_
  // represents the true number of lines whereas line_metrics_ has one
  // extra empty one.
  paragraph->line_metrics_.emplace_back(23, 24, 24, 24, true);

  ASSERT_EQ(paragraph->final_line_count_, paragraph->line_metrics_.size() - 1);
  ASSERT_EQ(paragraph->final_line_count_, 2ull);
  ASSERT_EQ(paragraph->GetLineCount(), 2ull);

  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(0.2, 20.2).position, 12ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(0.2, 0.2).position, 0ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(20.2, 0.2).position, 3ull);

  paragraph->line_metrics_.emplace_back(24, 25, 25, 25, true);

  ASSERT_EQ(paragraph->final_line_count_, paragraph->line_metrics_.size() - 2);
  ASSERT_EQ(paragraph->final_line_count_, 2ull);
  ASSERT_EQ(paragraph->GetLineCount(), 2ull);

  ASSERT_TRUE(Snapshot());
}

// Check that GetGlyphPositionAtCoordinate computes correct text positions for
// a paragraph containing multiple styled runs.
TEST_F(ParagraphTest, GetGlyphPositionAtCoordinateMultiRun) {
  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Ahem");
  text_style.color = SK_ColorBLACK;
  text_style.font_size = 10;
  builder.PushStyle(text_style);
  builder.AddText(u"A");
  text_style.font_size = 20;
  builder.PushStyle(text_style);
  builder.AddText(u"B");
  text_style.font_size = 30;
  builder.PushStyle(text_style);
  builder.AddText(u"C");

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(2.0, 5.0).position, 0ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(12.0, 5.0).position, 1ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(32.0, 5.0).position, 2ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, LineMetricsParagraph1) {
  const char* text = "Hello! What is going on?\nSecond line \nthirdline";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  // We must supply a font here, as the default is Arial, and we do not
  // include Arial in our test fonts as it is proprietary. We want it to
  // be Arial default though as it is one of the most common fonts on host
  // platforms. On real devices/apps, Arial should be able to be resolved.
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());

  ASSERT_EQ(paragraph->GetLineMetrics().size(), 3ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].start_index, 0ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].end_index, 24ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].end_including_newline, 25ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].end_excluding_whitespace, 24ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].hard_break, true);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].ascent, 12.988281);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].descent, 3.4179688);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].width, 149.72266);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].left, 0.0);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].baseline, 12.582031);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].line_number, 0ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].run_metrics.size(), 1ull);
  ASSERT_EQ(
      paragraph->GetLineMetrics()[0]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[0].start_index)
          ->second.text_style->color,
      SK_ColorBLACK);
  ASSERT_EQ(
      paragraph->GetLineMetrics()[0]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[0].start_index)
          ->second.text_style->font_families,
      std::vector<std::string>(1, "Roboto"));
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[0]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[0].start_index)
          ->second.font_metrics.fAscent,
      -12.988281);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[0]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[0].start_index)
          ->second.font_metrics.fDescent,
      3.4179688);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[0]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[0].start_index)
          ->second.font_metrics.fXHeight,
      7.3964844);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[0]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[0].start_index)
          ->second.font_metrics.fLeading,
      0);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[0]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[0].start_index)
          ->second.font_metrics.fTop,
      -14.786133);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[0]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[0].start_index)
          ->second.font_metrics.fUnderlinePosition,
      1.0253906);

  ASSERT_EQ(paragraph->GetLineMetrics()[1].start_index, 25ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].end_index, 37ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].end_including_newline, 38ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].end_excluding_whitespace, 36ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].hard_break, true);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].ascent, 12.988281);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].descent, 3.4179688);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].width, 72.0625);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].left, 0.0);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].baseline, 28.582031);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].line_number, 1ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].run_metrics.size(), 1ull);
  ASSERT_EQ(
      paragraph->GetLineMetrics()[1]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[1].start_index)
          ->second.text_style->color,
      SK_ColorBLACK);
  ASSERT_EQ(
      paragraph->GetLineMetrics()[1]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[1].start_index)
          ->second.text_style->font_families,
      std::vector<std::string>(1, "Roboto"));
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[1]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[1].start_index)
          ->second.font_metrics.fAscent,
      -12.988281);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[1]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[1].start_index)
          ->second.font_metrics.fDescent,
      3.4179688);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[1]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[1].start_index)
          ->second.font_metrics.fXHeight,
      7.3964844);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[1]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[1].start_index)
          ->second.font_metrics.fLeading,
      0);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[1]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[1].start_index)
          ->second.font_metrics.fTop,
      -14.786133);
  ASSERT_FLOAT_EQ(
      paragraph->GetLineMetrics()[1]
          .run_metrics.lower_bound(paragraph->GetLineMetrics()[1].start_index)
          ->second.font_metrics.fUnderlinePosition,
      1.0253906);
}

TEST_F(ParagraphTest, DISABLE_ON_MAC(LineMetricsParagraph2)) {
  const char* text = "test string alphabetic";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string alphabetic(icu_text.getBuffer(),
                            icu_text.getBuffer() + icu_text.length());

  const char* text2 = "测试中文日本語한국어";
  auto icu_text2 = icu::UnicodeString::fromUTF8(text2);
  std::u16string cjk(icu_text2.getBuffer(),
                     icu_text2.getBuffer() + icu_text2.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_families.push_back("Noto Sans CJK JP");
  text_style.font_size = 27;
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(alphabetic);

  text_style.font_size = 24;
  builder.PushStyle(text_style);
  builder.AddText(cjk);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(350);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());

  ASSERT_EQ(paragraph->GetLineMetrics().size(), 2ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].start_index, 0ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].end_index, 26ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].end_including_newline, 26ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].end_excluding_whitespace, 26ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].hard_break, false);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].ascent, 27.84);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].descent, 7.6799998);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].width, 348.61328);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].left, 0.0);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0].baseline, 28.32);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].line_number, 0ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[0].run_metrics.size(), 2ull);
  // First run
  ASSERT_EQ(paragraph->GetLineMetrics()[0]
                .run_metrics.lower_bound(2)
                ->second.text_style->font_size,
            27);
  ASSERT_EQ(paragraph->GetLineMetrics()[0]
                .run_metrics.lower_bound(2)
                ->second.text_style->font_families,
            text_style.font_families);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0]
                      .run_metrics.lower_bound(2)
                      ->second.font_metrics.fAscent,
                  -25.048828);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0]
                      .run_metrics.lower_bound(2)
                      ->second.font_metrics.fDescent,
                  6.5917969);

  ASSERT_EQ(paragraph->GetLineMetrics()[0]
                .run_metrics.lower_bound(21)
                ->second.text_style->font_size,
            27);
  ASSERT_EQ(paragraph->GetLineMetrics()[0]
                .run_metrics.lower_bound(21)
                ->second.text_style->font_families,
            text_style.font_families);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0]
                      .run_metrics.lower_bound(21)
                      ->second.font_metrics.fAscent,
                  -25.048828);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0]
                      .run_metrics.lower_bound(21)
                      ->second.font_metrics.fDescent,
                  6.5917969);

  // Second run
  ASSERT_EQ(paragraph->GetLineMetrics()[0]
                .run_metrics.lower_bound(22)
                ->second.text_style->font_size,
            24);
  ASSERT_EQ(paragraph->GetLineMetrics()[0]
                .run_metrics.lower_bound(22)
                ->second.text_style->font_families,
            text_style.font_families);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0]
                      .run_metrics.lower_bound(22)
                      ->second.font_metrics.fAscent,
                  -27.84);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0]
                      .run_metrics.lower_bound(22)
                      ->second.font_metrics.fDescent,
                  7.6799998);

  ASSERT_EQ(paragraph->GetLineMetrics()[0]
                .run_metrics.lower_bound(24)
                ->second.text_style->font_size,
            24);
  ASSERT_EQ(paragraph->GetLineMetrics()[0]
                .run_metrics.lower_bound(24)
                ->second.text_style->font_families,
            text_style.font_families);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0]
                      .run_metrics.lower_bound(24)
                      ->second.font_metrics.fAscent,
                  -27.84);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[0]
                      .run_metrics.lower_bound(24)
                      ->second.font_metrics.fDescent,
                  7.6799998);

  ASSERT_EQ(paragraph->GetLineMetrics()[1].start_index, 26ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].end_index, 32ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].end_including_newline, 32ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].end_excluding_whitespace, 32ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].hard_break, true);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].ascent, 27.84);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].descent, 7.6799998);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].width, 138.23438);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].left, 0.0);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1].baseline, 64.32);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].line_number, 1ull);
  ASSERT_EQ(paragraph->GetLineMetrics()[1].run_metrics.size(), 1ull);
  // Indexing below the line will just resolve to the first run in the line.
  ASSERT_EQ(paragraph->GetLineMetrics()[1]
                .run_metrics.lower_bound(3)
                ->second.text_style->font_size,
            24);
  ASSERT_EQ(paragraph->GetLineMetrics()[1]
                .run_metrics.lower_bound(3)
                ->second.text_style->font_families,
            text_style.font_families);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1]
                      .run_metrics.lower_bound(3)
                      ->second.font_metrics.fAscent,
                  -27.84);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1]
                      .run_metrics.lower_bound(3)
                      ->second.font_metrics.fDescent,
                  7.6799998);

  // Indexing within the line
  ASSERT_EQ(paragraph->GetLineMetrics()[1]
                .run_metrics.lower_bound(31)
                ->second.text_style->font_size,
            24);
  ASSERT_EQ(paragraph->GetLineMetrics()[1]
                .run_metrics.lower_bound(31)
                ->second.text_style->font_families,
            text_style.font_families);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1]
                      .run_metrics.lower_bound(31)
                      ->second.font_metrics.fAscent,
                  -27.84);
  ASSERT_FLOAT_EQ(paragraph->GetLineMetrics()[1]
                      .run_metrics.lower_bound(31)
                      ->second.font_metrics.fDescent,
                  7.6799998);
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholderParagraph)) {
  const char* text = "012 34";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(50, 50, PlaceholderAlignment::kBaseline,
                                      TextBaseline::kAlphabetic, 0);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.AddPlaceholder(placeholder_run);
  txt::PlaceholderRun placeholder_run2(5, 50, PlaceholderAlignment::kBaseline,
                                       TextBaseline::kAlphabetic, 50);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddText(u16_text);
  builder.AddPlaceholder(placeholder_run2);

  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddText(u16_text);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 3, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  // ASSERT_TRUE(Snapshot());
  EXPECT_EQ(boxes.size(), 1ull);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);

  paint.setColor(SK_ColorRED);
  boxes = paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(4, 17, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 7ull);
  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[1].rect.top(), 50);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 140.94531);
  EXPECT_FLOAT_EQ(boxes[1].rect.bottom(), 100);

  EXPECT_FLOAT_EQ(boxes[3].rect.left(), 231.39062);
  EXPECT_FLOAT_EQ(boxes[3].rect.top(), 50);
  EXPECT_FLOAT_EQ(boxes[3].rect.right(), 231.39062 + 50);
  EXPECT_FLOAT_EQ(boxes[3].rect.bottom(), 100);

  EXPECT_FLOAT_EQ(boxes[4].rect.left(), 281.39062);
  EXPECT_FLOAT_EQ(boxes[4].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[4].rect.right(), 281.39062 + 5);
  EXPECT_FLOAT_EQ(boxes[4].rect.bottom(), 50);

  EXPECT_FLOAT_EQ(boxes[6].rect.left(), 336.39062);
  EXPECT_FLOAT_EQ(boxes[6].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[6].rect.right(), 336.39062 + 5);
  EXPECT_FLOAT_EQ(boxes[6].rect.bottom(), 50);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholderBaselineParagraph)) {
  const char* text = "012 34";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(55, 50, PlaceholderAlignment::kBaseline,
                                      TextBaseline::kAlphabetic, 38.34734);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the box is in the right place
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 145.94531);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 50);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(5, 6, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the other text didn't just shift to accommodate it.
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 75.34375);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 14.226246);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 44.694996);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       DISABLE_ON_WINDOWS(InlinePlaceholderAboveBaselineParagraph)) {
  const char* text = "012 34";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(55, 50,
                                      PlaceholderAlignment::kAboveBaseline,
                                      TextBaseline::kAlphabetic, 903129.129308);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the box is in the right place
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), -0.34765625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 145.94531);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 49.652344);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(5, 6, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the other text didn't just shift to accommodate it.
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 75.34375);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 25.53125);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 56);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       DISABLE_ON_WINDOWS(InlinePlaceholderBelowBaselineParagraph)) {
  const char* text = "012 34";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(55, 50,
                                      PlaceholderAlignment::kBelowBaseline,
                                      TextBaseline::kAlphabetic, 903129.129308);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the box is in the right place
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 24);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 145.94531);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 74);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(5, 6, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the other text didn't just shift to accommodate it.
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 75.34375);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), -0.12109375);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 30.347656);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholderBottomParagraph)) {
  const char* text = "012 34";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(55, 50, PlaceholderAlignment::kBottom,
                                      TextBaseline::kAlphabetic, 0);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the box is in the right place
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 145.94531);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 50);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the other text didn't just shift to accommodate it.
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0.5);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 19.53125);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 16.101562);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 50);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholderTopParagraph)) {
  const char* text = "012 34";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(55, 50, PlaceholderAlignment::kTop,
                                      TextBaseline::kAlphabetic, 0);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the box is in the right place
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 145.94531);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 50);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the other text didn't just shift to accommodate it.
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0.5);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 16.101562);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 30.46875);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholderMiddleParagraph)) {
  const char* text = "012 34";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(55, 50, PlaceholderAlignment::kMiddle,
                                      TextBaseline::kAlphabetic, 0);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the box is in the right place
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 145.94531);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 50);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(5, 6, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the other text didn't just shift to accommodate it.
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 75.34375);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 9.765625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 40.234375);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       DISABLE_ON_MAC(
           DISABLE_ON_WINDOWS(InlinePlaceholderIdeographicBaselineParagraph))) {
  const char* text = "給能上目秘使";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Source Han Serif CN");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(55, 50, PlaceholderAlignment::kBaseline,
                                      TextBaseline::kIdeographic, 38.34734);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the box is in the right place
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 162.5);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 217.5);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 50);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(5, 6, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  // Verify the other text didn't just shift to accommodate it.
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 135.5);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 4.7033391);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 162.5);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 42.065342);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholderBreakParagraph)) {
  const char* text = "012 34";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(50, 50, PlaceholderAlignment::kBaseline,
                                      TextBaseline::kAlphabetic, 50);
  txt::PlaceholderRun placeholder_run2(25, 25, PlaceholderAlignment::kBaseline,
                                       TextBaseline::kAlphabetic, 12.5);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddText(u16_text);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);

  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddText(u16_text);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 3, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);

  paint.setColor(SK_ColorGREEN);
  boxes = paragraph->GetRectsForRange(175, 176, rect_height_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 31.703125);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 218.53125);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 47.304688);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 249);

  paint.setColor(SK_ColorRED);
  boxes = paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(4, 45, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 30ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 59.742188);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 26.378906);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 56.847656);

  EXPECT_FLOAT_EQ(boxes[11].rect.left(), 606.39062);
  EXPECT_FLOAT_EQ(boxes[11].rect.top(), 38);
  EXPECT_FLOAT_EQ(boxes[11].rect.right(), 631.39062);
  EXPECT_FLOAT_EQ(boxes[11].rect.bottom(), 63);

  EXPECT_FLOAT_EQ(boxes[17].rect.left(), 0.5);
  EXPECT_FLOAT_EQ(boxes[17].rect.top(), 63.5);
  EXPECT_FLOAT_EQ(boxes[17].rect.right(), 50.5);
  EXPECT_FLOAT_EQ(boxes[17].rect.bottom(), 113.5);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholderGetRectsParagraph)) {
  const char* text = "012 34";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  txt::PlaceholderRun placeholder_run(50, 50, PlaceholderAlignment::kBaseline,
                                      TextBaseline::kAlphabetic, 50);
  txt::PlaceholderRun placeholder_run2(5, 20, PlaceholderAlignment::kBaseline,
                                       TextBaseline::kAlphabetic, 10);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run);

  builder.AddText(u16_text);

  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run2);

  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddText(u16_text);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddPlaceholder(placeholder_run);
  builder.AddPlaceholder(placeholder_run2);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 34ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 90.945312);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 140.94531);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 50);

  EXPECT_FLOAT_EQ(boxes[16].rect.left(), 800.94531);
  EXPECT_FLOAT_EQ(boxes[16].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[16].rect.right(), 850.94531);
  EXPECT_FLOAT_EQ(boxes[16].rect.bottom(), 50);

  EXPECT_FLOAT_EQ(boxes[33].rect.left(), 503.48438);
  EXPECT_FLOAT_EQ(boxes[33].rect.top(), 160);
  EXPECT_FLOAT_EQ(boxes[33].rect.right(), 508.48438);
  EXPECT_FLOAT_EQ(boxes[33].rect.bottom(), 180);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(30, 50, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 8ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 216.10156);
  // Top should be taller than "tight"
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 60);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 290.94531);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 120);

  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 290.94531);
  EXPECT_FLOAT_EQ(boxes[1].rect.top(), 60);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 340.94531);
  EXPECT_FLOAT_EQ(boxes[1].rect.bottom(), 120);

  EXPECT_FLOAT_EQ(boxes[2].rect.left(), 340.94531);
  EXPECT_FLOAT_EQ(boxes[2].rect.top(), 60);
  EXPECT_FLOAT_EQ(boxes[2].rect.right(), 345.94531);
  EXPECT_FLOAT_EQ(boxes[2].rect.bottom(), 120);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholderLongestLine)) {
  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 1;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  txt::PlaceholderRun placeholder_run(50, 50, PlaceholderAlignment::kBaseline,
                                      TextBaseline::kAlphabetic, 0);
  builder.AddPlaceholder(placeholder_run);
  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  ASSERT_DOUBLE_EQ(paragraph->width_, GetTestCanvasWidth());
  ASSERT_TRUE(paragraph->longest_line_ < GetTestCanvasWidth());
  ASSERT_TRUE(paragraph->longest_line_ >= 50);
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholderIntrinsicWidth)) {
  const char* text = "A ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::PlaceholderRun placeholder_run(50, 50, PlaceholderAlignment::kBaseline,
                                      TextBaseline::kAlphabetic, 0);

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 20;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);
  builder.AddPlaceholder(placeholder_run);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  ASSERT_DOUBLE_EQ(paragraph->GetMinIntrinsicWidth(), 50);
  ASSERT_DOUBLE_EQ(paragraph->GetMaxIntrinsicWidth(), 68);
}

#if OS_LINUX
// Tests if manually inserted 0xFFFC characters are replaced to 0xFFFD in order
// to not interfere with the placeholder box layout.
TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(InlinePlaceholder0xFFFCParagraph)) {
  const char* text = "ab\uFFFCcd";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  // Used to generate the replaced version.
  const char* text2 = "ab\uFFFDcd";
  auto icu_text2 = icu::UnicodeString::fromUTF8(text2);
  std::u16string u16_text2(icu_text2.getBuffer(),
                           icu_text2.getBuffer() + icu_text2.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  std::vector<uint16_t> truth_text;

  builder.AddText(u16_text);
  truth_text.insert(truth_text.end(), u16_text2.begin(), u16_text2.end());
  builder.AddText(u16_text);
  truth_text.insert(truth_text.end(), u16_text2.begin(), u16_text2.end());

  txt::PlaceholderRun placeholder_run(50, 50, PlaceholderAlignment::kBaseline,
                                      TextBaseline::kAlphabetic, 25);
  builder.AddPlaceholder(placeholder_run);
  truth_text.push_back(0xFFFC);

  builder.AddText(u16_text);
  truth_text.insert(truth_text.end(), u16_text2.begin(), u16_text2.end());
  builder.AddText(u16_text);
  truth_text.insert(truth_text.end(), u16_text2.begin(), u16_text2.end());

  builder.AddPlaceholder(placeholder_run);
  truth_text.push_back(0xFFFC);
  builder.AddPlaceholder(placeholder_run);
  truth_text.push_back(0xFFFC);
  builder.AddText(u16_text);
  truth_text.insert(truth_text.end(), u16_text2.begin(), u16_text2.end());
  builder.AddText(u16_text);
  truth_text.insert(truth_text.end(), u16_text2.begin(), u16_text2.end());
  builder.AddPlaceholder(placeholder_run);
  truth_text.push_back(0xFFFC);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  for (size_t i = 0; i < truth_text.size(); ++i) {
    EXPECT_EQ(paragraph->text_[i], truth_text[i]);
  }

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  paint.setColor(SK_ColorRED);

  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForPlaceholders();
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 4ull);

  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 177.83594);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 227.83594);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 50);

  EXPECT_FLOAT_EQ(boxes[3].rect.left(), 682.50781);
  EXPECT_FLOAT_EQ(boxes[3].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[3].rect.right(), 732.50781);
  EXPECT_FLOAT_EQ(boxes[3].rect.bottom(), 50);

  ASSERT_TRUE(Snapshot());
}
#endif

TEST_F(ParagraphTest, SimpleRedParagraph) {
  const char* text = "I am RED";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorRED;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, RainbowParagraph) {
  const char* text1 = "Red Roboto";
  auto icu_text1 = icu::UnicodeString::fromUTF8(text1);
  std::u16string u16_text1(icu_text1.getBuffer(),
                           icu_text1.getBuffer() + icu_text1.length());
  const char* text2 = "big Greeen Default";
  auto icu_text2 = icu::UnicodeString::fromUTF8(text2);
  std::u16string u16_text2(icu_text2.getBuffer(),
                           icu_text2.getBuffer() + icu_text2.length());
  const char* text3 = "Defcolor Homemade Apple";
  auto icu_text3 = icu::UnicodeString::fromUTF8(text3);
  std::u16string u16_text3(icu_text3.getBuffer(),
                           icu_text3.getBuffer() + icu_text3.length());
  const char* text4 = "Small Blue Roboto";
  auto icu_text4 = icu::UnicodeString::fromUTF8(text4);
  std::u16string u16_text4(icu_text4.getBuffer(),
                           icu_text4.getBuffer() + icu_text4.length());
  const char* text5 =
      "Continue Last Style With lots of words to check if it overlaps "
      "properly or not";
  auto icu_text5 = icu::UnicodeString::fromUTF8(text5);
  std::u16string u16_text5(icu_text5.getBuffer(),
                           icu_text5.getBuffer() + icu_text5.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 2;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style1;
  text_style1.font_families = std::vector<std::string>(1, "Roboto");
  text_style1.color = SK_ColorRED;

  builder.PushStyle(text_style1);

  builder.AddText(u16_text1);

  txt::TextStyle text_style2;
  text_style2.font_size = 50;
  text_style2.letter_spacing = 10;
  text_style2.word_spacing = 30;
  text_style2.font_weight = txt::FontWeight::w600;
  text_style2.color = SK_ColorGREEN;
  text_style2.font_families = std::vector<std::string>(1, "Roboto");
  text_style2.decoration = TextDecoration::kUnderline |
                           TextDecoration::kOverline |
                           TextDecoration::kLineThrough;
  text_style2.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style2);

  builder.AddText(u16_text2);

  txt::TextStyle text_style3;
  text_style3.font_families = std::vector<std::string>(1, "Homemade Apple");
  builder.PushStyle(text_style3);

  builder.AddText(u16_text3);

  txt::TextStyle text_style4;
  text_style4.font_size = 14;
  text_style4.color = SK_ColorBLUE;
  text_style4.font_families = std::vector<std::string>(1, "Roboto");
  text_style4.decoration = TextDecoration::kUnderline |
                           TextDecoration::kOverline |
                           TextDecoration::kLineThrough;
  text_style4.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style4);

  builder.AddText(u16_text4);

  // Extra text to see if it goes to default when there is more text chunks than
  // styles.
  builder.AddText(u16_text5);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());
  paragraph->Paint(GetCanvas(), 0, 0);

  u16_text1 += u16_text2 + u16_text3 + u16_text4;
  for (size_t i = 0; i < u16_text1.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text1[i]);
  }
  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->runs_.runs_.size(), 4ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 5ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style1));
  ASSERT_TRUE(paragraph->runs_.styles_[2].equals(text_style2));
  ASSERT_TRUE(paragraph->runs_.styles_[3].equals(text_style3));
  ASSERT_TRUE(paragraph->runs_.styles_[4].equals(text_style4));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style1.color);
  ASSERT_EQ(paragraph->records_[1].style().color, text_style2.color);
  ASSERT_EQ(paragraph->records_[2].style().color, text_style3.color);
  ASSERT_EQ(paragraph->records_[3].style().color, text_style4.color);
}

// Currently, this should render nothing without a supplied TextStyle.
TEST_F(ParagraphTest, DefaultStyleParagraph) {
  const char* text = "No TextStyle! Uh Oh!";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 1ull);
  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, BoldParagraph) {
  const char* text = "This is Red max bold text!";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 60;
  text_style.letter_spacing = 0;
  text_style.font_weight = txt::FontWeight::w900;
  text_style.color = SK_ColorRED;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 10.0, 60.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());

  // width_ takes the full available space, but longest_line_ is only the width
  // of the text, which is less than one line.
  ASSERT_DOUBLE_EQ(paragraph->width_, GetTestCanvasWidth());
  ASSERT_TRUE(paragraph->longest_line_ < paragraph->width_);
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  std::vector<txt::Paragraph::TextBox> boxes = paragraph->GetRectsForRange(
      0, strlen(text), rect_height_style, rect_width_style);
  ASSERT_DOUBLE_EQ(paragraph->longest_line_,
                   boxes[boxes.size() - 1].rect.right() - boxes[0].rect.left());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(HeightOverrideParagraph)) {
  const char* text = "01234満毎冠行来昼本可\nabcd\n満毎冠行来昼本可";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 20;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 3.6345;
  text_style.has_height_override = true;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kIncludeLineSpacingMiddle;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 40, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 3ull);
  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 0);
  EXPECT_NEAR(boxes[1].rect.top(), 92.805778503417969, 0.0001);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 43.851562);
  EXPECT_NEAR(boxes[1].rect.bottom(), 165.49578857421875, 0.0001);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(HeightOverrideHalfLeadingTextStyle)) {
  // All 3 lines will have the same typeface.
  const char* text = "01234満毎冠行来昼本可\nabcd\n満毎冠行来昼本可";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_height_behavior = TextHeightBehavior::kAll;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 20;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 3.6345;
  text_style.has_height_override = true;
  // Override paragraph_style.text_height_behavior:
  text_style.half_leading = true;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_style_max =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);

  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 40, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }

  std::vector<txt::Paragraph::TextBox> line_boxes = paragraph->GetRectsForRange(
      0, 40, rect_height_style_max, rect_width_style);
  EXPECT_EQ(boxes.size(), 3ull);
  EXPECT_EQ(line_boxes.size(), 3ull);

  const double line_spacing1 = boxes[1].rect.top() - boxes[0].rect.bottom();
  const double line_spacing2 = boxes[2].rect.top() - boxes[1].rect.bottom();

  EXPECT_EQ(line_spacing1, line_spacing2);

  // half leading.
  EXPECT_EQ(line_boxes[0].rect.top() - boxes[0].rect.top(),
            boxes[0].rect.bottom() - line_boxes[0].rect.bottom());
  EXPECT_EQ(line_boxes[1].rect.top() - boxes[1].rect.top(),
            boxes[1].rect.bottom() - line_boxes[1].rect.bottom());
  EXPECT_EQ(line_boxes[2].rect.top() - boxes[2].rect.top(),
            boxes[2].rect.bottom() - line_boxes[2].rect.bottom());
  // With half-leadding, the x coordinates should remain the same.
  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 43.851562);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(MixedTextHeightBehaviorSameLine)) {
  // Both runs will still have the same typeface, but with different text height
  // behaviors.
  const char* text = "01234満毎冠行来昼本可abcd";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  std::u16string u16_text2(icu_text.getBuffer(),
                           icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_height_behavior = TextHeightBehavior::kAll;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 20;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 3.6345;
  text_style.has_height_override = true;
  // First run, with half-leading.
  text_style.half_leading = true;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  // Second run with AD-scaling.
  text_style.half_leading = false;

  builder.PushStyle(text_style);
  builder.AddText(u16_text2);
  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);
  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_style_max =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);

  std::vector<txt::Paragraph::TextBox> boxes = paragraph->GetRectsForRange(
      0, icu_text.length(), rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }

  std::vector<txt::Paragraph::TextBox> line_boxes = paragraph->GetRectsForRange(
      0, icu_text.length(), rect_height_style_max, rect_width_style);
  // The runs has the same typeface so they should be grouped together.
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_EQ(line_boxes.size(), 1ull);

  const double glyphHeight = boxes[0].rect.height();
  const double metricsAscent = 18.5546875;
  const double metricsDescent = 4.8828125;
  EXPECT_DOUBLE_EQ(glyphHeight, metricsAscent + metricsDescent);

  const double line_height = 3.6345 * 20;
  const double leading = line_height - glyphHeight;

  // Overall descent is from half-leading and overall ascent is from AD-scaling.
  EXPECT_NEAR(boxes[0].rect.top() - line_boxes[0].rect.top(),
              leading * metricsAscent / (metricsAscent + metricsDescent),
              0.001);

  EXPECT_NEAR(line_boxes[0].rect.bottom() - boxes[0].rect.bottom(),
              leading * 0.5, 0.001);
}

TEST_F(ParagraphTest,
       DISABLE_ON_WINDOWS(MixedTextHeightBehaviorSameLineWithZeroHeight)) {
  // Both runs will still have the same typeface, but with different text height
  // behaviors.
  const char* text = "01234満毎冠行来昼本可abcd";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_height_behavior = TextHeightBehavior::kAll;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 20;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  // Set height to 0
  text_style.height = 0;
  text_style.has_height_override = true;
  // First run, with half-leading.
  text_style.half_leading = true;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  // Second run with AD-scaling.
  text_style.half_leading = false;

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);
  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_style_max =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);

  std::vector<txt::Paragraph::TextBox> boxes = paragraph->GetRectsForRange(
      0, icu_text.length(), rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }

  std::vector<txt::Paragraph::TextBox> line_boxes = paragraph->GetRectsForRange(
      0, icu_text.length(), rect_height_style_max, rect_width_style);
  // The runs has the same typeface so they should be grouped together.
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_EQ(line_boxes.size(), 1ull);

  const double glyphHeight = boxes[0].rect.height();
  const double metricsAscent = 18.5546875;
  const double metricsDescent = 4.8828125;
  EXPECT_DOUBLE_EQ(glyphHeight, metricsAscent + metricsDescent);

  // line_height for both styled runs is 0, but the overall line height is not
  // 0.
  EXPECT_DOUBLE_EQ(line_boxes[0].rect.height(),
                   metricsAscent - (metricsAscent + metricsDescent) / 2);
  EXPECT_LT(boxes[0].rect.top(), 0.0);
  EXPECT_GT(boxes[0].rect.bottom(), 0.0);
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(HeightOverrideHalfLeadingStrut)) {
  // All 3 lines will have the same typeface.
  const char* text = "01234満毎冠行来昼本可\nabcd\n満毎冠行来昼本可";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.strut_enabled = true;
  paragraph_style.strut_has_height_override = true;
  paragraph_style.strut_height = 3.6345;
  paragraph_style.strut_font_size = 20;
  paragraph_style.strut_font_families.push_back("Roboto");
  paragraph_style.strut_half_leading = true;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 20;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 3.6345;
  text_style.has_height_override = true;
  text_style.half_leading = true;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_style_max =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);

  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 40, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }

  std::vector<txt::Paragraph::TextBox> line_boxes = paragraph->GetRectsForRange(
      0, 40, rect_height_style_max, rect_width_style);
  EXPECT_EQ(boxes.size(), 3ull);
  EXPECT_EQ(line_boxes.size(), 3ull);

  const double line_spacing1 = boxes[1].rect.top() - boxes[0].rect.bottom();
  const double line_spacing2 = boxes[2].rect.top() - boxes[1].rect.bottom();

  EXPECT_EQ(line_spacing1, line_spacing2);

  // Strut half leading.
  EXPECT_EQ(line_boxes[0].rect.top() - boxes[0].rect.top(),
            boxes[0].rect.bottom() - line_boxes[0].rect.bottom());
  EXPECT_EQ(line_boxes[1].rect.top() - boxes[1].rect.top(),
            boxes[1].rect.bottom() - line_boxes[1].rect.bottom());
  EXPECT_EQ(line_boxes[2].rect.top() - boxes[2].rect.top(),
            boxes[2].rect.bottom() - line_boxes[2].rect.bottom());

  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 43.851562);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       DISABLE_ON_WINDOWS(ZeroHeightHalfLeadingStrutForceHeight)) {
  // All 3 lines will have the same typeface.
  const char* text = "01234満毎冠行来昼本可abcdn満毎冠行来昼本可";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.strut_enabled = true;
  paragraph_style.strut_has_height_override = true;
  paragraph_style.strut_height = 0;
  // Force strut height.
  paragraph_style.force_strut_height = true;
  paragraph_style.strut_font_size = 20;
  paragraph_style.strut_font_families.push_back("Roboto");
  paragraph_style.strut_half_leading = true;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 20;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 0;
  text_style.has_height_override = true;

  // First run, with half-leading.
  text_style.half_leading = true;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  // Second run with AD-scaling.
  text_style.half_leading = false;

  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_style_max =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);

  std::vector<txt::Paragraph::TextBox> boxes = paragraph->GetRectsForRange(
      0, icu_text.length(), rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }

  std::vector<txt::Paragraph::TextBox> line_boxes = paragraph->GetRectsForRange(
      0, icu_text.length(), rect_height_style_max, rect_width_style);
  // The runs has the same typeface so they should be grouped together.
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_EQ(line_boxes.size(), 1ull);

  const double glyphHeight = boxes[0].rect.height();
  const double metricsAscent = 18.5546875;
  const double metricsDescent = 4.8828125;
  EXPECT_DOUBLE_EQ(glyphHeight, metricsAscent + metricsDescent);

  EXPECT_DOUBLE_EQ(line_boxes[0].rect.height(), 0.0);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(LeftAlignParagraph)) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are necessary. Very short. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_.size(), paragraph_style.max_lines);
  double expected_y = 24;

  ASSERT_TRUE(paragraph->records_[0].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[0].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_DOUBLE_EQ(paragraph->records_[0].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[1].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[1].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_DOUBLE_EQ(paragraph->records_[1].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[2].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[3].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[3].offset().y(), expected_y);
  expected_y += 30 * 10;
  ASSERT_DOUBLE_EQ(paragraph->records_[3].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[13].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[13].offset().y(), expected_y);
  ASSERT_DOUBLE_EQ(paragraph->records_[13].offset().x(), 0);

  ASSERT_EQ(paragraph_style.text_align,
            paragraph->GetParagraphStyle().text_align);

  // Tests for GetGlyphPositionAtCoordinate()
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(0, 0).position, 0ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(1, 1).position, 0ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(1, 35).position, 68ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(1, 70).position, 134ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(2000, 35).position, 134ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(LeftAlignRTLParagraphHitTest)) {
  // Regression test for https://github.com/flutter/flutter/issues/54969.
  const char* text = "بمباركة التقليدية قام عن. تصفح";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 1;
  paragraph_style.text_align = TextAlign::left;
  paragraph_style.text_direction = TextDirection::rtl;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());

  // Tests for GetGlyphPositionAtCoordinate()
  ASSERT_EQ(
      paragraph->GetGlyphPositionAtCoordinate(GetTestCanvasWidth() - 0.5, 0.5)
          .position,
      0ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(RightAlignParagraph)) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are necessary. Very short. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::right;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  int available_width = GetTestCanvasWidth() - 100;
  paragraph->Layout(available_width);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  // Two records for each due to 'ghost' trailing whitespace run.
  ASSERT_EQ(paragraph->records_.size(), paragraph_style.max_lines * 2);
  double expected_y = 24;

  ASSERT_TRUE(paragraph->records_[0].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[0].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(paragraph->records_[0].offset().x(),
              paragraph->width_ -
                  paragraph->line_widths_[paragraph->records_[0].line()],
              2.0);

  // width_ takes the full available space, while longest_line_ wraps the glyphs
  // as tightly as possible. Even though this text is more than one line long,
  // no line perfectly spans the width of the full line, so longest_line_ is
  // less than width_.
  ASSERT_DOUBLE_EQ(paragraph->width_, available_width);
  ASSERT_TRUE(paragraph->longest_line_ < available_width);
  ASSERT_DOUBLE_EQ(paragraph->longest_line_, 880.87109375);

  ASSERT_TRUE(paragraph->records_[2].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(paragraph->records_[2].offset().x(),
              paragraph->width_ -
                  paragraph->line_widths_[paragraph->records_[2].line()],
              2.0);

  ASSERT_TRUE(paragraph->records_[4].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[4].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(paragraph->records_[4].offset().x(),
              paragraph->width_ -
                  paragraph->line_widths_[paragraph->records_[4].line()],
              2.0);

  ASSERT_TRUE(paragraph->records_[6].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[6].offset().y(), expected_y);
  expected_y += 30 * 10;
  ASSERT_NEAR(paragraph->records_[6].offset().x(),
              paragraph->width_ -
                  paragraph->line_widths_[paragraph->records_[6].line()],
              2.0);

  ASSERT_TRUE(paragraph->records_[26].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[26].offset().y(), expected_y);
  ASSERT_NEAR(paragraph->records_[26].offset().x(),
              paragraph->width_ -
                  paragraph->line_widths_[paragraph->records_[26].line()],
              2.0);

  ASSERT_EQ(paragraph_style.text_align,
            paragraph->GetParagraphStyle().text_align);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(CenterAlignParagraph)) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are necessary. Very short. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::center;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  // Two records for each due to 'ghost' trailing whitespace run.
  ASSERT_EQ(paragraph->records_.size(), paragraph_style.max_lines * 2);
  double expected_y = 24;

  ASSERT_TRUE(paragraph->records_[0].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[0].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(paragraph->records_[0].offset().x(),
              (paragraph->width_ -
               paragraph->line_widths_[paragraph->records_[0].line()]) /
                  2,
              2.0);

  ASSERT_TRUE(paragraph->records_[2].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(paragraph->records_[2].offset().x(),
              (paragraph->width_ -
               paragraph->line_widths_[paragraph->records_[2].line()]) /
                  2,
              2.0);

  ASSERT_TRUE(paragraph->records_[4].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[4].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(paragraph->records_[4].offset().x(),
              (paragraph->width_ -
               paragraph->line_widths_[paragraph->records_[4].line()]) /
                  2,
              2.0);

  ASSERT_TRUE(paragraph->records_[6].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[6].offset().y(), expected_y);
  expected_y += 30 * 10;
  ASSERT_NEAR(paragraph->records_[6].offset().x(),
              (paragraph->width_ -
               paragraph->line_widths_[paragraph->records_[6].line()]) /
                  2,
              2.0);

  ASSERT_TRUE(paragraph->records_[26].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[26].offset().y(), expected_y);
  ASSERT_NEAR(paragraph->records_[26].offset().x(),
              (paragraph->width_ -
               paragraph->line_widths_[paragraph->records_[26].line()]) /
                  2,
              2.0);

  ASSERT_EQ(paragraph_style.text_align,
            paragraph->GetParagraphStyle().text_align);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(JustifyAlignParagraph)) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are necessary. Very short. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint "
      "occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
      "mollit anim id est laborum. "
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod "
      "tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
      "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea "
      "commodo consequat. Duis aute irure dolor in reprehenderit in voluptate "
      "velit esse cillum dolore eu fugiat.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::justify;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_.size(), 27ull);
  double expected_y = 24;

  ASSERT_TRUE(paragraph->records_[0].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[0].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_DOUBLE_EQ(paragraph->records_[0].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[2].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[4].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[4].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_DOUBLE_EQ(paragraph->records_[4].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[6].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[6].offset().y(), expected_y);
  expected_y += 30 * 10;
  ASSERT_DOUBLE_EQ(paragraph->records_[6].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[26].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[26].offset().y(), expected_y);
  ASSERT_DOUBLE_EQ(paragraph->records_[26].offset().x(), 0);

  ASSERT_EQ(paragraph_style.text_align,
            paragraph->GetParagraphStyle().text_align);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(JustifyRTL)) {
  const char* text =
      "אאא בּבּבּבּ אאאא בּבּ אאא בּבּבּ אאאאא בּבּבּבּ אאאא בּבּבּבּבּ "
      "אאאאא בּבּבּבּבּ אאאבּבּבּבּבּבּאאאאא בּבּבּבּבּבּאאאאאבּבּבּבּבּבּ אאאאא בּבּבּבּבּ "
      "אאאאא בּבּבּבּבּבּ אאאאא בּבּבּבּבּבּ אאאאא בּבּבּבּבּבּ אאאאא בּבּבּבּבּבּ אאאאא בּבּבּבּבּבּ";

  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::justify;
  paragraph_style.text_direction = TextDirection::rtl;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Ahem");
  text_style.font_size = 26;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  size_t paragraph_width = GetTestCanvasWidth() - 100;
  paragraph->Layout(paragraph_width);

  paragraph->Paint(GetCanvas(), 0, 0);

  auto glyph_line_width = [&paragraph](int index) {
    size_t second_to_last_position_index =
        paragraph->glyph_lines_[index].positions.size() - 1;
    return paragraph->glyph_lines_[index]
        .positions[second_to_last_position_index]
        .x_pos.end;
  };

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 100, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  ASSERT_EQ(boxes.size(), 5ull);

  paint.setColor(SK_ColorBLUE);
  boxes = paragraph->GetRectsForRange(240, 250, rect_height_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  ASSERT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 588);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 130);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 640);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 156);
  ASSERT_TRUE(Snapshot());

  // All lines should be justified to the width of the
  // paragraph.
  for (size_t i = 0; i < paragraph->glyph_lines_.size(); ++i) {
    ASSERT_EQ(glyph_line_width(i), paragraph_width);
  }
}

TEST_F(ParagraphTest, LINUX_ONLY(JustifyRTLNewLine)) {
  const char* text =
      "אאא בּבּבּבּ אאאא\nבּבּ אאא בּבּבּ אאאאא בּבּבּבּ אאאא בּבּבּבּבּ "
      "אאאאא בּבּבּבּבּ אאאבּבּבּבּבּבּאאאאא בּבּבּבּבּבּאאאאאבּבּבּבּבּבּ אאאאא בּבּבּבּבּ "
      "אאאאא בּבּבּבּבּבּ אאאאא בּבּבּבּבּבּ אאאאא בּבּבּבּבּבּ אאאאא בּבּבּבּבּבּ אאאאא בּבּבּבּבּבּ";

  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::justify;
  paragraph_style.text_direction = TextDirection::rtl;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Ahem");
  text_style.font_size = 26;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  size_t paragraph_width = GetTestCanvasWidth() - 100;
  paragraph->Layout(paragraph_width);

  paragraph->Paint(GetCanvas(), 0, 0);

  auto glyph_line_width = [&paragraph](int index) {
    size_t second_to_last_position_index =
        paragraph->glyph_lines_[index].positions.size() - 1;
    return paragraph->glyph_lines_[index]
        .positions[second_to_last_position_index]
        .x_pos.end;
  };

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  ASSERT_TRUE(Snapshot());

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 30, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  ASSERT_EQ(boxes.size(), 2ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 562);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), -1.4305115e-06);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 900);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 26);

  paint.setColor(SK_ColorBLUE);
  boxes = paragraph->GetRectsForRange(240, 250, rect_height_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  ASSERT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 68);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 130);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 120);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 156);
  ASSERT_TRUE(Snapshot());

  // All lines should be justified to the width of the
  // paragraph.
  for (size_t i = 0; i < paragraph->glyph_lines_.size(); ++i) {
    ASSERT_EQ(glyph_line_width(i), paragraph_width);
  }
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(JustifyPlaceholder)) {
  const char* text1 = "A ";
  auto icu_text1 = icu::UnicodeString::fromUTF8(text1);
  std::u16string u16_text1(icu_text1.getBuffer(),
                           icu_text1.getBuffer() + icu_text1.length());

  txt::PlaceholderRun placeholder_run(60, 60, PlaceholderAlignment::kBaseline,
                                      TextBaseline::kAlphabetic, 0);

  const char* text2 = " B CCCCC";
  auto icu_text2 = icu::UnicodeString::fromUTF8(text2);
  std::u16string u16_text2(icu_text2.getBuffer(),
                           icu_text2.getBuffer() + icu_text2.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.text_align = TextAlign::justify;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Ahem");
  text_style.font_size = 20;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text1);
  builder.AddPlaceholder(placeholder_run);
  builder.AddText(u16_text2);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(200);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;

  // Check location of placeholder at the center of the line.
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(2, 3, rect_height_style, rect_width_style);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 70);

  // Check location of character B at the end of the line.
  boxes =
      paragraph->GetRectsForRange(4, 5, rect_height_style, rect_width_style);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 180);
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(LeadingSpaceRTL)) {
  const char* text = " leading space";

  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::justify;
  paragraph_style.text_direction = TextDirection::rtl;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Ahem");
  text_style.font_size = 26;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  size_t paragraph_width = GetTestCanvasWidth() - 100;
  paragraph->Layout(paragraph_width);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 100, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  ASSERT_EQ(boxes.size(), 2ull);

  // This test should crash if behavior regresses.
}

TEST_F(ParagraphTest, DecorationsParagraph) {
  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 2;
  text_style.decoration = TextDecoration::kUnderline |
                          TextDecoration::kOverline |
                          TextDecoration::kLineThrough;
  text_style.decoration_style = txt::TextDecorationStyle::kSolid;
  text_style.decoration_color = SK_ColorBLACK;
  text_style.decoration_thickness_multiplier = 2.0;
  builder.PushStyle(text_style);
  builder.AddText(u"This text should be");

  text_style.decoration_style = txt::TextDecorationStyle::kDouble;
  text_style.decoration_color = SK_ColorBLUE;
  text_style.decoration_thickness_multiplier = 1.0;
  builder.PushStyle(text_style);
  builder.AddText(u" decorated even when");

  text_style.decoration_style = txt::TextDecorationStyle::kDotted;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u" wrapped around to");

  text_style.decoration_style = txt::TextDecorationStyle::kDashed;
  text_style.decoration_color = SK_ColorBLACK;
  text_style.decoration_thickness_multiplier = 3.0;
  builder.PushStyle(text_style);
  builder.AddText(u" the next line.");

  text_style.decoration_style = txt::TextDecorationStyle::kWavy;
  text_style.decoration_color = SK_ColorRED;
  text_style.decoration_thickness_multiplier = 1.0;
  builder.PushStyle(text_style);

  builder.AddText(u" Otherwise, bad things happen.");

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->runs_.size(), 5ull);
  ASSERT_EQ(paragraph->records_.size(), 6ull);

  for (size_t i = 0; i < 6; ++i) {
    ASSERT_EQ(paragraph->records_[i].style().decoration,
              TextDecoration::kUnderline | TextDecoration::kOverline |
                  TextDecoration::kLineThrough);
  }

  ASSERT_EQ(paragraph->records_[0].style().decoration_style,
            txt::TextDecorationStyle::kSolid);
  ASSERT_EQ(paragraph->records_[1].style().decoration_style,
            txt::TextDecorationStyle::kDouble);
  ASSERT_EQ(paragraph->records_[2].style().decoration_style,
            txt::TextDecorationStyle::kDotted);
  ASSERT_EQ(paragraph->records_[3].style().decoration_style,
            txt::TextDecorationStyle::kDashed);
  ASSERT_EQ(paragraph->records_[4].style().decoration_style,
            txt::TextDecorationStyle::kDashed);
  ASSERT_EQ(paragraph->records_[5].style().decoration_style,
            txt::TextDecorationStyle::kWavy);

  ASSERT_EQ(paragraph->records_[0].style().decoration_color, SK_ColorBLACK);
  ASSERT_EQ(paragraph->records_[1].style().decoration_color, SK_ColorBLUE);
  ASSERT_EQ(paragraph->records_[2].style().decoration_color, SK_ColorBLACK);
  ASSERT_EQ(paragraph->records_[3].style().decoration_color, SK_ColorBLACK);
  ASSERT_EQ(paragraph->records_[4].style().decoration_color, SK_ColorBLACK);
  ASSERT_EQ(paragraph->records_[5].style().decoration_color, SK_ColorRED);

  ASSERT_EQ(paragraph->records_[0].style().decoration_thickness_multiplier,
            2.0);
  ASSERT_EQ(paragraph->records_[1].style().decoration_thickness_multiplier,
            1.0);
  ASSERT_EQ(paragraph->records_[2].style().decoration_thickness_multiplier,
            1.0);
  ASSERT_EQ(paragraph->records_[3].style().decoration_thickness_multiplier,
            3.0);
  ASSERT_EQ(paragraph->records_[4].style().decoration_thickness_multiplier,
            3.0);
  ASSERT_EQ(paragraph->records_[5].style().decoration_thickness_multiplier,
            1.0);
}

TEST_F(ParagraphTest, WavyDecorationParagraph) {
  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 26;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 2;
  text_style.decoration = TextDecoration::kUnderline |
                          TextDecoration::kOverline |
                          TextDecoration::kLineThrough;

  text_style.decoration_style = txt::TextDecorationStyle::kWavy;
  text_style.decoration_color = SK_ColorRED;
  text_style.decoration_thickness_multiplier = 1.0;
  builder.PushStyle(text_style);

  builder.AddText(u" Otherwise, bad things happen.");

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->runs_.size(), 1ull);
  ASSERT_EQ(paragraph->records_.size(), 1ull);

  for (size_t i = 0; i < 1; ++i) {
    ASSERT_EQ(paragraph->records_[i].style().decoration,
              TextDecoration::kUnderline | TextDecoration::kOverline |
                  TextDecoration::kLineThrough);
  }

  ASSERT_EQ(paragraph->records_[0].style().decoration_style,
            txt::TextDecorationStyle::kWavy);

  ASSERT_EQ(paragraph->records_[0].style().decoration_color, SK_ColorRED);

  ASSERT_EQ(paragraph->records_[0].style().decoration_thickness_multiplier,
            1.0);

  SkPath path0;
  SkPath canonical_path0;
  paragraph->ComputeWavyDecoration(path0, 1, 1, 9.56, 1);

  canonical_path0.moveTo(1, 1);
  canonical_path0.rQuadTo(1, -1, 2, 0);
  canonical_path0.rQuadTo(1, 1, 2, 0);
  canonical_path0.rQuadTo(1, -1, 2, 0);
  canonical_path0.rQuadTo(1, 1, 2, 0);
  canonical_path0.rQuadTo(0.78, -0.78, 1.56, -0.3432);

  ASSERT_EQ(path0.countPoints(), canonical_path0.countPoints());
  for (int i = 0; i < canonical_path0.countPoints(); ++i) {
    ASSERT_EQ(path0.getPoint(i).x(), canonical_path0.getPoint(i).x());
    ASSERT_EQ(path0.getPoint(i).y(), canonical_path0.getPoint(i).y());
  }

  SkPath path1;
  SkPath canonical_path1;
  paragraph->ComputeWavyDecoration(path1, 1, 1, 8.35, 1);

  canonical_path1.moveTo(1, 1);
  canonical_path1.rQuadTo(1, -1, 2, 0);
  canonical_path1.rQuadTo(1, 1, 2, 0);
  canonical_path1.rQuadTo(1, -1, 2, 0);
  canonical_path1.rQuadTo(1, 1, 2, 0);
  canonical_path1.rQuadTo(0.175, -0.175, 0.35, -0.28875);

  ASSERT_EQ(path1.countPoints(), canonical_path1.countPoints());
  for (int i = 0; i < canonical_path1.countPoints(); ++i) {
    ASSERT_EQ(path1.getPoint(i).x(), canonical_path1.getPoint(i).x());
    ASSERT_EQ(path1.getPoint(i).y(), canonical_path1.getPoint(i).y());
  }

  SkPath path2;
  SkPath canonical_path2;
  paragraph->ComputeWavyDecoration(path2, 1, 1, 10.59, 1);

  canonical_path2.moveTo(1, 1);
  canonical_path2.rQuadTo(1, -1, 2, 0);
  canonical_path2.rQuadTo(1, 1, 2, 0);
  canonical_path2.rQuadTo(1, -1, 2, 0);
  canonical_path2.rQuadTo(1, 1, 2, 0);
  canonical_path2.rQuadTo(1, -1, 2, 0);
  canonical_path2.rQuadTo(0.295, 0.295, 0.59, 0.41595);

  ASSERT_EQ(path2.countPoints(), canonical_path2.countPoints());
  for (int i = 0; i < canonical_path2.countPoints(); ++i) {
    ASSERT_EQ(path2.getPoint(i).x(), canonical_path2.getPoint(i).x());
    ASSERT_EQ(path2.getPoint(i).y(), canonical_path2.getPoint(i).y());
  }

  SkPath path3;
  SkPath canonical_path3;
  paragraph->ComputeWavyDecoration(path3, 1, 1, 11.2, 1);

  canonical_path3.moveTo(1, 1);
  canonical_path3.rQuadTo(1, -1, 2, 0);
  canonical_path3.rQuadTo(1, 1, 2, 0);
  canonical_path3.rQuadTo(1, -1, 2, 0);
  canonical_path3.rQuadTo(1, 1, 2, 0);
  canonical_path3.rQuadTo(1, -1, 2, 0);
  canonical_path3.rQuadTo(0.6, 0.6, 1.2, 0.48);

  ASSERT_EQ(path3.countPoints(), canonical_path3.countPoints());
  for (int i = 0; i < canonical_path3.countPoints(); ++i) {
    ASSERT_EQ(path3.getPoint(i).x(), canonical_path3.getPoint(i).x());
    ASSERT_EQ(path3.getPoint(i).y(), canonical_path3.getPoint(i).y());
  }

  SkPath path4;
  SkPath canonical_path4;
  paragraph->ComputeWavyDecoration(path4, 1, 1, 12, 1);

  canonical_path4.moveTo(1, 1);
  canonical_path4.rQuadTo(1, -1, 2, 0);
  canonical_path4.rQuadTo(1, 1, 2, 0);
  canonical_path4.rQuadTo(1, -1, 2, 0);
  canonical_path4.rQuadTo(1, 1, 2, 0);
  canonical_path4.rQuadTo(1, -1, 2, 0);
  canonical_path4.rQuadTo(1, 1, 2, 0);

  ASSERT_EQ(path4.countPoints(), canonical_path4.countPoints());
  for (int i = 0; i < canonical_path4.countPoints(); ++i) {
    ASSERT_EQ(path4.getPoint(i).x(), canonical_path4.getPoint(i).x());
    ASSERT_EQ(path4.getPoint(i).y(), canonical_path4.getPoint(i).y());
  }
}

TEST_F(ParagraphTest, ItalicsParagraph) {
  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorRED;
  text_style.font_size = 10;
  builder.PushStyle(text_style);
  builder.AddText(u"No italic ");

  text_style.font_style = txt::FontStyle::italic;
  builder.PushStyle(text_style);
  builder.AddText(u"Yes Italic ");

  builder.Pop();
  builder.AddText(u"No Italic again.");

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_EQ(paragraph->runs_.runs_.size(), 3ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 3ull);
  ASSERT_EQ(paragraph->records_[1].style().color, text_style.color);
  ASSERT_EQ(paragraph->records_[1].style().font_style, txt::FontStyle::italic);
  ASSERT_EQ(paragraph->records_[2].style().font_style, txt::FontStyle::normal);
  ASSERT_EQ(paragraph->records_[0].style().font_style, txt::FontStyle::normal);
  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, ChineseParagraph) {
  const char* text =
      "左線読設重説切後碁給能上目秘使約。満毎冠行来昼本可必図将発確年。今属場育"
      "図情闘陰野高備込制詩西校客。審対江置講今固残必託地集済決維駆年策。立得庭"
      "際輝求佐抗蒼提夜合逃表。注統天言件自謙雅載報紙喪。作画稿愛器灯女書利変探"
      "訃第金線朝開化建。子戦年帝励害表月幕株漠新期刊人秘。図的海力生禁挙保天戦"
      "聞条年所在口。";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::justify;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_size = 35;
  text_style.letter_spacing = 2;
  text_style.font_families = std::vector<std::string>(1, "Source Han Serif CN");
  text_style.decoration = TextDecoration::kUnderline |
                          TextDecoration::kOverline |
                          TextDecoration::kLineThrough;
  text_style.decoration_style = txt::TextDecorationStyle::kSolid;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_EQ(paragraph->records_.size(), 7ull);

  ASSERT_TRUE(Snapshot());
}

// TODO(garyq): Support RTL languages.
TEST_F(ParagraphTest, DISABLED_ArabicParagraph) {
  const char* text =
      "من أسر وإعلان الخاصّة وهولندا،, عل قائمة الضغوط بالمطالبة تلك. الصفحة "
      "بمباركة التقليدية قام عن. تصفح";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::right;
  paragraph_style.text_direction = TextDirection::rtl;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_size = 35;
  text_style.letter_spacing = 2;
  text_style.font_families = std::vector<std::string>(1, "Katibeh");
  text_style.decoration = TextDecoration::kUnderline |
                          TextDecoration::kOverline |
                          TextDecoration::kLineThrough;
  text_style.decoration_style = txt::TextDecorationStyle::kSolid;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());

  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_EQ(paragraph->records_.size(), 2ull);
  ASSERT_EQ(paragraph->paragraph_style_.text_direction, TextDirection::rtl);

  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[u16_text.length() - i]);
  }

  ASSERT_TRUE(Snapshot());
}

// Checks if the rects are in the correct positions after typing spaces in
// Arabic.
TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(ArabicRectsParagraph)) {
  const char* text = "بمباركة التقليدية قام عن. تصفح يد    ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::right;
  paragraph_style.text_direction = TextDirection::rtl;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Noto Naskh Arabic");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 100, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 2ull);

  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 556.48438);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), -0.26855469);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 900);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 44);

  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 510.03125);
  EXPECT_FLOAT_EQ(boxes[1].rect.top(), -0.26855469);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 556.98438);
  EXPECT_FLOAT_EQ(boxes[1].rect.bottom(), 44);

  ASSERT_EQ(paragraph_style.text_align,
            paragraph->GetParagraphStyle().text_align);

  ASSERT_TRUE(Snapshot());
}

// Trailing space at the end of the arabic rtl run should be at the left end of
// the arabic run.
TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(ArabicRectsLTRLeftAlignParagraph)) {
  const char* text = "Helloبمباركة التقليدية قام عن. تصفح يد ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::left;
  paragraph_style.text_direction = TextDirection::ltr;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Noto Naskh Arabic");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(36, 40, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);

  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 89.425781);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), -0.26855469);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 121.90625);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 44);

  ASSERT_EQ(paragraph_style.text_align,
            paragraph->GetParagraphStyle().text_align);

  ASSERT_TRUE(Snapshot());
}

// Trailing space at the end of the arabic rtl run should be at the left end of
// the arabic run and be a ghost space.
TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(ArabicRectsLTRRightAlignParagraph)) {
  const char* text = "Helloبمباركة التقليدية قام عن. تصفح يد ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::right;
  paragraph_style.text_direction = TextDirection::ltr;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Noto Naskh Arabic");
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  text_style.decoration = TextDecoration::kUnderline;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(36, 40, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 2ull);

  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 556.48438);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), -0.26855469);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 577.72656);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 44);

  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 545.24609);
  EXPECT_FLOAT_EQ(boxes[1].rect.top(), -0.26855469);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 556.98438);
  EXPECT_FLOAT_EQ(boxes[1].rect.bottom(), 44);

  ASSERT_EQ(paragraph_style.text_align,
            paragraph->GetParagraphStyle().text_align);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, GetGlyphPositionAtCoordinateParagraph) {
  const char* text =
      "12345 67890 12345 67890 12345 67890 12345 67890 12345 67890 12345 "
      "67890 12345";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 50;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());

  // Tests for GetGlyphPositionAtCoordinate()
  // NOTE: resulting values can be a few off from their respective positions in
  // the original text because the final trailing whitespaces are sometimes not
  // drawn (namely, when using "justify" alignment) and therefore are not active
  // glyphs.
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(-10000, -10000).position,
            0ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(-1, -1).position, 0ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(0, 0).position, 0ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(3, 3).position, 0ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(35, 1).position, 1ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(300, 2).position, 11ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(301, 2.2).position, 11ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(302, 2.6).position, 11ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(301, 2.1).position, 11ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(100000, 20).position,
            18ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(450, 20).position, 16ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(100000, 90).position,
            36ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(-100000, 90).position,
            18ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(20, -80).position, 1ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(1, 90).position, 18ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(1, 170).position, 36ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(10000, 180).position,
            72ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(70, 180).position, 56ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(1, 270).position, 72ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(35, 90).position, 19ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(10000, 10000).position,
            77ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(85, 10000).position, 75ull);
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(GetRectsForRangeParagraph)) {
  const char* text =
      "12345,  \"67890\" 12345 67890 12345 67890 12345 67890 12345 67890 12345 "
      "67890 12345";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  // NOTE: The base truth values may still need adjustment as the specifics
  // are adjusted.
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 28.417969);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(2, 8, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 56.835938);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 177.98438);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(8, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 177.98438);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 507.03906);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(30, 100, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 4ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 211.37891);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 59.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 463.62891);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 118);

  // TODO(garyq): The following set of vals are definitely wrong and
  // end of paragraph handling needs to be fixed in a later patch.
  EXPECT_FLOAT_EQ(boxes[3].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[3].rect.top(), 236.40625);
  EXPECT_FLOAT_EQ(boxes[3].rect.right(), 142.08984);
  EXPECT_FLOAT_EQ(boxes[3].rect.bottom(), 295);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(19, 22, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 450.20312);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 519.49219);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(21, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, LINUX_ONLY(GetRectsForRangeTight)) {
  const char* text =
      "(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)("
      "　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)("
      "　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Noto Sans CJK JP");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  // NOTE: The base truth values may still need adjustment as the specifics
  // are adjusted.
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 16.898438);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 74);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(2, 8, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 264.09766);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 74);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(8, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 2ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 264.09766);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 595.09375);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 74);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       DISABLE_ON_WINDOWS(GetRectsForRangeIncludeLineSpacingMiddle)) {
  const char* text =
      "(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)("
      "　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)("
      "　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.6;
  text_style.has_height_override = true;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  // NOTE: The base truth values may still need adjustment as the specifics
  // are adjusted.
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kIncludeLineSpacingMiddle;
  Paragraph::RectWidthStyle rect_width_style = Paragraph::RectWidthStyle::kMax;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 17.433594);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 88.473305);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(2, 8, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 67.433594);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 190.01953);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 88.473305);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(8, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 190.01953);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 508.09375);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 88.473312);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(30, 150, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 8ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 190.01953);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 88.473312);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 525.72266);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 168.47331);

  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 525.72266);
  EXPECT_FLOAT_EQ(boxes[1].rect.top(), 88.473312);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[1].rect.bottom(), 168.4733);

  EXPECT_FLOAT_EQ(boxes[2].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[2].rect.top(), 168.4733);
  EXPECT_FLOAT_EQ(boxes[2].rect.right(), 531.60547);
  EXPECT_FLOAT_EQ(boxes[2].rect.bottom(), 248.47331);

  EXPECT_FLOAT_EQ(boxes[3].rect.left(), 531.60547);
  EXPECT_FLOAT_EQ(boxes[3].rect.top(), 168.4733);
  EXPECT_FLOAT_EQ(boxes[3].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[3].rect.bottom(), 248.47331);

  EXPECT_FLOAT_EQ(boxes[4].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[4].rect.top(), 248.47331);
  EXPECT_FLOAT_EQ(boxes[4].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[4].rect.bottom(), 328.4733);

  EXPECT_FLOAT_EQ(boxes[5].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[5].rect.top(), 328.47333);
  EXPECT_FLOAT_EQ(boxes[5].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[5].rect.bottom(), 408.4733);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(19, 22, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 463.75781);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 530.26172);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 88.473305);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(21, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       DISABLE_ON_WINDOWS(GetRectsForRangeIncludeLineSpacingTop)) {
  const char* text =
      "(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)("
      "　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)("
      "　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.6;
  text_style.has_height_override = true;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  // NOTE: The base truth values may still need adjustment as the specifics
  // are adjusted.
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kIncludeLineSpacingTop;
  Paragraph::RectWidthStyle rect_width_style = Paragraph::RectWidthStyle::kMax;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 17.433594);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 80);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(2, 8, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 67.433594);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 190.01953);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 80);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(8, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 190.01953);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 508.09375);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 80);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(30, 150, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 8ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 190.01953);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 80);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 525.72266);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 160);

  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 525.72266);
  EXPECT_FLOAT_EQ(boxes[1].rect.top(), 80);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[1].rect.bottom(), 160);

  EXPECT_FLOAT_EQ(boxes[2].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[2].rect.top(), 160);
  EXPECT_FLOAT_EQ(boxes[2].rect.right(), 531.60547);
  EXPECT_FLOAT_EQ(boxes[2].rect.bottom(), 240);

  EXPECT_FLOAT_EQ(boxes[3].rect.left(), 531.60547);
  EXPECT_FLOAT_EQ(boxes[3].rect.top(), 160);
  EXPECT_FLOAT_EQ(boxes[3].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[3].rect.bottom(), 240);

  EXPECT_FLOAT_EQ(boxes[4].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[4].rect.top(), 240);
  EXPECT_FLOAT_EQ(boxes[4].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[4].rect.bottom(), 320);

  EXPECT_FLOAT_EQ(boxes[5].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[5].rect.top(), 320);
  EXPECT_FLOAT_EQ(boxes[5].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[5].rect.bottom(), 400);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(19, 22, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 463.75781);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 530.26172);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 80);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(21, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       DISABLE_ON_WINDOWS(GetRectsForRangeIncludeLineSpacingBottom)) {
  const char* text =
      "(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)("
      "　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)("
      "　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)(　´･‿･｀)";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.6;
  text_style.has_height_override = true;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  // NOTE: The base truth values may still need adjustment as the specifics
  // are adjusted.
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kIncludeLineSpacingBottom;
  Paragraph::RectWidthStyle rect_width_style = Paragraph::RectWidthStyle::kMax;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 17.433594);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 96.946609);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(2, 8, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 67.433594);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 190.01953);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 96.946609);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(8, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 190.01953);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 508.09375);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 96.946609);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(30, 150, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 8ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 190.01953);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 96.946617);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 525.72266);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 176.94661);

  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 525.72266);
  EXPECT_FLOAT_EQ(boxes[1].rect.top(), 96.946617);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[1].rect.bottom(), 176.94661);

  EXPECT_FLOAT_EQ(boxes[2].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[2].rect.top(), 176.94661);
  EXPECT_FLOAT_EQ(boxes[2].rect.right(), 531.60547);
  EXPECT_FLOAT_EQ(boxes[2].rect.bottom(), 256.94662);

  EXPECT_FLOAT_EQ(boxes[3].rect.left(), 531.60547);
  EXPECT_FLOAT_EQ(boxes[3].rect.top(), 176.94661);
  EXPECT_FLOAT_EQ(boxes[3].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[3].rect.bottom(), 256.94662);

  EXPECT_FLOAT_EQ(boxes[4].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[4].rect.top(), 256.94662);
  EXPECT_FLOAT_EQ(boxes[4].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[4].rect.bottom(), 336.94662);

  EXPECT_FLOAT_EQ(boxes[5].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[5].rect.top(), 336.94662);
  EXPECT_FLOAT_EQ(boxes[5].rect.right(), 570.05859);
  EXPECT_FLOAT_EQ(boxes[5].rect.bottom(), 416.94662);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(19, 22, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 463.75781);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 16.946615);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 530.26172);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 96.946609);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(21, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, GetRectsForRangeIncludeCombiningCharacter) {
  const char* text = "ดีสวัสดีชาวโลกที่น่ารัก";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 50;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;

  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 0ull);

  // Case when the sentence starts with a combining character
  // We should get 0 box for ด because it's already been combined to ดี
  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(1, 2, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 1ull);

  boxes =
      paragraph->GetRectsForRange(0, 2, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 1ull);

  // Case when the sentence contains a combining character
  // We should get 0 box for ว because it's already been combined to วั
  boxes =
      paragraph->GetRectsForRange(3, 4, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(4, 5, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 1ull);

  boxes =
      paragraph->GetRectsForRange(3, 5, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 1ull);

  // Case when the sentence contains a combining character that contain 3
  // characters We should get 0 box for ท and ที because it's already been
  // combined to ที่
  boxes =
      paragraph->GetRectsForRange(14, 15, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(15, 16, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(16, 17, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 1ull);

  boxes =
      paragraph->GetRectsForRange(14, 17, rect_height_style, rect_width_style);
  EXPECT_EQ(boxes.size(), 1ull);
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(GetRectsForRangeCenterParagraph)) {
  const char* text = "01234  　 ";  // includes ideographic space
                                    // and english space.
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::center;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 203.95508);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 232.37305);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(2, 4, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 260.79102);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 317.62695);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(4, 6, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 2ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 317.62695);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 346.04492);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorBLACK);
  boxes =
      paragraph->GetRectsForRange(5, 6, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 346.04492);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 358.49805);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(21, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, LINUX_ONLY(GetRectsForRangeParagraphNewlineLeftAlign)) {
  const char* text = "01234\n\nعab\naعلی\n";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";
  paragraph_style.max_lines = 10;
  paragraph_style.text_direction = TextDirection::ltr;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = {"Roboto", "Noto Naskh Arabic"};
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 28.417969);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(6, 7, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(),
                  75);  // TODO(garyq): This value can be improved... Should be
                        // taller, but we need a good way to obtain a height
                        // without any glyphs on the line.

  boxes =
      paragraph->GetRectsForRange(10, 11, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 85);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 85);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 160);

  boxes =
      paragraph->GetRectsForRange(15, 16, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 27);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 27);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 245);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, LINUX_ONLY(GetRectsForRangeParagraphNewlineRightAlign)) {
  const char* text = "01234\n\nعab\naعلی\n";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";
  paragraph_style.max_lines = 10;
  paragraph_style.text_direction = TextDirection::ltr;
  paragraph_style.text_align = TextAlign::right;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = {"Roboto", "Noto Naskh Arabic"};
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 407.91016);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 436.32812);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(6, 7, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 550);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 550);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(),
                  75);  // TODO(garyq): This value can be improved... Should be
                        // taller, but we need a good way to obtain a height
                        // without any glyphs on the line.

  boxes =
      paragraph->GetRectsForRange(10, 11, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 550);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 550);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 160);

  boxes =
      paragraph->GetRectsForRange(15, 16, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 478);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 478);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 245);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       LINUX_ONLY(GetRectsForRangeCenterParagraphNewlineCentered)) {
  const char* text = "01234\n\nعab\naعلی\n";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";
  paragraph_style.max_lines = 10;
  paragraph_style.text_direction = TextDirection::ltr;
  paragraph_style.text_align = TextAlign::center;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = {"Roboto", "Noto Naskh Arabic"};
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 203.95508);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 232.37305);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(6, 7, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 275);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 275);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(),
                  75);  // TODO(garyq): This value can be improved... Should be
                        // taller, but we need a good way to obtain a height
                        // without any glyphs on the line.

  boxes =
      paragraph->GetRectsForRange(10, 11, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 317);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 317);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 160);

  boxes =
      paragraph->GetRectsForRange(15, 16, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 252);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 252);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 245);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       LINUX_ONLY(GetRectsForRangeParagraphNewlineRTLLeftAlign)) {
  const char* text = "01234\n\nعab\naعلی\n";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";
  paragraph_style.max_lines = 10;
  paragraph_style.text_direction = TextDirection::rtl;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = {"Roboto", "Noto Naskh Arabic"};
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 28.417969);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(6, 7, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(),
                  75);  // TODO(garyq): This value can be improved... Should be
                        // taller, but we need a good way to obtain a height
                        // without any glyphs on the line.

  boxes =
      paragraph->GetRectsForRange(10, 11, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 55);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 55);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 160);

  boxes =
      paragraph->GetRectsForRange(15, 16, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 245);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       LINUX_ONLY(GetRectsForRangeParagraphNewlineRTLRightAlign)) {
  const char* text = "01234\n\nعab\naعلی\n";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";
  paragraph_style.max_lines = 10;
  paragraph_style.text_direction = TextDirection::rtl;
  paragraph_style.text_align = TextAlign::right;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = {"Roboto", "Noto Naskh Arabic"};
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 407.91016);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 436.32812);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(6, 7, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 550);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 550);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(),
                  75);  // TODO(garyq): This value can be improved... Should be
                        // taller, but we need a good way to obtain a height
                        // without any glyphs on the line.

  boxes =
      paragraph->GetRectsForRange(10, 11, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 519);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 519);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 160);

  boxes =
      paragraph->GetRectsForRange(15, 16, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 451);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 451);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 245);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       LINUX_ONLY(GetRectsForRangeCenterParagraphNewlineRTLCentered)) {
  const char* text = "01234\n\nعab\naعلی\n";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";
  paragraph_style.max_lines = 10;
  paragraph_style.text_direction = TextDirection::rtl;
  paragraph_style.text_align = TextAlign::center;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = {"Roboto", "Noto Naskh Arabic"};
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 203.95508);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 232.37305);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(6, 7, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 275);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 275);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(),
                  75);  // TODO(garyq): This value can be improved... Should be
                        // taller, but we need a good way to obtain a height
                        // without any glyphs on the line.

  boxes =
      paragraph->GetRectsForRange(10, 11, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 287);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 287);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 160);

  boxes =
      paragraph->GetRectsForRange(15, 16, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 225);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 225);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 245);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest,
       DISABLE_ON_WINDOWS(GetRectsForRangeCenterMultiLineParagraph)) {
  const char* text = "01234  　 \n0123　        ";  // includes ideographic
                                                    // space and english space.
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::center;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 203.95508);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 232.37305);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorBLUE);
  boxes =
      paragraph->GetRectsForRange(2, 4, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 260.79102);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 317.62695);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes =
      paragraph->GetRectsForRange(4, 6, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 2ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 317.62695);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 346.04492);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorBLACK);
  boxes =
      paragraph->GetRectsForRange(5, 6, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 346.04492);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 358.49805);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorBLACK);
  boxes =
      paragraph->GetRectsForRange(10, 12, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 218.16406);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 59.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 275);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 118);

  paint.setColor(SK_ColorBLACK);
  boxes =
      paragraph->GetRectsForRange(14, 18, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 331.83594);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 59.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 419.19531);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 118);

  paint.setColor(SK_ColorRED);
  boxes =
      paragraph->GetRectsForRange(21, 21, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, LINUX_ONLY(GetRectsForRangeStrut)) {
  const char* text = "Chinese 字典";

  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.strut_enabled = true;
  paragraph_style.strut_font_families.push_back("Roboto");
  paragraph_style.strut_font_size = 14;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families.push_back("Noto Sans CJK JP");
  text_style.font_size = 20;
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  std::vector<txt::Paragraph::TextBox> strut_boxes =
      paragraph->GetRectsForRange(0, 10, Paragraph::RectHeightStyle::kStrut,
                                  Paragraph::RectWidthStyle::kMax);
  ASSERT_EQ(strut_boxes.size(), 1ull);
  const SkRect& strut_rect = strut_boxes.front().rect;
  paint.setColor(SK_ColorRED);
  GetCanvas()->drawRect(strut_rect, paint);

  std::vector<txt::Paragraph::TextBox> tight_boxes =
      paragraph->GetRectsForRange(0, 10, Paragraph::RectHeightStyle::kTight,
                                  Paragraph::RectWidthStyle::kMax);
  ASSERT_EQ(tight_boxes.size(), 1ull);
  const SkRect& tight_rect = tight_boxes.front().rect;
  paint.setColor(SK_ColorGREEN);
  GetCanvas()->drawRect(tight_rect, paint);

  EXPECT_FLOAT_EQ(strut_rect.left(), 0);
  EXPECT_FLOAT_EQ(strut_rect.top(), 10.611719);
  EXPECT_FLOAT_EQ(strut_rect.right(), 118.61719);
  EXPECT_FLOAT_EQ(strut_rect.bottom(), 27.017969);

  ASSERT_TRUE(tight_rect.contains(strut_rect));

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(GetRectsForRangeStrutFallback)) {
  const char* text = "Chinese 字典";

  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.strut_enabled = false;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families.push_back("Noto Sans CJK JP");
  text_style.font_size = 20;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  std::vector<txt::Paragraph::TextBox> strut_boxes =
      paragraph->GetRectsForRange(0, 10, Paragraph::RectHeightStyle::kStrut,
                                  Paragraph::RectWidthStyle::kMax);
  std::vector<txt::Paragraph::TextBox> tight_boxes =
      paragraph->GetRectsForRange(0, 10, Paragraph::RectHeightStyle::kTight,
                                  Paragraph::RectWidthStyle::kMax);

  ASSERT_EQ(strut_boxes.size(), 1ull);
  ASSERT_EQ(tight_boxes.size(), 1ull);
  ASSERT_EQ(strut_boxes.front().rect, tight_boxes.front().rect);
}

SkRect GetCoordinatesForGlyphPosition(txt::Paragraph& paragraph, size_t pos) {
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph.GetRectsForRange(pos, pos + 1, Paragraph::RectHeightStyle::kMax,
                                 Paragraph::RectWidthStyle::kTight);
  return !boxes.empty() ? boxes.front().rect : SkRect::MakeEmpty();
}

TEST_F(ParagraphTest, GetWordBoundaryParagraph) {
  const char* text =
      "12345  67890 12345 67890 12345 67890 12345 67890 12345 67890 12345 "
      "67890 12345";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 52;
  text_style.letter_spacing = 1.19039;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.5;
  text_style.has_height_override = true;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);
  paint.setColor(SK_ColorRED);

  SkRect rect = GetCoordinatesForGlyphPosition(*paragraph, 0);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  EXPECT_EQ(paragraph->GetWordBoundary(0), txt::Paragraph::Range<size_t>(0, 5));
  EXPECT_EQ(paragraph->GetWordBoundary(1), txt::Paragraph::Range<size_t>(0, 5));
  EXPECT_EQ(paragraph->GetWordBoundary(2), txt::Paragraph::Range<size_t>(0, 5));
  EXPECT_EQ(paragraph->GetWordBoundary(3), txt::Paragraph::Range<size_t>(0, 5));
  EXPECT_EQ(paragraph->GetWordBoundary(4), txt::Paragraph::Range<size_t>(0, 5));
  rect = GetCoordinatesForGlyphPosition(*paragraph, 5);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  EXPECT_EQ(paragraph->GetWordBoundary(5), txt::Paragraph::Range<size_t>(5, 7));
  rect = GetCoordinatesForGlyphPosition(*paragraph, 6);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  EXPECT_EQ(paragraph->GetWordBoundary(6), txt::Paragraph::Range<size_t>(5, 7));
  rect = GetCoordinatesForGlyphPosition(*paragraph, 7);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  EXPECT_EQ(paragraph->GetWordBoundary(7),
            txt::Paragraph::Range<size_t>(7, 12));
  EXPECT_EQ(paragraph->GetWordBoundary(8),
            txt::Paragraph::Range<size_t>(7, 12));
  EXPECT_EQ(paragraph->GetWordBoundary(9),
            txt::Paragraph::Range<size_t>(7, 12));
  EXPECT_EQ(paragraph->GetWordBoundary(10),
            txt::Paragraph::Range<size_t>(7, 12));
  EXPECT_EQ(paragraph->GetWordBoundary(11),
            txt::Paragraph::Range<size_t>(7, 12));
  rect = GetCoordinatesForGlyphPosition(*paragraph, 12);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  EXPECT_EQ(paragraph->GetWordBoundary(12),
            txt::Paragraph::Range<size_t>(12, 13));
  rect = GetCoordinatesForGlyphPosition(*paragraph, 13);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  EXPECT_EQ(paragraph->GetWordBoundary(13),
            txt::Paragraph::Range<size_t>(13, 18));
  rect = GetCoordinatesForGlyphPosition(*paragraph, 18);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  rect = GetCoordinatesForGlyphPosition(*paragraph, 19);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  rect = GetCoordinatesForGlyphPosition(*paragraph, 24);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  rect = GetCoordinatesForGlyphPosition(*paragraph, 25);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  rect = GetCoordinatesForGlyphPosition(*paragraph, 30);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  EXPECT_EQ(paragraph->GetWordBoundary(30),
            txt::Paragraph::Range<size_t>(30, 31));
  rect = GetCoordinatesForGlyphPosition(*paragraph, 31);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  rect = GetCoordinatesForGlyphPosition(*paragraph, icu_text.length() - 5);
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  EXPECT_EQ(
      paragraph->GetWordBoundary(icu_text.length() - 1),
      txt::Paragraph::Range<size_t>(icu_text.length() - 5, icu_text.length()));
  rect = GetCoordinatesForGlyphPosition(*paragraph, icu_text.length());
  GetCanvas()->drawLine(rect.fLeft, rect.fTop, rect.fLeft, rect.fBottom, paint);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, SpacingParagraph) {
  const char* text = "H";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 50;
  text_style.letter_spacing = 20;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();

  text_style.font_size = 50;
  text_style.letter_spacing = 10;
  text_style.word_spacing = 0;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();

  text_style.font_size = 50;
  text_style.letter_spacing = 20;
  text_style.word_spacing = 0;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);
  builder.Pop();

  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  builder.PushStyle(text_style);
  builder.AddText(u"|");
  builder.Pop();

  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 20;
  builder.PushStyle(text_style);
  builder.AddText(u"H ");
  builder.Pop();

  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  builder.PushStyle(text_style);
  builder.AddText(u"H ");
  builder.Pop();

  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 20;
  builder.PushStyle(text_style);
  builder.AddText(u"H ");
  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);
  paint.setColor(SK_ColorRED);

  ASSERT_TRUE(Snapshot());

  ASSERT_EQ(paragraph->records_.size(), 7ull);
  ASSERT_EQ(paragraph->records_[0].style().letter_spacing, 20);
  ASSERT_EQ(paragraph->records_[1].style().letter_spacing, 10);
  ASSERT_EQ(paragraph->records_[2].style().letter_spacing, 20);

  ASSERT_EQ(paragraph->records_[4].style().word_spacing, 20);
  ASSERT_EQ(paragraph->records_[5].style().word_spacing, 0);
  ASSERT_EQ(paragraph->records_[6].style().word_spacing, 20);
}

TEST_F(ParagraphTest, LongWordParagraph) {
  const char* text =
      "A "
      "veryverylongwordtoseewherethiswillwraporifitwillatallandifitdoesthenthat"
      "wouldbeagoodthingbecausethebreakingisworking.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.break_strategy = minikin::kBreakStrategy_HighQuality;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 31;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() / 2);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_EQ(paragraph->GetLineCount(), 4ull);
  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, LINUX_ONLY(KernScaleParagraph)) {
  float scale = 3.0f;

  txt::ParagraphStyle paragraph_style;
  paragraph_style.break_strategy = minikin::kBreakStrategy_HighQuality;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Droid Serif");
  text_style.font_size = 100 / scale;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(u"AVAVAWAH A0 V0 VA To The Lo");
  builder.PushStyle(text_style);
  builder.AddText(u"A");
  builder.PushStyle(text_style);
  builder.AddText(u"V");
  text_style.font_size = 14 / scale;
  builder.PushStyle(text_style);
  builder.AddText(
      u" Dialog Text List lots of words to see if kerning works on a bigger "
      u"set of characters AVAVAW");

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() / scale);
  GetCanvas()->scale(scale, scale);
  paragraph->Paint(GetCanvas(), 0, 0);
  GetCanvas()->scale(1.0, 1.0);
  ASSERT_TRUE(Snapshot());

  EXPECT_DOUBLE_EQ(paragraph->records_[0].offset().x(), 0);
  EXPECT_DOUBLE_EQ(paragraph->records_[1].offset().x(), 0);
  EXPECT_DOUBLE_EQ(paragraph->records_[2].offset().x(), 207.3671875f);
  EXPECT_DOUBLE_EQ(paragraph->records_[3].offset().x(), 230.8671875f);
  EXPECT_DOUBLE_EQ(paragraph->records_[4].offset().x(), 253.35546875f);
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(NewlineParagraph)) {
  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";
  paragraph_style.break_strategy = minikin::kBreakStrategy_HighQuality;

  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 60;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(
      u"line1\nline2 test1 test2 test3 test4 test5 test6 test7\nline3\n\nline4 "
      "test1 test2 test3 test4");

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 300);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());

  ASSERT_EQ(paragraph->records_.size(), 6ull);
  EXPECT_DOUBLE_EQ(paragraph->records_[0].offset().x(), 0);
  EXPECT_DOUBLE_EQ(paragraph->records_[1].offset().x(), 0);
  EXPECT_DOUBLE_EQ(paragraph->records_[1].offset().y(), 126);
  EXPECT_DOUBLE_EQ(paragraph->records_[2].offset().x(), 0);
  EXPECT_DOUBLE_EQ(paragraph->records_[3].offset().x(), 0);
  EXPECT_DOUBLE_EQ(paragraph->records_[4].offset().x(), 0);
  EXPECT_DOUBLE_EQ(paragraph->records_[3].offset().y(), 266);
  EXPECT_DOUBLE_EQ(paragraph->records_[5].offset().x(), 0);
}

TEST_F(ParagraphTest, LINUX_ONLY(EmojiParagraph)) {
  const char* text =
      "😀😃😄😁😆😅😂🤣☺😇🙂😍😡😟😢😻👽💩👍👎🙏👌👋👄👁👦👼👨‍🚀👨‍🚒🙋‍♂️👳👨‍👨‍👧‍👧\
      💼👡👠☂🐶🐰🐻🐼🐷🐒🐵🐔🐧🐦🐋🐟🐡🕸🐌🐴🐊🐄🐪🐘🌸🌏🔥🌟🌚🌝💦💧\
      ❄🍕🍔🍟🥝🍱🕶🎩🏈⚽🚴‍♀️🎻🎼🎹🚨🚎🚐⚓🛳🚀🚁🏪🏢🖱⏰📱💾💉📉🛏🔑🔓\
      📁🗓📊❤💯🚫🔻♠♣🕓❗🏳🏁🏳️‍🌈🇮🇹🇱🇷🇺🇸🇬🇧🇨🇳🇧🇴";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_families = std::vector<std::string>(1, "Noto Color Emoji");
  text_style.font_size = 50;
  text_style.decoration = TextDecoration::kUnderline;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());

  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }

  ASSERT_EQ(paragraph->records_.size(), 8ull);

  EXPECT_EQ(paragraph->records_[0].line(), 0ull);
  EXPECT_EQ(paragraph->records_[1].line(), 1ull);
  EXPECT_EQ(paragraph->records_[2].line(), 2ull);
  EXPECT_EQ(paragraph->records_[3].line(), 3ull);
  EXPECT_EQ(paragraph->records_[7].line(), 7ull);
}

TEST_F(ParagraphTest, LINUX_ONLY(EmojiMultiLineRectsParagraph)) {
  // clang-format off
  const char* text =
      "👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧i🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸"
      "👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸"
      "👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸"
      "👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸👩‍👩‍👦👩‍👩‍👧‍👧🇺🇸"
      "❄🍕🍔🍟🥝🍱🕶🎩🏈⚽🚴‍♀️🎻🎼🎹🚨🚎🚐⚓🛳🚀🚁🏪🏢🖱⏰📱💾💉📉🛏🔑🔓"
      "📁🗓📊❤💯🚫🔻♠♣🕓❗🏳🏁🏳️‍🌈🇮🇹🇱🇷🇺🇸🇬🇧🇨🇳🇧🇴";
  // clang-format on
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_families = std::vector<std::string>(1, "Noto Color Emoji");
  text_style.font_size = 50;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 300);

  paragraph->Paint(GetCanvas(), 0, 0);

  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }

  ASSERT_EQ(paragraph->records_.size(), 10ull);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  // GetPositionForCoordinates should not return inter-emoji positions.
  boxes = paragraph->GetRectsForRange(
      0, paragraph->GetGlyphPositionAtCoordinate(610, 100).position,
      rect_height_style, rect_width_style);
  paint.setColor(SK_ColorGREEN);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 2ull);
  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 622.53906);

  boxes = paragraph->GetRectsForRange(
      0, paragraph->GetGlyphPositionAtCoordinate(580, 100).position,
      rect_height_style, rect_width_style);
  paint.setColor(SK_ColorGREEN);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 2ull);
  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 560.28516);

  boxes = paragraph->GetRectsForRange(
      0, paragraph->GetGlyphPositionAtCoordinate(560, 100).position,
      rect_height_style, rect_width_style);
  paint.setColor(SK_ColorGREEN);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 2ull);
  EXPECT_FLOAT_EQ(boxes[1].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[1].rect.right(), 560.28516);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, LINUX_ONLY(LigatureCharacters)) {
  const char* text = "Office";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  // The "ffi" characters will be combined into one glyph in the Roboto font.
  // Verify that the graphemes within the glyph have distinct boxes.
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(1, 2, Paragraph::RectHeightStyle::kTight,
                                  Paragraph::RectWidthStyle::kTight);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 9.625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 13.608073);

  boxes = paragraph->GetRectsForRange(2, 4, Paragraph::RectHeightStyle::kTight,
                                      Paragraph::RectWidthStyle::kTight);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 13.608073);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 21.574219);
}

TEST_F(ParagraphTest, HyphenBreakParagraph) {
  const char* text =
      "A "
      "very-very-long-Hyphen-word-to-see-where-this-will-wrap-or-if-it-will-at-"
      "all-and-if-it-does-thent-hat-"
      "would-be-a-good-thing-because-the-breaking.";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.break_strategy = minikin::kBreakStrategy_HighQuality;

  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 31;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() / 2);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_EQ(paragraph->GetLineCount(), 5ull);
  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, RepeatLayoutParagraph) {
  const char* text =
      "Sentence to layout at diff widths to get diff line counts. short words "
      "short words short words short words short words short words short words "
      "short words short words short words short words short words short words "
      "end";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.break_strategy = minikin::kBreakStrategy_HighQuality;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 31;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  // First Layout.
  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(300);

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_EQ(paragraph->GetLineCount(), 12ull);

  // Second Layout.
  SetUp();
  paragraph->Layout(600);
  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_EQ(paragraph->GetLineCount(), 6ull);
  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, Ellipsize) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are necessary. Very short. ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.ellipsis = u"\u2026";
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_TRUE(Snapshot());

  // Check that the ellipsizer limited the text to one line and did not wrap
  // to a second line.
  ASSERT_EQ(paragraph->records_.size(), 1ull);
}

// Test for shifting when identical runs of text are built as multiple runs.
TEST_F(ParagraphTest, UnderlineShiftParagraph) {
  const char* text1 = "fluttser ";
  auto icu_text1 = icu::UnicodeString::fromUTF8(text1);
  std::u16string u16_text1(icu_text1.getBuffer(),
                           icu_text1.getBuffer() + icu_text1.length());
  const char* text2 = "mdje";
  auto icu_text2 = icu::UnicodeString::fromUTF8(text2);
  std::u16string u16_text2(icu_text2.getBuffer(),
                           icu_text2.getBuffer() + icu_text2.length());
  const char* text3 = "fluttser mdje";
  auto icu_text3 = icu::UnicodeString::fromUTF8(text3);
  std::u16string u16_text3(icu_text3.getBuffer(),
                           icu_text3.getBuffer() + icu_text3.length());

  // Construct multi-run paragraph.
  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 2;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style1;
  text_style1.color = SK_ColorBLACK;
  text_style1.font_families = std::vector<std::string>(1, "Roboto");
  builder.PushStyle(text_style1);

  builder.AddText(u16_text1);

  txt::TextStyle text_style2;
  text_style2.color = SK_ColorBLACK;
  text_style2.font_families = std::vector<std::string>(1, "Roboto");
  text_style2.decoration = TextDecoration::kUnderline;
  text_style2.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style2);

  builder.AddText(u16_text2);

  builder.Pop();

  // Construct single run paragraph.
  txt::ParagraphBuilderTxt builder2(paragraph_style, GetTestFontCollection());

  builder2.PushStyle(text_style1);

  builder2.AddText(u16_text3);

  builder2.Pop();

  // Build multi-run paragraph
  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  // Build single-run paragraph
  auto paragraph2 = BuildParagraph(builder2);
  paragraph2->Layout(GetTestCanvasWidth());

  paragraph2->Paint(GetCanvas(), 0, 25);

  ASSERT_TRUE(Snapshot());

  ASSERT_EQ(paragraph->records_[0].GetRunWidth() +
                paragraph->records_[1].GetRunWidth(),
            paragraph2->records_[0].GetRunWidth());

  auto rects1 =
      paragraph->GetRectsForRange(0, 12, Paragraph::RectHeightStyle::kMax,
                                  Paragraph::RectWidthStyle::kTight);
  auto rects2 =
      paragraph2->GetRectsForRange(0, 12, Paragraph::RectHeightStyle::kMax,
                                   Paragraph::RectWidthStyle::kTight);

  for (size_t i = 0; i < 12; ++i) {
    auto r1 = GetCoordinatesForGlyphPosition(*paragraph, i);
    auto r2 = GetCoordinatesForGlyphPosition(*paragraph2, i);

    ASSERT_EQ(r1.fLeft, r2.fLeft);
    ASSERT_EQ(r1.fRight, r2.fRight);
  }
}

TEST_F(ParagraphTest, SimpleShadow) {
  const char* text = "Hello World Text Dialog";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  text_style.text_shadows.emplace_back(SK_ColorBLACK, SkPoint::Make(2.0, 2.0),
                                       1.0);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());
  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 2ull);
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);

  ASSERT_EQ(paragraph->records_[0].style().text_shadows.size(), 1ull);
  ASSERT_EQ(paragraph->records_[0].style().text_shadows[0],
            text_style.text_shadows[0]);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, ComplexShadow) {
  const char* text = "Text Chunk ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  text_style.text_shadows.emplace_back(SK_ColorBLACK, SkPoint::Make(2.0, 2.0),
                                       1.0);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  text_style.text_shadows.emplace_back(SK_ColorRED, SkPoint::Make(2.0, 2.0),
                                       5.0);
  text_style.text_shadows.emplace_back(SK_ColorGREEN, SkPoint::Make(10.0, -5.0),
                                       3.0);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();
  builder.AddText(u16_text);

  text_style.text_shadows.emplace_back(SK_ColorGREEN, SkPoint::Make(0.0, -1.0),
                                       0.0);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());
  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length() * 5);
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }

  ASSERT_EQ(paragraph->records_[0].style().text_shadows.size(), 1ull);
  ASSERT_EQ(paragraph->records_[1].style().text_shadows.size(), 3ull);
  ASSERT_EQ(paragraph->records_[2].style().text_shadows.size(), 1ull);
  ASSERT_EQ(paragraph->records_[3].style().text_shadows.size(), 4ull);
  ASSERT_EQ(paragraph->records_[4].style().text_shadows.size(), 1ull);
  for (size_t i = 0; i < 1; ++i)
    ASSERT_EQ(paragraph->records_[0].style().text_shadows[i],
              text_style.text_shadows[i]);
  for (size_t i = 0; i < 3; ++i)
    ASSERT_EQ(paragraph->records_[1].style().text_shadows[i],
              text_style.text_shadows[i]);
  for (size_t i = 0; i < 1; ++i)
    ASSERT_EQ(paragraph->records_[2].style().text_shadows[i],
              text_style.text_shadows[i]);
  for (size_t i = 0; i < 4; ++i)
    ASSERT_EQ(paragraph->records_[3].style().text_shadows[i],
              text_style.text_shadows[i]);
  for (size_t i = 0; i < 1; ++i)
    ASSERT_EQ(paragraph->records_[4].style().text_shadows[i],
              text_style.text_shadows[i]);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_MAC(BaselineParagraph)) {
  const char* text =
      "左線読設Byg後碁給能上目秘使約。満毎冠行来昼本可必図将発確年。今属場育"
      "図情闘陰野高備込制詩西校客。審対江置講今固残必託地集済決維駆年策。立得";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::justify;
  paragraph_style.height = 1.5;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_size = 55;
  text_style.letter_spacing = 2;
  text_style.font_families = std::vector<std::string>(1, "Source Han Serif CN");
  text_style.decoration_style = txt::TextDecorationStyle::kSolid;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 100);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);
  paint.setColor(SK_ColorRED);
  GetCanvas()->drawLine(0, paragraph->GetIdeographicBaseline(),
                        paragraph->GetMaxWidth(),
                        paragraph->GetIdeographicBaseline(), paint);

  paint.setColor(SK_ColorGREEN);

  GetCanvas()->drawLine(0, paragraph->GetAlphabeticBaseline(),
                        paragraph->GetMaxWidth(),
                        paragraph->GetAlphabeticBaseline(), paint);
  ASSERT_DOUBLE_EQ(paragraph->GetIdeographicBaseline(), 79.035000801086426);
  ASSERT_DOUBLE_EQ(paragraph->GetAlphabeticBaseline(), 63.305000305175781);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, FontFallbackParagraph) {
  const char* text = "Roboto 字典 ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());
  const char* text2 = "Homemade Apple 字典";
  icu_text = icu::UnicodeString::fromUTF8(text2);
  std::u16string u16_text2(icu_text.getBuffer(),
                           icu_text.getBuffer() + icu_text.length());
  const char* text3 = "Chinese 字典";
  icu_text = icu::UnicodeString::fromUTF8(text3);
  std::u16string u16_text3(icu_text.getBuffer(),
                           icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  // No chinese fallback provided, should not be able to render the chinese.
  text_style.font_families = std::vector<std::string>(1, "Not a real font");
  text_style.font_families.push_back("Also a fake font");
  text_style.font_families.push_back("So fake it is obvious");
  text_style.font_families.push_back("Next one should be a real font...");
  text_style.font_families.push_back("Roboto");
  text_style.font_families.push_back("another fake one in between");
  text_style.font_families.push_back("Homemade Apple");
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  // Japanese version of the chinese should be rendered.
  text_style.font_families = std::vector<std::string>(1, "Not a real font");
  text_style.font_families.push_back("Also a fake font");
  text_style.font_families.push_back("So fake it is obvious");
  text_style.font_families.push_back("Homemade Apple");
  text_style.font_families.push_back("Next one should be a real font...");
  text_style.font_families.push_back("Roboto");
  text_style.font_families.push_back("another fake one in between");
  text_style.font_families.push_back("Noto Sans CJK JP");
  text_style.font_families.push_back("Source Han Serif CN");
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text2);

  // Chinese font defiend first
  text_style.font_families = std::vector<std::string>(1, "Not a real font");
  text_style.font_families.push_back("Also a fake font");
  text_style.font_families.push_back("So fake it is obvious");
  text_style.font_families.push_back("Homemade Apple");
  text_style.font_families.push_back("Next one should be a real font...");
  text_style.font_families.push_back("Roboto");
  text_style.font_families.push_back("another fake one in between");
  text_style.font_families.push_back("Source Han Serif CN");
  text_style.font_families.push_back("Noto Sans CJK JP");
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text3);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_TRUE(Snapshot());

  ASSERT_EQ(paragraph->records_.size(), 5ull);
  ASSERT_DOUBLE_EQ(paragraph->records_[0].GetRunWidth(), 64.2109375);
  ASSERT_DOUBLE_EQ(paragraph->records_[1].GetRunWidth(), 139.1328125);
  ASSERT_DOUBLE_EQ(paragraph->records_[2].GetRunWidth(), 28);
  ASSERT_DOUBLE_EQ(paragraph->records_[3].GetRunWidth(), 62.25);
  ASSERT_DOUBLE_EQ(paragraph->records_[4].GetRunWidth(), 28);
  // When a different font is resolved, then the metrics are different.
  ASSERT_TRUE(paragraph->records_[2].metrics().fTop -
                  paragraph->records_[4].metrics().fTop !=
              0);
  ASSERT_TRUE(paragraph->records_[2].metrics().fAscent -
                  paragraph->records_[4].metrics().fAscent !=
              0);
  ASSERT_TRUE(paragraph->records_[2].metrics().fDescent -
                  paragraph->records_[4].metrics().fDescent !=
              0);
  ASSERT_TRUE(paragraph->records_[2].metrics().fBottom -
                  paragraph->records_[4].metrics().fBottom !=
              0);
  ASSERT_TRUE(paragraph->records_[2].metrics().fAvgCharWidth -
                  paragraph->records_[4].metrics().fAvgCharWidth !=
              0);
}

TEST_F(ParagraphTest, LINUX_ONLY(StrutParagraph1)) {
  // The chinese extra height should be absorbed by the strut.
  const char* text = "01234満毎冠p来É本可\nabcd\n満毎É行p昼本可";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.strut_font_families = std::vector<std::string>(1, "BlahFake");
  paragraph_style.strut_font_families.push_back("ahem");
  paragraph_style.strut_font_size = 50;
  paragraph_style.strut_height = 1.8;
  paragraph_style.strut_has_height_override = true;
  paragraph_style.strut_leading = 0.1;
  paragraph_style.strut_enabled = true;

  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "ahem");
  text_style.font_families.push_back("ahem");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = .5;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_max_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 34.5, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 50);
  EXPECT_NEAR(boxes[0].rect.bottom(), 84.5, 0.0001);

  boxes = paragraph->GetRectsForRange(0, 1, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 0, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 50);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 95);

  boxes =
      paragraph->GetRectsForRange(6, 10, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 300);
  EXPECT_NEAR(boxes[0].rect.top(), 34.5, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 500);
  EXPECT_NEAR(boxes[0].rect.bottom(), 84.5, 0.0001);
  ;

  boxes = paragraph->GetRectsForRange(6, 10, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 300);
  EXPECT_NEAR(boxes[0].rect.top(), 0, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 500);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 95);

  boxes = paragraph->GetRectsForRange(14, 16, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 190, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 100);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 285);

  boxes = paragraph->GetRectsForRange(20, 25, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 50);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 285);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 300);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 380);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(StrutParagraph2)) {
  // This string is all one size and smaller than the strut metrics.
  const char* text = "01234ABCDEFGH\nabcd\nABCDEFGH";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.strut_font_families = std::vector<std::string>(1, "ahem");
  paragraph_style.strut_font_size = 50;
  paragraph_style.strut_height = 1.6;
  paragraph_style.strut_has_height_override = true;
  paragraph_style.strut_enabled = true;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "ahem");
  text_style.font_families.push_back("ahem");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_max_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 24, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 50);
  EXPECT_NEAR(boxes[0].rect.bottom(), 74, 0.0001);

  boxes = paragraph->GetRectsForRange(0, 1, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 0, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 50);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 80);

  boxes =
      paragraph->GetRectsForRange(6, 10, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 300);
  EXPECT_NEAR(boxes[0].rect.top(), 24, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 500);
  EXPECT_NEAR(boxes[0].rect.bottom(), 74, 0.0001);

  boxes = paragraph->GetRectsForRange(6, 10, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 300);
  EXPECT_NEAR(boxes[0].rect.top(), 0, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 500);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 80);

  boxes = paragraph->GetRectsForRange(14, 16, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 160, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 100);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 240);

  boxes = paragraph->GetRectsForRange(20, 25, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 50);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 240);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 300);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 320);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(StrutParagraph3)) {
  // The strut is too small to absorb the extra chinese height, but the english
  // second line height is increased due to strut.
  const char* text = "01234満毎p行来昼本可\nabcd\n満毎冠行来昼本可";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.strut_font_families = std::vector<std::string>(1, "ahem");
  paragraph_style.strut_font_size = 50;
  paragraph_style.strut_height = 1.2;
  paragraph_style.strut_has_height_override = true;
  paragraph_style.strut_enabled = true;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "ahem");
  text_style.font_families.push_back("ahem");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_max_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 8, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 50);
  EXPECT_NEAR(boxes[0].rect.bottom(), 58, 0.0001);

  boxes = paragraph->GetRectsForRange(0, 1, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 0, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 50);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 60);

  boxes =
      paragraph->GetRectsForRange(6, 10, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 300);
  EXPECT_NEAR(boxes[0].rect.top(), 8, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 500);
  EXPECT_NEAR(boxes[0].rect.bottom(), 58, 0.0001);

  boxes = paragraph->GetRectsForRange(6, 10, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 300);
  EXPECT_NEAR(boxes[0].rect.top(), 0, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 500);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 60);

  boxes = paragraph->GetRectsForRange(14, 16, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 120);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 100);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 180);

  boxes = paragraph->GetRectsForRange(20, 25, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 50);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 180);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 300);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 240);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(StrutForceParagraph)) {
  // The strut is too small to absorb the extra chinese height, but the english
  // second line height is increased due to strut.
  const char* text = "01234満毎冠行来昼本可\nabcd\n満毎冠行来昼本可";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.strut_font_families = std::vector<std::string>(1, "ahem");
  paragraph_style.strut_font_size = 50;
  paragraph_style.strut_height = 1.5;
  paragraph_style.strut_has_height_override = true;
  paragraph_style.strut_leading = 0.1;
  paragraph_style.force_strut_height = true;
  paragraph_style.strut_enabled = true;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "ahem");
  text_style.font_families.push_back("ahem");
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_max_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 22.5, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 50);
  EXPECT_NEAR(boxes[0].rect.bottom(), 72.5, 0.0001);

  boxes = paragraph->GetRectsForRange(0, 1, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 0, 0.0001);
  ;
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 50);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 80);

  boxes =
      paragraph->GetRectsForRange(6, 10, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 300);
  EXPECT_NEAR(boxes[0].rect.top(), 22.5, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 500);
  EXPECT_NEAR(boxes[0].rect.bottom(), 72.5, 0.0001);

  boxes = paragraph->GetRectsForRange(6, 10, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 300);
  EXPECT_NEAR(boxes[0].rect.top(), 0, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 500);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 80);

  boxes = paragraph->GetRectsForRange(14, 16, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 160, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 100);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 240);

  boxes = paragraph->GetRectsForRange(20, 25, rect_height_max_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 50);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 240);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 300);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 320);

  ASSERT_TRUE(Snapshot());
}

// The height override is disabled for this test. Direct metrics from the font.
TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(StrutDefaultParagraph)) {
  const char* text = "01234満毎冠行来昼本可\nabcd\n満毎冠行来昼本可";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 10;
  paragraph_style.strut_font_families = std::vector<std::string>(1, "ahem");
  paragraph_style.strut_font_size = 50;
  paragraph_style.strut_height = 1.5;
  paragraph_style.strut_leading = 0.1;
  paragraph_style.force_strut_height = false;
  paragraph_style.strut_enabled = true;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "ahem");
  text_style.font_families.push_back("ahem");
  text_style.font_size = 20;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kTight;
  Paragraph::RectHeightStyle rect_height_strut_style =
      Paragraph::RectHeightStyle::kStrut;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes =
      paragraph->GetRectsForRange(0, 1, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 26.5, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 20);
  EXPECT_NEAR(boxes[0].rect.bottom(), 46.5, 0.0001);

  boxes = paragraph->GetRectsForRange(0, 2, rect_height_strut_style,
                                      rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_NEAR(boxes[0].rect.top(), 2.5, 0.0001);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 40);
  EXPECT_NEAR(boxes[0].rect.bottom(), 52.5, 0.0001);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, FontFeaturesParagraph) {
  const char* text = "12ab\n";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.color = SK_ColorBLACK;
  text_style.font_features.SetFeature("tnum", 1);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  text_style.font_features.SetFeature("tnum", 0);
  text_style.font_features.SetFeature("pnum", 1);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();
  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->glyph_lines_.size(), 3ull);

  // Tabular numbers should have equal widths.
  const txt::ParagraphTxt::GlyphLine& tnum_line = paragraph->glyph_lines_[0];
  ASSERT_EQ(tnum_line.positions.size(), 4ull);
  EXPECT_FLOAT_EQ(tnum_line.positions[0].x_pos.width(),
                  tnum_line.positions[1].x_pos.width());

  // Proportional numbers should have variable widths.
  const txt::ParagraphTxt::GlyphLine& pnum_line = paragraph->glyph_lines_[1];
  ASSERT_EQ(pnum_line.positions.size(), 4ull);
  EXPECT_NE(pnum_line.positions[0].x_pos.width(),
            pnum_line.positions[1].x_pos.width());

  // Alphabetic characters should be unaffected.
  EXPECT_FLOAT_EQ(tnum_line.positions[2].x_pos.width(),
                  pnum_line.positions[2].x_pos.width());

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, KhmerLineBreaker) {
  const char* text = "និងក្មេងចង់ផ្ទៃសមុទ្រសែនខៀវស្រងាត់";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_families = std::vector<std::string>(1, "Noto Sans Khmer");
  text_style.font_size = 24;
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(200);
  paragraph->Paint(GetCanvas(), 0, 0);

  ASSERT_EQ(paragraph->glyph_lines_.size(), 3ull);
  EXPECT_EQ(paragraph->glyph_lines_[0].positions.size(), 7ul);
  EXPECT_EQ(paragraph->glyph_lines_[1].positions.size(), 7ul);
  EXPECT_EQ(paragraph->glyph_lines_[2].positions.size(), 3ul);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, TextHeightBehaviorRectsParagraph) {
  // clang-format off
  const char* text =
      "line1\nline2\nline3";
  // clang-format on
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.text_height_behavior =
      txt::TextHeightBehavior::kDisableFirstAscent |
      txt::TextHeightBehavior::kDisableLastDescent;

  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 30;
  text_style.height = 5;
  text_style.has_height_override = true;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 300);

  paragraph->Paint(GetCanvas(), 0, 0);

  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }

  ASSERT_EQ(paragraph->records_.size(), 3ull);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  // First line. Shorter due to disabled height modifications on first ascent.
  boxes =
      paragraph->GetRectsForRange(0, 3, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 31.117188);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), -0.08203125);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom() - boxes[0].rect.top(), 59.082031);

  // Second line. Normal.
  boxes =
      paragraph->GetRectsForRange(6, 10, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 47.011719);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 59);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 209);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom() - boxes[0].rect.top(), 150);

  // Third line. Shorter due to disabled height modifications on last descent
  boxes =
      paragraph->GetRectsForRange(12, 17, rect_height_style, rect_width_style);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 63.859375);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 208.92578);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 335);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom() - boxes[0].rect.top(), 126.07422);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, MixedTextHeightBehaviorRectsParagraph) {
  const char* text = "0123456789";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  // The paragraph's first line and the last line use the font's ascent/descent.
  paragraph_style.text_height_behavior =
      txt::TextHeightBehavior::kDisableFirstAscent |
      txt::TextHeightBehavior::kDisableLastDescent;

  txt::ParagraphBuilderTxt builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_families = std::vector<std::string>(1, "Roboto");
  text_style.font_size = 30;
  text_style.height = 5;
  text_style.has_height_override = true;
  text_style.half_leading = true;

  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  text_style.half_leading = false;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  // 2 identical runs except the first run has half-leading enabled.
  builder.Pop();

  auto paragraph = BuildParagraph(builder);
  paragraph->Layout(GetTestCanvasWidth() - 300);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  Paragraph::RectHeightStyle rect_height_style =
      Paragraph::RectHeightStyle::kMax;
  Paragraph::RectWidthStyle rect_width_style =
      Paragraph::RectWidthStyle::kTight;
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 20, rect_height_style, rect_width_style);

  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  // The kDisableAll flag is applied.
  EXPECT_GT(boxes.size(), 1ull);
  // The height of the line equals to the metrics height of the font
  // (ascent + descent).
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom() - boxes[0].rect.top(),
                  27.8320312 + 7.32421875);

  ASSERT_TRUE(Snapshot());
}
}  // namespace txt
