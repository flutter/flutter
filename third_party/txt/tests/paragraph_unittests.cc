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

#include "flutter/fml/logging.h"
#include "render_test.h"
#include "third_party/icu/source/common/unicode/unistr.h"
#include "third_party/skia/include/core/SkColor.h"
#include "txt/font_style.h"
#include "txt/font_weight.h"
#include "txt/paragraph.h"
#include "txt/paragraph_builder.h"
#include "txt_test_utils.h"

#define DISABLE_ON_WINDOWS(TEST) DISABLE_TEST_WINDOWS(TEST)

namespace txt {

using ParagraphTest = RenderTest;

TEST_F(ParagraphTest, SimpleParagraph) {
  const char* text = "Hello World Text Dialog";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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

TEST_F(ParagraphTest, SimpleRedParagraph) {
  const char* text = "I am RED";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorRED;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style1;
  text_style1.color = SK_ColorRED;
  text_style1.font_family = "Roboto";
  builder.PushStyle(text_style1);

  builder.AddText(u16_text1);

  txt::TextStyle text_style2;
  text_style2.font_size = 50;
  text_style2.letter_spacing = 10;
  text_style2.word_spacing = 30;
  text_style2.font_weight = txt::FontWeight::w600;
  text_style2.color = SK_ColorGREEN;
  text_style2.font_family = "Roboto";
  text_style2.decoration = TextDecoration::kUnderline |
                           TextDecoration::kOverline |
                           TextDecoration::kLineThrough;
  text_style2.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style2);

  builder.AddText(u16_text2);

  txt::TextStyle text_style3;
  text_style3.font_family = "Homemade Apple";
  builder.PushStyle(text_style3);

  builder.AddText(u16_text3);

  txt::TextStyle text_style4;
  text_style4.font_size = 14;
  text_style4.color = SK_ColorBLUE;
  text_style4.font_family = "Roboto";
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

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.font_size = 60;
  text_style.letter_spacing = 0;
  text_style.font_weight = txt::FontWeight::w900;
  text_style.color = SK_ColorRED;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(LeftAlignParagraph)) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are nessecary. Very short. "
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
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

