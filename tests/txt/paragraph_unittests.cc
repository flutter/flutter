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

#include "lib/ftl/logging.h"
#include "lib/txt/src/font_style.h"
#include "lib/txt/src/font_weight.h"
#include "lib/txt/src/paragraph.h"
#include "lib/txt/src/text_align.h"
#include "lib/txt/tests/txt/utils.h"
#include "paragraph_builder.h"
#include "render_test.h"
#include "third_party/icu/source/common/unicode/unistr.h"
#include "third_party/skia/include/core/SkColor.h"

namespace txt {

TEST_F(RenderTest, SimpleParagraph) {
  const char* text = "Hello World";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.color = SK_ColorBLACK;
  builder.PushStyle(text_style);
  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth(), txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 1ull);
  ASSERT_TRUE(paragraph->runs_.styles_[0].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

TEST_F(RenderTest, SimpleRedParagraph) {
  const char* text = "I am RED";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.color = SK_ColorRED;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth(), txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 1ull);
  ASSERT_TRUE(paragraph->runs_.styles_[0].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

TEST_F(RenderTest, RainbowParagraph) {
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
  txt::ParagraphBuilder builder(paragraph_style);

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
  text_style2.fake_bold = true;
  text_style2.color = SK_ColorGREEN;
  text_style2.decoration = txt::TextDecoration(0x1 | 0x2 | 0x4);
  text_style2.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style2);

  builder.AddText(u16_text2);

  txt::TextStyle text_style3;
  text_style3.font_family = "Homemade Apple";
  builder.PushStyle(text_style3);

  builder.AddText(u16_text3);

  txt::TextStyle text_style4;
  text_style4.font_size = 10;
  text_style4.color = SK_ColorBLUE;
  text_style4.font_family = "Roboto";
  builder.PushStyle(text_style4);

  builder.AddText(u16_text4);

  // Extra text to see if it goes to default when there is more text chunks than
  // styles.
  builder.AddText(u16_text5);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth(), txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 10.0, 50.0);

  u16_text1 += u16_text2 + u16_text3 + u16_text4;
  for (size_t i = 0; i < u16_text1.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text1[i]);
  }
  ASSERT_TRUE(Snapshot());
  ASSERT_EQ(paragraph->runs_.runs_.size(), 4ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 4ull);
  ASSERT_TRUE(paragraph->runs_.styles_[0].equals(text_style1));
  ASSERT_TRUE(paragraph->runs_.styles_[1].equals(text_style2));
  ASSERT_TRUE(paragraph->runs_.styles_[2].equals(text_style3));
  ASSERT_TRUE(paragraph->runs_.styles_[3].equals(text_style4));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style1.color);
  ASSERT_EQ(paragraph->records_[1].style().color, text_style2.color);
  ASSERT_EQ(paragraph->records_[2].style().color, text_style3.color);
  ASSERT_EQ(paragraph->records_[3].style().color, text_style4.color);
}

// Currently, this should render nothing without a supplied TextStyle.
TEST_F(RenderTest, DefaultStyleParagraph) {
  const char* text = "No TextStyle! Uh Oh!";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.color = SK_ColorRED;

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth(), txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 10.0, 15.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 0ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 0ull);
  ASSERT_TRUE(Snapshot());
}

TEST_F(RenderTest, BoldParagraph) {
  const char* text = "This is Red max bold text!";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.font_size = 60;
  // Letter spacing not yet implemented
  text_style.letter_spacing = 10;
  text_style.font_weight = txt::FontWeight::w700;
  text_style.fake_bold = true;
  text_style.color = SK_ColorRED;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth(), txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 10.0, 60.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 1ull);
  ASSERT_TRUE(paragraph->runs_.styles_[0].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

TEST_F(RenderTest, LeftAlignParagraph) {
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
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.15;
  text_style.decoration = txt::TextDecoration(0x1);
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth() - 100, txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 0, 0);
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 1ull);
  ASSERT_TRUE(paragraph->runs_.styles_[0].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

TEST_F(RenderTest, RightAlignParagraph) {
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
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.15;
  text_style.decoration = txt::TextDecoration(0x1);
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth() - 100, txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 0, 0);
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 1ull);
  ASSERT_TRUE(paragraph->runs_.styles_[0].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

TEST_F(RenderTest, CenterAlignParagraph) {
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
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.15;
  text_style.decoration = txt::TextDecoration(0x1);
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth() - 100, txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 0, 0);
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 1ull);
  ASSERT_TRUE(paragraph->runs_.styles_[0].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

TEST_F(RenderTest, JustifyAlignParagraph) {
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
  paragraph_style.text_align = TextAlign::justify;
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.font_size = 26;
  text_style.letter_spacing = 1;
  text_style.word_spacing = 5;
  text_style.color = SK_ColorBLACK;
  text_style.height = 1.15;
  text_style.decoration = txt::TextDecoration(0x1);
  text_style.decoration_color = SK_ColorBLACK;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth() - 100, txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 0, 0);
  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 1ull);
  ASSERT_TRUE(paragraph->runs_.styles_[0].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

TEST_F(RenderTest, ItalicsParagraph) {
  const char* text = "I am Italicized!                           ";
  auto icu_text = icu::UnicodeString::fromUTF8(text);
  std::u16string u16_text(icu_text.getBuffer(),
                          icu_text.getBuffer() + icu_text.length());

  txt::ParagraphStyle paragraph_style;
  txt::ParagraphBuilder builder(paragraph_style);

  txt::TextStyle text_style;
  text_style.color = SK_ColorRED;
  text_style.font_style = txt::FontStyle::italic;
  text_style.font_size = 35;
  builder.PushStyle(text_style);

  builder.AddText(u16_text);

  builder.Pop();

  auto paragraph = builder.Build();
  paragraph->Layout(GetTestCanvasWidth(), txt::GetFontDir());

  paragraph->Paint(GetCanvas(), 10.0, 35.0);

  ASSERT_EQ(paragraph->text_.size(), std::string{text}.length());
  for (size_t i = 0; i < u16_text.length(); i++) {
    ASSERT_EQ(paragraph->text_[i], u16_text[i]);
  }
  ASSERT_EQ(paragraph->runs_.runs_.size(), 1ull);
  ASSERT_EQ(paragraph->runs_.styles_.size(), 1ull);
  ASSERT_TRUE(paragraph->runs_.styles_[0].equals(text_style));
  ASSERT_EQ(paragraph->records_[0].style().color, text_style.color);
  ASSERT_TRUE(Snapshot());
}

}  // namespace txt