  auto paragraph = builder.Build();
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

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(RightAlignParagraph)) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are nessecary. Very short. "
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
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

  auto paragraph = builder.Build();
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
  ASSERT_NEAR(
      paragraph->records_[0].offset().x(),
      paragraph->width_ -
          paragraph->breaker_.getWidths()[paragraph->records_[0].line()],
      2.0);

  ASSERT_TRUE(paragraph->records_[1].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[1].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(
      paragraph->records_[1].offset().x(),
      paragraph->width_ -
          paragraph->breaker_.getWidths()[paragraph->records_[1].line()],
      2.0);

  ASSERT_TRUE(paragraph->records_[2].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(
      paragraph->records_[2].offset().x(),
      paragraph->width_ -
          paragraph->breaker_.getWidths()[paragraph->records_[2].line()],
      2.0);

  ASSERT_TRUE(paragraph->records_[3].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[3].offset().y(), expected_y);
  expected_y += 30 * 10;
  ASSERT_NEAR(
      paragraph->records_[3].offset().x(),
      paragraph->width_ -
          paragraph->breaker_.getWidths()[paragraph->records_[3].line()],
      2.0);

  ASSERT_TRUE(paragraph->records_[13].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[13].offset().y(), expected_y);
  ASSERT_NEAR(
      paragraph->records_[13].offset().x(),
      paragraph->width_ -
          paragraph->breaker_.getWidths()[paragraph->records_[13].line()],
      2.0);

  ASSERT_EQ(paragraph_style.text_align,
            paragraph->GetParagraphStyle().text_align);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(CenterAlignParagraph)) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are nessecary. Very short. "
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
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

  auto paragraph = builder.Build();
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
  ASSERT_NEAR(paragraph->records_[0].offset().x(),
              (paragraph->width_ -
               paragraph->breaker_.getWidths()[paragraph->records_[0].line()]) /
                  2,
              2.0);

  ASSERT_TRUE(paragraph->records_[1].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[1].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(paragraph->records_[1].offset().x(),
              (paragraph->width_ -
               paragraph->breaker_.getWidths()[paragraph->records_[1].line()]) /
                  2,
              2.0);

  ASSERT_TRUE(paragraph->records_[2].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().y(), expected_y);
  expected_y += 30;
  ASSERT_NEAR(paragraph->records_[2].offset().x(),
              (paragraph->width_ -
               paragraph->breaker_.getWidths()[paragraph->records_[2].line()]) /
                  2,
              2.0);

  ASSERT_TRUE(paragraph->records_[3].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[3].offset().y(), expected_y);
  expected_y += 30 * 10;
  ASSERT_NEAR(paragraph->records_[3].offset().x(),
              (paragraph->width_ -
               paragraph->breaker_.getWidths()[paragraph->records_[3].line()]) /
                  2,
              2.0);

  ASSERT_TRUE(paragraph->records_[13].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[13].offset().y(), expected_y);
  ASSERT_NEAR(
      paragraph->records_[13].offset().x(),
      (paragraph->width_ -
       paragraph->breaker_.getWidths()[paragraph->records_[13].line()]) /
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
      "sentences are okay too because they are nessecary. Very short. "
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
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

  auto paragraph = builder.Build();
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

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DecorationsParagraph) {
  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::left;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
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
  builder.PushStyle(text_style);
  builder.AddText("This text should be");

  text_style.decoration_style = txt::TextDecorationStyle::kDouble;
  text_style.decoration_color = SK_ColorBLUE;
  builder.PushStyle(text_style);
  builder.AddText(" decorated even when");

  text_style.decoration_style = txt::TextDecorationStyle::kDotted;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(" wrapped around to");

  text_style.decoration_style = txt::TextDecorationStyle::kDashed;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(" the next line.");

  text_style.decoration_style = txt::TextDecorationStyle::kWavy;
  text_style.decoration_color = SK_ColorRED;
  builder.PushStyle(text_style);

  builder.AddText(" Otherwise, bad things happen.");

  builder.Pop();

  auto paragraph = builder.Build();
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
}

TEST_F(ParagraphTest, ItalicsParagraph) {
  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorRED;
  text_style.font_size = 10;
  builder.PushStyle(text_style);
  builder.AddText("No italic ");

  text_style.font_style = txt::FontStyle::italic;
  builder.PushStyle(text_style);
  builder.AddText("Yes Italic ");

  builder.Pop();
  builder.AddText("No Italic again.");

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_size = 35;
  text_style.letter_spacing = 2;
  text_style.font_family = "Source Han Serif CN";
  text_style.decoration = TextDecoration::kUnderline |
                          TextDecoration::kOverline |
                          TextDecoration::kLineThrough;
  text_style.decoration_style = txt::TextDecorationStyle::kSolid;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_size = 35;
  text_style.letter_spacing = 2;
  text_style.font_family = "Katibeh";
  text_style.decoration = TextDecoration::kUnderline |
                          TextDecoration::kOverline |
                          TextDecoration::kLineThrough;
  text_style.decoration_style = txt::TextDecorationStyle::kSolid;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.font_size = 50;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.5;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(1, 180).position, 36ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(10000, 180).position,
            54ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(70, 180).position, 38ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(1, 270).position, 54ull);
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  // NOTE: The base truth values may still need adjustment as the specifics
  // are adjusted.
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, Paragraph::RectStyle::kNone);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes = paragraph->GetRectsForRange(0, 1, Paragraph::RectStyle::kNone);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 28.417969);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorBLUE);
  boxes = paragraph->GetRectsForRange(2, 8, Paragraph::RectStyle::kNone);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 56.835938);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 177.97266);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorGREEN);
  boxes = paragraph->GetRectsForRange(8, 21, Paragraph::RectStyle::kNone);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 177.97266);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 507.02344);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorRED);
  boxes = paragraph->GetRectsForRange(30, 100, Paragraph::RectStyle::kNone);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 4ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 211.375);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 59.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 463.61719);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 118);

  // TODO(garyq): The following set of vals are definetly wrong and
  // end of paragraph handling needs to be fixed in a later patch.
  EXPECT_FLOAT_EQ(boxes[3].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[3].rect.top(), 236.40625);
  EXPECT_FLOAT_EQ(boxes[3].rect.right(), 142.08984);
  EXPECT_FLOAT_EQ(boxes[3].rect.bottom(), 295);

  paint.setColor(SK_ColorBLUE);
  boxes = paragraph->GetRectsForRange(19, 22, Paragraph::RectStyle::kNone);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 450.1875);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0.40625);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 519.47266);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 59);

  paint.setColor(SK_ColorRED);
  boxes = paragraph->GetRectsForRange(21, 21, Paragraph::RectStyle::kNone);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(GetRectsForRangeTight)) {
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Noto Sans CJK JP";
  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.font_weight = FontWeight::w500;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(550);

  paragraph->Paint(GetCanvas(), 0, 0);

  SkPaint paint;
  paint.setStyle(SkPaint::kStroke_Style);
  paint.setAntiAlias(true);
  paint.setStrokeWidth(1);

  // Tests for GetRectsForRange()
  // NOTE: The base truth values may still need adjustment as the specifics
  // are adjusted.
  paint.setColor(SK_ColorRED);
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph->GetRectsForRange(0, 0, Paragraph::RectStyle::kTight);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 0ull);

  boxes = paragraph->GetRectsForRange(0, 1, Paragraph::RectStyle::kTight);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 16.898438);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 74);

  paint.setColor(SK_ColorBLUE);
  boxes = paragraph->GetRectsForRange(2, 8, Paragraph::RectStyle::kTight);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 1ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 264.09375);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 74);

  paint.setColor(SK_ColorGREEN);
  boxes = paragraph->GetRectsForRange(8, 21, Paragraph::RectStyle::kTight);
  for (size_t i = 0; i < boxes.size(); ++i) {
    GetCanvas()->drawRect(boxes[i].rect, paint);
  }
  EXPECT_EQ(boxes.size(), 2ull);
  EXPECT_FLOAT_EQ(boxes[0].rect.left(), 264.09375);
  EXPECT_FLOAT_EQ(boxes[0].rect.top(), 0);
  EXPECT_FLOAT_EQ(boxes[0].rect.right(), 595.08594);
  EXPECT_FLOAT_EQ(boxes[0].rect.bottom(), 74);

  ASSERT_TRUE(Snapshot());
}

SkRect GetCoordinatesForGlyphPosition(const txt::Paragraph& paragraph,
                                      size_t pos) {
  std::vector<txt::Paragraph::TextBox> boxes =
      paragraph.GetRectsForRange(pos, pos + 1, Paragraph::RectStyle::kNone);
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.font_size = 52;
  text_style.letter_spacing = 1.19039;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.5;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
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
  builder.AddText("|");
  builder.Pop();

  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 20;
  builder.PushStyle(text_style);
  builder.AddText("H ");
  builder.Pop();

  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  builder.PushStyle(text_style);
  builder.AddText("H ");
  builder.Pop();

  text_style.font_size = 50;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 20;
  builder.PushStyle(text_style);
  builder.AddText("H ");
  builder.Pop();

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.font_size = 31;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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

TEST_F(ParagraphTest, KernScaleParagraph) {
  float scale = 3.0f;

  txt::ParagraphStyle paragraph_style;
  paragraph_style.break_strategy = minikin::kBreakStrategy_HighQuality;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Droid Serif";
  text_style.font_size = 100 / scale;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText("AVAVAWAH A0 V0 VA To The Lo");
  builder.PushStyle(text_style);
  builder.AddText("A");
  builder.PushStyle(text_style);
  builder.AddText("V");
  text_style.font_size = 14 / scale;
  builder.PushStyle(text_style);
  builder.AddText(
      " Dialog Text List lots of words to see if kerning works on a bigger set "
      "of characters AVAVAW");

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth() / scale);
  GetCanvas()->scale(scale, scale);
  paragraph->Paint(GetCanvas(), 0, 0);
  GetCanvas()->scale(1.0, 1.0);
  ASSERT_TRUE(Snapshot());

  EXPECT_DOUBLE_EQ(paragraph->records_[0].offset().x(), 0);
  EXPECT_DOUBLE_EQ(paragraph->records_[1].offset().x(), 0);
  EXPECT_DOUBLE_EQ(paragraph->records_[2].offset().x(), 207.37109375f);
  EXPECT_DOUBLE_EQ(paragraph->records_[3].offset().x(), 230.87109375f);
  EXPECT_DOUBLE_EQ(paragraph->records_[4].offset().x(), 253.36328125f);
}

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(NewlineParagraph)) {
  txt::ParagraphStyle paragraph_style;
  paragraph_style.font_family = "Roboto";
  paragraph_style.break_strategy = minikin::kBreakStrategy_HighQuality;

  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.font_size = 60;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(
      "line1\nline2 test1 test2 test3 test4 test5 test6 test7\nline3\n\nline4 "
      "test1 test2 test3 test4");

  builder.Pop();

  auto paragraph = builder.Build();
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

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(EmojiParagraph)) {
  const char* text =
      "😀😃😄😁😆😅😂🤣☺😇🙂😍😡😟😢😻👽💩👍👎🙏👌👋👄👁👦👼👨‍🚀👨‍🚒🙋‍♂️👳👨‍👨‍👧‍👧\
      💼👡👠☂🐶🐰🐻🐼🐷🐒🐵🐔🐧🐦🐋🐟🐡🕸🐌🐴🐊🐄🐪🐘🌸🌏🔥🌟🌚🌝💦💧\
      ❄🍕🍔🍟🥝🍱🕶🎩🏈⚽🚴‍♀️🎻🎼🎹🚨🚎🚐⚓🛳🚀🚁🏪🏢🖱⏰📱💾💉📉🛏🔑🔓\
      📁🗓📊❤💯🚫🔻♠♣🕓❗🏳🏁🏳️‍🌈🇮🇹🇱🇷🇺🇸🇬🇧🇨🇳🇧🇴";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;

  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_family = "Noto Color Emoji";
  text_style.font_size = 50;
  text_style.decoration = TextDecoration::kUnderline;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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

  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.font_size = 31;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.font_size = 31;
  text_style.letter_spacing = 0;
  text_style.word_spacing = 0;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  // First Layout.
  auto paragraph = builder.Build();
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
      "sentences are okay too because they are nessecary. Very short. ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.ellipsis = u"\u2026";
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style1;
  text_style1.color = SK_ColorBLACK;
  text_style1.font_family = "Roboto";
  builder.PushStyle(text_style1);

  builder.AddText(u16_text1);

  txt::TextStyle text_style2;
  text_style2.color = SK_ColorBLACK;
  text_style2.font_family = "Roboto";
  text_style2.decoration = TextDecoration::kUnderline;
  text_style2.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style2);

  builder.AddText(u16_text2);

  builder.Pop();

  // Construct single run paragraph.
  txt::ParagraphBuilder builder2(paragraph_style, GetTestFontCollection());

  builder2.PushStyle(text_style1);

  builder2.AddText(u16_text3);

  builder2.Pop();

  // Build multi-run paragraph
  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth());

  paragraph->Paint(GetCanvas(), 0, 0);

  // Build single-run paragraph
  auto paragraph2 = builder2.Build();
  paragraph2->Layout(GetTestCanvasWidth());

  paragraph2->Paint(GetCanvas(), 0, 25);

  ASSERT_TRUE(Snapshot());

  ASSERT_EQ(paragraph->records_[0].GetRunWidth() +
                paragraph->records_[1].GetRunWidth(),
            paragraph2->records_[0].GetRunWidth());

  auto rects1 = paragraph->GetRectsForRange(0, 12, Paragraph::RectStyle::kNone);
  auto rects2 =
      paragraph2->GetRectsForRange(0, 12, Paragraph::RectStyle::kNone);

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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
  text_style.color = SK_ColorBLACK;
  text_style.text_shadows.emplace_back(SK_ColorBLACK, SkPoint::Make(2.0, 2.0),
                                       1.0);
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
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

  auto paragraph = builder.Build();
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

TEST_F(ParagraphTest, DISABLE_ON_WINDOWS(LineHeightsParagraph)) {
  const char* text =
      "This is a very long sentence to test if the text will properly wrap "
      "around and go to the next line. Sometimes, short sentence. Longer "
      "sentences are okay too because they are nessecary. Very short. "
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
  double line_height = 2.0;
  paragraph_style.line_height = line_height;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.font_family = "Roboto";
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

  auto paragraph = builder.Build();
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
  expected_y += 27.5 * line_height;
  ASSERT_DOUBLE_EQ(paragraph->records_[0].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[1].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[1].offset().y(), expected_y);
  expected_y += 27.5 * line_height;
  ASSERT_DOUBLE_EQ(paragraph->records_[1].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[2].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().y(), expected_y);
  expected_y += 27.5 * line_height;
  ASSERT_DOUBLE_EQ(paragraph->records_[2].offset().x(), 0);

  ASSERT_TRUE(paragraph->records_[3].style().equals(text_style));
  ASSERT_DOUBLE_EQ(paragraph->records_[3].offset().y(), expected_y);
  expected_y += 27.5 * 10 * line_height;
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
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(1, 70).position, 68ull);
  ASSERT_EQ(paragraph->GetGlyphPositionAtCoordinate(2000, 35).position, 134ull);

  ASSERT_TRUE(Snapshot());
}

TEST_F(ParagraphTest, BaselineParagraph) {
  const char* text =
      "左線読設Byg後碁給能上目秘使約。満毎冠行来昼本可必図将発確年。今属場育"
      "図情闘陰野高備込制詩西校客。審対江置講今固残必託地集済決維駆年策。立得";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  paragraph_style.max_lines = 14;
  paragraph_style.text_align = TextAlign::justify;
  paragraph_style.line_height = 1.5;
  txt::ParagraphBuilder builder(paragraph_style, GetTestFontCollection());

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  text_style.font_size = 55;
  text_style.letter_spacing = 2;
  text_style.font_family = "Source Han Serif CN";
  text_style.decoration_style = txt::TextDecorationStyle::kSolid;
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
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
  ASSERT_DOUBLE_EQ(paragraph->GetIdeographicBaseline(), 79.035003662109375);
  ASSERT_DOUBLE_EQ(paragraph->GetAlphabeticBaseline(), 63.305000305175781);

  ASSERT_TRUE(Snapshot());
}

}  // namespace txt
